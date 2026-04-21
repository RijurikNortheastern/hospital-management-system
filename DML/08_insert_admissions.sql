-- =============================================================
-- FILE   : DML/08_insert_admissions.sql
-- PROJECT: Hospital Management System (DMDD 6210 - Table Turners)
-- RUN AS : hms_admin
-- PURPOSE: Seed 10 admissions + billing + payments
--            4 ACTIVE   admissions (beds marked occupied)
--            6 DISCHARGED admissions (beds remain/set free)
--          Also seeds:
--            10 BILLING rows (1 per admission)
--            8  PAYMENT rows (paid bills only)
-- DEPENDS: DML/03 (patients), DML/04 (beds), DML/02 (employees)
-- SAFE   : Idempotent — cleans dependent tables before re-insert
-- =============================================================
 
 
-- Disable parallel execution to avoid ORA-12839 on OCI Autonomous DB
ALTER SESSION DISABLE PARALLEL DML;
ALTER SESSION DISABLE PARALLEL DDL;
ALTER SESSION DISABLE PARALLEL QUERY;
 
 
-- =============================================================
-- SECTION 1: CLEAN EXISTING DATA (FK order)
-- Reset bed occupancy flags too
-- =============================================================
 
BEGIN
    DELETE FROM PAYMENT;
    DELETE FROM BILLING;
    DELETE FROM ADMISSION;
    UPDATE BED SET is_occupied = 'N';
    DBMS_OUTPUT.PUT_LINE('ADMISSION, BILLING, PAYMENT cleared. All beds reset.');
END;
/
 
 
-- =============================================================
-- SECTION 2: INSERT 10 ADMISSIONS
-- =============================================================
 
DECLARE
    v_bed_id     NUMBER;
    v_patient_id NUMBER;
    v_emp_id     NUMBER;
    v_doc_count  NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_doc_count
    FROM   EMPLOYEE WHERE role = 'DOCTOR';
 
    -- ── 4 ACTIVE admissions ──────────────────────────────────
    FOR i IN 1..4 LOOP
 
        -- Lookup i-th bed by rank
        SELECT bed_id INTO v_bed_id
        FROM (
            SELECT bed_id,
                   ROW_NUMBER() OVER (ORDER BY bed_id) AS rn
            FROM   BED
            WHERE  is_occupied = 'N'            -- only assign free beds
        )
        WHERE rn = i;
 
        -- Mark bed occupied
        UPDATE BED SET is_occupied = 'Y'
        WHERE  bed_id = v_bed_id;
 
        -- Lookup patient rank 100+i (patients 101–104)
        SELECT patient_id INTO v_patient_id
        FROM (
            SELECT patient_id,
                   ROW_NUMBER() OVER (ORDER BY patient_id) AS rn
            FROM   PATIENT
        )
        WHERE rn = 100 + i;
 
        -- Lookup doctor rank i (cycles across doctors)
        SELECT employee_id INTO v_emp_id
        FROM (
            SELECT employee_id,
                   ROW_NUMBER() OVER (ORDER BY employee_id) AS rn
            FROM   EMPLOYEE
            WHERE  role = 'DOCTOR'
        )
        WHERE rn = MOD(i - 1, v_doc_count) + 1;
 
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
            admission_seq.NEXTVAL,
            TRUNC(SYSDATE) - (20 - i * 2),
            NULL,                               -- NULL = still admitted
            'Admission reason ' || i,
            'ACTIVE',
            v_bed_id,
            v_patient_id,
            v_emp_id
        );
    END LOOP;
 
    -- ── 6 DISCHARGED admissions ──────────────────────────────
    FOR i IN 5..10 LOOP
 
        -- Lookup i-th free bed by rank (beds 5–10)
        SELECT bed_id INTO v_bed_id
        FROM (
            SELECT bed_id,
                   ROW_NUMBER() OVER (ORDER BY bed_id) AS rn
            FROM   BED
            WHERE  is_occupied = 'N'
        )
        WHERE rn = i - 4;                       -- ranks 1–6 of remaining free beds
 
        -- Lookup patient rank 100+i (patients 105–110)
        SELECT patient_id INTO v_patient_id
        FROM (
            SELECT patient_id,
                   ROW_NUMBER() OVER (ORDER BY patient_id) AS rn
            FROM   PATIENT
        )
        WHERE rn = 100 + i;
 
        -- Lookup doctor rank (cycles across doctors)
        SELECT employee_id INTO v_emp_id
        FROM (
            SELECT employee_id,
                   ROW_NUMBER() OVER (ORDER BY employee_id) AS rn
            FROM   EMPLOYEE
            WHERE  role = 'DOCTOR'
        )
        WHERE rn = MOD(i - 1, v_doc_count) + 1;
 
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
            admission_seq.NEXTVAL,
            TRUNC(SYSDATE) - (30 - i * 2),
            TRUNC(SYSDATE) - (i - 4),          -- discharge date in the past
            'Admission reason ' || i,
            'DISCHARGED',
            v_bed_id,
            v_patient_id,
            v_emp_id
        );
        -- Bed stays 'N' — patient was discharged, no UPDATE needed
    END LOOP;
 
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('10 admissions inserted (4 active, 6 discharged).');
END;
/
 
 
-- =============================================================
-- SECTION 3: INSERT BILLING (1 bill per admission)
-- Active admissions   → PENDING
-- Discharged          → PAID or PARTIALLY_PAID
-- Insurance discount applied where patient has coverage
-- =============================================================
 
BEGIN
    FOR rec IN (
        SELECT
            a.admission_id,
            a.status          AS adm_status,
            a.PATIENT_patient_id,
            pi.INSURANCE_insurance_id,
            ins.coverage_pct,
            ROW_NUMBER() OVER (ORDER BY a.admission_id) AS rn
        FROM   ADMISSION a
        LEFT JOIN PATIENT_INSURANCE pi
               ON pi.PATIENT_patient_id = a.PATIENT_patient_id
              AND pi.is_primary = 'Y'
        LEFT JOIN INSURANCE ins
               ON ins.insurance_id = pi.INSURANCE_insurance_id
        ORDER  BY a.admission_id
    ) LOOP
        DECLARE
            v_total    NUMBER := 5000 + (rec.rn * 1000);
            v_discount NUMBER := 0;
            v_net      NUMBER;
            v_status   VARCHAR2(20);
        BEGIN
            -- Apply insurance discount if available
            IF rec.coverage_pct IS NOT NULL THEN
                v_discount := ROUND(v_total * rec.coverage_pct / 100, 2);
            END IF;
            v_net := v_total - v_discount;
 
            -- Bill status based on admission status
            v_status := CASE
                WHEN rec.adm_status = 'ACTIVE'      THEN 'PENDING'
                WHEN MOD(rec.rn, 3) = 0             THEN 'PARTIALLY_PAID'
                ELSE                                     'PAID'
            END;
 
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
                bill_seq.NEXTVAL,
                TRUNC(SYSDATE) - MOD(rec.rn, 10),
                v_total,
                v_discount,
                v_net,
                v_status,
                rec.PATIENT_patient_id,
                rec.INSURANCE_insurance_id,     -- NULL if no insurance
                rec.admission_id,
                NULL                            -- admission bill, not appointment bill
            );
        END;
    END LOOP;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('10 billing rows inserted.');
END;
/
 
 
-- =============================================================
-- SECTION 4: INSERT PAYMENTS (for PAID and PARTIALLY_PAID bills)
-- =============================================================
 
BEGIN
    FOR rec IN (
        SELECT bill_id, net_amount, status,
               ROW_NUMBER() OVER (ORDER BY bill_id) AS rn
        FROM   BILLING
        WHERE  status IN ('PAID', 'PARTIALLY_PAID')
        ORDER  BY bill_id
    ) LOOP
        INSERT INTO PAYMENT (
            payment_id,
            payment_date,
            amount,
            payment_method,
            transaction_ref,
            BILLING_bill_id
        ) VALUES (
            payment_seq.NEXTVAL,
            TRUNC(SYSDATE) - MOD(rec.rn, 5),
            CASE rec.status
                WHEN 'PAID'          THEN rec.net_amount
                ELSE                      ROUND(rec.net_amount * 0.5, 2)  -- 50% partial
            END,
            CASE MOD(rec.rn, 3)
                WHEN 0 THEN 'CASH'
                WHEN 1 THEN 'CARD'
                ELSE        'INSURANCE'
            END,
            'TXN-' || LPAD(rec.rn, 6, '0'),
            rec.bill_id
        );
    END LOOP;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Payment rows inserted for paid bills.');
END;
/
 
 
-- =============================================================
-- SECTION 5: VERIFY
-- =============================================================
 
-- Admission status summary
SELECT status, COUNT(*) AS total
FROM   ADMISSION
GROUP  BY status;
 
-- Occupied beds count
SELECT is_occupied, COUNT(*) AS total
FROM   BED
GROUP  BY is_occupied;
 
-- Billing summary
SELECT status, COUNT(*) AS total, SUM(net_amount) AS total_revenue
FROM   BILLING
GROUP  BY status
ORDER  BY status;
 
-- Payment summary
SELECT payment_method, COUNT(*) AS total, SUM(amount) AS amount_collected
FROM   PAYMENT
GROUP  BY payment_method
ORDER  BY payment_method;
 
BEGIN
    DBMS_OUTPUT.PUT_LINE('DML/08 completed — admissions, billing, payments loaded.');
END;
/