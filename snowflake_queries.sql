-- ============================================================
-- Cell Tower Health & Dropped Calls
-- Snowflake Analysis Queries
-- ============================================================


-- ============================================================
-- 1. Validate Gold table row count
-- ============================================================

SELECT COUNT(*) AS TOTAL_ROWS
FROM GOLD_TOWER_HOUR;


-- ============================================================
-- 2. Validate total calls and dropped calls
-- ============================================================

SELECT
    SUM(CALLS) AS TOTAL_CALLS,
    SUM(DROPPED_CALLS) AS TOTAL_DROPPED_CALLS
FROM GOLD_TOWER_HOUR;


-- ============================================================
-- 3. Q1: Worst drop-rate hour for each tower
-- ============================================================

WITH TOWER_HOUR AS (
    SELECT
        TOWER_ID,
        HOUR_OF_DAY,
        SUM(CALLS) AS CALLS,
        SUM(DROPPED_CALLS) AS DROPS,
        SUM(DROPPED_CALLS) / NULLIF(SUM(CALLS), 0) AS DROP_RATE
    FROM GOLD_TOWER_HOUR
    GROUP BY
        TOWER_ID,
        HOUR_OF_DAY
),

WORST_HOUR AS (
    SELECT
        TOWER_ID,
        HOUR_OF_DAY,
        DROP_RATE,
        SUM(DROPS) OVER (PARTITION BY TOWER_ID)
            / NULLIF(SUM(CALLS) OVER (PARTITION BY TOWER_ID), 0)
            AS TOWER_DROP_RATE,

        ROW_NUMBER() OVER (
            PARTITION BY TOWER_ID
            ORDER BY DROP_RATE DESC, HOUR_OF_DAY
        ) AS RN

    FROM TOWER_HOUR
)

SELECT
    TOWER_ID,
    HOUR_OF_DAY,
    DROP_RATE,
    TOWER_DROP_RATE
FROM WORST_HOUR
WHERE RN = 1
ORDER BY TOWER_ID;


-- ============================================================
-- 4. Q2: Towers exceeding 5% daily drop rate
--    on more than 10 of the 15 days
-- ============================================================

WITH DAILY_RATES AS (
    SELECT
        TOWER_ID,
        CALL_DATE,
        SUM(CALLS) AS CALLS,
        SUM(DROPPED_CALLS) AS DROPS,
        SUM(DROPPED_CALLS) / NULLIF(SUM(CALLS), 0)
            AS DROP_RATE
    FROM GOLD_TOWER_HOUR
    GROUP BY
        TOWER_ID,
        CALL_DATE
)

SELECT
    TOWER_ID,
    SUM(
        CASE
            WHEN DROP_RATE > 0.05 THEN 1
            ELSE 0
        END
    ) AS DAYS_OVER_5_PCT
FROM DAILY_RATES
GROUP BY TOWER_ID
HAVING DAYS_OVER_5_PCT > 10
ORDER BY TOWER_ID;


-- ============================================================
-- 5. Q3: Drop rate by peak concurrent calls
-- ============================================================

SELECT
    PEAK_CONCURRENT,
    SUM(CALLS) AS CALLS,
    SUM(DROPPED_CALLS) AS DROPS,
    SUM(DROPPED_CALLS) / NULLIF(SUM(CALLS), 0)
        AS DROP_RATE
FROM GOLD_TOWER_HOUR
GROUP BY PEAK_CONCURRENT
ORDER BY PEAK_CONCURRENT;


-- ============================================================
-- 6. Verify the Snowflake stage
-- ============================================================

LIST @GOLD_TOWER_STAGE;


-- ============================================================
-- 7. COPY INTO - initial load
-- ============================================================
-- Note: The final successful load used the explicit
-- column mapping/casts in Snowflake because the initial
-- automatic load produced a schema mapping issue.
--
-- Keep the exact successful COPY INTO statement you used
-- in Snowflake here if you want the submission to reproduce
-- the load.