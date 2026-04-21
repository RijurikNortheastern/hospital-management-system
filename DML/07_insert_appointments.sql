-- =============================================================
-- FILE   : DML/07_insert_appointments.sql
-- PROJECT: Hospital Management System (DMDD 6210 - Table Turners)
-- RUN AS : hms_admin
-- PURPOSE: Seed 50 appointments with mixed statuses
--          Status mix:  CANCELLED (~10) | COMPLETED (~17) |
--                       RESCHEDULED (~7) | SCHEDULED (~16)
-- DEPENDS: DML/03 (patients), DML/06 (employee_schedule bridge)
-- SAFE   : Idempotent — deletes dependent rows then appointments
-- =============================================================
 
 
-- =============================================================
-- SECTION 1: CLEAN EXISTING DATA (FK order)
-- =============================================================
 
BEGIN
    DELETE FROM APPOINTMENT_HISTORY;
    DELETE FROM PRESCRIPTION;
    DELETE FROM BILLING;
    DELETE FROM APPOINTMENT;
    DBMS_OUTPUT.PUT_LINE('APPOINTMENT and dependent tables cleared.');
END;
/
 
 
-- =============================================================
-- SECTION 2: INSERT 50 APPOINTMENTS
--
-- FIX 1: TO_DATE(time_only) — same issue as DML/06.
--         Use fixed base date 2000-01-01 for time storage.
--
-- FIX 2: MOD(i-1, 200)+1 for patient_id — hardcoded, breaks
--         on re-run. Use ROW_NUMBER() ranked subquery instead.
--
-- FIX 3: MOD(i-1, 300)+1 for bridge_id — EMPLOYEE_SCHEDULE
--         may not have 300 rows and IDs won't start at 1 on
--         re-run. Lookup by rank from EMPLOYEE_SCHEDULE table.
--
-- FIX 4: Missing / after END; — block never executes in SQLcl
-- =============================================================
 
DECLARE
    v_patient_id  NUMBER;
    v_bridge_id   NUMBER;
    v_patient_cnt NUMBER;
    v_bridge_cnt  NUMBER;
BEGIN
    -- Get total counts to keep MOD within valid range
    SELECT COUNT(*) INTO v_patient_cnt FROM PATIENT;
    SELECT COUNT(*) INTO v_bridge_cnt  FROM EMPLOYEE_SCHEDULE;
 
    FOR i IN 1..50 LOOP
 
        -- Lookup i-th patient by rank (cycles through all 200 patients)
        SELECT patient_id INTO v_patient_id
        FROM (
            SELECT patient_id,
                   ROW_NUMBER() OVER (ORDER BY patient_id) AS rn
            FROM   PATIENT
        )
        WHERE rn = MOD(i - 1, v_patient_cnt) + 1;
 
        -- Lookup matching bridge row by rank (cycles through available slots)
        SELECT bridge_id INTO v_bridge_id
        FROM (
            SELECT bridge_id,
                   ROW_NUMBER() OVER (ORDER BY bridge_id) AS rn
            FROM   EMPLOYEE_SCHEDULE
            WHERE  status = 'AVAILABLE'             -- only book available slots
        )
        WHERE rn = MOD(i - 1, v_bridge_cnt) + 1;
 
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
            appointment_seq.NEXTVAL,
            TRUNC(SYSDATE) + MOD(i, 20) - 10,       -- dates: -10 to +9 days from today
            TO_DATE('2000-01-01 ' ||
                LPAD(8 + MOD(i, 8), 2, '0') || ':00',
                'YYYY-MM-DD HH24:MI'),               -- appointment times 08:00–15:00
            CASE
                WHEN MOD(i, 5) = 0 THEN 'CANCELLED'
                WHEN MOD(i, 3) = 0 THEN 'COMPLETED'
                WHEN MOD(i, 7) = 0 THEN 'RESCHEDULED'
                ELSE                     'SCHEDULED'
            END,
            'Reason for visit ' || i,
            SYSDATE - MOD(i, 30),                   -- created_at: up to 30 days ago
            v_patient_id,
            v_bridge_id
        );
    END LOOP;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('50 appointments inserted.');
END;
/
 
 
-- =============================================================
-- SECTION 3: INSERT APPOINTMENT_HISTORY AUDIT ROWS
-- Every appointment gets at least 1 history record (CREATED)
-- RESCHEDULED appointments get a second row showing old/new date
-- =============================================================
 
BEGIN
    -- CREATED record for all 50 appointments
    FOR rec IN (SELECT appointment_id, appointment_date, created_at
                FROM   APPOINTMENT
                ORDER  BY appointment_id)
    LOOP
        INSERT INTO APPOINTMENT_HISTORY (
            history_id,
            action,
            action_date,
            old_date,
            new_date,
            notes,
            APPOINTMENT_appointment_id
        ) VALUES (
            history_seq.NEXTVAL,
            'CREATED',
            rec.created_at,
            NULL,
            rec.appointment_date,
            'Appointment booked',
            rec.appointment_id
        );
    END LOOP;
 
    -- RESCHEDULED record for appointments with RESCHEDULED status
    FOR rec IN (SELECT appointment_id, appointment_date
                FROM   APPOINTMENT
                WHERE  status = 'RESCHEDULED'
                ORDER  BY appointment_id)
    LOOP
        INSERT INTO APPOINTMENT_HISTORY (
            history_id,
            action,
            action_date,
            old_date,
            new_date,
            notes,
            APPOINTMENT_appointment_id
        ) VALUES (
            history_seq.NEXTVAL,
            'RESCHEDULED',
            SYSDATE,
            rec.appointment_date,
            rec.appointment_date + 7,               -- rescheduled 1 week later
            'Patient requested reschedule',
            rec.appointment_id
        );
    END LOOP;
 
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Appointment history rows inserted.');
END;
/
 
 
-- =============================================================
-- SECTION 4: VERIFY
-- =============================================================
 
-- Status distribution
SELECT
    status,
    COUNT(*) AS total
FROM   APPOINTMENT
GROUP  BY status
ORDER  BY status;
 
-- Date range sanity check
SELECT
    MIN(appointment_date) AS earliest,
    MAX(appointment_date) AS latest,
    COUNT(*)              AS total
FROM   APPOINTMENT;
 
-- History audit check
SELECT
    action,
    COUNT(*) AS total
FROM   APPOINTMENT_HISTORY
GROUP  BY action
ORDER  BY action;
 
BEGIN
    DBMS_OUTPUT.PUT_LINE('DML/07 completed — 50 appointments + history rows inserted.');
END;
/