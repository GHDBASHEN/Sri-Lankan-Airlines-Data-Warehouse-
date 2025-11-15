1. Total Passenger Movements by Airport
Business Question: "What is the total number of passengers and aircraft movements recorded by the CAA for each airport?"


-- business_query_1.sql
SELECT
    a.iata_code AS Airport,
    a.country AS Country,
    SUM(f.passengers) AS Total_Passengers,
    SUM(f.aircraft_movements) AS Total_Movements
FROM
    fact_passenger_movements f
JOIN
    dim_airport a ON f.airport_key = a.airport_key
GROUP BY
    a.iata_code, a.country
ORDER BY
    Total_Passengers DESC;







2.Passenger Movement Trends Over Time (Annual)
Business Question: "How many passengers did the CAA record each year and quarter?"



SELECT
    d.year AS Year,
    d.quarter AS Quarter,
    SUM(f.passengers) AS Total_Passengers
FROM
    fact_passenger_movements f
JOIN
    dim_date d ON f.date_key = d.date_key
GROUP BY
    d.year, d.quarter
ORDER BY
    d.year, d.quarter;




3. SriLankan Airlines Financial & Operational Report
Business Question: "What are the key financial and operational metrics for SriLankan Airlines for 2022 and 2023?"



SELECT
    d.year AS Year,
    m.metric_name AS Metric,
    f.value AS Value,
    f.currency AS Currency
FROM
    fact_airline_financials f
JOIN
    dim_metric m ON f.metric_key = m.metric_key
JOIN
    dim_date d ON f.date_key = d.date_key
WHERE
    d.year IN (2022, 2023)
ORDER BY
    d.year, m.metric_name;





4. World Bank Passenger Data (Sri Lanka vs. Neighbors)
Business Question: "How does Sri Lanka's annual passenger count (from World Bank data) compare to its neighbors like India and Maldives?"



SELECT
    d.year AS Year,
    c.country_name AS Country,
    f.passengers AS Total_Passengers
FROM
    fact_world_transport_stats f
JOIN
    dim_country c ON f.country_key = c.country_key
JOIN
    dim_date d ON f.date_key = d.date_key
WHERE
    c.country_name IN ('Sri Lanka', 'India', 'Maldives', 'Bangladesh')
ORDER BY
    c.country_name, d.year;




5. Monthly Passenger Traffic at Colombo (CMB) for 2023
Business Question: "What did the monthly passenger traffic at Colombo (CMB) look like in 2023?"


SELECT
    d.year AS Year,
    d.month AS Month_Number,
    d.month_name AS Month_Name,
    SUM(f.passengers) AS Total_Passengers
FROM
    fact_passenger_movements f
JOIN
    dim_date d ON f.date_key = d.date_key
JOIN
    dim_airport a ON f.airport_key = a.airport_key
WHERE
    a.iata_code = 'CMB'
    AND d.year = 2023
GROUP BY
    d.year, d.month, d.month_name
ORDER BY
    d.month;


Passenger Movement Analysis (from CAA Data)
Busiest Months for Colombo (CMB)

Business Question: "What are the top 3 busiest months on record for Colombo (CMB) based on passenger volume?"

SQL Query:

SQL

SELECT
    d.year,
    d.month_name,
    SUM(f.passengers) AS Total_Passengers
FROM fact_passenger_movements f
JOIN dim_date d ON f.date_key = d.date_key
JOIN dim_airport a ON f.airport_key = a.airport_key
WHERE
    a.iata_code = 'CMB'
GROUP BY
    d.year, d.month_name
ORDER BY
    Total_Passengers DESC
LIMIT 3;
Airport Passenger Market Share

Business Question: "Of all passengers recorded by the CAA, what percentage of the total traffic did each airport handle?"

SQL Query:

SQL

SELECT
    a.iata_code AS Airport,
    SUM(f.passengers) AS Total_Passengers,
    (SUM(f.passengers) * 100.0 / SUM(SUM(f.passengers)) OVER ()) AS Percentage_of_Total
FROM fact_passenger_movements f
JOIN dim_airport a ON f.airport_key = a.airport_key
GROUP BY
    a.iata_code
ORDER BY
    Percentage_of_Total DESC;
Average Passengers per Flight (Proxy)

Business Question: "What is the average number of passengers per aircraft movement at each airport (as a proxy for how full flights are)?"

SQL Query:

SQL

SELECT
    a.iata_code AS Airport,
    SUM(f.passengers) / SUM(f.aircraft_movements) AS Avg_Passengers_Per_Movement
FROM fact_passenger_movements f
JOIN dim_airport a ON f.airport_key = a.airport_key
WHERE
    f.aircraft_movements > 0
GROUP BY
    a.iata_code
ORDER BY
    Avg_Passengers_Per_Movement DESC;
Year-over-Year (YoY) Passenger Growth (CMB)

Business Question: "What was the year-over-year passenger growth percentage for Colombo (CMB)?"

SQL Query:

SQL

WITH YearlyTraffic AS (
    SELECT
        d.year,
        SUM(f.passengers) AS Total_Passengers,
        LAG(SUM(f.passengers), 1, 0) OVER (ORDER BY d.year) AS Previous_Year_Passengers
    FROM fact_passenger_movements f
    JOIN dim_date d ON f.date_key = d.date_key
    JOIN dim_airport a ON f.airport_key = a.airport_key
    WHERE a.iata_code = 'CMB'
    GROUP BY d.year
)
SELECT
    year,
    Total_Passengers,
    Previous_Year_Passengers,
    (Total_Passengers - Previous_Year_Passengers) * 100.0 / Previous_Year_Passengers AS YoY_Growth_Percentage
FROM YearlyTraffic
WHERE Previous_Year_Passengers > 0;
Identify Low-Traffic Airports/Quarters

Business Question: "Which airports had fewer than 1,000 aircraft movements in the first quarter of 2023?"

SQL Query:

SQL

SELECT
    a.iata_code AS Airport,
    SUM(f.aircraft_movements) AS Q1_Movements
FROM fact_passenger_movements f
JOIN dim_date d ON f.date_key = d.date_key
JOIN dim_airport a ON f.airport_key = a.airport_key
WHERE
    d.year = 2023 AND d.quarter = 1
GROUP BY
    a.iata_code
HAVING
    SUM(f.aircraft_movements) < 1000;
Airline Financial Analysis (from SriLankan Report)
Revenue vs. Operating Loss (Side-by-Side)

Business Question: "Show me the total Revenue and Operating Loss for SriLankan Airlines side-by-side for each year."

SQL Query:

SQL

SELECT
    d.year,
    SUM(CASE WHEN m.metric_name = 'Revenue' THEN f.value ELSE 0 END) AS Total_Revenue,
    SUM(CASE WHEN m.metric_name = 'Operating Loss' THEN f.value ELSE 0 END) AS Total_Operating_Loss
FROM fact_airline_financials f
JOIN dim_date d ON f.date_key = d.date_key
JOIN dim_metric m ON f.metric_key = m.metric_key
WHERE
    f.currency = 'LKR' OR f.currency = 'USD' -- Filter for primary currencies
GROUP BY
    d.year
ORDER BY
    d.year;

    
All Operational Metrics for a Specific Year

Business Question: "What were all the 'Operational' metrics (like Passengers, Fleet Size) for SriLankan Airlines in 2022?"


SELECT
    m.metric_name,
    f.value
FROM fact_airline_financials f
JOIN dim_metric m ON f.metric_key = m.metric_key
JOIN dim_date d ON f.date_key = d.date_key
WHERE
    d.year = 2022
    AND m.metric_category = 'Operational';


Financials Reported in USD
Business Question: "What is the total value of all financial metrics reported in 'USD'?"



SELECT
    m.metric_name,
    SUM(f.value) AS Total_USD_Value
FROM fact_airline_financials f
JOIN dim_metric m ON f.metric_key = m.metric_key
WHERE
    f.currency = 'USD'
    AND m.metric_category = 'Financial'
GROUP BY
    m.metric_name;


Revenue per Passenger (Proxy)

Business Question: "What was the approximate LKR revenue per passenger for SriLankan Airlines in 2023?"



WITH Metrics AS (
    SELECT
        m.metric_name,
        f.value
    FROM fact_airline_financials f
    JOIN dim_date d ON f.date_key = d.date_key
    JOIN dim_metric m ON f.metric_key = m.metric_key
    WHERE
        d.year = 2023 AND f.currency = 'LKR'
        AND m.metric_name IN ('Revenue', 'Passengers')
)
SELECT
    (SELECT value FROM Metrics WHERE metric_name = 'Revenue') /
    (SELECT value FROM Metrics WHERE metric_name = 'Passengers')
    AS LKR_Revenue_Per_Passenger;


Employee Count Trend

Business Question: "How has the employee count for SriLankan Airlines changed over the years?"



SELECT
    d.year,
    f.value AS Employee_Count
FROM fact_airline_financials f
JOIN dim_date d ON f.date_key = d.date_key
JOIN dim_metric m ON f.metric_key = m.metric_key
WHERE
    m.metric_name = 'Employee Count'
ORDER BY
    d.year;



Global Context Analysis (from World Bank Data)
Fastest Growing Countries (Passenger Volume)

Business Question: "Which country in the World Bank data had the highest passenger growth from 2021 to 2022?"



WITH YearlyData AS (
    SELECT
        c.country_name,
        d.year,
        f.passengers,
        LAG(f.passengers, 1, 0) OVER (PARTITION BY c.country_name ORDER BY d.year) AS prev_year_passengers
    FROM fact_world_transport_stats f
    JOIN dim_date d ON f.date_key = d.date_key
    JOIN dim_country c ON f.country_key = c.country_key
)
SELECT
    country_name,
    passengers AS passengers_2022,
    prev_year_passengers AS passengers_2021,
    (passengers - prev_year_passengers) * 100.0 / prev_year_passengers AS Growth_Percentage
FROM YearlyData
WHERE
    year = 2022 AND prev_year_passengers > 0
ORDER BY
    Growth_Percentage DESC
LIMIT 10;


Sri Lankas Share of Regional Traffic

Business Question: "In 2022, what percentage of the total passenger traffic for Sri Lanka, India, and Maldives (from World Bank data) was attributable to Sri Lanka?"



WITH RegionalTraffic AS (
    SELECT
        c.country_name,
        f.passengers
    FROM fact_world_transport_stats f
    JOIN dim_date d ON f.date_key = d.date_key
    JOIN dim_country c ON f.country_key = c.country_key
    WHERE
        d.year = 2022
        AND c.country_name IN ('Sri Lanka', 'India', 'Maldives')
)
SELECT
    (SELECT passengers FROM RegionalTraffic WHERE country_name = 'Sri Lanka') * 100.0 / SUM(passengers) AS SriLanka_Percentage
FROM RegionalTraffic;


Countries with Missing Data

Business Question: "Which countries have passenger data for 2018 but are missing data for 2019?"



SELECT
    c.country_name
FROM fact_world_transport_stats f
JOIN dim_date d ON f.date_key = d.date_key
JOIN dim_country c ON f.country_key = c.country_key
WHERE
    d.year = 2018
AND c.country_key NOT IN (
    SELECT f2.country_key
    FROM fact_world_transport_stats f2
    JOIN dim_date d2 ON f2.date_key = d2.date_key
    WHERE d2.year = 2019
);


Combined Analysis (Joining Multiple Facts)
Compare CAA vs. World Bank Passenger Data for Sri Lanka

Business Question: "How does the total annual passenger count from the CAA data compare to the World Bank data for Sri Lanka?"



WITH CAATotal AS (
    SELECT
        d.year,
        SUM(f.passengers) AS caa_passengers
    FROM fact_passenger_movements f
    JOIN dim_date d ON f.date_key = d.date_key
    GROUP BY d.year
),
WBTotal AS (
    SELECT
        d.year,
        f.passengers AS wb_passengers
    FROM fact_world_transport_stats f
    JOIN dim_date d ON f.date_key = d.date_key
    JOIN dim_country c ON f.country_key = c.country_key
    WHERE c.country_name = 'Sri Lanka'
)
SELECT
    COALESCE(c.year, w.year) AS Year,
    c.caa_passengers,
    w.wb_passengers,
    (c.caa_passengers - w.wb_passengers) AS Difference
FROM CAATotal c
FULL OUTER JOIN WBTotal w ON c.year = w.year
ORDER BY Year;


SriLankan Airlines vs. Total CAA Passengers

Business Question: "In 2022, what percentage of total CAA-reported passengers were SriLankan Airlines passengers?"



SELECT
    (
        SELECT f_sl.value
        FROM fact_airline_financials f_sl
        JOIN dim_date d_sl ON f_sl.date_key = d_sl.date_key
        JOIN dim_metric m_sl ON f_sl.metric_key = m_sl.metric_key
        WHERE d_sl.year = 2022 AND m_sl.metric_name = 'Passengers'
        LIMIT 1
    )
    /
    (
        SELECT SUM(f_caa.passengers)
        FROM fact_passenger_movements f_caa
        JOIN dim_date d_caa ON f_caa.date_key = d_caa.date_key
        WHERE d_caa.year = 2022
    ) * 100.0 AS SL_Passenger_Share_of_CAA;




    Passenger & Traffic Analysis (Sri Lanka)
These queries focus on the data from the Civil Aviation Authority.

Total passengers per year in Sri Lanka:

sql
SELECT d.year, SUM(f.passengers) AS total_passengers
FROM fact_passenger_movements f
JOIN dim_date d ON f.date_key = d.date_key
GROUP BY d.year
ORDER BY d.year;
Busiest airport by total passenger volume:

sql
SELECT a.airport_name, SUM(f.passengers) AS total_passengers
FROM fact_passenger_movements f
JOIN dim_airport a ON f.airport_key = a.airport_key
GROUP BY a.airport_name
ORDER BY total_passengers DESC;
Monthly passenger traffic for Colombo (CMB) in the latest year:

sql
 Show full code block 
SELECT d.month_name, SUM(f.passengers) AS monthly_passengers
FROM fact_passenger_movements f
JOIN dim_date d ON f.date_key = d.date_key
JOIN dim_airport a ON f.airport_key = a.airport_key
WHERE a.iata_code = 'CMB' AND d.year = (SELECT MAX(year) FROM dim_date)
GROUP BY d.year, d.month, d.month_name
ORDER BY d.month;
Year-over-year passenger growth rate for all Sri Lankan airports combined:

sql
 Show full code block 
WITH yearly_traffic AS (
    SELECT d.year, SUM(f.passengers) AS total_passengers
    FROM fact_passenger_movements f
    JOIN dim_date d ON f.date_key = d.date_key
    GROUP BY d.year
)
SELECT
    year, total_passengers,
    LAG(total_passengers, 1, 0) OVER (ORDER BY year) AS previous_year_passengers,
    ROUND(((total_passengers - LAG(total_passengers, 1, 0) OVER (ORDER BY year)) / LAG(total_passengers, 1, 0) OVER (ORDER BY year)) * 100, 2) AS growth_percentage
FROM yearly_traffic
ORDER BY year;
Average passengers per aircraft movement (a measure of flight fullness/efficiency) at each airport:

sql
 Show full code block 
SELECT a.airport_name, ROUND(SUM(f.passengers) / SUM(f.aircraft_movements)) AS avg_passengers_per_flight
FROM fact_passenger_movements f
JOIN dim_airport a ON f.airport_key = a.airport_key
WHERE f.aircraft_movements > 0
GROUP BY a.airport_name
ORDER BY avg_passengers_per_flight DESC;
Passenger traffic on weekends vs. weekdays:

sql
 Show full code block 
SELECT
    CASE WHEN d.is_weekend = 1 THEN 'Weekend' ELSE 'Weekday' END AS day_type,
    SUM(f.passengers) AS total_passengers
FROM fact_passenger_movements f
JOIN dim_date d ON f.date_key = d.date_key
GROUP BY day_type;
Top 5 busiest days on record at Bandaranaike International Airport (CMB):

sql
 Show full code block 
SELECT d.full_date, f.passengers
FROM fact_passenger_movements f
JOIN dim_date d ON f.date_key = d.date_key
JOIN dim_airport a ON f.airport_key = a.airport_key
WHERE a.iata_code = 'CMB'
ORDER BY f.passengers DESC
LIMIT 5;
Financial & Operational Analysis (SriLankan Airlines)
These queries focus on the data from the SriLankan Airlines annual reports.

SriLankan Airlines' revenue and operating loss trend over the years:

sql
 Show full code block 
SELECT
    d.year,
    SUM(CASE WHEN m.metric_name = 'Revenue' THEN f.value ELSE 0 END) AS total_revenue,
    SUM(CASE WHEN m.metric_name = 'Operating Loss' THEN f.value ELSE 0 END) AS operating_loss
FROM fact_airline_financials f
JOIN dim_date d ON f.date_key = d.date_key
JOIN dim_metric m ON f.metric_key = m.metric_key
WHERE m.metric_category = 'Financial'
GROUP BY d.year
ORDER BY d.year;
List all operational metrics for the most recent year:

sql
 Show full code block 
SELECT m.metric_name, f.value
FROM fact_airline_financials f
JOIN dim_metric m ON f.metric_key = m.metric_key
JOIN dim_date d ON f.date_key = d.date_key
WHERE m.metric_category = 'Operational'
  AND d.year = (SELECT MAX(d2.year) FROM fact_airline_financials f2 JOIN dim_date d2 ON f2.date_key = d2.date_key)
ORDER BY m.metric_name;
Average passenger load factor over the last 5 years:

sql
 Show full code block 
SELECT AVG(f.value) AS average_load_factor
FROM fact_airline_financials f
JOIN dim_metric m ON f.metric_key = m.metric_key
JOIN dim_date d ON f.date_key = d.date_key
WHERE m.metric_name = 'Passenger Load Factor'
  AND d.year > (SELECT MAX(year) FROM dim_date) - 5;
Compare Cargo Revenue to Passenger Revenue (as a percentage) over time:

sql
 Show full code block 
WITH yearly_revenue AS (
    SELECT
        d.year,
        SUM(CASE WHEN m.metric_name = 'Revenue' THEN f.value ELSE 0 END) AS passenger_revenue,
        SUM(CASE WHEN m.metric_name = 'Cargo Revenue' THEN f.value ELSE 0 END) AS cargo_revenue
    FROM fact_airline_financials f
    JOIN dim_date d ON f.date_key = d.date_key
    JOIN dim_metric m ON f.metric_key = m.metric_key
    GROUP BY d.year
)
SELECT year, passenger_revenue, cargo_revenue,
       ROUND((cargo_revenue / passenger_revenue) * 100, 2) AS cargo_as_pct_of_passenger_revenue
FROM yearly_revenue
WHERE passenger_revenue > 0
ORDER BY year;
Show the year with the highest recorded operating loss:

sql
 Show full code block 
SELECT d.year, f.value AS operating_loss
FROM fact_airline_financials f
JOIN dim_metric m ON f.metric_key = m.metric_key
JOIN dim_date d ON f.date_key = d.date_key
WHERE m.metric_name = 'Operating Loss'
ORDER BY f.value ASC -- Loss is negative, so ascending order finds the largest loss
LIMIT 1;
Global & Comparative Analysis (World Bank Data)
These queries use the World Bank data to compare Sri Lanka with other countries.

Compare Sri Lanka's total air passengers with neighboring countries for the latest available year:

sql
 Show full code block 
SELECT c.country_name, f.passengers
FROM fact_world_transport_stats f
JOIN dim_country c ON f.country_key = c.country_key
JOIN dim_date d ON f.date_key = d.date_key
WHERE d.year = (SELECT MAX(d2.year) FROM fact_world_transport_stats f2 JOIN dim_date d2 ON f2.date_key = d2.date_key)
  AND c.country_name IN ('Sri Lanka', 'India', 'Pakistan', 'Bangladesh', 'Maldives')
ORDER BY f.passengers DESC;
Find the top 10 countries by air passenger volume in the most recent year:

sql
 Show full code block 
SELECT c.country_name, f.passengers
FROM fact_world_transport_stats f
JOIN dim_country c ON f.country_key = c.country_key
JOIN dim_date d ON f.date_key = d.date_key
WHERE d.year = (SELECT MAX(d2.year) FROM fact_world_transport_stats f2 JOIN dim_date d2 ON f2.date_key = d2.date_key)
ORDER BY f.passengers DESC
LIMIT 10;
Track Sri Lanka's air passenger growth vs. the world average over the last decade:

sql
 Show full code block 
WITH yearly_stats AS (
    SELECT
        d.year,
        AVG(CASE WHEN c.country_name = 'Sri Lanka' THEN f.passengers END) AS srilanka_passengers,
        AVG(f.passengers) AS world_avg_passengers
    FROM fact_world_transport_stats f
    JOIN dim_country c ON f.country_key = c.country_key
    JOIN dim_date d ON f.date_key = d.date_key
    WHERE d.year > (SELECT MAX(year) FROM dim_date) - 10
    GROUP BY d.year
)
SELECT year, srilanka_passengers, ROUND(world_avg_passengers) as world_avg_passengers
FROM yearly_stats
ORDER BY year;
Combined & Advanced Queries
These queries join multiple fact and dimension tables for deeper insights.

Correlate SriLankan Airlines' revenue with total passenger traffic in Sri Lanka:

sql
 Show full code block 
SELECT
    fin.year,
    fin.total_revenue,
    traffic.total_passengers
FROM
    (SELECT d.year, SUM(f.value) AS total_revenue FROM fact_airline_financials f JOIN dim_date d ON f.date_key = d.date_key JOIN dim_metric m ON f.metric_key = m.metric_key WHERE m.metric_name = 'Revenue' GROUP BY d.year) AS fin
JOIN
    (SELECT d.year, SUM(f.passengers) AS total_passengers FROM fact_passenger_movements f JOIN dim_date d ON f.date_key = d.date_key GROUP BY d.year) AS traffic
ON fin.year = traffic.year
ORDER BY fin.year;
List all available financial metrics and their categories:

sql
SELECT DISTINCT metric_name, metric_category
FROM dim_metric
ORDER BY metric_category, metric_name;
Find the quarter with the highest passenger traffic across all Sri Lankan airports:

sql
 Show full code block 
SELECT d.year, d.quarter, SUM(f.passengers) AS quarterly_passengers
FROM fact_passenger_movements f
JOIN dim_date d ON f.date_key = d.date_key
GROUP BY d.year, d.quarter
ORDER BY quarterly_passengers DESC
LIMIT 1;
List all aircraft models in the fleet with their seat capacity:

sql
SELECT manufacturer, aircraft_model, seat_capacity
FROM dim_aircraft
ORDER BY manufacturer, seat_capacity DESC;
Show all financial data recorded in USD:

sql
 Show full code block 
SELECT d.year, m.metric_name, f.value, f.currency
FROM fact_airline_financials f
JOIN dim_date d ON f.date_key = d.date_key
JOIN dim_metric m ON f.metric_key = m.metric_key
WHERE f.currency = 'USD'
ORDER BY d.year, m.metric_name;
Get the total number of passengers for each country in the World Bank data:

sql
SELECT c.country_name, SUM(f.passengers) AS total_passengers_all_time
FROM fact_world_transport_stats f
JOIN dim_country c ON f.country_key = c.country_key
GROUP BY c.country_name
ORDER BY total_passengers_all_time DESC;
Find the first and last date of recorded passenger movements:

sql
SELECT MIN(d.full_date) AS first_record, MAX(d.full_date) AS last_record
FROM fact_passenger_movements f
JOIN dim_date d ON f.date_key = d.date_key;
Count the number of unique countries in the World Bank dataset:


SELECT COUNT(DISTINCT country_name) AS number_of_countries FROM dim_country;



Show the trend of the number of employees at SriLankan Airlines:


 Show full code block 
SELECT d.year, f.value AS employee_count
FROM fact_airline_financials f
JOIN dim_metric m ON f.metric_key = m.metric_key
JOIN dim_date d ON f.date_key = d.date_key
WHERE m.metric_name = 'Employee Count'
ORDER BY d.year;



Calculate the percentage of total Sri Lankan passengers that passed through Colombo (CMB) each year:


WITH yearly_totals AS (
    SELECT d.year,
        SUM(f.passengers) AS total_passengers,
        SUM(CASE WHEN a.iata_code = 'CMB' THEN f.passengers ELSE 0 END) AS cmb_passengers
    FROM fact_passenger_movements f
    JOIN dim_date d ON f.date_key = d.date_key
    JOIN dim_airport a ON f.airport_key = a.airport_key
    GROUP BY d.year
)
SELECT year, total_passengers, cmb_passengers,
       ROUND((cmb_passengers / total_passengers) * 100, 2) AS cmb_percentage
FROM yearly_totals
WHERE total_passengers > 0
ORDER BY year;
