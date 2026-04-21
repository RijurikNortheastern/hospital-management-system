-- =============================================================
-- FILE   : DDL/03_sequences.sql
-- PROJECT: Hospital Management System (DMDD 6210 - Table Turners)
-- RUN AS : hms_admin
-- PURPOSE: Create one sequence per table for PK auto-generation
-- DEPENDS: DDL/01_create_tables.sql must run first
-- SAFE   : Idempotent — drops each sequence if it exists,
--          then recreates from 1
-- COUNT  : 16 sequences (one per table)
-- =============================================================
 
 
-- =============================================================
-- SECTION 1: DROP ALL SEQUENCES (if they exist)
-- Prevents ORA-04043 "object already exists" on re-run
-- =============================================================
 
BEGIN
    FOR s IN (
        SELECT sequence_name
        FROM   user_sequences
        WHERE  sequence_name IN (
            'DEPARTMENT_SEQ', 'ROOM_SEQ',      'PATIENT_SEQ',
            'EMPLOYEE_SEQ',   'BED_SEQ',        'INSURANCE_SEQ',
            'PATIENT_INS_SEQ','SCHEDULE_SEQ',   'EMP_SCHED_SEQ',
            'VACATION_SEQ',   'APPOINTMENT_SEQ','ADMISSION_SEQ',
            'HISTORY_SEQ',    'PRESCRIPTION_SEQ','BILL_SEQ',
            'PAYMENT_SEQ'
        )
    ) LOOP
        EXECUTE IMMEDIATE 'DROP SEQUENCE ' || s.sequence_name;
        DBMS_OUTPUT.PUT_LINE('Dropped sequence: ' || s.sequence_name);
    END LOOP;
END;
/
 
 
-- =============================================================
-- SECTION 2: CREATE ALL SEQUENCES
-- NOCACHE  : Avoids gaps in IDs on instance restart (OCI safe)
-- NOCYCLE  : Sequence stops rather than wrapping around
-- ORDER    : Guarantees ascending order (important on RAC/OCI)
-- =============================================================
 
-- Group A: Independent tables
CREATE SEQUENCE department_seq  START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE ORDER;
CREATE SEQUENCE room_seq        START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE ORDER;
CREATE SEQUENCE patient_seq     START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE ORDER;
CREATE SEQUENCE schedule_seq    START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE ORDER;  -- DOCTOR_SCHEDULE
CREATE SEQUENCE insurance_seq   START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE ORDER;
 
-- Group B: FK-dependent tables
CREATE SEQUENCE employee_seq    START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE ORDER;
CREATE SEQUENCE bed_seq         START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE ORDER;
CREATE SEQUENCE patient_ins_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE ORDER;  -- PATIENT_INSURANCE
CREATE SEQUENCE emp_sched_seq   START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE ORDER;  -- EMPLOYEE_SCHEDULE
CREATE SEQUENCE vacation_seq    START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE ORDER;  -- DOCTOR_VACATION
 
-- Group C: Transactional tables
CREATE SEQUENCE appointment_seq  START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE ORDER;
CREATE SEQUENCE admission_seq    START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE ORDER;
CREATE SEQUENCE history_seq      START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE ORDER;  -- APPOINTMENT_HISTORY
CREATE SEQUENCE prescription_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE ORDER;
CREATE SEQUENCE bill_seq         START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE ORDER;  -- BILLING
CREATE SEQUENCE payment_seq      START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE ORDER;
 
 
-- =============================================================
-- SECTION 3: VERIFY — confirm all 16 sequences created
-- =============================================================
 
SELECT
    sequence_name,
    min_value,
    max_value,
    increment_by,
    cycle_flag,
    order_flag,
    cache_size,
    last_number
FROM   user_sequences
WHERE  sequence_name IN (
    'DEPARTMENT_SEQ', 'ROOM_SEQ',       'PATIENT_SEQ',
    'EMPLOYEE_SEQ',   'BED_SEQ',         'INSURANCE_SEQ',
    'PATIENT_INS_SEQ','SCHEDULE_SEQ',    'EMP_SCHED_SEQ',
    'VACATION_SEQ',   'APPOINTMENT_SEQ', 'ADMISSION_SEQ',
    'HISTORY_SEQ',    'PRESCRIPTION_SEQ','BILL_SEQ',
    'PAYMENT_SEQ'
)
ORDER BY sequence_name;
 
BEGIN
    DBMS_OUTPUT.PUT_LINE('DDL/03_sequences.sql completed — 16 sequences created.');
END;
/