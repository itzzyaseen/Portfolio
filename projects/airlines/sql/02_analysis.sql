/* ============================================================================
   Airlines Data Analysis — on-time performance & delay drivers
   A flight counts as on-time when arrival delay <= 15 minutes (industry rule).
   ============================================================================ */

/* ---------------------------------------------------------------------------
   1. Overall status split  — on-time / delayed / cancelled (the donut)
   --------------------------------------------------------------------------- */
SELECT
    COUNT(*)                                                        AS total_flights,
    SUM(CASE WHEN cancelled = 1 THEN 1 ELSE 0 END)                 AS cancelled,
    SUM(CASE WHEN cancelled = 0 AND arr_delay_min <= 15 THEN 1 ELSE 0 END) AS on_time,
    SUM(CASE WHEN cancelled = 0 AND arr_delay_min >  15 THEN 1 ELSE 0 END) AS delayed,
    ROUND(100.0 * SUM(CASE WHEN cancelled = 0 AND arr_delay_min <= 15 THEN 1 ELSE 0 END)
          / COUNT(*), 1)                                            AS on_time_pct
FROM flights;

/* ---------------------------------------------------------------------------
   2. Carrier league table  — ranked by average arrival delay
   RANK() surfaces best/worst carriers.
   --------------------------------------------------------------------------- */
SELECT
    carrier,
    COUNT(*)                                                        AS flights,
    ROUND(AVG(arr_delay_min), 1)                                   AS avg_arr_delay,
    ROUND(100.0 * AVG(CASE WHEN arr_delay_min <= 15 THEN 1.0 ELSE 0 END), 1) AS on_time_pct,
    RANK() OVER (ORDER BY AVG(arr_delay_min))                      AS punctuality_rank
FROM flights
WHERE cancelled = 0
GROUP BY carrier
ORDER BY avg_arr_delay;

/* ---------------------------------------------------------------------------
   3. Delay by departure hour  — when in the day do delays build up?
   --------------------------------------------------------------------------- */
SELECT
    sched_dep_hour,
    COUNT(*)                                                        AS flights,
    ROUND(AVG(arr_delay_min), 1)                                   AS avg_arr_delay
FROM flights
WHERE cancelled = 0
GROUP BY sched_dep_hour
ORDER BY sched_dep_hour;

/* ---------------------------------------------------------------------------
   4. Busiest routes  — origin->dest volume with a running share of total
   --------------------------------------------------------------------------- */
WITH route_vol AS (
    SELECT origin || '-' || dest AS route,     -- SQL Server: origin + '-' + dest
           COUNT(*)              AS flights
    FROM flights
    GROUP BY origin, dest
)
SELECT
    route,
    flights,
    ROUND(100.0 * flights / SUM(flights) OVER (), 2)              AS pct_of_all,
    RANK()  OVER (ORDER BY flights DESC)                         AS volume_rank
FROM route_vol
ORDER BY flights DESC
LIMIT 15;                                                          -- SQL Server: TOP 15

/* ---------------------------------------------------------------------------
   5. Worst routes for delay  (min 50 flights, so it's statistically fair)
   --------------------------------------------------------------------------- */
SELECT
    origin || '-' || dest                                         AS route,
    COUNT(*)                                                      AS flights,
    ROUND(AVG(arr_delay_min), 1)                                 AS avg_arr_delay
FROM flights
WHERE cancelled = 0
GROUP BY origin, dest
HAVING COUNT(*) >= 50
ORDER BY avg_arr_delay DESC
LIMIT 10;

/* ---------------------------------------------------------------------------
   6. Monthly on-time trend  — is punctuality improving?
   --------------------------------------------------------------------------- */
SELECT
    DATE_TRUNC('month', flight_date)                             AS flight_month,  -- SQL Server: DATEFROMPARTS(...)
    COUNT(*)                                                     AS flights,
    ROUND(100.0 * AVG(CASE WHEN arr_delay_min <= 15 THEN 1.0 ELSE 0 END), 1) AS on_time_pct
FROM flights
WHERE cancelled = 0
GROUP BY DATE_TRUNC('month', flight_date)
ORDER BY flight_month;
