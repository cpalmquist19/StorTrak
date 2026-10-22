"""Command line entry point: python -m seed --out db/seed.sql"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

import faker

from . import config
from .build import build_dataset
from .checks import SeedError, validate
from .sqlwriter import render


def header(seed: int) -> list[str]:
    return [
        "StorTrak seed data. GENERATED FILE - do not edit by hand.",
        "Regenerate with `make seed` (see seed/README.md).",
        f"Faker {faker.VERSION}, seed {seed}, as of {config.AS_OF.isoformat()}.",
    ]


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="python -m seed", description="Generate db/seed.sql.")
    parser.add_argument("--out", type=Path, default=Path("db/seed.sql"), help="output file")
    parser.add_argument("--seed", type=int, default=config.SEED, help="random seed")
    args = parser.parse_args(argv)

    dataset = build_dataset(args.seed)
    try:
        validate(dataset)
    except SeedError as exc:
        print(f"seed: validation failed: {exc}", file=sys.stderr)
        return 1

    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(render(dataset, header(args.seed)), encoding="utf-8", newline="\n")
    print(
        f"seed: wrote {args.out} - {len(dataset.units)} units, {len(dataset.tenants)} tenants, "
        f"{len(dataset.rentals)} rentals, {len(dataset.entries)} ledger rows, "
        f"{len(dataset.payments)} payments, {len(dataset.liens)} liens",
        file=sys.stderr,
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
