-- =====================================================================
-- 04_segmentation.sql
-- Purpose : Find WHICH groups of customers are the problem.
-- Skills  : CASE WHEN bucketing, JOIN to a lookup table, CTEs, HAVING
-- =====================================================================

-- S1 ---------------------------------------------------------------
-- Business question: When in the customer lifecycle does churn happen?
-- SQL logic: CASE bands tenure into segments (numbered so ORDER BY sorts logically).
SELECT CASE WHEN tenure_months <= 12 THEN '1 (0-12 months)'
            WHEN tenure_months <= 24 THEN '2 (13-24 months)'
            WHEN tenure_months <= 48 THEN '3 (25-48 months)'
            ELSE                          '4 (49-72 months)' END AS tenure_segment,
       COUNT(*)                                        AS customers,
       SUM(churn_value)                                AS churned,
       ROUND(100.0 * SUM(churn_value) / COUNT(*), 2)   AS churn_rate_pct,
       ROUND(AVG(monthly_charges), 2)                  AS avg_monthly_charge
FROM customers
GROUP BY tenure_segment
ORDER BY tenure_segment;
-- Result: 0-12 months 47.44%, 13-24 28.71%, 25-48 20.39%, 49-72 9.51%.
-- Business interpretation: Nearly half of customers in their first year left. Churn falls steadily with tenure, so early-life retention is the biggest lever.

-- S2 ---------------------------------------------------------------
-- Business question: Which customer VALUE tiers are leaving, and what revenue do they carry?
-- SQL logic: CASE creates the value tier from monthly_charges (thresholds are simple and
--            explainable; Phase 7 may refine them). SUM of lost revenue shows size of the problem.
SELECT CASE WHEN monthly_charges <  35 THEN '1 Low (<35)'
            WHEN monthly_charges <  70 THEN '2 Medium (35-69.99)'
            ELSE                            '3 High (70+)' END AS value_tier,
       COUNT(*)                                        AS customers,
       ROUND(100.0 * SUM(churn_value) / COUNT(*), 2)   AS churn_rate_pct,
       ROUND(SUM(CASE WHEN churn_value = 1 THEN monthly_charges END), 0) AS monthly_revenue_lost
FROM customers
GROUP BY value_tier
ORDER BY value_tier;
-- Result: Low 10.86%, Medium 23.65%, High 35.48%. High tier accounts for $112,981 of the $139,131 monthly revenue lost (81%).
-- Business interpretation: Churn is concentrated in the most valuable customers, so revenue loss is much larger than the churn rate suggests.

-- S3 ---------------------------------------------------------------
-- Business question: WHY do customers say they leave, grouped into actionable themes?
-- SQL logic: a small lookup table maps 20 raw reasons to 5 themes. JOIN attaches the theme
--            to each churned customer. LEFT JOIN + 'Unmapped' would expose any reason we forgot.
DROP TABLE IF EXISTS churn_reason_map;
CREATE TABLE churn_reason_map (churn_reason TEXT PRIMARY KEY, reason_theme TEXT);
INSERT INTO churn_reason_map VALUES
 ('Competitor made better offer',                'Competitor'),
 ('Competitor had better devices',               'Competitor'),
 ('Competitor offered higher download speeds',   'Competitor'),
 ('Competitor offered more data',                'Competitor'),
 ('Attitude of support person',                  'Support attitude / expertise'),
 ('Attitude of service provider',                'Support attitude / expertise'),
 ('Poor expertise of phone support',             'Support attitude / expertise'),
 ('Poor expertise of online support',            'Support attitude / expertise'),
 ('Price too high',                              'Price / charges'),
 ('Extra data charges',                          'Price / charges'),
 ('Long distance charges',                       'Price / charges'),
 ('Lack of affordable download/upload speed',    'Price / charges'),
 ('Network reliability',                         'Product / service quality'),
 ('Product dissatisfaction',                     'Product / service quality'),
 ('Service dissatisfaction',                     'Product / service quality'),
 ('Lack of self-service on Website',             'Product / service quality'),
 ('Limited range of services',                   'Product / service quality'),
 ('Moved',                                       'Life event / unknown'),
 ('Deceased',                                    'Life event / unknown'),
 ('Don''t know',                                 'Life event / unknown');

SELECT COALESCE(m.reason_theme, 'Unmapped')                         AS reason_theme,
       COUNT(*)                                                     AS churned_customers,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)           AS pct_of_churn,
       ROUND(SUM(c.monthly_charges), 0)                             AS monthly_revenue_lost
FROM customers c
LEFT JOIN churn_reason_map m ON m.churn_reason = c.churn_reason
WHERE c.churn_value = 1
GROUP BY reason_theme
ORDER BY churned_customers DESC;
-- Result: Competitor 33.2%, Product/service quality 22.8%, Support 19.6%, Price/charges 13.0%, Life event/unknown 11.4%.
-- Business interpretation: A third of churners cite a competitor, but only 13% cite price directly. Support attitude and expertise (about 20%) is something the company controls. Reasons are self-reported and the theme grouping is my own judgement.

-- S4 ---------------------------------------------------------------
-- Business question: Which concrete customer profiles are highest-risk AND large enough to act on?
-- SQL logic: CTE builds a profile (contract x internet x tenure band); the outer query keeps
--            profiles with >= 150 customers and sorts by churn rate. HAVING-style filter is
--            applied in the outer WHERE because the CTE already aggregated.
WITH profile AS (
    SELECT contract,
           internet_service,
           CASE WHEN tenure_months <= 12 THEN '0-12 mo' ELSE '13+ mo' END AS tenure_band,
           COUNT(*)                                       AS customers,
           SUM(churn_value)                               AS churned,
           ROUND(100.0 * SUM(churn_value) / COUNT(*), 1)  AS churn_rate_pct,
           ROUND(SUM(CASE WHEN churn_value = 1 THEN monthly_charges END), 0) AS monthly_revenue_lost
    FROM customers
    GROUP BY contract, internet_service, tenure_band
)
SELECT *
FROM profile
WHERE customers >= 150
ORDER BY churn_rate_pct DESC
LIMIT 8;
-- Result: Month-to-month + Fiber + 0-12 months: 916 customers, 70.2% churned, $53,178 monthly revenue lost (38% of all lost revenue).
-- Business interpretation: This one profile is the clearest place to focus retention effort.

