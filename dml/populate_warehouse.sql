/* Make sure you are using your database */
USE Airlines;

/*
-- 1. POPULATE dim_date --
This query finds all dates from your staging tables, converts them to
a full date row, and inserts them.
*/
INSERT IGNORE INTO dim_date (date_key, full_date, year, quarter, month, month_name, day, day_of_week, is_weekend)
-- Get specific dates from CAA data
SELECT 
    date_key,
    STR_TO_DATE(date_key, '%Y%m%d') AS full_date,
    YEAR(STR_TO_DATE(date_key, '%Y%m%d')) AS year,
    QUARTER(STR_TO_DATE(date_key, '%Y%m%d')) AS quarter,
    MONTH(STR_TO_DATE(date_key, '%Y%m%d')) AS month,
    DATE_FORMAT(STR_TO_DATE(date_key, '%Y%m%d'), '%M') AS month_name,
    DAY(STR_TO_DATE(date_key, '%Y%m%d')) AS day,
    DAYOFWEEK(STR_TO_DATE(date_key, '%Y%m%d')) AS day_of_week,
    IF(DAYOFWEEK(STR_TO_DATE(date_key, '%Y%m%d')) IN (1, 7), 1, 0) AS is_weekend
FROM stg_caa_movements
WHERE date_key IS NOT NULL
UNION
-- Get Jan 1st for all years from Financial data
SELECT
    year * 10000 + 101 AS date_key,
    STR_TO_DATE(CONCAT(year, '-01-01'), '%Y-%m-%d') AS full_date,
    year, 1, 1, 'January', 1,
    DAYOFWEEK(STR_TO_DATE(CONCAT(year, '-01-01'), '%Y-%m-%d')) AS day_of_week,
    IF(DAYOFWEEK(STR_TO_DATE(CONCAT(year, '-01-01'), '%Y-%m-%d')) IN (1, 7), 1, 0) AS is_weekend
FROM stg_srilankan_financials
WHERE year IS NOT NULL
UNION
-- Get Jan 1st for all years from World Bank data
SELECT
    year * 10000 + 101 AS date_key,
    STR_TO_DATE(CONCAT(year, '-01-01'), '%Y-%m-%d') AS full_date,
    year, 1, 1, 'January', 1,
    DAYOFWEEK(STR_TO_DATE(CONCAT(year, '-01-01'), '%Y-%m-%d')) AS day_of_week,
    IF(DAYOFWEEK(STR_TO_DATE(CONCAT(year, '-01-01'), '%Y-%m-%d')) IN (1, 7), 1, 0) AS is_weekend
FROM stg_worldbank_transport
WHERE year IS NOT NULL;


/*
-- 2. POPULATE dim_airport --
Finds all unique airports from the CAA staging table.
*/
INSERT IGNORE INTO dim_airport (iata_code, country)
SELECT DISTINCT 
    airport_iata, 
    country
FROM stg_caa_movements
WHERE airport_iata IS NOT NULL AND airport_iata != '';


/*
-- 3. POPULATE dim_country --
Finds all unique countries from the World Bank staging table.
*/
INSERT IGNORE INTO dim_country (country_code, country_name)
SELECT DISTINCT 
    country_code, 
    country_name
FROM stg_worldbank_transport
WHERE country_code IS NOT NULL AND country_code != '';


/*
-- 4. POPULATE dim_metric --
Finds all unique metrics from the financial staging table.
*/
INSERT IGNORE INTO dim_metric (metric_name, metric_category)
SELECT DISTINCT 
    metric,
    CASE 
        WHEN metric IN ('Revenue', 'Operating Loss', 'Cargo Revenue') THEN 'Financial'
        WHEN metric IN ('Passengers', 'Aircraft Fleet', 'Employee Count', 'Passenger Load Factor') THEN 'Operational'
        ELSE 'Other'
    END AS metric_category
FROM stg_srilankan_financials
WHERE metric IS NOT NULL AND metric != '';


/*
-- 5. POPULATE fact_passenger_movements --
This query joins the staging table with the new dimension tables
to get the correct keys, and then inserts the numeric data.
*/
TRUNCATE TABLE fact_passenger_movements; -- Clear old data first
INSERT INTO fact_passenger_movements (date_key, airport_key, passengers, aircraft_movements)
SELECT
    s.date_key,
    a.airport_key,
    s.passengers,
    s.aircraft_movements
FROM stg_caa_movements s
-- Join to get the airport_key
LEFT JOIN dim_airport a ON s.airport_iata = a.iata_code
WHERE s.date_key IS NOT NULL;


/*
-- 6. POPULATE fact_airline_financials --
*/
TRUNCATE TABLE fact_airline_financials; -- Clear old data first
INSERT INTO fact_airline_financials (date_key, metric_key, value, currency)
SELECT
    s.year * 10000 + 101 AS date_key, -- Use YYYY0101 as the date_key
    m.metric_key,
    s.value,
    s.currency
FROM stg_srilankan_financials s
-- Join to get the metric_key
LEFT JOIN dim_metric m ON s.metric = m.metric_name
WHERE s.year IS NOT NULL;


/*
-- 7. POPULATE fact_world_transport_stats --
*/
TRUNCATE TABLE fact_world_transport_stats; -- Clear old data first
INSERT INTO fact_world_transport_stats (date_key, country_key, passengers)
SELECT
    s.year * 10000 + 101 AS date_key, -- Use YYYY0101 as the date_key
    c.country_key,
    s.passengers
FROM stg_worldbank_transport s
-- Join to get the country_key
LEFT JOIN dim_country c ON s.country_code = c.country_code
WHERE s.year IS NOT NULL;