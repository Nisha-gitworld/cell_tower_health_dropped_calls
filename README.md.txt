README.md

# Cell Tower Health & Dropped Calls

## Project Overview

This project analyzes cell tower health and dropped calls using a data engineering pipeline built with Databricks and Snowflake.

The project implements a Bronze → Silver → Gold architecture to ingest raw call data, clean and validate it, generate tower-level hourly health metrics, and load the final Gold dataset into Snowflake for analysis.

## Technologies Used

- Databricks
- PySpark
- Delta Lake
- Snowflake
- SQL
- GitHub

## Architecture

```text
Raw Data
   |
   v
Bronze Layer
   |
   | Cleaning & Validation
   v
Silver Layer
   |
   | Aggregation & Health Metrics
   v
Gold Layer
   |
   v
CSV Export
   |
   v
Snowflake
   |
   v
Business Analysis

Bronze Layer

The Bronze layer stores the raw tower and call data with the original values preserved.

The Bronze tables include the following ingestion metadata:

_source_file
_ingested_at
_row_hash

The raw data was loaded without applying business transformations.

Bronze tables:

bronze_towers
bronze_calls
Silver Layer

The Silver layer cleans and validates the Bronze data.

The pipeline performs the following operations:

Converts duration_seconds to an integer using safe casting
Converts start_ts to a timestamp
Removes duplicate call_id records
Rejects unknown tower IDs
Rejects non-numeric duration values
Rejects durations outside the valid range of 0–7200 seconds
Cleans the end_cause field using trim and uppercase
Identifies dropped calls
Derives end_ts

Silver tables:

silver_calls
silver_rejects
Silver Results

The pipeline produced:

372,150 valid Silver call records
2,250 rejected records

Rejected records:

1,200 non-numeric duration records
450 out-of-range duration records
600 unknown tower records
Gold Layer

The Gold layer produces one row per tower, date, and hour.

The Gold dataset contains:

tower_id
site_name
city
district
capacity_channels
call_date
hour_of_day
calls
dropped_calls
avg_duration_seconds
drop_rate
peak_concurrent
utilisation
Gold Results

The completed Gold dataset contains:

43,142 rows
372,150 total calls
6,792 dropped calls
120 cell towers
Business Analysis

The Gold dataset was used to answer three business questions.

1. Worst Hour by Tower

The drop rate was calculated for each tower and hour, and the hour with the highest drop rate was identified for each tower.

2. Towers Exceeding 5% Daily Drop Rate

Daily drop rates were calculated for each tower.

The analysis identified 40 towers (T081–T120) that exceeded a 5% drop rate on more than 10 of the 15 days.

3. Drop Rate and Peak Concurrent Calls

Drop rates were aggregated by peak concurrent calls.

The results were:

Peak Concurrent Calls	Calls	Dropped Calls	Drop Rate
1	85,949	3,752	4.365%
2	114,370	640	0.560%
4	171,831	2,400	1.397%

These results were used to examine the relationship between concurrent calls and dropped-call rates.

Snowflake

The Gold dataset was exported to CSV and uploaded to a Snowflake stage.

The final Snowflake table is:

GOLD_TOWER_HOUR

The Snowflake validation confirmed:

43,142 rows
372,150 total calls
6,792 total dropped calls
0 errors during the successful load

COPY INTO was executed a second time to verify that the stage did not reload the same file.

Databricks Job

The Databricks notebook was configured as a scheduled job.

Task: cell_tower_health
Compute: Serverless
Schedule: Daily
Job status: Successful

The job was successfully executed and all notebook tasks completed successfully.

Project Files
cell-tower-health-dropped-calls/
│
├── cell_Tower.ipynb
├── gold_tower_hour.csv
├── snowflake_queries.sql
└── README.md
Project Deliverables

This project includes:

Databricks data pipeline
Bronze, Silver, and Gold data layers
Gold CSV export
Snowflake staging and loading
Snowflake business analysis queries
Scheduled Databricks Job
Project documentation
Author

Nisha


