sh# Sri Lankan Airlines Data Warehouse & Analytics

This project is a complete end-to-end data engineering solution that builds a data warehouse for Sri Lankan air travel analytics. It follows a modern **ELT (Extract, Load, Transform)** process, pulling raw, unclean data from multiple sources, loading it into a staging area, and then transforming it into a clean, query-ready **Galaxy Schema** for business intelligence.

This data warehouse integrates passenger movements from the CAA, financial metrics from SriLankan Airlines' annual reports, and global context from the World Bank.


<img width="1203" height="622" alt="Screenshot 2025-10-25 143158" src="https://github.com/user-attachments/assets/d82dd0e1-e565-4dc0-b73c-6ac351764942" />

*(Recommended: Replace this with a screenshot of your Power BI Model view)*

---

## 🚀 Key Features

* **ELT Pipeline:** A robust Python script using `pandas` and `PyMySQL` extracts data from raw Excel files, loads it into a staging database, and then executes SQL-based transformations.
* **Data Warehouse:** The final model is a **Galaxy Schema** (Fact Constellation) with multiple fact tables sharing conformed dimensions.
* **Business Intelligence:** The warehouse is connected to a Power BI report, featuring interactive visualizations and answering key business questions.
* **Data Cleaning:** The Python script includes extensive cleaning logic to handle inconsistent dates, currency symbols, missing values, and other "dirty" data.

---

<img width="1024" height="1024" alt="Gemini_Generated_Image_mk7m6imk7m6imk7m" src="https://github.com/user-attachments/assets/76d35351-38f7-4695-8242-703ca37f9ce9" />


## 🏛️ Data Warehouse Schema (Galaxy Schema)

The final model consists of multiple fact tables sharing conformed dimensions, which allows for robust, cross-functional analysis.

### Dimension Tables (The "Context")

* **`dim_date`**: A central date dimension that links all fact tables. Contains `year`, `month`, `quarter`, `month_name`, etc.
* **`dim_airport`**: Stores information about airports, such as `iata_code` and `country`.
* **`dim_country`**: Stores global country data, including `country_code` and `country_name`.
* **`dim_metric`**: Stores financial and operational metric names, like "Revenue" or "Passenger Count".

### Fact Tables (The "Measurements")

* **`fact_passenger_movements`**: Records monthly passenger and aircraft movement data from the CAA.
    * *Links to: `dim_date`, `dim_airport`*
* **`fact_airline_financials`**: Records annual financial and operational metrics for the airline.
    * *Links to: `dim_date`, `dim_metric`*
* **`fact_world_transport_stats`**: Records annual air transport passenger data from the World Bank.
    * *Links to: `dim_date`, `dim_country`*

---

## 🛠️ Tech Stack

* **Data Pipeline:** Python
* **Data Handling:** `pandas`, `openpyxl`
* **Database:** MySQL (local)
* **DB Connector:** `PyMySQL`, `mysql-connector-python`
* **Visualization:** Power BI

---

## 📁 Project Structure

This project uses a standard data engineering structure to separate concerns.

```
SriLankan_Airlines_DW/
│
├── .gitignore
├── LICENSE
├── README.md                <-- You are here
├── requirements.txt         <-- Python libraries to install
│
├── data/
│   └── raw/                 <-- All source Excel files
│         ├── caa_passenger_movements_unclean.xlsx
│         ├── srilankan_annual_report_unclean.xlsx
│         └── worldbank_air_transport_unclean.xlsx
│
├── reports/
│   └── Srilankan_Airlines_Analysis.pbix  <-- Power BI report file
│
├── src/
│   └── etl.py               <-- The main Python ELT script
│
└── sql/
    ├── ddl/                 <-- (Data Definition) All CREATE TABLE scripts
    │     ├── 01_create_staging_tables.sql
    │     ├── 02_create_dimension_tables.sql
    │     └── 03_create_fact_tables.sql
    │
    └── analysis/
          └── business_queries.sql  <-- Sample queries for analysis
```

---

## 🚀 How to Run This Project

Follow these steps to build the data warehouse on your local machine.

### Prerequisites

* Python 3.8+
* A local MySQL server (e.g., MySQL Community Server, MariaDB)
* Power BI Desktop (optional, for viewing the report)

### 1. Clone the Repository

```bash
git clone [https://github.com/ghdbashen/SriLankan_Airlines_DW.git](https://github.com/ghdbashen/SriLankan_Airlines_DW.git)
cd SriLankan_Airlines_DW
```

### 2. Set Up the Environment

1.  **Create a virtual environment (recommended):**
    ```bash
    python -m venv venv
    source venv/bin/activate  # On Windows: venv\Scripts\activate
    ```

2.  **Install the required Python libraries:**
    ```bash
    pip install -r requirements.txt
    ```

### 3. Set Up the Database

1.  **Access your local MySQL server:**
    ```sql
    mysql -u root -p
    ```

2.  **Create the database:**
    ```sql
    CREATE DATABASE dw_srilankan;
    USE dw_srilankan;
    ```

3.  **Run the DDL scripts** to create all your tables. You can run the SQL files from the `sql/ddl/` folder in this order:
    1.  `01_create_staging_tables.sql`
    2.  `02_create_dimension_tables.sql`
    3.  `03_create_fact_tables.sql`

### 4. Configure the ELT Script

1.  Open the `src/etl.py` file.
2.  Find the `DB_CONFIG` dictionary at the top.
3.  Update the `user` and `password` to match your local MySQL credentials.

### 5. Run the ELT Pipeline

1.  Make sure you are in the project's root directory.
2.  Execute the Python script:

    ```bash
    python src/etl.py
    ```

The script will:
* **Extract** data from the Excel files in `data/raw/`.
* **Load** this raw data into the `stg_...` tables.
* **Transform** the data from the staging tables into the final `dim_...` and `fact_...` tables.

You can verify the data by connecting to your `dw_srilankan` database with a tool like MySQL Workbench or DBeaver.

---

## 📊 Business Analysis & Queries

The final data warehouse can answer complex business questions. You can find these queries in `sql/analysis/business_queries.sql`.

### Example Business Questions:

1.  **What is the total passenger traffic by airport?**
    ```sql
    SELECT
        a.iata_code AS Airport,
        SUM(f.passengers) AS Total_Passengers
    FROM fact_passenger_movements f
    JOIN dim_airport a ON f.airport_key = a.airport_key
    GROUP BY a.iata_code
    ORDER BY Total_Passengers DESC;
    ```

2.  **How do Sri Lanka's annual passengers (World Bank) compare to its neighbors?**
    ```sql
    SELECT
        d.year AS Year,
        c.country_name AS Country,
        f.passengers AS Total_Passengers
    FROM fact_world_transport_stats f
    JOIN dim_country c ON f.country_key = c.country_key
    JOIN dim_date d ON f.date_key = d.date_key
    WHERE
        c.country_name IN ('Sri Lanka', 'India', 'Maldives', 'Bangladesh')
    ORDER BY
        c.country_name, d.year;
    ```

3.  **What are the key financial vs. operational metrics for the airline?**
    ```sql
    SELECT
        d.year AS Year,
        m.metric_name AS Metric,
        f.value AS Value,
        f.currency AS Currency
    FROM fact_airline_financials f
    JOIN dim_metric m ON f.metric_key = m.metric_key
    JOIN dim_date d ON f.date_key = d.date_key
    WHERE
        d.year IN (2022, 2023)
    ORDER BY
        d.year, m.metric_name;
    ```
