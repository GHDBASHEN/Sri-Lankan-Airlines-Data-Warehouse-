-- 1. Create the database if it doesn’t exist
CREATE DATABASE IF NOT EXISTS legacydb;

-- 2. Use the database
USE legacydb;

-- 3. Create the table if it doesn’t exist
CREATE TABLE IF NOT EXISTS flight_routes (
    route_id VARCHAR(20),
    origin_iata VARCHAR(10),
    destination_iata VARCHAR(10),
    distance_km INT
);

-- 4. Insert data into the table
INSERT INTO flight_routes (route_id, origin_iata, destination_iata, distance_km) VALUES
('CMB-LHR', 'CMB', 'LHR', 8730),
('CMB-NRT', 'CMB', 'NRT', 6900),
('CMB-SIN', 'CMB', 'SIN', 2700),
('LHR-JFK', 'LHR', 'JFK', 5540);

-- 5. Verify data
SELECT * FROM flight_routes;
