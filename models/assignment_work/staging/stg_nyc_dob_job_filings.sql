-- Clean and standardize DOB Job Filings data
WITH source AS (
    SELECT * FROM {{ source('raw', 'source_nyc_dob_job_apps') }}
),

cleaned AS (
    SELECT 
        -- 1. EXCLUDE the original columns you are renaming or casting
        * EXCEPT (
            job_filing_number, 
            house__street_name, 
            zip, 
            borough 
        ),
        
        -- 2. CAST and RENAME to match the 311 staging table
        CAST(job_filing_number AS STRING) AS job_number, 
        
        -- Example: Ensure zip is a string and just call it 'zip'
        CAST(zip AS STRING) AS zip, 
        
        -- Example: Ensure borough is a string and just call it 'borough'
        CAST(borough AS STRING) AS borough,
        
        CURRENT_TIMESTAMP() AS _stg_loaded_at

    FROM source
    -- 3. Add a simple filter to ensure the data is valid
    WHERE job_filing_number IS NOT NULL
)

SELECT * FROM cleaned