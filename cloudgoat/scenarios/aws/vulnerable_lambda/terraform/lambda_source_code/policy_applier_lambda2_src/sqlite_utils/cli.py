import base64
import click
from click_default_group import DefaultGroup  # type: ignore
from datetime import datetime
import hashlib
import pathlib
import sqlite_utils
from sqlite_utils.db import AlterError, BadMultiValues, DescIndex
from sqlite_utils import recipes
import textwrap
import inspect
import io
import itertools
import json
import os
import sys
import csv as csv_std
import tabulate
from .utils import (
    file_progress,
    find_spatialite,
    sqlite3,
    decode_base64_values,
    progressbar,
    rows_from_file,
    Format,
    TypeTracker,
)

CONTEXT_SETTINGS = dict(help_option_names=["-h", "--help"])

VALID_COLUMN_TYPES = ("INTEGER", "TEXT", "FLOAT", "BLOB")

UNICODE_ERROR = """
{}

The input you provided uses a character encoding other than utf-8.

You can fix this by passing the --encoding= option with the encoding of the file.

If you do not know the encoding, running 'file filename.csv' may tell you.

It's often worth trying: --encoding=latin-1
""".strip()


# Increase CSV field size limit to maximum possible
# https://stackoverflow.com/a/15063941
field_size_limit = sys.maxsize

while True:
    try:
        csv_std.field_size_limit(field_size_limit)
        break
    except OverflowError:
        field_size_limit = int(field_size_limit / 10)


def output_options(fn):
    for decorator in reversed(
        (
            click.option(
                "--nl",
                help="Output newline-delimited JSON",
                is_flag=True,
                default=False,
            ),
            click.option(
                "--arrays",
                help="Output rows as arrays instead of objects",
                is_flag=True,
                default=False,
            ),
            click.option("--csv", is_flag=True, help="Output CSV"),
            click.option("--tsv", is_flag=True, help="Output TSV"),
            click.option("--no-headers", is_flag=True, help="Omit CSV headers"),
            click.option("-t", "--table", is_flag=True, help="Output as a table"),
            click.option(
                "--fmt",
                help="Table format - one of {}".format(
                    ", ".join(tabulate.tabulate_formats)
                ),
                default="simple",
            ),
            click.option(
                "--json-cols",
                help="Detect JSON cols and output them as JSON, not escaped strings",
                is_flag=True,
                default=False,
            ),
        )
    ):
        fn = decorator(fn)
    return fn


def load_extension_option(fn):
    return click.option(
        "--load-extension",
        multiple=True,
        help="SQLite extensions to load",
    )(fn)


@click.group(
    cls=DefaultGroup,
    default="query",
    default_if_no_args=True,
    context_settings=CONTEXT_SETTINGS,
)
@click.version_option()
def cli():
    "Commands for interacting with a SQLite database"
    pass


@cli.command()
@click.argument(
    "path",
    type=click.Path(exists=True, file_okay=True, dir_okay=False, allow_dash=False),
    required=True,
)
@click.option(
    "--fts4", help="Just show FTS4 enabled tables", default=False, is_flag=True
)
@click.option(
    "--fts5", help="Just show FTS5 enabled tables", default=False, is_flag=True
)
@click.option(
    "--counts", help="Include row counts per table", default=False, is_flag=True
)
@output_options
@click.option(
    "--columns",
    help="Include list of columns for each table",
    is_flag=True,
    default=False,
)
@click.option(
    "--schema",
    help="Include schema for each table",
    is_flag=True,
    default=False,
)
@load_extension_option
def tables(
    path,
    fts4,
    fts5,
    counts,
    nl,
    arrays,
    csv,
    tsv,
    no_headers,
    table,
    fmt,
    json_cols,
    columns,
    schema,
    load_extension,
    views=False,
):
    """List the tables in the database"""
    db = sqlite_utils.Database(path)
    _load_extensions(db, load_extension)
    headers = ["view" if views else "table"]
    if counts:
        headers.append("count")
    if columns:
        headers.append("columns")
    if schema:
        headers.append("schema")

    def _iter():
        if views:
            items = db.view_names()
        else:
            items = db.table_names(fts4=fts4, fts5=fts5)
        for name in items:
            row = [name]
            if counts:
                row.append(db[name].count)
            if columns:
                cols = [c.name for c in db[name].columns]
                if csv:
                    row.append("\n".join(cols))
                else:
                    row.append(cols)
            if schema:
                row.append(db[name].schema)
            yield row

    if table:
        print(tabulate.tabulate(_iter(), headers=headers, tablefmt=fmt))
    elif csv or tsv:
        writer = csv_std.writer(sys.stdout, dialect="excel-tab" if tsv else "excel")
        if not no_headers:
            writer.writerow(headers)
        for row in _iter():
            writer.writerow(row)
    else:
        for line in output_rows(_iter(), headers, nl, arrays, json_cols):
            click.echo(line)


@cli.command()
@click.argument(
    "path",
    type=click.Path(exists=True, file_okay=True, dir_okay=False, allow_dash=False),
    required=True,
)
@click.option(
    "--counts", help="Include row counts per view", default=False, is_flag=True
)
@output_options
@click.option(
    "--columns",
    help="Include list of columns for each view",
    is_flag=True,
    default=False,
)
@click.option(
    "--schema",
    help="Include schema for each view",
    is_flag=True,
    default=False,
)
@load_extension_option
def views(
    path,
    counts,
    nl,
    arrays,
    csv,
    tsv,
    no_headers,
    table,
    fmt,
    json_cols,
    columns,
    schema,
    load_extension,
):
    """List the views in the database"""
    tables.callback(
        path=path,
        fts4=False,
        fts5=False,
        counts=counts,
        nl=nl,
        arrays=arrays,
        csv=csv,
        tsv=tsv,
        no_headers=no_headers,
        table=table,
        fmt=fmt,
        json_cols=json_cols,
        columns=columns,
        schema=schema,
        load_extension=load_extension,
        views=True,
    )


@cli.command()
@click.argument(
    "path",
    type=click.Path(exists=True, file_okay=True, dir_okay=False, allow_dash=False),
    required=True,
)
@click.argument("tables", nargs=-1)
@click.option("--no-vacuum", help="Don't run VACUUM", default=False, is_flag=True)
@load_extension_option
def optimize(path, tables, no_vacuum, load_extension):
    """Optimize all full-text search tables and then run VACUUM - should shrink the database file"""
    db = sqlite_utils.Database(path)
    _load_extensions(db, load_extension)
    if not tables:
        tables = db.table_names(fts4=True) + db.table_names(fts5=True)
    with db.conn:
        for table in tables:
            db[table].optimize()
    if not no_vacuum:
        db.vacuum()


@cli.command(name="rebuild-fts")
@click.argument(
    "path",
    type=click.Path(exists=True, file_okay=True, dir_okay=False, allow_dash=False),
    required=True,
)
@click.argument("tables", nargs=-1)
@load_extension_option
def rebuild_fts(path, tables, load_extension):
    """Rebuild all or specific full-text search tables"""
    db = sqlite_utils.Database(path)
    _load_extensions(db, load_extension)
    if not tables:
        tables = db.table_names(fts4=True) + db.table_names(fts5=True)
    with db.conn:
        for table in tables:
            db[table].rebuild_fts()


@cli.command()
@click.argument(
    "path",
    type=click.Path(exists=True, file_okay=True, dir_okay=False, allow_dash=False),
    required=True,
)
def vacuum(path):
    """Run VACUUM against the database"""
    sqlite_utils.Database(path).vacuum()


@cli.command()
@click.argument(
    "path",
    type=click.Path(exists=True, file_okay=True, dir_okay=False, allow_dash=False),
    required=True,
)
@load_extension_option
def dump(path, load_extension):
    """Output a SQL dump of the schema and full contents of the database"""
    db = sqlite_utils.Database(path)
    _load_extensions(db, load_extension)
    for line in db.conn.iterdump():
        click.echo(line)


@cli.command(name="add-column")
@click.argument(
    "path",
    type=click.Path(exists=True, file_okay=True, dir_okay=False, allow_dash=False),
    required=True,
)
@click.argument("table")
@click.argument("col_name")
@click.argument(
    "col_type",
    type=click.Choice(
        ["integer", "float", "blob", "text", "INTEGER", "FLOAT", "BLOB", "TEXT"]
    ),
    required=False,
)
@click.option(
    "--fk", type=str, required=False, help="Table to reference as a foreign key"
)
@click.option(
    "--fk-col",
    type=str,
    required=False,
    help="Referenced column on that foreign key table - if omitted will automatically use the primary key",
)
@click.option(
    "--not-null-default",
    type=str,
    required=False,
    help="Add NOT NULL DEFAULT 'TEXT' constraint",
)
@load_extension_option
def add_column(
    path, table, col_name, col_type, fk, fk_col, not_null_default, load_extension
):
    "Add a column to the specified table"
    db = sqlite_utils.Database(path)
    _load_extensions(db, load_extension)
    db[table].add_column(
        col_name, col_type, fk=fk, fk_col=fk_col, not_null_default=not_null_default
    )


@cli.command(name="add-foreign-key")
@click.argument(
    "path",
    type=click.Path(exists=True, file_okay=True, dir_okay=False, allow_dash=False),
    required=True,
)
@click.argument("table")
@click.argument("column")
@click.argument("other_table", required=False)
@click.argument("other_column", required=False)
@click.option(
    "--ignore",
    is_flag=True,
    help="If foreign key already exists, do nothing",
)
@load_extension_option
def add_foreign_key(
    path, table, column, other_table, other_column, ignore, load_extension
):
    """
    Add a new foreign key constraint to an existing table. Example usage:

        $ sqlite-utils add-foreign-key my.db books author_id authors id

    WARNING: Could corrupt your database! Back up your database file first.
    """
    db = sqlite_utils.Database(path)
    _load_extensions(db, load_extension)
    try:
        db[table].add_foreign_key(column, other_table, other_column, ignore=ignore)
    except AlterError as e:
        raise click.ClickException(e)


@cli.command(name="add-foreign-keys")
@click.argument(
    "path",
    type=click.Path(exists=True, file_okay=True, dir_okay=False, allow_dash=False),
    required=True,
)
@click.argument("foreign_key", nargs=-1)
@load_extension_option
def add_foreign_keys(path, foreign_key, load_extension):
    """
    Add multiple new foreign key constraints to a database. Example usage:

    \b
    sqlite-utils add-foreign-keys my.db \\
        books author_id authors id \\
        authors country_id countries id
    """
    db = sqlite_utils.Database(path)
    _load_extensions(db, load_extension)
    if len(foreign_key) % 4 != 0:
        raise click.ClickException(
            "Each foreign key requires four values: table, column, other_table, other_column"
        )
    tuples = []
    for i in range(len(foreign_key) // 4):
        tuples.append(tuple(foreign_key[i * 4 : (i * 4) + 4]))
    try:
        db.add_foreign_keys(tuples)
    except AlterError as e:
        raise click.ClickException(e)


@cli.command(name="index-foreign-keys")
@click.argument(
    "path",
    type=click.Path(exists=True, file_okay=True, dir_okay=False, allow_dash=False),
    required=True,
)
@load_extension_option
def index_foreign_keys(path, load_extension):
    """
    Ensure every foreign key column has an index on it.
    """
    db = sqlite_utils.Database(path)
    _load_extensions(db, load_extension)
    db.index_foreign_keys()


@cli.command(name="create-index")
@click.argument(
    "path",
    type=click.Path(exists=True, file_okay=True, dir_okay=False, allow_dash=False),
    required=True,
)
@click.argument("table")
@click.argument("column", nargs=-1, required=True)
@click.option("--name", help="Explicit name for the new index")
@click.option("--unique", help="Make this a unique index", default=False, is_flag=True)
@click.option(
    "--if-not-exists",
    help="Ignore if index already exists",
    default=False,
    is_flag=True,
)
@load_extension_option
def create_index(path, table, column, name, unique, if_not_exists, load_extension):
    """
    Add an index to the specified table covering the specified columns.
    Use "sqlite-utils create-index mydb -- -column" to specify descending
    order for a column.
    """
    db = sqlite_utils.Database(path)
    _load_extensions(db, load_extension)
    # Treat -prefix as descending for columns
    columns = []
    for col in column:
        if col.startswith("-"):
            col = DescIndex(col[1:])
        columns.append(col)
    db[table].create_index(
        columns, index_name=name, unique=unique, if_not_exists=if_not_exists
    )


@cli.command(name="enable-fts")
@click.argument(
    "path",
    type=click.Path(exists=True, file_okay=True, dir_okay=False, allow_dash=False),
    required=True,
)
@click.argument("table")
@click.argument("column", nargs=-1, required=True)
@click.option("--fts4", help="Use FTS4", default=False, is_flag=True)
@click.option("--fts5", help="Use FTS5", default=False, is_flag=True)
@click.option("--tokenize", help="Tokenizer to use, e.g. porter")
@click.option(
    "--create-triggers",
    help="Create triggers to update the FTS tables when the parent table changes.",
    default=False,
    is_flag=True,
)
@load_extension_option
def enable_fts(
    path, table, column, fts4, fts5, tokenize, create_triggers, load_extension
):
    "Enable full-text search for specific table and columns"
    fts_version = "FTS5"
    if fts4 and fts5:
        click.echo("Can only use one of --fts4 or --fts5", err=True)
        return
    elif fts4:
        fts_version = "FTS4"

    db = sqlite_utils.Database(path)
    _load_extensions(db, load_extension)
    db[table].enable_fts(
        column,
        fts_version=fts_version,
        tokenize=tokenize,
        create_triggers=create_triggers,
    )


@cli.command(name="populate-fts")
@click.argument(
    "path",
    type=click.Path(exists=True, file_okay=True, dir_okay=False, allow_dash=False),
    required=True,
)
@click.argument("table")
@click.argument("column", nargs=-1, required=True)
@load_extension_option
def populate_fts(path, table, column, load_extension):
    "Re-populate full-text search for specific table and columns"
    db = sqlite_utils.Database(path)
    _load_extensions(db, load_extension)
    db[table].populate_fts(column)


@cli.command(name="disable-fts")
@click.argument(
    "path",
    type=click.Path(exists=True, file_okay=True, dir_okay=False, allow_dash=False),
    required=True,
)
@click.argument("table")
@load_extension_option
def disable_fts(path, table, load_extension):
    "Disable full-text search for specific table"
    db = sqlite_utils.Database(path)
    _load_extensions(db, load_extension)
    db[table].disable_fts()


@cli.command(name="enable-wal")
@click.argument(
    "path",
    nargs=-1,
    type=click.Path(exists=True, file_okay=True, dir_okay=False, allow_dash=False),
    required=True,
)
@load_extension_option
def enable_wal(path, load_extension):
    "Enable WAL for database files"
    for path_ in path:
        db = sqlite_utils.Database(path_)
        _load_extensions(db, load_extension)
        db.enable_wal()


@cli.command(name="disable-wal")
@click.argument(
    "path",
    nargs=-1,
    type=click.Path(exists=True, file_okay=True, dir_okay=False, allow_dash=False),
    required=True,
)
@load_extension_option
def disable_wal(path, load_extension):
    "Disable WAL for database files"
    for path_ in path:
        db = sqlite_utils.Database(path_)
        _load_extensions(db, load_extension)
        db.disable_wal()


@cli.command(name="enable-counts")
@click.argument(
    "path",
    type=click.Path(exists=True, file_okay=True, dir_okay=False, allow_dash=False),
    required=True,
)
@click.argument("tables", nargs=-1)
@load_extension_option
def enable_counts(path, tables, load_extension):
    "Configure triggers to update a _counts table with row counts"
    db = sqlite_utils.Database(path)
    _load_extensions(db, load_extension)
    if not tables:
        db.enable_counts()
    else:
        # Check all tables exist
        bad_tables = [table for table in tables if not db[table].exists()]
        if bad_tables:
            raise click.ClickException("Invalid tables: {}".format(bad_tables))
        for table in tables:
            db[table].enable_counts()


@cli.command(name="reset-counts")
@click.argument(
    "path",
    type=click.Path(exists=True, file_okay=True, dir_okay=False, allow_dash=False),
    required=True,
)
@load_extension_option
def reset_counts(path, load_extension):
    "Reset calculated counts in the _counts table"
    db = sqlite_utils.Database(path)
    _load_extensions(db, load_extension)
    db.reset_counts()


def insert_upsert_options(fn):
    for decorator in reversed(
        (
            click.argument(
                "path",
                type=click.Path(file_okay=True, dir_okay=False, allow_dash=False),
                required=True,
            ),
            click.argument("table"),
            click.argument("json_file", type=click.File("rb"), required=True),
            click.option(
                "--pk", help="Columns to use as the primary key, e.g. id", multiple=True
            ),
            click.option("--nl", is_flag=True, help="Expect newline-delimited JSON"),
            click.option("--flatten", is_flag=True, help="Flatten nested JSON objects"),
            click.option("-c", "--csv", is_flag=True, help="Expect CSV"),
            click.option("--tsv", is_flag=True, help="Expect TSV"),
            click.option("--delimiter", help="Delimiter to use for CSV files"),
            click.option("--quotechar", help="Quote character to use for CSV/TSV"),
            click.option(
                "--sniff", is_flag=True, help="Detect delimiter and quote character"
            ),
            click.option(
                "--no-headers", is_flag=True, help="CSV file has no header row"
            ),
            click.option(
                "--batch-size", type=int, default=100, help="Commit every X records"
            ),
            click.option(
                "--alter",
                is_flag=True,
                help="Alter existing table to add any missing columns",
            ),
            click.option(
                "--not-null",
                multiple=True,
                help="Columns that should be created as NOT NULL",
            ),
            click.option(
                "--default",
                multiple=True,
                type=(str, str),
                help="Default value that should be set for a column",
            ),
            click.option(
                "--encoding",
                help="Character encoding for input, defaults to utf-8",
            ),
            click.option(
                "-d",
                "--detect-types",
                is_flag=True,
                envvar="SQLITE_UTILS_DETECT_TYPES",
                help="Detect types for columns in CSV/TSV data",
            ),
            load_extension_option,
            click.option("--silent", is_flag=True, help="Do not show progress bar"),
        )
    ):
        fn = decorator(fn)
    return fn


def insert_upsert_implementation(
    path,
    table,
    json_file,
    pk,
    nl,
    flatten,
    csv,
    tsv,
    delimiter,
    quotechar,
    sniff,
    no_headers,
    batch_size,
    alter,
    upsert,
    ignore=False,
    replace=False,
    truncate=False,
    not_null=None,
    default=None,
    encoding=None,
    detect_types=None,
    load_extension=None,
    silent=False,
):
    db = sqlite_utils.Database(path)
    _load_extensions(db, load_extension)
    if (delimiter or quotechar or sniff or no_headers) and not tsv:
        csv = True
    if (nl + csv + tsv) >= 2:
        raise click.ClickException("Use just one of --nl, --csv or --tsv")
    if (csv or tsv) and flatten:
        raise click.ClickException("--flatten cannot be used with --csv or --tsv")
    if encoding and not (csv or tsv):
        raise click.ClickException("--encoding must be used with --csv or --tsv")
    if pk and len(pk) == 1:
        pk = pk[0]
    encoding = encoding or "utf-8-sig"
    buffered = io.BufferedReader(json_file, buffer_size=4096)
    decoded = io.TextIOWrapper(buffered, encoding=encoding)
    tracker = None
    if csv or tsv:
        if sniff:
            # Read first 2048 bytes and use that to detect
            first_bytes = buffered.peek(2048)
            dialect = csv_std.Sniffer().sniff(first_bytes.decode(encoding, "ignore"))
        else:
            dialect = "excel-tab" if tsv else "excel"
        with file_progress(decoded, silent=silent) as decoded:
            csv_reader_args = {"dialect": dialect}
            if delimiter:
                csv_reader_args["delimiter"] = delimiter
            if quotechar:
                csv_reader_args["quotechar"] = quotechar
            reader = csv_std.reader(decoded, **csv_reader_args)
            first_row = next(reader)
            if no_headers:
                headers = ["untitled_{}".format(i + 1) for i in range(len(first_row))]
                reader = itertools.chain([first_row], reader)
            else:
                headers = first_row
            docs = (dict(zip(headers, row)) for row in reader)
            if detect_types:
                tracker = TypeTracker()
                docs = tracker.wrap(docs)
    else:
        try:
            if nl:
                docs = (json.loads(line) for line in decoded)
            else:
                docs = json.load(decoded)
                if isinstance(docs, dict):
                    docs = [docs]
        except json.decoder.JSONDecodeError:
            raise click.ClickException(
                "Invalid JSON - use --csv for CSV or --tsv for TSV files"
            )
        if flatten:
            docs = (dict(_flatten(doc)) for doc in docs)

    extra_kwargs = {"ignore": ignore, "replace": replace, "truncate": truncate}
    if not_null:
        extra_kwargs["not_null"] = set(not_null)
    if default:
        extra_kwargs["defaults"] = dict(default)
    if upsert:
        extra_kwargs["upsert"] = upsert
    # Apply {"$base64": true, ...} decoding, if needed
    docs = (decode_base64_values(doc) for doc in docs)
    try:
        db[table].insert_all(
            docs, pk=pk, batch_size=batch_size, alter=alter, **extra_kwargs
        )
    except Exception as e:
        if (
            isinstance(e, sqlite3.OperationalError)
            and e.args
            and "has no column named" in e.args[0]
        ):
            raise click.ClickException(
                "{}\n\nTry using --alter to add additional columns".format(e.args[0])
            )
        # If we can find sql= and parameters= arguments, show those
        variables = _find_variables(e.__traceback__, ["sql", "parameters"])
        if "sql" in variables and "parameters" in variables:
            raise click.ClickException(
                "{}\n\nsql = {}\nparameters = {}".format(
                    str(e), variables["sql"], variables["parameters"]
                )
            )
        else:
            raise
    if tracker is not None:
        db[table].transform(types=tracker.types)


def _flatten(d):
    for key, value in d.items():
        if isinstance(value, dict):
            for key2, value2 in _flatten(value):
                yield key + "_" + key2, value2
        else:
            yield key, value


def _find_variables(tb, vars):
    to_find = list(vars)
    found = {}
    for var in to_find:
        if var in tb.tb_frame.f_locals:
            vars.remove(var)
            found[var] = tb.tb_frame.f_locals[var]
    if vars and tb.tb_next:
        found.update(_find_variables(tb.tb_next, vars))
    return found


@cli.command()
@insert_upsert_options
@click.option(
    "--ignore", is_flag=True, default=False, help="Ignore records if pk already exists"
)
@click.option(
    "--replace",
    is_flag=True,
    default=False,
    help="Replace records if pk already exists",
)
@click.option(
    "--truncate",
    is_flag=True,
    default=False,
    help="Truncate table before inserting records, if table already exists",
)
def insert(
    path,
    table,
    json_file,
    pk,
    nl,
    flatten,
    csv,
    tsv,
    delimiter,
    quotechar,
    sniff,
    no_headers,
    batch_size,
    alter,
    encoding,
    detect_types,
    load_extension,
    silent,
    ignore,
    replace,
    truncate,
    not_null,
    default,
):
    """
    Insert records from JSON file into a table, creating the table if it
    does not already exist.

    Input should be a JSON array of objects, unless --nl or --csv is used.
    """
    try:
        insert_upsert_implementation(
            path,
            table,
            json_file,
            pk,
            nl,
            flatten,
            csv,
            tsv,
            delimiter,
            quotechar,
            sniff,
            no_headers,
            batch_size,
            alter=alter,
            upsert=False,
            ignore=ignore,
            replace=replace,
            truncate=truncate,
            encoding=encoding,
            detect_types=detect_types,
            load_extension=load_extension,
            silent=silent,
            not_null=not_null,
            default=default,
        )
    except UnicodeDecodeError as ex:
        raise click.ClickException(UNICODE_ERROR.format(ex))


@cli.command()
@insert_upsert_options
def upsert(
    path,
    table,
    json_file,
    pk,
    nl,
    flatten,
    csv,
    tsv,
    batch_size,
    delimiter,
    quotechar,
    sniff,
    no_headers,
    alter,
    not_null,
    default,
    encoding,
    detect_types,
    load_extension,
    silent,
):
    """
    Upsert records based on their primary key. Works like 'insert' but if
    an incoming record has a primary key that matches an existing record
    the existing record will be updated.
    """
    try:
        insert_upsert_implementation(
            path,
            table,
            json_file,
            pk,
            nl,
            flatten,
            csv,
            tsv,
            delimiter,
            quotechar,
            sniff,
            no_headers,
            batch_size,
            alter=alter,
            upsert=True,
            not_null=not_null,
            default=default,
            encoding=encoding,
            load_extension=load_extension,
            silent=silent,
        )
    except UnicodeDecodeError as ex:
        raise click.ClickException(UNICODE_ERROR.format(ex))


@cli.command(name="create-table")
@click.argument(
    "path",
    type=click.Path(file_okay=True, dir_okay=False, allow_dash=False),
    required=True,
)
@click.argument("table")
@click.argument("columns", nargs=-1, required=True)
@click.option("--pk", help="Column to use as primary key")
@click.option(
    "--not-null",
    multiple=True,
    help="Columns that should be created as NOT NULL",
)
@click.option(
    "--default",
    multiple=True,
    type=(str, str),
    help="Default value that should be set for a column",
)
@click.option(
    "--fk",
    multiple=True,
    type=(str, str, str),
    help="Column, other table, other column to set as a foreign key",
)
@click.option(
    "--ignore",
    is_flag=True,
    help="If table already exists, do nothing",
)
@click.option(
    "--replace",
    is_flag=True,
    help="If table already exists, replace it",
)
@load_extension_option
def create_table(
    path, table, columns, pk, not_null, default, fk, ignore, replace, load_extension
):
    """
    Add a table with the specified columns. Columns should be specified using
    name, type pairs, for example:

    \b
    sqlite-utils create-table my.db people \\
        id integer \\
        name text \\
        height float \\
        photo blob --pk id
    """
    db = sqlite_utils.Database(path)
    _load_extensions(db, load_extension)
    if len(columns) % 2 == 1:
        raise click.ClickException(
            "columns must be an even number of 'name' 'type' pairs"
        )
    coltypes = {}
    columns = list(columns)
    while columns:
        name = columns.pop(0)
        ctype = columns.pop(0)
        if ctype.upper() not in VALID_COLUMN_TYPES:
            raise click.ClickException(
                "column types must be one of {}".format(VALID_COLUMN_TYPES)
            )
        coltypes[name] = ctype.upper()
    # Does table already exist?
    if table in db.table_names():
        if ignore:
            return
        elif replace:
            db[table].drop()
        else:
            raise click.ClickException(
                'Table "{}" already exists. Use --replace to delete and replace it.'.format(
                    table
                )
            )
    db[table].create(
        coltypes, pk=pk, not_null=not_null, defaults=dict(default), foreign_keys=fk
    )


@cli.command(name="drop-table")
@click.argument(
    "path",
    type=click.Path(file_okay=True, dir_okay=False, allow_dash=False),
    required=True,
)
@click.argument("table")
@click.option("--ignore", is_flag=True)
@load_extension_option
def drop_table(path, table, ignore, load_extension):
    "Drop the specified table"
    db = sqlite_utils.Database(path)
    _load_extensions(db, load_extension)
    try:
        db[table].drop(ignore=ignore)
    except sqlite3.OperationalError:
        raise click.ClickException('Table "{}" does not exist'.format(table))


@cli.command(name="create-view")
@click.argument(
    "path",
    type=click.Path(file_okay=True, dir_okay=False, allow_dash=False),
    required=True,
)
@click.argument("view")
@click.argument("select")
@click.option(
    "--ignore",
    is_flag=True,
    help="If view already exists, do nothing",
)
@click.option(
    "--replace",
    is_flag=True,
    help="If view already exists, replace it",
)
@load_extension_option
def create_view(path, view, select, ignore, replace, load_extension):
    "Create a view for the provided SELECT query"
    db = sqlite_utils.Database(path)
    _load_extensions(db, load_extension)
    # Does view already exist?
    if view in db.view_names():
        if ignore:
            return
        elif replace:
            db[view].drop()
        else:
            raise click.ClickException(
                'View "{}" already exists. Use --replace to delete and replace it.'.format(
                    view
                )
            )
    db.create_view(view, select)


@cli.command(name="drop-view")
@click.argument(
    "path",
    type=click.Path(file_okay=True, dir_okay=False, allow_dash=False),
    required=True,
)
@click.argument("view")
@click.option("--ignore", is_flag=True)
@load_extension_option
def drop_view(path, view, ignore, load_extension):
    "Drop the specified view"
    db = sqlite_utils.Database(path)
    _load_extensions(db, load_extension)
    try:
        db[view].drop(ignore=ignore)
    except sqlite3.OperationalError:
        raise click.ClickException('View "{}" does not exist'.format(view))


@cli.command()
@click.argument(
    "path",
    type=click.Path(file_okay=True, dir_okay=False, allow_dash=False),
    required=True,
)
@click.argument("sql")
@click.option(
    "--attach",
    type=(str, click.Path(file_okay=True, dir_okay=False, allow_dash=False)),
    multiple=True,
    help="Additional databases to attach - specify alias and filepath",
)
@output_options
@click.option("-r", "--raw", is_flag=True, help="Raw output, first column of first row")
@click.option(
    "-p",
    "--param",
    multiple=True,
    type=(str, str),
    help="Named :parameters for SQL query",
)
@load_extension_option
def query(
    path,
    sql,
    attach,
    nl,
    arrays,
    csv,
    tsv,
    no_headers,
    table,
    fmt,
    json_cols,
    raw,
    param,
    load_extension,
):
    "Execute SQL query and return the results as JSON"
    db = sqlite_utils.Database(path)
    for alias, attach_path in attach:
        db.attach(alias, attach_path)
    _load_extensions(db, load_extension)
    db.register_fts4_bm25()

    _execute_query(
        db, sql, param, raw, table, csv, tsv, no_headers, fmt, nl, arrays, json_cols
    )


@cli.command()
@click.argument(
    "paths",
    type=click.Path(file_okay=True, dir_okay=False, allow_dash=True),
    required=False,
    nargs=-1,
)
@click.argument("sql")
@click.option(
    "--attach",
    type=(str, click.Path(file_okay=True, dir_okay=False, allow_dash=False)),
    multiple=True,
    help="Additional databases to attach - specify alias and filepath",
)
@output_options
@click.option("-r", "--raw", is_flag=True, help="Raw output, first column of first row")
@click.option(
    "-p",
    "--param",
    multiple=True,
    type=(str, str),
    help="Named :parameters for SQL query",
)
@click.option(
    "--encoding",
    help="Character encoding for CSV input, defaults to utf-8",
)
@click.option(
    "-n",
    "--no-detect-types",
    is_flag=True,
    help="Treat all CSV/TSV columns as TEXT",
)
@click.option("--schema", is_flag=True, help="Show SQL schema for in-memory database")
@click.option("--dump", is_flag=True, help="Dump SQL for in-memory database")
@click.option(
    "--save",
    type=click.Path(file_okay=True, dir_okay=False, allow_dash=False),
    help="Save in-memory database to this file",
)
@click.option(
    "--analyze",
    is_flag=True,
    help="Analyze resulting tables and output results",
)
@load_extension_option
def memory(
    paths,
    sql,
    attach,
    nl,
    arrays,
    csv,
    tsv,
    no_headers,
    table,
    fmt,
    json_cols,
    raw,
    param,
    encoding,
    no_detect_types,
    schema,
    dump,
    save,
    analyze,
    load_extension,
):
    """Execute SQL query against an in-memory database, optionally populated by imported data

    To import data from CSV, TSV or JSON files pass them on the command-line:

    \b
        sqlite-utils memory one.csv two.json \\
            "select * from one join two on one.two_id = two.id"

    For data piped into the tool from standard input, use "-" or "stdin":

    \b
        cat animals.csv | sqlite-utils memory - \\
            "select * from stdin where species = 'dog'"

    The format of the data will be automatically detected. You can specify the format
    explicitly using :json, :csv, :tsv or :nl (for newline-delimited JSON) - for example:

    \b
        cat animals.csv | sqlite-utils memory stdin:csv places.dat:nl \\
            "select * from stdin where place_id in (select id from places)"

    Use --schema to view the SQL schema of any imported files:

    \b
        sqlite-utils memory animals.csv --schema
    """
    db = sqlite_utils.Database(memory=True)
    # If --dump or --save or --analyze used but no paths detected, assume SQL query is a path:
    if (dump or save or schema or analyze) and not paths:
        paths = [sql]
        sql = None
    for i, path in enumerate(paths):
        # Path may have a :format suffix
        if ":" in path and path.rsplit(":", 1)[-1].upper() in Format.__members__:
            path, suffix = path.rsplit(":", 1)
            format = Format[suffix.upper()]
        else:
            format = None
        if path in ("-", "stdin"):
            csv_fp = sys.stdin.buffer
            csv_table = "stdin"
        else:
            csv_path = pathlib.Path(path)
            csv_table = csv_path.stem
            csv_fp = csv_path.open("rb")
        rows, format_used = rows_from_file(csv_fp, format=format, encoding=encoding)
        tracker = None
        if format_used in (Format.CSV, Format.TSV) and not no_detect_types:
            tracker = TypeTracker()
            rows = tracker.wrap(rows)
        db[csv_table].insert_all(rows, alter=True)
        if tracker is not None:
            db[csv_table].transform(types=tracker.types)
        # Add convenient t / t1 / t2 views
        view_names = ["t{}".format(i + 1)]
        if i == 0:
            view_names.append("t")
        for view_name in view_names:
            if not db[view_name].exists():
                db.create_view(view_name, "select * from [{}]".format(csv_table))

    if analyze:
        _analyze(db, tables=None, columns=None, save=False)
        return

    if dump:
        for line in db.conn.iterdump():
            click.echo(line)
        return

    if schema:
        click.echo(db.schema)
        return

    if save:
        db2 = sqlite_utils.Database(save)
        for line in db.conn.iterdump():
            db2.execute(line)
        return

    for alias, attach_path in attach:
        db.attach(alias, attach_path)
    _load_extensions(db, load_extension)
    db.register_fts4_bm25()

    _execute_query(
        db, sql, param, raw, table, csv, tsv, no_headers, fmt, nl, arrays, json_cols
    )


def _execute_query(
    db, sql, param, raw, table, csv, tsv, no_headers, fmt, nl, arrays, json_cols
):
    with db.conn:
        try:
            cursor = db.execute(sql, dict(param))
        except sqlite3.OperationalError as e:
            raise click.ClickException(str(e))
        if cursor.description is None:
            # This was an update/insert
            headers = ["rows_affected"]
            cursor = [[cursor.rowcount]]
        else:
            headers = [c[0] for c in cursor.description]
        if raw:
            data = cursor.fetchone()[0]
            if isinstance(data, bytes):
                sys.stdout.buffer.write(data)
            else:
                sys.stdout.write(str(data))
        elif table:
            print(tabulate.tabulate(list(cursor), headers=headers, tablefmt=fmt))
        elif csv or tsv:
            writer = csv_std.writer(sys.stdout, dialect="excel-tab" if tsv else "excel")
            if not no_headers:
                writer.writerow(headers)
            for row in cursor:
                writer.writerow(row)
        else:
            for line in output_rows(cursor, headers, nl, arrays, json_cols):
                click.echo(line)


@cli.command()
@click.argument(
    "path",
    type=click.Path(file_okay=True, dir_okay=False, allow_dash=False),
    required=True,
)
@click.argument("dbtable")
@click.argument("q")
@click.option("-o", "--order", type=str, help="Order by ('column' or 'column desc')")
@click.option("-c", "--column", type=str, multiple=True, help="Columns to return")
@click.option(
    "--limit",
    type=int,
    help="Number of rows to return - defaults to everything",
)
@click.option(
    "--sql", "show_sql", is_flag=True, help="Show SQL query that would be run"
)
@click.option("--quote", is_flag=True, help="Apply FTS quoting rules to search term")
@output_options
@load_extension_option
@click.pass_context
def search(
    ctx,
    path,
    dbtable,
    q,
    order,
    show_sql,
    quote,
    column,
    limit,
    nl,
    arrays,
    csv,
    tsv,
    no_headers,
    table,
    fmt,
    json_cols,
    load_extension,
):
    "Execute a full-text search against this table"
    db = sqlite_utils.Database(path)
    _load_extensions(db, load_extension)
    # Check table exists
    table_obj = db[dbtable]
    if not table_obj.exists():
        raise click.ClickException("Table '{}' does not exist".format(dbtable))
    if not table_obj.detect_fts():
        raise click.ClickException(
            "Table '{}' is not configured for full-text search".format(dbtable)
        )
    if column:
        # Check they all exist
        table_columns = table_obj.columns_dict
        for c in column:
            if c not in table_columns:
                raise click.ClickException(
                    "Table '{}' has no column '{}".format(dbtable, c)
                )
    sql = table_obj.search_sql(columns=column, order_by=order, limit=limit)
    if show_sql:
        click.echo(sql)
        return
    if quote:
        q = db.quote_fts(q)
    try:
        ctx.invoke(
            query,
            path=path,
            sql=sql,
            nl=nl,
            arrays=arrays,
            csv=csv,
            tsv=tsv,
            no_headers=no_headers,
            table=table,
            fmt=fmt,
            json_cols=json_cols,
            param=[("query", q)],
            load_extension=load_extension,
        )
    except click.ClickException as e:
        if "malformed MATCH expression" in str(e) or "unterminated string" in str(e):
            raise click.ClickException(
                "{}\n\nTry running this again with the --quote option".format(str(e))
            )
        else:
            raise


@cli.command()
@click.argument(
    "path",
    type=click.Path(file_okay=True, dir_okay=False, allow_dash=False),
    required=True,
)
@click.argument("dbtable")
@click.option("-c", "--column", type=str, multiple=True, help="Columns to return")
@output_options
@load_extension_option
@click.pass_context
def rows(
    ctx,
    path,
    dbtable,
    column,
    nl,
    arrays,
    csv,
    tsv,
    no_headers,
    table,
    fmt,
    json_cols,
    load_extension,
):
    "Output all rows in the specified table"
    columns = "*"
    if column:
        columns = ", ".join("[{}]".format(c) for c in column)
    ctx.invoke(
        query,
        path=path,
        sql="select {} from [{}]".format(columns, dbtable),
        nl=nl,
        arrays=arrays,
        csv=csv,
        tsv=tsv,
        no_headers=no_headers,
        table=table,
        fmt=fmt,
        json_cols=json_cols,
        load_extension=load_extension,
    )


@cli.command()
@click.argument(
    "path",
    type=click.Path(file_okay=True, dir_okay=False, allow_dash=False),
    required=True,
)
@click.argument("tables", nargs=-1)
@output_options
@load_extension_option
@click.pass_context
def triggers(
    ctx,
    path,
    tables,
    nl,
    arrays,
    csv,
    tsv,
    no_headers,
    table,
    fmt,
    json_cols,
    load_extension,
):
    "Show triggers configured in this database"
    sql = "select name, tbl_name as [table], sql from sqlite_master where type = 'trigger'"
    if tables:
        quote = sqlite_utils.Database(memory=True).quote
        sql += " and [table] in ({})".format(
            ", ".join(quote(table) for table in tables)
        )
    ctx.invoke(
        query,
        path=path,
        sql=sql,
        nl=nl,
        arrays=arrays,
        csv=csv,
        tsv=tsv,
        no_headers=no_headers,
        table=table,
        fmt=fmt,
        json_cols=json_cols,
        load_extension=load_extension,
    )


@cli.command()
@click.argument(
    "path",
    type=click.Path(file_okay=True, dir_okay=False, allow_dash=False),
    required=True,
)
@click.argument("tables", nargs=-1)
@click.option("--aux", is_flag=True, help="Include auxiliary columns")
@output_options
@load_extension_option
@click.pass_context
def indexes(
    ctx,
    path,
    tables,
    aux,
    nl,
    arrays,
    csv,
    tsv,
    no_headers,
    table,
    fmt,
    json_cols,
    load_extension,
):
    "Show indexes for this database"
    sql = """
    select
      sqlite_master.name as "table",
      indexes.name as index_name,
      xinfo.*
    from sqlite_master
      join pragma_index_list(sqlite_master.name) indexes
      join pragma_index_xinfo(index_name) xinfo
    where
      sqlite_master.type = 'table'
    """
    if tables:
        quote = sqlite_utils.Database(memory=True).quote
        sql += " and sqlite_master.name in ({})".format(
            ", ".join(quote(table) for table in tables)
        )
    if not aux:
        sql += " and xinfo.key = 1"
    ctx.invoke(
        query,
        path=path,
        sql=sql,
        nl=nl,
        arrays=arrays,
        csv=csv,
        tsv=tsv,
        no_headers=no_headers,
        table=table,
        fmt=fmt,
        json_cols=json_cols,
        load_extension=load_extension,
    )


@cli.command()
@click.argument(
    "path",
    type=click.Path(file_okay=True, dir_okay=False, allow_dash=False),
    required=True,
)
@click.argument("tables", nargs=-1, required=False)
@load_extension_option
def schema(
    path,
    tables,
    load_extension,
):
    "Show full schema for this database or for specified tables"
    db = sqlite_utils.Database(path)
    _load_extensions(db, load_extension)
    if tables:
        for table in tables:
            click.echo(db[table].schema)
    else:
        click.echo(db.schema)


@cli.command()
@click.argument(
    "path",
    type=click.Path(file_okay=True, dir_okay=False, allow_dash=False),
    required=True,
)
@click.argument("table")
@click.option(
    "--type",
    type=(
        str,
        click.Choice(["INTEGER", "TEXT", "FLOAT", "BLOB"], case_sensitive=False),
    ),
    multiple=True,
    help="Change column type to INTEGER, TEXT, FLOAT or BLOB",
)
@click.option("--drop", type=str, multiple=True, help="Drop this column")
@click.option(
    "--rename", type=(str, str), multiple=True, help="Rename this column to X"
)
@click.option("-o", "--column-order", type=str, multiple=True, help="Reorder columns")
@click.option("--not-null", type=str, multiple=True, help="Set this column to NOT NULL")
@click.option(
    "--not-null-false", type=str, multiple=True, help="Remove NOT NULL from this column"
)
@click.option("--pk", type=str, multiple=True, help="Make this column the primary key")
@click.option(
    "--pk-none", is_flag=True, help="Remove primary key (convert to rowid table)"
)
@click.option(
    "--default",
    type=(str, str),
    multiple=True,
    help="Set default value for this column",
)
@click.option(
    "--default-none", type=str, multiple=True, help="Remove default from this column"
)
@click.option(
    "--drop-foreign-key",
    type=str,
    multiple=True,
    help="Drop this foreign key constraint",
)
@click.option("--sql", is_flag=True, help="Output SQL without executing it")
@load_extension_option
def transform(
    path,
    table,
    type,
    drop,
    rename,
    column_order,
    not_null,
    not_null_false,
    pk,
    pk_none,
    default,
    default_none,
    drop_foreign_key,
    sql,
    load_extension,
):
    "Transform a table beyond the capabilities of ALTER TABLE"
    db = sqlite_utils.Database(path)
    _load_extensions(db, load_extension)
    types = {}
    kwargs = {}
    for column, ctype in type:
        if ctype.upper() not in VALID_COLUMN_TYPES:
            raise click.ClickException(
                "column types must be one of {}".format(VALID_COLUMN_TYPES)
            )
        types[column] = ctype.upper()

    not_null_dict = {}
    for column in not_null:
        not_null_dict[column] = True
    for column in not_null_false:
        not_null_dict[column] = False

    default_dict = {}
    for column, value in default:
        default_dict[column] = value
    for column in default_none:
        default_dict[column] = None

    kwargs["types"] = types
    kwargs["drop"] = set(drop)
    kwargs["rename"] = dict(rename)
    kwargs["column_order"] = column_order or None
    kwargs["not_null"] = not_null_dict
    if pk:
        if len(pk) == 1:
            kwargs["pk"] = pk[0]
        else:
            kwargs["pk"] = pk
    elif pk_none:
        kwargs["pk"] = None
    kwargs["defaults"] = default_dict
    if drop_foreign_key:
        kwargs["drop_foreign_keys"] = drop_foreign_key

    if sql:
        for line in db[table].transform_sql(**kwargs):
            click.echo(line)
    else:
        db[table].transform(**kwargs)


@cli.command()
@click.argument(
    "path",
    type=click.Path(file_okay=True, dir_okay=False, allow_dash=False),
    required=True,
)
@click.argument("table")
@click.argument("columns", nargs=-1, required=True)
@click.option(
    "--table", "other_table", help="Name of the other table to extract columns to"
)
@click.option("--fk-column", help="Name of the foreign key column to add to the table")
@click.option(
    "--rename",
    type=(str, str),
    multiple=True,
    help="Rename this column in extracted table",
)
@load_extension_option
def extract(
    path,
    table,
    columns,
    other_table,
    fk_column,
    rename,
    load_extension,
):
    "Extract one or more columns into a separate table"
    db = sqlite_utils.Database(path)
    _load_extensions(db, load_extension)
    kwargs = dict(
        columns=columns,
        table=other_table,
        fk_column=fk_column,
        rename=dict(rename),
    )
    db[table].extract(**kwargs)


@cli.command(name="insert-files")
@click.argument(
    "path",
    type=click.Path(file_okay=True, dir_okay=False, allow_dash=False),
    required=True,
)
@click.argument("table")
@click.argument(
    "file_or_dir",
    nargs=-1,
    required=True,
    type=click.Path(file_okay=True, dir_okay=True, allow_dash=True),
)
@click.option(
    "-c",
    "--column",
    type=str,
    multiple=True,
    help="Column definitions for the table",
)
@click.option("--pk", type=str, help="Column to use as primary key")
@click.option("--alter", is_flag=True, help="Alter table to add missing columns")
@click.option("--replace", is_flag=True, help="Replace files with matching primary key")
@click.option("--upsert", is_flag=True, help="Upsert files with matching primary key")
@click.option("--name", type=str, help="File name to use")
@click.option("--text", is_flag=True, help="Store file content as TEXT, not BLOB")
@click.option(
    "--encoding",
    help="Character encoding for input, defaults to utf-8",
)
@click.option("-s", "--silent", is_flag=True, help="Don't show a progress bar")
@load_extension_option
def insert_files(
    path,
    table,
    file_or_dir,
    column,
    pk,
    alter,
    replace,
    upsert,
    name,
    text,
    encoding,
    silent,
    load_extension,
):
    """
    Insert one or more files using BLOB columns in the specified table

    Example usage:

    \b
    sqlite-utils insert-files pics.db images *.gif \\
        -c name:name \\
        -c content:content \\
        -c content_hash:sha256 \\
        -c created:ctime_iso \\
        -c modified:mtime_iso \\
        -c size:size \\
        --pk name
    """
    if not column:
        if text:
            column = ["path:path", "content_text:content_text", "size:size"]
        else:
            column = ["path:path", "content:content", "size:size"]
        if not pk:
            pk = "path"

    def yield_paths_and_relative_paths():
        for f_or_d in file_or_dir:
            path = pathlib.Path(f_or_d)
            if f_or_d == "-":
                yield "-", "-"
            elif path.is_dir():
                for subpath in path.rglob("*"):
                    if subpath.is_file():
                        yield subpath, subpath.relative_to(path)
            elif path.is_file():
                yield path, path

    # Load all paths so we can show a progress bar
    paths_and_relative_paths = list(yield_paths_and_relative_paths())

    with progressbar(paths_and_relative_paths, silent=silent) as bar:

        def to_insert():
            for path, relative_path in bar:
                row = {}
                # content_text is special case as it considers 'encoding'

                def _content_text(p):
                    resolved = p.resolve()
                    try:
                        return resolved.read_text(encoding=encoding)
                    except UnicodeDecodeError as e:
                        raise UnicodeDecodeErrorForPath(e, resolved)

                lookups = dict(FILE_COLUMNS, content_text=_content_text)
                if path == "-":
                    stdin_data = sys.stdin.buffer.read()
                    # We only support a subset of columns for this case
                    lookups = {
                        "name": lambda p: name or "-",
                        "path": lambda p: name or "-",
                        "content": lambda p: stdin_data,
                        "content_text": lambda p: stdin_data.decode(
                            encoding or "utf-8"
                        ),
                        "sha256": lambda p: hashlib.sha256(stdin_data).hexdigest(),
                        "md5": lambda p: hashlib.md5(stdin_data).hexdigest(),
                        "size": lambda p: len(stdin_data),
                    }
                for coldef in column:
                    if ":" in coldef:
                        colname, coltype = coldef.rsplit(":", 1)
                    else:
                        colname, coltype = coldef, coldef
                    try:
                        value = lookups[coltype](path)
                        row[colname] = value
                    except KeyError:
                        raise click.ClickException(
                            "'{}' is not a valid column definition - options are {}".format(
                                coltype, ", ".join(lookups.keys())
                            )
                        )
                    # Special case for --name
                    if coltype == "name" and name:
                        row[colname] = name
                yield row

        db = sqlite_utils.Database(path)
        _load_extensions(db, load_extension)
        try:
            with db.conn:
                db[table].insert_all(
                    to_insert(), pk=pk, alter=alter, replace=replace, upsert=upsert
                )
        except UnicodeDecodeErrorForPath as e:
            raise click.ClickException(
                UNICODE_ERROR.format(
                    "Could not read file '{}' as text\n\n{}".format(e.path, e.exception)
                )
            )


@cli.command(name="analyze-tables")
@click.argument(
    "path",
    type=click.Path(file_okay=True, dir_okay=False, allow_dash=False, exists=True),
    required=True,
)
@click.argument("tables", nargs=-1)
@click.option(
    "-c",
    "--column",
    "columns",
    type=str,
    multiple=True,
    help="Specific columns to analyze",
)
@click.option("--save", is_flag=True, help="Save results to _analyze_tables table")
@load_extension_option
def analyze_tables(
    path,
    tables,
    columns,
    save,
    load_extension,
):
    "Analyze the columns in one or more tables"
    db = sqlite_utils.Database(path)
    _load_extensions(db, load_extension)
    _analyze(db, tables, columns, save)


def _analyze(db, tables, columns, save):
    if not tables:
        tables = db.table_names()
    todo = []
    table_counts = {}
    for table in tables:
        table_counts[table] = db[table].count
        for column in db[table].columns:
            if not columns or column.name in columns:
                todo.append((table, column.name))
    # Now we now how many we need to do
    for i, (table, column) in enumerate(todo):
        column_details = db[table].analyze_column(
            column, total_rows=table_counts[table], value_truncate=80
        )
        if save:
            db["_analyze_tables_"].insert(
                column_details._asdict(), pk=("table", "column"), replace=True
            )
        most_common_rendered = _render_common(
            "\n\n  Most common:", column_details.most_common
        )
        least_common_rendered = _render_common(
            "\n\n  Least common:", column_details.least_common
        )
        details = (
            (
                textwrap.dedent(
                    """
        {table}.{column}: ({i}/{total})

          Total rows: {total_rows}
          Null rows: {num_null}
          Blank rows: {num_blank}

          Distinct values: {num_distinct}{most_common_rendered}{least_common_rendered}
        """
                )
                .strip()
                .format(
                    i=i + 1,
                    total=len(todo),
                    most_common_rendered=most_common_rendered,
                    least_common_rendered=least_common_rendered,
                    **column_details._asdict()
                )
            )
            + "\n"
        )
        click.echo(details)


def _generate_convert_help():
    help = textwrap.dedent(
        """
    Convert columns using Python code you supply. For example:

    \b
    $ sqlite-utils convert my.db mytable mycolumn \\
        '"\\n".join(textwrap.wrap(value, 10))' \\
        --import=textwrap

    "value" is a variable with the column value to be converted.

    The following common operations are available as recipe functions:
    """
    ).strip()
    recipe_names = [
        n for n in dir(recipes) if not n.startswith("_") and n not in ("json", "parser")
    ]
    for name in recipe_names:
        fn = getattr(recipes, name)
        help += "\n\nr.{}{}\n\n  {}".format(
            name, str(inspect.signature(fn)), fn.__doc__
        )
    help += "\n\n"
    help += textwrap.dedent(
        """
    You can use these recipes like so:

    \b
    $ sqlite-utils convert my.db mytable mycolumn \\
        'r.jsonsplit(value, delimiter=":")'
    """
    ).strip()
    return help


@cli.command(help=_generate_convert_help())
@click.argument(
    "db_path",
    type=click.Path(file_okay=True, dir_okay=False, allow_dash=False),
    required=True,
)
@click.argument("table", type=str)
@click.argument("columns", type=str, nargs=-1, required=True)
@click.argument("code", type=str)
@click.option(
    "--import", "imports", type=str, multiple=True, help="Python modules to import"
)
@click.option(
    "--dry-run", is_flag=True, help="Show results of running this against first 10 rows"
)
@click.option(
    "--multi", is_flag=True, help="Populate columns for keys in returned dictionary"
)
@click.option("--where", help="Optional where clause")
@click.option(
    "-p",
    "--param",
    multiple=True,
    type=(str, str),
    help="Named :parameters for where clause",
)
@click.option("--output", help="Optional separate column to populate with the output")
@click.option(
    "--output-type",
    help="Column type to use for the output column",
    default="text",
    type=click.Choice(["integer", "float", "blob", "text"]),
)
@click.option("--drop", is_flag=True, help="Drop original column afterwards")
@click.option("-s", "--silent", is_flag=True, help="Don't show a progress bar")
def convert(
    db_path,
    table,
    columns,
    code,
    imports,
    dry_run,
    multi,
    where,
    param,
    output,
    output_type,
    drop,
    silent,
):
    sqlite3.enable_callback_tracebacks(True)
    db = sqlite_utils.Database(db_path)
    if output is not None and len(columns) > 1:
        raise click.ClickException("Cannot use --output with more than one column")
    if multi and len(columns) > 1:
        raise click.ClickException("Cannot use --multi with more than one column")
    if drop and not (output or multi):
        raise click.ClickException("--drop can only be used with --output or --multi")
    # If single line and no 'return', add the return
    if "\n" not in code and not code.strip().startswith("return "):
        code = "return {}".format(code)
    where_args = dict(param) if param else []
    # Compile the code into a function body called fn(value)
    new_code = ["def fn(value):"]
    for line in code.split("\n"):
        new_code.append("    {}".format(line))
    code_o = compile("\n".join(new_code), "<string>", "exec")
    locals = {}
    globals = {"r": recipes, "recipes": recipes}
    for import_ in imports:
        globals[import_] = __import__(import_)
    exec(code_o, globals, locals)
    fn = locals["fn"]
    if dry_run:
        # Pull first 20 values for first column and preview them
        db.conn.create_function("preview_transform", 1, lambda v: fn(v) if v else v)
        sql = """
            select
                [{column}] as value,
                preview_transform([{column}]) as preview
            from [{table}]{where} limit 10
        """.format(
            column=columns[0],
            table=table,
            where=" where {}".format(where) if where is not None else "",
        )
        for row in db.conn.execute(sql, where_args).fetchall():
            click.echo(str(row[0]))
            click.echo(" --- becomes:")
            click.echo(str(row[1]))
            click.echo()
        count = db[table].count_where(
            where=where,
            where_args=where_args,
        )
        click.echo("Would affect {} row{}".format(count, "" if count == 1 else "s"))
    else:
        try:
            db[table].convert(
                columns,
                fn,
                where=where,
                where_args=where_args,
                output=output,
                output_type=output_type,
                drop=drop,
                multi=multi,
                show_progress=not silent,
            )
        except BadMultiValues as e:
            raise click.ClickException(
                "When using --multi code must return a Python dictionary - returned: {}".format(
                    repr(e.values)
                )
            )


def _render_common(title, values):
    if values is None:
        return ""
    lines = [title]
    for value, count in values:
        lines.append("    {}: {}".format(count, value))
    return "\n".join(lines)


class UnicodeDecodeErrorForPath(Exception):
    def __init__(self, exception, path):
        self.exception = exception
        self.path = path


FILE_COLUMNS = {
    "name": lambda p: p.name,
    "path": lambda p: str(p),
    "fullpath": lambda p: str(p.resolve()),
    "sha256": lambda p: hashlib.sha256(p.resolve().read_bytes()).hexdigest(),
    "md5": lambda p: hashlib.md5(p.resolve().read_bytes()).hexdigest(),
    "mode": lambda p: p.stat().st_mode,
    "content": lambda p: p.resolve().read_bytes(),
    "mtime": lambda p: p.stat().st_mtime,
    "ctime": lambda p: p.stat().st_ctime,
    "mtime_int": lambda p: int(p.stat().st_mtime),
    "ctime_int": lambda p: int(p.stat().st_ctime),
    "mtime_iso": lambda p: datetime.utcfromtimestamp(p.stat().st_mtime).isoformat(),
    "ctime_iso": lambda p: datetime.utcfromtimestamp(p.stat().st_ctime).isoformat(),
    "size": lambda p: p.stat().st_size,
}


def output_rows(iterator, headers, nl, arrays, json_cols):
    # We have to iterate two-at-a-time so we can know if we
    # should output a trailing comma or if we have reached
    # the last row.
    current_iter, next_iter = itertools.tee(iterator, 2)
    next(next_iter, None)
    first = True
    for row, next_row in itertools.zip_longest(current_iter, next_iter):
        is_last = next_row is None
        data = row
        if json_cols:
            # Any value that is a valid JSON string should be treated as JSON
            data = [maybe_json(value) for value in data]
        if not arrays:
            data = dict(zip(headers, data))
        line = "{firstchar}{serialized}{maybecomma}{lastchar}".format(
            firstchar=("[" if first else " ") if not nl else "",
            serialized=json.dumps(data, default=json_binary),
            maybecomma="," if (not nl and not is_last) else "",
            lastchar="]" if (is_last and not nl) else "",
        )
        yield line
        first = False


def maybe_json(value):
    if not isinstance(value, str):
        return value
    stripped = value.strip()
    if not (stripped.startswith("{") or stripped.startswith("[")):
        return value
    try:
        return json.loads(stripped)
    except ValueError:
        return value


def json_binary(value):
    if isinstance(value, bytes):
        return {"$base64": True, "encoded": base64.b64encode(value).decode("latin-1")}
    else:
        raise TypeError


def _load_extensions(db, load_extension):
    if load_extension:
        db.conn.enable_load_extension(True)
        for ext in load_extension:
            if ext == "spatialite" and not os.path.exists(ext):
                ext = find_spatialite()
            db.conn.load_extension(ext)
