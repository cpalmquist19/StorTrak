"""Date helpers for anniversary billing."""

from __future__ import annotations

import random
from calendar import monthrange
from datetime import date, datetime, time, timedelta


def add_months(d: date, months: int) -> date:
    """Same day-of-month `months` later, clamped to the end of short months."""
    years, month0 = divmod(d.month - 1 + months, 12)
    year, month = d.year + years, month0 + 1
    return date(year, month, min(d.day, monthrange(year, month)[1]))


def due_date(movein: date, period: int) -> date:
    """Rent for period n is due on the move-in anniversary n months later."""
    return add_months(movein, period)


def period_end(movein: date, period: int) -> date:
    return due_date(movein, period + 1) - timedelta(days=1)


def periods_due(movein: date, first: date, last: date) -> list[int]:
    """Indexes of the periods whose due date falls within [first, last]."""
    result: list[int] = []
    period = 0
    while (due := due_date(movein, period)) <= last:
        if due >= first:
            result.append(period)
        period += 1
    return result


def midnight(d: date) -> datetime:
    return datetime.combine(d, time(0, 0))


def business_time(rng: random.Random, d: date) -> datetime:
    """A time during office hours (9:00-16:59) on day `d`."""
    return datetime.combine(d, time(rng.randint(9, 16), rng.randint(0, 59)))
