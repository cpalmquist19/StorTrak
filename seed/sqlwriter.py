"""Render a Dataset as MySQL INSERT statements."""

from __future__ import annotations

from collections.abc import Callable, Iterable, Sequence
from datetime import date, datetime
from decimal import Decimal

from . import config
from .model import Dataset, Rental

ROWS_PER_INSERT = 250

SqlValue = str | int | Decimal | date | datetime | None


def money(cents: int | None) -> Decimal | None:
    return None if cents is None else Decimal(cents).scaleb(-2)


def pdt_text(rental: Rental) -> str | None:
    if rental.pdt is None:
        return None
    if rental.movein < config.PDT_US_FORMAT_BEFORE:
        return rental.pdt.strftime("%m/%d/%Y")
    return rental.pdt.isoformat()


def literal(value: SqlValue) -> str:
    if value is None:
        return "NULL"
    if isinstance(value, bool):
        raise TypeError("booleans have no column in this schema")
    if isinstance(value, (int, Decimal)):
        return str(value)
    if isinstance(value, datetime):
        return f"'{value:%Y-%m-%d %H:%M:%S}'"
    if isinstance(value, date):
        return f"'{value.isoformat()}'"
    escaped = value.replace("\\", "\\\\").replace("'", "''")
    return f"'{escaped}'"


def inserts(table: str, columns: Sequence[str], rows: Iterable[Sequence[SqlValue]]) -> str:
    rows = list(rows)
    chunks: list[str] = [f"-- {table}: {len(rows)} rows"]
    for start in range(0, len(rows), ROWS_PER_INSERT):
        batch = rows[start : start + ROWS_PER_INSERT]
        values = ",\n".join("(" + ", ".join(literal(v) for v in row) + ")" for row in batch)
        chunks.append(f"INSERT INTO {table} ({', '.join(columns)}) VALUES\n{values};")
    return "\n".join(chunks)


TableSpec = tuple[str, tuple[str, ...], Callable[[Dataset], Iterable[Sequence[SqlValue]]]]

TABLES: tuple[TableSpec, ...] = (
    ("tblFacility", ("FacID", "FacNm", "Addr", "Ph", "TaxRt"),
     lambda ds: ((f.fac_id, f.name, f.addr, f.phone, f.tax_rate) for f in ds.facilities)),
    ("rates", ("fac", "sz", "utype", "mo_rate", "rate_old"),
     lambda ds: ((r.fac_id, r.sz, r.utype, money(r.mo_rate_cents), money(r.rate_old_cents)) for r in ds.rates)),
    ("units", ("unit_id", "fac", "unit_no", "sz", "utype", "stat"),
     lambda ds: ((u.unit_id, u.fac_id, u.unit_no, u.sz, u.utype, u.stat) for u in ds.units)),
    ("tenant", ("TenantID", "fname", "lname", "ph1", "ph2", "email", "addr1", "city", "st", "zip", "ugc", "dt_added"),
     lambda ds: ((t.tenant_id, t.fname, t.lname, t.ph1, t.ph2, t.email, t.addr1, t.city, t.st, t.zip, t.ugc,
                  t.dt_added) for t in ds.tenants)),
    ("rental", ("rid", "tid", "unit_id", "movein_dt", "moveout_dt", "pdt", "rnt_amt", "dep_amt"),
     lambda ds: ((r.rid, r.tenant.tenant_id, r.unit.unit_id, r.movein, r.moveout, pdt_text(r),
                  money(r.rent_cents), money(r.deposit_cents)) for r in ds.rentals)),
    ("ledger", ("lid", "rid", "typ", "amt", "dt", "memo", "usr"),
     lambda ds: ((e.lid, e.rental.rid, e.typ, money(e.cents), e.dt, e.memo, e.usr) for e in ds.entries)),
    ("payment", ("pmt_id", "rid", "amt", "method", "chk_no", "cc_last4", "dt", "usr"),
     lambda ds: ((p.pmt_id, p.entry.rental.rid, money(p.entry.cents), p.method, p.chk_no, p.cc_last4,
                  p.entry.dt, p.entry.usr) for p in ds.payments)),
    ("lien", ("lien_id", "rid", "lnstat", "notice1_dt", "notice2_dt", "sale_dt", "sale_amt"),
     lambda ds: sorted(((r.lien.lien_id, r.rid, r.lien.lnstat, r.lien.notice1, r.lien.notice2, r.lien.sale_dt,
                         money(r.lien.sale_cents)) for r in ds.rentals if r.lien is not None),
                       key=lambda row: row[0])),
    ("settings", ("k", "v"), lambda ds: ds.settings),
    ("users", ("uid", "uname", "pw", "lvl", "fname"),
     lambda ds: ((u.uid, u.uname, u.pw_md5, u.lvl, u.fname) for u in ds.users)),
)


def render(ds: Dataset, header_lines: Sequence[str]) -> str:
    parts = ["\n".join(f"-- {line}" if line else "--" for line in header_lines)]
    parts.append("SET NAMES utf8mb4;\nSET autocommit = 0;")
    parts.extend(inserts(table, columns, rows(ds)) for table, columns, rows in TABLES)
    parts.append("COMMIT;")
    return "\n\n".join(parts) + "\n"
