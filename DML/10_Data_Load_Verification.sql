-- =============================================================
-- FILE   : DML/10_Data_Load_Verification.sql
-- PROJECT: Hospital Management System (DMDD 6210 - Table Turners)
-- RUN AS : hms_admin
-- PURPOSE: Verify all data loaded correctly with PASS/FAIL checks
-- =============================================================
 
SET SERVEROUTPUT ON;
 
-- =============================================================
-- SECTION 1: TABLE ROW COUNT VERIFICATION
-- =============================================================
 
SELECT * FROM (
    SELECT 'ADMISSION'           AS table_name, COUNT(*) AS actual_count, 10  AS expected_min FROM ADMISSION
    UNION ALL
    SELECT 'APPOINTMENT',                        COUNT(*),                 50               FROM APPOINTMENT
    UNION ALL
    SELECT 'APPOINTMENT_HISTORY',                COUNT(*),                 50               FROM APPOINTMENT_HISTORY
    UNION ALL
    SELECT 'BED',                                COUNT(*),                 75               FROM BED
    UNION ALL
    SELECT 'BILLING',                            COUNT(*),                 10               FROM BILLING
    UNION ALL
    SELECT 'DEPARTMENT',                         COUNT(*),                  5               FROM DEPARTMENT
    UNION ALL
    SELECT 'DOCTOR_SCHEDULE',                    COUNT(*),                 10               FROM DOCTOR_SCHEDULE
    UNION ALL
    SELECT 'DOCTOR_VACATION',                    COUNT(*),                  3               FROM DOCTOR_VACATION
    UNION ALL
    SELECT 'EMPLOYEE',                           COUNT(*),                 23               FROM EMPLOYEE
    UNION ALL
    SELECT 'EMPLOYEE_SCHEDULE',                  COUNT(*),                200               FROM EMPLOYEE_SCHEDULE
    UNION ALL
    SELECT 'INSURANCE',                          COUNT(*),                  6               FROM INSURANCE
    UNION ALL
    SELECT 'PATIENT',                            COUNT(*),                200               FROM PATIENT
    UNION ALL
    SELECT 'PATIENT_INSURANCE',                  COUNT(*),                100               FROM PATIENT_INSURANCE
    UNION ALL
    SELECT 'PAYMENT',                            COUNT(*),                  6               FROM PAYMENT
    UNION ALL
    SELECT 'PRESCRIPTION',                       COUNT(*),                  0               FROM PRESCRIPTION
    UNION ALL
    SELECT 'ROOM',                               COUNT(*),                 50               FROM ROOM
)
ORDER BY table_name;
 
 
-- =============================================================
-- SECTION 2: BUSINESS RULE VALIDATIONS
-- =============================================================
 
-- BR1: Minor patients must have guardian
SELECT 'BR1 - Minor patients have guardian' AS business_rule,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END AS status,
    COUNT(*) AS violations
FROM PATIENT
WHERE dob > ADD_MONTHS(SYSDATE, -216)
  AND guardian_id IS NULL;
 
-- BR2: No duplicate primary insurance per patient
SELECT 'BR2 - No duplicate primary insurance' AS business_rule,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END AS status,
    COUNT(*) AS violations
FROM (
    SELECT PATIENT_patient_id, COUNT(*) AS cnt
    FROM   PATIENT_INSURANCE
    WHERE  is_primary = 'Y'
    GROUP  BY PATIENT_patient_id
    HAVING COUNT(*) > 1
);
 
-- BR3: Active admissions must have their bed marked occupied
SELECT 'BR3 - Active admission bed occupied' AS business_rule,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END AS status,
    COUNT(*) AS violations
FROM ADMISSION a
JOIN BED b ON b.bed_id = a.BED_bed_id
WHERE a.status      = 'ACTIVE'
  AND b.is_occupied = 'N';
 
-- BR4: Discharged admissions must have discharge date
SELECT 'BR4 - Discharged has discharge_date' AS business_rule,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END AS status,
    COUNT(*) AS violations
FROM ADMISSION
WHERE status         = 'DISCHARGED'
  AND discharge_date IS NULL;
 
-- BR5: Billing net amount = total - discount
SELECT 'BR5 - Billing net amount accuracy' AS business_rule,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END AS status,
    COUNT(*) AS violations
FROM BILLING
WHERE ABS(net_amount - (total_amount - discount)) > 0.01;
 
-- BR6: Appointment schedule bridge FK valid
SELECT 'BR6 - Appointment bridge FK valid' AS business_rule,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END AS status,
    COUNT(*) AS violations
FROM APPOINTMENT a
WHERE NOT EXISTS (
    SELECT 1 FROM EMPLOYEE_SCHEDULE es
    WHERE es.bridge_id = a.EMPLOYEE_SCHEDULE_bridge_id
);
 
-- BR7: Doctor assigned to valid department
SELECT 'BR7 - Doctor department valid' AS business_rule,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END AS status,
    COUNT(*) AS violations
FROM EMPLOYEE e
WHERE e.role = 'DOCTOR'
  AND NOT EXISTS (
    SELECT 1 FROM DEPARTMENT d
    WHERE d.department_id = e.DEPARTMENT_DEPARTMENT_ID
);
 
-- BR8: Payment amounts must be positive
SELECT 'BR8 - Payment amounts positive' AS business_rule,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END AS status,
    COUNT(*) AS violations
FROM PAYMENT
WHERE amount <= 0;
 
-- BR9: Emergency admissions have admission_type = EMERGENCY
SELECT 'BR9 - Emergency appts have EMERGENCY admission' AS business_rule,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END AS status,
    COUNT(*) AS violations
FROM APPOINTMENT a
WHERE a.is_emergency = 'Y'
  AND NOT EXISTS (
    SELECT 1 FROM ADMISSION adm
    WHERE adm.PATIENT_PATIENT_ID = a.PATIENT_patient_id
      AND adm.admission_type = 'EMERGENCY'
);
 
 
-- =============================================================
-- SECTION 3: DASHBOARD SUMMARY
-- =============================================================
 
SELECT
    (SELECT COUNT(*) FROM PATIENT WHERE dob <= ADD_MONTHS(SYSDATE,-216)) AS adult_patients,
    (SELECT COUNT(*) FROM PATIENT WHERE dob >  ADD_MONTHS(SYSDATE,-216)) AS minor_patients,
    (SELECT COUNT(*) FROM EMPLOYEE WHERE role = 'DOCTOR') AS doctors,
    (SELECT COUNT(*) FROM EMPLOYEE WHERE role = 'NURSE')  AS nurses,
    (SELECT COUNT(*) FROM EMPLOYEE WHERE role = 'ADMIN')  AS admins,
    (SELECT COUNT(*) FROM ROOM)  AS total_rooms,
    (SELECT COUNT(*) FROM BED)   AS total_beds,
    (SELECT COUNT(*) FROM BED WHERE is_occupied = 'Y') AS occupied_beds,
    (SELECT COUNT(*) FROM APPOINTMENT WHERE status = 'SCHEDULED')  AS scheduled_appts,
    (SELECT COUNT(*) FROM APPOINTMENT WHERE status = 'COMPLETED')  AS completed_appts,
    (SELECT COUNT(*) FROM APPOINTMENT WHERE status = 'CANCELLED')  AS cancelled_appts,
    (SELECT COUNT(*) FROM APPOINTMENT WHERE is_emergency = 'Y')    AS emergency_appts,
    (SELECT COUNT(*) FROM ADMISSION  WHERE status = 'ACTIVE')      AS active_admissions,
    (SELECT COUNT(*) FROM ADMISSION  WHERE admission_type = 'EMERGENCY') AS emergency_admissions,
    (SELECT COUNT(*) FROM BILLING)  AS total_bills,
    (SELECT NVL(SUM(net_amount),0) FROM BILLING) AS total_billed,
    (SELECT NVL(SUM(amount),0)     FROM PAYMENT) AS total_collected
FROM DUAL;
 
BEGIN
    DBMS_OUTPUT.PUT_LINE('DML/10 verification complete. Check FAIL rows above if any.');
END;
/