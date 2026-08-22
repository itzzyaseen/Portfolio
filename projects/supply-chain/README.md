# Supply Chain Performance & Inventory Analytics

End-to-end BI build: raw operational data in SQL → data model → interactive dashboard tracking
**OTIF (On-Time-In-Full)**, inventory turnover and stockout risk.

**[▶ Open the dashboard](dashboard/index.html)**

## Problem
Orders, inventory and shipments lived in separate systems, so no one could see where the chain
was slipping until it cost a sale. This unifies them into one operations view.

## Data (`/data`)
> Synthetic case-study data modelled on realistic distributions. No client data is included.

| File | Rows | Key columns |
|---|---|---|
| `suppliers.csv` | 15 | supplier_id, supplier_name, country, category |
| `products.csv` | 60 | product_id, category, unit_cost, reorder_point, supplier_id |
| `orders.csv` | ~2,100 | order_id, product_id, qty_ordered, qty_delivered, promised_date, delivered_date |
| `inventory.csv` | 720 | product_id, snapshot_month, opening/closing stock, units_sold, below_reorder |

## SQL (`/sql`)
- `01_schema.sql` — table definitions.
- `02_analysis.sql` — the analytical queries: OTIF by month, month-over-month change with `LAG()`,
  inventory turnover, reorder-point breaches, a supplier scorecard ranked with `RANK()`, and
  category spend.

## Dashboard
Built in Power BI; rebuilt here as an interactive web view (`dashboard/index.html`).
Key DAX measures are in [`dashboard/measures.dax`](dashboard/measures.dax).

Visuals: OTIF trend vs target · stockout-risk bars · category-spend donut · KPI cards.

## Reproduce in Power BI
1. Load the four CSVs (Get Data → Text/CSV) or point Power BI at your SQL Server.
2. Relate `orders[product_id]` and `inventory[product_id]` to `products[product_id]`,
   and `products[supplier_id]` to `suppliers[supplier_id]`.
3. Add the measures from `measures.dax`.
4. Build the OTIF line, stockout bars and category donut.
