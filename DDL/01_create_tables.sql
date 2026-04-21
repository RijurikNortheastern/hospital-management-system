-- =============================================================
-- FILE   : DDL/01_create_tables.sql
-- PROJECT: Hospital Management System (DMDD 6210 - Table Turners)
-- RUN AS : hms_admin
-- PURPOSE: Drop (if exists) and recreate all 16 tables with PKs
-- SAFE   : Idempotent — CASCADE CONSTRAINTS handles FK order
-- ORDER  : Run before DDL/02 (constraints) and DDL/03 (sequences)
-- =============================================================
 
 
-- =============================================================
-- SECTION 1: DROP ALL TABLES (reverse FK dependency order)
-- CASCADE CONSTRAINTS removes FK references automatically
-- EXCEPTION WHEN OTHERS THEN NULL = skip if table does not exist
-- =============================================================
 
BEGIN EXECUTE IMMEDIATE 'DROP TABLE PAYMENT              CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE BILLING              CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE PRESCRIPTION         CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE APPOINTMENT_HISTORY  CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE ADMISSION            CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE APPOINTMENT          CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE DOCTOR_VACATION      CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE EMPLOYEE_SCHEDULE    CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE PATIENT_INSURANCE    CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE BED                  CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE EMPLOYEE             CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE INSURANCE            CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE DOCTOR_SCHEDULE      CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE PATIENT              CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE ROOM                 CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE DEPARTMENT           CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
 
BEGIN
    DBMS_OUTPUT.PUT_LINE('All existing tables dropped successfully.');
END;
/
 
 
-- =============================================================
-- SECTION 2: CREATE TABLES
-- Order: independent tables first, then dependent tables
-- =============================================================
 
 
-- -------------------------------------------------------------
-- GROUP A: Independent tables (no foreign keys)
-- -------------------------------------------------------------
 
-- 1. DEPARTMENT
CREATE TABLE DEPARTMENT (
    department_id   NUMBER        NOT NULL,
    department_name VARCHAR2(100) NOT NULL,
    location        VARCHAR2(100),
    phone           VARCHAR2(15)
);
ALTER TABLE DEPARTMENT ADD CONSTRAINT DEPARTMENT_PK PRIMARY KEY (department_id);
 
-- 2. ROOM
CREATE TABLE ROOM (
    room_id     NUMBER       NOT NULL,
    room_number VARCHAR2(10) NOT NULL,
    room_type   VARCHAR2(20) NOT NULL,   -- 'General', 'ICU', 'Private', 'Semi-Private'
    floor_num   NUMBER,
    status      VARCHAR2(20) NOT NULL    -- 'Available', 'Occupied', 'Maintenance'
);
ALTER TABLE ROOM ADD CONSTRAINT ROOM_PK PRIMARY KEY (room_id);
 
-- 3. PATIENT
--    guardian_id is a self-referencing FK added in DDL/02
--    Supports 180 adults + 20 minors with guardians
CREATE TABLE PATIENT (
    patient_id        NUMBER        NOT NULL,
    first_name        VARCHAR2(100) NOT NULL,
    last_name         VARCHAR2(100) NOT NULL,
    dob               DATE          NOT NULL,
    gender            VARCHAR2(10)  NOT NULL,
    phone             VARCHAR2(15)  NOT NULL,
    email             VARCHAR2(100) NOT NULL,
    address           VARCHAR2(255),
    blood_group       VARCHAR2(5),
    emergency_contact VARCHAR2(15),
    registration_date DATE          DEFAULT SYSDATE,
    guardian_id       NUMBER                         -- self-ref FK → PATIENT(patient_id)
);
ALTER TABLE PATIENT ADD CONSTRAINT PATIENT_PK PRIMARY KEY (patient_id);
 
-- 4. DOCTOR_SCHEDULE
--    Stores reusable weekly time slots; linked via EMPLOYEE_SCHEDULE bridge
CREATE TABLE DOCTOR_SCHEDULE (
    schedule_id NUMBER       NOT NULL,
    day_of_week VARCHAR2(10) NOT NULL,  -- 'Monday' .. 'Sunday'
    start_time  DATE         NOT NULL,  -- date portion ignored; time used only
    end_time    DATE         NOT NULL
);
ALTER TABLE DOCTOR_SCHEDULE ADD CONSTRAINT DOCTOR_SCHEDULE_PK PRIMARY KEY (schedule_id);
 
-- 5. INSURANCE
CREATE TABLE INSURANCE (
    insurance_id  NUMBER        NOT NULL,
    provider_name VARCHAR2(100) NOT NULL,
    policy_number VARCHAR2(50)  NOT NULL,
    coverage_pct  NUMBER        NOT NULL  -- 0-100; e.g. 80 = 80% covered
);
ALTER TABLE INSURANCE ADD CONSTRAINT INSURANCE_PK PRIMARY KEY (insurance_id);
 
 
-- -------------------------------------------------------------
-- GROUP B: Tables with FKs to Group A
-- (Foreign keys themselves are added in DDL/02)
-- -------------------------------------------------------------
 
-- 6. EMPLOYEE  — merged Doctor + Staff; role column distinguishes them
CREATE TABLE EMPLOYEE (
    employee_id              NUMBER        NOT NULL,
    first_name               VARCHAR2(100) NOT NULL,
    last_name                VARCHAR2(100) NOT NULL,
    role                     VARCHAR2(50)  NOT NULL,  -- 'Doctor','Nurse','Admin','Staff'
    phone                    VARCHAR2(15),
    email                    VARCHAR2(100),
    hire_date                DATE          NOT NULL,
    salary                   NUMBER,
    specialization           VARCHAR2(100),           -- doctors only
    license_no               VARCHAR2(50),            -- doctors only
    DEPARTMENT_department_id NUMBER        NOT NULL   -- FK → DEPARTMENT
);
ALTER TABLE EMPLOYEE ADD CONSTRAINT EMPLOYEE_PK PRIMARY KEY (employee_id);
 
-- 7. BED  (FK → ROOM)
CREATE TABLE BED (
    bed_id       NUMBER       NOT NULL,
    bed_number   VARCHAR2(10) NOT NULL,
    is_occupied  CHAR(1)      NOT NULL,  -- 'Y' or 'N'
    ROOM_room_id NUMBER       NOT NULL   -- FK → ROOM
);
ALTER TABLE BED ADD CONSTRAINT BED_PK PRIMARY KEY (bed_id);
 
-- 8. PATIENT_INSURANCE  — Bridge: PATIENT M:N INSURANCE
CREATE TABLE PATIENT_INSURANCE (
    patient_ins_id         NUMBER  NOT NULL,
    valid_from             DATE    NOT NULL,
    valid_to               DATE    NOT NULL,
    is_primary             CHAR(1) NOT NULL,  -- 'Y' = primary policy
    PATIENT_patient_id     NUMBER  NOT NULL,  -- FK → PATIENT
    INSURANCE_insurance_id NUMBER  NOT NULL   -- FK → INSURANCE
);
ALTER TABLE PATIENT_INSURANCE ADD CONSTRAINT PATIENT_INSURANCE_PK PRIMARY KEY (patient_ins_id);
 
-- 9. EMPLOYEE_SCHEDULE  — Bridge: EMPLOYEE M:N DOCTOR_SCHEDULE
CREATE TABLE EMPLOYEE_SCHEDULE (
    bridge_id                   NUMBER       NOT NULL,
    availability_date           DATE         NOT NULL,
    status                      VARCHAR2(20) NOT NULL,  -- 'Available','On Leave','Booked'
    EMPLOYEE_employee_id        NUMBER       NOT NULL,  -- FK → EMPLOYEE
    DOCTOR_SCHEDULE_schedule_id NUMBER       NOT NULL   -- FK → DOCTOR_SCHEDULE
);
ALTER TABLE EMPLOYEE_SCHEDULE ADD CONSTRAINT EMPLOYEE_SCHEDULE_PK PRIMARY KEY (bridge_id);
 
-- 10. DOCTOR_VACATION  (FK → EMPLOYEE)
CREATE TABLE DOCTOR_VACATION (
    vacation_id          NUMBER       NOT NULL,
    start_date           DATE         NOT NULL,
    end_date             DATE         NOT NULL,
    reason               VARCHAR2(200),
    status               VARCHAR2(20) NOT NULL,  -- 'Approved','Pending','Rejected'
    EMPLOYEE_employee_id NUMBER       NOT NULL   -- FK → EMPLOYEE
);
ALTER TABLE DOCTOR_VACATION ADD CONSTRAINT DOCTOR_VACATION_PK PRIMARY KEY (vacation_id);
 
 
-- -------------------------------------------------------------
-- GROUP C: Transactional / child tables
-- -------------------------------------------------------------
 
-- 11. APPOINTMENT  (FK → PATIENT, EMPLOYEE_SCHEDULE)
CREATE TABLE APPOINTMENT (
    appointment_id              NUMBER       NOT NULL,
    appointment_date            DATE         NOT NULL,
    appointment_time            DATE         NOT NULL,  -- time portion used only
    status                      VARCHAR2(20) NOT NULL,  -- 'Scheduled','Completed','Cancelled'
    reason                      VARCHAR2(200),
    created_at                  DATE         DEFAULT SYSDATE,
    PATIENT_patient_id          NUMBER       NOT NULL,  -- FK → PATIENT
    EMPLOYEE_SCHEDULE_bridge_id NUMBER       NOT NULL   -- FK → EMPLOYEE_SCHEDULE
);
ALTER TABLE APPOINTMENT ADD CONSTRAINT APPOINTMENT_PK PRIMARY KEY (appointment_id);
 
-- 12. ADMISSION  (FK → BED, PATIENT, EMPLOYEE)
CREATE TABLE ADMISSION (
    admission_id         NUMBER       NOT NULL,
    admit_date           DATE         NOT NULL,
    discharge_date       DATE,                         -- NULL = currently admitted
    admit_reason         VARCHAR2(200),
    status               VARCHAR2(20) NOT NULL,        -- 'Active','Discharged'
    BED_bed_id           NUMBER       NOT NULL,        -- FK → BED
    PATIENT_patient_id   NUMBER       NOT NULL,        -- FK → PATIENT
    EMPLOYEE_employee_id NUMBER       NOT NULL         -- FK → EMPLOYEE (attending doctor)
);
ALTER TABLE ADMISSION ADD CONSTRAINT ADMISSION_PK PRIMARY KEY (admission_id);
 
-- 13. APPOINTMENT_HISTORY  (FK → APPOINTMENT)  — audit trail
CREATE TABLE APPOINTMENT_HISTORY (
    history_id                 NUMBER       NOT NULL,
    action                     VARCHAR2(20) NOT NULL,  -- 'Created','Rescheduled','Cancelled'
    action_date                DATE         DEFAULT SYSDATE,
    old_date                   DATE,
    new_date                   DATE,
    notes                      VARCHAR2(500),
    APPOINTMENT_appointment_id NUMBER       NOT NULL   -- FK → APPOINTMENT
);
ALTER TABLE APPOINTMENT_HISTORY ADD CONSTRAINT APPOINTMENT_HISTORY_PK PRIMARY KEY (history_id);
 
-- 14. PRESCRIPTION  (FK → APPOINTMENT, EMPLOYEE, PATIENT)
CREATE TABLE PRESCRIPTION (
    prescription_id            NUMBER        NOT NULL,
    medication_name            VARCHAR2(100) NOT NULL,
    dosage                     VARCHAR2(50),
    frequency                  VARCHAR2(50),
    start_date                 DATE,
    end_date                   DATE,
    notes                      VARCHAR2(500),
    APPOINTMENT_appointment_id NUMBER        NOT NULL,  -- FK → APPOINTMENT
    EMPLOYEE_employee_id       NUMBER        NOT NULL,  -- FK → EMPLOYEE (prescribing doctor)
    PATIENT_patient_id         NUMBER        NOT NULL   -- FK → PATIENT
);
ALTER TABLE PRESCRIPTION ADD CONSTRAINT PRESCRIPTION_PK PRIMARY KEY (prescription_id);
 
-- 15. BILLING  (FK → PATIENT, INSURANCE[nullable], ADMISSION[nullable], APPOINTMENT[nullable])
CREATE TABLE BILLING (
    bill_id                    NUMBER       NOT NULL,
    bill_date                  DATE         NOT NULL,
    total_amount               NUMBER       NOT NULL,
    discount                   NUMBER       DEFAULT 0,
    net_amount                 NUMBER,
    status                     VARCHAR2(20) NOT NULL,  -- 'Pending','Paid','Cancelled'
    PATIENT_patient_id         NUMBER       NOT NULL,  -- FK → PATIENT
    INSURANCE_insurance_id     NUMBER,                 -- FK → INSURANCE  (nullable)
    ADMISSION_admission_id     NUMBER,                 -- FK → ADMISSION  (nullable)
    APPOINTMENT_appointment_id NUMBER                  -- FK → APPOINTMENT (nullable)
);
ALTER TABLE BILLING ADD CONSTRAINT BILLING_PK PRIMARY KEY (bill_id);
 
-- 16. PAYMENT  (FK → BILLING)
CREATE TABLE PAYMENT (
    payment_id      NUMBER       NOT NULL,
    payment_date    DATE         NOT NULL,
    amount          NUMBER       NOT NULL,
    payment_method  VARCHAR2(30),                     -- 'Cash','Card','Insurance','Online'
    transaction_ref VARCHAR2(50),
    BILLING_bill_id NUMBER       NOT NULL             -- FK → BILLING
);
ALTER TABLE PAYMENT ADD CONSTRAINT PAYMENT_PK PRIMARY KEY (payment_id);
 
 
-- =============================================================
-- SECTION 3: VERIFY — confirm all 16 tables were created
-- =============================================================
 
SELECT table_name
FROM   user_tables
WHERE  table_name IN (
    'DEPARTMENT', 'ROOM', 'PATIENT', 'DOCTOR_SCHEDULE', 'INSURANCE',
    'EMPLOYEE', 'BED', 'PATIENT_INSURANCE', 'EMPLOYEE_SCHEDULE',
    'DOCTOR_VACATION', 'APPOINTMENT', 'ADMISSION', 'APPOINTMENT_HISTORY',
    'PRESCRIPTION', 'BILLING', 'PAYMENT'
)
ORDER  BY table_name;
 
BEGIN
    DBMS_OUTPUT.PUT_LINE('DDL/01_create_tables.sql completed — 16 tables created.');
END;
/