/* ============================================================================
   Airlines Data Analysis — schema
   Dialect: ANSI SQL (SQL Server / PostgreSQL / MySQL 8+)
   ============================================================================ */

CREATE TABLE flights (
    flight_id      VARCHAR(12) PRIMARY KEY,
    flight_date    DATE,
    carrier        VARCHAR(20),
    origin         CHAR(3),
    dest           CHAR(3),
    sched_dep_hour INT,
    dep_delay_min  INT,
    arr_delay_min  INT,
    distance_km    INT,
    cancelled      INT           -- 1 = cancelled
);
