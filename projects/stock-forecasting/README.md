# Stock Forecasting Application

End-to-end BI build: prepare time-series features in SQL, then forecast the next 30 days with a
95% confidence band.

**[▶ Open the dashboard](dashboard/index.html)**

## Problem
**Business case:** A price history table is difficult to interpret as a forward-looking view. This case study turns time-series data into a readable forecast with an uncertainty band.

## Data (`/data`)
> Illustrative case-study prices for four real market tickers over a 2023–2024-style period. The committed dashboard data is synthetic; the included fetch script can replace it with real historical data.
> To load **real** data, run `fetch_real_data.py` (see below).

| File | Rows | Key columns |
|---|---|---|
| `stock_prices.csv` | ~2,100 | ticker, date, open, high, low, close, volume |

## SQL (`/sql`)
- `01_schema.sql` — table definition.
- `02_analysis.sql` — feature prep: daily returns with `LAG()`, 20/50-day moving averages,
  20-day rolling volatility (`STDDEV` window), monthly OHLC roll-up, and 52-week high/low band.

## Forecast approach
The SQL builds the features; the forward forecast + confidence band use **Power BI's Analytics
pane (exponential smoothing)**. The web dashboard mirrors this with an EWMA trend and a
±1.96σ·√horizon band.

## Load real data (optional)
```bash
pip install yfinance pandas
python fetch_real_data.py            # writes data/stock_prices.csv for real tickers
```
Edit the `TICKERS` list at the top of the script first.

> Note: my sandbox couldn't reach a market-data API, so the committed CSV is synthetic.
> Running the script locally replaces it with real prices.
