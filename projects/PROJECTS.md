# Projects

Four reproducible BI case studies. Each folder contains a **dataset** (`/data`), **runnable SQL**
(`/sql`), **DAX measures + build notes** (`/dashboard`), an **interactive dashboard**
(`dashboard/index.html`), and a **README**.

| # | Project | Domain | Dashboard | Stack |
|---|---|---|---|---|
| CS-01 | [Supply Chain Performance & Inventory](supply-chain/) | Supply Chain | [open](supply-chain/dashboard/index.html) | SQL Server · DAX · Power BI |
| CS-02 | [Vendor Performance Analysis](vendor-performance/) | Procurement | [open](vendor-performance/dashboard/index.html) | SQL · CTEs · RANK · Power BI |
| CS-03 | [Stock Forecasting Application](stock-forecasting/) | Forecasting | [open](stock-forecasting/dashboard/index.html) | SQL · Time-series · Power BI |
| CS-04 | [Airlines Data Analysis](airlines/) | Aviation | [open](airlines/dashboard/index.html) | SQL · Data cleaning · Power BI |

## A note on the data
The project datasets are **synthetic case-study data**, generated with realistic
distributions so the SQL and dashboards behave like the real thing. They are designed to demonstrate the analytical approach; replace
them with real extracts and update the headline numbers on the portfolio cards to match.

```bash
pip install pandas numpy
python generate_data.py     # regenerates all /data CSVs and dashboard data.js files
```

## Dashboards
The interactive dashboards are plain HTML + [Chart.js](https://www.chartjs.org) (vendored in
`vendor/`), reading a small pre-aggregated `data.js` per project. They're the web mirror of the
Power BI reports and are served directly by the site.
