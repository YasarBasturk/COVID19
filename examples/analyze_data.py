#!/usr/bin/env python3
"""
COVID-19 Data Warehouse Analysis Script
This script demonstrates how a data scientist can fetch and analyze data
from the data warehouse.
"""

import pandas as pd
import psycopg2
import matplotlib.pyplot as plt

# =====================================================
# 1. Create database connection
# =====================================================
def get_connection():
    """Create connection to PostgreSQL database"""
    return psycopg2.connect(
        host="localhost",
        port=5432,
        database="analytics",
        user="covid",
        password="covid"
    )

# =====================================================
# 2. Fetch data from data warehouse
# =====================================================
def get_total_cases_by_country(conn):
    """Fetch total cases and vaccinations per country"""
    query = """
    SELECT 
        l.location,
        l.population,
        SUM(f.new_cases) as total_cases,
        SUM(f.new_vaccinations) as total_vaccinations,
        MAX(f.people_fully_vaccinated) as people_fully_vaccinated,
        -- Calculate cases per 1000 inhabitants
        ROUND(1000.0 * SUM(f.new_cases) / NULLIF(l.population, 0), 2) as cases_per_1000,
        -- Calculate vaccination rate
        ROUND(100.0 * MAX(f.people_fully_vaccinated) / NULLIF(l.population, 0), 2) as vaccination_rate
    FROM covid.fct_covid_daily f
    JOIN covid.dim_location l USING (location_key)
    WHERE f.new_cases > 0
    GROUP BY l.location, l.population
    ORDER BY total_cases DESC
    """
    return pd.read_sql(query, conn)

def get_daily_trends(conn, iso_code='DK'):
    """Fetch daily trends for a specific country"""
    query = """
    SELECT 
        d.date,
        l.location,
        f.new_cases,
        f.total_cases
    FROM covid.fct_covid_daily f
    JOIN covid.dim_location l USING (location_key)
    JOIN covid.dim_date d USING (date_key)
    WHERE l.iso_code = %s
    ORDER BY d.date
    """
    return pd.read_sql(query, conn, params=(iso_code,))

def get_weekly_metrics(conn):
    """Fetch weekly aggregations"""
    query = """
    SELECT 
        location,
        year,
        iso_week,
        weekly_cases,
        weekly_vaccinations,
        fully_vaccinated_pct
    FROM covid.covid_country_metrics
    ORDER BY location, year DESC, iso_week DESC
    """
    return pd.read_sql(query, conn)

# =====================================================
# 3. Analyze and visualize data
# =====================================================
def plot_total_cases(df):
    """Plot total cases per country"""
    plt.figure(figsize=(10, 6))
    df.plot(kind='bar', x='location', y='total_cases', color='steelblue')
    plt.title('Total COVID-19 Cases per Country', fontsize=14, fontweight='bold')
    plt.xlabel('Country', fontsize=12)
    plt.ylabel('Total Cases', fontsize=12)
    plt.xticks(rotation=45, ha='right')
    plt.tight_layout()
    plt.savefig('examples/plots/total_cases.png', dpi=150)
    print("✅ Plot saved to examples/plots/total_cases.png")
    plt.show()

def plot_cases_per_1000(df):
    """Plot cases per 1000 inhabitants"""
    plt.figure(figsize=(10, 6))
    df.plot(kind='bar', x='location', y='cases_per_1000', color='coral')
    plt.title('COVID-19 Cases per 1000 Inhabitants', fontsize=14, fontweight='bold')
    plt.xlabel('Country', fontsize=12)
    plt.ylabel('Cases per 1000', fontsize=12)
    plt.xticks(rotation=45, ha='right')
    plt.tight_layout()
    plt.savefig('examples/plots/cases_per_1000.png', dpi=150)
    print("✅ Plot saved to examples/plots/cases_per_1000.png")
    plt.show()

def plot_daily_trends(df):
    """Plot daily trends"""
    fig, axes = plt.subplots(1, 1, figsize=(12, 6))
    axes.plot(df['date'], df['new_cases'], marker='o', linewidth=2, markersize=6)
    axes.set_title(f'Daily New Cases - {df["location"].iloc[0]}', fontsize=14, fontweight='bold')
    axes.set_xlabel('Date', fontsize=12)
    axes.set_ylabel('New Cases', fontsize=12)
    axes.grid(True, alpha=0.3)
    axes.tick_params(axis='x', rotation=45)
    
    plt.tight_layout()
    plt.savefig(f'examples/plots/daily_trends_{df["location"].iloc[0]}.png', dpi=150)
    print(f"✅ Plot saved to examples/plots/daily_trends_{df['location'].iloc[0]}.png")
    plt.show()

# =====================================================
# 4. Main execution
# =====================================================
def main():
    """Main function that runs the analyses"""
    
    print("🔗 Connecting to database...")
    conn = get_connection()
    print("✅ Connected!\n")
    
    # Create plots directory if it doesn't exist
    import os
    os.makedirs('examples/plots', exist_ok=True)
    
    # =====================================================
    # Analysis 1: Total cases per country
    # =====================================================
    print("📊 Fetching data: Total cases per country...")
    df_countries = get_total_cases_by_country(conn)
    print(f"✅ Found data for {len(df_countries)} countries\n")
    
    print("📈 Top countries:")
    print(df_countries[['location', 'total_cases', 'total_vaccinations', 'cases_per_1000']].to_string(index=False))
    print("\n")
    
    # Visualize
    plot_total_cases(df_countries)
    plot_cases_per_1000(df_countries)
    
    # =====================================================
    # Analysis 2: Daily trends
    # =====================================================
    print("\n📊 Fetching daily trends for Denmark...")
    df_daily_dk = get_daily_trends(conn, 'DK')
    print(f"✅ Found {len(df_daily_dk)} days with data\n")
    
    print("📈 Daily data for Denmark:")
    print(df_daily_dk.to_string(index=False))
    print("\n")
    
    plot_daily_trends(df_daily_dk)
    
    # =====================================================
    # Analysis 3: Statistics
    # =====================================================
    print("\n📊 Statistics for daily cases:")
    print(df_daily_dk['new_cases'].describe())
    print("\n")
    
    # =====================================================
    # Analysis 4: Weekly metrics
    # =====================================================
    print("📊 Fetching weekly metrics...")
    df_weekly = get_weekly_metrics(conn)
    print(f"✅ Found {len(df_weekly)} weeks with data\n")
    
    print("📈 Weekly aggregations:")
    print(df_weekly.to_string(index=False))
    print("\n")
    
    # Close connection
    conn.close()
    print("✅ Analysis complete!")

if __name__ == "__main__":
    main()
