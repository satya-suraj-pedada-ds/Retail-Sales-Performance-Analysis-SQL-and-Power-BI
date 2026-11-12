/* =============================================================================
   PROJECT : Supermarket Retail Performance
   SOURCE  : Public supermarket transactions
             1,000 invoices | 3 branches | 01 Jan 2019 – 30 Mar 2019
             A-Yangon, B-Mandalay, C-Naypyitaw
   LIMIT   : Small 3-month sample. Do not over-claim.
             gross_margin_percentage is constant (~4.76%) — not a real KPI.
             1000 invoices, 3 branches, Jan-Mar 2019 only.
			 Branches and Member/Normal are almost even.
             Small differences are not a national strategy.
============================================================================= */

CREATE DATABASE  Super_Market_SalesRetail;
USE Super_Market_SalesRetail;

CREATE TABLE Sales_Retail_Table (
    invoice_id VARCHAR(30) NOT NULL PRIMARY KEY,
    branch VARCHAR(5) NOT NULL,
    city VARCHAR(30) NOT NULL,
    customer_type VARCHAR(30) NOT NULL,
    gender VARCHAR(10) NOT NULL,
    product_line VARCHAR(100) NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    quantity INT NOT NULL,
    VAT DECIMAL(10,4) NOT NULL,
    total DECIMAL(10,4) NOT NULL,
    date DATE NOT NULL,
    time TIME NOT NULL,
    payment_method VARCHAR(30) NOT NULL,
    cogs DECIMAL(10,2) NOT NULL,
    gross_margin_percentage DECIMAL(11,9) NOT NULL,
    gross_income DECIMAL(10,4) NOT NULL,
    rating DECIMAL(4,1) NOT NULL
);

SHOW VARIABLES LIKE 'secure_file_priv';

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/supermarket_sales_2019.csv'
INTO TABLE Sales_Retail_Table
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(invoice_id, branch, city, customer_type, gender, product_line,
 unit_price, quantity, VAT, total, @date, time, payment_method,
 cogs, gross_margin_percentage, gross_income, rating)
SET date = STR_TO_DATE(@date, '%Y-%m-%d');

SELECT * FROM Sales_Retail_Table LIMIT 10;
SHOW COLUMNS FROM Sales_Retail_Table;
SELECT COUNT(*) AS row_count FROM Sales_Retail_Table;


-- preprocessing --
-- Names/types are already correct from CREATE TABLE + LOAD DATA.
-- Do not rename `Invoice ID`. That column does not exist here.

-- 1. Null audit
SELECT * FROM Sales_Retail_Table
WHERE invoice_id IS NULL OR branch IS NULL OR city IS NULL OR customer_type IS NULL
    OR gender IS NULL OR product_line IS NULL OR unit_price IS NULL OR quantity IS NULL
    OR VAT IS NULL OR total IS NULL OR date IS NULL OR time IS NULL
    OR payment_method IS NULL OR cogs IS NULL OR gross_margin_percentage IS NULL
    OR gross_income IS NULL OR rating IS NULL;

-- 2. Duplicate invoice check
SELECT invoice_id, COUNT(*) AS duplicate_count
FROM Sales_Retail_Table
GROUP BY invoice_id
HAVING COUNT(*) > 1;

-- 3. Allowed-value checks (anomalies)
SELECT DISTINCT branch FROM Sales_Retail_Table;
SELECT DISTINCT city FROM Sales_Retail_Table;
SELECT DISTINCT customer_type FROM Sales_Retail_Table;
SELECT DISTINCT gender FROM Sales_Retail_Table;
SELECT DISTINCT product_line FROM Sales_Retail_Table;
SELECT DISTINCT payment_method FROM Sales_Retail_Table;

-- 4. Range / outlier checks
SELECT
    MIN(date) AS start_date,
    MAX(date) AS end_date,
    MIN(time) AS earliest_time,
    MAX(time) AS latest_time,
    MIN(unit_price) AS min_price,
    MAX(unit_price) AS max_price,
    MIN(quantity) AS min_qty,
    MAX(quantity) AS max_qty,
    MIN(rating) AS min_rating,
    MAX(rating) AS max_rating,
    MIN(total) AS min_total,
    MAX(total) AS max_total
FROM Sales_Retail_Table;

-- 5. Business-rule consistency
-- VAT should be 5% of COGS; total should be COGS + VAT; gross_income should match VAT
SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN ABS(VAT - (cogs * 0.05)) > 0.01 THEN 1 ELSE 0 END) AS vat_mismatch,
    SUM(CASE WHEN ABS(total - (cogs + VAT)) > 0.01 THEN 1 ELSE 0 END) AS total_mismatch,
    SUM(CASE WHEN ABS(gross_income - VAT) > 0.01 THEN 1 ELSE 0 END) AS income_mismatch,
    SUM(CASE WHEN rating < 0 OR rating > 10 THEN 1 ELSE 0 END) AS rating_out_of_range,
    SUM(CASE WHEN quantity <= 0 THEN 1 ELSE 0 END) AS invalid_qty,
    SUM(CASE WHEN unit_price <= 0 THEN 1 ELSE 0 END) AS invalid_price
FROM Sales_Retail_Table;

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'Super_Market_SalesRetail'
  AND table_name = 'Sales_Retail_Table'
ORDER BY ordinal_position;

SELECT * FROM Sales_Retail_Table LIMIT 10;


-- feature engineering--

SET SQL_SAFE_UPDATES = 0;

ALTER TABLE Sales_Retail_Table
  ADD COLUMN timeofday VARCHAR(20),
  ADD COLUMN dayname VARCHAR(20),
  ADD COLUMN monthname VARCHAR(20),
  ADD COLUMN hour_of_day INT,
  ADD COLUMN weekend_flag VARCHAR(10),
  ADD COLUMN week_number INT,
  ADD COLUMN qty_bucket VARCHAR(20),
  ADD COLUMN spend_bucket VARCHAR(20);


SET SQL_SAFE_UPDATES = 0;
UPDATE Sales_Retail_Table
SET
  timeofday = CASE
      WHEN HOUR(time) >= 0 AND HOUR(time) < 12 THEN 'Morning'
      WHEN HOUR(time) >= 12 AND HOUR(time) < 18 THEN 'Afternoon'
      ELSE 'Evening'
  END,
  dayname = DATE_FORMAT(date, '%a'),
  monthname = DATE_FORMAT(date, '%b'),
  hour_of_day = HOUR(time),
  weekend_flag = CASE
      WHEN DAYOFWEEK(date) IN (1, 7) THEN 'Weekend'
      ELSE 'Weekday'
  END,
  week_number = WEEK(date, 3),
  qty_bucket = CASE
      WHEN quantity <= 3 THEN 'Small basket'
      WHEN quantity <= 7 THEN 'Medium basket'
      ELSE 'Large basket'
  END;
SET SQL_SAFE_UPDATES = 1;

SELECT timeofday, dayname, monthname, hour_of_day, weekend_flag, week_number, qty_bucket
FROM Sales_Retail_Table
LIMIT 20;

-- Spend tiers using quartiles (window function)
UPDATE Sales_Retail_Table AS a
JOIN (
    SELECT
        invoice_id,
        CASE NTILE(4) OVER (ORDER BY total)
            WHEN 1 THEN 'Low spend'
            WHEN 2 THEN 'Mid-low spend'
            WHEN 3 THEN 'Mid-high spend'
            ELSE 'High spend'
        END AS spend_bucket
    FROM Sales_Retail_Table
) AS t ON a.invoice_id = t.invoice_id
SET a.spend_bucket = t.spend_bucket;

SELECT * FROM Sales_Retail_Table LIMIT 10;

/*==============================================================
-- Product Analysis --
==============================================================*/

SELECT COUNT(DISTINCT product_line) AS distinct_product_lines FROM Sales_Retail_Table;
SELECT DISTINCT product_line AS distinct_product_lines FROM Sales_Retail_Table;
-- INSIGHT: There are 6 distinct product lines in the dataset.
-- ACTION: Use this as the fixed product category list for all analysis.

SELECT product_line, SUM(total) AS total_sales
FROM Sales_Retail_Table
GROUP BY product_line
ORDER BY total_sales DESC;
-- INSIGHT: Food & Beverages generates the highest revenue, followed by Sports & Travel.
-- ACTION: Maintain strong focus on the top revenue-generating product lines.

SELECT product_line, AVG(rating) AS avg_rating
FROM Sales_Retail_Table
GROUP BY product_line
ORDER BY avg_rating ASC;
-- INSIGHT: Some product lines have noticeably lower average ratings than others.
-- ACTION: Investigate the lowest-rated product lines for possible quality or service issues.


-- Sales Analysis --

SELECT branch, SUM(total) AS overall_sales, AVG(rating) AS overall_avg_rating
FROM Sales_Retail_Table
GROUP BY branch
ORDER BY overall_sales DESC;
-- INSIGHT: One branch leads in revenue, but the differences between the three branches are not very large.
-- ACTION: Focus on understanding local customer behavior rather than major structural changes.

SELECT monthname, product_line, SUM(total) AS monthly_sales
FROM Sales_Retail_Table
GROUP BY monthname, product_line
ORDER BY monthname, monthly_sales DESC;
-- INSIGHT: Monthly sales vary by product line. Some products perform more consistently than others.
-- ACTION: Identify products with strong monthly consistency for stable inventory planning.

SELECT branch, product_line, SUM(total) AS branch_sales
FROM Sales_Retail_Table
GROUP BY branch, product_line
ORDER BY branch, branch_sales DESC;
-- INSIGHT: Product performance differs slightly across branches.
-- ACTION: Avoid assuming the same top products work equally well in every branch.

SELECT payment_method, product_line, SUM(total) AS payment_method_sales
FROM Sales_Retail_Table
GROUP BY payment_method, product_line
ORDER BY payment_method, payment_method_sales DESC;
-- INSIGHT: Payment method preference can vary by product line.
-- ACTION: Useful for understanding customer buying behavior, but not a major operational priority.

SELECT payment_method, SUM(total) AS overall_pay_sales
FROM Sales_Retail_Table
GROUP BY payment_method
ORDER BY overall_pay_sales DESC;
-- INSIGHT: Cash, Ewallet, and Credit card are all actively used, with relatively balanced contribution.
-- ACTION: Continue supporting all three payment methods.


-- Customer Analysis --

SELECT DISTINCT customer_type AS customer_segment FROM Sales_Retail_Table;
-- INSIGHT: There are only two customer types — Member and Normal.
-- ACTION: Use this simple segmentation for comparison analysis.

SELECT customer_type, monthname, SUM(total) AS total_sales
FROM Sales_Retail_Table
GROUP BY customer_type, monthname
ORDER BY customer_type, monthname;
-- INSIGHT: Both Member and Normal customers contribute across all months.
-- ACTION: No major seasonal difference is visible between the two customer types in this sample.

SELECT customer_type, SUM(total) AS total_sales, SUM(gross_income) AS total_profit
FROM Sales_Retail_Table
GROUP BY customer_type
ORDER BY total_profit DESC;
-- INSIGHT: Member customers generate slightly higher total revenue and gross income than Normal customers.
-- ACTION: Explore light loyalty benefits, but do not over-invest based on this small sample.



/*==============================================================
-- Executive KPI snapshot
============================================================== */
SELECT
    COUNT(*) AS invoices,
    SUM(quantity) AS units_sold,
    ROUND(SUM(total), 2) AS revenue,
    ROUND(SUM(gross_income), 2) AS gross_income,
    ROUND(AVG(total), 2) AS avg_order_value,
    ROUND(AVG(rating), 2) AS avg_rating
FROM Sales_Retail_Table;
-- INSIGHT: Baseline performance of the entire sample (1,000 invoices).
-- ACTION: Use these figures as the reference point for all comparisons.

/* ============================================================== 
-- Branch contribution and rank
============================================================== */
SELECT
    branch,
    city,
    COUNT(*) AS invoices,
    ROUND(SUM(total), 2) AS revenue,
    ROUND(SUM(total) * 100 / SUM(SUM(total)) OVER (), 2) AS revenue_share_pct,
    RANK() OVER (ORDER BY SUM(total) DESC) AS revenue_rank,
    ROUND(AVG(total), 2) AS avg_order_value,
    ROUND(AVG(rating), 2) AS avg_rating
FROM Sales_Retail_Table
GROUP BY branch, city;
-- INSIGHT: Naypyitaw leads, but revenue is fairly evenly distributed across the three cities.
-- ACTION: No major reallocation needed. Focus on local customer behavior instead.

/* ============================================================== 
-- Daily revenue with running total and previous-day change
============================================================== */
SELECT
    date,
    ROUND(SUM(total), 2) AS daily_revenue,
    ROUND(SUM(SUM(total)) OVER (ORDER BY date), 2) AS running_revenue,
    ROUND(
        SUM(total) - LAG(SUM(total)) OVER (ORDER BY date),
        2
    ) AS vs_previous_day
FROM Sales_Retail_Table
GROUP BY date
ORDER BY date;
-- INSIGHT: Daily revenue fluctuates across the period. The running total shows overall sales momentum over the three months.
-- ACTION: Identify low-revenue days for further investigation (possible stock, staffing, or promotion issues).

/*============================================================== 
-- Product line: revenue, share, AOV, rating, rank
============================================================== */
SELECT
    product_line,
    COUNT(*) AS invoices,
    ROUND(SUM(total), 2) AS revenue,
    ROUND(SUM(total) * 100 / SUM(SUM(total)) OVER (), 2) AS revenue_share_pct,
    ROUND(AVG(total), 2) AS avg_order_value,
    ROUND(AVG(rating), 2) AS avg_rating,
    RANK() OVER (ORDER BY SUM(total) DESC) AS sales_rank
FROM Sales_Retail_Table
GROUP BY product_line
ORDER BY revenue DESC;
-- INSIGHT: Food & Beverages leads in revenue. Some high-revenue products have weaker ratings.
-- ACTION: Prioritize quality improvement on high-sales, lower-rating product lines.

/*============================================================== 
-- Weekend vs weekday
============================================================== */ 
SELECT
    weekend_flag,
    COUNT(*) AS invoices,
    ROUND(SUM(total), 2) AS revenue,
    ROUND(AVG(total), 2) AS avg_order_value,
    ROUND(AVG(rating), 2) AS avg_rating
FROM Sales_Retail_Table
GROUP BY weekend_flag;
-- INSIGHT: Weekdays generate significantly more total revenue due to higher volume. Weekend Average Order Value is slightly higher.
-- ACTION: Maintain strong weekday operations and test targeted promotions on weekends.

/*============================================================== 
-- Hour-of-day demand
============================================================== */ 
SELECT
    hour_of_day,
    timeofday,
    COUNT(*) AS invoices,
    ROUND(SUM(total), 2) AS revenue
FROM Sales_Retail_Table
GROUP BY hour_of_day, timeofday
ORDER BY hour_of_day;
-- INSIGHT: Afternoon and Evening generate the highest revenue.
-- ACTION: Align staffing and inventory with these peak periods.

/*============================================================== 
-- Basket size vs value
==============================================================*/ 
SELECT
    qty_bucket,
    COUNT(*) AS invoices,
    ROUND(AVG(total), 2) AS avg_order_value,
    ROUND(SUM(total), 2) AS revenue
FROM Sales_Retail_Table
GROUP BY qty_bucket
ORDER BY revenue DESC;
-- INSIGHT: Large baskets generate the highest total revenue and significantly higher Average Order Value compared to Small and Medium baskets.
-- ACTION: Design targeted strategies (bundling, promotions, or upselling) to encourage customers to move from smaller baskets to larger ones.


-- Business Question to Answers --

-- =====================================================
-- 15 STRONG BUSINESS QUESTIONS 
-- =====================================================

-- 1. Which product lines generate high revenue but have below-average customer ratings?
SELECT 
    product_line,
    ROUND(SUM(total), 2) AS revenue,
    ROUND(AVG(rating), 2) AS avg_rating
FROM Sales_Retail_Table
GROUP BY product_line
HAVING AVG(rating) < (SELECT AVG(rating) FROM Sales_Retail_Table)
ORDER BY revenue DESC;
-- INSIGHT: These product lines sell well but receive lower customer satisfaction scores.
-- ACTION: Prioritize quality and service review for these high-revenue, lower-rated products.

-- 2. How does Average Order Value differ between Member and Normal customers?
SELECT 
    customer_type,
    COUNT(*) AS invoices,
    ROUND(AVG(total), 2) AS avg_order_value,
    ROUND(SUM(total), 2) AS total_revenue
FROM Sales_Retail_Table
GROUP BY customer_type;
-- INSIGHT: Member customers show slightly higher Average Order Value than Normal customers.
-- ACTION: Test light loyalty benefits for Members, but avoid heavy investment based on this small sample.

-- 3. Which hours of the day generate the highest revenue?
SELECT 
    hour_of_day,
    ROUND(SUM(total), 2) AS revenue,
    COUNT(*) AS invoices
FROM Sales_Retail_Table
GROUP BY hour_of_day
ORDER BY revenue DESC;
-- INSIGHT: Evening hours generally contribute the highest revenue.
-- ACTION: Align staffing and inventory readiness with peak evening hours.

-- 4. What is the revenue contribution of each city and its rank?
SELECT 
    city,
    ROUND(SUM(total), 2) AS revenue,
    ROUND(SUM(total) * 100.0 / SUM(SUM(total)) OVER (), 2) AS revenue_share_pct,
    RANK() OVER (ORDER BY SUM(total) DESC) AS revenue_rank
FROM Sales_Retail_Table
GROUP BY city;
-- INSIGHT: Naypyitaw leads in revenue, but the gap between the three cities is relatively small.
-- ACTION: Focus on understanding local preferences rather than major structural changes.

-- 5. How does performance differ between Weekdays and Weekends?
SELECT 
    weekend_flag,
    COUNT(*) AS invoices,
    ROUND(SUM(total), 2) AS revenue,
    ROUND(AVG(total), 2) AS avg_order_value,
    ROUND(AVG(rating), 2) AS avg_rating
FROM Sales_Retail_Table
GROUP BY weekend_flag;
-- INSIGHT: Weekdays generate significantly more total revenue due to higher volume, while Weekend AOV is slightly higher.
-- ACTION: Maintain strong weekday operations and test targeted weekend promotions.

-- 6. Which product line performs best in each city?
SELECT 
    city,
    product_line,
    ROUND(SUM(total), 2) AS revenue,
    RANK() OVER (PARTITION BY city ORDER BY SUM(total) DESC) AS city_rank
FROM Sales_Retail_Table
GROUP BY city, product_line
HAVING city_rank = 1;
-- INSIGHT: The top product line can differ by city.
-- ACTION: Avoid assuming one product strategy works equally well across all branches.

-- 7. What is the relationship between basket size and revenue?
SELECT 
    qty_bucket,
    COUNT(*) AS invoices,
    ROUND(SUM(total), 2) AS revenue,
    ROUND(AVG(total), 2) AS avg_order_value
FROM Sales_Retail_Table
GROUP BY qty_bucket
ORDER BY revenue DESC;
-- INSIGHT: Large baskets contribute the highest revenue and higher Average Order Value.
-- ACTION: Explore ways to encourage customers to increase basket size.

-- 8. Which payment method is most used in each branch?
SELECT 
    branch,
    payment_method,
    COUNT(*) AS invoices,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY branch), 2) AS pct_of_branch
FROM Sales_Retail_Table
GROUP BY branch, payment_method
ORDER BY branch, invoices DESC;
-- INSIGHT: All three payment methods are actively used across branches with relatively balanced distribution.
-- ACTION: Continue supporting Cash, Ewallet, and Credit card equally.

-- 9. Which day of the week generates the highest average rating?
SELECT 
    dayname,
    ROUND(AVG(rating), 2) AS avg_rating,
    COUNT(*) AS invoices
FROM Sales_Retail_Table
GROUP BY dayname
ORDER BY avg_rating DESC;
-- INSIGHT: Customer ratings vary slightly by day of the week.
-- ACTION: Investigate whether service quality or staffing differences explain rating variations.

-- 10. What is the monthly revenue trend by product line?
SELECT 
    monthname,
    product_line,
    ROUND(SUM(total), 2) AS monthly_revenue
FROM Sales_Retail_Table
GROUP BY monthname, product_line
ORDER BY monthname, monthly_revenue DESC;
-- INSIGHT: Some product lines show more stable monthly performance than others.
-- ACTION: Use consistent performers for stable inventory planning.

-- 11. Which gender prefers which product lines the most?
SELECT * FROM (
    SELECT 
        gender,
        product_line,
        COUNT(*) AS frequency,
        RANK() OVER (PARTITION BY gender ORDER BY COUNT(*) DESC) AS preference_rank
    FROM Sales_Retail_Table
    GROUP BY gender, product_line
) AS ranked
WHERE preference_rank <= 3
ORDER BY gender, preference_rank;
-- INSIGHT: Product preferences differ by gender.
-- ACTION: Useful for light targeted merchandising or promotions.

-- 12. What is the average rating by time of day?
SELECT 
    timeofday,
    ROUND(AVG(rating), 2) AS avg_rating,
    COUNT(*) AS invoices
FROM Sales_Retail_Table
GROUP BY timeofday
ORDER BY avg_rating DESC;
-- INSIGHT: Customer ratings show slight variation across Morning, Afternoon, and Evening.
-- ACTION: Check whether service levels differ by time of day.

-- 13. Which branch has the highest Average Order Value?
SELECT 
    branch,
    city,
    ROUND(AVG(total), 2) AS avg_order_value,
    ROUND(SUM(total), 2) AS total_revenue
FROM Sales_Retail_Table
GROUP BY branch, city
ORDER BY avg_order_value DESC;
-- INSIGHT: Average Order Value differs slightly across branches.
-- ACTION: Study the branch with higher AOV for possible best practices.

-- 14. How much revenue comes from the top 20% of invoices?
WITH RankedInvoices AS (
    SELECT 
        invoice_id,
        total,
        NTILE(5) OVER (ORDER BY total DESC) AS revenue_quintile
    FROM Sales_Retail_Table
)
SELECT 
    ROUND(SUM(CASE WHEN revenue_quintile = 1 THEN total ELSE 0 END), 2) AS top_20_pct_revenue,
    ROUND(SUM(total), 2) AS total_revenue,
    ROUND(SUM(CASE WHEN revenue_quintile = 1 THEN total ELSE 0 END) * 100.0 / SUM(total), 2) AS top_20_pct_share
FROM RankedInvoices;
-- INSIGHT: A smaller group of high-value invoices contributes a noticeable share of total revenue.
-- ACTION: Understand what drives higher invoice values (basket size, product mix, etc.).

-- 15. Which product lines have both high revenue and high rating? (Ideal products)
SELECT 
    product_line,
    ROUND(SUM(total), 2) AS revenue,
    ROUND(AVG(rating), 2) AS avg_rating
FROM Sales_Retail_Table
GROUP BY product_line
HAVING AVG(rating) >= (SELECT AVG(rating) FROM Sales_Retail_Table)
ORDER BY revenue DESC;
-- INSIGHT: These product lines perform well in both sales and customer satisfaction.
-- ACTION: Protect and potentially expand these strong-performing categories.

-- 16 . List the Peak Hour by Branch 
WITH BranchHourRevenue AS (
    SELECT
        branch,
        hour_of_day,
        ROUND(SUM(total), 2) AS revenue,
        RANK() OVER (PARTITION BY branch ORDER BY SUM(total) DESC) AS rnk
    FROM Sales_Retail_Table
    GROUP BY branch, hour_of_day
)
SELECT branch, hour_of_day, revenue
FROM BranchHourRevenue
WHERE rnk = 1
ORDER BY branch;
-- INSIGHT: Peak hour differs slightly by branch.
-- ACTION: Do not apply one single timetable to all branches.

-- 17. Top 10 invoices by revenue
SELECT invoice_id, branch, product_line, total, rating
FROM Sales_Retail_Table
ORDER BY total DESC
LIMIT 10;
-- INSIGHT: Highest invoices for QA sampling only.
-- ACTION: Do not treat this as a VIP customer list (no customer_id in the file).

-- =====================================================
-- EXECUTIVE SUMMARY
-- =====================================================
/*
Key Findings:
1. Naypyitaw has the highest revenue, but the gap between the three cities is small.
2. Food & Beverages is the top product line by revenue.
3. Some high-revenue product lines have below-average ratings (priority for quality review).
4. Member customers show slightly higher Average Order Value than Normal customers.
5. Afternoon and Evening periods generate the majority of revenue.
6. Weekdays contribute most of the total revenue due to higher volume.
7. Payment methods (Cash, Ewallet, Credit card) are relatively balanced.

Note: Insights are directional only due to the small public sample size.
*/