-- =====================================================================
-- RIDE-SHARE PLATFORM OPERATIONS & LOGISTICS ANALYSIS
-- Author: Saicharan Uchiha
-- Stack: SQL (CTEs, Window Functions, Conditional Aggregations)
-- =====================================================================

CREATE DATABASE IF NOT EXISTS rideshare_db;
USE rideshare_db;

-- Drop existing tables to allow clean re-runs
DROP TABLE IF EXISTS fact_trips;
DROP TABLE IF EXISTS dim_drivers;
DROP TABLE IF EXISTS dim_zones;

-- Geographic Zones Dimension
CREATE TABLE dim_zones (
    zone_id INT PRIMARY KEY,
    zone_name VARCHAR(100) NOT NULL,
    area_type VARCHAR(50) NOT NULL
);

-- Driver Fleet Dimension
CREATE TABLE dim_drivers (
    driver_id VARCHAR(50) PRIMARY KEY,
    vehicle_type VARCHAR(50) NOT NULL,
    rating DECIMAL(3, 2),
    active_status VARCHAR(20) NOT NULL,
    onboarding_date VARCHAR(20)
);

-- Granular Trip Transactions Fact Table
CREATE TABLE fact_trips (
    trip_id VARCHAR(50) PRIMARY KEY,
    rider_id VARCHAR(50) NOT NULL,
    driver_id VARCHAR(50),
    pickup_zone_id INT NOT NULL,
    dropoff_zone_id INT NOT NULL,
    request_timestamp DATETIME NOT NULL,
    dropoff_timestamp DATETIME,
    trip_distance_km DECIMAL(6, 2),
    base_fare DECIMAL(8, 2),
    surge_multiplier DECIMAL(4, 2),
    total_fare DECIMAL(8, 2),
    driver_payout DECIMAL(8, 2),
    trip_status VARCHAR(50) NOT NULL
);

-- ---------------------------------------------------------------------
-- 1. Hourly Dispatch & Fulfillment Rate (Supply vs. Demand Bottlenecks)
-- Identifies peak fulfillment gaps during rush hours.
-- ---------------------------------------------------------------------
SELECT 
    HOUR(request_timestamp) AS request_hour,
    COUNT(trip_id) AS total_requests,
    SUM(CASE WHEN trip_status = 'Completed' THEN 1 ELSE 0 END) AS completed_trips,
    SUM(CASE WHEN trip_status = 'Rider Cancelled' THEN 1 ELSE 0 END) AS rider_cancelled,
    SUM(CASE WHEN trip_status = 'Driver Cancelled' THEN 1 ELSE 0 END) AS driver_cancelled,
    SUM(CASE WHEN trip_status = 'Unfulfilled' THEN 1 ELSE 0 END) AS unfulfilled_requests,
    ROUND(
        100.0 * SUM(CASE WHEN trip_status = 'Completed' THEN 1 ELSE 0 END) / COUNT(trip_id), 
        2
    ) AS fulfillment_rate_pct
FROM fact_trips
GROUP BY HOUR(request_timestamp)
ORDER BY request_hour;


-- ---------------------------------------------------------------------
-- 2. Zone-Level Platform Economics & Take-Rate
-- Evaluates gross bookings, driver payouts, and platform net revenue margin.
-- ---------------------------------------------------------------------
SELECT 
    z.zone_name,
    z.area_type,
    COUNT(t.trip_id) AS total_dispatched_trips,
    ROUND(SUM(t.total_fare), 2) AS gross_bookings,
    ROUND(SUM(t.driver_payout), 2) AS total_driver_payout,
    ROUND(SUM(t.total_fare - t.driver_payout), 2) AS net_platform_revenue,
    ROUND(
        100.0 * SUM(t.total_fare - t.driver_payout) / NULLIF(SUM(t.total_fare), 0), 
        2
    ) AS net_take_rate_pct
FROM fact_trips t
JOIN dim_zones z ON t.pickup_zone_id = z.zone_id
WHERE t.trip_status = 'Completed'
GROUP BY z.zone_name, z.area_type
ORDER BY net_platform_revenue DESC;


-- ---------------------------------------------------------------------
-- 3. Driver Performance Tiers & Relative Ranking (Window Functions)
-- Uses CTEs and DENSE_RANK to classify top operational drivers by revenue.
-- ---------------------------------------------------------------------
WITH driver_metrics AS (
    SELECT 
        d.driver_id,
        d.vehicle_type,
        d.rating,
        COUNT(t.trip_id) AS completed_rides,
        ROUND(SUM(t.driver_payout), 2) AS total_earnings,
        ROUND(AVG(t.trip_distance_km), 2) AS avg_trip_distance
    FROM dim_drivers d
    JOIN fact_trips t ON d.driver_id = t.driver_id
    WHERE t.trip_status = 'Completed'
    GROUP BY d.driver_id, d.vehicle_type, d.rating
)
SELECT 
    driver_id,
    vehicle_type,
    rating,
    completed_rides,
    total_earnings,
    avg_trip_distance,
    DENSE_RANK() OVER (ORDER BY total_earnings DESC) AS revenue_rank,
    NTILE(4) OVER (ORDER BY total_earnings DESC) AS performance_quartile
FROM driver_metrics
ORDER BY revenue_rank ASC
LIMIT 20;


-- ---------------------------------------------------------------------
-- 4. Lost Opportunity Cost (Revenue Lost to Friction)
-- Quantifies the monetary loss caused by cancellations and driver shortages.
-- ---------------------------------------------------------------------
SELECT 
    trip_status,
    COUNT(trip_id) AS incident_count,
    ROUND(SUM(base_fare * surge_multiplier), 2) AS estimated_gross_opportunity_loss,
    ROUND(SUM((base_fare * surge_multiplier) * 0.22), 2) AS estimated_net_revenue_loss
FROM fact_trips
WHERE trip_status != 'Completed'
GROUP BY trip_status
ORDER BY estimated_gross_opportunity_loss DESC;


-- ---------------------------------------------------------------------
-- 5. Surge Multiplier Price Elasticity
-- Analyzes whether higher surge multipliers degrade trip completion.
-- ---------------------------------------------------------------------
WITH surge_cohorts AS (
    SELECT 
        trip_id,
        trip_status,
        CASE 
            WHEN surge_multiplier = 1.0 THEN '1. Base (1.0x)'
            WHEN surge_multiplier < 1.5 THEN '2. Moderate (1.1x - 1.4x)'
            WHEN surge_multiplier < 2.0 THEN '3. High (1.5x - 1.9x)'
            ELSE '4. Critical (2.0x+)'
        END AS surge_bracket
    FROM fact_trips
)
SELECT 
    surge_bracket,
    COUNT(trip_id) AS total_requests,
    SUM(CASE WHEN trip_status = 'Completed' THEN 1 ELSE 0 END) AS completed_trips,
    SUM(CASE WHEN trip_status = 'Rider Cancelled' THEN 1 ELSE 0 END) AS rider_dropped,
    ROUND(
        100.0 * SUM(CASE WHEN trip_status = 'Completed' THEN 1 ELSE 0 END) / COUNT(trip_id), 
        2
    ) AS conversion_rate_pct
FROM surge_cohorts
GROUP BY surge_bracket
ORDER BY surge_bracket ASC;