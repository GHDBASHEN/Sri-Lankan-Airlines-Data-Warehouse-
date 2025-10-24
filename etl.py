import os
import pandas as pd
import traceback
import re
import pymysql
import mysql.connector
from mysql.connector import errorcode

# --- Setup ---
try:
    # Use PyMySQL as the connector
    mysql.connector.connect = pymysql.connect
except ImportError:
    print("❌ CRITICAL ERROR: The 'PyMySQL' or 'mysql-connector-python' library is not installed.")
    print("   Please run 'pip install PyMySQL mysql-connector-python pandas openpyxl' in your terminal.")
    exit()

# --- Configuration ---

# !!! IMPORTANT: UPDATE YOUR LOCAL DATABASE USER AND PASSWORD HERE !!!
DB_CONFIG = {
    'host': 'localhost',          # Or '127.0.0.1'
    'user': 'root',      # <-- !!! UPDATE THIS !!!
    'password': '1234', # <-- !!! UPDATE THIS !!!
    'database': 'Airlines',
    'connect_timeout': 20
}

# Define a folder for all your data source files
DATA_SOURCE_FOLDER = 'data_sources'


# --- Transform Helper Functions ---

def _transform_caa_movements(df):
    """Cleans the CAA passenger movements data."""
    print("  -> Transforming CAA data...")
    df = df.drop_duplicates()
    
    # Clean text fields
    df['airport_iata'] = df['airport_iata'].astype(str).str.strip()
    df['country'] = df['country'].astype(str).str.strip()

    # Clean numeric fields (remove commas, dashes, 'N/A')
    df['passengers'] = df['passengers'].astype(str).str.replace(r'[,—N/A]', '', regex=True).str.strip()
    df['passengers'] = pd.to_numeric(df['passengers'], errors='coerce').astype('Int64')
    
    df['aircraft_movements'] = df['aircraft_movements'].astype(str).str.replace(r'[,—]', '', regex=True).str.strip()
    df['aircraft_movements'] = pd.to_numeric(df['aircraft_movements'], errors='coerce').astype('Int64')

    # Standardize date period to date_key
    df['period_dt'] = pd.to_datetime(df['period'], errors='coerce', infer_datetime_format=True)
    df['date_key'] = df['period_dt'].dt.strftime('%Y%m%d').astype('Int64')
    
    # Select and filter final columns
    final_df = df[['date_key', 'airport_iata', 'passengers', 'aircraft_movements', 'country']]
    final_df = final_df.dropna(subset=['date_key'])
    return final_df

def _transform_srilankan_financials(df):
    """Cleans the SriLankan annual report data."""
    print("  -> Transforming SriLankan financials data...")
    df = df.drop_duplicates()

    # Clean year (remove 'x', convert to number)
    df['year'] = df['year'].astype(str).str.replace('x', '', regex=False).str.strip()
    df['year'] = pd.to_numeric(df['year'], errors='coerce').astype('Int64')
    df = df.dropna(subset=['year'])

    # Clean text fields
    df['metric'] = df['metric'].astype(str).str.strip()
    df['notes'] = df['notes'].astype(str).str.strip()

    def clean_financial_value(val):
        """Helper to parse messy currency values."""
        val_str = str(val).strip()
        currency = 'LKR'  # Default
        if 'USD' in val_str: currency = 'USD'
        if 'Rs.' in val_str: currency = 'LKR'
        
        is_negative = False
        if val_str.startswith('(') and val_str.endswith(')'):
            is_negative = True
            val_str = val_str.strip('()')
            
        val_str = re.sub(r'[USD,Rs.,LKR\s]', '', val_str, flags=re.IGNORECASE)
        val_str = val_str.replace('—', '').replace('N/A', '')
        
        try:
            num_val = float(val_str)
            if is_negative:
                num_val = -num_val
            return pd.Series([num_val, currency])
        except (ValueError, TypeError):
            return pd.Series([pd.NA, pd.NA])

    df[['value', 'currency']] = df['value'].apply(clean_financial_value)
    
    # Select and filter final columns
    final_df = df[['year', 'metric', 'value', 'currency', 'notes']]
    final_df = final_df.dropna(subset=['value'])
    final_df['value'] = final_df['value'].astype('Float64')
    return final_df

def _transform_worldbank_transport(df):
    """Cleans the World Bank air transport data."""
    print("  -> Transforming World Bank data...")
    df = df.drop_duplicates()

    # Clean year (remove 'a', convert to number)
    df['year'] = df['year'].astype(str).str.replace('a', '', regex=False).str.strip()
    df['year'] = pd.to_numeric(df['year'], errors='coerce').astype('Int64')
    df = df.dropna(subset=['year'])

    # Clean numeric fields
    df['passengers'] = df['passengers'].astype(str).str.replace(r'[,—]', '', regex=True).str.strip()
    df['passengers'] = pd.to_numeric(df['passengers'], errors='coerce').astype('Int64')
    
    # Clean text fields
    df['country_name'] = df['country_name'].astype(str).str.strip()
    df['country_code'] = df['country_code'].astype(str).str.strip()

    # Select and filter final columns
    final_df = df[['year', 'country_name', 'country_code', 'passengers']]
    return final_df


# --- ETL Pipeline ---

def extract():
    """Extract Phase: Reads data from all source Excel files in the data_sources folder."""
    print("\n--- 1. EXTRACT ---")
    print(f"Reading data from source folder: '{DATA_SOURCE_FOLDER}'")
    dataframes = {}
    
    source_files = {
        "caa_movements": "caa_passenger_movements_unclean.xlsx",
        "srilankan_financials": "srilankan_annual_report_unclean.xlsx",
        "worldbank_transport": "worldbank_air_transport_unclean.xlsx"
    }
    
    try:
        for name, filename in source_files.items():
            path = os.path.join(DATA_SOURCE_FOLDER, filename) 
            if not os.path.exists(path):
                print(f"❌ ERROR: File not found: {path}"); return None
            
            dataframes[name] = pd.read_excel(path, na_filter=False, dtype=str)
            print(f"✅ Read {len(dataframes[name])} rows from {filename}")
            
        return dataframes
    except Exception as e:
        print(f"❌ EXTRACT ERROR: Could not read Excel files. Details: {e}");
        print("   (Did you remember to 'pip install openpyxl' ?)")
        return None

def transform(raw_data):
    """Transform Phase: Cleans and prepares the data for staging."""
    if not raw_data: return None
    print("\n--- 2. TRANSFORM (for Staging) ---")
    print("Cleaning and preparing data for loading...")
    try:
        # Transform external data sources
        if 'caa_movements' in raw_data:
            raw_data['caa_movements_clean'] = _transform_caa_movements(raw_data['caa_movements'])
            print("✅ Transformed CAA movements.")

        if 'srilankan_financials' in raw_data:
            raw_data['srilankan_financials_clean'] = _transform_srilankan_financials(raw_data['srilankan_financials'])
            print("✅ Transformed SriLankan financials.")

        if 'worldbank_transport' in raw_data:
            raw_data['worldbank_transport_clean'] = _transform_worldbank_transport(raw_data['worldbank_transport'])
            print("✅ Transformed World Bank transport.")

        print("✅ All transformations complete.")
        return raw_data
        
    except Exception as e:
        print(f"❌ TRANSFORM ERROR: {e}"); 
        traceback.print_exc()
        return None

def load(transformed_data):
    """Load Phase: Connects to the DB and loads all data into staging tables."""
    if not transformed_data: return False
    print("\n--- 3. LOAD (to Staging) ---")
    print(f"Connecting to database: {DB_CONFIG['host']}/{DB_CONFIG['database']}...")
    
    conn = None
    cursor = None
    try:
        conn = mysql.connector.connect(**DB_CONFIG)
        cursor = conn.cursor()
        print("✅ Database connection successful. Starting data load...")

        # Load transformed external data
        if 'caa_movements_clean' in transformed_data:
            _load_stg_caa_movements(conn, cursor, transformed_data['caa_movements_clean'])
        if 'srilankan_financials_clean' in transformed_data:
            _load_stg_srilankan_financials(conn, cursor, transformed_data['srilankan_financials_clean'])
        if 'worldbank_transport_clean' in transformed_data:
            _load_stg_worldbank_transport(conn, cursor, transformed_data['worldbank_transport_clean'])

        print("\n✅ All staging data loaded successfully.")
        return True
    except Exception as e:
        print(f"❌ An unexpected error occurred during the LOAD phase.")
        traceback.print_exc()
        if conn: conn.rollback()
        return False
    finally:
        if cursor: cursor.close()
        if conn:
            conn.close()
            print("\n🔌 Database connection closed.")

# <-- NEW FUNCTION -->
def run_warehouse_transforms():
    """
    Transform Phase 2: Runs SQL queries to transform data from Staging tables
    into the final Data Warehouse (Star Schema) tables.
    """
    print("\n--- 4. TRANSFORM (to Data Warehouse) ---")
    print(f"Connecting to database: {DB_CONFIG['host']}/{DB_CONFIG['database']}...")

    conn = None
    cursor = None
    
    # All the SQL commands to run, in order
    sql_commands = {
        "Populating dim_date...": """
            INSERT IGNORE INTO dim_date (date_key, full_date, year, quarter, month, month_name, day, day_of_week, is_weekend)
            SELECT 
                date_key, STR_TO_DATE(date_key, '%Y%m%d') AS full_date,
                YEAR(STR_TO_DATE(date_key, '%Y%m%d')) AS year, QUARTER(STR_TO_DATE(date_key, '%Y%m%d')) AS quarter,
                MONTH(STR_TO_DATE(date_key, '%Y%m%d')) AS month, DATE_FORMAT(STR_TO_DATE(date_key, '%Y%m%d'), '%M') AS month_name,
                DAY(STR_TO_DATE(date_key, '%Y%m%d')) AS day, DAYOFWEEK(STR_TO_DATE(date_key, '%Y%m%d')) AS day_of_week,
                IF(DAYOFWEEK(STR_TO_DATE(date_key, '%Y%m%d')) IN (1, 7), 1, 0) AS is_weekend
            FROM stg_caa_movements WHERE date_key IS NOT NULL
            UNION
            SELECT
                year * 10000 + 101 AS date_key, STR_TO_DATE(CONCAT(year, '-01-01'), '%Y-%m-%d') AS full_date,
                year, 1, 1, 'January', 1, DAYOFWEEK(STR_TO_DATE(CONCAT(year, '-01-01'), '%Y-%m-%d')) AS day_of_week,
                IF(DAYOFWEEK(STR_TO_DATE(CONCAT(year, '-01-01'), '%Y-%m-%d')) IN (1, 7), 1, 0) AS is_weekend
            FROM stg_srilankan_financials WHERE year IS NOT NULL
            UNION
            SELECT
                year * 10000 + 101 AS date_key, STR_TO_DATE(CONCAT(year, '-01-01'), '%Y-%m-%d') AS full_date,
                year, 1, 1, 'January', 1, DAYOFWEEK(STR_TO_DATE(CONCAT(year, '-01-01'), '%Y-%m-%d')) AS day_of_week,
                IF(DAYOFWEEK(STR_TO_DATE(CONCAT(year, '-01-01'), '%Y-%m-%d')) IN (1, 7), 1, 0) AS is_weekend
            FROM stg_worldbank_transport WHERE year IS NOT NULL
        """,
        "Populating dim_airport...": """
            INSERT IGNORE INTO dim_airport (iata_code, country)
            SELECT DISTINCT airport_iata, country
            FROM stg_caa_movements
            WHERE airport_iata IS NOT NULL AND airport_iata != ''
        """,
        "Populating dim_country...": """
            INSERT IGNORE INTO dim_country (country_code, country_name)
            SELECT DISTINCT country_code, country_name
            FROM stg_worldbank_transport
            WHERE country_code IS NOT NULL AND country_code != ''
        """,
        "Populating dim_metric...": """
            INSERT IGNORE INTO dim_metric (metric_name, metric_category)
            SELECT DISTINCT 
                metric,
                CASE 
                    WHEN metric IN ('Revenue', 'Operating Loss', 'Cargo Revenue') THEN 'Financial'
                    WHEN metric IN ('Passengers', 'Aircraft Fleet', 'Employee Count', 'Passenger Load Factor') THEN 'Operational'
                    ELSE 'Other'
                END AS metric_category
            FROM stg_srilankan_financials
            WHERE metric IS NOT NULL AND metric != ''
        """,
        "Populating fact_passenger_movements...": """
            TRUNCATE TABLE fact_passenger_movements
        """,
        "Populating fact_passenger_movements (Insert)...": """
            INSERT INTO fact_passenger_movements (date_key, airport_key, passengers, aircraft_movements)
            SELECT
                s.date_key, a.airport_key, s.passengers, s.aircraft_movements
            FROM stg_caa_movements s
            LEFT JOIN dim_airport a ON s.airport_iata = a.iata_code
            WHERE s.date_key IS NOT NULL
        """,
        "Populating fact_airline_financials...": """
            TRUNCATE TABLE fact_airline_financials
        """,
        "Populating fact_airline_financials (Insert)...": """
            INSERT INTO fact_airline_financials (date_key, metric_key, value, currency)
            SELECT
                s.year * 10000 + 101 AS date_key, m.metric_key, s.value, s.currency
            FROM stg_srilankan_financials s
            LEFT JOIN dim_metric m ON s.metric = m.metric_name
            WHERE s.year IS NOT NULL
        """,
        "Populating fact_world_transport_stats...": """
            TRUNCATE TABLE fact_world_transport_stats
        """,
        "Populating fact_world_transport_stats (Insert)...": """
            INSERT INTO fact_world_transport_stats (date_key, country_key, passengers)
            SELECT
                s.year * 10000 + 101 AS date_key, c.country_key, s.passengers
            FROM stg_worldbank_transport s
            LEFT JOIN dim_country c ON s.country_code = c.country_code
            WHERE s.year IS NOT NULL
        """
    }

    try:
        conn = mysql.connector.connect(**DB_CONFIG)
        cursor = conn.cursor()
        print("✅ Database connection successful. Running warehouse transforms...")

        for message, sql in sql_commands.items():
            print(f"   -> {message}")
            cursor.execute(sql)
            conn.commit()
            if "INSERT" in sql or "TRUNCATE" in sql:
                print(f"      ... {cursor.rowcount} rows affected.")

        print("\n✅ Data Warehouse transformations complete.")
        return True
    except Exception as e:
        print(f"❌ An unexpected error occurred during the WAREHOUSE TRANSFORM phase.")
        traceback.print_exc()
        if conn: conn.rollback()
        return False
    finally:
        if cursor: cursor.close()
        if conn:
            conn.close()
            print("\n🔌 Database connection closed.")


# --- Database Helper Functions ---

def _clean_df_for_db(df):
    """Converts a DataFrame into a list of tuples for database insertion."""
    df_clean = df.replace({pd.NaT: None, pd.NA: None, '': None, 'nan': None})
    return [tuple(x) for x in df_clean.to_numpy()]

def _load_stg_caa_movements(conn, cursor, df):
    """Loads cleaned CAA data into its staging table."""
    print("🔄 Loading stg_caa_movements...")
    try:
        data_to_load = _clean_df_for_db(df)
        cursor.execute("TRUNCATE TABLE stg_caa_movements") 
        print("   -> Staging table truncated.")
        sql = "INSERT INTO stg_caa_movements (date_key, airport_iata, passengers, aircraft_movements, country) VALUES (%s,%s,%s,%s,%s)"
        cursor.executemany(sql, data_to_load)
        conn.commit()
        print(f"   -> {cursor.rowcount} rows processed for stg_caa_movements.")
    except Exception as e:
        print(f"❌ Error loading stg_caa_movements: {e}"); conn.rollback(); raise

def _load_stg_srilankan_financials(conn, cursor, df):
    """Loads cleaned financial data into its staging table."""
    print("🔄 Loading stg_srilankan_financials...")
    try:
        data_to_load = _clean_df_for_db(df)
        cursor.execute("TRUNCATE TABLE stg_srilankan_financials")
        print("   -> Staging table truncated.")
        sql = "INSERT INTO stg_srilankan_financials (year, metric, value, currency, notes) VALUES (%s,%s,%s,%s,%s)"
        cursor.executemany(sql, data_to_load)
        conn.commit()
        print(f"   -> {cursor.rowcount} rows processed for stg_srilankan_financials.")
    except Exception as e:
        print(f"❌ Error loading stg_srilankan_financials: {e}"); conn.rollback(); raise

def _load_stg_worldbank_transport(conn, cursor, df):
    """Loads cleaned World Bank data into its staging table."""
    print("🔄 Loading stg_worldbank_transport...")
    try:
        data_to_load = _clean_df_for_db(df)
        cursor.execute("TRUNCATE TABLE stg_worldbank_transport")
        print("   -> Staging table truncated.")
        sql = "INSERT INTO stg_worldbank_transport (year, country_name, country_code, passengers) VALUES (%s,%s,%s,%s)"
        cursor.executemany(sql, data_to_load)
        conn.commit()
        print(f"   -> {cursor.rowcount} rows processed for stg_worldbank_transport.")
    except Exception as e:
        print(f"❌ Error loading stg_worldbank_transport: {e}"); conn.rollback(); raise

# --- Main Execution Block ---

def main():
    """Controls the full ELT process."""
    print("=" * 60)
    print("SriLankan Airlines Data Warehouse ELT Process")
    print(" (Reading from Excel)")
    print("=" * 60)
    
    # --- Step 1: EXTRACT ---
    raw_datasets = extract()
    if not raw_datasets: 
        return False
        
    # --- Step 2: TRANSFORM (for Staging) ---
    transformed_datasets = transform(raw_datasets)
    if not transformed_datasets: 
        return False
        
    # --- Step 3: LOAD (to Staging) ---
    load_success = load(transformed_datasets)
    if not load_success:
        return False
        
    # --- Step 4: TRANSFORM (Staging to Warehouse) ---
    # <-- MODIFIED: Call the new warehouse transform step
    transform_success = run_warehouse_transforms()
    if not transform_success:
        return False
        
    return True # Return True only if all steps succeed

if __name__ == "__main__":
    try:
        if main():
            print("\n🎉 Full ELT process completed successfully!")
        else:
            print("\n❌ ELT process failed! Please check the error messages above.")
    except Exception as e:
        print(f"\n❌ A CRITICAL, UNEXPECTED ERROR OCCURRED: {e}")
    finally:
        print("\n" + "=" * 60)