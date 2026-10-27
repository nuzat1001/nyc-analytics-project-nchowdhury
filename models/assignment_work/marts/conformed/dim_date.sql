-- Date dimension shared by DOT 311 service requests and DOB NOW job filings

-- Build initial CTEs for Jinja syntax to make refs to staging models easier
WITH stg_311 AS (
    SELECT * FROM {{ ref('stg_nyc_311_dot') }}
),

stg_dob AS (
    SELECT * FROM {{ ref('stg_nyc_dob_job_filings') }}
),

-- Then union dates from the staging data together, collecting all poss dates
all_dates AS (
    -- 311 service requests dates
    SELECT DISTINCT CAST(created_date AS DATE) AS full_date
    FROM stg_311
    WHERE created_date IS NOT NULL

    UNION DISTINCT

    SELECT DISTINCT CAST(closed_date AS DATE) AS full_date
    FROM stg_311
    WHERE closed_date IS NOT NULL

    UNION DISTINCT

    -- DOB job filings dates (Using SAFE_CAST to prevent errors with messy timestamps)
    SELECT DISTINCT SAFE_CAST(SUBSTR(CAST(filing_date AS STRING), 1, 10) AS DATE) AS full_date
    FROM stg_dob
    WHERE filing_date IS NOT NULL

    UNION DISTINCT

    SELECT DISTINCT SAFE_CAST(SUBSTR(CAST(current_status_date AS STRING), 1, 10) AS DATE) AS full_date
    FROM stg_dob
    WHERE current_status_date IS NOT NULL

    UNION DISTINCT

    SELECT DISTINCT SAFE_CAST(SUBSTR(CAST(first_permit_date AS STRING), 1, 10) AS DATE) AS full_date
    FROM stg_dob
    WHERE first_permit_date IS NOT NULL

    UNION DISTINCT

    SELECT DISTINCT SAFE_CAST(SUBSTR(CAST(approved_date AS STRING), 1, 10) AS DATE) AS full_date
    FROM stg_dob
    WHERE approved_date IS NOT NULL

    UNION DISTINCT

    SELECT DISTINCT SAFE_CAST(SUBSTR(CAST(signoff_date AS STRING), 1, 10) AS DATE) AS full_date
    FROM stg_dob
    WHERE signoff_date IS NOT NULL
),

-- Date dimension with NYC fiscal year, Jul 1 - Jun 30, diff from federal
date_dimension AS (

    SELECT
        TO_HEX(MD5(CAST(full_date AS STRING))) AS date_key,

        full_date,
        EXTRACT(YEAR FROM full_date) AS year,
        EXTRACT(QUARTER FROM full_date) AS quarter,
        EXTRACT(MONTH FROM full_date) AS month,
        FORMAT_DATE('%B', full_date) AS month_name,
        EXTRACT(DAY FROM full_date) AS day_of_month,
        EXTRACT(DAYOFWEEK FROM full_date) AS day_of_week,
        FORMAT_DATE('%A', full_date) AS weekday_name,
        EXTRACT(DAYOFWEEK FROM full_date) IN (1, 7) AS is_weekend,

        CASE
            WHEN EXTRACT(MONTH FROM full_date) >= 7 THEN EXTRACT(YEAR FROM full_date) + 1
            ELSE EXTRACT(YEAR FROM full_date)
        END AS fiscal_year

    FROM all_dates

),

-- Null placeholder row: to handle NULL values.
-- Building fact tables should COALESCE a null source date to this key
-- Keeps all fact and date_dim joins INNER JOINs safely
-- Kimball convention to be explicit. (More to come on this)

null_placeholder AS (

    SELECT
        '-1' AS date_key,
        CAST(NULL AS DATE) AS full_date,
        CAST(NULL AS INT64) AS year,
        CAST(NULL AS INT64) AS quarter,
        CAST(NULL AS INT64) AS month,
        CAST(NULL AS STRING) AS month_name,
        CAST(NULL AS INT64) AS day_of_month,
        CAST(NULL AS INT64) AS day_of_week,
        CAST(NULL AS STRING) AS weekday_name,
        CAST(NULL AS BOOLEAN) AS is_weekend,
        CAST(NULL AS INT64) AS fiscal_year 
) 
-- make sure BQ knows the col types


SELECT * FROM date_dimension

UNION ALL

SELECT * FROM null_placeholder
