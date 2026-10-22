"""Who rents which unit, when, and how they pay."""

from __future__ import annotations

import random
from dataclasses import replace
from datetime import date, timedelta

from faker import Faker

from . import config
from .dates import business_time, due_date, periods_due
from .fixtures import FIXED_RENTALS, FixedRental
from .model import Behavior, Lien, RateRow, Rental, Tenant, Unit
from .people import make_tenant

LONG_TENURE_END = date(2013, 12, 31)


class Allocator:
    def __init__(self, rng: random.Random, fake: Faker, units: list[Unit], rates: list[RateRow]):
        self.rng = rng
        self.fake = fake
        self.units = units
        self.unit_by_no = {(u.fac_id, u.unit_no): u for u in units}
        self.rate_of = {(r.fac_id, r.sz, r.utype): r.mo_rate_cents for r in rates}
        self.tenants: list[Tenant] = []
        self.rentals: list[Rental] = []
        self.reserved_units: set[int] = set()
        self.free_before: dict[int, date] = {}

    # -- construction helpers ------------------------------------------------

    def new_tenant(self) -> Tenant:
        tenant = make_tenant(self.fake, self.rng, len(self.tenants))
        self.tenants.append(tenant)
        return tenant

    def random_behavior(self) -> Behavior:
        weights = [w for w, _ in config.LATE_PROFILES]
        late_rate = self.rng.choices(config.LATE_PROFILES, weights=weights)[0][1]
        return Behavior(late_rate=late_rate)

    def new_rental(
        self,
        tenant: Tenant,
        unit: Unit,
        movein: date,
        moveout: date | None = None,
        rent_cents: int | None = None,
        behavior: Behavior | None = None,
    ) -> Rental:
        rng = self.rng
        methods = [m for m, _ in config.PAYMENT_METHODS]
        weights = [w for _, w in config.PAYMENT_METHODS]
        rental = Rental(
            seq=len(self.rentals),
            tenant=tenant,
            unit=unit,
            movein=movein,
            movein_at=business_time(rng, movein),
            moveout=moveout,
            rent_cents=rent_cents or self.rate_of[(unit.fac_id, unit.sz, unit.utype)],
            deposit_cents=rng.choice(config.DEPOSIT_DOLLARS) * 100,
            behavior=behavior or self.random_behavior(),
            pay_method=rng.choices(methods, weights=weights)[0],
            next_check_no=rng.randint(1001, 4999),
            card_last4=f"{rng.randint(0, 9999):04d}",
        )
        if moveout is None:
            unit.stat = config.RENTED
        self.rentals.append(rental)
        return rental

    def random_movein(self) -> date:
        rng = self.rng
        if rng.random() < config.LONG_TENURE_SHARE:
            span = (LONG_TENURE_END - config.EARLIEST_MOVEIN).days
            return config.EARLIEST_MOVEIN + timedelta(days=rng.randint(0, span))
        movein = config.AS_OF - timedelta(days=int(rng.expovariate(1 / config.MEAN_TENURE_DAYS)))
        return max(movein, LONG_TENURE_END + timedelta(days=1))

    # -- liens ---------------------------------------------------------------

    @staticmethod
    def first_due_after(movein: date, d: date) -> date:
        period = 0
        while due_date(movein, period) <= d:
            period += 1
        return due_date(movein, period)

    def sold_lien(self, movein: date, last_paid_due: date, sale_cents: int | None) -> Lien:
        first_unpaid = self.first_due_after(movein, last_paid_due)
        return Lien(
            lnstat=config.SOLD,
            notice1=first_unpaid + timedelta(days=config.NOTICE1_DAYS),
            notice2=first_unpaid + timedelta(days=config.NOTICE2_DAYS),
            sale_dt=first_unpaid + timedelta(days=config.SALE_DAYS),
            sale_cents=sale_cents,
        )

    # -- placement -----------------------------------------------------------

    def place_fixed(self, fx: FixedRental) -> Rental:
        unit = self.unit_by_no[(fx.fac_id, fx.unit_no)]
        self.reserved_units.add(unit.unit_id)
        behavior = self.random_behavior()
        if fx.pays_on_due_date:
            behavior = Behavior(late_rate=0.0, pays_on_due_date=True)
        lien = None
        moveout = fx.moveout
        if fx.last_paid_due is not None:
            behavior = replace(behavior, last_paid_due=fx.last_paid_due)
            lien = self.sold_lien(fx.movein, fx.last_paid_due, fx.sale_cents)
            moveout = lien.sale_dt
        rental = self.new_rental(
            self.new_tenant(), unit, fx.movein, moveout, fx.rent_cents, behavior
        )
        rental.lien = lien
        if moveout is not None:
            self.free_before[unit.unit_id] = fx.movein - timedelta(days=self.rng.randint(7, 60))
        return rental

    def units_per_random_tenant(self, tenant_count: int, rental_count: int) -> list[int]:
        multi = config.MULTI_UNIT_TENANTS
        counts = [1] * (tenant_count - multi) + [2] * multi
        extra = rental_count - sum(counts)
        while extra > 0:
            i = self.rng.randrange(tenant_count - multi, tenant_count)
            if counts[i] < config.MAX_UNITS_PER_TENANT:
                counts[i] += 1
                extra -= 1
        return counts

    def place_current(self, fixed_active: list[Rental]) -> list[Rental]:
        """Fill the building to OCCUPANCY with random tenants; returns single-unit rentals."""
        fixed_units = {r.unit.unit_id for r in fixed_active}
        target_units = int(len(self.units) * config.OCCUPANCY)
        pool = [u for u in self.units if u.unit_id not in self.reserved_units]
        self.rng.shuffle(pool)
        pool = pool[: target_units - len(fixed_units)]

        counts = self.units_per_random_tenant(config.CURRENT_TENANTS - len(fixed_active), len(pool))
        singles: list[Rental] = []
        units = iter(pool)
        for count in counts:
            tenant = self.new_tenant()
            placed = [self.new_rental(tenant, next(units), self.random_movein()) for _ in range(count)]
            if count == 1:
                singles.extend(placed)
        return singles

    def apply_arrears(self, rental: Rental, missed: int) -> None:
        rng = self.rng
        dues = [due_date(rental.movein, p) for p in periods_due(rental.movein, rental.movein, config.AS_OF)]
        first_unpaid = dues[-missed]
        behavior = replace(rental.behavior, last_paid_due=dues[-missed - 1])
        notice1 = first_unpaid + timedelta(days=config.NOTICE1_DAYS)
        notice2 = first_unpaid + timedelta(days=config.NOTICE2_DAYS)

        if missed == 2:
            rental.unit.stat = config.OVERLOCKED
        elif missed == 3:
            lnstat = rng.choice((config.NOTICE1_SENT, config.NOTICE2_SENT))
            rental.unit.stat = config.IN_LIEN
            rental.lien = Lien(lnstat, notice1, notice2 if lnstat == config.NOTICE2_SENT else None, None, None)
        elif missed == 4:
            sale_dt = config.AS_OF + timedelta(days=rng.randint(7, 21))
            rental.unit.stat = config.AUCTION_PENDING
            rental.lien = Lien(config.AUCTION_SCHEDULED, notice1, notice2, sale_dt, None)
        elif missed > 4:
            rental.unit.stat = config.IN_LIEN
            rental.lien = Lien(config.PAYMENT_PLAN, notice1, notice2, None, None)
            behavior = replace(
                behavior,
                plan_start=first_unpaid + timedelta(days=config.PLAN_START_DAYS),
                plan_cents=rental.rent_cents + config.PLAN_EXTRA_CENTS,
            )
        rental.behavior = behavior

    def place_arrears(self, candidates: list[Rental]) -> None:
        cutoff = config.AS_OF - timedelta(days=config.ARREARS_MIN_TENURE_DAYS)
        eligible = [r for r in candidates if r.movein <= cutoff]
        chosen = self.rng.sample(eligible, len(config.ARREARS_PERIODS))
        for rental, missed in zip(chosen, config.ARREARS_PERIODS):
            self.apply_arrears(rental, missed)

    def init_free_before(self) -> None:
        """Latest date a past rental on each unit may end."""
        earliest_active: dict[int, date] = {}
        for r in self.rentals:
            if r.active:
                uid = r.unit.unit_id
                earliest_active[uid] = min(r.movein, earliest_active.get(uid, r.movein))
        for unit in self.units:
            if unit.unit_id in self.free_before:
                continue
            if unit.unit_id in earliest_active:
                gap = self.rng.randint(10, 90)
                self.free_before[unit.unit_id] = earliest_active[unit.unit_id] - timedelta(days=gap)
            else:
                self.free_before[unit.unit_id] = config.AS_OF - timedelta(days=self.rng.randint(5, 240))

    def place_past(self, tenant: Tenant) -> Rental:
        rng = self.rng
        while True:
            unit = rng.choice(self.units)
            if unit.unit_id in self.reserved_units:
                continue
            moveout = self.free_before[unit.unit_id] - timedelta(days=rng.randint(0, 45))
            movein = moveout - timedelta(days=rng.randint(60, 1500))
            if movein >= config.EARLIEST_MOVEIN:
                break
        self.free_before[unit.unit_id] = movein - timedelta(days=rng.randint(7, 60))
        return self.new_rental(tenant, unit, movein, moveout)

    def sell_out(self, rental: Rental) -> None:
        """Turn a past rental into one that ended in a lien sale."""
        assert rental.moveout is not None
        latest_first_unpaid = rental.moveout - timedelta(days=config.SALE_DAYS)
        dues = [due_date(rental.movein, p) for p in periods_due(rental.movein, rental.movein, latest_first_unpaid)]
        last_paid_due = dues[-2]
        rental.behavior = replace(rental.behavior, last_paid_due=last_paid_due)
        rental.lien = self.sold_lien(rental.movein, last_paid_due, None)
        rental.moveout = rental.lien.sale_dt

    def place_former(self, current_tenants: list[Tenant], fixed_past: int) -> None:
        random_past: list[Rental] = []
        for _ in range(config.FORMER_TENANTS - fixed_past):
            random_past.append(self.place_past(self.new_tenant()))
        for _ in range(config.EXTRA_PAST_RENTALS):
            random_past.append(self.place_past(self.rng.choice(current_tenants)))
        long_stays = [r for r in random_past if r.moveout and (r.moveout - r.movein).days >= 330]
        for rental in self.rng.sample(long_stays, config.SOLD_PAST_RENTALS):
            self.sell_out(rental)

    def set_idle_statuses(self) -> None:
        occupied = {r.unit.unit_id for r in self.rentals if r.active}
        idle = [u for u in self.units if u.unit_id not in occupied]
        picked = self.rng.sample(idle, sum(config.IDLE_STATUSES.values()))
        statuses = [stat for stat, n in config.IDLE_STATUSES.items() for _ in range(n)]
        for unit, stat in zip(picked, statuses):
            unit.stat = stat

    def set_dt_added(self) -> None:
        first_movein: dict[int, Rental] = {}
        for r in self.rentals:
            seen = first_movein.get(r.tenant.seq)
            if seen is None or r.movein_at < seen.movein_at:
                first_movein[r.tenant.seq] = r
        for tenant in self.tenants:
            tenant.dt_added = first_movein[tenant.seq].movein_at


def allocate(
    rng: random.Random, fake: Faker, units: list[Unit], rates: list[RateRow]
) -> tuple[list[Tenant], list[Rental]]:
    alloc = Allocator(rng, fake, units, rates)
    fixed = [alloc.place_fixed(fx) for fx in FIXED_RENTALS]
    fixed_active = [r for r in fixed if r.active]

    singles = alloc.place_current(fixed_active)
    current_tenants = [r.tenant for r in alloc.rentals if r.active and r not in fixed_active]
    current_tenants = list(dict.fromkeys(current_tenants))
    alloc.place_arrears(singles)

    alloc.init_free_before()
    alloc.place_former(current_tenants, fixed_past=len(fixed) - len(fixed_active))
    alloc.set_idle_statuses()
    alloc.set_dt_added()
    return alloc.tenants, alloc.rentals
