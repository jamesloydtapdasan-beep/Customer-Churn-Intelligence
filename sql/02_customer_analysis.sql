-- =====================================================================
-- 02_customer_analysis.sql
-- Purpose : First business answers: how big is churn and where does it show up?
-- Skills  : SELECT, WHERE, GROUP BY, ORDER BY, CASE WHEN, aggregates
-- Note    : churn_value is 1/0, so SUM(churn_value) = churned customers and
--           AVG(churn_value) = churn rate. This is the core trick of churn SQL.
-- =====================================================================

-- A1 ---------------------------------------------------------------
-- Business question: What is the company's overall churn rate?
-- SQL logic: total rows, SUM of the 1/0 flag, and their ratio.
SELECT COUNT(*)                                        AS total_customers,
       SUM(churn_value)                                AS churned_customers,
       COUNT(*) - SUM(churn_value)                     AS retained_customers,
       ROUND(100.0 * SUM(churn_value) / COUNT(*), 2)   AS churn_rate_pct
FROM customers;
-- Result: 7,043 customers, 1,869 churned, 5,174 retained, churn rate 26.54%.
-- Business interpretation: About 1 in 4 customers left. This is the baseline every segment is compared against.

-- A2 ---------------------------------------------------------------
-- Business question: Which contract type loses the most customers?
-- SQL logic: GROUP BY contract, same three measures per group.
SELECT contract,
       COUNT(*)                                       AS customers,
       SUM(churn_value)                               AS churned,
       ROUND(100.0 * SUM(churn_value) / COUNT(*), 2)  AS churn_rate_pct
FROM customers
GROUP BY contract
ORDER BY churn_rate_pct DESC;
-- Result: Month-to-month 42.71%, One year 11.27%, Two year 2.83%.
-- Business interpretation: Contract type shows the largest spread of any variable so far. Month-to-month customers are 55% of the base but 89% of churners (1,655 of 1,869). This is an association: customers who plan to leave may also simply prefer flexible contracts.

-- A3 ---------------------------------------------------------------
-- Business question: Does the way people pay relate to churn?
-- SQL logic: same pattern grouped by payment_method.
SELECT payment_method,
       COUNT(*)                                       AS customers,
       SUM(churn_value)                               AS churned,
       ROUND(100.0 * SUM(churn_value) / COUNT(*), 2)  AS churn_rate_pct
FROM customers
GROUP BY payment_method
ORDER BY churn_rate_pct DESC;
-- Result: Electronic check 45.29%; the other three methods 15.24% to 19.11%.
-- Business interpretation: Electronic-check payers churn roughly 2.5 to 3 times as often as the other methods. Checked in Phase 5: the gap persists within every contract type (month-to-month 53.7% vs 31.6-34.1% for other methods), so contract mix does not fully explain it. It is a strong targeting flag, but this data cannot show that changing the payment method would reduce churn.

-- A4 ---------------------------------------------------------------
-- Business question: Is churn higher for a particular internet product?
-- SQL logic: same pattern grouped by internet_service.
SELECT internet_service,
       COUNT(*)                                       AS customers,
       ROUND(100.0 * SUM(churn_value) / COUNT(*), 2)  AS churn_rate_pct,
       ROUND(AVG(monthly_charges), 2)                 AS avg_monthly_charge
FROM customers
GROUP BY internet_service
ORDER BY churn_rate_pct DESC;
-- Result: Fiber optic 41.89% (avg charge $91.50), DSL 18.96% ($58.10), no internet 7.40% ($21.08).
-- Business interpretation: Fiber customers pay the most and leave the most. That combination makes fiber the main revenue issue. The data cannot say why (price, quality or competition), only that it needs investigating.

-- A5 ---------------------------------------------------------------
-- Business question: Do churned customers pay more or less than retained ones?
-- SQL logic: CASE turns the 1/0 flag into readable labels, then GROUP BY the label.
SELECT CASE WHEN churn_value = 1 THEN 'Churned' ELSE 'Retained' END AS status,
       COUNT(*)                          AS customers,
       ROUND(AVG(monthly_charges), 2)    AS avg_monthly_charge,
       ROUND(AVG(tenure_months), 1)      AS avg_tenure_months
FROM customers
GROUP BY status;
-- Result: Churned: avg $74.44/month, avg tenure 18.0 months. Retained: $61.27, 37.6 months.
-- Business interpretation: Churners pay about $13 more per month and have half the tenure. The company is losing customers who are more valuable per month.

-- A6 ---------------------------------------------------------------
-- Business question: Which household types churn most?
-- SQL logic: CASE builds a customer_segment from demographic flags. Order matters:
--            the first matching WHEN wins, so a senior with dependents counts as Senior.
SELECT CASE WHEN senior_citizen = 'Yes' THEN '1 Senior'
            WHEN dependents     = 'Yes' THEN '2 Family (dependents)'
            WHEN partner        = 'Yes' THEN '3 Couple (no dependents)'
            ELSE                             '4 Single (no partner/dependents)'
       END                                             AS customer_segment,
       COUNT(*)                                        AS customers,
       ROUND(100.0 * SUM(churn_value) / COUNT(*), 2)   AS churn_rate_pct
FROM customers
GROUP BY customer_segment
ORDER BY customer_segment;
-- Result: Senior 41.68%, Family 6.05%, Couple 26.95%, Single 31.54%.
-- Business interpretation: Households with dependents are very stable; seniors are the least stable. Because the CASE puts seniors first, a senior with dependents is counted as Senior, so read these as priority-ordered groups, not independent traits.

-- A7 ---------------------------------------------------------------
-- Business question: Show me the churned month-to-month customers paying the most (WHERE practice).
-- SQL logic: filter with WHERE, sort, LIMIT. Useful to inspect individual cases.
SELECT customer_id, city, tenure_months, monthly_charges, churn_reason
FROM customers
WHERE churn_value = 1
  AND contract = 'Month-to-month'
  AND monthly_charges >= 100
ORDER BY monthly_charges DESC
LIMIT 10;
-- Result: Top 10 are high-paying (about $110-117) month-to-month customers with mixed reasons: competitor offers, support attitude, product dissatisfaction.
-- Business interpretation: Individual cases show the high-value losses are not all price-driven; support experience and competitors appear repeatedly.

