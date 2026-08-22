/* ============================================================================
   Stock Forecasting — time-series feature prep (SQL side)
   The SQL prepares the modelling features; Power BI's Analytics pane
   (exponential smoothing) draws the forward forecast + confidence band.
   ============================================================================ */

/* ---------------------------------------------------------------------------
   1. Daily returns using LAG()  — the base signal for volatility & trend
   --------------------------------------------------------------------------- */
SELECT
    ticker,
    date,
    close,
    LAG(close) OVER (PARTITION BY ticker ORDER BY date)          AS prev_close,
    ROUND(100.0 * (close - LAG(close) OVER (PARTITION BY ticker ORDER BY date))
          / NULLIF(LAG(close) OVER (PARTITION BY ticker ORDER BY date), 0), 3) AS daily_return_pct
FROM stock_prices
ORDER BY ticker, date;

/* ---------------------------------------------------------------------------
   2. Moving averages (20 / 50-day) with a windowed AVG  — trend + crossovers
   --------------------------------------------------------------------------- */
SELECT
    ticker,
    date,
    close,
    ROUND(AVG(close) OVER (PARTITION BY ticker ORDER BY date
              ROWS BETWEEN 19 PRECEDING AND CURRENT ROW), 2)     AS ma_20,
    ROUND(AVG(close) OVER (PARTITION BY ticker ORDER BY date
              ROWS BETWEEN 49 PRECEDING AND CURRENT ROW), 2)     AS ma_50
FROM stock_prices
ORDER BY ticker, date;

/* ---------------------------------------------------------------------------
   3. 20-day rolling volatility (stdev of returns) — feeds the confidence band
   --------------------------------------------------------------------------- */
WITH returns AS (
    SELECT ticker, date,
           (close - LAG(close) OVER (PARTITION BY ticker ORDER BY date))
           / NULLIF(LAG(close) OVER (PARTITION BY ticker ORDER BY date),0) AS ret
    FROM stock_prices
)
SELECT
    ticker,
    date,
    ROUND(100.0 * STDDEV(ret) OVER (PARTITION BY ticker ORDER BY date
              ROWS BETWEEN 19 PRECEDING AND CURRENT ROW), 3)     AS vol_20d_pct
FROM returns
ORDER BY ticker, date;

/* ---------------------------------------------------------------------------
   4. Monthly OHLC roll-up  — a lighter grain for the summary view
   --------------------------------------------------------------------------- */
WITH ranked AS (
    SELECT ticker, date, open, high, low, close,
           TO_CHAR(date, 'YYYY-MM')                              AS ym,  -- SQL Server: FORMAT(date,'yyyy-MM')
           ROW_NUMBER() OVER (PARTITION BY ticker, TO_CHAR(date,'YYYY-MM') ORDER BY date)      AS rn_first,
           ROW_NUMBER() OVER (PARTITION BY ticker, TO_CHAR(date,'YYYY-MM') ORDER BY date DESC) AS rn_last
    FROM stock_prices
)
SELECT
    ticker, ym,
    MAX(CASE WHEN rn_first = 1 THEN open END)                    AS month_open,
    MAX(high)                                                    AS month_high,
    MIN(low)                                                     AS month_low,
    MAX(CASE WHEN rn_last  = 1 THEN close END)                   AS month_close
FROM ranked
GROUP BY ticker, ym
ORDER BY ticker, ym;

/* ---------------------------------------------------------------------------
   5. 52-week high / low band per ticker  — context for the current price
   --------------------------------------------------------------------------- */
SELECT
    ticker,
    MAX(close)                                                   AS high_52w,
    MIN(close)                                                   AS low_52w,
    MAX(CASE WHEN date = (SELECT MAX(date) FROM stock_prices s2
                          WHERE s2.ticker = s.ticker) THEN close END) AS latest_close
FROM stock_prices s
WHERE date >= (SELECT MAX(date) FROM stock_prices) - INTERVAL '365 day'
GROUP BY ticker;
