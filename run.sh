#!/usr/bin/env bash
set -euo pipefail

DB="out/recon.sqlite"

mkdir -p out
rm -f "$DB"

# Create schema
sqlite3 "$DB" < sql/schema.sql

# Import CSV data
sqlite3 "$DB" <<'SQL'
.mode csv
.headers on
.import data/canonical_snapshot.csv canonical_snapshot
.import data/observed_counts.csv observed_counts
SQL

echo
echo "== Sanity counts =="
sqlite3 "$DB" "SELECT 'canonical' AS table_name, COUNT(*) AS rows FROM canonical_snapshot;"
sqlite3 "$DB" "SELECT 'observed'  AS table_name, COUNT(*) AS rows FROM observed_counts;"

echo
echo "== Integrity checks (duplicates / negatives) =="

sqlite3 "$DB" <<'SQL'
.headers on
.mode column

-- Duplicate checks
SELECT 'DUP_CANONICAL' AS issue, sku, location, snapshot_date, COUNT(*) AS n
FROM canonical_snapshot
GROUP BY sku, location, snapshot_date
HAVING COUNT(*) > 1;

SELECT 'DUP_OBSERVED' AS issue, sku, location, count_date, COUNT(*) AS n
FROM observed_counts
GROUP BY sku, location, count_date
HAVING COUNT(*) > 1;

-- Negative checks
SELECT 'NEG_CANONICAL' AS issue, sku, location, snapshot_date, expected_qty
FROM canonical_snapshot
WHERE expected_qty < 0;

SELECT 'NEG_OBSERVED' AS issue, sku, location, count_date, observed_qty
FROM observed_counts
WHERE observed_qty < 0;
SQL

echo
echo "== Reconciliation report =="

sqlite3 "$DB" <<'SQL'
.headers on
.mode column

WITH
canon AS (
  SELECT sku, location, expected_qty
  FROM canonical_snapshot
),
obs AS (
  SELECT sku, location, observed_qty
  FROM observed_counts
),
left_side AS (
  SELECT
    c.sku,
    c.location,
    c.expected_qty,
    o.observed_qty,
    CASE
      WHEN o.sku IS NULL THEN 'MISSING_OBSERVED'
      WHEN c.expected_qty != o.observed_qty THEN 'QTY_MISMATCH'
      ELSE 'OK'
    END AS status
  FROM canon c
  LEFT JOIN obs o
    ON c.sku = o.sku AND c.location = o.location
),
right_only AS (
  SELECT
    o.sku,
    o.location,
    NULL AS expected_qty,
    o.observed_qty,
    'UNEXPECTED_OBSERVED' AS status
  FROM obs o
  LEFT JOIN canon c
    ON c.sku = o.sku AND c.location = o.location
  WHERE c.sku IS NULL
),
full AS (
  SELECT * FROM left_side
  UNION ALL
  SELECT * FROM right_only
)
SELECT *
FROM full
ORDER BY status DESC, sku, location;
SQL

echo
echo "Done. Database saved to $DB"
