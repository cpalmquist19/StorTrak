"""Assemble the full dataset."""

from __future__ import annotations

import random

from faker import Faker

from . import config
from .ids import assign_ids
from .inventory import build_facilities, build_rates, build_units
from .ledger import build_ledger
from .model import Dataset
from .occupancy import allocate
from .people import build_users, staff_unames


def build_dataset(seed: int = config.SEED) -> Dataset:
    rng = random.Random(seed)
    fake = Faker("en_US")
    fake.seed_instance(seed)

    ds = Dataset()
    ds.facilities = build_facilities()
    ds.rates = build_rates(rng)
    ds.units = build_units(rng)
    ds.tenants, ds.rentals = allocate(rng, fake, ds.units, ds.rates)
    ds.entries, ds.payments = build_ledger(ds.rentals, rng, staff_unames())
    ds.users = build_users()
    ds.settings = list(config.SETTINGS)
    assign_ids(ds)
    return ds
