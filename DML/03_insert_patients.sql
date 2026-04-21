-- =============================================================
-- FILE   : DML/03_insert_patients.sql
-- PROJECT: Hospital Management System (DMDD 6210 - Table Turners)
-- RUN AS : hms_admin
-- PURPOSE: Seed 200 patients — 180 adults + 20 minors with guardians
-- DEPENDS: DDL/01, DDL/02, DDL/03 must run first
-- SAFE   : Idempotent — deletes PATIENT rows before re-inserting
-- NOTE   : Minors (i=181–200) use guardian_id = i (points to
--          adult patient_id 1–20 inserted in first loop)
--          PATIENT_GUARDIAN_FK self-ref requires adults exist first
-- =============================================================
 
 
-- =============================================================
-- SECTION 1: CLEAN EXISTING DATA
-- Must delete child tables first (FK order)
-- Full cascade is handled by DML/09; here we clear PATIENT safely
-- =============================================================
 
BEGIN
    DELETE FROM PRESCRIPTION;
    DELETE FROM APPOINTMENT_HISTORY;
    DELETE FROM BILLING;
    DELETE FROM ADMISSION;
    DELETE FROM APPOINTMENT;
    DELETE FROM PATIENT_INSURANCE;
    DELETE FROM PATIENT;
    DBMS_OUTPUT.PUT_LINE('PATIENT and dependent tables cleared.');
END;
/
 
 
-- =============================================================
-- SECTION 2: INSERT 180 ADULT PATIENTS
-- Age range: 20–64 years  (ADD_MONTHS with negative months)
-- gender   : 'MALE' / 'FEMALE' — matches no CHECK constraint
--            but kept consistent for reporting queries
-- guardian_id = NULL for all adults
-- =============================================================
 
BEGIN
    FOR i IN 1..180 LOOP
        INSERT INTO PATIENT (
            patient_id,
            first_name,
            last_name,
            dob,
            gender,
            phone,
            email,
            address,
            blood_group,
            emergency_contact,
            registration_date,
            guardian_id
        ) VALUES (
            patient_seq.NEXTVAL,
            'First_' || i,
            'Last_'  || i,
            ADD_MONTHS(SYSDATE, -12 * (20 + MOD(i, 45))),  -- age 20–64
            CASE WHEN MOD(i, 2) = 0 THEN 'MALE' ELSE 'FEMALE' END,
            '555-4' || LPAD(i, 4, '0'),
            'patient' || i || '@email.com',
            i || ' Main Street, Boston MA',
            CASE MOD(i, 8)
                WHEN 0 THEN 'A+'
                WHEN 1 THEN 'A-'
                WHEN 2 THEN 'B+'
                WHEN 3 THEN 'B-'
                WHEN 4 THEN 'O+'
                WHEN 5 THEN 'O-'
                WHEN 6 THEN 'AB+'
                ELSE         'AB-'
            END,
            '555-9' || LPAD(i, 4, '0'),
            SYSDATE - MOD(i, 365),
            NULL                                            -- no guardian for adults
        );
    END LOOP;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('180 adult patients inserted.');
END;
/
 
 
-- =============================================================
-- SECTION 3: INSERT 20 MINOR PATIENTS
-- Age range : 5–16 years
-- guardian_id: points to patient_seq values 1–20 (first 20 adults)
-- IMPORTANT : Adults MUST be committed before this block runs
--             (PATIENT_GUARDIAN_FK self-referencing constraint)
-- Phone/email: unique prefix '555-5' and 'minor' to avoid
--              PATIENT_EMAIL_UN / phone collisions with adults
-- =============================================================
 
BEGIN
    FOR i IN 1..20 LOOP
        INSERT INTO PATIENT (
            patient_id,
            first_name,
            last_name,
            dob,
            gender,
            phone,
            email,
            address,
            blood_group,
            emergency_contact,
            registration_date,
            guardian_id
        ) VALUES (
            patient_seq.NEXTVAL,
            'Child_' || i,
            'Last_'  || i,
            ADD_MONTHS(SYSDATE, -12 * (5 + MOD(i, 12))),   -- age 5–16
            CASE WHEN MOD(i, 2) = 0 THEN 'MALE' ELSE 'FEMALE' END,
            '555-5' || LPAD(i, 4, '0'),
            'minor' || i || '@email.com',                   -- unique email (UNIQUE constraint)
            i || ' Main Street, Boston MA',
            CASE MOD(i, 4)
                WHEN 0 THEN 'A+'
                WHEN 1 THEN 'B+'
                WHEN 2 THEN 'O+'
                ELSE         'AB+'
            END,
            '555-8' || LPAD(i, 4, '0'),
            SYSDATE - MOD(i, 100),
            i                                               -- guardian = adult patient_id i (1–20)
        );
    END LOOP;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('20 minor patients inserted with guardian_id 1–20.');
END;
/
 
 
-- =============================================================
-- SECTION 4: VERIFY
-- =============================================================
 
-- Total count
SELECT
    CASE WHEN guardian_id IS NULL THEN 'Adult' ELSE 'Minor' END AS patient_type,
    COUNT(*) AS total
FROM   PATIENT
GROUP  BY CASE WHEN guardian_id IS NULL THEN 'Adult' ELSE 'Minor' END;
 
-- Confirm all 20 minors have a valid guardian
SELECT
    p.patient_id,
    p.first_name || ' ' || p.last_name   AS minor_name,
    p.guardian_id,
    g.first_name || ' ' || g.last_name   AS guardian_name
FROM   PATIENT p
JOIN   PATIENT g ON p.guardian_id = g.patient_id
ORDER  BY p.patient_id;
 
-- Age range sanity check
SELECT
    MIN(TRUNC(MONTHS_BETWEEN(SYSDATE, dob) / 12)) AS min_age,
    MAX(TRUNC(MONTHS_BETWEEN(SYSDATE, dob) / 12)) AS max_age
FROM   PATIENT
WHERE  guardian_id IS NULL;
 
BEGIN
    DBMS_OUTPUT.PUT_LINE('DML/03 completed — 200 patients inserted (180 adults, 20 minors).');
END;
/