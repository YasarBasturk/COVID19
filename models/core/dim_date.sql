{{ config(materialized='table') }}

with dates as (
  {{ dbt_utils.date_spine(
      datepart='day',
      start_date="cast('2020-01-01' as date)",
      end_date="current_date"
  ) }}
)
select
  cast(date_day as date) as date,
  cast(to_char(date_day, 'YYYYMMDD') as int) as date_key,
  extract(year from date_day) as year,
  extract(quarter from date_day) as quarter,
  extract(month from date_day) as month,
  extract(day from date_day) as day_of_month,
  extract(isodow from date_day) as day_of_week,
  extract(week from date_day) as iso_week
from dates
