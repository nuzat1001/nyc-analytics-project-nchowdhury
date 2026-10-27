WITH source AS (
    SELECT * FROM {{ source('raw', 'source_nyc_dob_job_apps') }}
)
SELECT 
    *,
    CURRENT_TIMESTAMP() AS _stg_loaded_at
FROM source