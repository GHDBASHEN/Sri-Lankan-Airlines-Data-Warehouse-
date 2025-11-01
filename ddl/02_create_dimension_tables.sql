/* Make sure you are using your database */
USE Airlines;

/*
-- DIMENSION 1: Date --
This table will hold all dates, so you can group facts by
year, month, quarter, etc.
*/
CREATE TABLE IF NOT EXISTS dim_date (
    date_key INT PRIMARY KEY,         -- YYYYMMDD format
    full_date DATE NOT NULL,
    year INT NOT NULL,
    quarter INT NOT NULL,             -- 1, 2, 3, 4
    month INT NOT NULL,               -- 1-12
    month_name VARCHAR(20) NOT NULL,    -- January, February...
    day INT NOT NULL,
    day_of_week INT NOT NULL,           -- 1=Monday, 7=Sunday
    is_weekend TINYINT(1) NOT NULL,   -- 1 for Sat/Sun, 0 otherwise
    UNIQUE KEY uk_full_date (full_date)
);

/*
-- DIMENSION 2: Airport --
This table will store unique airport information.
*/
CREATE TABLE IF NOT EXISTS dim_airport (
    airport_key INT AUTO_INCREMENT PRIMARY KEY,
    iata_code VARCHAR(10) NOT NULL,
    airport_name VARCHAR(255),        -- We can add this later
    city VARCHAR(100),                -- We can add this later
    country VARCHAR(100),
    UNIQUE KEY uk_iata_code (iata_code)
);

/*
-- DIMENSION 3: Country --
This table will store unique country information.
*/
CREATE TABLE IF NOT EXISTS dim_country (
    country_key INT AUTO_INCREMENT PRIMARY KEY,
    country_code VARCHAR(10),
    country_name VARCHAR(255),
    UNIQUE KEY uk_country_code (country_code),
    UNIQUE KEY uk_country_name (country_name)
);

/*
-- DIMENSION 4: Financial Metric --
This table will store the different types of financial metrics
(e.g., "Revenue", "Operating Loss").
*/
CREATE TABLE IF NOT EXISTS dim_metric (
    metric_key INT AUTO_INCREMENT PRIMARY KEY,
    metric_name VARCHAR(255) NOT NULL,
    metric_category VARCHAR(100),     -- e.g., 'Financial', 'Operational'
    UNIQUE KEY uk_metric_name (metric_name)
);

-- DIMENSION 5: Aircraft --

CREATE TABLE `dim_aircraft` (
  `aircraft_key` int NOT NULL AUTO_INCREMENT,
  `aircraft_model` varchar(100) NOT NULL,
  `manufacturer` varchar(100) DEFAULT NULL,
  `seat_capacity` int DEFAULT NULL,
  `engine_type` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`aircraft_key`),
  UNIQUE KEY `aircraft_model` (`aircraft_model`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;