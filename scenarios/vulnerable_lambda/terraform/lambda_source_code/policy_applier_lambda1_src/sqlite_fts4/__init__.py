import struct
import math
import json
import traceback
from functools import wraps


def register_functions(conn):
    "Registers these custom functions against an SQLite connection"
    conn.create_function("rank_score", 1, rank_score)
    conn.create_function("decode_matchinfo", 1, decode_matchinfo_str)
    conn.create_function("annotate_matchinfo", 2, annotate_matchinfo)
    conn.create_function("rank_bm25", 1, rank_bm25)


def wrap_sqlite_function_in_error_logger(fn):
    # Because SQLite swallows exceptions inside custom functions
    @wraps(fn)
    def wrapper(*args, **kwargs):
        try:
            return fn(*args, **kwargs)
        except Exception:
            traceback.print_exc()
            raise

    return wrapper


def decode_matchinfo_str(buf):
    return str(list(decode_matchinfo(buf)))


def decode_matchinfo(buf):
    # buf is a bytestring of unsigned integers, each 4 bytes long
    return struct.unpack("I" * (len(buf) // 4), buf)


def _error(m):
    return {"error": m}


@wrap_sqlite_function_in_error_logger
def annotate_matchinfo(buf, format_string):
    return json.dumps(_annotate_matchinfo(buf, format_string), indent=2)


def _annotate_matchinfo(buf, format_string):
    # See https://www.sqlite.org/fts3.html#matchinfo for detailed specification
    matchinfo = list(decode_matchinfo(buf))
    if not matchinfo:
        return {}
    matchinfo_index = 0
    p_num_phrases = None
    c_num_columns = None

    def _next():
        nonlocal matchinfo_index
        value = matchinfo[matchinfo_index]
        matchinfo_index += 1
        return value, matchinfo_index - 1

    results = {}
    for ch in format_string:
        if ch == "p":
            p_num_phrases, idx = _next()
            results["p"] = {
                "value": p_num_phrases,
                "title": "Number of matchable phrases in the query",
                "idx": idx,
            }
        elif ch == "c":
            c_num_columns, idx = _next()
            results["c"] = {
                "value": c_num_columns,
                "title": "Number of user defined columns in the FTS table",
                "idx": idx,
            }
        elif ch == "x":
            # Depends on p and c
            if None in (p_num_phrases, c_num_columns):
                return _error("'x' must be preceded by 'p' and 'c'")
            info = []
            results["x"] = {
                "value": info,
                "title": "Details for each phrase/column combination",
            }
            # 3 * c_num_columns * p_num_phrases
            for phrase_index in range(p_num_phrases):
                for column_index in range(c_num_columns):
                    hits_this_column_this_row, idx1 = _next()
                    hits_this_column_all_rows, idx2 = _next()
                    docs_with_hits, idx3 = _next()
                    info.append(
                        {
                            "phrase_index": phrase_index,
                            "column_index": column_index,
                            "hits_this_column_this_row": hits_this_column_this_row,
                            "hits_this_column_all_rows": hits_this_column_all_rows,
                            "docs_with_hits": docs_with_hits,
                            "idxs": [idx1, idx2, idx3],
                        }
                    )
        elif ch == "y":
            if None in (p_num_phrases, c_num_columns):
                return _error("'y' must be preceded by 'p' and 'c'")
            info = []
            results["y"] = {
                "value": info,
                "title": "Usable phrase matches for each phrase/column combination",
            }
            for phrase_index in range(p_num_phrases):
                for column_index in range(c_num_columns):
                    hits_for_phrase_in_col, idx = _next()
                    info.append(
                        {
                            "phrase_index": phrase_index,
                            "column_index": column_index,
                            "hits_for_phrase_in_col": hits_for_phrase_in_col,
                            "idx": idx,
                        }
                    )
        elif ch == "b":
            if None in (p_num_phrases, c_num_columns):
                return _error("'b' must be preceded by 'p' and 'c'")
            values = []
            # We get back one integer for each 32 columns for each phrase
            num_32_column_chunks = (c_num_columns + 31) // 32
            decoded = {}
            for phrase_index in range(p_num_phrases):
                current_phrase_chunks = []
                for _ in range(num_32_column_chunks):
                    v = _next()[0]
                    values.append(v)
                    current_phrase_chunks.append(v)
                decoded["phrase_{}".format(phrase_index)] = "".join(
                    [
                        "{:032b}".format(unsigned_integer)[::-1]
                        for unsigned_integer in current_phrase_chunks
                    ]
                )
            results["b"] = {
                "title": "Bitfield showing which phrases occur in which columns",
                "value": values,
                # Each integer is a 32bit unsigned integer, least significant
                # bit is column 0, then column 1, then so on
                "decoded": decoded,
            }
        elif ch == "n":
            value, idx = _next()
            results["n"] = {
                "value": value,
                "title": "Number of rows in the FTS4 table",
                "idx": idx,
            }
        elif ch == "a":
            if c_num_columns is None:
                return _error("'a' must be preceded by 'c'")
            values = []
            for i in range(c_num_columns):
                value, idx = _next()
                values.append(
                    {"column_index": i, "average_num_tokens": value, "idx": idx}
                )
            results["a"] = {
                "title": "Average number of tokens in each column across the whole table",
                "value": values,
            }
        elif ch == "l":
            if c_num_columns is None:
                return _error("'l' must be preceded by 'c'")
            values = []
            for i in range(c_num_columns):
                value, idx = _next()
                values.append({"column_index": i, "num_tokens": value, "idx": idx})
            results["l"] = {
                "title": "Number of tokens in each column of the current row of the FTS4 table",
                "value": values,
            }
        elif ch == "s":
            if c_num_columns is None:
                return _error("'s' must be preceded by 'c'")
            values = []
            for i in range(c_num_columns):
                value, idx = _next()
                values.append(
                    {
                        "column_index": i,
                        "length_phrase_subsequence_match": value,
                        "idx": idx,
                    }
                )
            results["s"] = {
                "title": "Length of longest subsequence of phrase matching each column",
                "value": values,
            }
    return results


@wrap_sqlite_function_in_error_logger
def rank_score(raw_matchinfo):
    # Score using matchinfo called w/default args 'pcx' - based on example rank
    # function http://sqlite.org/fts3.html#appendix_a
    # The overall relevancy returned is the sum of the relevancies of each
    # column value in the FTS table. The relevancy of a column value is the
    # sum of the following for each reportable phrase in the FTS query:
    #   (<hit count > / <global hit count>)
    if not raw_matchinfo:
        return None
    matchinfo = _annotate_matchinfo(raw_matchinfo, "pcx")
    score = 0.0
    x_phrase_column_details = matchinfo["x"]["value"]
    for details in x_phrase_column_details:
        hits_this_column_this_row = details["hits_this_column_this_row"]
        hits_this_column_all_rows = details["hits_this_column_all_rows"]
        if hits_this_column_this_row > 0:
            score += float(hits_this_column_this_row) / hits_this_column_all_rows
    return -score


@wrap_sqlite_function_in_error_logger
def rank_bm25(raw_match_info):
    "Must be called with output of matchinfo 'pcnalx'"
    if not raw_match_info:
        return None
    match_info = _annotate_matchinfo(raw_match_info, "pcnalx")
    # How much should multiple matches in the same document increase the score?
    k = 1.2
    # How much should document length affect the score? (shorter docs = higher score)
    b = 0.75
    score = 0.0

    phrase_count = match_info["p"]["value"]
    column_count = match_info["c"]["value"]
    total_row_count = match_info["n"]["value"]

    for phrase_index in range(phrase_count):
        for column_index in range(column_count):
            average_num_tokens = match_info["a"]["value"][column_index][
                "average_num_tokens"
            ]
            num_tokens = match_info["l"]["value"][column_index]["num_tokens"]
            if average_num_tokens == 0:
                d = 0
            else:
                d = 1 - b + (b * (float(num_tokens) / float(average_num_tokens)))

            phrase_column_x = [
                v
                for v in match_info["x"]["value"]
                if v["column_index"] == column_index
                and v["phrase_index"] == phrase_index
            ][0]
            term_frequency = float(phrase_column_x["hits_this_column_this_row"])
            docs_with_hits = float(phrase_column_x["docs_with_hits"])

            # idf = inverse document frequency: is this term rare or common
            # across our entire corpus?
            idf = max(
                math.log(
                    (total_row_count - docs_with_hits + 0.5) / (docs_with_hits + 0.5)
                ),
                0,
            )
            denom = term_frequency + (k * d)
            if denom == 0:
                rhs = 0
            else:
                rhs = (term_frequency * (k + 1)) / denom

            score += idf * rhs

    return -score
