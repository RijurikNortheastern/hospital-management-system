-- =============================================================
-- FILE   : Procedures/05_generate_bill.sql
-- PROJECT: Hospital Management System (DMDD 6210 - Table Turners)
-- RUN AS : hms_admin
-- PURPOSE: Generate a bill for a patient with insurance discount
-- VALIDATIONS:
--   1. Patient must exist
--   2. Total amount must be positive
--   3. If admission_id provided — must exist and belong to patient
--   4. If appointment_id provided — must exist and belong to patient
--   5. At least one of admission_id or appointment_id must be provided
--   6. Duplicate bill check — no existing PENDING bill for same source
-- LOGIC:
--   - Looks up primary active insurance for patient
--   - Applies coverage_pct as discount
--   - net_amount = total_amount - discount (rounded to 2 decimals)
--   - Bill inserted with status PENDING
-- =============================================================
 
CREATE OR REPLACE PROCEDURE generate_bill (
    p_patient_id     IN NUMBER,
    p_admission_id   IN NUMBER DEFAULT NULL,
    p_appointment_id IN NUMBER DEFAULT NULL,
    p_total_amount   IN NUMBER
)
AS
    v_insurance_id  NUMBER;
    v_coverage      NUMBER := 0;
    v_discount      NUMBER := 0;
    v_net_amount    NUMBER;
    v_count         NUMBER;
    v_new_bill_id   NUMBER;
BEGIN
 
    -- ──────────────────────────────────────────────────────────
    -- VALIDATION 1: Patient must exist
    -- ──────────────────────────────────────────────────────────
    SELECT COUNT(*) INTO v_count
    FROM   PATIENT
    WHERE  patient_id = p_patient_id;
 
    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20050,
            'Patient ID ' || p_patient_id || ' does not exist.');
    END IF;
 
    -- ──────────────────────────────────────────────────────────
    -- VALIDATION 2: Total amount must be positive
    -- ──────────────────────────────────────────────────────────
    IF p_total_amount <= 0 THEN
        RAISE_APPLICATION_ERROR(-20051,
            'Total amount must be greater than 0. Received: ' || p_total_amount || '.');
    END IF;
 
    -- ──────────────────────────────────────────────────────────
    -- VALIDATION 3: At least one source must be provided
    --      NULL appointment — orphan bills with no source
    -- ──────────────────────────────────────────────────────────
    IF p_admission_id IS NULL AND p_appointment_id IS NULL THEN
        RAISE_APPLICATION_ERROR(-20052,
            'At least one of p_admission_id or p_appointment_id must be provided.');
    END IF;
 
    -- ──────────────────────────────────────────────────────────
    -- VALIDATION 4: Admission must exist and belong to patient
    -- ──────────────────────────────────────────────────────────
    IF p_admission_id IS NOT NULL THEN
        SELECT COUNT(*) INTO v_count
        FROM   ADMISSION
        WHERE  admission_id        = p_admission_id
          AND  PATIENT_patient_id  = p_patient_id;
 
        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20053,
                'Admission ID ' || p_admission_id ||
                ' does not exist or does not belong to patient ' || p_patient_id || '.');
        END IF;
    END IF;
 
    -- ──────────────────────────────────────────────────────────
    -- VALIDATION 5: Appointment must exist and belong to patient
    -- ──────────────────────────────────────────────────────────
    IF p_appointment_id IS NOT NULL THEN
        SELECT COUNT(*) INTO v_count
        FROM   APPOINTMENT
        WHERE  appointment_id      = p_appointment_id
          AND  PATIENT_patient_id  = p_patient_id;
 
        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20054,
                'Appointment ID ' || p_appointment_id ||
                ' does not exist or does not belong to patient ' || p_patient_id || '.');
        END IF;
    END IF;
 
    -- ──────────────────────────────────────────────────────────
    -- VALIDATION 6: No duplicate PENDING bill for same source
    --      for same admission or appointment
    -- ──────────────────────────────────────────────────────────
    SELECT COUNT(*) INTO v_count
    FROM   BILLING
    WHERE  PATIENT_patient_id         = p_patient_id
      AND  status                     = 'PENDING'
      AND  (
               (p_admission_id   IS NOT NULL AND ADMISSION_admission_id     = p_admission_id)
            OR (p_appointment_id IS NOT NULL AND APPOINTMENT_appointment_id = p_appointment_id)
           );
 
    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20055,
            'A PENDING bill already exists for this patient and source.');
    END IF;
 
    -- ──────────────────────────────────────────────────────────
    -- INSURANCE LOOKUP — primary active policy only
    --      VALID_FROM check — policy might not have started yet
    --      reduces round trips and handles NULL insurance cleanly
    -- ──────────────────────────────────────────────────────────
    v_insurance_id := NULL;
    v_coverage     := 0;
 
    BEGIN
        SELECT pi.INSURANCE_insurance_id,
               ins.coverage_pct
        INTO   v_insurance_id,
               v_coverage
        FROM   PATIENT_INSURANCE pi
        JOIN   INSURANCE ins ON ins.insurance_id = pi.INSURANCE_insurance_id
        WHERE  pi.PATIENT_patient_id = p_patient_id
          AND  pi.is_primary         = 'Y'
          AND  ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_insurance_id := NULL;
            v_coverage     := 0;
    END;
 
    -- ──────────────────────────────────────────────────────────
    -- CALCULATE DISCOUNT AND NET AMOUNT
    --      could produce amounts like 1234.5666666...
    -- ──────────────────────────────────────────────────────────
    v_discount   := ROUND((p_total_amount * v_coverage) / 100, 2);
    v_net_amount := ROUND(p_total_amount - v_discount, 2);
 
    -- ──────────────────────────────────────────────────────────
    -- INSERT BILL
    -- ──────────────────────────────────────────────────────────
    v_new_bill_id := BILL_SEQ.NEXTVAL;
 
    INSERT INTO BILLING (
        bill_id,
        bill_date,
        total_amount,
        discount,
        net_amount,
        status,
        PATIENT_patient_id,
        INSURANCE_insurance_id,
        ADMISSION_admission_id,
        APPOINTMENT_appointment_id
    ) VALUES (
        v_new_bill_id,
        TRUNC(SYSDATE),
        p_total_amount,
        v_discount,
        v_net_amount,
        'PENDING',
        p_patient_id,
        v_insurance_id,       -- NULL if no active insurance
        p_admission_id,       -- NULL if appointment bill
        p_appointment_id      -- NULL if admission bill
    );
 
    COMMIT;
 
    DBMS_OUTPUT.PUT_LINE('Bill ' || v_new_bill_id || ' generated for patient ' || p_patient_id ||
                         '. Total: $' || p_total_amount ||
                         ', Discount: $' || v_discount ||
                         ' (' || v_coverage || '%)' ||
                         ', Net: $' || v_net_amount || '.');
 
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END generate_bill;
/
 
-- =============================================================
-- VERIFY procedure compiled without errors
-- =============================================================
SELECT object_name, object_type, status, last_ddl_time
FROM   user_objects
WHERE  object_name = 'GENERATE_BILL';


