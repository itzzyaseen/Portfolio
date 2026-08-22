/* ============================================================================
   Vendor Performance Analysis — weighted scorecard
   Score = 50% delivery reliability + 35% quality + 15% cost efficiency
   ============================================================================ */

/* ---------------------------------------------------------------------------
   1. Per-vendor raw metrics  (one row per vendor)
   --------------------------------------------------------------------------- */
WITH vendor_metrics AS (
    SELECT
        v.vendor_id,
        v.vendor_name,
        v.category,
        v.region,
        COUNT(po.po_id)                                              AS pos,
        SUM(po.order_value)                                          AS total_spend,
        AVG(CASE WHEN d.delivered_date <= po.promised_date
                 THEN 1.0 ELSE 0 END)                                AS on_time_rate,
        AVG(CAST(d.rejected_qty AS DECIMAL) /
            NULLIF(po.qty_ordered, 0))                              AS defect_rate
    FROM vendors v
    JOIN purchase_orders po ON po.vendor_id = v.vendor_id
    JOIN deliveries      d  ON d.po_id      = po.po_id
    GROUP BY v.vendor_id, v.vendor_name, v.category, v.region
),

/* ---------------------------------------------------------------------------
   2. Convert raw metrics to 0-100 component scores.
   Cost efficiency uses a percentile rank of spend (cheaper share of wallet
   scores higher) via PERCENT_RANK().
   --------------------------------------------------------------------------- */
scored AS (
    SELECT
        vendor_id, vendor_name, category, region, pos, total_spend,
        ROUND(100.0 * on_time_rate, 1)                              AS delivery_score,
        ROUND(100.0 * (1 - defect_rate), 1)                         AS quality_score,
        ROUND(100.0 - 30.0 *
              PERCENT_RANK() OVER (ORDER BY total_spend), 1)        AS cost_score
    FROM vendor_metrics
)

/* ---------------------------------------------------------------------------
   3. Final weighted score + ranking + tier.
   --------------------------------------------------------------------------- */
SELECT
    RANK() OVER (ORDER BY
        0.50*delivery_score + 0.35*quality_score + 0.15*cost_score DESC) AS rank,
    vendor_id,
    vendor_name,
    category,
    region,
    pos,
    delivery_score,
    quality_score,
    cost_score,
    ROUND(0.50*delivery_score + 0.35*quality_score + 0.15*cost_score, 1) AS overall_score,
    CASE
        WHEN 0.50*delivery_score + 0.35*quality_score + 0.15*cost_score >= 85 THEN 'Preferred'
        WHEN 0.50*delivery_score + 0.35*quality_score + 0.15*cost_score >= 70 THEN 'Approved'
        ELSE 'Review / Replace'
    END                                                                 AS tier
FROM scored
ORDER BY rank;

/* ---------------------------------------------------------------------------
   4. Average score by region  (drives the regional rollup visual)
   --------------------------------------------------------------------------- */
WITH vendor_metrics AS (
    SELECT v.vendor_id, v.region,
           AVG(CASE WHEN d.delivered_date <= po.promised_date THEN 1.0 ELSE 0 END) AS on_time_rate,
           AVG(CAST(d.rejected_qty AS DECIMAL)/NULLIF(po.qty_ordered,0))           AS defect_rate,
           SUM(po.order_value)                                                     AS total_spend
    FROM vendors v
    JOIN purchase_orders po ON po.vendor_id = v.vendor_id
    JOIN deliveries d       ON d.po_id      = po.po_id
    GROUP BY v.vendor_id, v.region
)
SELECT
    region,
    COUNT(*)                                                      AS vendors,
    ROUND(AVG(100.0*on_time_rate), 1)                            AS avg_delivery,
    ROUND(AVG(100.0*(1-defect_rate)), 1)                         AS avg_quality
FROM vendor_metrics
GROUP BY region
ORDER BY avg_delivery DESC;

/* ---------------------------------------------------------------------------
   5. Bottom vendors to action this quarter  (weak + material spend)
   --------------------------------------------------------------------------- */
WITH vendor_metrics AS (
    SELECT v.vendor_id, v.vendor_name,
           AVG(CASE WHEN d.delivered_date <= po.promised_date THEN 1.0 ELSE 0 END) AS on_time_rate,
           AVG(CAST(d.rejected_qty AS DECIMAL)/NULLIF(po.qty_ordered,0))           AS defect_rate,
           SUM(po.order_value)                                                     AS total_spend
    FROM vendors v
    JOIN purchase_orders po ON po.vendor_id = v.vendor_id
    JOIN deliveries d       ON d.po_id      = po.po_id
    GROUP BY v.vendor_id, v.vendor_name
)
SELECT vendor_id, vendor_name,
       ROUND(100.0*on_time_rate,1)   AS delivery_score,
       ROUND(100.0*(1-defect_rate),1) AS quality_score,
       total_spend
FROM vendor_metrics
WHERE on_time_rate < 0.75 OR defect_rate > 0.08
ORDER BY total_spend DESC;
