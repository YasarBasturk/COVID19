{{ config(materialized='table') }}

with by_day as (
  select
    coalesce(c.report_date, v.report_date) as report_date,
    coalesce(c.iso_code, v.iso_code) as iso_code,
    c.new_cases,
    c.total_cases,
    v.new_vaccinations,
    v.people_vaccinated,
    v.people_fully_vaccinated
  from {{ ref('stg_cases') }} c
  full outer join {{ ref('stg_vaccinations') }} v
    on c.report_date = v.report_date
   and c.iso_code = v.iso_code
),
joined as (
  select
    d.date_key,
    l.location_key,
    b.new_cases,
    b.total_cases,
    b.new_vaccinations,
    b.people_vaccinated,
    b.people_fully_vaccinated
  from by_day b
  join {{ ref('dim_date') }} d on d.date = b.report_date
  join {{ ref('dim_location') }} l on l.iso_code = b.iso_code
)
select
  {{ dbt_utils.generate_surrogate_key(['date_key','location_key']) }} as fact_key,
  date_key,
  location_key,
  new_cases,
  total_cases,
  new_vaccinations,
  people_vaccinated,
  people_fully_vaccinated
from joined
