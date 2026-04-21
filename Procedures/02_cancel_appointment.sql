-- =============================================================
-- FILE   : Procedures/02_cancel_appointment.sql
-- PROJECT: Hospital Management System (DMDD 6210 - Table Turners)
-- RUN AS : hms_admin
-- PURPOSE: Cancel an existing appointment with validations
-- VALIDATIONS:
--   1. Appointment must exist
--   2. Appointment must not already be CANCELLED or COMPLETED
--   3. Cannot cancel within 24 hours of appointment time
-- SIDE EFFECTS:
--   - Sets APPOINTMENT.status = 'CANCELLED'
--   - Releases EMPLOYEE_SCHEDULE slot back to 'AVAILABLE'
--   - Inserts APPOINTMENT_HISTORY audit row
-- =============================================================
 
CREATE OR REPLACE PROCEDURE cancel_appointment (
    p_appointment_id IN NUMBER
)
AS
    v_date      DATE;
    v_status    VARCHAR2(20);
    v_bridge_id NUMBER;
BEGIN
 
    -- ──────────────────────────────────────────────────────────
    -- VALIDATION 1: Appointment must exist
    --      unhandled NO_DATA_FOUND if ID doesn't exist
    -- ──────────────────────────────────────────────────────────
    BEGIN
        SELECT appointment_date,
               status,
               EMPLOYEE_SCHEDULE_bridge_id
        INTO   v_date,
               v_status,
               v_bridge_id
        FROM   APPOINTMENT
        WHERE  appointment_id = p_appointment_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20020,
                'Appointment ID ' || p_appointment_id || ' does not exist.');
    END;
 
    -- ──────────────────────────────────────────────────────────
    -- VALIDATION 2: Cannot cancel if already CANCELLED or COMPLETED
    --      appointments should not be cancellable either
    -- ──────────────────────────────────────────────────────────
    IF v_status = 'CANCELLED' THEN
        RAISE_APPLICATION_ERROR(-20021,
            'Appointment ' || p_appointment_id || ' is already cancelled.');
    END IF;
 
    IF v_status = 'COMPLETED' THEN
        RAISE_APPLICATION_ERROR(-20022,
            'Appointment ' || p_appointment_id || ' is already completed and cannot be cancelled.');
    END IF;
 
    -- ──────────────────────────────────────────────────────────
    -- VALIDATION 3: Cannot cancel within 24 hours
    --      only DATE portions — use TRUNC for clean day comparison
    --      and add descriptive message with actual appointment date
    -- ──────────────────────────────────────────────────────────
    IF (v_date - SYSDATE) < 1 THEN
        RAISE_APPLICATION_ERROR(-20023,
            'Cannot cancel appointment on ' ||
            TO_CHAR(v_date, 'YYYY-MM-DD') ||
            ' — must cancel at least 24 hours in advance.');
    END IF;
 
    -- ──────────────────────────────────────────────────────────
    -- UPDATE APPOINTMENT STATUS
    -- ──────────────────────────────────────────────────────────
    UPDATE APPOINTMENT
    SET    status = 'CANCELLED'
    WHERE  appointment_id = p_appointment_id;
 
    -- ──────────────────────────────────────────────────────────
    -- RELEASE SCHEDULE SLOT BACK TO AVAILABLE
    --      doctor's schedule stayed 'UNAVAILABLE' after cancel
    -- ──────────────────────────────────────────────────────────
    UPDATE EMPLOYEE_SCHEDULE
    SET    status = 'AVAILABLE'
    WHERE  bridge_id = v_bridge_id;
 
    -- ──────────────────────────────────────────────────────────
    -- INSERT APPOINTMENT HISTORY AUDIT ROW
    --      missing — needed for audit trail completeness
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
        'CANCELLED',
        SYSDATE,
        v_date,             -- old appointment date
        NULL,               -- no new date for cancellations
        'Appointment cancelled via cancel_appointment procedure',
        p_appointment_id
    );
 
    COMMIT;
 
    DBMS_OUTPUT.PUT_LINE('Appointment ' || p_appointment_id ||
                         ' cancelled successfully.');
 
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END cancel_appointment;
/
 
-- =============================================================
-- VERIFY procedure compiled without errors
-- =============================================================
SELECT object_name, object_type, status, last_ddl_time
FROM   user_objects
WHERE  object_name = 'CANCEL_APPOINTMENT';