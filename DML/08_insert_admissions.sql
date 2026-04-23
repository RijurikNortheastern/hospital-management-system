-- =============================================================
-- FILE   : DML/08_insert_admissions.sql
-- PROJECT: Hospital Management System (DMDD 6210 - Table Turners)
-- RUN AS : hms_admin
-- PURPOSE: Seed 10 admissions + billing + payments + 2 emergency
-- SAFE   : Idempotent — cleans dependent tables before re-insert
-- =============================================================
 
ALTER SESSION DISABLE PARALLEL DML;
ALTER SESSION DISABLE PARALLEL DDL;
ALTER SESSION DISABLE PARALLEL QUERY;
 
BEGIN
    DELETE FROM PAYMENT;
    DELETE FROM BILLING;
    DELETE FROM ADMISSION;
    UPDATE BED SET is_occupied = 'N';
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('ADMISSION, BILLING, PAYMENT cleared. All beds reset.');
END;
/
 
-- 4 ACTIVE admissions using GENERAL beds 11-14
-- Manual UPDATE BED after each to ensure trigger visibility
BEGIN
    INSERT INTO ADMISSION (admission_id,admit_date,discharge_date,admit_reason,status,BED_bed_id,PATIENT_patient_id,EMPLOYEE_employee_id)
    VALUES (admission_seq.NEXTVAL,TRUNC(SYSDATE)-18,NULL,'Admission reason 1','ACTIVE',11,101,1);
    UPDATE BED SET is_occupied='Y' WHERE bed_id=11;
    COMMIT;
END;
/
 
BEGIN
    INSERT INTO ADMISSION (admission_id,admit_date,discharge_date,admit_reason,status,BED_bed_id,PATIENT_patient_id,EMPLOYEE_employee_id)
    VALUES (admission_seq.NEXTVAL,TRUNC(SYSDATE)-16,NULL,'Admission reason 2','ACTIVE',12,102,2);
    UPDATE BED SET is_occupied='Y' WHERE bed_id=12;
    COMMIT;
END;
/
 
BEGIN
    INSERT INTO ADMISSION (admission_id,admit_date,discharge_date,admit_reason,status,BED_bed_id,PATIENT_patient_id,EMPLOYEE_employee_id)
    VALUES (admission_seq.NEXTVAL,TRUNC(SYSDATE)-14,NULL,'Admission reason 3','ACTIVE',13,103,3);
    UPDATE BED SET is_occupied='Y' WHERE bed_id=13;
    COMMIT;
END;
/
 
BEGIN
    INSERT INTO ADMISSION (admission_id,admit_date,discharge_date,admit_reason,status,BED_bed_id,PATIENT_patient_id,EMPLOYEE_employee_id)
    VALUES (admission_seq.NEXTVAL,TRUNC(SYSDATE)-12,NULL,'Admission reason 4','ACTIVE',14,104,4);
    UPDATE BED SET is_occupied='Y' WHERE bed_id=14;
    COMMIT;
END;
/
 
-- 6 DISCHARGED admissions using beds 15-20
DECLARE v_adm_id NUMBER;
BEGIN
    v_adm_id := admission_seq.NEXTVAL;
    INSERT INTO ADMISSION (admission_id,admit_date,discharge_date,admit_reason,status,BED_bed_id,PATIENT_patient_id,EMPLOYEE_employee_id)
    VALUES (v_adm_id,TRUNC(SYSDATE)-20,NULL,'Admission reason 5','ACTIVE',15,105,5);
    UPDATE BED SET is_occupied='Y' WHERE bed_id=15;
    COMMIT;
    UPDATE ADMISSION SET status='DISCHARGED',discharge_date=TRUNC(SYSDATE)-1 WHERE admission_id=v_adm_id;
    UPDATE BED SET is_occupied='N' WHERE bed_id=15;
    COMMIT;
END;
/
 
DECLARE v_adm_id NUMBER;
BEGIN
    v_adm_id := admission_seq.NEXTVAL;
    INSERT INTO ADMISSION (admission_id,admit_date,discharge_date,admit_reason,status,BED_bed_id,PATIENT_patient_id,EMPLOYEE_employee_id)
    VALUES (v_adm_id,TRUNC(SYSDATE)-18,NULL,'Admission reason 6','ACTIVE',16,106,6);
    UPDATE BED SET is_occupied='Y' WHERE bed_id=16;
    COMMIT;
    UPDATE ADMISSION SET status='DISCHARGED',discharge_date=TRUNC(SYSDATE)-2 WHERE admission_id=v_adm_id;
    UPDATE BED SET is_occupied='N' WHERE bed_id=16;
    COMMIT;
END;
/
 
DECLARE v_adm_id NUMBER;
BEGIN
    v_adm_id := admission_seq.NEXTVAL;
    INSERT INTO ADMISSION (admission_id,admit_date,discharge_date,admit_reason,status,BED_bed_id,PATIENT_patient_id,EMPLOYEE_employee_id)
    VALUES (v_adm_id,TRUNC(SYSDATE)-16,NULL,'Admission reason 7','ACTIVE',17,107,7);
    UPDATE BED SET is_occupied='Y' WHERE bed_id=17;
    COMMIT;
    UPDATE ADMISSION SET status='DISCHARGED',discharge_date=TRUNC(SYSDATE)-3 WHERE admission_id=v_adm_id;
    UPDATE BED SET is_occupied='N' WHERE bed_id=17;
    COMMIT;
END;
/
 
DECLARE v_adm_id NUMBER;
BEGIN
    v_adm_id := admission_seq.NEXTVAL;
    INSERT INTO ADMISSION (admission_id,admit_date,discharge_date,admit_reason,status,BED_bed_id,PATIENT_patient_id,EMPLOYEE_employee_id)
    VALUES (v_adm_id,TRUNC(SYSDATE)-14,NULL,'Admission reason 8','ACTIVE',18,108,8);
    UPDATE BED SET is_occupied='Y' WHERE bed_id=18;
    COMMIT;
    UPDATE ADMISSION SET status='DISCHARGED',discharge_date=TRUNC(SYSDATE)-4 WHERE admission_id=v_adm_id;
    UPDATE BED SET is_occupied='N' WHERE bed_id=18;
    COMMIT;
END;
/
 
DECLARE v_adm_id NUMBER;
BEGIN
    v_adm_id := admission_seq.NEXTVAL;
    INSERT INTO ADMISSION (admission_id,admit_date,discharge_date,admit_reason,status,BED_bed_id,PATIENT_patient_id,EMPLOYEE_employee_id)
    VALUES (v_adm_id,TRUNC(SYSDATE)-12,NULL,'Admission reason 9','ACTIVE',19,109,9);
    UPDATE BED SET is_occupied='Y' WHERE bed_id=19;
    COMMIT;
    UPDATE ADMISSION SET status='DISCHARGED',discharge_date=TRUNC(SYSDATE)-5 WHERE admission_id=v_adm_id;
    UPDATE BED SET is_occupied='N' WHERE bed_id=19;
    COMMIT;
END;
/
 
DECLARE v_adm_id NUMBER;
BEGIN
    v_adm_id := admission_seq.NEXTVAL;
    INSERT INTO ADMISSION (admission_id,admit_date,discharge_date,admit_reason,status,BED_bed_id,PATIENT_patient_id,EMPLOYEE_employee_id)
    VALUES (v_adm_id,TRUNC(SYSDATE)-10,NULL,'Admission reason 10','ACTIVE',20,110,10);
    UPDATE BED SET is_occupied='Y' WHERE bed_id=20;
    COMMIT;
    UPDATE ADMISSION SET status='DISCHARGED',discharge_date=TRUNC(SYSDATE)-6 WHERE admission_id=v_adm_id;
    UPDATE BED SET is_occupied='N' WHERE bed_id=20;
    COMMIT;
END;
/
 
BEGIN DBMS_OUTPUT.PUT_LINE('10 admissions inserted (4 active, 6 discharged).'); END;
/
 
-- BILLING
BEGIN
    FOR rec IN (
        SELECT a.admission_id, a.status AS adm_status,
               a.PATIENT_patient_id,
               pi.INSURANCE_insurance_id, ins.coverage_pct,
               ROW_NUMBER() OVER (ORDER BY a.admission_id) AS rn
        FROM   ADMISSION a
        LEFT JOIN PATIENT_INSURANCE pi ON pi.PATIENT_patient_id=a.PATIENT_patient_id AND pi.is_primary='Y'
        LEFT JOIN INSURANCE ins ON ins.insurance_id=pi.INSURANCE_insurance_id
        ORDER BY a.admission_id
    ) LOOP
        DECLARE
            v_total NUMBER := 5000+(rec.rn*1000);
            v_discount NUMBER := 0; v_net NUMBER; v_status VARCHAR2(20);
        BEGIN
            IF rec.coverage_pct IS NOT NULL THEN v_discount:=ROUND(v_total*rec.coverage_pct/100,2); END IF;
            v_net := v_total-v_discount;
            v_status := CASE WHEN rec.adm_status='ACTIVE' THEN 'PENDING' WHEN MOD(rec.rn,3)=0 THEN 'PARTIALLY_PAID' ELSE 'PAID' END;
            INSERT INTO BILLING (bill_id,bill_date,total_amount,discount,net_amount,status,PATIENT_patient_id,INSURANCE_insurance_id,ADMISSION_admission_id,APPOINTMENT_appointment_id)
            VALUES (bill_seq.NEXTVAL,TRUNC(SYSDATE)-MOD(rec.rn,10),v_total,v_discount,v_net,v_status,rec.PATIENT_patient_id,rec.INSURANCE_insurance_id,rec.admission_id,NULL);
        END;
    END LOOP;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('10 billing rows inserted.');
END;
/
 
-- PAYMENTS
BEGIN
    FOR rec IN (
        SELECT bill_id, net_amount, status, ROW_NUMBER() OVER (ORDER BY bill_id) AS rn
        FROM BILLING WHERE status IN ('PAID','PARTIALLY_PAID') ORDER BY bill_id
    ) LOOP
        INSERT INTO PAYMENT (payment_id,payment_date,amount,payment_method,transaction_ref,BILLING_bill_id)
        VALUES (payment_seq.NEXTVAL,TRUNC(SYSDATE)-MOD(rec.rn,5),
            CASE rec.status WHEN 'PAID' THEN rec.net_amount ELSE ROUND(rec.net_amount*0.5,2) END,
            CASE MOD(rec.rn,3) WHEN 0 THEN 'CASH' WHEN 1 THEN 'CARD' ELSE 'INSURANCE' END,
            'TXN-'||LPAD(rec.rn,6,'0'),rec.bill_id);
    END LOOP;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Payment rows inserted for paid bills.');
END;
/
 
-- EMERGENCY (ICU beds 1 and 2 are free)
BEGIN
    book_emergency(p_patient_id=>50,p_dept_id=>1,p_reason=>'Chest pain - emergency',p_date=>TRUNC(SYSDATE));
    DBMS_OUTPUT.PUT_LINE('Emergency 1: Chest pain booked successfully.');
EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Emergency 1 skipped: '||SQLERRM);
END;
/
 
BEGIN
    book_emergency(p_patient_id=>60,p_dept_id=>2,p_reason=>'Severe head injury - emergency',p_date=>TRUNC(SYSDATE));
    DBMS_OUTPUT.PUT_LINE('Emergency 2: Head injury booked successfully.');
EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Emergency 2 skipped: '||SQLERRM);
END;
/
 
-- VERIFY
SELECT status, COUNT(*) AS total FROM ADMISSION GROUP BY status;
SELECT is_occupied, COUNT(*) AS total FROM BED GROUP BY is_occupied;
SELECT status, COUNT(*) AS total, SUM(net_amount) AS total_revenue FROM BILLING GROUP BY status ORDER BY status;
SELECT payment_method, COUNT(*) AS total, SUM(amount) AS amount_collected FROM PAYMENT GROUP BY payment_method ORDER BY payment_method;
 
SELECT a.admission_id, a.admit_reason, a.admission_type, a.status, a.BED_BED_ID,
       p.first_name||' '||p.last_name AS patient_name
FROM ADMISSION a JOIN PATIENT p ON p.patient_id=a.PATIENT_PATIENT_ID
WHERE a.admission_type='EMERGENCY';
 
BEGIN DBMS_OUTPUT.PUT_LINE('DML/08 completed — admissions, billing, payments loaded.'); 
END;
/