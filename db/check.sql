-- Sanity check for a loaded database: row counts plus a short seed summary.
-- Run with `make check`. Read-only.

SELECT 'tblFacility' AS tbl, COUNT(*) AS n FROM tblFacility
UNION ALL SELECT 'units',    COUNT(*) FROM units
UNION ALL SELECT 'tenant',   COUNT(*) FROM tenant
UNION ALL SELECT 'rental',   COUNT(*) FROM rental
UNION ALL SELECT 'ledger',   COUNT(*) FROM ledger
UNION ALL SELECT 'payment',  COUNT(*) FROM payment
UNION ALL SELECT 'lien',     COUNT(*) FROM lien
UNION ALL SELECT 'rates',    COUNT(*) FROM rates
UNION ALL SELECT 'settings', COUNT(*) FROM settings
UNION ALL SELECT 'users',    COUNT(*) FROM users;

SELECT
    (SELECT COUNT(DISTINCT r.tid)
       FROM rental r
       JOIN (SELECT rid, SUM(CASE WHEN typ = 'P' THEN -amt ELSE amt END) AS bal
               FROM ledger
              GROUP BY rid) b ON b.rid = r.rid
      WHERE r.moveout_dt IS NULL AND b.bal > 0.005) AS delinquent_tenants,
    (SELECT COUNT(*) FROM lien) AS lien_rows;
