# Data Model Documentation

## ER-Diagram Description

### Star Schema Structure

```
                    ┌─────────────┐
                    │  dim_date   │
                    │─────────────│
                    │ date_key (PK)│
                    │ date        │
                    │ year        │
                    │ iso_week    │
                    │ ...         │
                    └──────┬──────┘
                           │
                           │ 1:N
                           │
        ┌──────────────────┴──────────────────┐
        │                                      │
        │              ┌──────────────────────┐
        │              │  fct_covid_daily     │
        │              │──────────────────────│
        │              │ fact_key (PK)        │
        │              │ date_key (FK)        │
        │              │ location_key (FK)     │
        │              │ new_cases            │
        │              │ total_cases           │
        │              │ new_vaccinations     │
        │              │ people_vaccinated    │
        │              │ people_fully_...     │
        └──────────────┴──────────────────────┘
                       │
                       │ N:1
                       │
        ┌──────────────┴──────────────┐
        │                              │
        │        ┌─────────────────────┐
        │        │  dim_location       │
        │        │─────────────────────│
        │        │ location_key (PK)   │
        │        │ iso_code (UK)       │
        │        │ location            │
        │        │ continent           │
        │        │ population          │
        └────────┴─────────────────────┘
```

## Dimension Tables

### dim_date
**Type**: Dimension (Slowly Changing Dimension Type 1)  
**Grain**: One row per day  
**Key**: `date_key` (YYYYMMDD format as integer)

**Column Descriptions**:
- `date_key`: Surrogate key (primary key)
- `date`: Calendar date
- `year`: Year (2020, 2021, etc.)
- `quarter`: Quarter (1-4)
- `month`: Month (1-12)
- `day_of_month`: Day of month (1-31)
- `day_of_week`: Day of week (1=Monday, 7=Sunday, ISO standard)
- `iso_week`: ISO week number (1-53)

**Business Rules**:
- Starts from 2020-01-01 (COVID-19 outbreak start)
- Dynamically generated to current_date
- No history handling (SCD Type 1)

### dim_location
**Type**: Dimension (Slowly Changing Dimension Type 1)  
**Grain**: One row per country  
**Key**: `location_key` (surrogate key based on iso_code)

**Column Descriptions**:
- `location_key`: Surrogate key (primary key)
- `iso_code`: ISO country code (DK, SE, etc.) - Unique
- `location`: Country name
- `continent`: Continent
- `population`: Population size

**Business Rules**:
- One row per country
- `iso_code` is unique and not-null
- History not handled (SCD Type 1)

## Fact Table

### fct_covid_daily
**Type**: Fact Table (Transaction Grain)  
**Grain**: One row per day per country  
**Key**: `fact_key` (composite key of date_key + location_key)

**Column Descriptions**:
- `fact_key`: Surrogate key (primary key)
- `date_key`: Foreign key to dim_date
- `location_key`: Foreign key to dim_location
- `new_cases`: New cases on the day (additive)
- `total_cases`: Total number of cases (semi-additive)
- `new_vaccinations`: New vaccinations on the day (additive)
- `people_vaccinated`: Total number of vaccinated (semi-additive)
- `people_fully_vaccinated`: Total number of fully vaccinated (semi-additive)

**Metrics Types**:
- **Additive**: Can be summed across all dimensions (new_cases, new_vaccinations)
- **Semi-additive**: Can only be summed across some dimensions (total_cases is actually a snapshot)
- **Non-additive**: Calculated metrics (percentages, rates)

**Business Rules**:
- One row per day per country
- If there is no data for a day, values are NULL (not 0)
- FULL OUTER JOIN between cases and vaccinations data

## Marts Table

### covid_country_metrics
**Type**: Aggregated Mart  
**Grain**: One row per week per country  
**Key**: Composite (location + year + iso_week)

**Column Descriptions**:
- `location`: Country name
- `year`: Year
- `iso_week`: ISO week number
- `weekly_cases`: Sum of new cases in the week (additive)
- `weekly_vaccinations`: Sum of new vaccinations in the week (additive)
- `people_vaccinated_to_date`: Max value (latest value in the week)
- `people_fully_vaccinated_to_date`: Max value (latest value in the week)
- `population`: Population (from dim_location)
- `fully_vaccinated_pct`: Percentage fully vaccinated

**Purpose**: 
- Optimized for week-based analyses
- Reduces need for complex aggregations in queries
- Business-ready metrics

## Data Flow

### ETL Process

1. **Extract**: CSV files (seeds) → PostgreSQL `covid_raw` schema
2. **Transform**: 
   - Staging layer: Data cleaning, type casting
   - Core layer: Dimensional modeling
   - Marts layer: Aggregations
3. **Load**: Materialized as views/tables in `covid` schema

### Transformation Steps

**Staging**:
- Uppercase ISO codes
- Initcap location names
- Cast numeric fields
- Null handling

**Core**:
- Generate date dimension
- Create location dimension with surrogate keys
- Join cases and vaccinations data
- Link to dimensions

**Marts**:
- Group by week and location
- Aggregate metrics
- Calculate percentages

## Query Patterns

### Slicing & Dicing
```sql
-- Fact table + dimensions provide flexible analysis
SELECT d.year, l.continent, SUM(f.new_cases)
FROM fct_covid_daily f
JOIN dim_date d USING (date_key)
JOIN dim_location l USING (location_key)
GROUP BY d.year, l.continent
```

### Time Series Analysis
```sql
-- Use dim_date for time-based analyses
SELECT d.date, SUM(f.new_cases) 
FROM fct_covid_daily f
JOIN dim_date d USING (date_key)
WHERE d.year = 2021
GROUP BY d.date
ORDER BY d.date
```

### Pre-aggregated Queries
```sql
-- Use marts for fast week analyses
SELECT * FROM covid_country_metrics
WHERE location = 'Denmark'
ORDER BY year DESC, iso_week DESC
```

## Data Quality

### Tests Implemented

**Uniqueness**:
- `dim_date.date_key` must be unique
- `dim_location.location_key` must be unique  
- `fct_covid_daily.fact_key` must be unique

**Completeness**:
- All staging models have required fields (not_null)
- Foreign keys have valid references (relationships tests)

**Referential Integrity**:
- `fct_covid_daily.date_key` → `dim_date.date_key`
- `fct_covid_daily.location_key` → `dim_location.location_key`
- `dim_location.iso_code` → `stg_population.iso_code`

## Notes

- All dimensions are SCD Type 1 (no history)
- Date dimension generated from 2020-01-01 to current_date
- Location dimension based on seed data
- Fact table uses FULL OUTER JOIN to handle missing data
- Marts table materialized as VIEW for automatic refresh
