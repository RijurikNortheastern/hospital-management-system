-- Security: Roles and Grants 
-- =============================================
-- Security: User Creation and Role Provisioning
-- Run as: ADMIN (OCI Autonomous Database)
-- =============================================

-- Application Admin (full access)
CREATE USER hms_admin IDENTIFIED BY "HospitalMgmt2026#";
GRANT DWROLE TO hms_admin;
GRANT UNLIMITED TABLESPACE TO hms_admin;
GRANT CREATE SESSION TO hms_admin;
GRANT CREATE TABLE TO hms_admin;
GRANT CREATE VIEW TO hms_admin;
GRANT CREATE PROCEDURE TO hms_admin;
GRANT CREATE SEQUENCE TO hms_admin;
GRANT CREATE TRIGGER TO hms_admin;

-- Operator (limited access)
CREATE USER hms_operator IDENTIFIED BY "HospitalOper2026#";
GRANT CREATE SESSION TO hms_operator;

-- =============================================
-- AFTER all tables are created (as ADMIN):
-- =============================================

-- Operator: SELECT on all tables
GRANT SELECT ON hms_admin.PATIENT TO hms_operator;
GRANT SELECT ON hms_admin.EMPLOYEE TO hms_operator;
GRANT SELECT ON hms_admin.DEPARTMENT TO hms_operator;
GRANT SELECT ON hms_admin.APPOINTMENT TO hms_operator;
GRANT SELECT ON hms_admin.APPOINTMENT_HISTORY TO hms_operator;
GRANT SELECT ON hms_admin.ADMISSION TO hms_operator;
GRANT SELECT ON hms_admin.BED TO hms_operator;
GRANT SELECT ON hms_admin.ROOM TO hms_operator;
GRANT SELECT ON hms_admin.BILLING TO hms_operator;
GRANT SELECT ON hms_admin.PAYMENT TO hms_operator;
GRANT SELECT ON hms_admin.INSURANCE TO hms_operator;
GRANT SELECT ON hms_admin.PATIENT_INSURANCE TO hms_operator;
GRANT SELECT ON hms_admin.PRESCRIPTION TO hms_operator;
GRANT SELECT ON hms_admin.DOCTOR_SCHEDULE TO hms_operator;
GRANT SELECT ON hms_admin.EMPLOYEE_SCHEDULE TO hms_operator;
GRANT SELECT ON hms_admin.DOCTOR_VACATION TO hms_operator;

-- Operator: INSERT/UPDATE on operational tables
GRANT INSERT, UPDATE ON hms_admin.APPOINTMENT TO hms_operator;
GRANT INSERT, UPDATE ON hms_admin.PATIENT TO hms_operator;
GRANT INSERT, UPDATE ON hms_admin.ADMISSION TO hms_operator;
GRANT INSERT, UPDATE ON hms_admin.BILLING TO hms_operator;
GRANT INSERT, UPDATE ON hms_admin.PAYMENT TO hms_operator;