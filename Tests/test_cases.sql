-- =========================================================
-- TEST CASES FOR HOSPITAL MANAGEMENT SYSTEM
-- Demonstrates business rules, validations, and transactions
-- =========================================================

-- =========================
-- 1. BOOK APPOINTMENT
-- =========================

-- SUCCESS CASE: valid booking
BEGIN
    book_appointment(1, 1, TO_DATE('2026-04-25','YYYY-MM-DD'), SYSDATE, 'Regular checkup');
END;
/

-- FAILURE CASE: duplicate booking (expected ORA-20001)
BEGIN
    book_appointment(1, 1, TO_DATE('2026-04-25','YYYY-MM-DD'), SYSDATE, 'Duplicate test');
END;
/

-- =========================
-- 2. CANCEL APPOINTMENT
-- =========================

-- FAILURE CASE: cancel within 24 hours (expected ORA-20004)
BEGIN
    cancel_appointment(1);
END;
/

-- =========================
-- 3. ADMIT PATIENT
-- =========================

-- FAILURE CASE: bed already occupied (expected ORA-20010)
BEGIN
    admit_patient(1, 1, 1, 'Fever admission');
END;
/

-- =========================
-- 4. GENERATE BILL
-- =========================

-- FAILURE CASE: NULL total amount (expected ORA-20030)
BEGIN
    generate_bill(1, 1, NULL, NULL);
END;
/

-- SUCCESS CASE: valid billing with amount
BEGIN
    generate_bill(1, 1, NULL, 5000);
END;
/

-- =========================
-- 5. RESCHEDULE APPOINTMENT
-- =========================

-- FAILURE CASE: slot already booked
BEGIN
    reschedule_appointment(1, TO_DATE('2026-04-25','YYYY-MM-DD'), SYSDATE, 1);
END;
/
