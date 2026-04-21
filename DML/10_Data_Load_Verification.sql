-- =============================================================
-- FILE   : DML/10_verify_data_load.sql
-- PROJECT: Hospital Management System (DMDD 6210 - Table Turners)
-- RUN AS : hms_admin
-- PURPOSE: Verify all tables loaded with expected row counts
--          and validate key business rules after full DML run
-- DEPENDS: DML/01 through DML/09 must all complete first
-- SAFE   : Read-only — no INSERT/UPDATE/DELETE
-- =============================================================
 
 
-- =============================================================
-- SECTION 1: ROW COUNT VERIFICATION — EXPECTED VS ACTUAL
-- FAILs appear first for quick scanning
-- =============================================================
 
SELECT
    tbl                                                         AS table_name,
    cnt                                                         AS actual_count,
    expected                                                    AS expected_min,
    CASE WHEN cnt >= expected THEN '✓ PASS' ELSE '✗ FAIL' END  AS status
FROM (
    SELECT 'DEPARTMENT'        AS tbl, COUNT(*) AS cnt,   5   AS expected FROM DEPARTMENT
    UNION ALL
    SELECT 'EMPLOYEE',                 COUNT(*),          23              FROM EMPLOYEE
    UNION ALL
    SELECT 'PATIENT',                  COUNT(*),          200             FROM PATIENT
    UNION ALL
    SELECT 'ROOM',                     COUNT(*),          50              FROM ROOM
    UNION ALL
    SELECT 'BED',                      COUNT(*),          75              FROM BED
    UNION ALL
    SELECT 'INSURANCE',                COUNT(*),          6               FROM INSURANCE
    UNION ALL
    SELECT 'PATIENT_INSURANCE',        COUNT(*),          100             FROM PATIENT_INSURANCE
    UNION ALL
    SELECT 'DOCTOR_SCHEDULE',          COUNT(*),          10              FROM DOCTOR_SCHEDULE
    UNION ALL
    SELECT 'EMPLOYEE_SCHEDULE',        COUNT(*),          200             FROM EMPLOYEE_SCHEDULE
    UNION ALL
    SELECT 'DOCTOR_VACATION',          COUNT(*),          3               FROM DOCTOR_VACATION
    UNION ALL
    SELECT 'APPOINTMENT',              COUNT(*),          50              FROM APPOINTMENT
    UNION ALL
    SELECT 'APPOINTMENT_HISTORY',      COUNT(*),          50              FROM APPOINTMENT_HISTORY
    UNION ALL
    SELECT 'ADMISSION',                COUNT(*),          10              FROM ADMISSION
    UNION ALL
    SELECT 'BILLING',                  COUNT(*),          18              FROM BILLING
    UNION ALL
    SELECT 'PAYMENT',                  COUNT(*),          14              FROM PAYMENT
    UNION ALL
    SELECT 'PRESCRIPTION',             COUNT(*),          0               FROM PRESCRIPTION
)
ORDER BY
    CASE WHEN cnt >= expected THEN 1 ELSE 0 END,  -- FAILs first
    tbl;
 
 
-- =============================================================
-- SECTION 2: BUSINESS RULE VALIDATIONS
-- Each returns PASS (0 violations) or FAIL (n violations)
-- =============================================================
 
-- BR1: All minors under 18 must have a guardian
SELECT 'BR1 - Minor patients have guardian'    AS business_rule,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END AS status,
    COUNT(*) AS violations
FROM PATIENT
WHERE guardian_id IS NULL
  AND MONTHS_BETWEEN(SYSDATE, dob) / 12 < 18;
 
-- BR2: No patient has more than 1 PRIMARY insurance
SELECT 'BR2 - No duplicate primary insurance'  AS business_rule,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END AS status,
    COUNT(*) AS violations
FROM (
    SELECT PATIENT_patient_id
    FROM   PATIENT_INSURANCE
    WHERE  is_primary = 'Y'
    GROUP  BY PATIENT_patient_id
    HAVING COUNT(*) > 1
);
 
-- BR3: Active admissions must have their bed marked occupied
SELECT 'BR3 - Active admission bed occupied'   AS business_rule,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END AS status,
    COUNT(*) AS violations
FROM ADMISSION a
JOIN BED b ON b.bed_id = a.BED_bed_id
WHERE a.status      = 'ACTIVE'
  AND b.is_occupied = 'N';
 
-- BR4: Discharged admissions must have a discharge_date
SELECT 'BR4 - Discharged has discharge_date'   AS business_rule,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END AS status,
    COUNT(*) AS violations
FROM ADMISSION
WHERE status         = 'DISCHARGED'
  AND discharge_date IS NULL;
 
-- BR5: net_amount = total_amount - discount (within $0.01)
SELECT 'BR5 - Billing net amount accuracy'     AS business_rule,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END AS status,
    COUNT(*) AS violations
FROM BILLING
WHERE ABS(net_amount - (total_amount - NVL(discount, 0))) > 0.01;
 
-- BR6: All appointments link to a valid employee_schedule slot
SELECT 'BR6 - Appointment bridge FK valid'     AS business_rule,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END AS status,
    COUNT(*) AS violations
FROM APPOINTMENT a
WHERE NOT EXISTS (
    SELECT 1 FROM EMPLOYEE_SCHEDULE es
    WHERE es.bridge_id = a.EMPLOYEE_SCHEDULE_bridge_id
);
 
-- BR7: All doctors belong to a valid department
SELECT 'BR7 - Doctor department valid'         AS business_rule,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END AS status,
    COUNT(*) AS violations
FROM EMPLOYEE e
WHERE role = 'DOCTOR'
  AND NOT EXISTS (
    SELECT 1 FROM DEPARTMENT d
    WHERE d.department_id = e.DEPARTMENT_department_id
);
 
-- BR8: All payment amounts are positive
SELECT 'BR8 - Payment amounts positive'        AS business_rule,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END AS status,
    COUNT(*) AS violations
FROM PAYMENT
WHERE amount <= 0;
 
 
-- =============================================================
-- SECTION 3: FULL DASHBOARD SUMMARY
-- =============================================================
 
SELECT
    (SELECT COUNT(*) FROM PATIENT WHERE guardian_id IS NULL)    AS adult_patients,
    (SELECT COUNT(*) FROM PATIENT WHERE guardian_id IS NOT NULL) AS minor_patients,
    (SELECT COUNT(*) FROM EMPLOYEE WHERE role = 'DOCTOR')       AS doctors,
    (SELECT COUNT(*) FROM EMPLOYEE WHERE role = 'NURSE')        AS nurses,
    (SELECT COUNT(*) FROM EMPLOYEE WHERE role = 'ADMIN')        AS admins,
    (SELECT COUNT(*) FROM ROOM)                                  AS total_rooms,
    (SELECT COUNT(*) FROM BED)                                   AS total_beds,
    (SELECT COUNT(*) FROM BED WHERE is_occupied = 'Y')          AS occupied_beds,
    (SELECT COUNT(*) FROM APPOINTMENT WHERE status='SCHEDULED')  AS scheduled_appts,
    (SELECT COUNT(*) FROM APPOINTMENT WHERE status='COMPLETED')  AS completed_appts,
    (SELECT COUNT(*) FROM APPOINTMENT WHERE status='CANCELLED')  AS cancelled_appts,
    (SELECT COUNT(*) FROM ADMISSION  WHERE status='ACTIVE')      AS active_admissions,
    (SELECT COUNT(*) FROM BILLING)                               AS total_bills,
    (SELECT ROUND(SUM(net_amount),2) FROM BILLING)               AS total_billed,
    (SELECT ROUND(SUM(amount),2)     FROM PAYMENT)               AS total_collected
FROM DUAL;
 
BEGIN
    DBMS_OUTPUT.PUT_LINE('DML/10 verification complete. Check FAIL rows above if any.');
END;
/