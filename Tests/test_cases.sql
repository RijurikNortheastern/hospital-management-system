-- =========================
-- TEST CASE 1: Book appointment (SUCCESS)
-- =========================
EXEC book_appointment(1, 1, TO_DATE('2026-04-25','YYYY-MM-DD'), SYSDATE, 'General checkup');


-- =========================
-- TEST CASE 2: Duplicate booking (FAIL)
-- =========================
-- Should throw: Duplicate booking not allowed
EXEC book_appointment(1, 1, TO_DATE('2026-04-25','YYYY-MM-DD'), SYSDATE, 'Duplicate test');


-- =========================
-- TEST CASE 3: Cancel appointment (>24 hrs)
-- =========================
EXEC cancel_appointment(1);


-- =========================
-- TEST CASE 4: Admit patient (SUCCESS)
-- =========================
EXEC admit_patient(1, 1, 1, 'Fever admission');


-- =========================
-- TEST CASE 5: Admit patient to occupied bed (FAIL)
-- =========================
EXEC admit_patient(2, 1, 1, 'Second admission test');


-- =========================
-- TEST CASE 6: Generate bill (with insurance)
-- =========================
EXEC generate_bill(1, 5000, 1, NULL);
