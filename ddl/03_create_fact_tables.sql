/* Make sure you are using your database */
USE Airlines;

/*
-- FACT 1: Passenger Movements --
Stores data from the CAA file.
*/
CREATE TABLE IF NOT EXISTS fact_passenger_movements (
    movement_id INT AUTO_INCREMENT PRIMARY KEY,
    
    -- Foreign Keys to Dimensions
    date_key INT NOT NULL,
    airport_key INT,
    
    -- Measures (the numbers)
    passengers BIGINT,
    aircraft_movements INT,
    
    -- Foreign Key Constraints
    FOREIGN KEY (date_key) REFERENCES dim_date(date_key),
    FOREIGN KEY (airport_key) REFERENCES dim_airport(airport_key)
);


/*
-- FACT 2: Airline Financials --
Stores data from the SriLankan Annual Report file.
*/
CREATE TABLE IF NOT EXISTS fact_airline_financials (
    financial_id INT AUTO_INCREMENT PRIMARY KEY,
    
    -- Foreign Keys to Dimensions
    date_key INT NOT NULL,       -- We will use YYYY0101
    metric_key INT NOT NULL,
    
    -- Measures (the numbers)
    value DECIMAL(20, 2),
    currency VARCHAR(10),
    
    -- Foreign Key Constraints
    FOREIGN KEY (date_key) REFERENCES dim_date(date_key),
    FOREIGN KEY (metric_key) REFERENCES dim_metric(metric_key)
);


/*
-- FACT 3: World Transport Stats --
Stores data from the World Bank file.
*/
CREATE TABLE IF NOT EXISTS fact_world_transport_stats (
    stat_id INT AUTO_INCREMENT PRIMARY KEY,
    
    -- Foreign Keys to Dimensions
    date_key INT NOT NULL,      -- We will use YYYY0101
    country_key INT NOT NULL,
    
    -- Measures (the numbers)
    passengers BIGINT,
    
    -- Foreign Key Constraints
    FOREIGN KEY (date_key) REFERENCES dim_date(date_key),
    FOREIGN KEY (country_key) REFERENCES dim_country(country_key)
);