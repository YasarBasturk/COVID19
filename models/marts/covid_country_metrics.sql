{{ config(materialized='table') }}

select
  l.location,
  d.year,
  d.iso_week,
  sum(coalesce(f.new_cases,0)) as weekly_cases,
  sum(coalesce(f.new_vaccinations,0)) as weekly_vaccinations,
  max(f.people_vaccinated) as people_vaccinated_to_date,
  max(f.people_fully_vaccinated) as people_fully_vaccinated_to_date,
  max(l.population) as population,
  round(100.0 * max(f.people_fully_vaccinated) / nullif(max(l.population),0), 2) as fully_vaccinated_pct
from {{ ref('fct_covid_daily') }} f
join {{ ref('dim_date') }} d using (date_key)
join {{ ref('dim_location') }} l using (location_key)
group by l.location, d.year, d.iso_week
