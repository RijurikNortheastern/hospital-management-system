-- =============================================================
-- FILE   : DML/05_insert_insurance.sql
-- PROJECT: Hospital Management System (DMDD 6210 - Table Turners)
-- RUN AS : hms_admin
-- PURPOSE: Seed 6 insurance providers + 100 patient-insurance links
--            80 patients  × 1 policy  (primary)
--            20 patients  × 2 policies (primary + secondary)
--            Total: 120 rows in PATIENT_INSURANCE bridge table
-- DEPENDS: DML/03 (patients 1–100 must exist)
-- SAFE   : Idempotent — deletes existing rows before re-inserting
-- NOTE   : Uses subquery lookup for patient_id and insurance_id
--          instead of hardcoded integers — safe across re-runs
-- =============================================================
 
 
-- =============================================================
-- SECTION 1: CLEAN EXISTING DATA (FK order)
-- =============================================================
 
BEGIN
    DELETE FROM PATIENT_INSURANCE;
    DELETE FROM INSURANCE;
    DBMS_OUTPUT.PUT_LINE('PATIENT_INSURANCE and INSURANCE tables cleared.');
END;
/
 
 
-- =============================================================
-- SECTION 2: INSERT 6 INSURANCE PROVIDERS
-- Named column insert — policy_number is UNIQUE constrained
-- =============================================================
 
INSERT INTO INSURANCE (insurance_id, provider_name, policy_number, coverage_pct)
VALUES (insurance_seq.NEXTVAL, 'BlueCross',     'POL-BC-001', 80);
 
INSERT INTO INSURANCE (insurance_id, provider_name, policy_number, coverage_pct)
VALUES (insurance_seq.NEXTVAL, 'Aetna',         'POL-AE-002', 70);
 
INSERT INTO INSURANCE (insurance_id, provider_name, policy_number, coverage_pct)
VALUES (insurance_seq.NEXTVAL, 'United Health', 'POL-UH-003', 75);
 
INSERT INTO INSURANCE (insurance_id, provider_name, policy_number, coverage_pct)
VALUES (insurance_seq.NEXTVAL, 'Cigna',         'POL-CI-004', 60);
 
INSERT INTO INSURANCE (insurance_id, provider_name, policy_number, coverage_pct)
VALUES (insurance_seq.NEXTVAL, 'Star Health',   'POL-SH-005', 85);
 
INSERT INTO INSURANCE (insurance_id, provider_name, policy_number, coverage_pct)
VALUES (insurance_seq.NEXTVAL, 'Max Bupa',      'POL-MB-006', 65);
 
COMMIT;
BEGIN
    DBMS_OUTPUT.PUT_LINE('6 insurance providers inserted.');
END;
/
 
 
-- =============================================================
-- SECTION 3: LINK 100 PATIENTS TO INSURANCE
--      so correct patient_id and insurance_id are always used
--      regardless of what value the sequences are currently at
-- =============================================================
 
BEGIN
    -- ----------------------------------------------------------
    -- 80 patients with 1 PRIMARY insurance policy each
    -- Patient rank 1–80, insurance rotates across 6 providers
    -- ----------------------------------------------------------
    FOR i IN 1..80 LOOP
        INSERT INTO PATIENT_INSURANCE (
            patient_ins_id,
            valid_from,
            valid_to,
            is_primary,
            PATIENT_patient_id,
            INSURANCE_insurance_id
        )
        SELECT
            patient_ins_seq.NEXTVAL,
            ADD_MONTHS(SYSDATE, -12),
            ADD_MONTHS(SYSDATE,  12),
            'Y',
            p.patient_id,
            ins.insurance_id
        FROM
            -- Lookup the i-th patient by insertion rank (not hardcoded ID)
            (SELECT patient_id,
                    ROW_NUMBER() OVER (ORDER BY patient_id) AS rn
             FROM   PATIENT
             WHERE  guardian_id IS NULL) p,
            -- Rotate across 6 insurance providers
            (SELECT insurance_id,
                    ROW_NUMBER() OVER (ORDER BY insurance_id) AS rn
             FROM   INSURANCE) ins
        WHERE p.rn   = i
          AND ins.rn = MOD(i - 1, 6) + 1;
    END LOOP;
 
    -- ----------------------------------------------------------
    -- 20 patients with a SECONDARY insurance policy
    -- Same first 20 adult patients, different insurance provider
    -- MOD(i, 6) + 1 ensures secondary differs from primary
    -- ----------------------------------------------------------
    FOR i IN 1..20 LOOP
        INSERT INTO PATIENT_INSURANCE (
            patient_ins_id,
            valid_from,
            valid_to,
            is_primary,
            PATIENT_patient_id,
            INSURANCE_insurance_id
        )
        SELECT
            patient_ins_seq.NEXTVAL,
            ADD_MONTHS(SYSDATE, -6),
            ADD_MONTHS(SYSDATE,  6),
            'N',
            p.patient_id,
            ins.insurance_id
        FROM
            (SELECT patient_id,
                    ROW_NUMBER() OVER (ORDER BY patient_id) AS rn
             FROM   PATIENT
             WHERE  guardian_id IS NULL) p,
            (SELECT insurance_id,
                    ROW_NUMBER() OVER (ORDER BY insurance_id) AS rn
             FROM   INSURANCE) ins
        WHERE p.rn   = i
          AND ins.rn = MOD(i, 6) + 1;
    END LOOP;
 
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('120 patient-insurance links inserted (80 primary + 20 secondary pairs).');
END;
/
 
 
-- =============================================================
-- SECTION 4: VERIFY
-- =============================================================
 
-- Insurance provider summary
SELECT
    insurance_id,
    provider_name,
    policy_number,
    coverage_pct
FROM   INSURANCE
ORDER  BY insurance_id;
 
-- Bridge table counts
SELECT
    is_primary,
    COUNT(*) AS total
FROM   PATIENT_INSURANCE
GROUP  BY is_primary;
 
-- Confirm no patient has 2 PRIMARY policies (business rule)
SELECT
    PATIENT_patient_id,
    COUNT(*) AS primary_count
FROM   PATIENT_INSURANCE
WHERE  is_primary = 'Y'
GROUP  BY PATIENT_patient_id
HAVING COUNT(*) > 1;
-- Should return 0 rows
 
BEGIN
    DBMS_OUTPUT.PUT_LINE('DML/05 completed — 6 insurers, 120 patient-insurance links.');
END;
/
 