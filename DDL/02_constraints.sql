-- =============================================================
-- FILE   : DDL/02_constraints.sql
-- PROJECT: Hospital Management System (DMDD 6210 - Table Turners)
-- RUN AS : hms_admin
-- PURPOSE: Add UNIQUE, CHECK, and FOREIGN KEY constraints
-- DEPENDS: DDL/01_create_tables.sql must run first
-- SAFE   : Idempotent — drops each constraint if it exists,
--          then re-adds it cleanly
-- COUNTS : 5 UNIQUE  |  13 CHECK  |  22 FOREIGN KEYS
-- =============================================================
 
 
-- =============================================================
-- SECTION 1: DROP ALL CONSTRAINTS (if they exist)
-- Allows clean re-run without ORA-02264 / ORA-02261 errors
-- =============================================================
 
BEGIN
    FOR c IN (
        SELECT constraint_name, table_name
        FROM   user_constraints
        WHERE  constraint_name IN (
            -- UNIQUE
            'PATIENT_EMAIL_UN', 'EMPLOYEE_EMAIL_UN', 'EMPLOYEE_LICENSE_NO_UN',
            'INSURANCE_POLICY_NUMBER_UN', 'ROOM_ROOM_NUMBER_UN',
            -- CHECK
            'ADM_STATUS_CHK', 'APPT_STATUS_CHK', 'BED_OCC_CHK',
            'BILL_STATUS_CHK', 'SCHED_TIME_CHK', 'VAC_DATE_CHK',
            'EMP_ROLE_CHK', 'INS_COVERAGE_CHK', 'PI_DATE_CHK',
            'PI_PRIMARY_CHK', 'PAY_AMT_CHK', 'ROOM_TYPE_CHK',
            'EMP_SCHED_STATUS_CHK',
            -- FOREIGN KEYS
            'PATIENT_GUARDIAN_FK', 'EMPLOYEE_DEPARTMENT_FK', 'BED_ROOM_FK',
            'PI_PATIENT_FK', 'PI_INSURANCE_FK',
            'EMP_SCHED_EMP_FK', 'EMP_SCHED_DOC_SCHED_FK',
            'DOCTOR_VACATION_EMPLOYEE_FK',
            'APPOINTMENT_PATIENT_FK', 'APPT_EMP_SCHED_FK',
            'APPT_HIST_APPT_FK',
            'ADMISSION_PATIENT_FK', 'ADMISSION_BED_FK', 'ADMISSION_EMPLOYEE_FK',
            'PRESCRIPTION_APPOINTMENT_FK', 'PRESCRIPTION_EMPLOYEE_FK', 'PRESCRIPTION_PATIENT_FK',
            'BILLING_PATIENT_FK', 'BILLING_INSURANCE_FK',
            'BILLING_ADMISSION_FK', 'BILLING_APPOINTMENT_FK',
            'PAYMENT_BILLING_FK'
        )
    ) LOOP
        EXECUTE IMMEDIATE 'ALTER TABLE ' || c.table_name
                       || ' DROP CONSTRAINT ' || c.constraint_name;
        DBMS_OUTPUT.PUT_LINE('Dropped: ' || c.constraint_name);
    END LOOP;
END;
/
 
 
-- =============================================================
-- SECTION 2: UNIQUE CONSTRAINTS  (5 total)
-- =============================================================
 
-- Prevent duplicate patient emails
ALTER TABLE PATIENT   ADD CONSTRAINT PATIENT_EMAIL_UN        UNIQUE (email);
 
-- Prevent duplicate employee emails and license numbers
ALTER TABLE EMPLOYEE  ADD CONSTRAINT EMPLOYEE_EMAIL_UN       UNIQUE (email);
ALTER TABLE EMPLOYEE  ADD CONSTRAINT EMPLOYEE_LICENSE_NO_UN  UNIQUE (license_no);
 
-- Prevent duplicate insurance policy numbers
ALTER TABLE INSURANCE ADD CONSTRAINT INSURANCE_POLICY_NUMBER_UN UNIQUE (policy_number);
 
-- Prevent duplicate room numbers
ALTER TABLE ROOM      ADD CONSTRAINT ROOM_ROOM_NUMBER_UN     UNIQUE (room_number);
 
 
-- =============================================================
-- SECTION 3: CHECK CONSTRAINTS  (13 total)
-- Values use UPPER CASE to match DML data standards
-- =============================================================
 
-- ADMISSION: valid status values
ALTER TABLE ADMISSION ADD CONSTRAINT ADM_STATUS_CHK
    CHECK (status IN ('ACTIVE', 'DISCHARGED', 'TRANSFERRED'));
 
-- APPOINTMENT: valid status values (added RESCHEDULED — used by triggers)
ALTER TABLE APPOINTMENT ADD CONSTRAINT APPT_STATUS_CHK
    CHECK (status IN ('SCHEDULED', 'COMPLETED', 'CANCELLED', 'RESCHEDULED'));
 
-- BED: occupancy flag
ALTER TABLE BED ADD CONSTRAINT BED_OCC_CHK
    CHECK (is_occupied IN ('Y', 'N'));
 
-- BILLING: valid billing status values
ALTER TABLE BILLING ADD CONSTRAINT BILL_STATUS_CHK
    CHECK (status IN ('PENDING', 'PAID', 'PARTIALLY_PAID', 'CANCELLED'));
 
-- DOCTOR_SCHEDULE: end must be after start
ALTER TABLE DOCTOR_SCHEDULE ADD CONSTRAINT SCHED_TIME_CHK
    CHECK (end_time > start_time);
 
-- DOCTOR_VACATION: end date must be >= start date
ALTER TABLE DOCTOR_VACATION ADD CONSTRAINT VAC_DATE_CHK
    CHECK (end_date >= start_date);
 
-- EMPLOYEE: valid roles (matches merged Doctor+Staff design)
ALTER TABLE EMPLOYEE ADD CONSTRAINT EMP_ROLE_CHK
    CHECK (role IN ('DOCTOR', 'NURSE', 'TECHNICIAN', 'ADMIN'));
 
-- INSURANCE: coverage must be 0–100 percent
ALTER TABLE INSURANCE ADD CONSTRAINT INS_COVERAGE_CHK
    CHECK (coverage_pct BETWEEN 0 AND 100);
 
-- PATIENT_INSURANCE: valid_to must be after valid_from
ALTER TABLE PATIENT_INSURANCE ADD CONSTRAINT PI_DATE_CHK
    CHECK (valid_to > valid_from);
 
-- PATIENT_INSURANCE: is_primary flag
ALTER TABLE PATIENT_INSURANCE ADD CONSTRAINT PI_PRIMARY_CHK
    CHECK (is_primary IN ('Y', 'N'));
 
-- PAYMENT: amount must be positive
ALTER TABLE PAYMENT ADD CONSTRAINT PAY_AMT_CHK
    CHECK (amount > 0);
 
-- ROOM: valid room types
ALTER TABLE ROOM ADD CONSTRAINT ROOM_TYPE_CHK
    CHECK (room_type IN ('GENERAL', 'ICU', 'PRIVATE'));
 
-- EMPLOYEE_SCHEDULE: valid availability status
ALTER TABLE EMPLOYEE_SCHEDULE ADD CONSTRAINT EMP_SCHED_STATUS_CHK
    CHECK (status IN ('AVAILABLE', 'UNAVAILABLE', 'ON_LEAVE'));
 
 
-- =============================================================
-- SECTION 4: FOREIGN KEY CONSTRAINTS  (22 total)
-- =============================================================
 
-- PATIENT self-referencing FK (minors → guardian adult patient)
ALTER TABLE PATIENT ADD CONSTRAINT PATIENT_GUARDIAN_FK
    FOREIGN KEY (guardian_id) REFERENCES PATIENT (patient_id);
 
-- EMPLOYEE → DEPARTMENT
ALTER TABLE EMPLOYEE ADD CONSTRAINT EMPLOYEE_DEPARTMENT_FK
    FOREIGN KEY (DEPARTMENT_department_id) REFERENCES DEPARTMENT (department_id);
 
-- BED → ROOM
ALTER TABLE BED ADD CONSTRAINT BED_ROOM_FK
    FOREIGN KEY (ROOM_room_id) REFERENCES ROOM (room_id);
 
-- PATIENT_INSURANCE → PATIENT, INSURANCE  (bridge table)
ALTER TABLE PATIENT_INSURANCE ADD CONSTRAINT PI_PATIENT_FK
    FOREIGN KEY (PATIENT_patient_id) REFERENCES PATIENT (patient_id);
ALTER TABLE PATIENT_INSURANCE ADD CONSTRAINT PI_INSURANCE_FK
    FOREIGN KEY (INSURANCE_insurance_id) REFERENCES INSURANCE (insurance_id);
 
-- EMPLOYEE_SCHEDULE → EMPLOYEE, DOCTOR_SCHEDULE  (bridge table)
ALTER TABLE EMPLOYEE_SCHEDULE ADD CONSTRAINT EMP_SCHED_EMP_FK
    FOREIGN KEY (EMPLOYEE_employee_id) REFERENCES EMPLOYEE (employee_id);
ALTER TABLE EMPLOYEE_SCHEDULE ADD CONSTRAINT EMP_SCHED_DOC_SCHED_FK
    FOREIGN KEY (DOCTOR_SCHEDULE_schedule_id) REFERENCES DOCTOR_SCHEDULE (schedule_id);
 
-- DOCTOR_VACATION → EMPLOYEE
ALTER TABLE DOCTOR_VACATION ADD CONSTRAINT DOCTOR_VACATION_EMPLOYEE_FK
    FOREIGN KEY (EMPLOYEE_employee_id) REFERENCES EMPLOYEE (employee_id);
 
-- APPOINTMENT → PATIENT, EMPLOYEE_SCHEDULE
ALTER TABLE APPOINTMENT ADD CONSTRAINT APPOINTMENT_PATIENT_FK
    FOREIGN KEY (PATIENT_patient_id) REFERENCES PATIENT (patient_id);
ALTER TABLE APPOINTMENT ADD CONSTRAINT APPT_EMP_SCHED_FK
    FOREIGN KEY (EMPLOYEE_SCHEDULE_bridge_id) REFERENCES EMPLOYEE_SCHEDULE (bridge_id);
 
-- APPOINTMENT_HISTORY → APPOINTMENT
ALTER TABLE APPOINTMENT_HISTORY ADD CONSTRAINT APPT_HIST_APPT_FK
    FOREIGN KEY (APPOINTMENT_appointment_id) REFERENCES APPOINTMENT (appointment_id);
 
-- ADMISSION → PATIENT, BED, EMPLOYEE
ALTER TABLE ADMISSION ADD CONSTRAINT ADMISSION_PATIENT_FK
    FOREIGN KEY (PATIENT_patient_id) REFERENCES PATIENT (patient_id);
ALTER TABLE ADMISSION ADD CONSTRAINT ADMISSION_BED_FK
    FOREIGN KEY (BED_bed_id) REFERENCES BED (bed_id);
ALTER TABLE ADMISSION ADD CONSTRAINT ADMISSION_EMPLOYEE_FK
    FOREIGN KEY (EMPLOYEE_employee_id) REFERENCES EMPLOYEE (employee_id);
 
-- PRESCRIPTION → APPOINTMENT, EMPLOYEE, PATIENT
ALTER TABLE PRESCRIPTION ADD CONSTRAINT PRESCRIPTION_APPOINTMENT_FK
    FOREIGN KEY (APPOINTMENT_appointment_id) REFERENCES APPOINTMENT (appointment_id);
ALTER TABLE PRESCRIPTION ADD CONSTRAINT PRESCRIPTION_EMPLOYEE_FK
    FOREIGN KEY (EMPLOYEE_employee_id) REFERENCES EMPLOYEE (employee_id);
ALTER TABLE PRESCRIPTION ADD CONSTRAINT PRESCRIPTION_PATIENT_FK
    FOREIGN KEY (PATIENT_patient_id) REFERENCES PATIENT (patient_id);
 
-- BILLING → PATIENT, INSURANCE (nullable), ADMISSION (nullable), APPOINTMENT (nullable)
ALTER TABLE BILLING ADD CONSTRAINT BILLING_PATIENT_FK
    FOREIGN KEY (PATIENT_patient_id) REFERENCES PATIENT (patient_id);
ALTER TABLE BILLING ADD CONSTRAINT BILLING_INSURANCE_FK
    FOREIGN KEY (INSURANCE_insurance_id) REFERENCES INSURANCE (insurance_id);
ALTER TABLE BILLING ADD CONSTRAINT BILLING_ADMISSION_FK
    FOREIGN KEY (ADMISSION_admission_id) REFERENCES ADMISSION (admission_id);
ALTER TABLE BILLING ADD CONSTRAINT BILLING_APPOINTMENT_FK
    FOREIGN KEY (APPOINTMENT_appointment_id) REFERENCES APPOINTMENT (appointment_id);
 
-- PAYMENT → BILLING
ALTER TABLE PAYMENT ADD CONSTRAINT PAYMENT_BILLING_FK
    FOREIGN KEY (BILLING_bill_id) REFERENCES BILLING (bill_id);
 
 
-- =============================================================
-- SECTION 5: VERIFY — list all constraints added
-- =============================================================
 
SELECT
    table_name,
    constraint_name,
    constraint_type,   -- P=PK, U=UNIQUE, C=CHECK, R=FK
    status
FROM   user_constraints
WHERE  constraint_type IN ('U', 'C', 'R')
  AND  table_name IN (
    'DEPARTMENT','ROOM','PATIENT','DOCTOR_SCHEDULE','INSURANCE',
    'EMPLOYEE','BED','PATIENT_INSURANCE','EMPLOYEE_SCHEDULE',
    'DOCTOR_VACATION','APPOINTMENT','ADMISSION','APPOINTMENT_HISTORY',
    'PRESCRIPTION','BILLING','PAYMENT'
  )
ORDER  BY table_name, constraint_type, constraint_name;
 
BEGIN
    DBMS_OUTPUT.PUT_LINE('DDL/02_constraints.sql completed — 5 UNIQUE | 13 CHECK | 22 FK.');
END;
/