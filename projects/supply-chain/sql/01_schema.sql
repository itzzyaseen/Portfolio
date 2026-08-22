/* ============================================================================
   Supply Chain Analytics — schema
   Dialect: ANSI SQL (tested on SQL Server / PostgreSQL / MySQL 8+)
   Load the four CSVs in /data into these tables before running 02_analysis.sql
   ============================================================================ */

CREATE TABLE suppliers (
    supplier_id   VARCHAR(10) PRIMARY KEY,
    supplier_name VARCHAR(80),
    country       VARCHAR(40),
    category      VARCHAR(40)
);

CREATE TABLE products (
    product_id    VARCHAR(10) PRIMARY KEY,
    product_name  VARCHAR(40),
    category      VARCHAR(40),
    unit_cost     DECIMAL(10,2),
    reorder_point INT,
    supplier_id   VARCHAR(10) REFERENCES suppliers(supplier_id)
);

CREATE TABLE orders (
    order_id       VARCHAR(12) PRIMARY KEY,
    product_id     VARCHAR(10) REFERENCES products(product_id),
    order_date     DATE,
    qty_ordered    INT,
    qty_delivered  INT,
    promised_date  DATE,
    delivered_date DATE,
    status         VARCHAR(10)
);

CREATE TABLE inventory (
    product_id     VARCHAR(10) REFERENCES products(product_id),
    snapshot_month CHAR(7),          -- 'YYYY-MM'
    opening_stock  INT,
    received       INT,
    units_sold     INT,
    closing_stock  INT,
    below_reorder  INT,              -- 1 if closing_stock < reorder_point
    PRIMARY KEY (product_id, snapshot_month)
);
