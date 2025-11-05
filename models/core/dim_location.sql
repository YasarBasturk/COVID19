{{ config(materialized='table') }}

select
  {{ dbt_utils.generate_surrogate_key(['p.iso_code']) }} as location_key,
  p.iso_code,
  p.location,
  p.continent,
  p.population
from {{ ref('stg_population') }} p
