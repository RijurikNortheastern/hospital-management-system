CREATE OR REPLACE PROCEDURE admit_patient (
    p_patient_id   NUMBER,
    p_bed_id       NUMBER,
    p_employee_id  NUMBER,
    p_reason       VARCHAR2
)
AS
    v_bed_status   CHAR(1);
    v_count        NUMBER;
BEGIN

    -- Check if bed is already occupied
    SELECT is_occupied
    INTO v_bed_status
    FROM BED
    WHERE bed_id = p_bed_id;

    IF v_bed_status = 'Y' THEN
        RAISE_APPLICATION_ERROR(-20010, 'Bed is already occupied');
    END IF;


    -- Check if patient already has active admission
    SELECT COUNT(*)
    INTO v_count
    FROM ADMISSION
    WHERE PATIENT_PATIENT_ID = p_patient_id
      AND status = 'ACTIVE';

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20011, 'Patient already admitted');
    END IF;


    -- Insert admission
    INSERT INTO ADMISSION (
        admission_id,
        admit_date,
        discharge_date,
        admit_reason,
        status,
        bed_bed_id,
        patient_patient_id,
        employee_employee_id
    )
    VALUES (
        ADMISSION_SEQ.NEXTVAL,
        SYSDATE,
        NULL,
        p_reason,
        'ACTIVE',
        p_bed_id,
        p_patient_id,
        p_employee_id
    );


    -- Update bed status
    UPDATE BED
    SET is_occupied = 'Y'
    WHERE bed_id = p_bed_id;

END;
/
