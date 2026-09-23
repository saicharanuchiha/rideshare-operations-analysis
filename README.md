# 🚖 Ride-Share Platform Operations & Friction Analysis

An end-to-end data operations project analyzing dispatch efficiency, supply bottlenecks, and revenue leakage for an urban ride-sharing platform across 15,000 trip requests.

---

## 📌 Executive Summary

* **Gross Platform Bookings:** $3.83M across 11,451 fulfilled trips.
* **Dispatch Fulfillment Rate:** 76.3% baseline platform efficiency.
* **Platform Net Take-Rate:** 23.0% net revenue capture.
* **Friction Opportunity Loss:** ~$1.0M in gross booking revenue lost to cancellations and unfulfilled demand.
* **Primary Friction Driver:** Rider cancellations represent **51.8%** of all dropped rides, driven by peak-hour ETA spikes.

---

## 📊 Dashboard Architecture

### Page 1: Executive Operations Overview
Monitors core commercial KPIs, hourly fulfillment dynamics, and revenue concentration across geographic operating zones.

![Executive Overview](docs/executive_overview.png)

* **Hourly Dispatch Curve:** Tracks request volume against fulfillment percentage from 00:00 to 23:00 to expose driver deficits.
* **Zone Economics:** Ranks municipal sectors by gross revenue generation to optimize driver positioning.

---

### Page 2: Friction & Supply Deep-Dive
Isolates dispatch breakdown root causes, fleet distribution, and lost platform revenue.

![Friction & Supply](docs/friction_and_supply.png)

* **Friction Breakdown:** Categorizes dropped demand into Rider Cancelled (51.8%), Driver Cancelled (30.6%), and Unfulfilled Shortages (17.5%).
* **Fleet Utilization:** Analyzes volume distribution across vehicle segments (Hatchback, Sedan, Premium Sedan, SUV).

---

## 🏗️ Data Architecture & Star Schema

The pipeline uses a Kimball-style dimensional star schema:

* **`fact_trips`**: Granular ride-level transactional records (`trip_id`, `request_timestamp`, `base_fare`, `surge_multiplier`, `total_fare`, `driver_payout`, `trip_status`).
* **`dim_zones`**: Geographic operational sectors (`zone_id`, `zone_name`, `area_type`).
* **`dim_drivers`**: Driver supply entity data (`driver_id`, `vehicle_type`, `rating`, `active_status`).

---

## 💻 Tech Stack & Key Files

* **Data Engineering & Simulation:** Python (`pandas`, `numpy`) via `generate_data.py`
* **Data Modeling & DAX:** Microsoft Power BI (`rideshare_operations_dashboard.pbix`)
* **Project Documentation & Assets:** Markdown & Visuals (`docs/`)