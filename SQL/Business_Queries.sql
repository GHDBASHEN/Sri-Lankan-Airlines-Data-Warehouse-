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