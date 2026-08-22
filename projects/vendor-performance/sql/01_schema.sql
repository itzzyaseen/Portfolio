/* ============================================================================
   Vendor Performance Analysis — schema
   Dialect: ANSI SQL (SQL Server / PostgreSQL / MySQL 8+)
   ============================================================================ */

CREATE TABLE vendors (
    vendor_id      VARCHAR(10) PRIMARY KEY,
    vendor_name    VARCHAR(40),
    category       VARCHAR(40),
    region         VARCHAR(20),
    onboarded_date DATE
);

CREATE TABLE purchase_orders (
    po_id         VARCHAR(12) PRIMARY KEY,
    vendor_id     VARCHAR(10) REFERENCES vendors(vendor_id),
    po_date       DATE,
    promised_date DATE,
    order_value   DECIMAL(12,2),
    qty_ordered   INT
);

CREATE TABLE deliveries (
    po_id          VARCHAR(12) REFERENCES purchase_orders(po_id),
    delivered_date DATE,
    accepted_qty   INT,
    rejected_qty   INT,
    defect_flag    INT
);
