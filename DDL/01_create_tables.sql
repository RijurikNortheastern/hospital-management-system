-- =============================================
-- CREATE TABLES + PRIMARY KEYS
-- Run as: hms_admin
-- =============================================

-- 1. Independent tables (no FKs to other tables)
CREATE TABLE DEPARTMENT (
  department_id   NUMBER        NOT NULL,
  department_name VARCHAR2(100) NOT NULL,
  location        VARCHAR2(100),
  phone           VARCHAR2(15)
);
ALTER TABLE DEPARTMENT ADD CONSTRAINT DEPARTMENT_PK PRIMARY KEY (department_id);

CREATE TABLE ROOM (
  room_id     NUMBER       NOT NULL,
  room_number VARCHAR2(10) NOT NULL,
  room_type   VARCHAR2(20) NOT NULL,
  floor_num   NUMBER,
  status      VARCHAR2(20) NOT NULL
);
ALTER TABLE ROOM ADD CONSTRAINT ROOM_PK PRIMARY KEY (room_id);

CREATE TABLE PATIENT (
  patient_id        NUMBER         NOT NULL,
  first_name        VARCHAR2(100)  NOT NULL,
  last_name         VARCHAR2(100)  NOT NULL,
  dob               DATE           NOT NULL,
  gender            VARCHAR2(10)   NOT NULL,
  phone             VARCHAR2(15)   NOT NULL,
  email             VARCHAR2(100)  NOT NULL,
  address           VARCHAR2(255),
  blood_group       VARCHAR2(5),
  emergency_contact VARCHAR2(15),
  registration_date DATE,
  guardian_id       NUMBER
);
ALTER TABLE PATIENT ADD CONSTRAINT PATIENT_PK PRIMARY KEY (patient_id);

CREATE TABLE DOCTOR_SCHEDULE (
  schedule_id NUMBER       NOT NULL,
  day_of_week VARCHAR2(10) NOT NULL,
  start_time  DATE         NOT NULL,
  end_time    DATE         NOT NULL
);
ALTER TABLE DOCTOR_SCHEDULE ADD CONSTRAINT DOCTOR_SCHEDULE_PK PRIMARY KEY (schedule_id);

CREATE TABLE INSURANCE (
  insurance_id  NUMBER         NOT NULL,
  provider_name VARCHAR2(100)  NOT NULL,
  policy_number VARCHAR2(50)   NOT NULL,
  coverage_pct  NUMBER         NOT NULL
);
ALTER TABLE INSURANCE ADD CONSTRAINT INSURANCE_PK PRIMARY KEY (insurance_id);

-- 2. Tables with FKs to above
CREATE TABLE EMPLOYEE (
  employee_id              NUMBER         NOT NULL,
  first_name               VARCHAR2(100)  NOT NULL,
  last_name                VARCHAR2(100)  NOT NULL,
  role                     VARCHAR2(50)   NOT NULL,
  phone                    VARCHAR2(15),
  email                    VARCHAR2(100),
  hire_date                DATE           NOT NULL,
  salary                   NUMBER,
  specialization           VARCHAR2(100),
  license_no               VARCHAR2(50),
  DEPARTMENT_department_id NUMBER         NOT NULL
);
ALTER TABLE EMPLOYEE ADD CONSTRAINT EMPLOYEE_PK PRIMARY KEY (employee_id);

CREATE TABLE BED (
  bed_id       NUMBER       NOT NULL,
  bed_number   VARCHAR2(10) NOT NULL,
  is_occupied  CHAR(1)      NOT NULL,
  ROOM_room_id NUMBER       NOT NULL
);
ALTER TABLE BED ADD CONSTRAINT BED_PK PRIMARY KEY (bed_id);

CREATE TABLE PATIENT_INSURANCE (
  patient_ins_id         NUMBER   NOT NULL,
  valid_from             DATE     NOT NULL,
  valid_to               DATE     NOT NULL,
  is_primary             CHAR(1)  NOT NULL,
  PATIENT_patient_id     NUMBER   NOT NULL,
  INSURANCE_insurance_id NUMBER   NOT NULL
);
ALTER TABLE PATIENT_INSURANCE ADD CONSTRAINT PATIENT_INSURANCE_PK PRIMARY KEY (patient_ins_id);

CREATE TABLE EMPLOYEE_SCHEDULE (
  bridge_id                   NUMBER       NOT NULL,
  availability_date           DATE         NOT NULL,
  status                      VARCHAR2(20) NOT NULL,
  EMPLOYEE_employee_id        NUMBER       NOT NULL,
  DOCTOR_SCHEDULE_schedule_id NUMBER       NOT NULL
);
ALTER TABLE EMPLOYEE_SCHEDULE ADD CONSTRAINT EMPLOYEE_SCHEDULE_PK PRIMARY KEY (bridge_id);

CREATE TABLE DOCTOR_VACATION (
  vacation_id          NUMBER        NOT NULL,
  start_date           DATE          NOT NULL,
  end_date             DATE          NOT NULL,
  reason               VARCHAR2(200),
  status               VARCHAR2(20)  NOT NULL,
  EMPLOYEE_employee_id NUMBER        NOT NULL
);
ALTER TABLE DOCTOR_VACATION ADD CONSTRAINT DOCTOR_VACATION_PK PRIMARY KEY (vacation_id);

CREATE TABLE APPOINTMENT (
  appointment_id              NUMBER        NOT NULL,
  appointment_date            DATE          NOT NULL,
  appointment_time            DATE          NOT NULL,
  status                      VARCHAR2(20)  NOT NULL,
  reason                      VARCHAR2(200),
  created_at                  DATE,
  PATIENT_patient_id          NUMBER        NOT NULL,
  EMPLOYEE_SCHEDULE_bridge_id NUMBER        NOT NULL
);
ALTER TABLE APPOINTMENT ADD CONSTRAINT APPOINTMENT_PK PRIMARY KEY (appointment_id);

CREATE TABLE ADMISSION (
  admission_id         NUMBER        NOT NULL,
  admit_date           DATE          NOT NULL,
  discharge_date       DATE,
  admit_reason         VARCHAR2(200),
  status               VARCHAR2(20)  NOT NULL,
  BED_bed_id           NUMBER        NOT NULL,
  PATIENT_patient_id   NUMBER        NOT NULL,
  EMPLOYEE_employee_id NUMBER        NOT NULL
);
ALTER TABLE ADMISSION ADD CONSTRAINT ADMISSION_PK PRIMARY KEY (admission_id);

CREATE TABLE APPOINTMENT_HISTORY (
  history_id                 NUMBER        NOT NULL,
  action                     VARCHAR2(20)  NOT NULL,
  action_date                DATE,
  old_date                   DATE,
  new_date                   DATE,
  notes                      VARCHAR2(500),
  APPOINTMENT_appointment_id NUMBER        NOT NULL
);
ALTER TABLE APPOINTMENT_HISTORY ADD CONSTRAINT APPOINTMENT_HISTORY_PK PRIMARY KEY (history_id);

CREATE TABLE PRESCRIPTION (
  prescription_id            NUMBER         NOT NULL,
  medication_name            VARCHAR2(100)  NOT NULL,
  dosage                     VARCHAR2(50),
  frequency                  VARCHAR2(50),
  start_date                 DATE,
  end_date                   DATE,
  notes                      VARCHAR2(500),
  APPOINTMENT_appointment_id NUMBER         NOT NULL,
  EMPLOYEE_employee_id       NUMBER         NOT NULL,
  PATIENT_patient_id         NUMBER         NOT NULL
);
ALTER TABLE PRESCRIPTION ADD CONSTRAINT PRESCRIPTION_PK PRIMARY KEY (prescription_id);

CREATE TABLE BILLING (
  bill_id                    NUMBER       NOT NULL,
  bill_date                  DATE         NOT NULL,
  total_amount               NUMBER       NOT NULL,
  discount                   NUMBER,
  net_amount                 NUMBER,
  status                     VARCHAR2(20) NOT NULL,
  PATIENT_patient_id         NUMBER       NOT NULL,
  INSURANCE_insurance_id     NUMBER,
  ADMISSION_admission_id     NUMBER,
  APPOINTMENT_appointment_id NUMBER
);
ALTER TABLE BILLING ADD CONSTRAINT BILLING_PK PRIMARY KEY (bill_id);

CREATE TABLE PAYMENT (
  payment_id      NUMBER       NOT NULL,
  payment_date    DATE         NOT NULL,
  amount          NUMBER       NOT NULL,
  payment_method  VARCHAR2(30),
  transaction_ref VARCHAR2(50),
  BILLING_bill_id NUMBER       NOT NULL
);
ALTER TABLE PAYMENT ADD CONSTRAINT PAYMENT_PK PRIMARY KEY (payment_id);