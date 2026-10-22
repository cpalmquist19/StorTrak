"""Tenants and staff logins."""

from __future__ import annotations

import hashlib
import random

from faker import Faker

from . import config
from .model import Tenant, User

PH2_MAX_LEN = 60


def phone(rng: random.Random) -> str:
    return f"{rng.choice(config.AREA_CODES)}-555-{rng.randint(0, 9999):04d}"


def email_for(rng: random.Random, fname: str, lname: str) -> str:
    handle = rng.choice((f"{fname}{lname}", f"{fname}.{lname}", f"{fname[0]}{lname}"))
    domain = rng.choice(("example.com", "example.net", "example.org"))
    return f"{handle}{rng.randint(1, 99)}@{domain}".lower()


def second_contact(rng: random.Random, fname: str, lname: str) -> str | None:
    """ph2 was free text on the old form: often blank, sometimes an email."""
    roll = rng.random()
    if roll < 0.55:
        return None
    if roll < 0.65:
        return ""
    if roll < 0.85:
        return phone(rng)
    return email_for(rng, fname, lname)[:PH2_MAX_LEN]


def gate_code(rng: random.Random) -> str:
    digits = rng.choice((4, 4, 5, 6))
    return str(rng.randint(10 ** (digits - 1), 10**digits - 1))


def make_tenant(fake: Faker, rng: random.Random, seq: int) -> Tenant:
    fname, lname = fake.first_name(), fake.last_name()
    city, st, zip_prefix = rng.choices(config.TOWNS, weights=config.TOWN_WEIGHTS)[0]
    return Tenant(
        seq=seq,
        fname=fname,
        lname=lname,
        ph1=phone(rng),
        ph2=second_contact(rng, fname, lname),
        email=email_for(rng, fname, lname) if rng.random() < 0.85 else None,
        addr1=fake.street_address(),
        city=city,
        st=st,
        zip=f"{zip_prefix}{rng.randint(0, 99):02d}",
        ugc=gate_code(rng),
    )


def build_users() -> list[User]:
    return [
        User(i, spec.uname, hashlib.md5(spec.password.encode()).hexdigest(), spec.lvl, spec.fname)
        for i, spec in enumerate(config.USERS, start=1)
    ]


def staff_unames() -> list[str]:
    return [spec.uname for spec in config.USERS]
