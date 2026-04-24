-- =============================================================
-- FILE   : demo_script.sql
-- PROJECT: Hospital Management System (DMDD 6210 - Table Turners)
-- RUN AS : hms_admin
-- PURPOSE: Complete demo script for professor presentation
-- HOW TO RUN: Run run_all.sql first, then run this script
-- =============================================================
 
SET SERVEROUTPUT ON SIZE UNLIMITED;
 
-- =============================================================
-- SECTION 1: DATABASE SUMMARY
-- Shows total count of all key entities in the system
-- =============================================================
 
SELECT 'Patients'        AS category, COUNT(*) AS total FROM PATIENT
UNION ALL
SELECT 'Doctors',        COUNT(*) FROM EMPLOYEE WHERE role='DOCTOR'
UNION ALL
SELECT 'Nurses',         COUNT(*) FROM EMPLOYEE WHERE role='NURSE'
UNION ALL
SELECT 'Rooms',          COUNT(*) FROM ROOM
UNION ALL
SELECT 'Total Beds',     COUNT(*) FROM BED
UNION ALL
SELECT 'Available Beds', COUNT(*) FROM BED WHERE is_occupied='N'
UNION ALL
SELECT 'Occupied Beds',  COUNT(*) FROM BED WHERE is_occupied='Y'
UNION ALL
SELECT 'Appointments',   COUNT(*) FROM APPOINTMENT
UNION ALL
SELECT 'Admissions',     COUNT(*) FROM ADMISSION
UNION ALL
SELECT 'Bills',          COUNT(*) FROM BILLING;
 
-- =============================================================
-- SECTION 2: AVAILABLE DOCTOR SLOTS
-- Shows first 5 available schedule slots across all doctors
-- bridge_id is the unique ID for each doctor-schedule slot
-- This is what patient needs to book an appointment
-- =============================================================
 
SELECT
    es.bridge_id,
    e.first_name || ' ' || e.last_name AS doctor_name,
    e.specialization,
    ds.day_of_week,
    TO_CHAR(ds.start_time, 'HH24:MI') AS shift_start,
    TO_CHAR(ds.end_time,   'HH24:MI') AS shift_end,
    es.status,
    es.availability_date
FROM EMPLOYEE_SCHEDULE es
JOIN EMPLOYEE e         ON e.employee_id   = es.EMPLOYEE_employee_id
JOIN DOCTOR_SCHEDULE ds ON ds.schedule_id  = es.DOCTOR_SCHEDULE_schedule_id
WHERE es.status = 'AVAILABLE'
AND   e.role    = 'DOCTOR'
AND   ROWNUM   <= 5
ORDER BY es.bridge_id;
 
-- =============================================================
-- SECTION 3: BOOK APPOINTMENT - SUCCESS CASE
-- Patient 10 books with Dr_2 using bridge_id = 21
-- Expected: Appointment created with status = SCHEDULED
-- Slot bridge_id 21 will change to UNAVAILABLE
-- History record logged with action = CREATED
-- =============================================================
 
BEGIN
    book_appointment(
        p_patient_id => 10,
        p_bridge_id  => 21,
        p_date       => TRUNC(SYSDATE) + 7,
        p_time       => TRUNC(SYSDATE) + 7 + 9/24,
        p_reason     => 'Regular checkup - Demo'
    );
END;
/
 
-- Verify appointment was created successfully
SELECT
    a.appointment_id,
    p.first_name || ' ' || p.last_name AS patient_name,
    e.first_name || ' ' || e.last_name AS doctor_name,
    a.appointment_date,
    a.status,
    a.reason
FROM APPOINTMENT a
JOIN PATIENT p ON p.patient_id = a.PATIENT_patient_id
JOIN EMPLOYEE_SCHEDULE es ON es.bridge_id = a.EMPLOYEE_SCHEDULE_bridge_id
JOIN EMPLOYEE e ON e.employee_id = es.EMPLOYEE_employee_id
WHERE a.reason = 'Regular checkup - Demo';
 
-- =============================================================
-- SECTION 4: BOOK APPOINTMENT - ERROR CASES
-- Demonstrates all validation errors in book_appointment()
-- =============================================================
 
-- ERROR 1: Patient ID 9999 does not exist in PATIENT table
-- Expected: ORA-20010
BEGIN
    book_appointment(
        p_patient_id => 9999,
        p_bridge_id  => 22,
        p_date       => TRUNC(SYSDATE) + 7,
        p_time       => TRUNC(SYSDATE) + 7 + 9/24,
        p_reason     => 'Test'
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR 1 - Patient not found: ' || SQLERRM);
END;
/
 
-- ERROR 2: bridge_id 1 is UNAVAILABLE (used by emergency patient)
-- Expected: ORA-20012
BEGIN
    book_appointment(
        p_patient_id => 10,
        p_bridge_id  => 1,
        p_date       => TRUNC(SYSDATE) + 7,
        p_time       => TRUNC(SYSDATE) + 7 + 9/24,
        p_reason     => 'Test'
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR 2 - Slot unavailable: ' || SQLERRM);
END;
/
 
-- ERROR 3: Dr_1 is on approved vacation Apr 28 - May 3
-- bridge_id 4 belongs to Dr_1 on Apr 29
-- Expected: ORA-20017
BEGIN
    book_appointment(
        p_patient_id => 10,
        p_bridge_id  => 4,
        p_date       => TO_DATE('2026-04-29','YYYY-MM-DD'),
        p_time       => TO_DATE('2026-04-29 09:00','YYYY-MM-DD HH24:MI'),
        p_reason     => 'Test vacation block'
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR 3 - Doctor on vacation: ' || SQLERRM);
END;
/
 
-- =============================================================
-- SECTION 5: CANCEL APPOINTMENT
-- Demonstrates cancel validation and success
-- =============================================================
 
-- ERROR: Appointment 10 happened today - less than 24 hours away
-- Expected: ORA-20023 - 24 hour cancellation rule violated
BEGIN
    cancel_appointment(p_appointment_id => 10);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('CANCEL ERROR - 24hr rule: ' || SQLERRM);
END;
/
 
-- SUCCESS: Cancel the appointment we just booked in Section 3
-- It is 7 days in future so cancellation is allowed
-- Slot bridge_id 21 will go back to AVAILABLE
DECLARE
    v_appt_id NUMBER;
BEGIN
    SELECT appointment_id INTO v_appt_id
    FROM   APPOINTMENT
    WHERE  reason = 'Regular checkup - Demo'
    AND    status = 'SCHEDULED'
    AND    ROWNUM = 1;
    cancel_appointment(p_appointment_id => v_appt_id);
    DBMS_OUTPUT.PUT_LINE('SUCCESS - Appointment ' || v_appt_id || ' cancelled!');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('CANCEL ERROR: ' || SQLERRM);
END;
/
 
-- =============================================================
-- SECTION 6: RESCHEDULE APPOINTMENT
-- Book an appointment then move it to a different slot and date
-- Demonstrates: old slot freed, new slot booked, history logged
-- =============================================================
 
-- Step 1: Book appointment for patient 20 using bridge_id 22
BEGIN
    book_appointment(
        p_patient_id => 20,
        p_bridge_id  => 22,
        p_date       => TRUNC(SYSDATE) + 10,
        p_time       => TRUNC(SYSDATE) + 10 + 9/24,
        p_reason     => 'To be rescheduled - Demo'
    );
END;
/
 
-- Step 2: Reschedule to bridge_id 23 on a different date
-- Old slot 22 will become AVAILABLE
-- New slot 23 will become UNAVAILABLE
-- History will show CREATED then RESCHEDULED
DECLARE
    v_appt_id NUMBER;
BEGIN
    SELECT appointment_id INTO v_appt_id
    FROM   APPOINTMENT
    WHERE  reason = 'To be rescheduled - Demo'
    AND    status = 'SCHEDULED'
    AND    ROWNUM = 1;
    reschedule_appointment(
        p_appointment_id => v_appt_id,
        p_new_bridge_id  => 23,
        p_new_date       => TRUNC(SYSDATE) + 12,
        p_new_time       => TRUNC(SYSDATE) + 12 + 14/24
    );
    DBMS_OUTPUT.PUT_LINE('SUCCESS - Appointment ' || v_appt_id || ' rescheduled!');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('RESCHEDULE ERROR: ' || SQLERRM);
END;
/
 
-- Verify history shows both CREATED and RESCHEDULED actions
SELECT
    ah.action,
    ah.action_date,
    ah.old_date,
    ah.new_date,
    ah.notes
FROM APPOINTMENT_HISTORY ah
JOIN APPOINTMENT a ON a.appointment_id = ah.APPOINTMENT_appointment_id
WHERE a.reason = 'To be rescheduled - Demo'
ORDER BY ah.history_id;
 
-- =============================================================
-- SECTION 7: ADMIT PATIENT
-- Demonstrates bed validation, role validation and success
-- =============================================================
 
-- Show 5 available GENERAL beds before admission
SELECT
    b.bed_id,
    r.room_number,
    r.room_type,
    b.bed_number,
    b.is_occupied
FROM BED b
JOIN ROOM r ON r.room_id = b.ROOM_room_id
WHERE b.is_occupied = 'N'
AND   r.room_type   = 'GENERAL'
AND   ROWNUM       <= 5;
 
-- ERROR 1: Bed 1 is occupied by emergency patient First_50
-- Expected: ORA-20042 - bed already occupied
BEGIN
    admit_patient(
        p_patient_id  => 30,
        p_bed_id      => 1,
        p_employee_id => 2,
        p_reason      => 'Test occupied bed'
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ADMIT ERROR 1 - Bed occupied: ' || SQLERRM);
END;
/
 
-- ERROR 2: Employee 16 is a NURSE not a DOCTOR
-- Only doctors can admit patients
-- Expected: ORA-20045
BEGIN
    admit_patient(
        p_patient_id  => 30,
        p_bed_id      => 30,
        p_employee_id => 16,
        p_reason      => 'Test nurse admit'
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ADMIT ERROR 2 - Not a doctor: ' || SQLERRM);
END;
/
 
-- SUCCESS: Patient 30 admitted to bed 30 by Doctor 3
-- Trigger trg_mark_bed_occupied will fire and mark bed 30 as Y
BEGIN
    admit_patient(
        p_patient_id  => 30,
        p_bed_id      => 30,
        p_employee_id => 3,
        p_reason      => 'Post surgery monitoring - Demo'
    );
END;
/
 
-- Verify trigger marked bed 30 as occupied (is_occupied = Y)
SELECT bed_id, bed_number, is_occupied
FROM   BED
WHERE  bed_id = 30;
 
-- =============================================================
-- SECTION 8: GENERATE BILL WITH INSURANCE DISCOUNT
-- Shows insurance lookup, discount calculation, net amount
-- =============================================================
 
-- First check patient 30 insurance coverage
-- Max Bupa covers 65% so patient pays only 35%
SELECT
    p.first_name || ' ' || p.last_name AS patient_name,
    i.provider_name,
    i.coverage_pct,
    pi.is_primary
FROM PATIENT_INSURANCE pi
JOIN PATIENT    p ON p.patient_id   = pi.PATIENT_patient_id
JOIN INSURANCE  i ON i.insurance_id = pi.INSURANCE_insurance_id
WHERE pi.PATIENT_patient_id = 30
AND   pi.is_primary = 'Y';
 
-- ERROR: Total amount = 0 is not allowed
-- Expected: ORA-20051
BEGIN
    generate_bill(
        p_patient_id     => 30,
        p_total_amount   => 0,
        p_admission_id   => NULL,
        p_appointment_id => 1
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('BILL ERROR - Zero amount: ' || SQLERRM);
END;
/
 
-- SUCCESS: Generate bill for patient 30
-- Total = $8000, Max Bupa covers 65% = $5200 discount
-- Patient pays only $2800 net amount
DECLARE
    v_adm_id NUMBER;
BEGIN
    SELECT admission_id INTO v_adm_id
    FROM   ADMISSION
    WHERE  PATIENT_PATIENT_ID = 30
    AND    status = 'ACTIVE'
    AND    ROWNUM = 1;
    generate_bill(
        p_patient_id     => 30,
        p_total_amount   => 8000,
        p_admission_id   => v_adm_id,
        p_appointment_id => NULL
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('BILL ERROR: ' || SQLERRM);
END;
/
 
-- Verify bill with insurance discount applied
SELECT
    b.bill_id,
    p.first_name || ' ' || p.last_name AS patient_name,
    b.total_amount,
    b.discount,
    b.net_amount,
    b.status,
    i.provider_name,
    i.coverage_pct
FROM BILLING b
JOIN PATIENT p ON p.patient_id = b.PATIENT_PATIENT_ID
LEFT JOIN INSURANCE i ON i.insurance_id = b.INSURANCE_INSURANCE_ID
WHERE b.PATIENT_PATIENT_ID = 30
ORDER BY b.bill_id DESC;
 
-- =============================================================
-- SECTION 9: EMERGENCY MODULE - book_emergency()
-- Auto assigns doctor, ICU bed, admission and bill in one call
-- No manual selection needed - fully automated
-- =============================================================
 
-- Show available ICU beds before emergency
-- Emergency patients get ICU priority over GENERAL beds
SELECT
    b.bed_id,
    r.room_number,
    r.room_type,
    b.bed_number,
    b.is_occupied
FROM BED b
JOIN ROOM r ON r.room_id = b.ROOM_room_id
WHERE r.room_type   = 'ICU'
AND   b.is_occupied = 'N'
AND   ROWNUM       <= 5;
 
-- ERROR 1: Patient 9999 does not exist
-- Expected: ORA-20060
BEGIN
    book_emergency(
        p_patient_id => 9999,
        p_dept_id    => 1,
        p_reason     => 'Test error',
        p_date       => TRUNC(SYSDATE)
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('EMERGENCY ERROR 1 - Patient: ' || SQLERRM);
END;
/
 
-- ERROR 2: Department 9999 does not exist - no doctors found
-- Expected: ORA-20061
BEGIN
    book_emergency(
        p_patient_id => 70,
        p_dept_id    => 9999,
        p_reason     => 'Test error',
        p_date       => TRUNC(SYSDATE)
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('EMERGENCY ERROR 2 - No doctors: ' || SQLERRM);
END;
/
 
-- SUCCESS: Patient 70 emergency in Neurology dept
-- System auto finds: doctor, slot, ICU bed
-- Auto creates: appointment, admission, bill ($5000)
-- All done in ONE procedure call!
BEGIN
    book_emergency(
        p_patient_id => 70,
        p_dept_id    => 2,
        p_reason     => 'Severe stroke symptoms - Demo Emergency',
        p_date       => TRUNC(SYSDATE)
    );
END;
/
 
-- Verify complete emergency chain:
-- appointment (is_emergency=Y) + admission (EMERGENCY) + bed (ICU) + bill ($5000)
SELECT
    a.appointment_id,
    a.is_emergency,
    p.first_name || ' ' || p.last_name AS patient_name,
    e.first_name || ' ' || e.last_name AS doctor_name,
    adm.admission_type,
    adm.status AS admission_status,
    b.bed_id,
    r.room_type,
    bi.total_amount,
    bi.status AS bill_status
FROM APPOINTMENT a
JOIN PATIENT p ON p.patient_id = a.PATIENT_patient_id
JOIN EMPLOYEE_SCHEDULE es ON es.bridge_id = a.EMPLOYEE_SCHEDULE_bridge_id
JOIN EMPLOYEE e ON e.employee_id = es.EMPLOYEE_employee_id
JOIN ADMISSION adm ON adm.PATIENT_PATIENT_ID = p.patient_id
    AND adm.admission_type = 'EMERGENCY'
JOIN BED b ON b.bed_id = adm.BED_BED_ID
JOIN ROOM r ON r.room_id = b.ROOM_room_id
JOIN BILLING bi ON bi.ADMISSION_ADMISSION_ID = adm.admission_id
WHERE a.reason = 'Severe stroke symptoms - Demo Emergency'
AND   a.is_emergency = 'Y';
 
-- =============================================================
-- SECTION 10: TRIGGERS IN ACTION
-- Shows all 3 triggers working:
-- trg_occupied_bed      : BEFORE INSERT - blocks occupied bed
-- trg_mark_bed_occupied : AFTER INSERT  - marks bed Y
-- trg_release_bed_on_discharge : AFTER UPDATE - frees bed
-- =============================================================
 
-- Current ICU bed status showing triggers worked correctly
-- Beds 1,2,3 occupied by seed emergency patients
-- Bed 4 occupied by our demo emergency patient 70
SELECT
    b.bed_id,
    r.room_number,
    r.room_type,
    b.bed_number,
    b.is_occupied,
    p.first_name || ' ' || p.last_name AS current_patient
FROM BED b
JOIN ROOM r ON r.room_id = b.ROOM_room_id
LEFT JOIN ADMISSION adm ON adm.BED_BED_ID = b.bed_id
    AND adm.status = 'ACTIVE'
LEFT JOIN PATIENT p ON p.patient_id = adm.PATIENT_PATIENT_ID
WHERE r.room_type = 'ICU'
ORDER BY b.bed_id;
 
-- =============================================================
-- SECTION 11: OPERATIONAL REPORTS
-- =============================================================
 
-- REPORT 1: Today's Appointments
-- Shows all appointments scheduled for today
-- Useful for reception staff at start of day
SELECT
    a.appointment_id,
    TO_CHAR(a.appointment_date, 'DD-MON-YYYY') AS appt_date,
    p.first_name || ' ' || p.last_name AS patient,
    e.first_name || ' ' || e.last_name AS doctor,
    a.status,
    a.reason
FROM APPOINTMENT a
JOIN PATIENT p ON p.patient_id = a.PATIENT_patient_id
JOIN EMPLOYEE_SCHEDULE es ON es.bridge_id = a.EMPLOYEE_SCHEDULE_bridge_id
JOIN EMPLOYEE e ON e.employee_id = es.EMPLOYEE_employee_id
WHERE a.appointment_date = TRUNC(SYSDATE)
ORDER BY a.appointment_id;
 
-- REPORT 2: Bed Occupancy by Room Type
-- Real-time bed availability dashboard
-- Hospital manager uses this to track capacity
SELECT
    r.room_type,
    COUNT(b.bed_id) AS total_beds,
    SUM(CASE WHEN b.is_occupied='Y' THEN 1 ELSE 0 END) AS occupied,
    SUM(CASE WHEN b.is_occupied='N' THEN 1 ELSE 0 END) AS available,
    ROUND(SUM(CASE WHEN b.is_occupied='Y' THEN 1 ELSE 0 END)
          * 100 / COUNT(b.bed_id), 1) AS pct
FROM BED b
JOIN ROOM r ON r.room_id = b.ROOM_room_id
GROUP BY r.room_type
ORDER BY r.room_type;
 
-- REPORT 3: Revenue by Insurance Provider
-- Finance team uses this for monthly revenue analysis
-- Shows gross amount, discount given and net collected
SELECT
    NVL(i.provider_name, 'Self-Pay') AS insurance_provider,
    COUNT(b.bill_id)    AS total_bills,
    SUM(b.total_amount) AS gross_amount,
    SUM(b.discount)     AS total_discount,
    SUM(b.net_amount)   AS net_revenue
FROM BILLING b
LEFT JOIN INSURANCE i ON i.insurance_id = b.INSURANCE_INSURANCE_ID
GROUP BY i.provider_name
ORDER BY net_revenue DESC;
 
-- REPORT 4: Emergency Appointments Report
-- Shows all emergency cases with ICU bed and bill details
-- Unique to our emergency module
SELECT
    a.appointment_id AS appt_id,
    p.first_name || ' ' || p.last_name AS patient_name,
    e.first_name || ' ' || e.last_name AS doctor_name,
    adm.admission_type,
    r.room_type,
    b.bed_number,
    bi.total_amount AS bill_amount,
    bi.status AS bill_status
FROM APPOINTMENT a
JOIN PATIENT p ON p.patient_id = a.PATIENT_patient_id
JOIN EMPLOYEE_SCHEDULE es ON es.bridge_id = a.EMPLOYEE_SCHEDULE_bridge_id
JOIN EMPLOYEE e ON e.employee_id = es.EMPLOYEE_employee_id
JOIN ADMISSION adm ON adm.PATIENT_PATIENT_ID = p.patient_id
    AND adm.admission_type = 'EMERGENCY'
JOIN BED b ON b.bed_id = adm.BED_BED_ID
JOIN ROOM r ON r.room_id = b.ROOM_room_id
JOIN BILLING bi ON bi.ADMISSION_ADMISSION_ID = adm.admission_id
WHERE a.is_emergency = 'Y'
ORDER BY a.appointment_id;
 
-- =============================================================
-- SECTION 12: BUSINESS RULES VERIFICATION
-- All 9 business rules must pass
-- =============================================================
 
-- BR1: Every minor patient (under 18) must have a guardian
-- Checks PATIENT table for minors without guardian_id
SELECT
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS br1_status,
    COUNT(*) AS violations
FROM PATIENT
WHERE dob > TRUNC(SYSDATE) - 365*18
AND   guardian_id IS NULL;
 
-- BR2: No patient can have more than one PRIMARY insurance
-- Checks PATIENT_INSURANCE for duplicate is_primary = Y
SELECT
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS br2_status,
    COUNT(*) AS violations
FROM (
    SELECT PATIENT_patient_id
    FROM   PATIENT_INSURANCE
    WHERE  is_primary = 'Y'
    GROUP BY PATIENT_patient_id
    HAVING COUNT(*) > 1
);
 
-- BR3: Every ACTIVE admission must have its bed marked as occupied
-- Joins ADMISSION to BED and checks is_occupied = N for active admissions
SELECT
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS br3_status,
    COUNT(*) AS violations
FROM ADMISSION a
JOIN BED b ON b.bed_id = a.BED_BED_ID
WHERE a.status      = 'ACTIVE'
AND   b.is_occupied = 'N';
 
-- BR9: Every appointment with is_emergency = Y must have
-- a corresponding ADMISSION with admission_type = EMERGENCY
SELECT
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS br9_status,
    COUNT(*) AS violations
FROM APPOINTMENT a
WHERE a.is_emergency = 'Y'
AND NOT EXISTS (
    SELECT 1
    FROM   ADMISSION adm
    WHERE  adm.PATIENT_PATIENT_ID = a.PATIENT_patient_id
    AND    adm.admission_type     = 'EMERGENCY'
);
 
-- =============================================================
-- DEMO COMPLETE!
-- Table Turners - DMDD 6210
-- =============================================================