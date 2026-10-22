"""Fixed parameters for the StorTrak seed data.

Everything that shapes the generated data lives here, so a change to the
dataset is a change to this file (or to fixtures.py), never to the logic.
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import date
from decimal import Decimal

# Reproducibility: one seed drives both Faker and the generator's own RNG,
# and "today" is pinned so output never depends on the wall clock.
SEED = 20060214
AS_OF = date(2026, 9, 30)
HISTORY_START = date(2024, 9, 30)  # active rentals keep 24 months of ledger
EARLIEST_MOVEIN = date(2006, 3, 1)
PDT_US_FORMAT_BEFORE = date(2014, 1, 1)  # pdt is MM/DD/YYYY before this, ISO after

# Billing rules (mirrored into the settings table).
GRACE_DAYS = 5
LATE_FEE_CENTS = 1500
LATE_FEE_PCT = 10
TAX_RATE = "0.0725"

SETTINGS: tuple[tuple[str, str], ...] = (
    ("GRACE", str(GRACE_DAYS)),
    ("LATEFEE", str(LATE_FEE_CENTS // 100)),
    ("LATEPCT", str(LATE_FEE_PCT)),
    ("TAXRT", TAX_RATE),
)

# units.utype / rates.utype
STANDARD, DRIVE_UP, CLIMATE, PARKING = 1, 2, 3, 4

# units.stat
(
    VACANT,
    RENTED,
    RESERVED,
    DAMAGED,
    COMPANY_USE,
    OVERLOCKED,
    IN_LIEN,
    AUCTION_PENDING,
    LEGACY,
) = range(1, 10)

# lien.lnstat
NOTICE1_SENT, NOTICE2_SENT, AUCTION_SCHEDULED, SOLD = 1, 2, 3, 4
PAYMENT_PLAN = 7


@dataclass(frozen=True)
class FacilitySpec:
    name: str
    addr: str
    phone: str
    tax_rate: Decimal
    unit_count: int
    price_factor: float


FACILITIES: tuple[FacilitySpec, ...] = (
    FacilitySpec(
        "Piedmont Stor-All Main",
        "410 W Market St, Haw Bend NC 27299",
        "336-555-0142",
        Decimal("0.0725"),
        180,
        1.00,
    ),
    FacilitySpec(
        "Piedmont Stor-All 29 North",
        "8815 Hwy 29 N, Carver Mills NC 27355",
        "336-555-0178",
        Decimal("0.0700"),
        160,
        0.92,
    ),
    FacilitySpec(
        "Old Mill Storage",
        "2 Mill Race Rd, Pine Fork NC 27380",
        "336-555-0119",
        Decimal("0.0675"),
        110,
        0.85,
    ),
)

TYPE_SIZES: dict[int, tuple[str, ...]] = {
    STANDARD: ("5x5", "5x10", "10x10", "10x15", "10x20"),
    DRIVE_UP: ("10x10", "10x15", "10x20", "10x30"),
    CLIMATE: ("5x5", "5x10", "10x10", "10x15", "10x20"),
    PARKING: ("10x20", "12x30", "12x40"),
}
TYPE_SHARE: dict[int, float] = {STANDARD: 0.45, DRIVE_UP: 0.25, CLIMATE: 0.20, PARKING: 0.10}
BUILDING: dict[int, str] = {STANDARD: "A", DRIVE_UP: "B", CLIMATE: "C", PARKING: "P"}

# Monthly street rate in whole dollars before type and facility multipliers.
BASE_RATE: dict[str, int] = {
    "5x5": 39,
    "5x10": 55,
    "10x10": 89,
    "10x15": 115,
    "10x20": 145,
    "10x30": 195,
}
PARKING_RATE: dict[str, int] = {"10x20": 45, "12x30": 65, "12x40": 79}
TYPE_PREMIUM: dict[int, float] = {STANDARD: 1.00, DRIVE_UP: 1.15, CLIMATE: 1.35}
RATE_OLD_SHARE = 0.20
RATE_INCREASES = (5, 8, 10, 12, 15)

# Occupancy and tenant mix.
OCCUPANCY = 0.75
CURRENT_TENANTS = 260
MULTI_UNIT_TENANTS = 40
MAX_UNITS_PER_TENANT = 5
FORMER_TENANTS = 40
EXTRA_PAST_RENTALS = 60
SOLD_PAST_RENTALS = 2
LONG_TENURE_SHARE = 0.10  # share of random move-ins drawn from before 2014
MEAN_TENURE_DAYS = 900
IDLE_STATUSES: dict[int, int] = {RESERVED: 4, DAMAGED: 3, COMPANY_USE: 2, LEGACY: 3}

# Accounts in arrears at AS_OF, by number of unpaid rent periods.
ARREARS_PERIODS: tuple[int, ...] = (1, 1, 1, 1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 6)
ARREARS_MIN_TENURE_DAYS = 250

# Lien timeline, in days after the first unpaid due date.
NOTICE1_DAYS = 30
NOTICE2_DAYS = 51
SALE_DAYS = 79
PLAN_START_DAYS = 90
PLAN_EXTRA_CENTS = 4000

# Payment behaviour: (weight, chance a given period is paid after grace).
LATE_PROFILES: tuple[tuple[int, float], ...] = ((70, 0.03), (25, 0.20), (5, 0.45))
ON_TIME_OFFSETS = (0, 0, 0, 1, 1, 2, 3, 4, 5)
LATEST_PAYMENT_OFFSET = 20
WAIVE_SHARE = 0.05
VOID_SHARE = 0.03
PAYMENT_METHODS: tuple[tuple[str, int], ...] = (("CC", 50), ("CHECK", 25), ("CASH", 20), ("MO", 5))
DEPOSIT_DOLLARS = (0, 25, 25, 50, 50, 100)

AUTO_USER = "AUTO"


@dataclass(frozen=True)
class UserSpec:
    uname: str
    password: str
    lvl: int
    fname: str


USERS: tuple[UserSpec, ...] = (
    UserSpec("admin", "stortrak1", 9, "Gary"),
    UserSpec("bwatts", "storage1", 1, "Brenda"),
    UserSpec("dcole", "welcome1", 1, "Dee"),
    UserSpec("mfrye", "mill2009", 1, "Marcus"),
)

# Tenant addresses: fictional towns, weighted toward home state.
TOWNS: tuple[tuple[str, str, str], ...] = (
    ("Haw Bend", "NC", "272"),
    ("Carver Mills", "NC", "273"),
    ("Pine Fork", "NC", "273"),
    ("Reedy Branch", "NC", "272"),
    ("Sumner Gap", "NC", "286"),
    ("Lake Tomlin", "NC", "274"),
    ("Dalton Ford", "VA", "245"),
    ("Cedar Shoals", "SC", "297"),
)
TOWN_WEIGHTS = (30, 22, 14, 12, 8, 8, 3, 3)
AREA_CODES = ("336", "336", "336", "704", "919")
