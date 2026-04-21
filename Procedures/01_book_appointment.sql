-- =============================================================
-- FILE   : Procedures/book_appointment.sql
-- PROJECT: Hospital Management System (DMDD 6210 - Table Turners)
-- RUN AS : hms_admin
-- PURPOSE: Book a new appointment with full validation
-- VALIDATIONS:
--   1. Patient must exist
--   2. Schedule slot (bridge_id) must exist and be AVAILABLE
--   3. Employee linked to slot must be a DOCTOR
--   4. No duplicate booking (same patient + slot + date + time)
--   5. Doctor must not be on approved vacation on that date
--   6. Doctor cannot have more than 5 appointments per day
-- CALLED BY: hms_operator or application layer
-- =============================================================
 
CREATE OR REPLACE PROCEDURE book_appointment (
    p_patient_id   IN NUMBER,
    p_bridge_id    IN NUMBER,
    p_date         IN DATE,
    p_time         IN DATE,
    p_reason       IN VARCHAR2
)
AS
    v_count        NUMBER;
    v_role         VARCHAR2(50);
    v_sched_status VARCHAR2(20);
    v_new_appt_id  NUMBER;
    v_patient_cnt  NUMBER;
    v_vacation_cnt NUMBER;
BEGIN
 
    -- ──────────────────────────────────────────────────────────
    -- VALIDATION 1: Patient must exist
    -- ──────────────────────────────────────────────────────────
    SELECT COUNT(*) INTO v_patient_cnt
    FROM   PATIENT
    WHERE  patient_id = p_patient_id;
 
    IF v_patient_cnt = 0 THEN
        RAISE_APPLICATION_ERROR(-20010, 'Patient ID ' || p_patient_id || ' does not exist.');
    END IF;
 
    -- ──────────────────────────────────────────────────────────
    -- VALIDATION 2: Schedule slot must exist and be AVAILABLE
    --      against an ON_LEAVE or UNAVAILABLE slot is invalid
    -- ──────────────────────────────────────────────────────────
    BEGIN
        SELECT status INTO v_sched_status
        FROM   EMPLOYEE_SCHEDULE
        WHERE  bridge_id = p_bridge_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20011, 'Schedule slot ' || p_bridge_id || ' does not exist.');
    END;
 
    IF v_sched_status <> 'AVAILABLE' THEN
        RAISE_APPLICATION_ERROR(-20012,
            'Schedule slot ' || p_bridge_id || ' is not available (status: ' || v_sched_status || ').');
    END IF;
 
    -- ──────────────────────────────────────────────────────────
    -- VALIDATION 3: Employee linked to slot must be a DOCTOR
    --      links to 0 or 2+ employees it would crash silently
    -- ──────────────────────────────────────────────────────────
    BEGIN
        SELECT e.role INTO v_role
        FROM   EMPLOYEE e
        JOIN   EMPLOYEE_SCHEDULE es ON e.employee_id = es.EMPLOYEE_employee_id
        WHERE  es.bridge_id = p_bridge_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20013, 'No employee linked to schedule slot ' || p_bridge_id || '.');
        WHEN TOO_MANY_ROWS THEN
            RAISE_APPLICATION_ERROR(-20014, 'Data integrity error: multiple employees on slot ' || p_bridge_id || '.');
    END;
 
    IF v_role <> 'DOCTOR' THEN
        RAISE_APPLICATION_ERROR(-20015,
            'Only DOCTOR slots can be booked. Employee role is: ' || v_role || '.');
    END IF;
 
    -- ──────────────────────────────────────────────────────────
    -- VALIDATION 4: No duplicate booking
    -- Same patient + same slot + same date/time + not cancelled
    -- ──────────────────────────────────────────────────────────
    SELECT COUNT(*) INTO v_count
    FROM   APPOINTMENT
    WHERE  PATIENT_patient_id          = p_patient_id
      AND  EMPLOYEE_SCHEDULE_bridge_id = p_bridge_id
      AND  appointment_date            = p_date
      AND  appointment_time            = p_time
      AND  status                     <> 'CANCELLED';
 
    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20016,
            'Duplicate booking: patient ' || p_patient_id ||
            ' already has an active appointment on this slot.');
    END IF;
 
    -- ──────────────────────────────────────────────────────────
    -- VALIDATION 5: Doctor must not be on approved vacation
    -- ──────────────────────────────────────────────────────────
    SELECT COUNT(*) INTO v_vacation_cnt
    FROM   DOCTOR_VACATION dv
    JOIN   EMPLOYEE_SCHEDULE es ON es.EMPLOYEE_employee_id = dv.EMPLOYEE_employee_id
    WHERE  es.bridge_id  = p_bridge_id
      AND  dv.status     = 'APPROVED'
      AND  p_date BETWEEN dv.start_date AND dv.end_date;
 
    IF v_vacation_cnt > 0 THEN
        RAISE_APPLICATION_ERROR(-20017,
            'Doctor is on approved vacation on ' || TO_CHAR(p_date, 'YYYY-MM-DD') || '.');
    END IF;
 
    -- ──────────────────────────────────────────────────────────
    -- VALIDATION 6: Doctor cannot have more than 5 appointments
    --               per day (business rule from Part 1)
    -- ──────────────────────────────────────────────────────────
    SELECT COUNT(*) INTO v_count
    FROM   APPOINTMENT a
    JOIN   EMPLOYEE_SCHEDULE es ON es.bridge_id = a.EMPLOYEE_SCHEDULE_bridge_id
    WHERE  es.EMPLOYEE_employee_id = (
               SELECT es2.EMPLOYEE_employee_id
               FROM   EMPLOYEE_SCHEDULE es2
               WHERE  es2.bridge_id = p_bridge_id
           )
      AND  a.appointment_date = p_date
      AND  a.status NOT IN ('CANCELLED');
 
    IF v_count >= 5 THEN
        RAISE_APPLICATION_ERROR(-20018,
            'Doctor already has 5 appointments on ' ||
            TO_CHAR(p_date, 'YYYY-MM-DD') || '. Maximum limit reached.');
    END IF;
 
    -- ──────────────────────────────────────────────────────────
    -- INSERT APPOINTMENT
    --      for history insert — avoids CURRVAL scope issues
    --      across different statement contexts
    -- ──────────────────────────────────────────────────────────
    v_new_appt_id := APPOINTMENT_SEQ.NEXTVAL;
 
    INSERT INTO APPOINTMENT (
        appointment_id,
        appointment_date,
        appointment_time,
        status,
        reason,
        created_at,
        PATIENT_patient_id,
        EMPLOYEE_SCHEDULE_bridge_id
    ) VALUES (
        v_new_appt_id,
        p_date,
        p_time,
        'SCHEDULED',
        p_reason,
        SYSDATE,
        p_patient_id,
        p_bridge_id
    );
 
    -- ──────────────────────────────────────────────────────────
    -- INSERT APPOINTMENT HISTORY
    --      CURRVAL is session-scoped but using the variable is
    --      safer and more explicit
    --      match APPOINTMENT_HISTORY_action CHECK constraint
    --      values used elsewhere in the project
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
        'CREATED',
        SYSDATE,
        NULL,
        p_date,
        'Appointment booked via book_appointment procedure',
        v_new_appt_id
    );
 
    -- Mark schedule slot as booked
    UPDATE EMPLOYEE_SCHEDULE
    SET    status = 'UNAVAILABLE'
    WHERE  bridge_id = p_bridge_id;
 
    COMMIT;
 
    DBMS_OUTPUT.PUT_LINE('Appointment ' || v_new_appt_id ||
                         ' booked successfully for patient ' || p_patient_id || '.');
 
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;  -- re-raise so caller sees the original error
END book_appointment;
/
 
-- =============================================================
-- VERIFY procedure compiled without errors
-- =============================================================
SELECT object_name, object_type, status, last_ddl_time
FROM   user_objects
WHERE  object_name = 'BOOK_APPOINTMENT';