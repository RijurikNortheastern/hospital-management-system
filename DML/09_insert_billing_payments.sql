-- =============================================================
-- FILE   : DML/09_insert_appointment_billing.sql
-- PROJECT: Hospital Management System (DMDD 6210 - Table Turners)
-- RUN AS : hms_admin
-- PURPOSE: Seed billing + payments for COMPLETED appointments
--          Up to 8 bills — one per completed appointment
--          Insurance discount applied where patient has coverage
-- DEPENDS: DML/07 (appointments), DML/05 (insurance)
--          DML/08 must run first (shares BILLING + PAYMENT tables)
-- SAFE   : Idempotent — deletes only appointment-linked bills
--          (leaves admission bills from DML/08 intact)
-- =============================================================
 
 
-- =============================================================
-- SECTION 1: CLEAN APPOINTMENT-LINKED BILLING ROWS ONLY
-- Do NOT delete admission bills inserted by DML/08
-- =============================================================
 
BEGIN
    -- Delete payments linked to appointment bills only
    DELETE FROM PAYMENT
    WHERE BILLING_bill_id IN (
        SELECT bill_id FROM BILLING
        WHERE  APPOINTMENT_appointment_id IS NOT NULL
    );
 
    -- Delete appointment bills only
    DELETE FROM BILLING
    WHERE APPOINTMENT_appointment_id IS NOT NULL;
 
    DBMS_OUTPUT.PUT_LINE('Appointment billing rows cleared.');
END;
/
 
 
-- =============================================================
-- SECTION 2: INSERT BILLS FOR COMPLETED APPOINTMENTS
-- Cursor fetches up to 8 completed appointments
-- Insurance lookup per patient — discount applied if found
-- =============================================================
 
DECLARE
    CURSOR c_appts IS
        SELECT appointment_id, PATIENT_patient_id
        FROM   APPOINTMENT
        WHERE  status = 'COMPLETED'
        AND    ROWNUM <= 8
        ORDER  BY appointment_id;
 
    v_ins_id   NUMBER;
    v_coverage NUMBER;
    v_total    NUMBER;
    v_discount NUMBER;
    v_net      NUMBER;
    v_counter  NUMBER := 0;
    v_bill_id  NUMBER;
    v_status   VARCHAR2(20);
BEGIN
    FOR rec IN c_appts LOOP
        v_counter  := v_counter + 1;
        v_total    := 500 + (v_counter * 200);   -- $700 to $2100
        v_discount := 0;
        v_ins_id   := NULL;
 
        -- Lookup primary active insurance for this patient
        BEGIN
            SELECT pi.INSURANCE_insurance_id,
                   ins.coverage_pct
            INTO   v_ins_id, v_coverage
            FROM   PATIENT_INSURANCE pi
            JOIN   INSURANCE ins
                   ON ins.insurance_id = pi.INSURANCE_insurance_id
            WHERE  pi.PATIENT_patient_id = rec.PATIENT_patient_id
              AND  pi.is_primary         = 'Y'
              AND  SYSDATE BETWEEN pi.valid_from AND pi.valid_to
              AND  ROWNUM = 1;
 
            v_discount := ROUND(v_total * v_coverage / 100, 2);
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_ins_id   := NULL;
                v_discount := 0;
        END;
 
        v_net    := v_total - v_discount;
        v_status := CASE WHEN MOD(v_counter, 3) = 0
                         THEN 'PARTIALLY_PAID'
                         ELSE 'PAID'
                    END;
 
        -- Insert bill
        v_bill_id := bill_seq.NEXTVAL;
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
            v_bill_id,
            TRUNC(SYSDATE) - MOD(v_counter, 5),
            v_total,
            v_discount,
            v_net,
            v_status,
            rec.PATIENT_patient_id,
            v_ins_id,
            NULL,                                -- appointment bill, not admission bill
            rec.appointment_id
        );
 
        -- Insert payment immediately for this bill
        INSERT INTO PAYMENT (
            payment_id,
            payment_date,
            amount,
            payment_method,
            transaction_ref,
            BILLING_bill_id
        ) VALUES (
            payment_seq.NEXTVAL,
            TRUNC(SYSDATE) - MOD(v_counter, 5),
            CASE v_status
                WHEN 'PAID'         THEN v_net
                ELSE ROUND(v_net * 0.5, 2)      -- 50% partial payment
            END,
            CASE MOD(v_counter, 3)
                WHEN 0 THEN 'CASH'
                WHEN 1 THEN 'CREDIT_CARD'
                ELSE        'INSURANCE'
            END,
            'TXN-APPT-' || LPAD(v_counter, 5, '0'),
            v_bill_id
        );
    END LOOP;
 
    COMMIT;
    DBMS_OUTPUT.PUT_LINE(v_counter || ' appointment bills and payments inserted.');
END;
/
 
 
-- =============================================================
-- SECTION 3: VERIFY
-- =============================================================
 
-- All billing rows by source
SELECT
    CASE
        WHEN ADMISSION_admission_id     IS NOT NULL THEN 'Admission Bill'
        WHEN APPOINTMENT_appointment_id IS NOT NULL THEN 'Appointment Bill'
        ELSE 'Other'
    END                        AS bill_source,
    status,
    COUNT(*)                   AS total,
    SUM(total_amount)          AS gross,
    SUM(discount)              AS total_discount,
    SUM(net_amount)            AS net_revenue
FROM   BILLING
GROUP  BY
    CASE
        WHEN ADMISSION_admission_id     IS NOT NULL THEN 'Admission Bill'
        WHEN APPOINTMENT_appointment_id IS NOT NULL THEN 'Appointment Bill'
        ELSE 'Other'
    END,
    status
ORDER  BY bill_source, status;
 
-- Payment summary
SELECT
    payment_method,
    COUNT(*)       AS payments,
    SUM(amount)    AS total_collected
FROM   PAYMENT
GROUP  BY payment_method
ORDER  BY payment_method;
 
BEGIN
    DBMS_OUTPUT.PUT_LINE('DML/09 completed — appointment billing and payments loaded.');
END;
/