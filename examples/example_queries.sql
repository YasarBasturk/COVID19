-- =====================================================
-- COVID-19 Data Warehouse - Example Queries with Insights
-- =====================================================
-- These queries demonstrate CONCRETE INSIGHTS from the data

-- =====================================================
-- 1. Which country has had the most COVID-19 cases?
-- INSIGHT: Comparison between countries
-- =====================================================
SELECT 
    l.location AS "Country",
    SUM(f.new_cases) AS "Total Cases",
    MAX(l.population) AS "Population",
    ROUND(1000.0 * SUM(f.new_cases) / NULLIF(MAX(l.population), 0), 2) AS "Cases per 1000 Inhabitants"
FROM covid.fct_covid_daily f
JOIN covid.dim_location l USING (location_key)
WHERE f.new_cases > 0
GROUP BY l.location
ORDER BY "Total Cases" DESC;

-- =====================================================
-- 2. When were there the most new cases? (Top 10 days)
-- INSIGHT: Identifies peak periods
-- =====================================================
SELECT 
    d.date AS "Date",
    l.location AS "Country",
    f.new_cases AS "New Cases"
FROM covid.fct_covid_daily f
JOIN covid.dim_location l USING (location_key)
JOIN covid.dim_date d USING (date_key)
WHERE f.new_cases > 0
ORDER BY f.new_cases DESC
LIMIT 10;

-- =====================================================
-- 3. Which country was hit hardest per inhabitant?
-- INSIGHT: Normalized comparison (fair comparison)
-- =====================================================
SELECT 
    l.location AS "Country",
    SUM(f.new_cases) AS "Total Cases",
    MAX(l.population) AS "Population",
    ROUND(1000.0 * SUM(f.new_cases) / NULLIF(MAX(l.population), 0), 2) AS "Cases per 1000"
FROM covid.fct_covid_daily f
JOIN covid.dim_location l USING (location_key)
WHERE f.new_cases > 0
GROUP BY l.location
ORDER BY "Cases per 1000" DESC;

-- =====================================================
-- 4. How did COVID-19 develop over time? (Denmark example)
-- INSIGHT: Temporal trend - can see waves of the pandemic
-- =====================================================
SELECT 
    d.date AS "Date",
    f.new_cases AS "New Cases",
    f.total_cases AS "Total Cases (Cumulative)"
FROM covid.fct_covid_daily f
JOIN covid.dim_location l USING (location_key)
JOIN covid.dim_date d USING (date_key)
WHERE l.iso_code = 'DK'
  AND f.new_cases > 0
ORDER BY d.date
LIMIT 30;

-- =====================================================
-- 5. Comparison: Which country had the most new cases in the same period?
-- INSIGHT: Parallel comparison of countries
-- =====================================================
SELECT 
    l.location AS "Country",
    COUNT(*) AS "Days with Cases",
    SUM(f.new_cases) AS "Total Cases",
    ROUND(AVG(f.new_cases), 2) AS "Average Daily Cases",
    MAX(f.new_cases) AS "Max Cases on One Day"
FROM covid.fct_covid_daily f
JOIN covid.dim_location l USING (location_key)
WHERE f.new_cases > 0
GROUP BY l.location
ORDER BY "Total Cases" DESC;

-- =====================================================
-- 6. Which month was hardest? (2020 vs 2021)
-- INSIGHT: Comparison between years
-- =====================================================
SELECT 
    d.year AS "Year",
    d.month AS "Month",
    SUM(f.new_cases) AS "Total Cases in Month",
    COUNT(DISTINCT l.location) AS "Countries with Cases"
FROM covid.fct_covid_daily f
JOIN covid.dim_location l USING (location_key)
JOIN covid.dim_date d USING (date_key)
WHERE f.new_cases > 0
GROUP BY d.year, d.month
ORDER BY d.year DESC, d.month DESC
LIMIT 12;

-- =====================================================
-- 7. How does the development look in the 4 Nordic countries?
-- INSIGHT: Side-by-side comparison
-- =====================================================
SELECT 
    l.location AS "Country",
    MIN(d.date) AS "First Case",
    MAX(d.date) AS "Last Case",
    SUM(f.new_cases) AS "Total Cases",
    ROUND(1000.0 * SUM(f.new_cases) / NULLIF(MAX(l.population), 0), 2) AS "Cases per 1000"
FROM covid.fct_covid_daily f
JOIN covid.dim_location l USING (location_key)
JOIN covid.dim_date d USING (date_key)
WHERE f.new_cases > 0
GROUP BY l.location
ORDER BY "Total Cases" DESC;

-- =====================================================
-- 8. Which weeks in 2020 had the most cases?
-- INSIGHT: Identifies weeks with high activity
-- =====================================================
SELECT 
    d.year AS "Year",
    d.iso_week AS "Week",
    SUM(f.new_cases) AS "Total Cases in Week",
    COUNT(DISTINCT l.location) AS "Countries Affected"
FROM covid.fct_covid_daily f
JOIN covid.dim_location l USING (location_key)
JOIN covid.dim_date d USING (date_key)
WHERE f.new_cases > 0
  AND d.year = 2020
GROUP BY d.year, d.iso_week
ORDER BY "Total Cases in Week" DESC
LIMIT 10;
