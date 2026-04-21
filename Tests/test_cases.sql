-- =============================================================
-- FILE   : Tests/test_cases.sql
-- PROJECT: Hospital Management System (DMDD 6210 - Table Turners)
-- RUN AS : hms_admin
-- PURPOSE: Test cases demonstrating business rule validations
--          for all 5 stored procedures
-- =============================================================
 
SET SERVEROUTPUT ON;
 
-- =============================================================
-- 1. BOOK APPOINTMENT
-- =============================================================
 
-- SUCCESS: Valid booking
BEGIN
    book_appointment(
        p_patient_id  => 1,
        p_bridge_id   => 1,
        p_date        => TO_DATE('2026-04-25', 'YYYY-MM-DD'),
        p_time        => TO_DATE('2000-01-01 09:00', 'YYYY-MM-DD HH24:MI'),
        p_reason      => 'Regular checkup'
    );
    DBMS_OUTPUT.PUT_LINE('TEST 1a PASSED: Appointment booked successfully.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('TEST 1a FAILED: ' || SQLERRM);
END;
/
 
-- FAILURE: Duplicate booking (expected ORA-20016)
BEGIN
    book_appointment(
        p_patient_id  => 1,
        p_bridge_id   => 1,
        p_date        => TO_DATE('2026-04-25', 'YYYY-MM-DD'),
        p_time        => TO_DATE('2000-01-01 09:00', 'YYYY-MM-DD HH24:MI'),
        p_reason      => 'Duplicate test'
    );
    DBMS_OUTPUT.PUT_LINE('TEST 1b FAILED: Should have raised duplicate error.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('TEST 1b PASSED: ' || SQLERRM);
END;
/
 
-- FAILURE: Non-existent patient (expected ORA-20010)
BEGIN
    book_appointment(
        p_patient_id  => 9999,
        p_bridge_id   => 1,
        p_date        => TO_DATE('2026-04-26', 'YYYY-MM-DD'),
        p_time        => TO_DATE('2000-01-01 10:00', 'YYYY-MM-DD HH24:MI'),
        p_reason      => 'Invalid patient test'
    );
    DBMS_OUTPUT.PUT_LINE('TEST 1c FAILED: Should have raised patient not found error.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('TEST 1c PASSED: ' || SQLERRM);
END;
/
 
 
-- =============================================================
-- 2. CANCEL APPOINTMENT
-- =============================================================
 
-- FAILURE: Cancel within 24 hours (expected ORA-20023)
BEGIN
    cancel_appointment(
        p_appointment_id => 1
    );
    DBMS_OUTPUT.PUT_LINE('TEST 2a FAILED: Should have raised 24-hour rule error.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('TEST 2a PASSED: ' || SQLERRM);
END;
/
 
-- FAILURE: Non-existent appointment (expected ORA-20020)
BEGIN
    cancel_appointment(
        p_appointment_id => 9999
    );
    DBMS_OUTPUT.PUT_LINE('TEST 2b FAILED: Should have raised appointment not found error.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('TEST 2b PASSED: ' || SQLERRM);
END;
/
 
 
-- =============================================================
-- 3. RESCHEDULE APPOINTMENT
-- =============================================================
 
-- FAILURE: New slot not available (expected ORA-20034)
BEGIN
    reschedule_appointment(
        p_appointment_id => 1,
        p_new_date       => TO_DATE('2026-04-25', 'YYYY-MM-DD'),
        p_new_time       => TO_DATE('2000-01-01 09:00', 'YYYY-MM-DD HH24:MI'),
        p_new_bridge_id  => 1
    );
    DBMS_OUTPUT.PUT_LINE('TEST 3a FAILED: Should have raised slot not available error.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('TEST 3a PASSED: ' || SQLERRM);
END;
/
 
-- FAILURE: Non-existent appointment (expected ORA-20030)
BEGIN
    reschedule_appointment(
        p_appointment_id => 9999,
        p_new_date       => TO_DATE('2026-04-28', 'YYYY-MM-DD'),
        p_new_time       => TO_DATE('2000-01-01 10:00', 'YYYY-MM-DD HH24:MI'),
        p_new_bridge_id  => 2
    );
    DBMS_OUTPUT.PUT_LINE('TEST 3b FAILED: Should have raised appointment not found error.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('TEST 3b PASSED: ' || SQLERRM);
END;
/
 
 
-- =============================================================
-- 4. ADMIT PATIENT
-- =============================================================
 
-- FAILURE: Bed already occupied (expected ORA-20042)
BEGIN
    admit_patient(
        p_patient_id  => 5,
        p_bed_id      => 1,
        p_employee_id => 1,
        p_reason      => 'Fever admission'
    );
    DBMS_OUTPUT.PUT_LINE('TEST 4a FAILED: Should have raised bed occupied error.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('TEST 4a PASSED: ' || SQLERRM);
END;
/
 
-- FAILURE: Non-doctor employee (expected ORA-20045)
BEGIN
    admit_patient(
        p_patient_id  => 5,
        p_bed_id      => 10,
        p_employee_id => 16,
        p_reason      => 'Non-doctor admit test'
    );
    DBMS_OUTPUT.PUT_LINE('TEST 4b FAILED: Should have raised non-doctor error.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('TEST 4b PASSED: ' || SQLERRM);
END;
/
 
-- SUCCESS: Valid admission
BEGIN
    admit_patient(
        p_patient_id  => 150,
        p_bed_id      => 20,
        p_employee_id => 1,
        p_reason      => 'Valid test admission'
    );
    DBMS_OUTPUT.PUT_LINE('TEST 4c PASSED: Patient admitted successfully.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('TEST 4c FAILED: ' || SQLERRM);
END;
/
 
 
-- =============================================================
-- 5. GENERATE BILL
-- =============================================================
 
-- FAILURE: Zero total amount (expected ORA-20051)
BEGIN
    generate_bill(
        p_patient_id     => 1,
        p_admission_id   => 1,
        p_appointment_id => NULL,
        p_total_amount   => 0
    );
    DBMS_OUTPUT.PUT_LINE('TEST 5a FAILED: Should have raised invalid amount error.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('TEST 5a PASSED: ' || SQLERRM);
END;
/
 
-- FAILURE: Both admission and appointment NULL (expected ORA-20052)
BEGIN
    generate_bill(
        p_patient_id     => 1,
        p_admission_id   => NULL,
        p_appointment_id => NULL,
        p_total_amount   => 5000
    );
    DBMS_OUTPUT.PUT_LINE('TEST 5b FAILED: Should have raised no source error.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('TEST 5b PASSED: ' || SQLERRM);
END;
/
 
-- SUCCESS: Valid bill using patient 1 and appointment 1
BEGIN
    generate_bill(
        p_patient_id     => 1,
        p_admission_id   => NULL,
        p_appointment_id => 1,
        p_total_amount   => 5000
    );
    DBMS_OUTPUT.PUT_LINE('TEST 5c PASSED: Bill generated successfully.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('TEST 5c FAILED: ' || SQLERRM);
END;
/
 
 
-- =============================================================
-- VERIFY: Final state after all tests
-- =============================================================
 
SELECT * FROM (
    SELECT 'APPOINTMENT'        AS tbl, COUNT(*) AS cnt FROM APPOINTMENT
    UNION ALL
    SELECT 'APPOINTMENT_HISTORY',       COUNT(*)        FROM APPOINTMENT_HISTORY
    UNION ALL
    SELECT 'ADMISSION',                 COUNT(*)        FROM ADMISSION
    UNION ALL
    SELECT 'BILLING',                   COUNT(*)        FROM BILLING
    UNION ALL
    SELECT 'PAYMENT',                   COUNT(*)        FROM PAYMENT
)
ORDER BY tbl;