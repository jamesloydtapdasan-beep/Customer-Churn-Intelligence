-- =====================================================================
-- 01_data_validation.sql
-- Purpose : Prove the clean data is trustworthy BEFORE any analysis.
-- Database: SQLite. Table `customers` = data/clean/customer_churn_clean.csv
-- Skills  : SELECT, COUNT, WHERE, CASE WHEN, aggregate functions
-- =====================================================================

-- V1 ---------------------------------------------------------------
-- Business question: Did the load work, and is there exactly one row per customer?
-- SQL logic: compare COUNT(*) with COUNT(DISTINCT customer_id). If they differ, there are duplicates.
SELECT COUNT(*)                     AS total_rows,
       COUNT(DISTINCT customer_id)  AS distinct_customers
FROM customers;
-- Result: 7,043 rows and 7,043 distinct customers.
-- Business interpretation: The grain is one row per customer, so customer counts are safe to trust.

-- V2 ---------------------------------------------------------------
-- Business question: Are any key columns missing values?
-- SQL logic: a CASE returns 1 when the value IS NULL; SUM adds them up.
--            churn_reason is excluded on purpose (null for customers who stayed).
SELECT SUM(CASE WHEN contract        IS NULL THEN 1 ELSE 0 END) AS null_contract,
       SUM(CASE WHEN payment_method  IS NULL THEN 1 ELSE 0 END) AS null_payment_method,
       SUM(CASE WHEN tenure_months   IS NULL THEN 1 ELSE 0 END) AS null_tenure,
       SUM(CASE WHEN monthly_charges IS NULL THEN 1 ELSE 0 END) AS null_monthly_charges,
       SUM(CASE WHEN total_charges   IS NULL THEN 1 ELSE 0 END) AS null_total_charges,
       SUM(CASE WHEN churn_value     IS NULL THEN 1 ELSE 0 END) AS null_churn_value
FROM customers;
-- Result: All zeros.
-- Business interpretation: No missing values in fields the analysis depends on.

-- V3 ---------------------------------------------------------------
-- Business question: Do the two churn columns tell the same story?
-- SQL logic: count rows where the text label and the 0/1 flag disagree. Expect 0.
SELECT COUNT(*) AS churn_columns_disagree
FROM customers
WHERE (churn_label = 'Yes' AND churn_value <> 1)
   OR (churn_label = 'No'  AND churn_value <> 0);
-- Result: 0 disagreements.
-- Business interpretation: Either churn column can be used safely.

-- V4 ---------------------------------------------------------------
-- Business question: Are there impossible values?
-- SQL logic: WHERE finds rows violating business rules; we count each rule separately.
SELECT SUM(CASE WHEN tenure_months   < 0 OR tenure_months > 72 THEN 1 ELSE 0 END) AS bad_tenure,
       SUM(CASE WHEN monthly_charges <= 0                      THEN 1 ELSE 0 END) AS bad_monthly_charge,
       SUM(CASE WHEN total_charges   <  0                      THEN 1 ELSE 0 END) AS bad_total_charge
FROM customers;
-- Result: All zeros.
-- Business interpretation: No impossible tenure or charge values.

-- V5 ---------------------------------------------------------------
-- Business question: Are category values consistent (no typos or duplicate spellings)?
-- SQL logic: GROUP BY each categorical column to list distinct values with counts.
SELECT 'contract' AS column_name, contract AS value, COUNT(*) AS n FROM customers GROUP BY contract
UNION ALL
SELECT 'payment_method', payment_method, COUNT(*) FROM customers GROUP BY payment_method
UNION ALL
SELECT 'internet_service', internet_service, COUNT(*) FROM customers GROUP BY internet_service;
-- Result: 3 contract types, 4 payment methods, 3 internet types, no stray spellings.
-- Business interpretation: Safe to GROUP BY these columns without cleanup.

-- V6 ---------------------------------------------------------------
-- Business question: Do billed totals make sense relative to tenure?
-- SQL logic: customers with tenure 0 should have total_charges = 0 (not yet billed).
--            Also count customers whose total differs from tenure x monthly by more than 50%.
SELECT SUM(CASE WHEN tenure_months = 0 AND total_charges = 0 THEN 1 ELSE 0 END) AS new_unbilled_customers,
       SUM(CASE WHEN tenure_months = 0 AND total_charges > 0 THEN 1 ELSE 0 END) AS new_but_billed_suspicious,
       SUM(CASE WHEN tenure_months > 0
                 AND ABS(total_charges - tenure_months * monthly_charges) > 0.5 * tenure_months * monthly_charges
                THEN 1 ELSE 0 END)                                                AS totals_far_from_expected
FROM customers;
-- Result: 11 new customers unbilled (tenure 0, total 0); 0 suspicious; 2 rows where total differs from tenure x monthly by more than 50%.
-- Business interpretation: The 11 are the cleaned blanks from Phase 3. The 2 odd rows (0.03%) are plausibly plan changes and are left as is, but are worth noting.

