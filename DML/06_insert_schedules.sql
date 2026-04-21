-- =============================================================
-- FILE   : DML/06_insert_schedules.sql
-- PROJECT: Hospital Management System (DMDD 6210 - Table Turners)
-- RUN AS : hms_admin
-- PURPOSE: Seed doctor schedule templates, employee-schedule
--          bridge assignments, and doctor vacation records
--            10 schedule templates (Mon–Fri, AM + PM slots)
--            ~300 employee_schedule rows (15 doctors × ~20 days)
--            3 doctor vacation records
-- DEPENDS: DML/02 (employees 1–15 doctors must exist)
-- SAFE   : Idempotent — deletes all rows before re-inserting
-- =============================================================
 
 
-- =============================================================
-- SECTION 1: CLEAN EXISTING DATA (FK order)
-- APPOINTMENT references EMPLOYEE_SCHEDULE — clear it first
-- =============================================================
 
BEGIN
    DELETE FROM APPOINTMENT_HISTORY;
    DELETE FROM PRESCRIPTION;
    DELETE FROM BILLING;
    DELETE FROM APPOINTMENT;
    DELETE FROM EMPLOYEE_SCHEDULE;
    DELETE FROM DOCTOR_VACATION;
    DELETE FROM DOCTOR_SCHEDULE;
    DBMS_OUTPUT.PUT_LINE('Schedule tables cleared.');
END;
/
 
 
-- =============================================================
-- SECTION 2: INSERT 10 DOCTOR_SCHEDULE TEMPLATES
--      which satisfies SCHED_TIME_CHK (end > start) but is
--      misleading. Use a fixed base date so time comparisons
--      are unambiguous and consistent across all environments.
--      Base date: 01-JAN-2000 (date portion ignored at runtime)
-- =============================================================
 
INSERT INTO DOCTOR_SCHEDULE (schedule_id, day_of_week, start_time, end_time)
VALUES (schedule_seq.NEXTVAL, 'MONDAY',
    TO_DATE('2000-01-01 09:00','YYYY-MM-DD HH24:MI'),
    TO_DATE('2000-01-01 13:00','YYYY-MM-DD HH24:MI'));
 
INSERT INTO DOCTOR_SCHEDULE (schedule_id, day_of_week, start_time, end_time)
VALUES (schedule_seq.NEXTVAL, 'MONDAY',
    TO_DATE('2000-01-01 14:00','YYYY-MM-DD HH24:MI'),
    TO_DATE('2000-01-01 17:00','YYYY-MM-DD HH24:MI'));
 
INSERT INTO DOCTOR_SCHEDULE (schedule_id, day_of_week, start_time, end_time)
VALUES (schedule_seq.NEXTVAL, 'TUESDAY',
    TO_DATE('2000-01-01 09:00','YYYY-MM-DD HH24:MI'),
    TO_DATE('2000-01-01 13:00','YYYY-MM-DD HH24:MI'));
 
INSERT INTO DOCTOR_SCHEDULE (schedule_id, day_of_week, start_time, end_time)
VALUES (schedule_seq.NEXTVAL, 'TUESDAY',
    TO_DATE('2000-01-01 14:00','YYYY-MM-DD HH24:MI'),
    TO_DATE('2000-01-01 17:00','YYYY-MM-DD HH24:MI'));
 
INSERT INTO DOCTOR_SCHEDULE (schedule_id, day_of_week, start_time, end_time)
VALUES (schedule_seq.NEXTVAL, 'WEDNESDAY',
    TO_DATE('2000-01-01 09:00','YYYY-MM-DD HH24:MI'),
    TO_DATE('2000-01-01 13:00','YYYY-MM-DD HH24:MI'));
 
INSERT INTO DOCTOR_SCHEDULE (schedule_id, day_of_week, start_time, end_time)
VALUES (schedule_seq.NEXTVAL, 'WEDNESDAY',
    TO_DATE('2000-01-01 14:00','YYYY-MM-DD HH24:MI'),
    TO_DATE('2000-01-01 17:00','YYYY-MM-DD HH24:MI'));
 
INSERT INTO DOCTOR_SCHEDULE (schedule_id, day_of_week, start_time, end_time)
VALUES (schedule_seq.NEXTVAL, 'THURSDAY',
    TO_DATE('2000-01-01 09:00','YYYY-MM-DD HH24:MI'),
    TO_DATE('2000-01-01 13:00','YYYY-MM-DD HH24:MI'));
 
INSERT INTO DOCTOR_SCHEDULE (schedule_id, day_of_week, start_time, end_time)
VALUES (schedule_seq.NEXTVAL, 'THURSDAY',
    TO_DATE('2000-01-01 14:00','YYYY-MM-DD HH24:MI'),
    TO_DATE('2000-01-01 17:00','YYYY-MM-DD HH24:MI'));
 
INSERT INTO DOCTOR_SCHEDULE (schedule_id, day_of_week, start_time, end_time)
VALUES (schedule_seq.NEXTVAL, 'FRIDAY',
    TO_DATE('2000-01-01 09:00','YYYY-MM-DD HH24:MI'),
    TO_DATE('2000-01-01 13:00','YYYY-MM-DD HH24:MI'));
 
INSERT INTO DOCTOR_SCHEDULE (schedule_id, day_of_week, start_time, end_time)
VALUES (schedule_seq.NEXTVAL, 'FRIDAY',
    TO_DATE('2000-01-01 14:00','YYYY-MM-DD HH24:MI'),
    TO_DATE('2000-01-01 17:00','YYYY-MM-DD HH24:MI'));
 
COMMIT;
BEGIN
    DBMS_OUTPUT.PUT_LINE('10 doctor schedule templates inserted.');
END;
/
 
 
-- =============================================================
-- SECTION 3: EMPLOYEE_SCHEDULE BRIDGE
-- Assigns each of the 15 doctors to schedule slots over 30 days
--      schedule_id — never rely on hardcoded loop integers
-- Pattern: doctor works ~20 out of 30 days (skips every 3rd)
-- =============================================================
 
DECLARE
    v_emp_id   NUMBER;
    v_sched_id NUMBER;
BEGIN
    FOR doc_rank IN 1..15 LOOP
 
        -- Lookup the actual employee_id for the doc_rank-th doctor
        SELECT employee_id INTO v_emp_id
        FROM (
            SELECT employee_id,
                   ROW_NUMBER() OVER (ORDER BY employee_id) AS rn
            FROM   EMPLOYEE
            WHERE  role = 'DOCTOR'
        )
        WHERE rn = doc_rank;
 
        FOR day_offset IN 0..29 LOOP
            -- Skip every 3rd day per doctor to simulate days off
            IF MOD(day_offset, 3) != MOD(doc_rank, 3) THEN
 
                -- Rotate across 10 schedule templates
                SELECT schedule_id INTO v_sched_id
                FROM (
                    SELECT schedule_id,
                           ROW_NUMBER() OVER (ORDER BY schedule_id) AS rn
                    FROM   DOCTOR_SCHEDULE
                )
                WHERE rn = MOD(day_offset * 2 + doc_rank, 10) + 1;
 
                INSERT INTO EMPLOYEE_SCHEDULE (
                    bridge_id,
                    availability_date,
                    status,
                    EMPLOYEE_employee_id,
                    DOCTOR_SCHEDULE_schedule_id
                ) VALUES (
                    emp_sched_seq.NEXTVAL,
                    TRUNC(SYSDATE) + day_offset,
                    'AVAILABLE',
                    v_emp_id,
                    v_sched_id
                );
            END IF;
        END LOOP;
    END LOOP;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Employee-schedule bridge rows inserted.');
END;
/
 
 
-- =============================================================
-- SECTION 4: DOCTOR VACATIONS (3 records)
--      instead of hardcoded values 1, 5, 10
-- =============================================================
 
DECLARE
    v_doc1  NUMBER;
    v_doc5  NUMBER;
    v_doc10 NUMBER;
BEGIN
    -- Lookup actual employee_ids by doctor rank
    SELECT employee_id INTO v_doc1
    FROM (SELECT employee_id, ROW_NUMBER() OVER (ORDER BY employee_id) AS rn
          FROM EMPLOYEE WHERE role = 'DOCTOR') WHERE rn = 1;
 
    SELECT employee_id INTO v_doc5
    FROM (SELECT employee_id, ROW_NUMBER() OVER (ORDER BY employee_id) AS rn
          FROM EMPLOYEE WHERE role = 'DOCTOR') WHERE rn = 5;
 
    SELECT employee_id INTO v_doc10
    FROM (SELECT employee_id, ROW_NUMBER() OVER (ORDER BY employee_id) AS rn
          FROM EMPLOYEE WHERE role = 'DOCTOR') WHERE rn = 10;
 
    INSERT INTO DOCTOR_VACATION (
        vacation_id, start_date, end_date, reason, status, EMPLOYEE_employee_id
    ) VALUES (
        vacation_seq.NEXTVAL, SYSDATE + 5,  SYSDATE + 10,
        'Family vacation', 'APPROVED', v_doc1
    );
 
    INSERT INTO DOCTOR_VACATION (
        vacation_id, start_date, end_date, reason, status, EMPLOYEE_employee_id
    ) VALUES (
        vacation_seq.NEXTVAL, SYSDATE + 15, SYSDATE + 20,
        'Conference',       'APPROVED', v_doc5
    );
 
    INSERT INTO DOCTOR_VACATION (
        vacation_id, start_date, end_date, reason, status, EMPLOYEE_employee_id
    ) VALUES (
        vacation_seq.NEXTVAL, SYSDATE + 2,  SYSDATE + 4,
        'Personal leave',   'PENDING',  v_doc10
    );
 
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('3 doctor vacation records inserted.');
END;
/
 
 
-- =============================================================
-- SECTION 5: VERIFY
-- =============================================================
 
-- Schedule templates
SELECT schedule_id, day_of_week,
       TO_CHAR(start_time,'HH24:MI') AS start_time,
       TO_CHAR(end_time,  'HH24:MI') AS end_time
FROM   DOCTOR_SCHEDULE
ORDER  BY schedule_id;
 
-- Employee schedule summary by doctor
SELECT
    e.first_name || ' ' || e.last_name AS doctor_name,
    COUNT(es.bridge_id)                AS assigned_slots
FROM   EMPLOYEE_SCHEDULE es
JOIN   EMPLOYEE e ON e.employee_id = es.EMPLOYEE_employee_id
GROUP  BY e.first_name, e.last_name
ORDER  BY doctor_name;
 
-- Vacations
SELECT
    e.first_name || ' ' || e.last_name AS doctor_name,
    dv.start_date, dv.end_date, dv.reason, dv.status
FROM   DOCTOR_VACATION dv
JOIN   EMPLOYEE e ON e.employee_id = dv.EMPLOYEE_employee_id;
 
BEGIN
    DBMS_OUTPUT.PUT_LINE('DML/06 completed — schedules and vacations loaded.');
END;
/