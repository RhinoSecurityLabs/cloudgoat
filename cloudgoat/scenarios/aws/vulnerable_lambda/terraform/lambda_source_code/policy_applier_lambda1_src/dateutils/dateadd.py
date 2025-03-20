from __future__ import print_function
from . import TIME_UNITS, date_range, increment
from dateutil.parser import parse
from datetime import datetime
from argparse import ArgumentParser


def get_arguments():
    a = ArgumentParser(description="Increment/decrement a date by some unit(s) of time.")

    a.add_argument('dates', metavar='DATE', nargs='*', help='a date to increment/decrement')

    a.add_argument('-F', '--format', default='%Y-%m-%d %H:%M:%S', help='use STRING as output format')
    a.add_argument('-I', '--iterate', default=False, action='store_true', help='expand a date range')

    a.add_argument('-y', '--years', metavar='NUM', type=int, default=0, help='add NUM years to date(s)')
    a.add_argument('-m', '--months', metavar='NUM', type=int, default=0, help='add NUM months to date(s)')
    a.add_argument('-w', '--weeks', metavar='NUM', type=int, default=0, help='add NUM weeks to date(s)')
    a.add_argument('-d', '--days', metavar='NUM', type=int, default=0, help='add NUM days to date(s)')
    a.add_argument('-H', '--hours', metavar='NUM', type=int, default=0, help='add NUM hours to date(s)')
    a.add_argument('-M', '--minutes', metavar='NUM', type=int, default=0, help='add NUM minutes to date(s)')
    a.add_argument('-S', '--seconds', metavar='NUM', type=int, default=0, help='add NUM seconds to date(s)')
    a.add_argument('-u', '--microseconds', metavar='NUM', type=int, default=0, help='add NUM microseconds to date(s)')
    a.add_argument('-b', '--business-days', metavar='NUM', type=int, default=0, help='add NUM business days to date(s)')

    a.add_argument('--holiday', metavar='DATE', action='append', help='holiday to include')
    a.add_argument('--holiday-file', metavar='FILE', help='holidays to include from a file')

    args = a.parse_args()
    kwargs = dict((k, v) for k, v in vars(args).items() if k in TIME_UNITS)
    return args, kwargs


def main():
    args, kwargs = get_arguments()
    # Only care about holidays when looking at business days
    if args.business_days:
        holidays = []
        if args.holiday:
            holidays.extend(parse(h) for h in args.holiday)
        if args.holiday_file:
            holidays.extend(parse(l) for l in open(args.holidays_file))
        kwargs['holidays'] = holidays
    # If iterating, the first two arguments must be start and end dates
    if args.iterate and len(args.dates) == 2:
        start_dt = parse(args.dates[0])
        end_dt = parse(args.dates[1])
        dates = list(date_range(start_dt, end_dt, **kwargs))
    else:
        if args.dates:
            dates = [parse(dt) for dt in args.dates]
        else:
            dates = [datetime.now()]
        if any(bool(v) for v in kwargs.values()):
            dates = [increment(dt, **kwargs) for dt in dates]
    for dt in dates:
        print(dt.strftime(args.format))
