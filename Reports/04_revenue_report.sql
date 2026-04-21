-- =============================================================
-- FILE   : Reports/04_revenue_report.sql
-- PROJECT: Hospital Management System (DMDD 6210 - Table Turners)
-- RUN AS : hms_admin
-- PURPOSE: Revenue summary — gross, discounts, net, collected,
--          outstanding broken down by month and insurance provider
-- =============================================================
 
-- Monthly revenue breakdown
SELECT
    TO_CHAR(b.bill_date, 'YYYY-MM')         AS month,
    COUNT(b.bill_id)                         AS total_bills,
    SUM(b.total_amount)                      AS gross_revenue,
    SUM(b.discount)                          AS total_discounts,
    SUM(b.net_amount)                        AS net_revenue,
    SUM(NVL(pay.paid, 0))                    AS total_collected,
    SUM(b.net_amount) - SUM(NVL(pay.paid,0)) AS outstanding
FROM   BILLING b
LEFT JOIN (
    SELECT BILLING_bill_id, SUM(amount) AS paid
    FROM   PAYMENT
    GROUP  BY BILLING_bill_id
) pay ON pay.BILLING_bill_id = b.bill_id
WHERE  b.status <> 'CANCELLED'
GROUP  BY TO_CHAR(b.bill_date, 'YYYY-MM')
ORDER  BY month;
 
-- Revenue by insurance provider
SELECT
    NVL(ins.provider_name, 'Self-Pay')      AS insurance_provider,
    COUNT(b.bill_id)                         AS bill_count,
    SUM(b.total_amount)                      AS gross_amount,
    SUM(b.discount)                          AS discount_given,
    SUM(b.net_amount)                        AS net_collected
FROM   BILLING b
LEFT JOIN INSURANCE ins ON ins.insurance_id = b.INSURANCE_insurance_id
WHERE  b.status <> 'CANCELLED'
GROUP  BY NVL(ins.provider_name, 'Self-Pay')  -- fixed: GROUP BY must match SELECT expression
ORDER  BY net_collected DESC;