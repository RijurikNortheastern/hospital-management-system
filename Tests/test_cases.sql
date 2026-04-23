-- =============================================================
-- FILE   : Tests/test_cases.sql
-- PROJECT: Hospital Management System (DMDD 6210 - Table Turners)
-- RUN AS : hms_admin
-- PURPOSE: Test cases demonstrating business rule validations
--          for all 6 stored procedures including emergency module
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
 
-- FAILURE: Max 5 appointments per doctor per day (expected ORA-20018)
DECLARE
    v_available_bridge NUMBER;
BEGIN
    SELECT es.bridge_id INTO v_available_bridge
    FROM   EMPLOYEE_SCHEDULE es
    JOIN   EMPLOYEE e ON e.employee_id = es.EMPLOYEE_employee_id
    WHERE  e.role = 'DOCTOR'
      AND  es.status = 'AVAILABLE'
      AND  (SELECT COUNT(*) FROM APPOINTMENT a
            JOIN EMPLOYEE_SCHEDULE es2 ON es2.bridge_id = a.EMPLOYEE_SCHEDULE_bridge_id
            WHERE es2.EMPLOYEE_employee_id = es.EMPLOYEE_employee_id
            AND a.appointment_date = TRUNC(SYSDATE) + 5
            AND a.status <> 'CANCELLED') >= 5
      AND  ROWNUM = 1;
 
    book_appointment(
        p_patient_id  => 50,
        p_bridge_id   => v_available_bridge,
        p_date        => TRUNC(SYSDATE) + 5,
        p_time        => TO_DATE('2000-01-01 09:00', 'YYYY-MM-DD HH24:MI'),
        p_reason      => 'Max appointments test'
    );
    DBMS_OUTPUT.PUT_LINE('TEST 1d FAILED: Should have raised max appointments error.');
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('TEST 1d SKIPPED: No doctor with 5+ appointments found in test data.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('TEST 1d PASSED: ' || SQLERRM);
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
-- TEST 4a: Bed already occupied (expected ORA-20042)
BEGIN
    admit_patient(
        p_patient_id  => 5,
        p_bed_id      => 1,   -- ← this is already occupied by regular admission 
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
-- 6. BOOK EMERGENCY
-- =============================================================
 
-- SUCCESS: Valid emergency booking — full flow
BEGIN
    DBMS_OUTPUT.PUT_LINE('TEST 6a: Valid emergency booking - full flow');
    book_emergency(
        p_patient_id => 1,
        p_dept_id    => 1,
        p_reason     => 'Chest pain - emergency',
        p_date       => TRUNC(SYSDATE)
    );
    DBMS_OUTPUT.PUT_LINE('TEST 6a PASSED: Emergency complete - appointment + admission + bill created.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('TEST 6a FAILED: ' || SQLERRM);
END;
/
 
-- FAILURE: Non-existent patient (expected ORA-20060)
BEGIN
    DBMS_OUTPUT.PUT_LINE('TEST 6b: Non-existent patient emergency');
    book_emergency(
        p_patient_id => 9999,
        p_dept_id    => 1,
        p_reason     => 'Test',
        p_date       => TRUNC(SYSDATE)
    );
    DBMS_OUTPUT.PUT_LINE('TEST 6b FAILED: Should have raised patient not found error.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -20060 THEN
            DBMS_OUTPUT.PUT_LINE('TEST 6b PASSED: ORA-20060 - ' || SQLERRM);
        ELSE
            DBMS_OUTPUT.PUT_LINE('TEST 6b FAILED: Wrong error - ' || SQLERRM);
        END IF;
END;
/
 
-- FAILURE: Invalid department (expected ORA-20061)
BEGIN
    DBMS_OUTPUT.PUT_LINE('TEST 6c: No doctors in department');
    book_emergency(
        p_patient_id => 1,
        p_dept_id    => 9999,
        p_reason     => 'Test',
        p_date       => TRUNC(SYSDATE)
    );
    DBMS_OUTPUT.PUT_LINE('TEST 6c FAILED: Should have raised no doctor error.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -20061 THEN
            DBMS_OUTPUT.PUT_LINE('TEST 6c PASSED: ORA-20061 - ' || SQLERRM);
        ELSE
            DBMS_OUTPUT.PUT_LINE('TEST 6c FAILED: Wrong error - ' || SQLERRM);
        END IF;
END;
/
 
-- SUCCESS: Verify ICU bed assigned
DECLARE
    v_bed_type       VARCHAR2(20);
    v_admission_type VARCHAR2(20);
BEGIN
    DBMS_OUTPUT.PUT_LINE('TEST 6d: ICU bed priority check');
    SELECT r.room_type, a.admission_type
    INTO   v_bed_type, v_admission_type
    FROM   ADMISSION a
    JOIN   BED b  ON b.bed_id  = a.BED_BED_ID
    JOIN   ROOM r ON r.room_id = b.ROOM_room_id
    WHERE  a.admission_type = 'EMERGENCY'
      AND  ROWNUM = 1;
 
    IF v_bed_type = 'ICU' THEN
        DBMS_OUTPUT.PUT_LINE('TEST 6d PASSED: ICU bed assigned — room type = ' || v_bed_type);
    ELSE
        DBMS_OUTPUT.PUT_LINE('TEST 6d INFO: Fallback bed assigned — room type = ' || v_bed_type);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('TEST 6d FAILED: ' || SQLERRM);
END;
/
 
-- SUCCESS: Verify bill auto-generated
DECLARE
    v_bill_status VARCHAR2(20);
    v_amount      NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('TEST 6e: Auto-bill generation check');
    SELECT b.status, b.total_amount
    INTO   v_bill_status, v_amount
    FROM   BILLING b
    JOIN   ADMISSION a ON a.admission_id = b.ADMISSION_ADMISSION_ID
    WHERE  a.admission_type = 'EMERGENCY'
      AND  ROWNUM = 1;
 
    DBMS_OUTPUT.PUT_LINE('TEST 6e PASSED: Bill auto-generated — status = ' ||
                          v_bill_status || '  amount = $' || v_amount);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('TEST 6e FAILED: ' || SQLERRM);
END;
/
 
-- FAILURE: Invalid department no doctors (expected ORA-20061)
BEGIN
    DBMS_OUTPUT.PUT_LINE('TEST 6f: Invalid department no doctors');
    book_emergency(
        p_patient_id => 1,
        p_dept_id    => 9999,
        p_reason     => 'Test',
        p_date       => TRUNC(SYSDATE)
    );
    DBMS_OUTPUT.PUT_LINE('TEST 6f FAILED: Should have errored.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -20061 THEN
            DBMS_OUTPUT.PUT_LINE('TEST 6f PASSED: ORA-20061 - ' || SQLERRM);
        ELSE
            DBMS_OUTPUT.PUT_LINE('TEST 6f FAILED: Wrong error - ' || SQLERRM);
        END IF;
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
 
-- Verify emergency appointments with admission and bill
SELECT
    a.appointment_id,
    a.PATIENT_patient_id        AS patient_id,
    a.status                    AS appt_status,
    a.is_emergency,
    adm.admission_type,
    adm.status                  AS admission_status,
    b.total_amount,
    b.status                    AS bill_status
FROM   APPOINTMENT a
LEFT JOIN ADMISSION adm ON adm.PATIENT_PATIENT_ID = a.PATIENT_patient_id
                       AND adm.admission_type      = 'EMERGENCY'
LEFT JOIN BILLING b     ON b.ADMISSION_ADMISSION_ID = adm.admission_id
WHERE  a.is_emergency = 'Y'
ORDER BY a.appointment_id;

SELECT admission_id, BED_BED_ID, status, admission_type
FROM ADMISSION
WHERE status = 'ACTIVE'
ORDER BY admission_id;