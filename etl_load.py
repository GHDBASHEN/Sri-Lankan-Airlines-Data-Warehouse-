# ==============================================================================
# SCRIPT START: COPY EVERYTHING BELOW THIS LINE
# ==============================================================================
import os
import pandas as pd
import traceback

# --- The Fix for Silent Crashing ---
try:
    import pymysql
    import mysql.connector
    from mysql.connector import errorcode
    mysql.connector.connect = pymysql.connect
except ImportError:
    print("❌ CRITICAL ERROR: The 'PyMySQL' or 'mysql-connector-python' library is not installed.")
    print("   Please run 'pip install PyMySQL mysql-connector-python pandas' in your terminal.")
    exit()

# --- Configuration ---
DB_CONFIG = {
    'host': 'hacktrail3.mysql.database.azure.com',
    'user': 'dilshan',
    'password': 'Pathum@2001',
    'database': 'dw_srilankan',
    'connect_timeout': 20,
    'ssl_ca': './DigiCertGlobalRootG2.crt.pem' # <-- ADD THIS LINE
}

# --- ETL Pipeline ---

def extract():
    """Extract Phase: Reads data from all source CSV files."""
    print("\n--- 1. EXTRACT ---")
    print("Reading data from source CSV files...")
    dataframes = {}
    csv_files = {
        "dim_airport": "airports.csv", "dim_aircraft": "aircraft.csv",
        "dim_flight": "flights_meta.csv", "dim_passenger": "passengers.csv",
        "fact_flights": "flights_occurrences.csv"
    }
    try:
        for name, path in csv_files.items():
            if not os.path.exists(path):
                print(f"❌ ERROR: File not found: {path}"); return None
            # IMPORTANT: Keep empty values as empty strings, don't default them to NaN
            dataframes[name] = pd.read_csv(path, na_filter=False)
            print(f"✅ Read {len(dataframes[name])} rows from {path}")
        return dataframes
    except Exception as e:
        print(f"❌ EXTRACT ERROR: Could not read CSV files. Details: {e}"); return None

def transform(raw_data):
    """Transform Phase: Cleans and prepares the data."""
    if not raw_data: return None
    print("\n--- 2. TRANSFORM ---")
    print("Cleaning and preparing data for loading...")
    try:
        ff_df = raw_data['fact_flights']
        ff_df['delay_arrival_minutes'] = pd.to_numeric(ff_df['delay_arrival_minutes'], errors='coerce').fillna(16)
        ff_df['ontime_flag'] = (ff_df['delay_arrival_minutes'] <= 15).astype(int)
        ff_df['date_key'] = pd.to_datetime(ff_df['date']).dt.strftime('%Y%m%d').astype(int)
        print("✅ Transformations complete.")
        return raw_data
    except Exception as e:
        print(f"❌ TRANSFORM ERROR: {e}"); return None

def load(transformed_data):
    """Load Phase: Connects to the DB and loads all data using efficient batch methods."""
    if not transformed_data: return False
    print("\n--- 3. LOAD ---")
    print("Connecting to the database...")
    
    conn = None
    try:
        conn = mysql.connector.connect(**DB_CONFIG)
        cursor = conn.cursor()
        print("✅ Database connection successful. Starting data load...")

        _load_dim_date(conn, cursor)
        _load_dim_airport(conn, cursor, transformed_data['dim_airport'])
        _load_dim_aircraft(conn, cursor, transformed_data['dim_aircraft'])
        _load_dim_flight(conn, cursor, transformed_data['dim_flight'])
        _load_dim_passenger(conn, cursor, transformed_data['dim_passenger'])
        _load_fact_flights(conn, cursor, transformed_data['fact_flights'])

        print("\n✅ All data loaded successfully.")
        return True
    except Exception as e:
        print(f"❌ An unexpected error occurred during the LOAD phase.")
        traceback.print_exc() # Print full error for debugging
        if conn: conn.rollback()
        return False
    finally:
        if conn:
            cursor.close()
            conn.close()
            print("\n🔌 Database connection closed.")

# --- HELPER FUNCTIONS with ROBUST NaN FIX ---

def _clean_df_for_db(df):
    """
    Converts a DataFrame into a list of tuples for database insertion.
    THE KEY FIX IS HERE: It replaces any pandas NaN/NaT and empty strings with None.
    """
    df_clean = df.replace({pd.NaT: None, '': None})
    return [tuple(x) for x in df_clean.to_numpy()]

def _load_dim_date(conn, cursor, start_date='2015-01-01', end_date='2030-12-31'):
    print("🔄 Populating dim_date...")
    try:
        dates = pd.date_range(start=start_date, end=end_date, freq='D')
        date_data = [(int(d.strftime("%Y%m%d")), d.strftime("%Y-%m-%d"), d.year, (d.month-1)//3+1, d.month, d.day, d.isoweekday(), 1 if d.isoweekday()>=6 else 0) for d in dates]
        sql = "INSERT IGNORE INTO dim_date (date_key, full_date, year, quarter, month, day, day_of_week, is_weekend) VALUES (%s,%s,%s,%s,%s,%s,%s,%s)"
        cursor.executemany(sql, date_data)
        conn.commit()
        print(f"   -> {cursor.rowcount} new rows inserted into dim_date.")
    except Exception as e:
        print(f"❌ Error populating dim_date: {e}"); conn.rollback(); raise

def _load_dim_airport(conn, cursor, df):
    print("🔄 Loading dim_airport...")
    try:
        airport_data = _clean_df_for_db(df)
        sql = "INSERT INTO dim_airport (iata, icao, name, city, country, latitude, longitude, timezone) VALUES (%s,%s,%s,%s,%s,%s,%s,%s) ON DUPLICATE KEY UPDATE name=VALUES(name)"
        cursor.executemany(sql, airport_data)
        conn.commit()
        print(f"   -> {cursor.rowcount} rows processed for dim_airport.")
    except Exception as e:
        print(f"❌ Error loading dim_airport: {e}"); conn.rollback(); raise

def _load_dim_aircraft(conn, cursor, df):
    print("🔄 Loading dim_aircraft...")
    try:
        aircraft_data = _clean_df_for_db(df)
        sql = "INSERT INTO dim_aircraft (tail_number, model, manufacturer, seating_capacity, effective_from, effective_to, is_current) VALUES (%s,%s,%s,%s,%s,%s,1) ON DUPLICATE KEY UPDATE model=VALUES(model)"
        cursor.executemany(sql, aircraft_data)
        conn.commit()
        print(f"   -> {cursor.rowcount} rows processed for dim_aircraft.")
    except Exception as e:
        print(f"❌ Error loading dim_aircraft: {e}"); conn.rollback(); raise

def _load_dim_flight(conn, cursor, df):
    print("🔄 Loading dim_flight...")
    try:
        flight_data = _clean_df_for_db(df)
        sql = "INSERT INTO dim_flight (carrier_code, flight_number, published_duration_minutes, aircraft_type_default) VALUES (%s,%s,%s,%s) ON DUPLICATE KEY UPDATE published_duration_minutes=VALUES(published_duration_minutes)"
        cursor.executemany(sql, flight_data)
        conn.commit()
        print(f"   -> {cursor.rowcount} rows processed for dim_flight.")
    except Exception as e:
        print(f"❌ Error loading dim_flight: {e}"); conn.rollback(); raise

def _load_dim_passenger(conn, cursor, df):
    print("🔄 Loading dim_passenger...")
    try:
        passenger_data = _clean_df_for_db(df)
        sql = "INSERT INTO dim_passenger (passenger_id_external, first_name, last_name, gender, dob, country) VALUES (%s,%s,%s,%s,%s,%s) ON DUPLICATE KEY UPDATE first_name=VALUES(first_name)"
        cursor.executemany(sql, passenger_data)
        conn.commit()
        print(f"   -> {cursor.rowcount} rows processed for dim_passenger.")
    except Exception as e:
        print(f"❌ Error loading dim_passenger: {e}"); conn.rollback(); raise

def _load_fact_flights(conn, cursor, df):
    print("🔄 Loading fact_flights...")
    try:
        cursor.execute("SELECT CONCAT(carrier_code, '-', flight_number), flight_key FROM dim_flight")
        flight_key_lookup = {row[0]: row[1] for row in cursor.fetchall()}
        
        df_clean = df.replace({pd.NaT: None, '': None})
        fact_data_to_insert = []
        for _, r in df_clean.iterrows():
            flight_lookup_str = f"{r['carrier_code']}-{r['flight_number']}"
            flight_key = flight_key_lookup.get(flight_lookup_str)
            if not flight_key: continue
            
            fact_data_to_insert.append((
                flight_key, r.get('aircraft_key'), r['date_key'], r.get('scheduled_dep_time'), r.get('scheduled_arr_time'),
                r.get('actual_dep_time'), r.get('actual_arr_time'), r.get('origin_airport_key'), r.get('dest_airport_key'),
                r.get('distance_km'), r.get('seats_offered'), r.get('seats_occupied'), r.get('cancellations', 0),
                r.get('delay_departure_minutes'), r.get('delay_arrival_minutes'), r['ontime_flag'], r.get('load_factor')
            ))
        
        sql = "INSERT INTO fact_flights (flight_key, aircraft_key, date_key, scheduled_dep_time, scheduled_arr_time, actual_dep_time, actual_arr_time, origin_airport_key, dest_airport_key, distance_km, seats_offered, seats_occupied, cancellations, delay_departure_minutes, delay_arrival_minutes, ontime, load_factor) VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)"
        cursor.executemany(sql, fact_data_to_insert)
        conn.commit()
        print(f"   -> {cursor.rowcount} rows processed for fact_flights.")
    except Exception as e:
        print(f"❌ Error loading fact_flights: {e}"); conn.rollback(); raise

# --- Main Execution Block ---

def main():
    """Controls the ETL process."""
    print("=" * 60)
    print("SriLankan Airlines Data Warehouse ETL Process")
    print("=" * 60)
    
    raw_datasets = extract()
    if not raw_datasets: return False
        
    transformed_datasets = transform(raw_datasets)
    if not transformed_datasets: return False
        
    return load(transformed_datasets)

if __name__ == "__main__":
    try:
        if main():
            print("\n🎉 ETL process completed successfully!")
        else:
            print("\n❌ ETL process failed! Please check the error messages above.")
    except Exception as e:
        print(f"\n❌ A CRITICAL, UNEXPECTED ERROR OCCURRED: {e}")
    finally:
        print("\n" + "=" * 60)
        input("Press Enter to exit...")

# ==============================================================================
# SCRIPT END: COPY EVERYTHING ABOVE THIS LINE
# ==============================================================================