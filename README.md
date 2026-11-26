# Geo-Spatial Supply Chain & Inventory Intelligence

An End-to-End Data Analytics Project using the **Olist Brazilian E-Commerce Public Dataset** to analyze e-commerce sales, product performance, seller distribution, delivery efficiency, customer behavior, and payment trends across Brazil.

---

## Project Overview

This project focuses on analyzing the Brazilian e-commerce marketplace using Python, MySQL, Excel, and Power BI.

The objective is to transform raw e-commerce data into meaningful business insights through data cleaning, exploratory data analysis, SQL business analysis, KPI development, and interactive dashboard development.

The project follows an end-to-end Data Analyst workflow, from raw data preparation to business intelligence reporting.

## Project Objectives

- Analyze overall e-commerce sales and revenue performance.
- Understand product and category-level sales trends.
- Explore seller distribution across Brazilian states and cities.
- Evaluate delivery performance and logistics efficiency.
- Analyze customer purchasing behavior.
- Understand payment preferences and customer review patterns.
- Develop interactive Power BI dashboards to communicate business insights.

## Tools & Technologies

| Tool | Purpose |
|---|---|
| Python | Data cleaning and exploratory analysis |
| Pandas & NumPy | Data manipulation and preprocessing |
| Matplotlib & Seaborn | Data visualization |
| MySQL | Database management and SQL analysis |
| Excel | Supporting data analysis and documentation |
| Power BI | Interactive dashboards and reporting |
| DAX | KPI and analytical measure development |
| Git & GitHub | Version control and project hosting |

## Dataset Information

**Dataset Name:** Olist Brazilian E-Commerce Public Dataset

**Source:** [Kaggle – Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)

The dataset contains information about Brazilian marketplace transactions, including:

- Customers
- Orders
- Order Items
- Products
- Sellers
- Payments
- Reviews
- Geolocation
- Product Category Translation

### Original Dataset Size

| Dataset | Records |
|---|---:|
| Orders | 99,441 |
| Order Items | 112,650 |
| Products | 32,951 |
| Sellers | 3,095 |
| Customers | 99,441 |
| Geolocation | 1,000,163 |
| Payments | 103,886 |
| Reviews | 99,224 |
| Category Translation | 71 |

## Project Workflow

1. Data Collection – Obtained the Olist Brazilian E-Commerce dataset.
2. Data Cleaning – Performed data quality checks, handled date fields, and prepared datasets using Python.
3. Exploratory Data Analysis – Analyzed sales, products, sellers, customers, and delivery performance.
4. Database Development – Imported the datasets into MySQL.
5. SQL Business Analysis – Executed business queries to identify trends and key performance indicators.
6. Excel Analysis – Prepared supporting analysis workbooks and data documentation.
7. Power BI Development – Built interactive dashboards using DAX measures, KPIs, charts, maps, and slicers.
8. Dashboard Reporting – Organized the analysis into five business-focused dashboard pages.

## Power BI Dashboard

The interactive Power BI dashboard consists of **five analytical pages**.

### 1. Executive Overview

Provides a high-level overview of marketplace performance, including total orders, revenue, customers, sellers, average order value, monthly revenue trends, geographical distribution, and order status.

![Executive Overview](images/Dashboard%20Page%201.png)

### 2. Sales & Product Intelligence

Analyzes product sales, category performance, monthly sales trends, top-performing product categories, average item prices, and freight costs.

![Sales & Product Intelligence](images/Dashboard%20Page%202.png)

### 3. Geographic & Seller Intelligence

Explores seller distribution across Brazilian states and cities, seller contribution, geographical sales performance, and monthly seller activity.

![Geographic & Seller Intelligence](images/Dashboard%20Page%203.png)

### 4. Delivery & Logistics Performance

Evaluates delivery efficiency, on-time and late deliveries, average delivery duration, estimated versus actual delivery time, and delivery status distribution.

![Delivery & Logistics Performance](images/Dashboard%20Page%204.png)

### 5. Customer & Payment Insights

Analyzes unique customers, customer growth, average order value, payment preferences, revenue by payment type, and customer review score distribution.

![Customer & Payment Insights](images/Dashboard%20Page%205.png)

## Key Business Findings

Based on the project analysis:

| Metric | Result |
|---|---:|
| Total Orders | 99,441 |
| Unique Customers | 96,096 |
| Marketplace Sellers | 3,095 |
| Total Payment Value | R$16.01 Million |
| Total Product Value | R$13.59 Million |
| Average Order Value | R$160.99 |
| Average Delivery Time | 12.56 Days |
| Average Review Score | 4.09 |

### Additional Insights

- São Paulo is the largest customer market by order volume.
- Health & Beauty is the leading product category by product sales value.
- Credit cards account for approximately 78.3% of total payment value.
- Approximately 91.9% of orders with valid delivery timestamps were delivered on time.

## Repository Structure

```text
Geo-Spatial-Supply-Chain-Analytics/
│
├── data/
│   ├── processed/
│   │   ├── category_summary.csv
│   │   ├── data_quality_report.csv
│   │   ├── monthly_orders.csv
│   │   ├── product_summary.csv
│   │   ├── seller_city_summary.csv
│   │   ├── seller_state_summary.csv
│   │   └── seller_summary.csv
│   │
│   ├── raw/                 (Excluded from Git)
│   └── cleaned/             (Excluded from Git)
│
├── Python/
│   └── Supply_Chain_Analysis.ipynb
│
├── SQL/
│   ├── 01_Database_Setup.sql
│   ├── 02_Business_Analysis_Queries.sql
│   ├── Project4_Complete_SQL_Analysis_25_Queries.sql
│   ├── Project4_SQL_Queries_26_to_43_Run_All.sql
│   └── Documentation/
│
├── Excel/
│   ├── Inventory_Reorder_and_Data_Dictionary.xlsx
│   └── Project4_SupplyChain_Excel_Analysis.xlsx
│
├── PowerBI/
│   └── Project 4 Complete Dashboard.pbix
│
├── Documentation/
│   ├── data_dictionary.csv
│   └── PROJECT_PROGRESS.md
│
├── images/
│   ├── Dashboard Page 1.png
│   ├── Dashboard Page 2.png
│   ├── Dashboard Page 3.png
│   ├── Dashboard Page 4.png
│   └── Dashboard Page 5.png
│
├── .gitignore
└── README.md
```

## Important Dataset Limitation

The Olist dataset contains historical marketplace transaction data. It does not provide actual warehouse stock levels, stock-out records, supplier lead times, purchase orders, safety stock, or real-time inventory information.

Therefore:

- Seller analysis refers to marketplace sellers, not upstream suppliers.
- Inventory and reorder planning in the supporting Excel workbook should be treated as hypothetical or illustrative where assumptions are used.
- The project does not claim to measure actual warehouse inventory or stock availability.

## Project Deliverables

- Python Jupyter Notebook for data cleaning and exploratory analysis.
- SQL scripts for database setup and business analysis.
- Excel workbooks for supporting analysis and documentation.
- Processed CSV datasets.
- Interactive Power BI dashboard with five analytical pages.
- Project documentation and data dictionary.

## Skills Demonstrated

- Data Cleaning & Preprocessing
- Exploratory Data Analysis (EDA)
- Python Data Analysis
- SQL Query Writing
- Database Management
- Business Intelligence
- DAX Measures & KPI Development
- Data Visualization
- Dashboard Design
- Business Insights & Reporting

## Project Objective

To demonstrate practical Data Analyst skills by completing an end-to-end analytics project involving data preparation, database management, business analysis, KPI development, and interactive reporting.

---

**Dataset:** Olist Brazilian E-Commerce Public Dataset  
**Tools:** Python | MySQL | Excel | Power BI  
**Project Type:** End-to-End Data Analytics  
