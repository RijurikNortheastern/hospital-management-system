CREATE OR REPLACE PROCEDURE cancel_appointment (
    p_appointment_id NUMBER
)
AS
    v_date   DATE;
    v_status VARCHAR2(20);
BEGIN

    -- Get appointment info
    SELECT appointment_date, status
    INTO v_date, v_status
    FROM APPOINTMENT
    WHERE appointment_id = p_appointment_id;

    -- Check already cancelled
    IF v_status = 'CANCELLED' THEN
        RAISE_APPLICATION_ERROR(-20003, 'Appointment already cancelled');
    END IF;

    -- Check 24 hour rule
    IF v_date - SYSDATE < 1 THEN
        RAISE_APPLICATION_ERROR(-20004, 'Cannot cancel within 24 hours');
    END IF;

    -- Update appointment
    UPDATE APPOINTMENT
    SET status = 'CANCELLED'
    WHERE appointment_id = p_appointment_id;

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
        'CANCELLED',
        SYSDATE,
        'Appointment cancelled',
        p_appointment_id
    );

END;
/