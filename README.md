# COVID-19 Mini Data Warehouse

A mini data warehouse project built with **PostgreSQL** and **dbt** (data build tool) to demonstrate data modeling and data warehousing concepts.

## 🎯 Project Goals

This project demonstrates:
- **Data Warehousing**: ETL/ELT process from raw data to analyzed data marts
- **Data Modeling**: Staging → Core (Dimensions & Facts) → Marts structure
- **dbt best practices**: Modularization, documentation, testing
- **PostgreSQL**: Relational database for data warehouse
- **Data Analysis**: Python scripts and SQL queries to derive insights from the data

## 🏗️ Data Model Structure

### Data Flow
```
Raw Data (Seeds) → Staging Layer → Core Layer → Marts Layer
```

### Layers

#### 1. **Raw Layer** (`seeds/`)
- `owid_covid_data.csv` - COVID-19 data from Our World in Data (Nordic countries: DK, SE, NO, FI)
  - Contains: cases, vaccinations, population data per day
  - Source: [Our World in Data](https://ourworldindata.org/covid-vaccinations)

#### 2. **Staging Layer** (`models/staging/`)
- `stg_cases` - Cleaned and validated cases data
- `stg_population` - Cleaned population data (unique per country)
- `stg_vaccinations` - Cleaned vaccinations data

**Purpose**: Data cleaning, type casting, standardization, ISO code mapping (DNK→DK, etc.)

#### 3. **Core Layer** (`models/core/`)
- `dim_date` - Date dimension (2020-01-01 to today)
- `dim_location` - Location dimension (4 Nordic countries with metadata)
- `fct_covid_daily` - Fact table (daily metrics per country per day)

**Purpose**: Kimball-style star schema with dimensions and facts

#### 4. **Marts Layer** (`models/marts/`)
- `covid_country_metrics` - Weekly aggregation for country analysis

**Purpose**: Business-ready analytics views

## 🛠️ Technology Stack

- **PostgreSQL 16**: Relational database (via Docker)
- **dbt**: Data transformation tool
- **Python 3.11**: Data analysis and visualization (via Conda environment)
- **Docker Compose**: PostgreSQL containerization
- **Pandas & Matplotlib**: Data analysis and plotting

## 📋 Setup Instructions

### 1. Create Conda Environment
```bash
conda create -n covid19 python=3.11
conda activate covid19
pip install dbt-core dbt-postgres pandas psycopg2-binary matplotlib
```

### 2. Start PostgreSQL (Docker)
```bash
docker compose up -d
```

### 3. Create Databases and Schemas
```bash
docker compose exec postgres psql -U covid -d analytics -c "CREATE SCHEMA IF NOT EXISTS covid; CREATE SCHEMA IF NOT EXISTS covid_raw;"
```

### 4. Install dbt Packages
```bash
dbt deps
```

### 5. Run dbt Pipeline
```bash
# Load seed data
dbt seed

# Build all models
dbt run

# Run tests
dbt test

# Generate documentation
dbt docs generate
dbt docs serve
```

## 📊 Data Model Diagram

```
┌─────────────────┐
│  Raw Layer      │
│  (Seeds)        │
├─────────────────┤
│ owid_covid_data │
│ (Nordic countries)│
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Staging Layer   │
├─────────────────┤
│ stg_cases       │
│ stg_population  │
│ stg_vaccinations│
└────────┬────────┘
         │
    ┌────┴────┐
    ▼         ▼
┌─────────┐ ┌──────────────────┐
│ Core    │ │ Core             │
│ dim_date│ │ dim_location     │
└────┬────┘ └─────┬────────────┘
     │            │
     └─────┬──────┘
           ▼
    ┌──────────────┐
    │ fct_covid_   │
    │ daily        │
    └──────┬───────┘
           │
           ▼
    ┌──────────────┐
    │ Marts        │
    │ covid_       │
    │ country_     │
    │ metrics      │
    └──────────────┘
```

## 📈 Data Analysis & Visualization

### SQL Queries
See `examples/example_queries.sql` for example queries that demonstrate:
- Total cases per country
- Peak days with most new cases
- Cases per 1000 inhabitants (normalized comparison)
- Daily trends over time
- Monthly and weekly analysis

Run queries:
```bash
cat examples/example_queries.sql | docker compose exec -T postgres psql -U covid -d analytics
```

### Python Analysis
Run `examples/analyze_data.py` to:
- Fetch data from the data warehouse
- Generate visualizations (bar charts, line plots)
- Calculate statistics
- Save plots in `examples/plots/`

Run Python script:
```bash
conda activate covid19
python examples/analyze_data.py
```

**Output:**
- `examples/plots/total_cases.png` - Total cases per country
- `examples/plots/cases_per_1000.png` - Cases per 1000 inhabitants
- `examples/plots/daily_trends_Denmark.png` - Daily trends for Denmark

## 🔍 Example Insights

Some insights you can derive from the data:

1. **Denmark hit hardest**: 584 cases per 1000 inhabitants (vs. 261 in Sweden)
2. **Peak day**: February 13, 2022 with 322,546 new cases (Omicron variant)
3. **Timeline**: Started with 3 cases on March 1, 2020, grew to 22,436 after 6 months
4. **Average**: Denmark had the highest average daily cases (15,476 per day)

## 📝 Notes

- Data is filtered to only Nordic countries (DK, SE, NO, FI) to keep the dataset manageable
- All staging models are materialized as VIEWS (fast refreshes)
- Core models are materialized as TABLES (better performance for analytics)
- Vaccination data is not available in the current dataset

## 🧪 Testing

dbt tests ensure:
- Data quality (not_null, unique)
- Referential integrity (relationships)
- Data consistency

Run all tests:
```bash
dbt test
```

## 📁 Project Structure

```
.
├── models/
│   ├── staging/          # Data cleaning layer
│   ├── core/             # Dimensions & Facts (star schema)
│   └── marts/            # Business-ready analytics
├── seeds/                # Raw CSV data
├── examples/             # SQL queries & Python analysis
│   ├── example_queries.sql
│   ├── analyze_data.py
│   └── plots/            # Generated visualizations
├── dbt_project.yml       # dbt configuration
├── packages.yml          # dbt packages
├── profiles.yml          # Database connection
└── docker-compose.yml    # PostgreSQL container
```

## 📚 Learning Objectives Achieved

✅ ETL/ELT pipeline design  
✅ Kimball dimensional modeling  
✅ dbt project structure and best practices  
✅ PostgreSQL data warehouse setup  
✅ Data quality testing  
✅ Documentation generation  
✅ SQL queries for data analysis  
✅ Python visualization and statistics  

## 🔗 Resources

- [dbt Documentation](https://docs.getdbt.com/)
- [Kimball Dimensional Modeling](https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/)
- [Our World in Data - COVID-19](https://ourworldindata.org/covid-vaccinations)

## 📄 License

This project is for educational purposes. COVID-19 data comes from Our World in Data.
