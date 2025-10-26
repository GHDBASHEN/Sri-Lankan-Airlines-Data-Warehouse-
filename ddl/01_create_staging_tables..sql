/* Make sure you are using your database */
USE Airlines;

/* Table for cleaned CAA passenger movements */
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