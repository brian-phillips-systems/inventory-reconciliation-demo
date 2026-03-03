PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS canonical_snapshot;
DROP TABLE IF EXISTS observed_counts;

CREATE TABLE canonical_snapshot (
  sku TEXT NOT NULL,
  location TEXT NOT NULL,
  expected_qty INTEGER NOT NULL,
  snapshot_date TEXT NOT NULL,
  PRIMARY KEY (sku, location, snapshot_date)
);

CREATE TABLE observed_counts (
  sku TEXT NOT NULL,
  location TEXT NOT NULL,
  observed_qty INTEGER NOT NULL,
  count_date TEXT NOT NULL,
  PRIMARY KEY (sku, location, count_date)
);
