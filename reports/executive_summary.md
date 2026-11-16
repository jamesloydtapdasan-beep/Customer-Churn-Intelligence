# Customer Churn: Executive Summary

*Data: 7,043 customers of a California telecom (IBM sample dataset, synthetic), one snapshot. All findings are associations, not proven causes.*

## Business Problem

26.5% of customers (1,869 of 7,043) have churned. Because churners pay more than average, they took **30.5% of monthly revenue** with them: about **$139K a month, or $1.67M a year**. Another **~$71K a month** of revenue from customers still here is exposed if past churn patterns repeat (an estimate, not a forecast). The question: where is the loss concentrated, and what should the company test first?

## Key Finding 1: Churn is concentrated in month-to-month customers, and fiber is the hot spot

**Evidence:**
- Month-to-month customers churn at 42.7% vs 6.8% on other contracts (95% CI for the gap: 34 to 38 points). They are 55% of customers but **89% of churners**.
- Fiber optic customers are 44% of customers but **69% of churners and 82% of lost revenue**. Fiber churns more than DSL under every contract type (month-to-month 54.6% vs 32.2%; two-year 7.2% vs 1.9%).
- The worst profile is **month-to-month, fiber, first 12 months: 916 customers, 70.2% churned, $53K a month lost (38% of all lost revenue)**.

**Business implication:** The loss sits in a narrow, identifiable group. Fiber's extra churn is not just a contract effect, so something about the fiber product, price or competition needs explaining.

## Key Finding 2: The cause is not simply price; competitors and support matter

**Evidence:**
- Churners pay more overall ($74 vs $61 a month), but **within each internet type they pay the same or less** (DSL $49 vs $60, fiber $88 vs $94). The gap reflects product mix, not a price premium.
- Stated reasons: 33% cite a competitor (mostly faster speeds, more data, better offers), 23% product or service quality, **20% support attitude or expertise**, only 13% price or charges.

**Business implication:** A blanket price cut is not supported by this data. Competitive speed and data offers, and the quality of customer support, are the better-evidenced levers. (Reasons are self-reported and grouped by us.)

## Key Finding 3: Churn is highest early and lowest among customers with protection services

**Evidence:**
- Churn is 53% in months 1-6 and 47% in the first year, falling to 5% in months 67-72.
- Among internet customers, churn falls from **56.7% with no protection add-on to 5.3% with all four**. Customers without online security churn at 41.8% (14.6% with it); without tech support 41.6% (15.2% with it). Streaming add-ons show no real difference.
- Electronic-check payers churn at 45% vs 15-19% for other methods, and the gap holds within every contract type.

**Business implication:** The first months are the critical window, and security/support add-ons mark customers who stay. Whether add-ons *cause* retention is unknown: engaged customers may simply buy more.

## Recommended Actions (prioritised by money at stake and strength of evidence)

1. **Pilot a first-year retention offer for month-to-month fiber customers.** Target group: 273 current customers in the highest-risk profile ($22K a month revenue, about $15K at risk). Randomise: offer half a discounted 12-month contract and compare churn after one quarter. This is the only way to learn if the offer *causes* retention.
2. **Investigate fiber competitiveness and reliability.** Run exit interviews and benchmark speed and data plans against the competitors named in exit reasons (higher speeds 189, more data 162, better offers 140). Fiber is 82% of lost revenue, so this has the largest ceiling.
3. **Trial a free 3-month security/tech-support bundle** for internet customers with no protection add-on (1,267 customers, 549 still active, ~$17K a month at risk). Randomise, and track churn, to separate cause from correlation.
4. **Review support quality.** 366 churners (20%) cited support attitude or expertise, about $27K a month. This is within the company's control: audit calls and set service targets.
5. **Test moving electronic-check payers to automatic payment** (1,294 active customers, ~$32K a month at risk), and use the risk model or scorecard to prioritise outreach (contacting the top 20% by predicted risk reaches about half of churners). Treat payment method as a warning flag, not a proven cause.

**Not recommended on this evidence:** targeting by gender (no association), blanket price cuts, or streaming promotions.

*Limitations: single snapshot, synthetic and single-state data, no dates (so forecasts cannot be validated), self-reported reasons. Revenue at risk assumes historical segment churn rates repeat. Model AUC is about 0.85 on held-out data.*
