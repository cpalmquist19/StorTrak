"""Facilities, the street-rate grid, and the units themselves."""

from __future__ import annotations

import random

from . import config
from .model import Facility, RateRow, Unit


def build_facilities() -> list[Facility]:
    return [
        Facility(i, spec.name, spec.addr, spec.phone, spec.tax_rate)
        for i, spec in enumerate(config.FACILITIES, start=1)
    ]


def street_rate_dollars(utype: int, sz: str, price_factor: float) -> int:
    if utype == config.PARKING:
        base = config.PARKING_RATE[sz]
    else:
        base = config.BASE_RATE[sz] * config.TYPE_PREMIUM[utype]
    return int(base * price_factor + 0.5)


def build_rates(rng: random.Random) -> list[RateRow]:
    rows: list[RateRow] = []
    for fac_id, spec in enumerate(config.FACILITIES, start=1):
        for utype, sizes in config.TYPE_SIZES.items():
            for sz in sizes:
                rate = street_rate_dollars(utype, sz, spec.price_factor)
                old = None
                if rng.random() < config.RATE_OLD_SHARE:
                    old = (rate - rng.choice(config.RATE_INCREASES)) * 100
                rows.append(RateRow(fac_id, sz, utype, rate * 100, old))
    return rows


def type_counts(unit_count: int) -> dict[int, int]:
    """Units per type for one facility; standard units absorb rounding."""
    counts = {
        utype: round(unit_count * share)
        for utype, share in config.TYPE_SHARE.items()
        if utype != config.STANDARD
    }
    counts[config.STANDARD] = unit_count - sum(counts.values())
    return {utype: counts[utype] for utype in config.TYPE_SIZES}


def size_mix(rng: random.Random, sizes: tuple[str, ...], count: int) -> list[str]:
    """`count` sizes in grid order: every size at least twice, middle sizes favoured."""
    middle = (len(sizes) - 1) / 2
    weights = [len(sizes) - abs(i - middle) for i in range(len(sizes))]
    picks = list(sizes) * 2 + rng.choices(sizes, weights=weights, k=count - 2 * len(sizes))
    return sorted(picks, key=sizes.index)


def build_units(rng: random.Random) -> list[Unit]:
    units: list[Unit] = []
    for fac_id, spec in enumerate(config.FACILITIES, start=1):
        for utype, count in type_counts(spec.unit_count).items():
            for n, sz in enumerate(size_mix(rng, config.TYPE_SIZES[utype], count), start=101):
                unit_no = f"{config.BUILDING[utype]}{n}"
                units.append(Unit(len(units) + 1, fac_id, unit_no, sz, utype, config.VACANT))
    return units
