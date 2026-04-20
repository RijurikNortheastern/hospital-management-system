CREATE OR REPLACE PROCEDURE book_appointment (
    p_patient_id   NUMBER,
    p_bridge_id    NUMBER,
    p_date         DATE,
    p_time         DATE,
    p_reason       VARCHAR2
)
AS
    v_count NUMBER;
    v_role  VARCHAR2(50);
BEGIN

    -- Check duplicate booking
    SELECT COUNT(*)
    INTO v_count
    FROM APPOINTMENT
    WHERE PATIENT_patient_id = p_patient_id
    AND EMPLOYEE_SCHEDULE_bridge_id = p_bridge_id
    AND appointment_date = p_date
    AND appointment_time = p_time
    AND status <> 'CANCELLED';

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Duplicate booking not allowed');
    END IF;

    -- Check doctor role
    SELECT e.role
    INTO v_role
    FROM EMPLOYEE e
    JOIN EMPLOYEE_SCHEDULE es
      ON e.employee_id = es.EMPLOYEE_employee_id
    WHERE es.bridge_id = p_bridge_id;

    IF v_role <> 'DOCTOR' THEN
        RAISE_APPLICATION_ERROR(-20002, 'Only doctors can be booked');
    END IF;

    -- Insert appointment
    INSERT INTO APPOINTMENT (
        appointment_id,
        appointment_date,
        appointment_time,
        status,
        reason,
        created_at,
        PATIENT_patient_id,
        EMPLOYEE_SCHEDULE_bridge_id
    )
    VALUES (
        APPOINTMENT_SEQ.NEXTVAL,
        p_date,
        p_time,
        'SCHEDULED',
        p_reason,
        SYSDATE,
        p_patient_id,
        p_bridge_id
    );

    -- Insert history
    INSERT INTO APPOINTMENT_HISTORY (
        history_id,
        action,
        action_date,
        notes,
        APPOINTMENT_appointment_id
    )
    VALUES (
        HISTORY_SEQ.NEXTVAL,
        'BOOKED',
        SYSDATE,
        'Appointment created',
        APPOINTMENT_SEQ.CURRVAL
    );

END;
/
