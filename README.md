# 🛡️ SENTINEL — Retail Business Health & Risk Analytics

SENTINEL is an end-to-end **Retail Business Health and Early-Risk Analytics System** built using **SQL Server and Power BI**.

Unlike a traditional retail dashboard that only reports sales and profit, SENTINEL evaluates multiple areas of business performance and identifies stores that may be developing operational or financial risks.

The system analyzes seven major business-health dimensions and converts them into a unified **Business Health Score**.

---

## 🎯 Project Objective

The objective of SENTINEL is to answer questions such as:

- Which stores are becoming risky?
- Why is a particular store underperforming?
- Is revenue declining?
- Are discounts damaging profitability?
- Are product returns increasing?
- Are stores experiencing inventory shortages?
- Is customer retention deteriorating?
- Are customer ratings falling?
- Are complaints increasing or taking too long to resolve?

The goal is to help management identify problems earlier instead of only analyzing historical performance.

---

## 🛠️ Tech Stack

- **SQL Server**
- **SQL Server Management Studio (SSMS)**
- **Power BI Desktop**
- **DAX**
- **Power Query**
- **GitHub**

---

## 🏗️ Project Architecture

```text
Retail Transaction Data
        ↓
   SQL Server
        ↓
Data Cleaning & Analysis
        ↓
Risk Analysis
        ↓
Component Scoring
        ↓
Business Health Score
        ↓
StoreHealthScores Table
        ↓
     Power BI
        ↓
Executive Risk Overview
        ↓
Store Risk Deep Dive
```
🔍 Business Risk Areas
SENTINEL evaluates seven major dimensions of store health.
1. Revenue Risk
Analyzes monthly net revenue and month-over-month revenue growth.
The analysis also detects consecutive periods of negative revenue growth to identify possible revenue deterioration.
Key SQL techniques:
- SUM()
- LAG()
- CTEs
- Window functions
- Month-over-month calculations
2. Profitability & Discount Dependency
Measures:
- Net Revenue
- Gross Profit
- Profit Margin %
- Discounted Revenue %
- Discount Amount
The analysis identifies situations where sales may remain strong while profitability deteriorates because of excessive discounting.
3. Return Risk
Measures:
- Units Sold
- Units Returned
- Return Rate %
- High-return categories
- High-return products
- Return reasons
This helps identify whether specific stores, categories or products are experiencing abnormal return behavior.
4. Inventory Risk
Measures:
- Out-of-Stock %
- Below-Reorder %
- Repeated Stockouts
- Products repeatedly below reorder level
The analysis also compares sales activity before and during inventory-risk periods to investigate whether poor product availability coincides with weaker sales performance.
5. Customer Retention Risk
Customer retention is calculated by identifying customers from the previous month who purchase again in the following month.
Metrics include:
- Previous Month Customers
- Retained Customers
- Lost Customers
- Retention Rate %
This provides a more meaningful retention measure than simply counting returning customers.
6. Customer Satisfaction Risk
Uses customer review data to monitor:
- Average Rating
- Review Count
- Previous Month Rating
- Rating Change
Low ratings with sufficient review volume are flagged as potential satisfaction risks.
7. Complaint Risk
Measures:
- Complaints per 100 Orders
- Average Resolution Days
- Open Complaints
- Escalated Complaints
Normalizing complaints per 100 orders allows stores with different transaction volumes to be compared more fairly.
🧠 Business Health Scoring System
Each store receives seven component scores ranging from 0 to 100.
Component	Weight
Revenue	20%
Profitability	15%
Returns	15%
Inventory	15%
Customer Retention	15%
Customer Satisfaction	10%
Complaints	10%


The final score is calculated as:
Business Health Score =

Revenue Score × 20%
+ Profitability Score × 15%
+ Return Score × 15%
+ Inventory Score × 15%
+ Retention Score × 15%
+ Satisfaction Score × 10%
+ Complaint Score × 10%

These weights and thresholds are project business-rule assumptions created for the SENTINEL model. In a real organization, they would be calibrated using historical performance and stakeholder requirements.

🚦 Health Status Classification
Each store is classified into one of five health states:
CRITICAL
HIGH RISK
WARNING
STABLE
HEALTHY

SENTINEL does not rely only on the overall Business Health Score.
A store can also be escalated when an individual component becomes critically weak.
For example, a store with a reasonable overall score may still be classified as HIGH RISK if its Inventory Score, Return Score or another component falls to a critical level.
This prevents serious individual problems from being hidden by stronger performance in other areas.
⚠️ Main Risk Identification
SENTINEL automatically identifies the weakest component for each store.
Possible Main Risk categories include:
- Revenue
- Profitability / Discount
- Returns
- Inventory
- Customer Retention
- Customer Satisfaction
- Complaints
This allows management to understand not only which store is risky, but also why it is risky.
📊 Power BI Dashboard
The Power BI report contains two main analytical pages.
1. Executive Risk Overview
Provides management with a high-level view of business health across all stores.
Features include:
- Overall Business Health
- High Risk Store Count
- Warning Store Count
- Healthy Store Count
- Month-over-Month changes
- Bottom 10 Stores by Health Score
- Stores by Health Status
- Main Risk Distribution
- Store Risk Details
- Dynamic Key Insight
- Dynamic Recommended Action
- Year, Month, Region, State, City and Store filters
Dashboard Preview
2. Store Risk Deep Dive
Allows users to drill through from the Executive Overview and investigate a specific store.
Features include:
- Business Health Score
- Revenue Score
- Profitability Score
- Return Score
- Inventory Score
- Retention Score
- Satisfaction Score
- Complaint Score
- Historical Health Score Trend
- Component Score Comparison
- Health Status History
- Monthly Component Trends
- Risk Indicator Table
- Dynamic Key Risk Insight
- Dynamic Recommended Action
Dashboard Preview
 
🔎 Example Risk Investigations
During analysis, SENTINEL highlighted several different types of store-level risk.
Discount Dependency
One store showed very high dependence on discounted sales while its profit margin dropped significantly.
This demonstrated how revenue alone can hide profitability problems.
Increasing Product Returns
Another store experienced a noticeable increase in return rate.
Further analysis identified the categories, individual products and return reasons contributing to the issue.
Inventory Availability Risk
Inventory analysis identified stores with repeated stockouts and products remaining below reorder levels across multiple months.
Customer Satisfaction Decline
Review analysis identified periods where average customer ratings fell below acceptable levels while sufficient review volume was available.
These examples demonstrate how SENTINEL moves from:
Problem Detection
      ↓
Risk Identification
      ↓
Root Cause Investigation
      ↓
Recommended Action

💻 SQL Techniques Demonstrated
The project uses several SQL concepts including:
- Common Table Expressions (CTEs)
- Window Functions
- LAG()
- Conditional Aggregation
- CASE
- NULLIF()
- ISNULL()
- DATEFROMPARTS()
- DATEADD()
- Aggregate Functions
- Inner Joins
- Left Joins
- Multi-table analysis
- Month-over-Month calculations
- Customer cohort comparison
- Business-rule scoring
- Index creation
- Risk classification logic
📈 Power BI / DAX Skills Demonstrated
- Data Modeling
- One-to-Many Relationships
- DAX Measures
- Filter Context
- CALCULATE
- SELECTEDVALUE
- Dynamic Conditional Formatting
- Drill-through
- Dynamic KPI Cards
- Dynamic Colors
- Top/Bottom N Analysis
- Month-over-Month calculations
- Interactive Slicers
- Visual Interactions
- Dynamic Insights
- Dynamic Recommended Actions
📁 Repository Structure
```text
SENTINEL-Retail-Business-Health-Analytics/
│
├── README.md
│
├── SENTINEL.pbix
│
├── SQL/
│   ├── 01_database_setup.sql
│   ├── 02_revenue_analysis.sql
│   ├── 03_profitability_analysis.sql
│   ├── 04_return_risk.sql
│   ├── 05_inventory_risk.sql
│   ├── 06_customer_retention.sql
│   ├── 07_satisfaction_analysis.sql
│   ├── 08_complaint_analysis.sql
│   └── 09_store_health_scoring.sql
│
└── Screenshots/
    ├── executive_risk_overview.png
    └── store_risk_deep_dive.png
```

▶️ How to Explore the Project
SQL
Run the SQL scripts in numerical order:
01 → Database Setup
02 → Revenue Analysis
03 → Profitability Analysis
04 → Return Risk
05 → Inventory Risk
06 → Customer Retention
07 → Satisfaction Analysis
08 → Complaint Analysis
09 → Business Health Scoring

Power BI
Download:
SENTINEL_Retail_Business_Health_Analytics.pbix

and open it using Power BI Desktop.
🚀 Future Enhancements
Potential future versions of SENTINEL may include:
- Python-based anomaly detection
- Predictive risk modeling
- Revenue forecasting
- Automated risk alerts
- Product-level risk scoring
- Customer churn prediction
These are planned future enhancements and are not part of the current SQL + Power BI implementation.

📌 Project Summary
SENTINEL demonstrates how SQL and Power BI can be used not only for reporting historical performance, but also for building a structured business-risk monitoring system.
The project combines:

Data Analysis → Business Rules → Risk Scoring → Root Cause Analysis → Decision Support
