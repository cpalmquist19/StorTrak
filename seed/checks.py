"""Consistency checks run before any SQL is written."""

from __future__ import annotations

from collections import defaultdict

from . import config
from .model import Dataset, Entry, Rental, balance_cents


class SeedError(Exception):
    pass


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SeedError(message)


def entries_by_rental(ds: Dataset) -> dict[int, list[Entry]]:
    grouped: dict[int, list[Entry]] = defaultdict(list)
    for entry in ds.entries:
        grouped[entry.rental.rid].append(entry)
    return grouped


def expected_balance_sign(rental: Rental) -> int:
    """+1 if the account should owe money at AS_OF, 0 if it should be settled."""
    return 1 if rental.active and rental.behavior.last_paid_due is not None else 0


def check_balances(ds: Dataset) -> None:
    grouped = entries_by_rental(ds)
    for rental in ds.rentals:
        balance = balance_cents(grouped[rental.rid])
        if expected_balance_sign(rental):
            require(balance > 0, f"rental {rental.rid} should owe money, balance {balance}")
        else:
            require(balance == 0, f"rental {rental.rid} should be settled, balance {balance}")

    owing = {r.tenant.tenant_id for r in ds.rentals if balance_cents(grouped[r.rid]) > 0 and r.active}
    require(len(owing) == len(config.ARREARS_PERIODS), f"{len(owing)} tenants owe money")


def check_payments(ds: Dataset) -> None:
    p_entries = [e for e in ds.entries if e.typ == "P"]
    require(len(p_entries) == len(ds.payments), "payment rows do not match P entries")
    for payment in ds.payments:
        require(payment.entry.typ == "P", f"payment {payment.pmt_id} is not tied to a P entry")


def check_dates(ds: Dataset) -> None:
    for entry in ds.entries:
        require(entry.dt.date() <= config.AS_OF, f"ledger {entry.lid} is after AS_OF")
        require(entry.dt.date() >= entry.rental.movein, f"ledger {entry.lid} is before move-in")
    for rental in ds.rentals:
        require(rental.pdt is not None, f"rental {rental.rid} has no paid-through date")


def check_units(ds: Dataset) -> None:
    active_units = {r.unit.unit_id for r in ds.rentals if r.active}
    for unit in ds.units:
        if unit.unit_id in active_units:
            require(unit.stat not in config.IDLE_STATUSES and unit.stat != config.VACANT,
                    f"unit {unit.unit_id} is rented but stat {unit.stat}")
        else:
            require(unit.stat == config.VACANT or unit.stat in config.IDLE_STATUSES,
                    f"unit {unit.unit_id} is empty but stat {unit.stat}")


def validate(ds: Dataset) -> None:
    check_payments(ds)
    check_balances(ds)
    check_dates(ds)
    check_units(ds)
