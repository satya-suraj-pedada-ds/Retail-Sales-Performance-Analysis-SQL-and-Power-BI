# Retail-Sales-Performance-Analysis-SQL-and-Power-BI
End-to-end supermarket sales analysis using MySQL and Power BI. Includes data quality validation, KPI reporting, product &amp; customer insights, operational patterns, and clear documentation of dataset limitations (1,000 invoices | 3 branches | Jan–Mar 2019). Designed for Junior Data Analyst / Apprenticeship roles.

Built for **Google Data Analyst Apprenticeship / Junior Data Analyst** roles at companies like Google, Amazon, and American Express.

---

## 1. Project Overview

This project analyzes supermarket sales performance across three branches (Yangon, Mandalay, Naypyitaw) using SQL for data preparation & analysis and Power BI for interactive dashboards.

**Key Focus Areas:**
- Revenue & product performance
- Customer segmentation (Member vs Normal)
- Time & operational patterns (hourly, daily, weekday/weekend)
- Data quality & project limitations (transparency)

**Important Note:**  
This is a **public sample dataset**. Insights are directional only and should not be treated as full business strategy recommendations.

---

## 2. Tools & Skills Demonstrated

| Category              | Tools / Techniques Used                          |
|-----------------------|--------------------------------------------------|
| Data Source           | Public supermarket transactions CSV              |
| Database              | MySQL                                            |
| Data Preparation      | Data quality checks, feature engineering         |
| Analysis              | Aggregations, Window functions, CTEs, Ranking    |
| Visualization         | Power BI (KPIs, charts, heatmaps, drill-down)    |
| Best Practices        | Clear limitations, Insight + Action comments     |

---

## 3. Repository Structure
```text
Retail-Sales-Performance-Analysis-SQL-and-Power-BI/
├── README.md
├── Data/
│   └── supermarket_sales_2019.csv
├── MySQL Workbench/
│   └── Super Market_Sales Retail.sql
├── BI Dashboards/
│   └── Supermarket_RetailSales_Analysis.pbix
└── BI Dashboard Images/
├── Dashboard-1 Supermarket Retail Performance Overview.jpg
├── Dashboard-2 Product Performance & Customer Insights.jpg
├── Dashboard-3 Time & Operational Insights.jpg
├── Dashboard-4 Detailed Transaction Explorer.jpg
└── Dashboard-5 Data Quality & Project Limits.jpg
```



---

## 4. Dataset Summary

| Attribute              | Value                                      |
|------------------------|--------------------------------------------|
| Total Invoices         | 1,000                                      |
| Date Range             | 01 Jan 2019 – 30 Mar 2019                  |
| Branches               | 3 (Yangon, Mandalay, Naypyitaw)            |
| Product Lines          | 6                                          |
| Customer Types         | Member, Normal                             |
| Payment Methods        | Cash, Ewallet, Credit card                 |

**Key Limitation:**  
No unique `customer_id` is available → true loyalty / retention analysis is not possible.  
`gross_margin_percentage` is almost constant (~4.76%) and is **not** treated as a real KPI.

---

## 5. SQL Analysis Highlights

The SQL file includes:

- Data quality checks (nulls, duplicates, range validation, business rule consistency)
- Feature engineering (Time of Day, Day Name, Weekend Flag, Basket Size, Spend Tier)
- Window functions (RANK, LAG, Running Total, NTILE)
- 2 clean CTEs
- 15+ business questions with **Insight + Action** comments
- Executive Summary of key findings

**Sample Insights from SQL:**
- Naypyitaw leads in revenue, but the gap between cities is relatively small.
- Food & Beverages is the top product line by revenue.
- Some high-revenue product lines have below-average ratings (priority for quality review).
- Afternoon and Evening periods generate the majority of revenue.
- Large baskets contribute significantly higher Average Order Value.

---

## 6. Power BI Dashboards

Five professional dashboards were created:

| Page | Title                              | Focus Area                                      |
|------|------------------------------------|-------------------------------------------------|
| 1    | Supermarket Retail Performance Overview | Executive KPIs + high-level performance        |
| 2    | Product Performance & Customer Insights | Product ranking, rating quality, customer segments |
| 3    | Time & Operational Insights        | Hourly, daily, and weekday/weekend patterns    |
| 4    | Detailed Transaction Explorer      | Invoice-level drill-down                       |
| 5    | Data Quality & Project Limits      | Transparency on data quality and limitations   |

**Dashboard Design Principles:**
- Consistent layout and color theme
- Clear titles and insight boxes
- Honest disclaimers on every page
- Focus on actionable observations rather than over-claiming

---

## 7. Key Business Findings

1. **City Performance:** Naypyitaw has the highest revenue, but differences across the three cities are not large.
2. **Product Performance:** Food & Beverages leads in revenue. Some high-selling products (especially Home & Lifestyle) have below-average ratings.
3. **Customer Behavior:** Member customers show slightly higher Average Order Value than Normal customers.
4. **Time Patterns:** Afternoon and Evening are the strongest revenue periods. Peak hour is typically around 19:00.
5. **Basket Size:** Large baskets generate significantly higher revenue and Average Order Value.
6. **Payment Methods:** Cash, Ewallet, and Credit card are relatively evenly used.

---

## 8. How to Use This Project

1. **SQL File**  
   Open `sql/Super Market_Sales Retail.sql` in MySQL Workbench and run the scripts sequentially.

2. **Power BI File**  
   Open `power-bi/Supermarket_RetailSales_Analysis.pbix` in Power BI Desktop.  
   (Update the data source path if required)

3. **Dashboard Images**  
   Preview the final dashboards in the `dashboard-images/` folder.

---

## 9. Project Limitations (Important)

- Public sample dataset only (not company internal data)
- Only 1,000 invoices and 3 months of data
- Only 3 branches
- No customer-level unique ID
- Insights are **directional** and should be validated with larger datasets

---

## 10. Author

**Satya Suraj Pedada**  
M.Tech Data Science  
Aspiring Data Analyst / Data Scientist  

- GitHub: https://github.com/satya-suraj-pedada-ds
- LinkedIn: https://www.linkedin.com/in/satya-suraj-pedada-773239305/
- Email: surajmtechds24@gmail.com

---

## 11. Acknowledgments

- Public supermarket sales dataset used for learning and demonstration purposes.
- Project developed to demonstrate end-to-end analytical thinking suitable for Junior Data Analyst and Apprenticeship roles.

