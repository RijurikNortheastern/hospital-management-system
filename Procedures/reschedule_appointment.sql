CREATE OR REPLACE PROCEDURE reschedule_appointment (
    p_appointment_id NUMBER,
    p_new_date       DATE,
    p_new_time       DATE,
    p_new_bridge_id  NUMBER
)
AS
    v_count NUMBER;
    v_old_date DATE;
    v_old_time DATE;
BEGIN

    -- Get old appointment data
    SELECT appointment_date, appointment_time
    INTO v_old_date, v_old_time
    FROM APPOINTMENT
    WHERE appointment_id = p_appointment_id;

    -- Check duplicate slot
    SELECT COUNT(*)
    INTO v_count
    FROM APPOINTMENT
    WHERE EMPLOYEE_SCHEDULE_bridge_id = p_new_bridge_id
      AND appointment_date = p_new_date
      AND appointment_time = p_new_time
      AND status <> 'CANCELLED';

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20005, 'Slot already booked');
    END IF;

    -- Save history (old schedule)
    INSERT INTO APPOINTMENT_HISTORY (
        history_id,
        action,
        action_date,
        notes,
        APPOINTMENT_appointment_id
    )
    VALUES (
        HISTORY_SEQ.NEXTVAL,
        'RESCHEDULED',
        SYSDATE,
        'Appointment rescheduled from ' || TO_CHAR(v_old_date,'DD-MON-YYYY'),
        p_appointment_id
    );

    -- Update appointment
    UPDATE APPOINTMENT
    SET appointment_date = p_new_date,
        appointment_time = p_new_time,
        EMPLOYEE_SCHEDULE_bridge_id = p_new_bridge_id,
        status = 'RESCHEDULED'
    WHERE appointment_id = p_appointment_id;

END;
/