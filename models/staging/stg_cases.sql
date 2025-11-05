{{ config(materialized='view') }}

with raw_data as (
  select * from {{ ref('owid_covid_data') }}
  where iso_code in ('DNK', 'SWE', 'NOR', 'FIN')
),
transformed as (
  select
    cast(date as date) as report_date,
    case 
      when iso_code = 'DNK' then 'DK'
      when iso_code = 'SWE' then 'SE'
      when iso_code = 'NOR' then 'NO'
      when iso_code = 'FIN' then 'FI'
    end as iso_code,
    cast(new_cases as numeric) as new_cases,
    cast(total_cases as numeric) as total_cases
  from raw_data
)
select * from transformed
