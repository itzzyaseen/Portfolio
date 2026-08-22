"""
Fetch REAL historical prices and write them to data/stock_prices.csv in the same
schema the SQL and dashboard expect.

    pip install yfinance pandas
    python fetch_real_data.py

Edit TICKERS and the date range as you like. Note: the dashboard's data.js is
pre-aggregated; after fetching real data, re-run the aggregation in your own
notebook or adapt generate_data.py to point at this CSV.
"""
import os
import yfinance as yf
import pandas as pd

TICKERS = ["AAPL", "MSFT", "NVDA", "AMZN"]   # real market tickers
START, END = "2023-01-01", "2024-12-31"

frames = []
for tk in TICKERS:
    df = yf.download(tk, start=START, end=END, progress=False)
    df = df.reset_index()[["Date", "Open", "High", "Low", "Close", "Volume"]]
    df.columns = ["date", "open", "high", "low", "close", "volume"]
    df.insert(0, "ticker", tk)
    df["date"] = pd.to_datetime(df["date"]).dt.date
    for c in ["open", "high", "low", "close"]:
        df[c] = df[c].round(2)
    frames.append(df)

out = pd.concat(frames, ignore_index=True)
path = os.path.join(os.path.dirname(__file__), "data", "stock_prices.csv")
out.to_csv(path, index=False)
print(f"Wrote {len(out):,} rows for {', '.join(TICKERS)} -> {path}")
