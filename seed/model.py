"""In-memory records, one class per table.

Money is held in integer cents and converted only when SQL is rendered.
Database IDs are assigned after generation (see ids.py), so they are 0 until then.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import date, datetime
from decimal import Decimal


@dataclass(eq=False)
class Facility:
    fac_id: int
    name: str
    addr: str
    phone: str
    tax_rate: Decimal


@dataclass(eq=False)
class RateRow:
    fac_id: int
    sz: str
    utype: int
    mo_rate_cents: int
    rate_old_cents: int | None


@dataclass(eq=False)
class Unit:
    unit_id: int
    fac_id: int
    unit_no: str
    sz: str
    utype: int
    stat: int


@dataclass(eq=False)
class Tenant:
    seq: int
    fname: str
    lname: str
    ph1: str
    ph2: str | None
    email: str | None
    addr1: str
    city: str
    st: str
    zip: str
    ugc: str
    dt_added: datetime | None = None
    tenant_id: int = 0


@dataclass(frozen=True)
class Behavior:
    """How an account pays. Periods due after `last_paid_due` go unpaid."""

    late_rate: float
    pays_on_due_date: bool = False
    last_paid_due: date | None = None
    plan_start: date | None = None
    plan_cents: int = 0


@dataclass(eq=False)
class Lien:
    lnstat: int
    notice1: date | None
    notice2: date | None
    sale_dt: date | None
    sale_cents: int | None
    lien_id: int = 0


@dataclass(eq=False)
class Rental:
    seq: int
    tenant: Tenant
    unit: Unit
    movein: date
    movein_at: datetime
    moveout: date | None
    rent_cents: int
    deposit_cents: int
    behavior: Behavior
    pay_method: str
    next_check_no: int
    card_last4: str
    lien: Lien | None = None
    pdt: date | None = None
    rid: int = 0

    @property
    def active(self) -> bool:
        return self.moveout is None


@dataclass(eq=False)
class Entry:
    """One ledger row. `cents` is positive except for voids (X)."""

    seq: int
    rental: Rental
    typ: str
    cents: int
    dt: datetime
    memo: str
    usr: str
    voids: Entry | None = None
    lid: int = 0


@dataclass(eq=False)
class Payment:
    entry: Entry
    method: str
    chk_no: str | None
    cc_last4: str | None
    pmt_id: int = 0


@dataclass(frozen=True)
class User:
    uid: int
    uname: str
    pw_md5: str
    lvl: int
    fname: str


@dataclass
class Dataset:
    facilities: list[Facility] = field(default_factory=list)
    rates: list[RateRow] = field(default_factory=list)
    units: list[Unit] = field(default_factory=list)
    tenants: list[Tenant] = field(default_factory=list)
    rentals: list[Rental] = field(default_factory=list)
    entries: list[Entry] = field(default_factory=list)
    payments: list[Payment] = field(default_factory=list)
    users: list[User] = field(default_factory=list)
    settings: list[tuple[str, str]] = field(default_factory=list)

    @property
    def liens(self) -> list[Lien]:
        return [r.lien for r in self.rentals if r.lien is not None]


def balance_cents(entries: list[Entry]) -> int:
    """Charges (R, L, D, A, X) minus payments (P)."""
    return sum(-e.cents if e.typ == "P" else e.cents for e in entries)
