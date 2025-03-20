from __future__ import print_function
from datetime import datetime
from dateutil.parser import parse
from argparse import ArgumentParser


def get_arguments():
    a = ArgumentParser(description="Perform various operations on dates and date ranges.")

    a.add_argument('start', metavar='START', help="the start date")
    a.add_argument('end', nargs='?', metavar='END', help="the end date")

    a.add_argument('-y', '--years', action='store_const', dest='unit', const='years', help='show difference in years')
    a.add_argument('-m', '--months', action='store_const', dest='unit', const='months', help='show difference in months')
    a.add_argument('-w', '--weeks', action='store_const', dest='unit', const='weeks', help='show difference in weeks')
    a.add_argument('-d', '--days', action='store_const', dest='unit', const='days', help='show difference in days')
    a.add_argument('-H', '--hours', action='store_const', dest='unit', const='hours', help='show difference in hours')
    a.add_argument('-M', '--minutes', action='store_const', dest='unit', const='minutes', help='show difference in minutes')
    a.add_argument('-S', '--seconds', action='store_const', dest='unit', const='seconds', help='show difference in seconds')
    a.add_argument('-u', '--microseconds', action='store_const', dest='unit', const='microseconds', help='show difference in microseconds')
    a.add_argument('-b', '--business-days', action='store_const', dest='unit', const='business_days', help='show difference in business days')

    a.add_argument('--holiday', metavar='DATE', action='append', help='holiday to include')
    a.add_argument('--holiday-file', metavar='FILE', help='holidays to include from a file')

    return a.parse_args()


def main():
    args = get_arguments()
    start_dt = parse(args.start)
    end_dt = datetime.now if not args.end else parse(args.end)
    kwargs = {}
    if args.unit == 'business_days':
        holidays = []
        if args.holiday:
            holidays.extend(parse(h) for h in args.holiday)
        if args.holiday_file:
            holidays.extend(parse(l) for l in open(args.holiday_file))
        kwargs['holidays'] = holidays
    print(__import__(args.unit)(end_dt, start_dt, **kwargs))
