"""Ledger and payment history for each rental.

Rent is charged on the move-in anniversary. A late fee is charged only when
that period's rent is still unpaid after the grace period. Every P entry has
exactly one matching payment row.
"""

from __future__ import annotations

import random
from datetime import date, datetime, timedelta

from . import config
from .dates import add_months, business_time, due_date, midnight, period_end, periods_due
from .model import Entry, Payment, Rental, balance_cents

ONE_MINUTE = timedelta(minutes=1)


def late_fee_cents(rent_cents: int) -> int:
    pct_fee = (rent_cents * config.LATE_FEE_PCT + 50) // 100
    return max(config.LATE_FEE_CENTS, pct_fee)


class RentalLedger:
    def __init__(self, rental: Rental, rng: random.Random, staff: list[str]):
        self.rental = rental
        self.rng = rng
        self.staff = staff
        self.entries: list[Entry] = []
        self.payments: list[Payment] = []
        self.end = rental.moveout or config.AS_OF

    # -- posting -------------------------------------------------------------

    def post(self, typ: str, cents: int, dt: datetime, memo: str, usr: str, voids: Entry | None = None) -> Entry:
        entry = Entry(len(self.entries), self.rental, typ, cents, dt, memo, usr, voids)
        self.entries.append(entry)
        return entry

    def pay(self, cents: int, dt: datetime, method: str | None = None) -> None:
        r = self.rental
        method = method or r.pay_method
        chk_no = cc_last4 = None
        if method == "CHECK":
            chk_no = str(r.next_check_no)
            r.next_check_no += 1
            memo = f"PMT CK #{chk_no}"
        elif method == "CC":
            cc_last4 = r.card_last4
            memo = f"PMT CC x{cc_last4}"
        elif method == "SALE":
            memo = "LIEN SALE"
        else:
            memo = f"PMT {method}"
        entry = self.post("P", cents, dt, memo, self.rng.choice(self.staff))
        self.payments.append(Payment(entry, method, chk_no, cc_last4))

    # -- billing -------------------------------------------------------------

    def unpaid(self, due: date) -> bool:
        last_paid = self.rental.behavior.last_paid_due
        return last_paid is not None and due > last_paid

    def move_in(self) -> None:
        r = self.rental
        t = r.movein_at
        clerk = self.rng.choice(self.staff)
        if r.deposit_cents:
            self.post("D", r.deposit_cents, t, "DEPOSIT", clerk)
        self.post("R", r.rent_cents, t, f"RENT {r.movein:%m/%d/%Y}", clerk)
        self.pay(r.deposit_cents + r.rent_cents, t + 2 * ONE_MINUTE)

    def payment_offset(self, due: date) -> int:
        """Days after `due` the tenant pays; more than GRACE_DAYS means late."""
        b = self.rental.behavior
        limit = (self.end - due).days
        if b.pays_on_due_date:
            return 0
        if self.rng.random() < b.late_rate and limit > config.GRACE_DAYS:
            return self.rng.randint(config.GRACE_DAYS + 1, min(config.LATEST_PAYMENT_OFFSET, limit))
        return min(self.rng.choice(config.ON_TIME_OFFSETS), limit)

    def charge_late_fee(self, due: date) -> int | None:
        fee_day = due + timedelta(days=config.GRACE_DAYS + 1)
        if fee_day > self.end:
            return None
        fee = late_fee_cents(self.rental.rent_cents)
        self.post("L", fee, midnight(fee_day), "LATE FEE", config.AUTO_USER)
        return fee

    def bill_period(self, due: date, duplicate: bool) -> None:
        r = self.rental
        rent = self.post("R", r.rent_cents, midnight(due), f"RENT {due:%m/%d/%Y}", config.AUTO_USER)
        if duplicate:
            dup = self.post("R", r.rent_cents, midnight(due), rent.memo, config.AUTO_USER)
            void_at = business_time(self.rng, due + timedelta(days=1))
            # memo ("VOID lid n") is written once ledger IDs are assigned
            self.post("X", -dup.cents, void_at, "", self.rng.choice(self.staff), voids=dup)

        plan_start = r.behavior.plan_start
        if self.unpaid(due):
            if plan_start is None or due < plan_start:
                self.charge_late_fee(due)
            return

        offset = self.payment_offset(due)
        paid_at = business_time(self.rng, due + timedelta(days=offset))
        amount = r.rent_cents
        if offset > config.GRACE_DAYS:
            fee = self.charge_late_fee(due)
            if fee is not None:
                if self.rng.random() < config.WAIVE_SHARE:
                    self.post("A", -fee, paid_at - ONE_MINUTE, "waive late fee", self.rng.choice(self.staff))
                else:
                    amount += fee
        self.pay(amount, paid_at)

    def plan_payments(self) -> None:
        b = self.rental.behavior
        if b.plan_start is None:
            return
        month = 0
        while (day := add_months(b.plan_start, month)) <= self.end:
            self.pay(b.plan_cents, business_time(self.rng, day))
            month += 1

    # -- results -------------------------------------------------------------

    def billed_periods(self) -> list[int]:
        r = self.rental
        first = r.movein if r.moveout else max(r.movein, config.HISTORY_START)
        periods = periods_due(r.movein, first, self.end)
        if r.moveout is not None:
            periods = [p for p in periods if due_date(r.movein, p) < r.moveout]
        return periods

    def paid_through(self, periods: list[int]) -> date:
        """End of the last period whose charges are covered by payments."""
        r = self.rental
        paid = sum(e.cents for e in self.entries if e.typ == "P")
        result = period_end(r.movein, periods[0] - 1) if periods[0] > 0 else r.movein
        for p in periods:
            cutoff = midnight(due_date(r.movein, p + 1))
            owed = sum(e.cents for e in self.entries if e.typ != "P" and e.dt < cutoff)
            if paid < owed:
                break
            result = period_end(r.movein, p)
        return result

    def settle_sale(self) -> None:
        lien = self.rental.lien
        assert lien is not None and lien.sale_dt is not None
        sold_at = business_time(self.rng, lien.sale_dt)
        if lien.sale_cents is None:
            owed = balance_cents(self.entries)
            lien.sale_cents = int(owed * self.rng.uniform(0.4, 0.9)) // 100 * 100
        self.pay(lien.sale_cents, sold_at, "SALE")
        remaining = balance_cents(self.entries)
        clerk = self.rng.choice(self.staff)
        if remaining < 0:
            refund_at = business_time(self.rng, lien.sale_dt + timedelta(days=3))
            self.post("A", -remaining, refund_at, "refund excess sale proceeds", clerk)
        elif remaining > 0:
            self.post("A", -remaining, sold_at + ONE_MINUTE, "write off bal after sale", clerk)

    def run(self) -> None:
        r = self.rental
        periods = self.billed_periods()
        voidable = [p for p in periods if p > 0 and due_date(r.movein, p) < self.end]
        void_period = None
        if voidable and self.rng.random() < config.VOID_SHARE:
            void_period = self.rng.choice(voidable)

        for p in periods:
            if p == 0:
                self.move_in()
            else:
                self.bill_period(due_date(r.movein, p), duplicate=p == void_period)
        self.plan_payments()
        r.pdt = self.paid_through(periods)
        if r.lien is not None and r.lien.lnstat == config.SOLD:
            self.settle_sale()


def build_ledger(rentals: list[Rental], rng: random.Random, staff: list[str]) -> tuple[list[Entry], list[Payment]]:
    entries: list[Entry] = []
    payments: list[Payment] = []
    for rental in rentals:
        ledger = RentalLedger(rental, rng, staff)
        ledger.run()
        entries.extend(ledger.entries)
        payments.extend(ledger.payments)
    return entries, payments
