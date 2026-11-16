-- =====================================================================
-- 03_churn_kpis.sql
-- Purpose : The headline numbers a manager or dashboard needs.
-- Skills  : aggregates, subqueries, HAVING, ROUND/CAST
-- Revenue definitions (used in Power BI too):
--   Monthly revenue      = SUM(monthly_charges) of ALL customers
--   Revenue lost         = SUM(monthly_charges) of customers who ALREADY churned (per month)
--   Revenue at risk      = what we expect to lose from customers still here:
--                          retained monthly revenue x that group's observed churn rate
-- =====================================================================

-- K1 ---------------------------------------------------------------
-- Business question: How much monthly revenue did churn cost us?
-- SQL logic: conditional SUM using the 1/0 flag, plus annualised (x12).
SELECT ROUND(SUM(monthly_charges), 2)                                       AS total_monthly_revenue,
       ROUND(SUM(CASE WHEN churn_value = 1 THEN monthly_charges END), 2)    AS monthly_revenue_lost,
       ROUND(100.0 * SUM(CASE WHEN churn_value = 1 THEN monthly_charges END)
                   / SUM(monthly_charges), 2)                               AS pct_revenue_lost,
       ROUND(12 * SUM(CASE WHEN churn_value = 1 THEN monthly_charges END), 0) AS annualised_revenue_lost
FROM customers;
-- Result: Monthly revenue $456,117; revenue lost to churn $139,131 per month (30.5%); about $1.67M annualised.
-- Business interpretation: Churners are 26.5% of customers but 30.5% of revenue, because they pay more than average. The annualised figure assumes the lost revenue would have continued.

-- K2 ---------------------------------------------------------------
-- Business question: Which contract/internet combinations churn above the company average,
--                    and are they big enough to matter?
-- SQL logic: GROUP BY two columns; HAVING filters AFTER aggregation (small groups give
--            unreliable rates, so require >= 100 customers); a scalar SUBQUERY supplies
--            the company-wide rate to compare against.
SELECT contract,
       internet_service,
       COUNT(*)                                       AS customers,
       ROUND(100.0 * SUM(churn_value) / COUNT(*), 2)  AS churn_rate_pct
FROM customers
GROUP BY contract, internet_service
HAVING COUNT(*) >= 100
   AND 1.0 * SUM(churn_value) / COUNT(*) > (SELECT AVG(churn_value) FROM customers)
ORDER BY churn_rate_pct DESC;
-- Result: Only two combinations clear both filters: Month-to-month + Fiber optic (54.61%, 2,128 customers) and Month-to-month + DSL (32.22%, 1,223).
-- Business interpretation: Month-to-month fiber is the single highest-risk large group: more than half leave.

-- K3 ---------------------------------------------------------------
-- Business question: Do high-paying customers churn more than the average customer?
-- SQL logic: subquery in WHERE compares each customer to the overall average charge.
SELECT CASE WHEN monthly_charges > (SELECT AVG(monthly_charges) FROM customers)
            THEN 'Above-average charge' ELSE 'At/below average' END AS charge_group,
       COUNT(*)                                       AS customers,
       ROUND(100.0 * SUM(churn_value) / COUNT(*), 2)  AS churn_rate_pct
FROM customers
GROUP BY charge_group;
-- Result: Above-average charge 34.54% vs 16.47% at or below average.
-- Business interpretation: Churn rises with price paid. Correlation only: higher-priced customers also take fiber and month-to-month more often.

-- K4 ---------------------------------------------------------------
-- Business question: How much monthly revenue is at risk among customers who are still with us?
-- SQL logic: CTE 1 = churn rate per contract; CTE 2 = retained monthly revenue per contract;
--            multiply to get an expected loss. This is an estimate that assumes future churn
--            behaves like the observed churn. It is NOT a forecast.
WITH contract_rate AS (
    SELECT contract, 1.0 * SUM(churn_value) / COUNT(*) AS churn_rate
    FROM customers
    GROUP BY contract
),
retained_revenue AS (
    SELECT contract, SUM(monthly_charges) AS retained_monthly_revenue, COUNT(*) AS retained_customers
    FROM customers
    WHERE churn_value = 0
    GROUP BY contract
)
SELECT r.contract,
       r.retained_customers,
       ROUND(r.retained_monthly_revenue, 0)                    AS retained_monthly_revenue,
       ROUND(100 * c.churn_rate, 1)                            AS churn_rate_pct,
       ROUND(r.retained_monthly_revenue * c.churn_rate, 0)     AS monthly_revenue_at_risk
FROM retained_revenue r
JOIN contract_rate c ON c.contract = r.contract
ORDER BY monthly_revenue_at_risk DESC;
-- Result: Month-to-month $58,276; One year $9,207; Two year $2,799. Total about $70,282 of monthly revenue.
-- Business interpretation: If current patterns repeat, month-to-month customers still with us would put about $58K a month at risk. This is a risk estimate based on observed rates, not a forecast.

