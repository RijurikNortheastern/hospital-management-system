-- =============================================================
-- FILE   : Procedures/03_reschedule_appointment.sql
-- PROJECT: Hospital Management System (DMDD 6210 - Table Turners)
-- RUN AS : hms_admin
-- PURPOSE: Reschedule an existing appointment to a new slot
-- VALIDATIONS:
--   1. Appointment must exist
--   2. Appointment must not be CANCELLED or COMPLETED
--   3. New slot must exist and be AVAILABLE
--   4. New slot employee must be a DOCTOR
--   5. No duplicate booking on new slot
--   6. Doctor must not be on vacation on new date
-- SIDE EFFECTS:
--   - Releases old EMPLOYEE_SCHEDULE slot → AVAILABLE
--   - Marks new EMPLOYEE_SCHEDULE slot → UNAVAILABLE
--   - Updates APPOINTMENT with new date/time/bridge
--   - Inserts APPOINTMENT_HISTORY audit row with old/new dates
-- =============================================================
 
CREATE OR REPLACE PROCEDURE reschedule_appointment (
    p_appointment_id IN NUMBER,
    p_new_date       IN DATE,
    p_new_time       IN DATE,
    p_new_bridge_id  IN NUMBER
)
AS
    v_old_date      DATE;
    v_old_time      DATE;
    v_old_bridge_id NUMBER;
    v_status        VARCHAR2(20);
    v_count         NUMBER;
    v_role          VARCHAR2(50);
    v_sched_status  VARCHAR2(20);
    v_vacation_cnt  NUMBER;
BEGIN
 
    -- ──────────────────────────────────────────────────────────
    -- VALIDATION 1: Appointment must exist
    --      would crash with an unhandled exception
    -- ──────────────────────────────────────────────────────────
    BEGIN
        SELECT appointment_date,
               appointment_time,
               status,
               EMPLOYEE_SCHEDULE_bridge_id
        INTO   v_old_date,
               v_old_time,
               v_status,
               v_old_bridge_id
        FROM   APPOINTMENT
        WHERE  appointment_id = p_appointment_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20030,
                'Appointment ID ' || p_appointment_id || ' does not exist.');
    END;
 
    -- ──────────────────────────────────────────────────────────
    -- VALIDATION 2: Cannot reschedule CANCELLED or COMPLETED
    -- ──────────────────────────────────────────────────────────
    IF v_status = 'CANCELLED' THEN
        RAISE_APPLICATION_ERROR(-20031,
            'Appointment ' || p_appointment_id || ' is cancelled and cannot be rescheduled.');
    END IF;
 
    IF v_status = 'COMPLETED' THEN
        RAISE_APPLICATION_ERROR(-20032,
            'Appointment ' || p_appointment_id || ' is completed and cannot be rescheduled.');
    END IF;
 
    -- ──────────────────────────────────────────────────────────
    -- VALIDATION 3: New slot must exist and be AVAILABLE
    -- ──────────────────────────────────────────────────────────
    BEGIN
        SELECT status INTO v_sched_status
        FROM   EMPLOYEE_SCHEDULE
        WHERE  bridge_id = p_new_bridge_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20033,
                'New schedule slot ' || p_new_bridge_id || ' does not exist.');
    END;
 
    IF v_sched_status <> 'AVAILABLE' THEN
        RAISE_APPLICATION_ERROR(-20034,
            'New schedule slot ' || p_new_bridge_id ||
            ' is not available (status: ' || v_sched_status || ').');
    END IF;
 
    -- ──────────────────────────────────────────────────────────
    -- VALIDATION 4: New slot employee must be a DOCTOR
    -- ──────────────────────────────────────────────────────────
    BEGIN
        SELECT e.role INTO v_role
        FROM   EMPLOYEE e
        JOIN   EMPLOYEE_SCHEDULE es ON e.employee_id = es.EMPLOYEE_employee_id
        WHERE  es.bridge_id = p_new_bridge_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20035,
                'No employee linked to new schedule slot ' || p_new_bridge_id || '.');
        WHEN TOO_MANY_ROWS THEN
            RAISE_APPLICATION_ERROR(-20036,
                'Data integrity error on slot ' || p_new_bridge_id || '.');
    END;
 
    IF v_role <> 'DOCTOR' THEN
        RAISE_APPLICATION_ERROR(-20037,
            'New slot must be a DOCTOR slot. Employee role is: ' || v_role || '.');
    END IF;
 
    -- ──────────────────────────────────────────────────────────
    -- VALIDATION 5: No duplicate booking on new slot
    --      appointment being rescheduled itself — would block
    --      rescheduling to same slot with different time
    -- ──────────────────────────────────────────────────────────
    SELECT COUNT(*) INTO v_count
    FROM   APPOINTMENT
    WHERE  EMPLOYEE_SCHEDULE_bridge_id = p_new_bridge_id
      AND  appointment_date            = p_new_date
      AND  appointment_time            = p_new_time
      AND  status                     <> 'CANCELLED'
      AND  appointment_id             <> p_appointment_id;  -- exclude self
 
    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20038,
            'New slot on ' || TO_CHAR(p_new_date, 'YYYY-MM-DD') ||
            ' at ' || TO_CHAR(p_new_time, 'HH24:MI') || ' is already booked.');
    END IF;
 
    -- ──────────────────────────────────────────────────────────
    -- VALIDATION 6: Doctor not on vacation on new date
    -- ──────────────────────────────────────────────────────────
    SELECT COUNT(*) INTO v_vacation_cnt
    FROM   DOCTOR_VACATION dv
    JOIN   EMPLOYEE_SCHEDULE es ON es.EMPLOYEE_employee_id = dv.EMPLOYEE_employee_id
    WHERE  es.bridge_id = p_new_bridge_id
      AND  dv.status    = 'APPROVED'
      AND  p_new_date   BETWEEN dv.start_date AND dv.end_date;
 
    IF v_vacation_cnt > 0 THEN
        RAISE_APPLICATION_ERROR(-20039,
            'Doctor is on approved vacation on ' ||
            TO_CHAR(p_new_date, 'YYYY-MM-DD') || '.');
    END IF;
 
    -- ──────────────────────────────────────────────────────────
    -- INSERT HISTORY BEFORE UPDATE (captures old values)
    --      but was missing old_date and new_date columns
    -- ──────────────────────────────────────────────────────────
    INSERT INTO APPOINTMENT_HISTORY (
        history_id,
        action,
        action_date,
        old_date,
        new_date,
        notes,
        APPOINTMENT_appointment_id
    ) VALUES (
        HISTORY_SEQ.NEXTVAL,
        'RESCHEDULED',
        SYSDATE,
        v_old_date,
        p_new_date,
        'Rescheduled from ' || TO_CHAR(v_old_date, 'YYYY-MM-DD') ||
        ' to '              || TO_CHAR(p_new_date,  'YYYY-MM-DD'),
        p_appointment_id
    );
 
    -- ──────────────────────────────────────────────────────────
    -- RELEASE OLD SLOT → AVAILABLE
    -- ──────────────────────────────────────────────────────────
    UPDATE EMPLOYEE_SCHEDULE
    SET    status = 'AVAILABLE'
    WHERE  bridge_id = v_old_bridge_id;
 
    -- ──────────────────────────────────────────────────────────
    -- UPDATE APPOINTMENT
    -- ──────────────────────────────────────────────────────────
    UPDATE APPOINTMENT
    SET    appointment_date            = p_new_date,
           appointment_time            = p_new_time,
           EMPLOYEE_SCHEDULE_bridge_id = p_new_bridge_id,
           status                      = 'RESCHEDULED'
    WHERE  appointment_id = p_appointment_id;
 
    -- ──────────────────────────────────────────────────────────
    -- MARK NEW SLOT → UNAVAILABLE
    -- ──────────────────────────────────────────────────────────
    UPDATE EMPLOYEE_SCHEDULE
    SET    status = 'UNAVAILABLE'
    WHERE  bridge_id = p_new_bridge_id;
 
    COMMIT;
 
    DBMS_OUTPUT.PUT_LINE('Appointment ' || p_appointment_id ||
                         ' rescheduled from ' || TO_CHAR(v_old_date, 'YYYY-MM-DD') ||
                         ' to '              || TO_CHAR(p_new_date,  'YYYY-MM-DD') || '.');
 
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END reschedule_appointment;
/
 
-- =============================================================
-- VERIFY procedure compiled without errors
-- =============================================================
SELECT object_name, object_type, status, last_ddl_time
FROM   user_objects
WHERE  object_name = 'RESCHEDULE_APPOINTMENT';