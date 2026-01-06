from dateutil import parser
import json


def parsedate(value, dayfirst=False, yearfirst=False):
    "Parse a date and convert it to ISO date format: yyyy-mm-dd"
    return (
        parser.parse(value, dayfirst=dayfirst, yearfirst=yearfirst).date().isoformat()
    )


def parsedatetime(value, dayfirst=False, yearfirst=False):
    "Parse a datetime and convert it to ISO datetime format: yyyy-mm-ddTHH:MM:SS"
    return parser.parse(value, dayfirst=dayfirst, yearfirst=yearfirst).isoformat()


def jsonsplit(value, delimiter=",", type=str):
    'Convert a string like a,b,c into a JSON array ["a", "b", "c"]'
    return json.dumps([type(s.strip()) for s in value.split(delimiter)])
