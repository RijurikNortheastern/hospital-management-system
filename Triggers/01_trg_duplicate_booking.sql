-- =============================================================
-- FILE   : Triggers/01_trg_duplicate_booking.sql
-- PROJECT: Hospital Management System (DMDD 6210 - Table Turners)
-- RUN AS : hms_admin
-- PURPOSE: Prevent duplicate appointment bookings
--          Fires BEFORE INSERT on APPOINTMENT
-- =============================================================
 
CREATE OR REPLACE TRIGGER trg_duplicate_booking
BEFORE INSERT ON APPOINTMENT
FOR EACH ROW
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO   v_count
    FROM   APPOINTMENT
    WHERE  PATIENT_patient_id          = :NEW.PATIENT_patient_id
      AND  EMPLOYEE_SCHEDULE_bridge_id = :NEW.EMPLOYEE_SCHEDULE_bridge_id
      AND  appointment_date            = :NEW.appointment_date
      AND  appointment_time            = :NEW.appointment_time
      AND  status NOT IN ('CANCELLED');
 
    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20101,
            'Duplicate appointment: patient already has an active booking ' ||
            'on this slot for ' || TO_CHAR(:NEW.appointment_date, 'YYYY-MM-DD') || '.');
    END IF;
END trg_duplicate_booking;
/
 
-- Verify
SELECT trigger_name, status, trigger_type, triggering_event
FROM   user_triggers
WHERE  trigger_name = 'TRG_DUPLICATE_BOOKING';