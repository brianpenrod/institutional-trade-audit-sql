# institutional-trade-audit-sql
"Enterprise-grade analytics pipeline migrating trade performance tracking from Excel to Google BigQuery. Features algorithmic execution auditing (VWAP, Stochastics), automated risk detection, and Power BI dashboarding"
# Institutional Trade Audit Pipeline & Risk Dashboard

## 1. Executive Summary
This project establishes a scalable, cloud-based data auditing framework for a proprietary trading portfolio (BP Capital). By migrating performance tracking from manual Excel logs to a **Google BigQuery** data warehouse, I engineered an automated pipeline to assess execution quality against institutional benchmarks (VWAP) and visualize risk regimes in real-time.

**Project Status:** [Production / Live]

## 2. The Business Problem
Manual trade logging in spreadsheets created latency in performance reporting and made it impossible to audit "Execution Quality" effectively.
* **Latency:** Performance metrics were lagging by days.
* **Blind Spots:** No ability to detect if entries were deviating from volume-weighted averages (VWAP).
* **Risk Control:** No automated mechanism to flag "Over-trading" or "Poor Performance" streaks in real-time.

## 3. The Solution
I architected a modern data stack that automates the entire lifecycle of trade analytics:

### Phase 1: Data Engineering (Google BigQuery)
* **Ingestion:** Pipeline to ingest raw execution logs from futures platforms.
* **Normalization:** Cleaning and structuring time-series data using Standard SQL.
* **Feature Engineering:** Algorithmic construction of advanced indicators (VWAP, Stochastic Oscillators) directly within the warehouse.

### Phase 2: Visualization (Looker Studio)
* **Executive Dashboard:** Connected BigQuery to Looker Studio to create a "Command Center" view.
* **Risk Flags:** Visual alerts for "Critical" vs. "High Performance" trading regimes.

## 4. Technical Architecture
* **Database:** Google BigQuery (Serverless Data Warehouse)
* **Language:** Standard SQL (Window Functions, CTEs, Aggregations)
* **Visualization:** Google Looker Studio
* **Validation:** Python (Pandas) for data integrity checks

## 5. Key SQL Logic Demonstrated
This project leverages enterprise analytical functions to reconstruct financial indicators:

### A. Volume Weighted Average Price (VWAP)
*Objective: Audit execution price efficiency against the institutional average.*
```sql
SUM(price * quantity) OVER (PARTITION BY ticker ORDER BY execution_time) / 
SUM(quantity) OVER (PARTITION BY ticker ORDER BY execution_time)
