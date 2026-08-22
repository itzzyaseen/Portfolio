/* ============================================================================
   Supply Chain Analytics — analytical queries
   These are the queries that feed the Power BI model / dashboard.
   ============================================================================ */

/* ---------------------------------------------------------------------------
   1. OTIF (On-Time-In-Full) by month  — the headline KPI trend
   An order is OTIF only when it arrived on/before the promised date AND
   the full quantity was delivered.
   --------------------------------------------------------------------------- */
WITH order_flags AS (
    SELECT
        order_id,
        DATE_TRUNC('month', order_date)                         AS order_month,  -- SQL Server: DATEFROMPARTS(YEAR(order_date),MONTH(order_date),1)
        CASE WHEN delivered_date <= promised_date THEN 1 ELSE 0 END AS on_time,
        CASE WHEN qty_delivered  >= qty_ordered   THEN 1 ELSE 0 END AS in_full
    FROM orders
)
SELECT
    order_month,
    COUNT(*)                                                   AS total_orders,
    ROUND(100.0 * AVG(on_time),               1)              AS on_time_pct,
    ROUND(100.0 * AVG(in_full),               1)              AS in_full_pct,
    ROUND(100.0 * AVG(on_time * in_full),     1)              AS otif_pct
FROM order_flags
GROUP BY order_month
ORDER BY order_month;

/* ---------------------------------------------------------------------------
   2. Month-over-month OTIF change with a window function (LAG)
   --------------------------------------------------------------------------- */
WITH monthly AS (
    SELECT
        DATE_TRUNC('month', order_date) AS order_month,
        AVG(CASE WHEN delivered_date <= promised_date
                  AND qty_delivered >= qty_ordered THEN 1.0 ELSE 0 END) AS otif
    FROM orders
    GROUP BY DATE_TRUNC('month', order_date)
)
SELECT
    order_month,
    ROUND(100.0 * otif, 1)                                            AS otif_pct,
    ROUND(100.0 * (otif - LAG(otif) OVER (ORDER BY order_month)), 1)  AS mom_change_pts
FROM monthly
ORDER BY order_month;

/* ---------------------------------------------------------------------------
   3. Inventory turnover by product  (units sold / average stock held)
   Higher = leaner inventory. Flags slow movers.
   --------------------------------------------------------------------------- */
SELECT
    p.product_id,
    p.product_name,
    p.category,
    SUM(i.units_sold)                                             AS units_sold,
    ROUND(AVG((i.opening_stock + i.closing_stock) / 2.0), 0)      AS avg_stock,
    ROUND(SUM(i.units_sold) /
          NULLIF(AVG((i.opening_stock + i.closing_stock) / 2.0), 0), 2) AS turnover_ratio
FROM inventory i
JOIN products p ON p.product_id = i.product_id
GROUP BY p.product_id, p.product_name, p.category
ORDER BY turnover_ratio DESC;

/* ---------------------------------------------------------------------------
   4. Reorder-point breaches — products that dipped below their reorder point
   This is what drives the automated stockout alert on the dashboard.
   --------------------------------------------------------------------------- */
SELECT
    i.snapshot_month,
    COUNT(*)                                                     AS products_below_reorder,
    STRING_AGG(p.product_name, ', ')                            AS which_products
FROM inventory i
JOIN products p ON p.product_id = i.product_id
WHERE i.below_reorder = 1
GROUP BY i.snapshot_month
ORDER BY i.snapshot_month;

/* ---------------------------------------------------------------------------
   5. Supplier scorecard — rank suppliers by the OTIF of their products
   Uses RANK() so ties share a position.
   --------------------------------------------------------------------------- */
WITH supplier_otif AS (
    SELECT
        s.supplier_id,
        s.supplier_name,
        COUNT(o.order_id)                                        AS orders,
        AVG(CASE WHEN o.delivered_date <= o.promised_date
                  AND o.qty_delivered >= o.qty_ordered
                 THEN 1.0 ELSE 0 END)                            AS otif
    FROM suppliers s
    JOIN products  p ON p.supplier_id = s.supplier_id
    JOIN orders    o ON o.product_id  = p.product_id
    GROUP BY s.supplier_id, s.supplier_name
)
SELECT
    RANK() OVER (ORDER BY otif DESC)          AS rank,
    supplier_id,
    supplier_name,
    orders,
    ROUND(100.0 * otif, 1)                    AS otif_pct
FROM supplier_otif
ORDER BY rank;

/* ---------------------------------------------------------------------------
   6. Category spend  — value at risk by product category
   --------------------------------------------------------------------------- */
SELECT
    p.category,
    SUM(o.qty_ordered * p.unit_cost)          AS total_spend
FROM orders o
JOIN products p ON p.product_id = o.product_id
GROUP BY p.category
ORDER BY total_spend DESC;
