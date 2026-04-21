-- =============================================================
-- FILE   : Procedures/04_admit_patient.sql
-- PROJECT: Hospital Management System (DMDD 6210 - Table Turners)
-- RUN AS : hms_admin
-- PURPOSE: Admit a patient to a bed with full validations
-- VALIDATIONS:
--   1. Patient must exist
--   2. Bed must exist and not be occupied
--   3. Patient must not already have an ACTIVE admission
--   4. Employee must exist and must be a DOCTOR
-- SIDE EFFECTS:
--   - Inserts ADMISSION row with status ACTIVE
--   - BED.is_occupied updated by trg_mark_bed_occupied trigger
-- =============================================================
 
CREATE OR REPLACE PROCEDURE admit_patient (
    p_patient_id  IN NUMBER,
    p_bed_id      IN NUMBER,
    p_employee_id IN NUMBER,
    p_reason      IN VARCHAR2
)
AS
    v_bed_status  CHAR(1);
    v_count       NUMBER;
    v_role        VARCHAR2(50);
    v_new_adm_id  NUMBER;
BEGIN
 
    -- ──────────────────────────────────────────────────────────
    -- VALIDATION 1: Patient must exist
    -- ──────────────────────────────────────────────────────────
    SELECT COUNT(*) INTO v_count
    FROM   PATIENT
    WHERE  patient_id = p_patient_id;
 
    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20040,
            'Patient ID ' || p_patient_id || ' does not exist.');
    END IF;
 
    -- ──────────────────────────────────────────────────────────
    -- VALIDATION 2: Bed must exist and not be occupied
    --      unhandled NO_DATA_FOUND if bed_id doesn't exist
    -- ──────────────────────────────────────────────────────────
    BEGIN
        SELECT is_occupied INTO v_bed_status
        FROM   BED
        WHERE  bed_id = p_bed_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20041,
                'Bed ID ' || p_bed_id || ' does not exist.');
    END;
 
    IF v_bed_status = 'Y' THEN
        RAISE_APPLICATION_ERROR(-20042,
            'Bed ' || p_bed_id || ' is already occupied.');
    END IF;
 
    -- ──────────────────────────────────────────────────────────
    -- VALIDATION 3: Patient must not have an ACTIVE admission
    -- ──────────────────────────────────────────────────────────
    SELECT COUNT(*) INTO v_count
    FROM   ADMISSION
    WHERE  PATIENT_patient_id = p_patient_id
      AND  status             = 'ACTIVE';
 
    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20043,
            'Patient ' || p_patient_id || ' already has an active admission.');
    END IF;
 
    -- ──────────────────────────────────────────────────────────
    -- VALIDATION 4: Employee must exist and be a DOCTOR
    -- ──────────────────────────────────────────────────────────
    BEGIN
        SELECT role INTO v_role
        FROM   EMPLOYEE
        WHERE  employee_id = p_employee_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20044,
                'Employee ID ' || p_employee_id || ' does not exist.');
    END;
 
    IF v_role <> 'DOCTOR' THEN
        RAISE_APPLICATION_ERROR(-20045,
            'Only a DOCTOR can admit a patient. Employee role is: ' || v_role || '.');
    END IF;
 
    -- ──────────────────────────────────────────────────────────
    -- INSERT ADMISSION
    --      (bed_bed_id, patient_patient_id, employee_employee_id)
    --      Oracle is case-insensitive for unquoted identifiers
    --      but using consistent UPPER CASE matches DDL definition
    --      portion for clean date-only comparisons in reports
    -- ──────────────────────────────────────────────────────────
    v_new_adm_id := ADMISSION_SEQ.NEXTVAL;
 
    INSERT INTO ADMISSION (
        admission_id,
        admit_date,
        discharge_date,
        admit_reason,
        status,
        BED_bed_id,
        PATIENT_patient_id,
        EMPLOYEE_employee_id
    ) VALUES (
        v_new_adm_id,
        TRUNC(SYSDATE),
        NULL,                   -- discharge_date NULL = currently admitted
        p_reason,
        'ACTIVE',
        p_bed_id,
        p_patient_id,
        p_employee_id
    );
 
    COMMIT;
 
    DBMS_OUTPUT.PUT_LINE('Patient ' || p_patient_id ||
                         ' admitted successfully. Admission ID: ' || v_new_adm_id ||
                         ', Bed ID: ' || p_bed_id || '.');
 
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END admit_patient;
/
 
-- =============================================================
-- VERIFY procedure compiled without errors
-- =============================================================
SELECT object_name, object_type, status, last_ddl_time
FROM   user_objects
WHERE  object_name = 'ADMIT_PATIENT';
