-- Insert Billing and Payments
-- Bills linked to admissions and appointments
-- Some with insurance discounts, some self-pay

-- Bills for discharged admissions (6 bills)
BEGIN
  FOR i IN 5..10 LOOP
    DECLARE
      v_ins_id    NUMBER;
      v_coverage  NUMBER;
      v_total     NUMBER := 5000 + (i * 1000);
      v_discount  NUMBER := 0;
      v_net       NUMBER;
    BEGIN
      -- Check if patient has insurance
      BEGIN
        SELECT pi.INSURANCE_insurance_id, ins.coverage_pct
        INTO v_ins_id, v_coverage
        FROM PATIENT_INSURANCE pi
        JOIN INSURANCE ins ON pi.INSURANCE_insurance_id = ins.insurance_id
        WHERE pi.PATIENT_patient_id = i
          AND pi.is_primary = 'Y'
          AND SYSDATE BETWEEN pi.valid_from AND pi.valid_to
          AND ROWNUM = 1;

        v_discount := v_total * v_coverage / 100;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          v_ins_id := NULL;
          v_discount := 0;
      END;

      v_net := v_total - v_discount;

      INSERT INTO BILLING VALUES (
        bill_seq.NEXTVAL,
        SYSDATE - (i - 4),
        v_total,
        v_discount,
        v_net,
        'PAID',
        i,
        v_ins_id,
        i,
        NULL
      );
    END;
  END LOOP;
  COMMIT;
END;
/

-- Bills for completed appointments
DECLARE
  CURSOR c_appts IS
    SELECT appointment_id, PATIENT_patient_id
    FROM APPOINTMENT
    WHERE status = 'COMPLETED'
    AND ROWNUM <= 8;
  v_ins_id   NUMBER;
  v_coverage NUMBER;
  v_total    NUMBER;
  v_discount NUMBER;
  v_net      NUMBER;
  v_counter  NUMBER := 0;
BEGIN
  FOR rec IN c_appts LOOP
    v_counter := v_counter + 1;
    v_total := 500 + (v_counter * 200);
    v_discount := 0;
    v_ins_id := NULL;

    BEGIN
      SELECT pi.INSURANCE_insurance_id, ins.coverage_pct
      INTO v_ins_id, v_coverage
      FROM PATIENT_INSURANCE pi
      JOIN INSURANCE ins ON pi.INSURANCE_insurance_id = ins.insurance_id
      WHERE pi.PATIENT_patient_id = rec.PATIENT_patient_id
        AND pi.is_primary = 'Y'
        AND SYSDATE BETWEEN pi.valid_from AND pi.valid_to
        AND ROWNUM = 1;
      v_discount := v_total * v_coverage / 100;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_ins_id := NULL;
        v_discount := 0;
    END;

    v_net := v_total - v_discount;

    INSERT INTO BILLING VALUES (
      bill_seq.NEXTVAL,
      SYSDATE - MOD(v_counter, 5),
      v_total, v_discount, v_net,
      CASE WHEN MOD(v_counter, 3) = 0 THEN 'PARTIALLY_PAID' ELSE 'PAID' END,
      rec.PATIENT_patient_id,
      v_ins_id, NULL, rec.appointment_id
    );
  END LOOP;
  COMMIT;
END;
/

-- Payments against all bills
DECLARE
  CURSOR c_bills IS
    SELECT bill_id, net_amount, status FROM BILLING;
  v_counter NUMBER := 0;
BEGIN
  FOR rec IN c_bills LOOP
    v_counter := v_counter + 1;
    IF rec.status = 'PAID' THEN
      INSERT INTO PAYMENT VALUES (
        payment_seq.NEXTVAL,
        SYSDATE - MOD(v_counter, 5),
        rec.net_amount,
        CASE MOD(v_counter, 3)
          WHEN 0 THEN 'CASH'
          WHEN 1 THEN 'CREDIT_CARD'
          ELSE 'INSURANCE'
        END,
        'TXN-' || LPAD(v_counter, 6, '0'),
        rec.bill_id
      );
    ELSE
      INSERT INTO PAYMENT VALUES (
        payment_seq.NEXTVAL,
        SYSDATE - MOD(v_counter, 5),
        ROUND(rec.net_amount / 2),
        'CREDIT_CARD',
        'TXN-' || LPAD(v_counter, 6, '0'),
        rec.bill_id
      );
    END IF;
  END LOOP;
  COMMIT;
END;
/