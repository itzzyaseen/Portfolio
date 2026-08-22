# Airlines Data Analysis

End-to-end BI build: clean a large flights table in SQL, then expose what actually drives
arrival delays — carrier, departure hour and route.

**[▶ Open the dashboard](dashboard/index.html)**

## Problem
**Business case:** Identify which operating factors are associated with arrival delays. The analysis compares carrier and departure-hour patterns in a cleaned flight sample.

## Data (`/data`)
> Synthetic case-study sample of 15,000 flights. No client data is included.

| File | Rows | Key columns |
|---|---|---|
| `flights.csv` | 15,000 | flight_id, flight_date, carrier, origin, dest, sched_dep_hour, dep_delay_min, arr_delay_min, distance_km, cancelled |

On-time rule: a flight is on-time when `arr_delay_min <= 15` (industry standard).

## SQL (`/sql`)
- `01_schema.sql` — table definition.
- `02_analysis.sql` — status split (on-time/delayed/cancelled), carrier league table ranked with
  `RANK()`, delay by departure hour, busiest routes with a running share via
  `SUM() OVER ()`, worst routes for delay, and a monthly on-time trend.

## Dashboard
Visuals: status donut · avg-delay-by-carrier bars · delay-by-hour line · KPI cards.
Key measures in [`dashboard/measures.dax`](dashboard/measures.dax).

## Reproduce in Power BI
1. Load `flights.csv` (or connect to SQL).
2. Add a calculated column `Status` and the measures from `measures.dax`.
3. Build the donut, carrier bars and hourly line; add slicers for carrier and route.
