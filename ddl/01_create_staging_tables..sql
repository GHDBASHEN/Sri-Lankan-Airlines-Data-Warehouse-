/* Make sure you are using your database */
USE Airlines;

/* Table for cleaned CAA passenger movements */
-- Data from the Civil Aviation Authority on passenger and aircraft traffic.
CREATE TABLE IF NOT EXISTS stg_caa_movements (
    movement_id INT AUTO_INCREMENT PRIMARY KEY,
    date_key INT,
    airport_iata VARCHAR(10),
    passengers BIGINT,
    aircraft_movements INT,
    country VARCHAR(100),
    load_timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    KEY idx_date_key (date_key)
);

/* Table for cleaned SriLankan Airlines financial report data */
CREATE TABLE IF NOT EXISTS stg_srilankan_financials (
    financial_id INT AUTO_INCREMENT PRIMARY KEY,
    year INT,
    metric VARCHAR(255),
    value DECIMAL(20, 2),
    currency VARCHAR(10),
    notes TEXT,
    load_timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    KEY idx_year_metric (year, metric)
);

/* Table for cleaned World Bank air transport data */
CREATE TABLE IF NOT EXISTS stg_worldbank_transport (
    transport_id INT AUTO_INCREMENT PRIMARY KEY,
    year INT,
    country_name VARCHAR(255),
    country_code VARCHAR(10),
    passengers BIGINT,
    load_timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    KEY idx_year_country (year, country_code)
);

-- Staging table for aircraft details from the JSON file
CREATE TABLE `stg_aircraft_details` (
  `aircraft_model` varchar(100) DEFAULT NULL,
  `manufacturer` varchar(100) DEFAULT NULL,
  `seat_capacity` int DEFAULT NULL,
  `engine_type` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Staging table for flight routes from the legacy database
CREATE TABLE `stg_flight_routes` (
  `route_id` varchar(20) DEFAULT NULL,
  `origin_iata` varchar(10) DEFAULT NULL,
  `destination_iata` varchar(10) DEFAULT NULL,
  `distance_km` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

