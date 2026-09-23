import os
import random
from datetime import datetime, timedelta
import pandas as pd
import numpy as np

# Set random seed for reproducibility
np.random.seed(42)
random.seed(42)

# Ensure output directory exists
os.makedirs("data", exist_ok=True)

# -------------------------------------------------------------
# 1. DIM_ZONES
# -------------------------------------------------------------
zones_data = [
    {"zone_id": 1, "zone_name": "International Airport", "area_type": "Airport"},
    {"zone_id": 2, "zone_name": "Tech Hub & Financial District", "area_type": "Commercial"},
    {"zone_id": 3, "zone_name": "Downtown Central", "area_type": "Commercial"},
    {"zone_id": 4, "zone_name": "Midtown Retail & Dining", "area_type": "Commercial"},
    {"zone_id": 5, "zone_name": "North Suburbs", "area_type": "Residential"},
    {"zone_id": 6, "zone_name": "South Suburbs", "area_type": "Residential"},
    {"zone_id": 7, "zone_name": "East University District", "area_type": "Residential"},
    {"zone_id": 8, "zone_name": "West Lake Residences", "area_type": "Residential"},
]
df_zones = pd.DataFrame(zones_data)
df_zones.to_csv("data/dim_zones.csv", index=False)
print("Generated dim_zones.csv (8 zones)")

# -------------------------------------------------------------
# 2. DIM_DRIVERS
# -------------------------------------------------------------
num_drivers = 250
vehicle_types = ["Hatchback", "Sedan", "Premium Sedan", "SUV"]
vehicle_weights = [0.45, 0.35, 0.10, 0.10]

drivers = []
start_date = datetime(2025, 1, 1)

for d_id in range(101, 101 + num_drivers):
    v_type = random.choices(vehicle_types, weights=vehicle_weights)[0]
    rating = round(random.uniform(4.35, 4.98), 2)
    onboarding_days = random.randint(0, 450)
    onboard_dt = start_date + timedelta(days=onboarding_days)
    status = random.choices(["Active", "Churned", "Suspended"], weights=[0.85, 0.12, 0.03])[0]
    
    drivers.append({
        "driver_id": d_id,
        "vehicle_type": v_type,
        "rating": rating,
        "onboarding_date": onboard_dt.strftime("%Y-%m-%d"),
        "active_status": status
    })

df_drivers = pd.DataFrame(drivers)
df_drivers.to_csv("data/dim_drivers.csv", index=False)
print(f"Generated dim_drivers.csv ({num_drivers} drivers)")

# -------------------------------------------------------------
# 3. FACT_TRIPS
# -------------------------------------------------------------
num_trips = 15000
trip_start_window = datetime(2026, 6, 1, 0, 0, 0)
trip_end_window = datetime(2026, 8, 31, 23, 59, 59)
total_seconds = int((trip_end_window - trip_start_window).total_seconds())

active_driver_ids = df_drivers[df_drivers["active_status"] == "Active"]["driver_id"].tolist()
statuses = ["Completed", "Rider Cancelled", "Driver Cancelled", "Unfulfilled"]
status_weights = [0.76, 0.12, 0.08, 0.04]

trips = []

for trip_idx in range(1, num_trips + 1):
    # Skew timestamps toward peak hours (8-10 AM, 5-8 PM)
    offset = random.randint(0, total_seconds)
    req_time = trip_start_window + timedelta(seconds=offset)
    hour = req_time.hour
    
    # Peak traffic multipliers
    is_peak = (8 <= hour <= 10) or (17 <= hour <= 20)
    surge = round(random.uniform(1.2, 2.4), 2) if (is_peak and random.random() < 0.65) else 1.0

    zone_id = random.choices(
        [1, 2, 3, 4, 5, 6, 7, 8],
        weights=[0.18, 0.22, 0.20, 0.14, 0.08, 0.08, 0.05, 0.05]
    )[0]
    
    status = random.choices(statuses, weights=status_weights)[0]
    rider_id = random.randint(5000, 9999)
    distance_km = round(random.uniform(2.5, 32.0), 2)
    
    if status == "Unfulfilled":
        driver_id = None
        drop_time = None
        base_fare = round(distance_km * 14.5 + 40, 2)
        total_fare = 0.0
        driver_payout = 0.0
    elif status in ["Rider Cancelled", "Driver Cancelled"]:
        driver_id = random.choice(active_driver_ids)
        drop_time = None
        base_fare = round(distance_km * 14.5 + 40, 2)
        # Small cancellation fee applies only to rider cancellations 40% of the time
        total_fare = 50.0 if (status == "Rider Cancelled" and random.random() < 0.4) else 0.0
        driver_payout = total_fare * 0.70
    else:  # Completed
        driver_id = random.choice(active_driver_ids)
        duration_minutes = int(distance_km * random.uniform(2.1, 3.8))
        drop_time = req_time + timedelta(minutes=duration_minutes)
        base_fare = round(distance_km * 14.5 + 40, 2)
        total_fare = round(base_fare * surge, 2)
        # Dynamic take rate between 20% and 26%
        platform_take_rate = random.uniform(0.20, 0.26)
        driver_payout = round(total_fare * (1 - platform_take_rate), 2)

    trips.append({
        "trip_id": f"TRIP-{trip_idx:06d}",
        "driver_id": driver_id,
        "rider_id": rider_id,
        "pickup_zone_id": zone_id,
        "request_timestamp": req_time.strftime("%Y-%m-%d %H:%M:%S"),
        "dropoff_timestamp": drop_time.strftime("%Y-%m-%d %H:%M:%S") if drop_time else "",
        "trip_status": status,
        "trip_distance_km": distance_km,
        "base_fare": base_fare,
        "surge_multiplier": surge,
        "total_fare": total_fare,
        "driver_payout": driver_payout
    })

df_trips = pd.DataFrame(trips)
df_trips.to_csv("data/fact_trips.csv", index=False)
print(f"Generated fact_trips.csv ({num_trips} trips)")