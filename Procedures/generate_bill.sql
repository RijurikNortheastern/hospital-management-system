CREATE OR REPLACE PROCEDURE generate_bill (
    p_patient_id       NUMBER,
    p_admission_id     NUMBER,
    p_appointment_id   NUMBER,
    p_total_amount     NUMBER
)
AS
    v_insurance_id   NUMBER;
    v_coverage       NUMBER := 0;
    v_discount       NUMBER := 0;
    v_net_amount     NUMBER;
BEGIN

    -- Get primary insurance (if exists)
    BEGIN
        SELECT INSURANCE_INSURANCE_ID
        INTO v_insurance_id
        FROM PATIENT_INSURANCE
        WHERE PATIENT_PATIENT_ID = p_patient_id
          AND IS_PRIMARY = 'Y'
          AND VALID_TO >= SYSDATE
          AND ROWNUM = 1;

        SELECT COVERAGE_PCT
        INTO v_coverage
        FROM INSURANCE
        WHERE INSURANCE_ID = v_insurance_id;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_coverage := 0;
    END;

    -- Calculate discount
    v_discount := (p_total_amount * v_coverage) / 100;
    v_net_amount := p_total_amount - v_discount;

    -- Insert bill
   INSERT INTO BILLING (
    BILL_ID,
    BILL_DATE,
    TOTAL_AMOUNT,
    DISCOUNT,
    NET_AMOUNT,
    STATUS,
    PATIENT_PATIENT_ID,
    INSURANCE_INSURANCE_ID,
    ADMISSION_ADMISSION_ID,
    APPOINTMENT_APPOINTMENT_ID
)
VALUES (
    BILL_SEQ.NEXTVAL,
    SYSDATE,
    p_total_amount,
    v_discount,
    v_net_amount,
    'PENDING',
    p_patient_id,
    v_insurance_id,
    p_admission_id,
    p_appointment_id
);

END;
/


