# Vendor Performance Analysis

End-to-end BI build: score every supplier on a weighted model, then rank them so procurement can compare suppliers consistently.

**[▶ Open the dashboard](dashboard/index.html)**

## Problem
**Business case:** Procurement needs a consistent way to compare suppliers. This case study scores each on
**50% delivery reliability + 35% quality + 15% cost efficiency** and produces a ranked scorecard.

## Data (`/data`)
> Synthetic case-study data. No client data is included.

| File | Rows | Key columns |
|---|---|---|
| `vendors.csv` | 120 | vendor_id, vendor_name, category, region, onboarded_date |
| `purchase_orders.csv` | ~3,500 | po_id, vendor_id, po_date, promised_date, order_value, qty_ordered |
| `deliveries.csv` | ~3,500 | po_id, delivered_date, accepted_qty, rejected_qty, defect_flag |

## SQL (`/sql`)
- `01_schema.sql` — table definitions.
- `02_analysis.sql` — the scorecard: per-vendor metrics → 0–100 component scores
  (cost score via `PERCENT_RANK()`) → weighted overall score, `RANK()`, and a `Preferred /
  Approved / Review-Replace` tier. Also regional rollups and a bottom-vendor action list.

## Dashboard
Visuals: top-vendor ranking (weighted score) · delivery-vs-quality components · regional radar ·
KPI cards. Key measures in [`dashboard/measures.dax`](dashboard/measures.dax).

## Reproduce in Power BI
1. Load the three CSVs (or connect to SQL).
2. Relate `purchase_orders[vendor_id]` → `vendors[vendor_id]` and
   `deliveries[po_id]` → `purchase_orders[po_id]`.
3. Add the measures, then build the ranked bar + components + radar.
