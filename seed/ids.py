"""Assign database IDs in chronological order, the way an app would have."""

from __future__ import annotations

from .model import Dataset


def assign_ids(ds: Dataset) -> None:
    ds.tenants.sort(key=lambda t: (t.dt_added, t.seq))
    for i, tenant in enumerate(ds.tenants, start=1):
        tenant.tenant_id = i

    ds.rentals.sort(key=lambda r: (r.movein_at, r.seq))
    for i, rental in enumerate(ds.rentals, start=1):
        rental.rid = i

    ds.entries.sort(key=lambda e: (e.dt, e.rental.rid, e.seq))
    for i, entry in enumerate(ds.entries, start=1):
        entry.lid = i
    for entry in ds.entries:
        if entry.voids is not None:
            entry.memo = f"VOID lid {entry.voids.lid}"

    ds.payments.sort(key=lambda p: p.entry.lid)
    for i, payment in enumerate(ds.payments, start=1):
        payment.pmt_id = i

    liened = [r for r in ds.rentals if r.lien is not None]
    liened.sort(key=lambda r: (r.lien.notice1, r.rid))  # type: ignore[union-attr]
    for i, rental in enumerate(liened, start=1):
        rental.lien.lien_id = i  # type: ignore[union-attr]
