-- =====================================================================
-- 05_advanced_analysis.sql
-- Purpose : Ranking and ordered comparisons. Each query exists because a plain GROUP BY
--           cannot answer the question.
-- Skills  : CTEs, ROW_NUMBER, RANK, DENSE_RANK, LAG, LEAD, window aggregates
-- Requires: the `customers` table only.
-- =====================================================================

-- X1 ---------------------------------------------------------------
-- Business question: Rank all segments (contract x payment method) by churn rate.
--                    Which are the worst, and are there ties?
-- SQL logic: aggregate in a CTE, then RANK() and DENSE_RANK(). RANK leaves gaps after ties
--            (1,1,3), DENSE_RANK does not (1,1,2). No ties occur in this result, so both columns match.
WITH seg AS (
    SELECT contract, payment_method,
           COUNT(*) AS customers,
           ROUND(100.0 * SUM(churn_value) / COUNT(*), 1) AS churn_rate_pct
    FROM customers
    GROUP BY contract, payment_method
    HAVING COUNT(*) >= 100
)
SELECT contract, payment_method, customers, churn_rate_pct,
       RANK()       OVER (ORDER BY churn_rate_pct DESC) AS rnk,
       DENSE_RANK() OVER (ORDER BY churn_rate_pct DESC) AS dense_rnk
FROM seg
ORDER BY churn_rate_pct DESC
LIMIT 8;
-- Result: Month-to-month + Electronic check ranks first at 53.7% (1,850 customers); the next is 34.1%. No ties appear in the top 8, so RANK and DENSE_RANK are identical here.
-- Business interpretation: The worst segment is far above the rest. Where ties do exist, RANK would skip a number and DENSE_RANK would not, which is why you should know both.

-- X2 ---------------------------------------------------------------
-- Business question: The retention team wants a call list. For each internet type, who are the
--                    5 highest-paying customers still with us who match the high-risk profile
--                    (month-to-month, tenure <= 12 months)?
-- SQL logic: ROW_NUMBER() restarts per partition. We keep rn <= 5 per internet type so the
--            list covers every product. This is a prioritisation list, not a prediction.
WITH candidates AS (
    SELECT customer_id, internet_service, tenure_months, monthly_charges,
           ROW_NUMBER() OVER (PARTITION BY internet_service
                              ORDER BY monthly_charges DESC, customer_id) AS rn
    FROM customers
    WHERE churn_value = 0
      AND contract = 'Month-to-month'
      AND tenure_months <= 12
)
SELECT internet_service, rn AS priority, customer_id, tenure_months, monthly_charges
FROM candidates
WHERE rn <= 5
ORDER BY internet_service, rn;
-- Result: Top 5 per internet type, ordered by monthly charge. Fiber optic candidates pay $105-111.
-- Business interpretation: A concrete outreach list for the retention team. The 'No internet' group is low-value so low priority. This ranks by revenue, not by model-predicted risk.

-- X3 ---------------------------------------------------------------
-- Business question: As customers stay longer, how does the churn rate change from one
--                    tenure year to the next? Where is the biggest drop?
-- SQL logic: aggregate to one row per tenure year, then LAG() reads the previous year's rate
--            so we can subtract. LEAD() would look forward. NULL in the first row is expected.
WITH by_year AS (
    SELECT (tenure_months - 1) / 12 + 1                                AS tenure_year,
           COUNT(*)                                                    AS customers,
           ROUND(100.0 * SUM(churn_value) / COUNT(*), 1)               AS churn_rate_pct
    FROM customers
    WHERE tenure_months >= 1
    GROUP BY tenure_year
)
SELECT tenure_year, customers, churn_rate_pct,
       LAG(churn_rate_pct)  OVER (ORDER BY tenure_year)                       AS prev_year_rate,
       ROUND(churn_rate_pct - LAG(churn_rate_pct) OVER (ORDER BY tenure_year), 1) AS change_pts
FROM by_year
ORDER BY tenure_year;
-- Result: Churn falls from 47.7% in year 1 to 6.6% in year 6. The biggest single-year drop is year 1 to 2 (-19.0 points).
-- Business interpretation: The first 12 months are the critical window. After year 2 the improvement is slower, so the earliest intervention matters most.

-- X4 ---------------------------------------------------------------
-- Business question: Which single contract+internet segments account for the largest share of
--                    all revenue lost to churn (Pareto view)?
-- SQL logic: window SUM() OVER () gives the grand total for share; a running SUM with
--            ORDER BY gives cumulative share, so we can see how few segments explain most losses.
WITH lost AS (
    SELECT contract, internet_service,
           ROUND(SUM(monthly_charges), 0) AS monthly_revenue_lost
    FROM customers
    WHERE churn_value = 1
    GROUP BY contract, internet_service
)
SELECT contract, internet_service, monthly_revenue_lost,
       ROUND(100.0 * monthly_revenue_lost / SUM(monthly_revenue_lost) OVER (), 1) AS pct_of_total_lost,
       ROUND(100.0 * SUM(monthly_revenue_lost) OVER (ORDER BY monthly_revenue_lost DESC)
                   / SUM(monthly_revenue_lost) OVER (), 1)                         AS cumulative_pct
FROM lost
ORDER BY monthly_revenue_lost DESC;
-- Result: Month-to-month + Fiber optic is 72.2% of lost revenue; the top two segments reach 85.4%.
-- Business interpretation: Revenue loss is highly concentrated. A programme aimed at month-to-month fiber and DSL customers would address most of the problem.

