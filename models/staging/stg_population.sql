{{ config(materialized='view') }}

with raw_data as (
  select * from {{ ref('owid_covid_data') }}
  where iso_code in ('DNK', 'SWE', 'NOR', 'FIN')
),
unique_locations as (
  select
    iso_code,
    location,
    continent,
    population,
    row_number() over (partition by iso_code order by date desc) as rn
  from raw_data
  where population is not null
),
transformed as (
  select
    case 
      when iso_code = 'DNK' then 'DK'
      when iso_code = 'SWE' then 'SE'
      when iso_code = 'NOR' then 'NO'
      when iso_code = 'FIN' then 'FI'
    end as iso_code,
    initcap(location) as location,
    initcap(continent) as continent,
    cast(population as numeric) as population
  from unique_locations
  where rn = 1
)
select * from transformed
