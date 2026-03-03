# Inventory Reconciliation Demo (Deterministic / Integrity-First)

A minimal, reproducible inventory reconciliation pipeline using SQLite.

This project demonstrates how to:

- Enforce canonical snapshot structure
- Import observed counts from external systems
- Detect data integrity violations
- Classify mismatches deterministically
- Produce a reproducible reconciliation report

---

## Problem

Inventory systems frequently drift:

- Counts do not match expected snapshot quantities
- SKUs appear in observed data that should not exist
- Expected SKUs are missing from observed exports
- Duplicate or negative records can corrupt reporting

This demo models those scenarios and classifies each condition explicitly.

---

## Structure

```
data/
  canonical_snapshot.csv   # Expected inventory state
  observed_counts.csv      # External observed counts

sql/
  schema.sql               # Table definitions and constraints
  checks.sql               # Integrity validation logic

run.sh                     # Deterministic execution pipeline
```

---

## Execution

```
./run.sh
```

Produces:

- Sanity row counts
- Duplicate / negative checks
- Classified reconciliation report
- SQLite artifact in `out/recon.sqlite`

---

## Status Classification

Each SKU/location is categorized as:

- `OK`
- `QTY_MISMATCH`
- `MISSING_OBSERVED`
- `UNEXPECTED_OBSERVED`

This mirrors real-world reconciliation workflows used in inventory, finance, and warehouse systems.

---

## Skills Demonstrated

- SQL schema design
- Primary key enforcement
- Deterministic reconciliation logic
- LEFT JOIN reasoning
- Integrity validation
- Reproducible CLI execution
- Separation of canonical vs observed data layers
