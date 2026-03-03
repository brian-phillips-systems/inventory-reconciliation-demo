.mode csv
.headers on

-- 1) Duplicates check (should return 0 rows)
SELECT 'DUP_CANONICAL' AS issue, sku, location, snapshot_date, COUNT(*) AS n
FROM canonical_snapshot
GROUP BY sku, location, snapshot_date
HAVING COUNT(*) > 1;

SELECT 'DUP_OBSERVED' AS issue, sku, location, count_date, COUNT(*) AS n
FROM observed_counts
GROUP BY sku, location, count_date
HAVING COUNT(*) > 1;

-- 2) Negative quantities check (should return 0 rows)
SELECT 'NEG_CANONICAL' AS issue, sku, location, snapshot_date, expected_qty
FROM canonical_snapshot
WHERE expected_qty < 0;

SELECT 'NEG_OBSERVED' AS issue, sku, location, count_date, observed_qty
FROM observed_counts
WHERE observed_qty < 0;

-- 3) Reconciliation report:
--    - missing observed rows
--    - unexpected observed rows
--    - qty mismatches
WITH
canon AS (
  SELECT sku, location, expected_qty, snapshot_date
  FROM canonical_snapshot
  WHERE snapshot_date = (SELECT MAX(snapshot_date) FROM canonical_snapshot)
),
obs AS (
  SELECT sku, location, observed_qty, count_date
  FROM observed_counts
  WHERE count_date = (SELECT MAX(count_date) FROM observed_counts)
),
full AS (
  SELECT
    COALESCE(c.sku, o.sku) AS sku,
    COALESCE(c.location, o.location) AS location,
    c.expected_qty,
    o.observed_qty,
    c.snapshot_date,
    o.count_date,
    CASE
      WHEN c.sku IS NULL THEN 'UNEXPECTED_OBSERVED'
      WHEN o.sku IS NULL THEN 'MISSING_OBSERVED'
      WHEN c.expected_qty != o.observed_qty THEN 'QTY_MISMATCH'
      ELSE 'OK'
    END AS status
  FROM canon c
  FULL OUTER JOIN obs o
    ON c.sku = o.sku AND c.location = o.location
)
SELECT *
FROM full
ORDER BY status DESC, sku, location;
