import calendar, pytz, math
from datetime import datetime, date, timedelta
from dateutil.relativedelta import relativedelta

TIME_UNITS = [
    'business_days',
    'years',
    'months',
    'weeks',
    'days',
    'hours',
    'minutes',
    'seconds',
    'microseconds'
    ]

QUARTER_MONTHS = [10, 1, 4, 7]


def timezone(dt, timezone='utc'):
    """Add timezone information to a naive datetime."""
    timezone = pytz.timezone(timezone)
    return datetime(tzinfo=timezone, *dt.timetuple()[:6])


def timezone_convert(dt, timezone):
    """Convert aware datetime to a different timezone."""
    timezone = pytz.timezone(timezone)
    return dt.astimezone(timezone)


def increment(dt, business_days=0, holidays=[], **inc):
    """Increment a date by the given amount.
    Arguments:
        dt -- the date to increment
    Keyword arguments:
        holidays -- list of holiday dates
        business_days -- number of business days to increment
        years -- number of years to increment
        months -- number of months to increment
        weeks -- number of weeks to increment
        days -- number of days to increment
        hours -- number of hours to increment
        minutes -- number of minutes to increment
        seconds -- number of seconds to increment
        microseconds -- number of microseconds to increment
    """
    new_dt = dt + relativedelta(**inc)
    if business_days != 0:
        i = business_days / abs(business_days)
        while business_days != 0:
            while True:
                new_dt = increment(new_dt, days=i)
                if is_business_day(new_dt, holidays):
                    break
            business_days -= i
    return new_dt


def is_business_day(dt, holidays=[]):
    if dt.weekday() in (calendar.SATURDAY, calendar.SUNDAY):
        return False
    if holidays and dt in holidays:
        return False
    return True


def date_range(start_dt, end_dt, holidays=[], **inc):
    """Generate a range of dates/datetimes based on the given increment."""
    # If incrementing by business days, make sure we start on one
    if inc.get('business_days', 0) and not is_business_day(start_dt, holidays=holidays):
        cur_dt = increment(start_dt, business_days=1, holidays=holidays)
    else:
        cur_dt = start_dt
    while cur_dt <= end_dt:
        yield cur_dt
        prev_dt = cur_dt
        cur_dt = increment(cur_dt, **inc)
        if cur_dt == prev_dt:
            break


def month_start(dt):
    """Get the beginning of the month for a given date."""
    return date(*dt.timetuple()[:2]+(1,))


def month_end(dt):
    """Get the end of the month for a given date."""
    return month_start(dt) - timedelta(days=1)


def quarter(dt):
    """Get the quarter for a given date."""
    quarter_months = [range(r, r+3) for r in (i for i in QUARTER_MONTHS)]
    for qm in quarter_months:
        if dt.month in qm:
            return quarter_months.index(qm) + 1


def quarter_start(dt):
    """Get the beginning of the quarter for a given date."""
    m = QUARTER_MONTHS.index(quarter(dt)-1) + 2
    return date(dt.year, m, 1)


def quarter_end(dt):
    """Get the end of the quarter for a given date."""
    m = QUARTER_MONTHS.index(quarter(dt)-1) + 2
    return month_end(date(dt.year, m, 1))


def day_of_year(dt):
    return dt.timetuple()[7]


def microseconds(end_dt, start_dt):
    d = end_dt - start_dt
    return (d.days*24*60*60*1000000)+(d.seconds*1000000)


def seconds(end_dt, start_dt):
    d = end_dt - start_dt
    return (d.days*24*60*60)+d.seconds


def minutes(end_dt, start_dt):
    d = end_dt - start_dt
    return (d.days*24*60)+(d.seconds/60)


def hours(end_dt, start_dt):
    d = end_dt - start_dt
    return (d.days*24)+(d.seconds/60/60)


def days(end_dt, start_dt):
    return (end_dt - start_dt).days


def weeks(end_dt, start_dt):
    return int(math.ceil(days(end_dt, start_dt)/7.0))


def months(end_dt, start_dt):
    return days(end_dt, start_dt)/31


def years(end_dt, start_dt):
    return months(end_dt, start_dt)/12


def business_days(end_dt, start_dt, holidays=[]):
    return len(list(date_range(start_dt, end_dt, business_days=1, holidays=holidays)))
