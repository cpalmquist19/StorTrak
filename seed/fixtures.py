"""Rentals with fixed terms.

These are placed before the random allocation and claim their units, so
the random rentals never land on them.
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import date


@dataclass(frozen=True)
class FixedRental:
    fac_id: int
    unit_no: str
    movein: date
    moveout: date | None = None
    rent_cents: int | None = None  # None: the unit's current street rate
    pays_on_due_date: bool = False
    last_paid_due: date | None = None
    sale_cents: int | None = None


FIXED_RENTALS: tuple[FixedRental, ...] = (
    FixedRental(1, "A104", date(2006, 4, 3)),
    FixedRental(1, "A118", date(2025, 1, 31)),
    FixedRental(2, "B114", date(2019, 6, 12)),
    FixedRental(2, "B114", date(2023, 3, 3)),
    FixedRental(2, "C121", date(2011, 10, 7)),
    FixedRental(3, "C112", date(2016, 4, 9), rent_cents=6400),
    FixedRental(1, "A140", date(2023, 8, 29), moveout=date(2024, 6, 15), pays_on_due_date=True),
    FixedRental(
        3, "B112", date(2022, 5, 14), last_paid_due=date(2024, 10, 14), sale_cents=145000
    ),
)
