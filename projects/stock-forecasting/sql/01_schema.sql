/* ============================================================================
   Stock Forecasting — schema
   Dialect: ANSI SQL (SQL Server / PostgreSQL / MySQL 8+)
   ============================================================================ */

CREATE TABLE stock_prices (
    ticker  VARCHAR(12),
    date    DATE,
    open    DECIMAL(12,2),
    high    DECIMAL(12,2),
    low     DECIMAL(12,2),
    close   DECIMAL(12,2),
    volume  BIGINT,
    PRIMARY KEY (ticker, date)
);
