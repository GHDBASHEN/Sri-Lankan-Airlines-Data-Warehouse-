1. Total Passenger Movements by Airport
Business Question: "What is the total number of passengers and aircraft movements recorded by the CAA for each airport?"


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