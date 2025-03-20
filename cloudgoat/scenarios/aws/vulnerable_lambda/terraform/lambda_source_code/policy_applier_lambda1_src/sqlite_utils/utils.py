import base64
import contextlib
import csv
import enum
import io
import json
import os
from typing import cast, BinaryIO, Iterable, Optional, Tuple, Type

import click

try:
    import pysqlite3 as sqlite3  # type: ignore
    import pysqlite3.dbapi2  # type: ignore

    OperationalError = pysqlite3.dbapi2.OperationalError
except ImportError:
    # https://github.com/python/mypy/issues/1153#issuecomment-253842414
    import sqlite3  # type: ignore

    OperationalError = sqlite3.OperationalError

SPATIALITE_PATHS = (
    "/usr/lib/x86_64-linux-gnu/mod_spatialite.so",
    "/usr/local/lib/mod_spatialite.dylib",
)


def suggest_column_types(records):
    all_column_types = {}
    for record in records:
        for key, value in record.items():
            all_column_types.setdefault(key, set()).add(type(value))
    return types_for_column_types(all_column_types)


def types_for_column_types(all_column_types):
    column_types = {}
    for key, types in all_column_types.items():
        # Ignore null values if at least one other type present:
        if len(types) > 1:
            types.discard(None.__class__)
        if {None.__class__} == types:
            t = str
        elif len(types) == 1:
            t = list(types)[0]
            # But if it's a subclass of list / tuple / dict, use str
            # instead as we will be storing it as JSON in the table
            for superclass in (list, tuple, dict):
                if issubclass(t, superclass):
                    t = str
        elif {int, bool}.issuperset(types):
            t = int
        elif {int, float, bool}.issuperset(types):
            t = float
        elif {bytes, str}.issuperset(types):
            t = bytes
        else:
            t = str
        column_types[key] = t
    return column_types


def column_affinity(column_type):
    # Implementation of SQLite affinity rules from
    # https://www.sqlite.org/datatype3.html#determination_of_column_affinity
    assert isinstance(column_type, str)
    column_type = column_type.upper().strip()
    if column_type == "":
        return str  # We differ from spec, which says it should be BLOB
    if "INT" in column_type:
        return int
    if "CHAR" in column_type or "CLOB" in column_type or "TEXT" in column_type:
        return str
    if "BLOB" in column_type:
        return bytes
    if "REAL" in column_type or "FLOA" in column_type or "DOUB" in column_type:
        return float
    # Default is 'NUMERIC', which we currently also treat as float
    return float


def decode_base64_values(doc):
    # Looks for '{"$base64": true..., "encoded": ...}' values and decodes them
    to_fix = [
        k
        for k in doc
        if isinstance(doc[k], dict)
        and doc[k].get("$base64") is True
        and "encoded" in doc[k]
    ]
    if not to_fix:
        return doc
    return dict(doc, **{k: base64.b64decode(doc[k]["encoded"]) for k in to_fix})


def find_spatialite():
    for path in SPATIALITE_PATHS:
        if os.path.exists(path):
            return path
    return None


class UpdateWrapper:
    def __init__(self, wrapped, update):
        self._wrapped = wrapped
        self._update = update

    def __iter__(self):
        for line in self._wrapped:
            self._update(len(line))
            yield line


@contextlib.contextmanager
def file_progress(file, silent=False, **kwargs):
    if silent:
        yield file
        return
    # file.fileno() throws an exception in our test suite
    try:
        fileno = file.fileno()
    except io.UnsupportedOperation:
        yield file
        return
    if fileno == 0:  # 0 means stdin
        yield file
    else:
        file_length = os.path.getsize(file.name)
        with click.progressbar(length=file_length, **kwargs) as bar:
            yield UpdateWrapper(file, bar.update)


class Format(enum.Enum):
    CSV = 1
    TSV = 2
    JSON = 3
    NL = 4


class RowsFromFileError(Exception):
    pass


class RowsFromFileBadJSON(RowsFromFileError):
    pass


def rows_from_file(
    fp: BinaryIO,
    format: Optional[Format] = None,
    dialect: Optional[Type[csv.Dialect]] = None,
    encoding: Optional[str] = None,
) -> Tuple[Iterable[dict], Format]:
    if format == Format.JSON:
        decoded = json.load(fp)
        if isinstance(decoded, dict):
            decoded = [decoded]
        if not isinstance(decoded, list):
            raise RowsFromFileBadJSON("JSON must be a list or a dictionary")
        return decoded, Format.JSON
    elif format == Format.NL:
        return (json.loads(line) for line in fp if line.strip()), Format.NL
    elif format == Format.CSV:
        use_encoding: str = encoding or "utf-8-sig"
        decoded_fp = io.TextIOWrapper(fp, encoding=use_encoding)
        if dialect is not None:
            reader = csv.DictReader(decoded_fp, dialect=dialect)
        else:
            reader = csv.DictReader(decoded_fp)
        return reader, Format.CSV
    elif format == Format.TSV:
        return (
            rows_from_file(
                fp, format=Format.CSV, dialect=csv.excel_tab, encoding=encoding
            )[0],
            Format.TSV,
        )
    elif format is None:
        # Detect the format, then call this recursively
        buffered = io.BufferedReader(cast(io.RawIOBase, fp), buffer_size=4096)
        first_bytes = buffered.peek(2048).strip()
        if first_bytes.startswith(b"[") or first_bytes.startswith(b"{"):
            # TODO: Detect newline-JSON
            return rows_from_file(buffered, format=Format.JSON)
        else:
            dialect = csv.Sniffer().sniff(
                first_bytes.decode(encoding or "utf-8-sig", "ignore")
            )
            return rows_from_file(
                buffered, format=Format.CSV, dialect=dialect, encoding=encoding
            )
    else:
        raise RowsFromFileError("Bad format")


class TypeTracker:
    def __init__(self):
        self.trackers = {}

    def wrap(self, iterator):
        for row in iterator:
            for key, value in row.items():
                tracker = self.trackers.setdefault(key, ValueTracker())
                tracker.evaluate(value)
            yield row

    @property
    def types(self):
        return {key: tracker.guessed_type for key, tracker in self.trackers.items()}


class ValueTracker:
    def __init__(self):
        self.couldbe = {key: getattr(self, "test_" + key) for key in self.get_tests()}

    @classmethod
    def get_tests(cls):
        return [
            key.split("test_")[-1]
            for key in cls.__dict__.keys()
            if key.startswith("test_")
        ]

    def test_integer(self, value):
        try:
            int(value)
            return True
        except (ValueError, TypeError):
            return False

    def test_float(self, value):
        try:
            float(value)
            return True
        except (ValueError, TypeError):
            return False

    def __repr__(self):
        return self.guessed_type + ": possibilities = " + repr(self.couldbe)

    @property
    def guessed_type(self):
        options = set(self.couldbe.keys())
        # Return based on precedence
        for key in self.get_tests():
            if key in options:
                return key
        return "text"

    def evaluate(self, value):
        if not value or not self.couldbe:
            return
        not_these = []
        for name, test in self.couldbe.items():
            if not test(value):
                not_these.append(name)
        for key in not_these:
            del self.couldbe[key]


class NullProgressBar:
    def __init__(self, *args):
        self.args = args

    def __iter__(self):
        yield from self.args[0]

    def update(self, value):
        pass


@contextlib.contextmanager
def progressbar(*args, **kwargs):
    silent = kwargs.pop("silent")
    if silent:
        yield NullProgressBar(*args)
    else:
        with click.progressbar(*args, **kwargs) as bar:
            yield bar
