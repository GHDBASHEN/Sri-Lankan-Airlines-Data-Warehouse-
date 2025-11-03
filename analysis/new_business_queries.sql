-- =================================================================
-- SQL Analytics Queries for SriLankan Airlines Data Warehouse
--
-- This file contains 25 analytical queries grouped by subject area.
-- =================================================================


/*
1. Passenger & Airport Analysis (CAA Data)
*/

-- 1. Total Passenger Movements by Airport
-- Insight: Identify which airports handle the most traffic.
SELECT a.iata_code AS Airport, a.country, SUM(f.passengers) AS Total_Passengers, SUM(f.aircraft_movements) AS Total_Movements
FROM fact_passenger_movements f
JOIN dim_airport a ON f.airport_key = a.airport_key
GROUP BY a.iata_code, a.country
ORDER BY Total_Passengers DESC;


-- 2. Passenger Movement Trends Over Time (Annual)
-- Insight: Understand traffic growth patterns year-by-year.
SELECT d.year, d.quarter, SUM(f.passengers) AS Total_Passengers
FROM fact_passenger_movements f
JOIN dim_date d ON f.date_key = d.date_key
GROUP BY d.year, d.quarter
ORDER BY d.year, d.quarter;


-- 3. Monthly Passenger Traffic at Colombo (CMB) for 2023
-- Insight: Detect seasonal trends or peak travel months.
SELECT d.month_name, SUM(f.passengers) AS Total_Passengers
FROM fact_passenger_movements f
JOIN dim_date d ON f.date_key = d.date_key
JOIN dim_airport a ON f.airport_key = a.airport_key
WHERE a.iata_code = 'CMB' AND d.year = 2023
GROUP BY d.month, d.month_name
ORDER BY d.month;


-- 4. Busiest Months for Colombo (CMB)
-- Insight: Find top 3 busiest months historically.
SELECT d.year, d.month_name, SUM(f.passengers) AS Total_Passengers
FROM fact_passenger_movements f
JOIN dim_date d ON f.date_key = d.date_key
JOIN dim_airport a ON f.airport_key = a.airport_key
WHERE a.iata_code = 'CMB'
GROUP BY d.year, d.month_name
ORDER BY Total_Passengers DESC
LIMIT 3;


-- 5. Airport Passenger Market Share
-- Insight: Compare each airport’s contribution to total passenger traffic.
SELECT a.iata_code AS Airport,
       SUM(f.passengers) AS Total_Passengers,
       (SUM(f.passengers) * 100.0 / SUM(SUM(f.passengers)) OVER ()) AS Percentage_of_Total
FROM fact_passenger_movements f
JOIN dim_airport a ON f.airport_key = a.airport_key
GROUP BY a.iata_code
ORDER BY Percentage_of_Total DESC;


-- 6. Average Passengers per Flight (Efficiency)
-- Insight: Estimate flight occupancy or utilization rates.
SELECT a.iata_code AS Airport,
       SUM(f.passengers) / SUM(f.aircraft_movements) AS Avg_Passengers_Per_Movement
FROM fact_passenger_movements f
JOIN dim_airport a ON f.airport_key = a.airport_key
WHERE f.aircraft_movements > 0
GROUP BY a.iata_code
ORDER BY Avg_Passengers_Per_Movement DESC;


-- 7. Year-over-Year Passenger Growth (CMB)
-- Insight: Measure annual growth at the main airport.
WITH YearlyTraffic AS (
    SELECT d.year, SUM(f.passengers) AS Total_Passengers,
           LAG(SUM(f.passengers)) OVER (ORDER BY d.year) AS Prev_Year
    FROM fact_passenger_movements f
    JOIN dim_date d ON f.date_key = d.date_key
    JOIN dim_airport a ON f.airport_key = a.airport_key
    WHERE a.iata_code = 'CMB'
    GROUP BY d.year
)
SELECT year, Total_Passengers, Prev_Year,
       (Total_Passengers - Prev_Year) * 100.0 / Prev_Year AS YoY_Growth
FROM YearlyTraffic
WHERE Prev_Year > 0;


-- 8. Identify Low-Traffic Airports (Q1 2023)
-- Insight: Show aircraft movements to identify airports with low utilization.
SELECT a.iata_code AS Airport, SUM(f.aircraft_movements) AS Q1_Movements
FROM fact_passenger_movements f
JOIN dim_date d ON f.date_key = d.date_key
JOIN dim_airport a ON f.airport_key = a.airport_key
WHERE d.year = 2023 AND d.quarter = 1
GROUP BY a.iata_code;


-- 9. Weekend vs. Weekday Passenger Traffic
-- Insight: Understand travel patterns for scheduling.
SELECT CASE WHEN d.is_weekend = 1 THEN 'Weekend' ELSE 'Weekday' END AS Day_Type,
       SUM(f.passengers) AS Total_Passengers
FROM fact_passenger_movements f
JOIN dim_date d ON f.date_key = d.date_key
GROUP BY Day_Type;


-- Query 10: Weekend vs. Weekday Passenger Traffic by Airport
SELECT
    a.iata_code AS Airport,
    CASE
        WHEN d.is_weekend = 1 THEN 'Weekend'
        ELSE 'Weekday'
    END AS Day_Type,
    SUM(f.passengers) AS Total_Passengers,
    SUM(f.aircraft_movements) AS Total_Movements
FROM
    fact_passenger_movements f
JOIN
    dim_date d ON f.date_key = d.date_key
JOIN
    dim_airport a ON f.airport_key = a.airport_key
GROUP BY
    a.iata_code,
    Day_Type
ORDER BY
    Airport,
    Total_Passengers DESC;


/*
2. SriLankan Airlines Financial & Operational Analysis
*/

-- 11. Revenue vs. Operating Loss Over Years
-- Insight: Track profitability trends.
SELECT d.year,
       SUM(CASE WHEN m.metric_name = 'Revenue' THEN f.value ELSE 0 END) AS Revenue,
       SUM(CASE WHEN m.metric_name = 'Operating Loss' THEN f.value ELSE 0 END) AS Operating_Loss
FROM fact_airline_financials f
JOIN dim_date d ON f.date_key = d.date_key
JOIN dim_metric m ON f.metric_key = m.metric_key
GROUP BY d.year
ORDER BY d.year;


-- 12. All Operational Metrics (2022)
-- Insight: Summarize fleet, passengers, etc. for a year.
SELECT m.metric_name, f.value
FROM fact_airline_financials f
JOIN dim_metric m ON f.metric_key = m.metric_key
JOIN dim_date d ON f.date_key = d.date_key
WHERE d.year = 2022 AND m.metric_category = 'Operational';


-- 13. Revenue per Passenger (Proxy)
-- Insight: Estimate financial efficiency.
WITH Metrics AS (
    SELECT m.metric_name, f.value
    FROM fact_airline_financials f
    JOIN dim_date d ON f.date_key = d.date_key
    JOIN dim_metric m ON f.metric_key = m.metric_key
    WHERE d.year = 2023 AND f.currency = 'LKR'
      AND m.metric_name IN ('Revenue', 'Passengers')
)
SELECT (SELECT SUM(value) FROM Metrics WHERE metric_name = 'Revenue') /
       (SELECT SUM(value) FROM Metrics WHERE metric_name = 'Passengers') AS LKR_Revenue_Per_Passenger;


-- 14. Employee Count Trend
-- Insight: See how staff numbers evolved.
SELECT d.year, f.value AS Employee_Count
FROM fact_airline_financials f
JOIN dim_date d ON f.date_key = d.date_key
JOIN dim_metric m ON f.metric_key = m.metric_key
WHERE m.metric_name = 'Employee Count'
ORDER BY d.year;


-- 15. Year with Highest Operating Loss
-- Insight: Identify worst-performing year.
SELECT d.year, f.value AS Operating_Loss
FROM fact_airline_financials f
JOIN dim_metric m ON f.metric_key = m.metric_key
JOIN dim_date d ON f.date_key = d.date_key
WHERE m.metric_name = 'Operating Loss'
ORDER BY f.value ASC
LIMIT 1;


/*
3. Global & Comparative (World Bank Data)
*/

-- 16. Sri Lanka vs. Neighbors (Latest Year)
-- Insight: Benchmark regionally.
SELECT c.country_name, f.passengers
FROM fact_world_transport_stats f
JOIN dim_country c ON f.country_key = c.country_key
JOIN dim_date d ON f.date_key = d.date_key
WHERE d.year = (SELECT MAX(d2.year) FROM dim_date d2)
  AND c.country_name IN ('Sri Lanka', 'India', 'Maldives', 'Bangladesh', 'Pakistan')
ORDER BY f.passengers DESC;


-- 17. Fastest Growing Countries (2022)
-- Insight: Identify global growth leaders.
WITH YearlyData AS (
    SELECT c.country_name, d.year, f.passengers,
           LAG(f.passengers) OVER (PARTITION BY c.country_name ORDER BY d.year) AS Prev_Year
    FROM fact_world_transport_stats f
    JOIN dim_country c ON f.country_key = c.country_key
    JOIN dim_date d ON f.date_key = d.date_key
)
SELECT country_name, passengers, Prev_Year,
       (passengers - Prev_Year) * 100.0 / Prev_Year AS Growth_Percentage
FROM YearlyData
WHERE year = 2022 AND Prev_Year > 0
ORDER BY Growth_Percentage DESC
LIMIT 10;


-- 18. Sri Lanka’s Share of Regional Traffic (2022)
-- Insight: Show Sri Lanka’s proportion of regional passengers.
WITH Regional AS (
    SELECT c.country_name, f.passengers
    FROM fact_world_transport_stats f
    JOIN dim_date d ON f.date_key = d.date_key
    JOIN dim_country c ON f.country_key = c.country_key
    WHERE d.year = 2022 AND c.country_name IN ('Sri Lanka', 'India', 'Maldives')
)
SELECT (SELECT passengers FROM Regional WHERE country_name = 'Sri Lanka') * 100.0 / SUM(passengers) AS SriLanka_Percentage
FROM Regional;


-- 19. Top 10 Countries by Passenger Volume (Latest Year)
-- Insight: See the largest aviation markets.
SELECT c.country_name, f.passengers
FROM fact_world_transport_stats f
JOIN dim_country c ON f.country_key = c.country_key
JOIN dim_date d ON f.date_key = d.date_key
WHERE d.year = (SELECT MAX(year) FROM dim_date)
ORDER BY f.passengers DESC
LIMIT 10;


-- 20. Count Unique Countries in Dataset
-- Insight: Data coverage check.
SELECT COUNT(DISTINCT country_name) AS Total_Countries FROM dim_country;


/*
4. Combined or Advanced Multi-Fact Insights
*/

-- Query 21: Aircraft Fleet Analysis by Manufacturer
SELECT
    manufacturer,
    COUNT(aircraft_key) AS Total_Aircraft,
    AVG(seat_capacity) AS Avg_Seat_Capacity
FROM
    dim_aircraft
GROUP BY
    manufacturer
ORDER BY
    Total_Aircraft DESC;


-- 22. SriLankan Airlines vs. Total CAA Passengers (2022)
-- Insight: Measure airline’s national traffic share.
SELECT
    IFNULL((SELECT SUM(f.value) FROM fact_airline_financials f
            JOIN dim_metric m ON f.metric_key = m.metric_key
            JOIN dim_date d ON f.date_key = d.date_key
            WHERE m.metric_name = 'Passengers' AND d.year = 2022), 0) /
    IFNULL((SELECT SUM(f.passengers) FROM fact_passenger_movements f
            JOIN dim_date d ON f.date_key = d.date_key WHERE d.year = 2022), 1) * 100 AS SL_Passenger_Share;


-- 23. Correlate Airline Revenue with Total CAA Passengers
-- Insight: See if national traffic impacts airline revenue.
SELECT fin.year, fin.total_revenue, traffic.total_passengers
FROM (
  SELECT d.year, SUM(f.value) AS total_revenue
  FROM fact_airline_financials f JOIN dim_metric m ON f.metric_key = m.metric_key JOIN dim_date d ON f.date_key = d.date_key
  WHERE m.metric_name = 'Revenue' GROUP BY d.year
) fin
JOIN (
  SELECT d.year, SUM(f.passengers) AS total_passengers
  FROM fact_passenger_movements f JOIN dim_date d ON f.date_key = d.date_key
  GROUP BY d.year
) traffic ON fin.year = traffic.year
ORDER BY fin.year;


-- 24. Percentage of Sri Lankan Passengers via CMB
-- Insight: Gauge CMB’s national dominance.
WITH yearly AS (
  SELECT d.year, SUM(f.passengers) AS total, SUM(CASE WHEN a.iata_code='CMB' THEN f.passengers ELSE 0 END) AS cmb
  FROM fact_passenger_movements f JOIN dim_date d ON f.date_key=d.date_key JOIN dim_airport a ON f.airport_key=a.airport_key
  GROUP BY d.year
)
SELECT year, total, cmb, ROUND((cmb/total)*100,2) AS CMB_Percentage FROM yearly ORDER BY year;


-- 25. Quarter with Highest Passenger Traffic (All Airports)
-- Insight: Identify most active quarter historically.
SELECT d.year, d.quarter, SUM(f.passengers) AS Total_Passengers
FROM fact_passenger_movements f
JOIN dim_date d ON f.date_key = d.date_key
GROUP BY d.year, d.quarter
ORDER BY Total_Passengers DESC
LIMIT 1;