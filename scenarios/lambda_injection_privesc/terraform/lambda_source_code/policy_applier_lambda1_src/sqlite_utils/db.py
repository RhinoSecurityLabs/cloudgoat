from .utils import (
    sqlite3,
    OperationalError,
    suggest_column_types,
    types_for_column_types,
    column_affinity,
    progressbar,
)
from collections import namedtuple
from collections.abc import Mapping
import contextlib
import datetime
import decimal
import hashlib
import inspect
import itertools
import json
import os
import pathlib
import re
from sqlite_fts4 import rank_bm25  # type: ignore
import sys
import textwrap
from typing import (
    cast,
    Any,
    Callable,
    Dict,
    Generator,
    Iterable,
    Union,
    Optional,
    List,
    Set,
    Tuple,
)
import uuid

SQLITE_MAX_VARS = 999

_quote_fts_re = re.compile(r'\s+|(".*?")')

_virtual_table_using_re = re.compile(
    r"""
^ # Start of string
\s*CREATE\s+VIRTUAL\s+TABLE\s+ # CREATE VIRTUAL TABLE
(
    '(?P<squoted_table>[^']*(?:''[^']*)*)' | # single quoted name
    "(?P<dquoted_table>[^"]*(?:""[^"]*)*)" | # double quoted name
    `(?P<backtick_table>[^`]+)`            | # `backtick` quoted name
    \[(?P<squarequoted_table>[^\]]+)\]     | # [...] quoted name
    (?P<identifier>                          # SQLite non-quoted identifier
        [A-Za-z_\u0080-\uffff]  # \u0080-\uffff = "any character larger than u007f"
        [A-Za-z_\u0080-\uffff0-9\$]* # zero-or-more alphanemuric or $
    )
)
\s+(IF\s+NOT\s+EXISTS\s+)?      # IF NOT EXISTS (optional)
USING\s+(?P<using>\w+)          # for example USING FTS5
""",
    re.VERBOSE | re.IGNORECASE,
)

try:
    import pandas as pd  # type: ignore
except ImportError:
    pd = None  # type: ignore

try:
    import numpy as np  # type: ignore
except ImportError:
    np = None  # type: ignore

Column = namedtuple(
    "Column", ("cid", "name", "type", "notnull", "default_value", "is_pk")
)
Column.__doc__ = """
Describes a SQLite column returned by the  :attr:`.Table.columns` property.

``cid``
    Column index

``name``
    Column name

``type``
    Column type

``notnull``
    Does the column have a ``not null`` constraint

``default_value``
    Default value for this column

``is_pk``
    Is this column part of the primary key
"""

ColumnDetails = namedtuple(
    "ColumnDetails",
    (
        "table",
        "column",
        "total_rows",
        "num_null",
        "num_blank",
        "num_distinct",
        "most_common",
        "least_common",
    ),
)
ColumnDetails.__doc__ = """
Summary information about a column, see :ref:`python_api_analyze_column`.

``table``
    The name of the table

``column``
    The name of the column

``total_rows``
    The total number of rows in the table

``num_null``
    The number of rows for which this column is null

``num_blank``
    The number of rows for which this column is blank (the empty string)

``num_distinct``
    The number of distinct values in this column

``most_common``
    The ``N`` most common values as a list of ``(value, count)`` tuples, or ``None`` if the table consists entirely of distinct values

``least_common``
    The ``N`` least common values as a list of ``(value, count)`` tuples, or ``None`` if the table is entirely distinct
    or if the number of distinct values is less than N (since they will already have been returned in ``most_common``)
"""
ForeignKey = namedtuple(
    "ForeignKey", ("table", "column", "other_table", "other_column")
)
Index = namedtuple("Index", ("seq", "name", "unique", "origin", "partial", "columns"))
XIndex = namedtuple("XIndex", ("name", "columns"))
XIndexColumn = namedtuple(
    "XIndexColumn", ("seqno", "cid", "name", "desc", "coll", "key")
)
Trigger = namedtuple("Trigger", ("name", "table", "sql"))


ForeignKeysType = Union[
    Iterable[str],
    Iterable[ForeignKey],
    Iterable[Tuple[str, str]],
    Iterable[Tuple[str, str, str]],
    Iterable[Tuple[str, str, str, str]],
]


class Default:
    pass


DEFAULT = Default()

COLUMN_TYPE_MAPPING = {
    float: "FLOAT",
    int: "INTEGER",
    bool: "INTEGER",
    str: "TEXT",
    bytes.__class__: "BLOB",
    bytes: "BLOB",
    memoryview: "BLOB",
    datetime.datetime: "TEXT",
    datetime.date: "TEXT",
    datetime.time: "TEXT",
    decimal.Decimal: "FLOAT",
    None.__class__: "TEXT",
    uuid.UUID: "TEXT",
    # SQLite explicit types
    "TEXT": "TEXT",
    "INTEGER": "INTEGER",
    "FLOAT": "FLOAT",
    "BLOB": "BLOB",
    "text": "TEXT",
    "integer": "INTEGER",
    "float": "FLOAT",
    "blob": "BLOB",
}
# If numpy is available, add more types
if np:
    COLUMN_TYPE_MAPPING.update(
        {
            np.int8: "INTEGER",
            np.int16: "INTEGER",
            np.int32: "INTEGER",
            np.int64: "INTEGER",
            np.uint8: "INTEGER",
            np.uint16: "INTEGER",
            np.uint32: "INTEGER",
            np.uint64: "INTEGER",
            np.float16: "FLOAT",
            np.float32: "FLOAT",
            np.float64: "FLOAT",
        }
    )

# If pandas is available, add more types
if pd:
    COLUMN_TYPE_MAPPING.update({pd.Timestamp: "TEXT"})  # type: ignore


class AlterError(Exception):
    "Error altering table"
    pass


class NoObviousTable(Exception):
    "Could not tell which table this operation refers to"
    pass


class BadPrimaryKey(Exception):
    "Table does not have a single obvious primary key"
    pass


class NotFoundError(Exception):
    "Record not found"
    pass


class PrimaryKeyRequired(Exception):
    "Primary key needs to be specified"
    pass


class InvalidColumns(Exception):
    "Specified columns do not exist"
    pass


class DescIndex(str):
    pass


class BadMultiValues(Exception):
    "With multi=True code must return a Python dictionary"

    def __init__(self, values):
        self.values = values


_COUNTS_TABLE_CREATE_SQL = """
CREATE TABLE IF NOT EXISTS [{}](
   [table] TEXT PRIMARY KEY,
   count INTEGER DEFAULT 0
);
""".strip()


class Database:
    """
    Wrapper for a SQLite database connection that adds a variety of useful utility methods.

    To create an instance::

        # create data.db file, or open existing:
        db = Database("data.db")
        # Create an in-memory database:
        dB = Database(memory=True)

    - ``filename_or_conn`` - String path to a file, or a ``pathlib.Path`` object, or a
      ``sqlite3`` connection
    - ``memory`` - set to ``True`` to create an in-memory database
    - ``recreate`` - set to ``True`` to delete and recreate a file database (**dangerous**)
    - ``recursive_triggers`` - defaults to ``True``, which sets ``PRAGMA recursive_triggers=on;`` -
      set to ``False`` to avoid setting this pragma
    - ``tracer`` - set a tracer function (``print`` works for this) which will be called with
      ``sql, parameters`` every time a SQL query is executed
    - ``use_counts_table`` - set to ``True`` to use a cached counts table, if available. See
      :ref:`python_api_cached_table_counts`.
    """

    _counts_table_name = "_counts"
    use_counts_table = False

    def __init__(
        self,
        filename_or_conn: Union[str, pathlib.Path, sqlite3.Connection] = None,
        memory: bool = False,
        recreate: bool = False,
        recursive_triggers: bool = True,
        tracer: Callable = None,
        use_counts_table: bool = False,
    ):
        assert (filename_or_conn is not None and not memory) or (
            filename_or_conn is None and memory
        ), "Either specify a filename_or_conn or pass memory=True"
        if memory or filename_or_conn == ":memory:":
            self.conn = sqlite3.connect(":memory:")
        elif isinstance(filename_or_conn, (str, pathlib.Path)):
            if recreate and os.path.exists(filename_or_conn):
                os.remove(filename_or_conn)
            self.conn = sqlite3.connect(str(filename_or_conn))
        else:
            assert not recreate, "recreate cannot be used with connections, only paths"
            self.conn = filename_or_conn
        self._tracer = tracer
        if recursive_triggers:
            self.execute("PRAGMA recursive_triggers=on;")
        self._registered_functions: set = set()
        self.use_counts_table = use_counts_table

    @contextlib.contextmanager
    def tracer(self, tracer: Callable = None):
        """
        Context manager to temporarily set a tracer function - all executed SQL queries will
        be passed to this.

        The tracer function should accept two arguments: ``sql`` and ``parameters``

        Example usage::

            with db.tracer(print):
                db["creatures"].insert({"name": "Cleo"})

        See :ref:`python_api_tracing`.
        """
        prev_tracer = self._tracer
        self._tracer = tracer or print
        try:
            yield self
        finally:
            self._tracer = prev_tracer

    def __getitem__(self, table_name: str) -> Union["Table", "View"]:
        """
        ``db[table_name]`` returns a :class:`.Table` object for the table with the specified name.
        If the table does not exist yet it will be created the first time data is inserted into it.
        """
        return self.table(table_name)

    def __repr__(self) -> str:
        return "<Database {}>".format(self.conn)

    def register_function(
        self, fn: Callable = None, deterministic: bool = False, replace: bool = False
    ):
        """
        ``fn`` will be made available as a function within SQL, with the same name and number
        of arguments. Can be used as a decorator::

            @db.register
            def upper(value):
                return str(value).upper()

        The decorator can take arguments::

            @db.register(deterministic=True, replace=True)
            def upper(value):
                return str(value).upper()

        - ``deterministic`` - set ``True`` for functions that always returns the same output for a given input
        - ``replace`` - set ``True`` to replace an existing function with the same name - otherwise throw an error

        See :ref:`python_api_register_function`.
        """

        def register(fn):
            name = fn.__name__
            arity = len(inspect.signature(fn).parameters)
            if not replace and (name, arity) in self._registered_functions:
                return fn
            kwargs = {}
            if deterministic and sys.version_info >= (3, 8):
                kwargs["deterministic"] = True
            self.conn.create_function(name, arity, fn, **kwargs)
            self._registered_functions.add((name, arity))
            return fn

        if fn is None:
            return register
        else:
            register(fn)

    def register_fts4_bm25(self):
        "Register the ``rank_bm25(match_info)`` function used for calculating relevance with SQLite FTS4."
        self.register_function(rank_bm25, deterministic=True)

    def attach(self, alias: str, filepath: Union[str, pathlib.Path]):
        """
        Attach another SQLite database file to this connection with the specified alias, equivalent to::

            ATTACH DATABASE 'filepath.db' AS alias
        """
        attach_sql = """
            ATTACH DATABASE '{}' AS [{}];
        """.format(
            str(pathlib.Path(filepath).resolve()), alias
        ).strip()
        self.execute(attach_sql)

    def query(
        self, sql: str, params: Optional[Union[Iterable, dict]] = None
    ) -> Generator[dict, None, None]:
        "Execute ``sql`` and return an iterable of dictionaries representing each row."
        cursor = self.execute(sql, params or tuple())
        keys = [d[0] for d in cursor.description]
        for row in cursor:
            yield dict(zip(keys, row))

    def execute(
        self, sql: str, parameters: Optional[Union[Iterable, dict]] = None
    ) -> sqlite3.Cursor:
        "Execute SQL query and return a ``sqlite3.Cursor``."
        if self._tracer:
            self._tracer(sql, parameters)
        if parameters is not None:
            return self.conn.execute(sql, parameters)
        else:
            return self.conn.execute(sql)

    def executescript(self, sql: str) -> sqlite3.Cursor:
        "Execute multiple SQL statements separated by ; and return the ``sqlite3.Cursor``."
        if self._tracer:
            self._tracer(sql, None)
        return self.conn.executescript(sql)

    def table(self, table_name: str, **kwargs) -> Union["Table", "View"]:
        "Return a table object, optionally configured with default options."
        klass = View if table_name in self.view_names() else Table
        return klass(self, table_name, **kwargs)

    def quote(self, value: str) -> str:
        "Apply SQLite string quoting to a value, including wrappping it in single quotes."
        # Normally we would use .execute(sql, [params]) for escaping, but
        # occasionally that isn't available - most notable when we need
        # to include a "... DEFAULT 'value'" in a column definition.
        return self.execute(
            # Use SQLite itself to correctly escape this string:
            "SELECT quote(:value)",
            {"value": value},
        ).fetchone()[0]

    def quote_fts(self, query: str) -> str:
        "Escape special characters in a SQLite full-text search query"
        # NOTE: This is not a query validator for FTS. Sqlite has
        # a well defined query syntax here:
        # https://www2.sqlite.org/fts5.html#full_text_query_syntax
        # but this function just aggressively quotes strings
        # to ensure that they are valid. In particular, passing
        # queries which make use of the query syntax will be incorrect,
        # e.g 'NEAR(one, two, 3)'.

        # If query has unbalanced ", add one at end
        if query.count('"') % 2:
            query += '"'
        bits = _quote_fts_re.split(query)
        bits = [b for b in bits if b and b != '""']
        return " ".join(
            '"{}"'.format(bit) if not bit.startswith('"') else bit for bit in bits
        )

    def table_names(self, fts4: bool = False, fts5: bool = False) -> List[str]:
        "A list of string table names in this database."
        where = ["type = 'table'"]
        if fts4:
            where.append("sql like '%USING FTS4%'")
        if fts5:
            where.append("sql like '%USING FTS5%'")
        sql = "select name from sqlite_master where {}".format(" AND ".join(where))
        return [r[0] for r in self.execute(sql).fetchall()]

    def view_names(self) -> List[str]:
        "A list of string view names in this database."
        return [
            r[0]
            for r in self.execute(
                "select name from sqlite_master where type = 'view'"
            ).fetchall()
        ]

    @property
    def tables(self) -> List["Table"]:
        "A list of Table objects in this database."
        return cast(List["Table"], [self[name] for name in self.table_names()])

    @property
    def views(self) -> List["View"]:
        "A list of View objects in this database."
        return cast(List["View"], [self[name] for name in self.view_names()])

    @property
    def triggers(self) -> List[Trigger]:
        "A list of ``(name, table_name, sql)`` tuples representing triggers in this database."
        return [
            Trigger(*r)
            for r in self.execute(
                "select name, tbl_name, sql from sqlite_master where type = 'trigger'"
            ).fetchall()
        ]

    @property
    def triggers_dict(self) -> Dict[str, str]:
        "A ``{trigger_name: sql}`` dictionary of triggers in this database."
        return {trigger.name: trigger.sql for trigger in self.triggers}

    @property
    def schema(self) -> str:
        "SQL schema for this database"
        sqls = []
        for row in self.execute(
            "select sql from sqlite_master where sql is not null"
        ).fetchall():
            sql = row[0]
            if not sql.strip().endswith(";"):
                sql += ";"
            sqls.append(sql)
        return "\n".join(sqls)

    @property
    def journal_mode(self) -> str:
        "Current ``journal_mode`` of this database."
        return self.execute("PRAGMA journal_mode;").fetchone()[0]

    def enable_wal(self):
        "Set ``journal_mode`` to ``'wal'`` to enable Write-Ahead Log mode."
        if self.journal_mode != "wal":
            self.execute("PRAGMA journal_mode=wal;")

    def disable_wal(self):
        "Set ``journal_mode`` back to ``'delete'`` to disable Write-Ahead Log mode."
        if self.journal_mode != "delete":
            self.execute("PRAGMA journal_mode=delete;")

    def _ensure_counts_table(self):
        with self.conn:
            self.execute(_COUNTS_TABLE_CREATE_SQL.format(self._counts_table_name))

    def enable_counts(self):
        """
        Enable trigger-based count caching for every table in the database, see
        :ref:`python_api_cached_table_counts`.
        """
        self._ensure_counts_table()
        for table in self.tables:
            if (
                table.virtual_table_using is None
                and table.name != self._counts_table_name
            ):
                table.enable_counts()
        self.use_counts_table = True

    def cached_counts(self, tables: Optional[Iterable[str]] = None) -> Dict[str, int]:
        """
        Return ``{table_name: count}`` dictionary of cached counts for specified tables, or
        all tables if ``tables`` not provided.
        """
        sql = "select [table], count from {}".format(self._counts_table_name)
        if tables:
            sql += " where [table] in ({})".format(", ".join("?" for table in tables))
        try:
            return {r[0]: r[1] for r in self.execute(sql, tables).fetchall()}
        except OperationalError:
            return {}

    def reset_counts(self):
        "Re-calculate cached counts for tables."
        tables = [table for table in self.tables if table.has_counts_triggers]
        with self.conn:
            self._ensure_counts_table()
            counts_table = self[self._counts_table_name]
            counts_table.delete_where()
            counts_table.insert_all(
                {"table": table.name, "count": table.execute_count()}
                for table in tables
            )

    def execute_returning_dicts(
        self, sql: str, params: Optional[Union[Iterable, dict]] = None
    ) -> List[dict]:
        return list(self.query(sql, params))

    def resolve_foreign_keys(
        self, name: str, foreign_keys: ForeignKeysType
    ) -> List[ForeignKey]:
        # foreign_keys may be a list of column names, a list of ForeignKey tuples,
        # a list of tuple-pairs or a list of tuple-triples. We want to turn
        # it into a list of ForeignKey tuples
        table = cast(Table, self[name])
        if all(isinstance(fk, ForeignKey) for fk in foreign_keys):
            return cast(List[ForeignKey], foreign_keys)
        if all(isinstance(fk, str) for fk in foreign_keys):
            # It's a list of columns
            fks = []
            for column in foreign_keys:
                column = cast(str, column)
                other_table = table.guess_foreign_table(column)
                other_column = table.guess_foreign_column(other_table)
                fks.append(ForeignKey(name, column, other_table, other_column))
            return fks
        assert all(
            isinstance(fk, (tuple, list)) for fk in foreign_keys
        ), "foreign_keys= should be a list of tuples"
        fks = []
        for tuple_or_list in foreign_keys:
            assert len(tuple_or_list) in (
                2,
                3,
            ), "foreign_keys= should be a list of tuple pairs or triples"
            if len(tuple_or_list) == 3:
                tuple_or_list = cast(Tuple[str, str, str], tuple_or_list)
                fks.append(
                    ForeignKey(
                        name, tuple_or_list[0], tuple_or_list[1], tuple_or_list[2]
                    )
                )
            else:
                # Guess the primary key
                fks.append(
                    ForeignKey(
                        name,
                        tuple_or_list[0],
                        tuple_or_list[1],
                        table.guess_foreign_column(tuple_or_list[1]),
                    )
                )
        return fks

    def create_table_sql(
        self,
        name: str,
        columns: Dict[str, Any],
        pk: Optional[Any] = None,
        foreign_keys: Optional[ForeignKeysType] = None,
        column_order: Optional[List[str]] = None,
        not_null: Iterable[str] = None,
        defaults: Optional[Dict[str, Any]] = None,
        hash_id: Optional[Any] = None,
        extracts: Optional[Union[Dict[str, str], List[str]]] = None,
    ) -> str:
        "Returns the SQL ``CREATE TABLE`` statement for creating the specified table."
        foreign_keys = self.resolve_foreign_keys(name, foreign_keys or [])
        foreign_keys_by_column = {fk.column: fk for fk in foreign_keys}
        # any extracts will be treated as integer columns with a foreign key
        extracts = resolve_extracts(extracts)
        for extract_column, extract_table in extracts.items():
            if isinstance(extract_column, tuple):
                assert False
            # Ensure other table exists
            if not self[extract_table].exists():
                self.create_table(extract_table, {"id": int, "value": str}, pk="id")
            columns[extract_column] = int
            foreign_keys_by_column[extract_column] = ForeignKey(
                name, extract_column, extract_table, "id"
            )
        # Soundness check not_null, and defaults if provided
        not_null = not_null or set()
        defaults = defaults or {}
        assert all(
            n in columns for n in not_null
        ), "not_null set {} includes items not in columns {}".format(
            repr(not_null), repr(set(columns.keys()))
        )
        assert all(
            n in columns for n in defaults
        ), "defaults set {} includes items not in columns {}".format(
            repr(set(defaults)), repr(set(columns.keys()))
        )
        validate_column_names(columns.keys())
        column_items = list(columns.items())
        if column_order is not None:

            def sort_key(p):
                return column_order.index(p[0]) if p[0] in column_order else 999

            column_items.sort(key=sort_key)
        if hash_id:
            column_items.insert(0, (hash_id, str))
            pk = hash_id
        # Soundness check foreign_keys point to existing tables
        for fk in foreign_keys:
            if not any(
                c for c in self[fk.other_table].columns if c.name == fk.other_column
            ):
                raise AlterError(
                    "No such column: {}.{}".format(fk.other_table, fk.other_column)
                )

        column_defs = []
        # ensure pk is a tuple
        single_pk = None
        if isinstance(pk, list) and len(pk) == 1 and isinstance(pk[0], str):
            pk = pk[0]
        if isinstance(pk, str):
            single_pk = pk
            if pk not in [c[0] for c in column_items]:
                column_items.insert(0, (pk, int))
        for column_name, column_type in column_items:
            column_extras = []
            if column_name == single_pk:
                column_extras.append("PRIMARY KEY")
            if column_name in not_null:
                column_extras.append("NOT NULL")
            if column_name in defaults and defaults[column_name] is not None:
                column_extras.append(
                    "DEFAULT {}".format(self.quote(defaults[column_name]))
                )
            if column_name in foreign_keys_by_column:
                column_extras.append(
                    "REFERENCES [{other_table}]([{other_column}])".format(
                        other_table=foreign_keys_by_column[column_name].other_table,
                        other_column=foreign_keys_by_column[column_name].other_column,
                    )
                )
            column_defs.append(
                "   [{column_name}] {column_type}{column_extras}".format(
                    column_name=column_name,
                    column_type=COLUMN_TYPE_MAPPING[column_type],
                    column_extras=(" " + " ".join(column_extras))
                    if column_extras
                    else "",
                )
            )
        extra_pk = ""
        if single_pk is None and pk and len(pk) > 1:
            extra_pk = ",\n   PRIMARY KEY ({pks})".format(
                pks=", ".join(["[{}]".format(p) for p in pk])
            )
        columns_sql = ",\n".join(column_defs)
        sql = """CREATE TABLE [{table}] (
{columns_sql}{extra_pk}
);
        """.format(
            table=name, columns_sql=columns_sql, extra_pk=extra_pk
        )
        return sql

    def create_table(
        self,
        name: str,
        columns: Dict[str, Any],
        pk: Optional[Any] = None,
        foreign_keys: Optional[ForeignKeysType] = None,
        column_order: Optional[List[str]] = None,
        not_null: Iterable[str] = None,
        defaults: Optional[Dict[str, Any]] = None,
        hash_id: Optional[Any] = None,
        extracts: Optional[Union[Dict[str, str], List[str]]] = None,
    ) -> "Table":
        """
        Create a table with the specified name and the specified ``{column_name: type}`` columns.

        See :ref:`python_api_explicit_create`.
        """
        sql = self.create_table_sql(
            name=name,
            columns=columns,
            pk=pk,
            foreign_keys=foreign_keys,
            column_order=column_order,
            not_null=not_null,
            defaults=defaults,
            hash_id=hash_id,
            extracts=extracts,
        )
        self.execute(sql)
        table = self.table(
            name,
            pk=pk,
            foreign_keys=foreign_keys,
            column_order=column_order,
            not_null=not_null,
            defaults=defaults,
            hash_id=hash_id,
        )
        return cast(Table, table)

    def create_view(
        self, name: str, sql: str, ignore: bool = False, replace: bool = False
    ):
        """
        Create a new SQL view with the specified name - ``sql`` should start with ``SELECT ...``.

        - ``ignore`` - set to ``True`` to do nothing if a view with this name already exists
        - ``replace`` - set to ``True`` to replace the view if one with this name already exists
        """
        assert not (
            ignore and replace
        ), "Use one or the other of ignore/replace, not both"
        create_sql = "CREATE VIEW {name} AS {sql}".format(name=name, sql=sql)
        if ignore or replace:
            # Does view exist already?
            if name in self.view_names():
                if ignore:
                    return self
                elif replace:
                    # If SQL is the same, do nothing
                    if create_sql == self[name].schema:
                        return self
                    self[name].drop()
        self.execute(create_sql)
        return self

    def m2m_table_candidates(self, table: str, other_table: str) -> List[str]:
        """
        Given two table names returns the name of tables that could define a
        many-to-many relationship between those two tables, based on having
        foreign keys to both of the provided tables.
        """
        candidates = []
        tables = {table, other_table}
        for table_obj in self.tables:
            # Does it have foreign keys to both table and other_table?
            has_fks_to = {fk.other_table for fk in table_obj.foreign_keys}
            if has_fks_to.issuperset(tables):
                candidates.append(table_obj.name)
        return candidates

    def add_foreign_keys(self, foreign_keys: Iterable[Tuple[str, str, str, str]]):
        """
        See :ref:`python_api_add_foreign_keys`.

        ``foreign_keys`` should be a list of  ``(table, column, other_table, other_column)``
        tuples, see :ref:`python_api_add_foreign_keys`.
        """
        # foreign_keys is a list of explicit 4-tuples
        assert all(
            len(fk) == 4 and isinstance(fk, (list, tuple)) for fk in foreign_keys
        ), "foreign_keys must be a list of 4-tuples, (table, column, other_table, other_column)"

        foreign_keys_to_create = []

        # Verify that all tables and columns exist
        for table, column, other_table, other_column in foreign_keys:
            if not self[table].exists():
                raise AlterError("No such table: {}".format(table))
            table_obj = self[table]
            if not isinstance(table_obj, Table):
                raise AlterError("Must be a table, not a view: {}".format(table))
            table_obj = cast(Table, table_obj)
            if column not in table_obj.columns_dict:
                raise AlterError("No such column: {} in {}".format(column, table))
            if not self[other_table].exists():
                raise AlterError("No such other_table: {}".format(other_table))
            if (
                other_column != "rowid"
                and other_column not in self[other_table].columns_dict
            ):
                raise AlterError(
                    "No such other_column: {} in {}".format(other_column, other_table)
                )
            # We will silently skip foreign keys that exist already
            if not any(
                fk
                for fk in table_obj.foreign_keys
                if fk.column == column
                and fk.other_table == other_table
                and fk.other_column == other_column
            ):
                foreign_keys_to_create.append(
                    (table, column, other_table, other_column)
                )

        # Construct SQL for use with "UPDATE sqlite_master SET sql = ? WHERE name = ?"
        table_sql: Dict[str, str] = {}
        for table, column, other_table, other_column in foreign_keys_to_create:
            old_sql = table_sql.get(table, self[table].schema)
            extra_sql = ",\n   FOREIGN KEY([{column}]) REFERENCES [{other_table}]([{other_column}])\n".format(
                column=column, other_table=other_table, other_column=other_column
            )
            # Stick that bit in at the very end just before the closing ')'
            last_paren = old_sql.rindex(")")
            new_sql = old_sql[:last_paren].strip() + extra_sql + old_sql[last_paren:]
            table_sql[table] = new_sql

        # And execute it all within a single transaction
        with self.conn:
            cursor = self.conn.cursor()
            schema_version = cursor.execute("PRAGMA schema_version").fetchone()[0]
            cursor.execute("PRAGMA writable_schema = 1")
            for table_name, new_sql in table_sql.items():
                cursor.execute(
                    "UPDATE sqlite_master SET sql = ? WHERE name = ?",
                    (new_sql, table_name),
                )
            cursor.execute("PRAGMA schema_version = %d" % (schema_version + 1))
            cursor.execute("PRAGMA writable_schema = 0")
        # Have to VACUUM outside the transaction to ensure .foreign_keys property
        # can see the newly created foreign key.
        self.vacuum()

    def index_foreign_keys(self):
        "Create indexes for every foreign key column on every table in the database."
        for table_name in self.table_names():
            table = self[table_name]
            existing_indexes = {
                i.columns[0] for i in table.indexes if len(i.columns) == 1
            }
            for fk in table.foreign_keys:
                if fk.column not in existing_indexes:
                    table.create_index([fk.column])

    def vacuum(self):
        "Run a SQLite ``VACUUM`` against the database."
        self.execute("VACUUM;")


class Queryable:
    def exists(self) -> bool:
        "Does this table or view exist yet?"
        return False

    def __init__(self, db, name):
        self.db = db
        self.name = name

    def count_where(
        self,
        where: str = None,
        where_args: Optional[Union[Iterable, dict]] = None,
    ) -> int:
        "Executes ``SELECT count(*) FROM table WHERE ...`` and returns a count."
        sql = "select count(*) from [{}]".format(self.name)
        if where is not None:
            sql += " where " + where
        return self.db.execute(sql, where_args or []).fetchone()[0]

    def execute_count(self):
        # Backwards compatibility, see https://github.com/simonw/sqlite-utils/issues/305#issuecomment-890713185
        return self.count_where()

    @property
    def count(self) -> int:
        "A count of the rows in this table or view."
        return self.count_where()

    @property
    def rows(self) -> Generator[dict, None, None]:
        "Iterate over every dictionaries for each row in this table or view."
        return self.rows_where()

    def rows_where(
        self,
        where: str = None,
        where_args: Optional[Union[Iterable, dict]] = None,
        order_by: str = None,
        select: str = "*",
        limit: int = None,
        offset: int = None,
    ) -> Generator[dict, None, None]:
        """
        Iterate over every row in this table or view that matches the specified where clause.

        - ``where`` - a SQL fragment to use as a ``WHERE`` clause, for example ``age > ?`` or ``age > :age``.
        - ``where_args`` - a list of arguments (if using ``?``) or a dictionary (if using ``:age``).
        - ``order_by`` - optional column or fragment of SQL to order by.
        - ``select`` - optional comma-separated list of columns to select.
        - ``limit`` - optional integer number of rows to limit to.
        - ``offset`` - optional integer for SQL offset.

        Returns each row as a dictionary. See :ref:`python_api_rows` for more details.
        """
        if not self.exists():
            return
        sql = "select {} from [{}]".format(select, self.name)
        if where is not None:
            sql += " where " + where
        if order_by is not None:
            sql += " order by " + order_by
        if limit is not None:
            sql += " limit {}".format(limit)
        if offset is not None:
            sql += " offset {}".format(offset)
        cursor = self.db.execute(sql, where_args or [])
        columns = [c[0] for c in cursor.description]
        for row in cursor:
            yield dict(zip(columns, row))

    def pks_and_rows_where(
        self,
        where: str = None,
        where_args: Optional[Union[Iterable, dict]] = None,
        order_by: str = None,
        limit: int = None,
        offset: int = None,
    ) -> Generator[Tuple[Any, Dict], None, None]:
        "Like ``.rows_where()`` but returns ``(pk, row)`` pairs - ``pk`` can be a single value or tuple."
        column_names = [column.name for column in self.columns]
        pks = [column.name for column in self.columns if column.is_pk]
        if not pks:
            column_names.insert(0, "rowid")
            pks = ["rowid"]
        select = ",".join("[{}]".format(column_name) for column_name in column_names)
        for row in self.rows_where(
            select=select,
            where=where,
            where_args=where_args,
            order_by=order_by,
            limit=limit,
            offset=offset,
        ):
            row_pk = tuple(row[pk] for pk in pks)
            if len(row_pk) == 1:
                row_pk = row_pk[0]
            yield row_pk, row

    @property
    def columns(self) -> List["Column"]:
        "List of :ref:`Columns <reference_db_other_column>` representing the columns in this table or view."
        if not self.exists():
            return []
        rows = self.db.execute("PRAGMA table_info([{}])".format(self.name)).fetchall()
        return [Column(*row) for row in rows]

    @property
    def columns_dict(self) -> Dict[str, Any]:
        "``{column_name: python-type}`` dictionary representing columns in this table or view."
        return {column.name: column_affinity(column.type) for column in self.columns}

    @property
    def schema(self) -> str:
        "SQL schema for this table or view."
        return self.db.execute(
            "select sql from sqlite_master where name = ?", (self.name,)
        ).fetchone()[0]


class Table(Queryable):
    "Tables should usually be initialized using the ``db.table(table_name)`` or ``db[table_name]`` methods."
    #: The ``rowid`` of the last inserted, updated or selected row.
    last_rowid: Optional[int] = None
    #: The primary key of the last inserted, updated or selected row.
    last_pk: Optional[Any] = None

    def __init__(
        self,
        db: Database,
        name: str,
        pk: Optional[Any] = None,
        foreign_keys: Optional[ForeignKeysType] = None,
        column_order: Optional[List[str]] = None,
        not_null: Iterable[str] = None,
        defaults: Optional[Dict[str, Any]] = None,
        batch_size: int = 100,
        hash_id: Optional[Any] = None,
        alter: bool = False,
        ignore: bool = False,
        replace: bool = False,
        extracts: Optional[Union[Dict[str, str], List[str]]] = None,
        conversions: Optional[dict] = None,
        columns: Optional[Union[Dict[str, Any]]] = None,
    ):
        super().__init__(db, name)
        self._defaults = dict(
            pk=pk,
            foreign_keys=foreign_keys,
            column_order=column_order,
            not_null=not_null,
            defaults=defaults,
            batch_size=batch_size,
            hash_id=hash_id,
            alter=alter,
            ignore=ignore,
            replace=replace,
            extracts=extracts,
            conversions=conversions or {},
            columns=columns,
        )

    def __repr__(self) -> str:
        return "<Table {}{}>".format(
            self.name,
            " (does not exist yet)"
            if not self.exists()
            else " ({})".format(", ".join(c.name for c in self.columns)),
        )

    @property
    def count(self) -> int:
        "Count of the rows in this table - optionally from the table count cache, if configured."
        if self.db.use_counts_table:
            counts = self.db.cached_counts([self.name])
            if counts:
                return next(iter(counts.values()))
        return self.count_where()

    def exists(self) -> bool:
        return self.name in self.db.table_names()

    @property
    def pks(self) -> List[str]:
        "Primary key columns for this table."
        names = [column.name for column in self.columns if column.is_pk]
        if not names:
            names = ["rowid"]
        return names

    @property
    def use_rowid(self) -> bool:
        "Does this table use ``rowid`` for its primary key (no other primary keys are specified)?"
        return not any(column for column in self.columns if column.is_pk)

    def get(self, pk_values: Union[list, tuple, str, int]) -> dict:
        """
        Return row (as dictionary) for the specified primary key.

        Primary key can be a single value, or a tuple for tables with a compound primary key.

        Raises ``NotFoundError`` if a matching row cannot be found.
        """
        if not isinstance(pk_values, (list, tuple)):
            pk_values = [pk_values]
        pks = self.pks
        last_pk = pk_values[0] if len(pks) == 1 else pk_values
        if len(pks) != len(pk_values):
            raise NotFoundError(
                "Need {} primary key value{}".format(
                    len(pks), "" if len(pks) == 1 else "s"
                )
            )

        wheres = ["[{}] = ?".format(pk_name) for pk_name in pks]
        rows = self.rows_where(" and ".join(wheres), pk_values)
        try:
            row = list(rows)[0]
            self.last_pk = last_pk
            return row
        except IndexError:
            raise NotFoundError

    @property
    def foreign_keys(self) -> List["ForeignKey"]:
        "List of foreign keys defined on this table."
        fks = []
        for row in self.db.execute(
            "PRAGMA foreign_key_list([{}])".format(self.name)
        ).fetchall():
            if row is not None:
                id, seq, table_name, from_, to_, on_update, on_delete, match = row
                fks.append(
                    ForeignKey(
                        table=self.name,
                        column=from_,
                        other_table=table_name,
                        other_column=to_,
                    )
                )
        return fks

    @property
    def virtual_table_using(self) -> Optional[str]:
        "Type of virtual table, or ``None`` if this is not a virtual table."
        match = _virtual_table_using_re.match(self.schema)
        if match is None:
            return None
        return match.groupdict()["using"].upper()

    @property
    def indexes(self) -> List[Index]:
        "List of indexes defined on this table."
        sql = 'PRAGMA index_list("{}")'.format(self.name)
        indexes = []
        for row in self.db.execute_returning_dicts(sql):
            index_name = row["name"]
            index_name_quoted = (
                '"{}"'.format(index_name)
                if not index_name.startswith('"')
                else index_name
            )
            column_sql = "PRAGMA index_info({})".format(index_name_quoted)
            columns = []
            for seqno, cid, name in self.db.execute(column_sql).fetchall():
                columns.append(name)
            row["columns"] = columns
            # These columns may be missing on older SQLite versions:
            for key, default in {"origin": "c", "partial": 0}.items():
                if key not in row:
                    row[key] = default
            indexes.append(Index(**row))
        return indexes

    @property
    def xindexes(self) -> List[XIndex]:
        "List of indexes defined on this table using the more detailed ``XIndex`` format."
        sql = 'PRAGMA index_list("{}")'.format(self.name)
        indexes = []
        for row in self.db.execute_returning_dicts(sql):
            index_name = row["name"]
            index_name_quoted = (
                '"{}"'.format(index_name)
                if not index_name.startswith('"')
                else index_name
            )
            column_sql = "PRAGMA index_xinfo({})".format(index_name_quoted)
            index_columns = []
            for info in self.db.execute(column_sql).fetchall():
                index_columns.append(XIndexColumn(*info))
            indexes.append(XIndex(index_name, index_columns))
        return indexes

    @property
    def triggers(self) -> List[Trigger]:
        "List of triggers defined on this table."
        return [
            Trigger(*r)
            for r in self.db.execute(
                "select name, tbl_name, sql from sqlite_master where type = 'trigger'"
                " and tbl_name = ?",
                (self.name,),
            ).fetchall()
        ]

    @property
    def triggers_dict(self) -> Dict[str, str]:
        "``{trigger_name: sql}`` dictionary of triggers defined on this table."
        return {trigger.name: trigger.sql for trigger in self.triggers}

    def create(
        self,
        columns: Dict[str, Any],
        pk: Optional[Any] = None,
        foreign_keys: Optional[ForeignKeysType] = None,
        column_order: Optional[List[str]] = None,
        not_null: Iterable[str] = None,
        defaults: Optional[Dict[str, Any]] = None,
        hash_id: Optional[Any] = None,
        extracts: Optional[Union[Dict[str, str], List[str]]] = None,
    ) -> "Table":
        """
        Create a table with the specified columns.

        See :ref:`python_api_explicit_create` for full details.
        """
        columns = {name: value for (name, value) in columns.items()}
        with self.db.conn:
            self.db.create_table(
                self.name,
                columns,
                pk=pk,
                foreign_keys=foreign_keys,
                column_order=column_order,
                not_null=not_null,
                defaults=defaults,
                hash_id=hash_id,
                extracts=extracts,
            )
        return self

    def transform(
        self,
        *,
        types=None,
        rename=None,
        drop=None,
        pk=DEFAULT,
        not_null=None,
        defaults=None,
        drop_foreign_keys=None,
        column_order=None,
    ) -> "Table":
        """
        Apply an advanced alter table, including operations that are not supported by
        ``ALTER TABLE`` in SQLite itself.

        See :ref:`python_api_transform` for full details.
        """
        assert self.exists(), "Cannot transform a table that doesn't exist yet"
        sqls = self.transform_sql(
            types=types,
            rename=rename,
            drop=drop,
            pk=pk,
            not_null=not_null,
            defaults=defaults,
            drop_foreign_keys=drop_foreign_keys,
            column_order=column_order,
        )
        pragma_foreign_keys_was_on = self.db.execute("PRAGMA foreign_keys").fetchone()[
            0
        ]
        try:
            if pragma_foreign_keys_was_on:
                self.db.execute("PRAGMA foreign_keys=0;")
            with self.db.conn:
                for sql in sqls:
                    self.db.execute(sql)
                # Run the foreign_key_check before we commit
                if pragma_foreign_keys_was_on:
                    self.db.execute("PRAGMA foreign_key_check;")
        finally:
            if pragma_foreign_keys_was_on:
                self.db.execute("PRAGMA foreign_keys=1;")
        return self

    def transform_sql(
        self,
        *,
        types=None,
        rename=None,
        drop=None,
        pk=DEFAULT,
        not_null=None,
        defaults=None,
        drop_foreign_keys=None,
        column_order=None,
        tmp_suffix=None,
    ) -> List[str]:
        "Returns a list of SQL statements that would be executed in order to apply this transformation."
        types = types or {}
        rename = rename or {}
        drop = drop or set()
        new_table_name = "{}_new_{}".format(
            self.name, tmp_suffix or os.urandom(6).hex()
        )
        current_column_pairs = list(self.columns_dict.items())
        new_column_pairs = []
        copy_from_to = {column: column for column, _ in current_column_pairs}
        for name, type_ in current_column_pairs:
            type_ = types.get(name) or type_
            if name in drop:
                del [copy_from_to[name]]
                continue
            new_name = rename.get(name) or name
            new_column_pairs.append((new_name, type_))
            copy_from_to[name] = new_name

        sqls = []
        if pk is DEFAULT:
            pks_renamed = tuple(
                rename.get(p.name) or p.name for p in self.columns if p.is_pk
            )
            if len(pks_renamed) == 1:
                pk = pks_renamed[0]
            else:
                pk = pks_renamed

        # not_null may be a set or dict, need to convert to a set
        create_table_not_null = {
            rename.get(c.name) or c.name
            for c in self.columns
            if c.notnull
            if c.name not in drop
        }
        if isinstance(not_null, dict):
            # Remove any columns with a value of False
            for key, value in not_null.items():
                # Column may have been renamed
                key = rename.get(key) or key
                if value is False and key in create_table_not_null:
                    create_table_not_null.remove(key)
                else:
                    create_table_not_null.add(key)
        elif isinstance(not_null, set):
            create_table_not_null.update((rename.get(k) or k) for k in not_null)
        elif not_null is None:
            pass
        else:
            assert False, "not_null must be a dict or a set or None"
        # defaults=
        create_table_defaults = {
            (rename.get(c.name) or c.name): c.default_value
            for c in self.columns
            if c.default_value is not None and c.name not in drop
        }
        if defaults is not None:
            create_table_defaults.update(
                {rename.get(c) or c: v for c, v in defaults.items()}
            )

        # foreign_keys
        create_table_foreign_keys = []
        for table, column, other_table, other_column in self.foreign_keys:
            if (drop_foreign_keys is None) or (column not in drop_foreign_keys):
                create_table_foreign_keys.append(
                    (rename.get(column) or column, other_table, other_column)
                )

        if column_order is not None:
            column_order = [rename.get(col) or col for col in column_order]

        sqls.append(
            self.db.create_table_sql(
                new_table_name,
                dict(new_column_pairs),
                pk=pk,
                not_null=create_table_not_null,
                defaults=create_table_defaults,
                foreign_keys=create_table_foreign_keys,
                column_order=column_order,
            ).strip()
        )

        # Copy across data, respecting any renamed columns
        new_cols = []
        old_cols = []
        for from_, to_ in copy_from_to.items():
            old_cols.append(from_)
            new_cols.append(to_)
        copy_sql = "INSERT INTO [{new_table}] ({new_cols})\n   SELECT {old_cols} FROM [{old_table}];".format(
            new_table=new_table_name,
            old_table=self.name,
            old_cols=", ".join("[{}]".format(col) for col in old_cols),
            new_cols=", ".join("[{}]".format(col) for col in new_cols),
        )
        sqls.append(copy_sql)
        # Drop the old table
        sqls.append("DROP TABLE [{}];".format(self.name))
        # Rename the new one
        sqls.append(
            "ALTER TABLE [{}] RENAME TO [{}];".format(new_table_name, self.name)
        )
        return sqls

    def extract(
        self,
        columns: Union[str, Iterable[str]],
        table: Optional[str] = None,
        fk_column: Optional[str] = None,
        rename: Optional[Dict[str, str]] = None,
    ) -> "Table":
        """
        Extract specified columns into a separate table.

        See :ref:`python_api_extract` for details.
        """
        rename = rename or {}
        if isinstance(columns, str):
            columns = [columns]
        if not set(columns).issubset(self.columns_dict.keys()):
            raise InvalidColumns(
                "Invalid columns {} for table with columns {}".format(
                    columns, list(self.columns_dict.keys())
                )
            )
        table = table or "_".join(columns)
        lookup_table = self.db[table]
        fk_column = fk_column or "{}_id".format(table)
        magic_lookup_column = "{}_{}".format(fk_column, os.urandom(6).hex())

        # Populate the lookup table with all of the extracted unique values
        lookup_columns_definition = {
            (rename.get(col) or col): typ
            for col, typ in self.columns_dict.items()
            if col in columns
        }
        if lookup_table.exists():
            if not set(lookup_columns_definition.items()).issubset(
                lookup_table.columns_dict.items()
            ):
                raise InvalidColumns(
                    "Lookup table {} already exists but does not have columns {}".format(
                        table, lookup_columns_definition
                    )
                )
        else:
            lookup_table.create(
                {
                    **{
                        "id": int,
                    },
                    **lookup_columns_definition,
                },
                pk="id",
            )
        lookup_columns = [(rename.get(col) or col) for col in columns]
        lookup_table.create_index(lookup_columns, unique=True, if_not_exists=True)
        self.db.execute(
            "INSERT OR IGNORE INTO [{lookup_table}] ({lookup_columns}) SELECT DISTINCT {table_cols} FROM [{table}]".format(
                lookup_table=table,
                lookup_columns=", ".join("[{}]".format(c) for c in lookup_columns),
                table_cols=", ".join("[{}]".format(c) for c in columns),
                table=self.name,
            )
        )

        # Now add the new fk_column
        self.add_column(magic_lookup_column, int)

        # And populate it
        self.db.execute(
            "UPDATE [{table}] SET [{magic_lookup_column}] = (SELECT id FROM [{lookup_table}] WHERE {where})".format(
                table=self.name,
                magic_lookup_column=magic_lookup_column,
                lookup_table=table,
                where=" AND ".join(
                    "[{table}].[{column}] = [{lookup_table}].[{lookup_column}]".format(
                        table=self.name,
                        lookup_table=table,
                        column=column,
                        lookup_column=rename.get(column) or column,
                    )
                    for column in columns
                ),
            )
        )
        # Figure out the right column order
        column_order = []
        for c in self.columns:
            if c.name in columns and magic_lookup_column not in column_order:
                column_order.append(magic_lookup_column)
            elif c.name == magic_lookup_column:
                continue
            else:
                column_order.append(c.name)

        # Drop the unnecessary columns and rename lookup column
        self.transform(
            drop=set(columns),
            rename={magic_lookup_column: fk_column},
            column_order=column_order,
        )

        # And add the foreign key constraint
        self.add_foreign_key(fk_column, table, "id")
        return self

    def create_index(
        self,
        columns: Iterable[Union[str, DescIndex]],
        index_name: Optional[str] = None,
        unique: bool = False,
        if_not_exists: bool = False,
    ):
        """
        Create an index on this table.

        - ``columns`` - a single columns or list of columns to index. These can be strings or,
          to create an index using the column in descending order, ``db.DescIndex(column_name)`` objects.
        - ``index_name`` - the name to use for the new index. Defaults to the column names joined on ``_``.
        - ``unique`` - should the index be marked as unique, forcing unique values?
        - ``if_not_exists`` - only create the index if one with that name does not already exist.

        See :ref:`python_api_create_index`.
        """
        if index_name is None:
            index_name = "idx_{}_{}".format(
                self.name.replace(" ", "_"), "_".join(columns)
            )
        columns_sql = []
        for column in columns:
            if isinstance(column, DescIndex):
                fmt = "[{}] desc"
            else:
                fmt = "[{}]"
            columns_sql.append(fmt.format(column))
        sql = (
            textwrap.dedent(
                """
            CREATE {unique}INDEX {if_not_exists}[{index_name}]
                ON [{table_name}] ({columns});
        """
            )
            .strip()
            .format(
                index_name=index_name,
                table_name=self.name,
                columns=", ".join(columns_sql),
                unique="UNIQUE " if unique else "",
                if_not_exists="IF NOT EXISTS " if if_not_exists else "",
            )
        )
        self.db.execute(sql)
        return self

    def add_column(
        self, col_name: str, col_type=None, fk=None, fk_col=None, not_null_default=None
    ):
        "Add a column to this table. See :ref:`python_api_add_column`."
        fk_col_type = None
        if fk is not None:
            # fk must be a valid table
            if fk not in self.db.table_names():
                raise AlterError("table '{}' does not exist".format(fk))
            # if fk_col specified, must be a valid column
            if fk_col is not None:
                if fk_col not in self.db[fk].columns_dict:
                    raise AlterError("table '{}' has no column {}".format(fk, fk_col))
            else:
                # automatically set fk_col to first primary_key of fk table
                pks = [c for c in self.db[fk].columns if c.is_pk]
                if pks:
                    fk_col = pks[0].name
                    fk_col_type = pks[0].type
                else:
                    fk_col = "rowid"
                    fk_col_type = "INTEGER"
        if col_type is None:
            col_type = str
        not_null_sql = None
        if not_null_default is not None:
            not_null_sql = "NOT NULL DEFAULT {}".format(self.db.quote(not_null_default))
        sql = "ALTER TABLE [{table}] ADD COLUMN [{col_name}] {col_type}{not_null_default};".format(
            table=self.name,
            col_name=col_name,
            col_type=fk_col_type or COLUMN_TYPE_MAPPING[col_type],
            not_null_default=(" " + not_null_sql) if not_null_sql else "",
        )
        self.db.execute(sql)
        if fk is not None:
            self.add_foreign_key(col_name, fk, fk_col)
        return self

    def drop(self, ignore: bool = False):
        "Drop this table. ``ignore=True`` means errors will be ignored."
        try:
            self.db.execute("DROP TABLE [{}]".format(self.name))
        except sqlite3.OperationalError:
            if not ignore:
                raise

    def guess_foreign_table(self, column: str) -> str:
        """
        For a given column, suggest another table that might be referenced by this
        column should it be used as a foreign key.

        For example, a column called ``tag_id`` or ``tag`` or ``tags`` might suggest
        a ``tag`` table, if one exists.

        If no candidates can be found, raises a ``NoObviousTable`` exception.
        """
        column = column.lower()
        possibilities = [column]
        if column.endswith("_id"):
            column_without_id = column[:-3]
            possibilities.append(column_without_id)
            if not column_without_id.endswith("s"):
                possibilities.append(column_without_id + "s")
        elif not column.endswith("s"):
            possibilities.append(column + "s")
        existing_tables = {t.lower(): t for t in self.db.table_names()}
        for table in possibilities:
            if table in existing_tables:
                return existing_tables[table]
        # If we get here there's no obvious candidate - raise an error
        raise NoObviousTable(
            "No obvious foreign key table for column '{}' - tried {}".format(
                column, repr(possibilities)
            )
        )

    def guess_foreign_column(self, other_table: str):
        pks = [c for c in self.db[other_table].columns if c.is_pk]
        if len(pks) != 1:
            raise BadPrimaryKey(
                "Could not detect single primary key for table '{}'".format(other_table)
            )
        else:
            return pks[0].name

    def add_foreign_key(
        self,
        column: str,
        other_table: Optional[str] = None,
        other_column: Optional[str] = None,
        ignore: bool = False,
    ):
        """
        Alter the schema to mark the specified column as a foreign key to another table.

        - ``column`` - the column to mark as a foreign key.
        - ``other_table`` - the table it refers to - if omitted, will be guessed based on the column name.
        - ``other_column`` - the column on the other table it - if omitted, will be guessed.
        - ``ignore`` - set this to ``True`` to ignore an existing foreign key - otherwise a ``AlterError`` will be raised.
        """
        # Ensure column exists
        if column not in self.columns_dict:
            raise AlterError("No such column: {}".format(column))
        # If other_table is not specified, attempt to guess it from the column
        if other_table is None:
            other_table = self.guess_foreign_table(column)
        # If other_column is not specified, detect the primary key on other_table
        if other_column is None:
            other_column = self.guess_foreign_column(other_table)

        # Soundness check that the other column exists
        if (
            not [c for c in self.db[other_table].columns if c.name == other_column]
            and other_column != "rowid"
        ):
            raise AlterError("No such column: {}.{}".format(other_table, other_column))
        # Check we do not already have an existing foreign key
        if any(
            fk
            for fk in self.foreign_keys
            if fk.column == column
            and fk.other_table == other_table
            and fk.other_column == other_column
        ):
            if ignore:
                return self
            else:
                raise AlterError(
                    "Foreign key already exists for {} => {}.{}".format(
                        column, other_table, other_column
                    )
                )
        self.db.add_foreign_keys([(self.name, column, other_table, other_column)])
        return self

    def enable_counts(self):
        """
        Set up triggers to update a cache of the count of rows in this table.

        See :ref:`python_api_cached_table_counts` for details.
        """
        sql = (
            textwrap.dedent(
                """
        {create_counts_table}
        CREATE TRIGGER IF NOT EXISTS [{table}{counts_table}_insert] AFTER INSERT ON [{table}]
        BEGIN
            INSERT OR REPLACE INTO [{counts_table}]
            VALUES (
                {table_quoted},
                COALESCE(
                    (SELECT count FROM [{counts_table}] WHERE [table] = {table_quoted}),
                0
                ) + 1
            );
        END;
        CREATE TRIGGER IF NOT EXISTS [{table}{counts_table}_delete] AFTER DELETE ON [{table}]
        BEGIN
            INSERT OR REPLACE INTO [{counts_table}]
            VALUES (
                {table_quoted},
                COALESCE(
                    (SELECT count FROM [{counts_table}] WHERE [table] = {table_quoted}),
                0
                ) - 1
            );
        END;
        INSERT OR REPLACE INTO _counts VALUES ({table_quoted}, (select count(*) from [{table}]));
        """
            )
            .strip()
            .format(
                create_counts_table=_COUNTS_TABLE_CREATE_SQL.format(
                    self.db._counts_table_name
                ),
                counts_table=self.db._counts_table_name,
                table=self.name,
                table_quoted=self.db.quote(self.name),
            )
        )
        with self.db.conn:
            self.db.conn.executescript(sql)
        self.db.use_counts_table = True

    @property
    def has_counts_triggers(self) -> bool:
        "Does this table have triggers setup to update cached counts?"
        trigger_names = {
            "{table}{counts_table}_{suffix}".format(
                counts_table=self.db._counts_table_name, table=self.name, suffix=suffix
            )
            for suffix in ["insert", "delete"]
        }
        return trigger_names.issubset(self.triggers_dict.keys())

    def enable_fts(
        self,
        columns: Iterable[str],
        fts_version: str = "FTS5",
        create_triggers: bool = False,
        tokenize: Optional[str] = None,
        replace: bool = False,
    ):
        """
        Enable SQLite full-text search against the specified columns.

        - ``columns`` - list of column names to include in the search index.
        - ``fts_version`` - FTS version to use - defaults to ``FTS5`` but you may want ``FTS4`` for older SQLite versions.
        - ``create_triggers`` - should triggers be created to keep the search index up-to-date? Defaults to ``False``.
        - ``tokenize`` - custom SQLite tokenizer to use, for example ``"porter"`` to enable Porter stemming.
        - ``replace`` - should any existing FTS index for this table be replaced by the new one?

        See :ref:`python_api_fts` for more details.
        """
        create_fts_sql = (
            textwrap.dedent(
                """
            CREATE VIRTUAL TABLE [{table}_fts] USING {fts_version} (
                {columns},{tokenize}
                content=[{table}]
            )
        """
            )
            .strip()
            .format(
                table=self.name,
                columns=", ".join("[{}]".format(c) for c in columns),
                fts_version=fts_version,
                tokenize="\n    tokenize='{}',".format(tokenize) if tokenize else "",
            )
        )
        should_recreate = False
        if replace and self.db["{}_fts".format(self.name)].exists():
            # Does the table need to be recreated?
            fts_schema = self.db["{}_fts".format(self.name)].schema
            if fts_schema != create_fts_sql:
                should_recreate = True
            expected_triggers = {self.name + suffix for suffix in ("_ai", "_ad", "_au")}
            existing_triggers = {t.name for t in self.triggers}
            has_triggers = existing_triggers.issuperset(expected_triggers)
            if has_triggers != create_triggers:
                should_recreate = True
            if not should_recreate:
                # Table with correct configuration already exists
                return self

        if should_recreate:
            self.disable_fts()

        self.db.executescript(create_fts_sql)
        self.populate_fts(columns)

        if create_triggers:
            old_cols = ", ".join("old.[{}]".format(c) for c in columns)
            new_cols = ", ".join("new.[{}]".format(c) for c in columns)
            triggers = (
                textwrap.dedent(
                    """
                CREATE TRIGGER [{table}_ai] AFTER INSERT ON [{table}] BEGIN
                  INSERT INTO [{table}_fts] (rowid, {columns}) VALUES (new.rowid, {new_cols});
                END;
                CREATE TRIGGER [{table}_ad] AFTER DELETE ON [{table}] BEGIN
                  INSERT INTO [{table}_fts] ([{table}_fts], rowid, {columns}) VALUES('delete', old.rowid, {old_cols});
                END;
                CREATE TRIGGER [{table}_au] AFTER UPDATE ON [{table}] BEGIN
                  INSERT INTO [{table}_fts] ([{table}_fts], rowid, {columns}) VALUES('delete', old.rowid, {old_cols});
                  INSERT INTO [{table}_fts] (rowid, {columns}) VALUES (new.rowid, {new_cols});
                END;
            """
                )
                .strip()
                .format(
                    table=self.name,
                    columns=", ".join("[{}]".format(c) for c in columns),
                    old_cols=old_cols,
                    new_cols=new_cols,
                )
            )
            self.db.executescript(triggers)
        return self

    def populate_fts(self, columns: Iterable[str]) -> "Table":
        """
        Update the associated SQLite full-text search index with the latest data from the
        table for the specified columns.
        """
        sql = (
            textwrap.dedent(
                """
            INSERT INTO [{table}_fts] (rowid, {columns})
                SELECT rowid, {columns} FROM [{table}];
        """
            )
            .strip()
            .format(
                table=self.name, columns=", ".join("[{}]".format(c) for c in columns)
            )
        )
        self.db.executescript(sql)
        return self

    def disable_fts(self) -> "Table":
        "Remove any full-text search index and related triggers configured for this table."
        fts_table = self.detect_fts()
        if fts_table:
            self.db[fts_table].drop()
        # Now delete the triggers that related to that table
        sql = (
            textwrap.dedent(
                """
            SELECT name FROM sqlite_master
                WHERE type = 'trigger'
                AND sql LIKE '% INSERT INTO [{}]%'
        """
            )
            .strip()
            .format(fts_table)
        )
        trigger_names = []
        for row in self.db.execute(sql).fetchall():
            trigger_names.append(row[0])
        with self.db.conn:
            for trigger_name in trigger_names:
                self.db.execute("DROP TRIGGER IF EXISTS [{}]".format(trigger_name))
        return self

    def rebuild_fts(self):
        "Run the ``rebuild`` operation against the associated full-text search index table."
        fts_table = self.detect_fts()
        if fts_table is None:
            # Assume this is itself an FTS table
            fts_table = self.name
        self.db.execute(
            "INSERT INTO [{table}]([{table}]) VALUES('rebuild');".format(
                table=fts_table
            )
        )
        return self

    def detect_fts(self) -> Optional[str]:
        "Detect if table has a corresponding FTS virtual table and return it"
        sql = (
            textwrap.dedent(
                """
            SELECT name FROM sqlite_master
                WHERE rootpage = 0
                AND (
                    sql LIKE '%VIRTUAL TABLE%USING FTS%content=%{table}%'
                    OR (
                        tbl_name = "{table}"
                        AND sql LIKE '%VIRTUAL TABLE%USING FTS%'
                    )
                )
        """
            )
            .strip()
            .format(table=self.name)
        )
        rows = self.db.execute(sql).fetchall()
        if len(rows) == 0:
            return None
        else:
            return rows[0][0]

    def optimize(self) -> "Table":
        "Run the ``optimize`` operation against the associated full-text search index table."
        fts_table = self.detect_fts()
        if fts_table is not None:
            self.db.execute(
                """
                INSERT INTO [{table}] ([{table}]) VALUES ("optimize");
            """.strip().format(
                    table=fts_table
                )
            )
        return self

    def search_sql(
        self,
        columns: Optional[Iterable[str]] = None,
        order_by: Optional[str] = None,
        limit: Optional[int] = None,
        offset: Optional[int] = None,
    ) -> str:
        "Return SQL string that can be used to execute searches against this table."
        # Pick names for table and rank column that don't clash
        original = "original_" if self.name == "original" else "original"
        columns_sql = "*"
        columns_with_prefix_sql = "[{}].*".format(original)
        if columns:
            columns_sql = ",\n        ".join("[{}]".format(c) for c in columns)
            columns_with_prefix_sql = ",\n    ".join(
                "[{}].[{}]".format(original, c) for c in columns
            )
        fts_table = self.detect_fts()
        assert fts_table, "Full-text search is not configured for table '{}'".format(
            self.name
        )
        virtual_table_using = self.db[fts_table].virtual_table_using
        sql = textwrap.dedent(
            """
        with {original} as (
            select
                rowid,
                {columns}
            from [{dbtable}]
        )
        select
            {columns_with_prefix}
        from
            [{original}]
            join [{fts_table}] on [{original}].rowid = [{fts_table}].rowid
        where
            [{fts_table}] match :query
        order by
            {order_by}
        {limit_offset}
        """
        ).strip()
        if virtual_table_using == "FTS5":
            rank_implementation = "[{}].rank".format(fts_table)
        else:
            self.db.register_fts4_bm25()
            rank_implementation = "rank_bm25(matchinfo([{}], 'pcnalx'))".format(
                fts_table
            )
        limit_offset = ""
        if limit is not None:
            limit_offset += " limit {}".format(limit)
        if offset is not None:
            limit_offset += " offset {}".format(offset)
        return sql.format(
            dbtable=self.name,
            original=original,
            columns=columns_sql,
            columns_with_prefix=columns_with_prefix_sql,
            fts_table=fts_table,
            order_by=order_by or rank_implementation,
            limit_offset=limit_offset.strip(),
        ).strip()

    def search(
        self,
        q: str,
        order_by: Optional[str] = None,
        columns: Optional[Iterable[str]] = None,
        limit: Optional[int] = None,
        offset: Optional[int] = None,
        quote: bool = False,
    ) -> Generator[dict, None, None]:
        """
        Execute a search against this table using SQLite full-text search, returning a sequence of
        dictionaries for each row.

        - ``q`` - terms to search for
        - ``order_by`` - defaults to order by rank, or specify a column here.
        - ``columns`` - list of columns to return, defaults to all columns.
        - ``limit`` - optional integer limit for returned rows.
        - ``offset`` - optional integer SQL offset.
        - ``quote`` - apply quoting to disable any special characters in the search query

        See :ref:`python_api_fts_search`.
        """
        cursor = self.db.execute(
            self.search_sql(
                order_by=order_by,
                columns=columns,
                limit=limit,
                offset=offset,
            ),
            {"query": self.db.quote_fts(q) if quote else q},
        )
        columns = [c[0] for c in cursor.description]
        for row in cursor:
            yield dict(zip(columns, row))

    def value_or_default(self, key, value):
        return self._defaults[key] if value is DEFAULT else value

    def delete(self, pk_values: Union[list, tuple, str, int, float]) -> "Table":
        "Delete row matching the specified primary key."
        if not isinstance(pk_values, (list, tuple)):
            pk_values = [pk_values]
        self.get(pk_values)
        wheres = ["[{}] = ?".format(pk_name) for pk_name in self.pks]
        sql = "delete from [{table}] where {wheres}".format(
            table=self.name, wheres=" and ".join(wheres)
        )
        with self.db.conn:
            self.db.execute(sql, pk_values)
        return self

    def delete_where(
        self, where: str = None, where_args: Optional[Union[Iterable, dict]] = None
    ) -> "Table":
        "Delete rows matching specified where clause, or delete all rows in the table."
        if not self.exists():
            return self
        sql = "delete from [{}]".format(self.name)
        if where is not None:
            sql += " where " + where
        self.db.execute(sql, where_args or [])
        return self

    def update(
        self,
        pk_values: Union[list, tuple, str, int, float],
        updates: Optional[dict] = None,
        alter: bool = False,
        conversions: Optional[dict] = None,
    ) -> "Table":
        """
        Execute a SQL ``UPDATE`` against the specified row.

        - ``pk_values`` - the primary key of an individual record - can be a tuple if the
          table has a compound primary key.
        - ``updates`` - a dictionary mapping columns to their updated values.
        - ``alter`` - set to ``True`` to add any missing columns.
        - ``conversions`` - optional dictionary of SQL functions to apply during the update, for example
          ``{"mycolumn": "upper(?)"}``.

        See :ref:`python_api_update`.
        """
        updates = updates or {}
        conversions = conversions or {}
        if not isinstance(pk_values, (list, tuple)):
            pk_values = [pk_values]
        # Soundness check that the record exists (raises error if not):
        self.get(pk_values)
        if not updates:
            return self
        args = []
        sets = []
        wheres = []
        pks = self.pks
        validate_column_names(updates.keys())
        for key, value in updates.items():
            sets.append("[{}] = {}".format(key, conversions.get(key, "?")))
            args.append(jsonify_if_needed(value))
        wheres = ["[{}] = ?".format(pk_name) for pk_name in pks]
        args.extend(pk_values)
        sql = "update [{table}] set {sets} where {wheres}".format(
            table=self.name, sets=", ".join(sets), wheres=" and ".join(wheres)
        )
        with self.db.conn:
            try:
                rowcount = self.db.execute(sql, args).rowcount
            except OperationalError as e:
                if alter and (" column" in e.args[0]):
                    # Attempt to add any missing columns, then try again
                    self.add_missing_columns([updates])
                    rowcount = self.db.execute(sql, args).rowcount
                else:
                    raise

            # TODO: Test this works (rolls back) - use better exception:
            assert rowcount == 1
        self.last_pk = pk_values[0] if len(pks) == 1 else pk_values
        return self

    def convert(
        self,
        columns: Union[str, List[str]],
        fn: Callable,
        output: Optional[str] = None,
        output_type: Optional[Any] = None,
        drop: bool = False,
        multi: bool = False,
        where: Optional[str] = None,
        where_args: Optional[Union[Iterable, dict]] = None,
        show_progress: bool = False,
    ):
        """
        Apply conversion function ``fn`` to every value in the specified columns.

        - ``columns`` - a single column or list of string column names to convert.
        - ``fn`` - a callable that takes a single argument, ``value``, and returns it converted.
        - ``output`` - optional string column name to write the results to (defaults to the input column).
        - ``output_type`` - if the output column needs to be created, this is the type that will be used
          for the new column.
        - ``drop`` - boolean, should the original column be dropped once the conversion is complete?
        - ``multi`` - boolean, if ``True`` the return value of ``fn(value)`` will be expected to be a
          dictionary, and new columns will be created for each key of that dictionary.
        - ``where`` - a SQL fragment to use as a ``WHERE`` clause to limit the rows to which the conversion
          is applied, for example ``age > ?`` or ``age > :age``.
        - ``where_args`` - a list of arguments (if using ``?``) or a dictionary (if using ``:age``).
        - ``show_progress`` - boolean, should a progress bar be displayed?

        See :ref:`python_api_convert`.
        """
        if isinstance(columns, str):
            columns = [columns]

        if multi:
            return self._convert_multi(
                columns[0],
                fn,
                drop=drop,
                where=where,
                where_args=where_args,
                show_progress=show_progress,
            )

        if output is not None:
            assert len(columns) == 1, "output= can only be used with a single column"
            if output not in self.columns_dict:
                self.add_column(output, output_type or "text")

        todo_count = self.count_where(where, where_args) * len(columns)
        with progressbar(length=todo_count, silent=not show_progress) as bar:

            def convert_value(v):
                bar.update(1)
                if not v:
                    return v
                return fn(v)

            self.db.register_function(convert_value)
            sql = "update [{table}] set {sets}{where};".format(
                table=self.name,
                sets=", ".join(
                    [
                        "[{output_column}] = convert_value([{column}])".format(
                            output_column=output or column, column=column
                        )
                        for column in columns
                    ]
                ),
                where=" where {}".format(where) if where is not None else "",
            )
            with self.db.conn:
                self.db.execute(sql, where_args or [])
                if drop:
                    self.transform(drop=columns)
        return self

    def _convert_multi(
        self, column, fn, drop, show_progress, where=None, where_args=None
    ):
        # First we execute the function
        pk_to_values = {}
        new_column_types = {}
        pks = [column.name for column in self.columns if column.is_pk]
        if not pks:
            pks = ["rowid"]

        with progressbar(
            length=self.count, silent=not show_progress, label="1: Evaluating"
        ) as bar:
            for row in self.rows_where(
                select=", ".join(
                    "[{}]".format(column_name) for column_name in (pks + [column])
                ),
                where=where,
                where_args=where_args,
            ):
                row_pk = tuple(row[pk] for pk in pks)
                if len(row_pk) == 1:
                    row_pk = row_pk[0]
                values = fn(row[column])
                if values is not None and not isinstance(values, dict):
                    raise BadMultiValues(values)
                if values:
                    for key, value in values.items():
                        new_column_types.setdefault(key, set()).add(type(value))
                    pk_to_values[row_pk] = values
                bar.update(1)

        # Add any new columns
        columns_to_create = types_for_column_types(new_column_types)
        for column_name, column_type in columns_to_create.items():
            if column_name not in self.columns_dict:
                self.add_column(column_name, column_type)

        # Run the updates
        with progressbar(
            length=self.count, silent=not show_progress, label="2: Updating"
        ) as bar:
            with self.db.conn:
                for pk, updates in pk_to_values.items():
                    self.update(pk, updates)
                    bar.update(1)
                if drop:
                    self.transform(drop=(column,))

    def build_insert_queries_and_params(
        self,
        extracts,
        chunk,
        all_columns,
        hash_id,
        upsert,
        pk,
        conversions,
        num_records_processed,
        replace,
        ignore,
    ):
        # values is the list of insert data that is passed to the
        # .execute() method - but some of them may be replaced by
        # new primary keys if we are extracting any columns.
        values = []
        extracts = resolve_extracts(extracts)
        for record in chunk:
            record_values = []
            for key in all_columns:
                value = jsonify_if_needed(
                    record.get(key, None if key != hash_id else _hash(record))
                )
                if key in extracts:
                    extract_table = extracts[key]
                    value = self.db[extract_table].lookup({"value": value})
                record_values.append(value)
            values.append(record_values)

        queries_and_params = []
        if upsert:
            if isinstance(pk, str):
                pks = [pk]
            else:
                pks = pk
            self.last_pk = None
            for record_values in values:
                # TODO: make more efficient:
                record = dict(zip(all_columns, record_values))
                sql = "INSERT OR IGNORE INTO [{table}]({pks}) VALUES({pk_placeholders});".format(
                    table=self.name,
                    pks=", ".join(["[{}]".format(p) for p in pks]),
                    pk_placeholders=", ".join(["?" for p in pks]),
                )
                queries_and_params.append((sql, [record[col] for col in pks]))
                # UPDATE [book] SET [name] = 'Programming' WHERE [id] = 1001;
                set_cols = [col for col in all_columns if col not in pks]
                if set_cols:
                    sql2 = "UPDATE [{table}] SET {pairs} WHERE {wheres}".format(
                        table=self.name,
                        pairs=", ".join(
                            "[{}] = {}".format(col, conversions.get(col, "?"))
                            for col in set_cols
                        ),
                        wheres=" AND ".join("[{}] = ?".format(pk) for pk in pks),
                    )
                    queries_and_params.append(
                        (
                            sql2,
                            [record[col] for col in set_cols]
                            + [record[pk] for pk in pks],
                        )
                    )
                # We can populate .last_pk right here
                if num_records_processed == 1:
                    self.last_pk = tuple(record[pk] for pk in pks)
                    if len(self.last_pk) == 1:
                        self.last_pk = self.last_pk[0]

        else:
            or_what = ""
            if replace:
                or_what = "OR REPLACE "
            elif ignore:
                or_what = "OR IGNORE "
            sql = """
                INSERT {or_what}INTO [{table}] ({columns}) VALUES {rows};
            """.strip().format(
                or_what=or_what,
                table=self.name,
                columns=", ".join("[{}]".format(c) for c in all_columns),
                rows=", ".join(
                    "({placeholders})".format(
                        placeholders=", ".join(
                            [conversions.get(col, "?") for col in all_columns]
                        )
                    )
                    for record in chunk
                ),
            )
            flat_values = list(itertools.chain(*values))
            queries_and_params = [(sql, flat_values)]

        return queries_and_params

    def insert_chunk(
        self,
        alter,
        extracts,
        chunk,
        all_columns,
        hash_id,
        upsert,
        pk,
        conversions,
        num_records_processed,
        replace,
        ignore,
    ):
        queries_and_params = self.build_insert_queries_and_params(
            extracts,
            chunk,
            all_columns,
            hash_id,
            upsert,
            pk,
            conversions,
            num_records_processed,
            replace,
            ignore,
        )

        with self.db.conn:
            result = None
            for query, params in queries_and_params:
                try:
                    result = self.db.execute(query, params)
                except OperationalError as e:
                    if alter and (" column" in e.args[0]):
                        # Attempt to add any missing columns, then try again
                        self.add_missing_columns(chunk)
                        result = self.db.execute(query, params)
                    elif e.args[0] == "too many SQL variables":

                        first_half = chunk[: len(chunk) // 2]
                        second_half = chunk[len(chunk) // 2 :]

                        self.insert_chunk(
                            alter,
                            extracts,
                            first_half,
                            all_columns,
                            hash_id,
                            upsert,
                            pk,
                            conversions,
                            num_records_processed,
                            replace,
                            ignore,
                        )

                        self.insert_chunk(
                            alter,
                            extracts,
                            second_half,
                            all_columns,
                            hash_id,
                            upsert,
                            pk,
                            conversions,
                            num_records_processed,
                            replace,
                            ignore,
                        )

                    else:
                        raise
            if num_records_processed == 1 and not upsert:
                self.last_rowid = result.lastrowid
                self.last_pk = self.last_rowid
                # self.last_rowid will be 0 if a "INSERT OR IGNORE" happened
                if (hash_id or pk) and self.last_rowid:
                    row = list(self.rows_where("rowid = ?", [self.last_rowid]))[0]
                    if hash_id:
                        self.last_pk = row[hash_id]
                    elif isinstance(pk, str):
                        self.last_pk = row[pk]
                    else:
                        self.last_pk = tuple(row[p] for p in pk)

        return

    def insert(
        self,
        record: Dict[str, Any],
        pk=DEFAULT,
        foreign_keys=DEFAULT,
        column_order: Optional[Union[List[str], Default]] = DEFAULT,
        not_null: Optional[Union[Set[str], Default]] = DEFAULT,
        defaults: Optional[Union[Dict[str, Any], Default]] = DEFAULT,
        hash_id: Optional[Union[str, Default]] = DEFAULT,
        alter: Optional[Union[bool, Default]] = DEFAULT,
        ignore: Optional[Union[bool, Default]] = DEFAULT,
        replace: Optional[Union[bool, Default]] = DEFAULT,
        extracts: Optional[Union[Dict[str, str], List[str], Default]] = DEFAULT,
        conversions: Optional[Union[Dict[str, str], Default]] = DEFAULT,
        columns: Optional[Union[Dict[str, Any], Default]] = DEFAULT,
    ) -> "Table":
        """
        Insert a single record into the table. The table will be created with a schema that matches
        the inserted record if it does not already exist, see :ref:`python_api_creating_tables`.

        - ``record`` - required: a dictionary representing the record to be inserted.

        The other parameters are optional, and mostly influence how the new table will be created if
        that table does not exist yet.

        Each of them defaults to ``DEFAULT``, which indicates that the default setting for the current
        ``Table`` object (specified in the table constructor) should be used.

        - ``pk`` - if creating the table, which column should be the primary key.
        - ``foreign_keys`` - see :ref:`python_api_foreign_keys`.
        - ``column_order`` - optional list of strings specifying a full or partial column order
          to use when creating the table.
        - ``not_null`` - optional set of strings specifying columns that should be ``NOT NULL``.
        - ``defaults`` - optional dictionary specifying default values for specific columns.
        - ``hash_id`` - optional name of a column to create and use as a primary key, where the
          value of thet primary key will be derived as a SHA1 hash of the other column values
          in the record. ``hash_id="id"`` is a common column name used for this.
        - ``alter`` - boolean, should any missing columns be added automatically?
        - ``ignore`` - boolean, if a record already exists with this primary key, ignore this insert.
        - ``replace`` - boolean, if a record already exists with this primary key, replace it with this new record.
        - ``extracts`` - a list of columns to extract to other tables, or a dictionary that maps
          ``{column_name: other_table_name}``. See :ref:`python_api_extracts`.
        - ``conversions`` - dictionary specifying SQL conversion functions to be applied to the data while it
          is being inserted, for example ``{"name": "upper(?)"}``. See :ref:`python_api_conversions`.
        - ``columns`` - dictionary over-riding the detected types used for the columns, for example
          ``{"age": int, "weight": float}``.
        """
        return self.insert_all(
            [record],
            pk=pk,
            foreign_keys=foreign_keys,
            column_order=column_order,
            not_null=not_null,
            defaults=defaults,
            hash_id=hash_id,
            alter=alter,
            ignore=ignore,
            replace=replace,
            extracts=extracts,
            conversions=conversions,
            columns=columns,
        )

    def insert_all(
        self,
        records,
        pk=DEFAULT,
        foreign_keys=DEFAULT,
        column_order=DEFAULT,
        not_null=DEFAULT,
        defaults=DEFAULT,
        batch_size=DEFAULT,
        hash_id=DEFAULT,
        alter=DEFAULT,
        ignore=DEFAULT,
        replace=DEFAULT,
        truncate=False,
        extracts=DEFAULT,
        conversions=DEFAULT,
        columns=DEFAULT,
        upsert=False,
    ) -> "Table":
        """
        Like ``.insert()`` but takes a list of records and ensures that the table
        that it creates (if table does not exist) has columns for ALL of that data.
        """
        pk = self.value_or_default("pk", pk)
        foreign_keys = self.value_or_default("foreign_keys", foreign_keys)
        column_order = self.value_or_default("column_order", column_order)
        not_null = self.value_or_default("not_null", not_null)
        defaults = self.value_or_default("defaults", defaults)
        batch_size = self.value_or_default("batch_size", batch_size)
        hash_id = self.value_or_default("hash_id", hash_id)
        alter = self.value_or_default("alter", alter)
        ignore = self.value_or_default("ignore", ignore)
        replace = self.value_or_default("replace", replace)
        extracts = self.value_or_default("extracts", extracts)
        conversions = self.value_or_default("conversions", conversions)
        columns = self.value_or_default("columns", columns)

        if upsert and (not pk and not hash_id):
            raise PrimaryKeyRequired("upsert() requires a pk")
        assert not (hash_id and pk), "Use either pk= or hash_id="
        if hash_id:
            pk = hash_id

        assert not (
            ignore and replace
        ), "Use either ignore=True or replace=True, not both"
        all_columns = []
        first = True
        num_records_processed = 0
        # We can only handle a max of 999 variables in a SQL insert, so
        # we need to adjust the batch_size down if we have too many cols
        records = iter(records)
        # Peek at first record to count its columns:
        try:
            first_record = next(records)
        except StopIteration:
            return self  # It was an empty list
        num_columns = len(first_record.keys())
        assert (
            num_columns <= SQLITE_MAX_VARS
        ), "Rows can have a maximum of {} columns".format(SQLITE_MAX_VARS)
        batch_size = max(1, min(batch_size, SQLITE_MAX_VARS // num_columns))
        self.last_rowid = None
        self.last_pk = None
        if truncate and self.exists():
            self.db.execute("DELETE FROM [{}];".format(self.name))
        for chunk in chunks(itertools.chain([first_record], records), batch_size):
            chunk = list(chunk)
            num_records_processed += len(chunk)
            if first:
                if not self.exists():
                    # Use the first batch to derive the table names
                    column_types = suggest_column_types(chunk)
                    column_types.update(columns or {})
                    self.create(
                        column_types,
                        pk,
                        foreign_keys,
                        column_order=column_order,
                        not_null=not_null,
                        defaults=defaults,
                        hash_id=hash_id,
                        extracts=extracts,
                    )
                all_columns_set = set()
                for record in chunk:
                    all_columns_set.update(record.keys())
                all_columns = list(sorted(all_columns_set))
                if hash_id:
                    all_columns.insert(0, hash_id)
            else:
                for record in chunk:
                    all_columns += [
                        column for column in record if column not in all_columns
                    ]

            validate_column_names(all_columns)
            first = False

            self.insert_chunk(
                alter,
                extracts,
                chunk,
                all_columns,
                hash_id,
                upsert,
                pk,
                conversions,
                num_records_processed,
                replace,
                ignore,
            )

        return self

    def upsert(
        self,
        record,
        pk=DEFAULT,
        foreign_keys=DEFAULT,
        column_order=DEFAULT,
        not_null=DEFAULT,
        defaults=DEFAULT,
        hash_id=DEFAULT,
        alter=DEFAULT,
        extracts=DEFAULT,
        conversions=DEFAULT,
        columns=DEFAULT,
    ) -> "Table":
        """
        Like ``.insert()`` but performs an ``UPSERT``, where records are inserted if they do
        not exist and updated if they DO exist, based on matching against their primary key.

        See :ref:`python_api_upsert`.
        """
        return self.upsert_all(
            [record],
            pk=pk,
            foreign_keys=foreign_keys,
            column_order=column_order,
            not_null=not_null,
            defaults=defaults,
            hash_id=hash_id,
            alter=alter,
            extracts=extracts,
            conversions=conversions,
            columns=columns,
        )

    def upsert_all(
        self,
        records,
        pk=DEFAULT,
        foreign_keys=DEFAULT,
        column_order=DEFAULT,
        not_null=DEFAULT,
        defaults=DEFAULT,
        batch_size=DEFAULT,
        hash_id=DEFAULT,
        alter=DEFAULT,
        extracts=DEFAULT,
        conversions=DEFAULT,
        columns=DEFAULT,
    ) -> "Table":
        """
        Like ``.upsert()`` but can be applied to a list of records.
        """
        return self.insert_all(
            records,
            pk=pk,
            foreign_keys=foreign_keys,
            column_order=column_order,
            not_null=not_null,
            defaults=defaults,
            batch_size=batch_size,
            hash_id=hash_id,
            alter=alter,
            extracts=extracts,
            conversions=conversions,
            columns=columns,
            upsert=True,
        )

    def add_missing_columns(self, records: Iterable[Dict[str, Any]]) -> "Table":
        needed_columns = suggest_column_types(records)
        current_columns = {c.lower() for c in self.columns_dict}
        for col_name, col_type in needed_columns.items():
            if col_name.lower() not in current_columns:
                self.add_column(col_name, col_type)
        return self

    def lookup(self, column_values: Dict[str, Any]):
        """
        Create or populate a lookup table with the specified values.

        ``db["Species"].lookup({"name": "Palm"})`` will create a table called ``Species``
        (if one does not already exist) with two columns: ``id`` and ``name``. It will
        set up a unique constraint on the ``name`` column to guarantee it will not
        contain duplicate rows.

        It well then inserts a new row with the ``name`` set to ``Palm`` and return the
        new integer primary key value.

        See :ref:`python_api_lookup_tables` for more details.
        """
        # lookups is a dictionary - all columns will be used for a unique index
        assert isinstance(column_values, dict)
        if self.exists():
            self.add_missing_columns([column_values])
            unique_column_sets = [set(i.columns) for i in self.indexes]
            if set(column_values.keys()) not in unique_column_sets:
                self.create_index(column_values.keys(), unique=True)
            wheres = ["[{}] = ?".format(column) for column in column_values]
            rows = list(
                self.rows_where(
                    " and ".join(wheres), [value for _, value in column_values.items()]
                )
            )
            try:
                return rows[0]["id"]
            except IndexError:
                return self.insert(column_values, pk="id").last_pk
        else:
            pk = self.insert(column_values, pk="id").last_pk
            self.create_index(column_values.keys(), unique=True)
            return pk

    def m2m(
        self,
        other_table: Union[str, "Table"],
        record_or_iterable: Optional[
            Union[Iterable[Dict[str, Any]], Dict[str, Any]]
        ] = None,
        pk: Optional[Union[Any, Default]] = DEFAULT,
        lookup: Optional[Dict[str, Any]] = None,
        m2m_table: Optional[str] = None,
        alter: bool = False,
    ):
        """
        After inserting a record in a table, create one or more records in some other
        table and then create many-to-many records linking the original record and the
        newly created records together.

        For example::

            db["dogs"].insert({"id": 1, "name": "Cleo"}, pk="id").m2m(
                "humans", {"id": 1, "name": "Natalie"}, pk="id"
            )

        See :ref:`python_api_m2m` for details.

        - ``other_table`` - the name of the table to insert the new records into.
        - ``record_or_iterable`` - a single dictionary record to insert, or a list of records.
        - ``pk`` - the primary key to use if creating ``other_table``.
        - ``lookup`` - same dictionary as for ``.lookup()``, to create a many-to-many lookup table.
        - ``m2m_table`` - the string name to use for the many-to-many table, defaults to creating
          this automatically based on the names of the two tables.
        - ``alter`` - set to ``True`` to add any missing columns on ``other_table`` if that table
          already exists.
        """
        if isinstance(other_table, str):
            other_table = cast(Table, self.db.table(other_table, pk=pk))
        our_id = self.last_pk
        if lookup is not None:
            assert record_or_iterable is None, "Provide lookup= or record, not both"
        else:
            assert record_or_iterable is not None, "Provide lookup= or record, not both"
        tables = list(sorted([self.name, other_table.name]))
        columns = ["{}_id".format(t) for t in tables]
        if m2m_table is not None:
            m2m_table_name = m2m_table
        else:
            # Detect if there is a single, unambiguous option
            candidates = self.db.m2m_table_candidates(self.name, other_table.name)
            if len(candidates) == 1:
                m2m_table_name = candidates[0]
            elif len(candidates) > 1:
                raise NoObviousTable(
                    "No single obvious m2m table for {}, {} - use m2m_table= parameter".format(
                        self.name, other_table.name
                    )
                )
            else:
                # If not, create a new table
                m2m_table_name = m2m_table or "{}_{}".format(*tables)
        m2m_table_obj = self.db.table(m2m_table_name, pk=columns, foreign_keys=columns)
        if lookup is None:
            # if records is only one record, put the record in a list
            if isinstance(record_or_iterable, Mapping):
                records = [record_or_iterable]
            else:
                records = cast(List, record_or_iterable)
            # Ensure each record exists in other table
            for record in records:
                id = other_table.insert(
                    cast(dict, record), pk=pk, replace=True, alter=alter
                ).last_pk
                m2m_table_obj.insert(
                    {
                        "{}_id".format(other_table.name): id,
                        "{}_id".format(self.name): our_id,
                    },
                    replace=True,
                )
        else:
            id = other_table.lookup(lookup)
            m2m_table_obj.insert(
                {
                    "{}_id".format(other_table.name): id,
                    "{}_id".format(self.name): our_id,
                },
                replace=True,
            )
        return self

    def analyze_column(
        self, column: str, common_limit: int = 10, value_truncate=None, total_rows=None
    ) -> "ColumnDetails":
        """
        Return statistics about the specified column.

        See :ref:`python_api_analyze_column`.
        """
        db = self.db
        table = self.name
        if total_rows is None:
            total_rows = db[table].count

        def truncate(value):
            if value_truncate is None or isinstance(value, (float, int)):
                return value
            value = str(value)
            if len(value) > value_truncate:
                value = value[:value_truncate] + "..."
            return value

        num_null = db.execute(
            "select count(*) from [{}] where [{}] is null".format(table, column)
        ).fetchone()[0]
        num_blank = db.execute(
            "select count(*) from [{}] where [{}] = ''".format(table, column)
        ).fetchone()[0]
        num_distinct = db.execute(
            "select count(distinct [{}]) from [{}]".format(column, table)
        ).fetchone()[0]
        most_common = None
        least_common = None
        if num_distinct == 1:
            value = db.execute(
                "select [{}] from [{}] limit 1".format(column, table)
            ).fetchone()[0]
            most_common = [(truncate(value), total_rows)]
        elif num_distinct != total_rows:
            most_common = [
                (truncate(r[0]), r[1])
                for r in db.execute(
                    "select [{}], count(*) from [{}] group by [{}] order by count(*) desc, [{}] limit {}".format(
                        column, table, column, column, common_limit
                    )
                ).fetchall()
            ]
            most_common.sort(key=lambda p: (p[1], p[0]), reverse=True)
            if num_distinct <= common_limit:
                # No need to run the query if it will just return the results in revers order
                least_common = None
            else:
                least_common = [
                    (truncate(r[0]), r[1])
                    for r in db.execute(
                        "select [{}], count(*) from [{}] group by [{}] order by count(*), [{}] desc limit {}".format(
                            column, table, column, column, common_limit
                        )
                    ).fetchall()
                ]
                least_common.sort(key=lambda p: (p[1], p[0]))
        return ColumnDetails(
            self.name,
            column,
            total_rows,
            num_null,
            num_blank,
            num_distinct,
            most_common,
            least_common,
        )


class View(Queryable):
    def exists(self):
        return True

    def __repr__(self):
        return "<View {} ({})>".format(
            self.name, ", ".join(c.name for c in self.columns)
        )

    def drop(self, ignore=False):
        try:
            self.db.execute("DROP VIEW [{}]".format(self.name))
        except sqlite3.OperationalError:
            if not ignore:
                raise

    def enable_fts(self, *args, **kwargs):
        raise NotImplementedError(
            "enable_fts() is supported on tables but not on views"
        )


def chunks(sequence, size):
    iterator = iter(sequence)
    for item in iterator:
        yield itertools.chain([item], itertools.islice(iterator, size - 1))


def jsonify_if_needed(value):
    if isinstance(value, decimal.Decimal):
        return float(value)
    if isinstance(value, (dict, list, tuple)):
        return json.dumps(value, default=repr, ensure_ascii=False)
    elif isinstance(value, (datetime.time, datetime.date, datetime.datetime)):
        return value.isoformat()
    elif isinstance(value, uuid.UUID):
        return str(value)
    else:
        return value


def _hash(record):
    return hashlib.sha1(
        json.dumps(record, separators=(",", ":"), sort_keys=True, default=repr).encode(
            "utf8"
        )
    ).hexdigest()


def resolve_extracts(
    extracts: Optional[Union[Dict[str, str], List[str], Tuple[str]]]
) -> dict:
    if extracts is None:
        extracts = {}
    if isinstance(extracts, (list, tuple)):
        extracts = {item: item for item in extracts}
    return extracts


def validate_column_names(columns):
    # Validate no columns contain '[' or ']' - #86
    for column in columns:
        assert (
            "[" not in column and "]" not in column
        ), "'[' and ']' cannot be used in column names"
