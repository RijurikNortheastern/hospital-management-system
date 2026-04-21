-- =============================================================
-- FILE   : Security/02_operator_grants.sql
-- PROJECT: Hospital Management System (DMDD 6210 - Table Turners)
-- RUN AS : ADMIN (OCI Autonomous Database)
-- PURPOSE: Grant object-level privileges to hms_operator
-- DEPENDS: Security/01_roles_and_grants.sql must run first
--          DDL scripts (01, 02, 03) must run first so tables exist
-- SAFE   : Idempotent — re-running a GRANT that already exists
--          is a no-op in Oracle (no error, no duplicate)
-- =============================================================
 
 
-- =============================================================
-- SECTION 1: VERIFY PREREQS BEFORE GRANTING
-- Warn if hms_operator user does not exist yet
-- =============================================================
 
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM   dba_users
    WHERE  username = 'HMS_OPERATOR';
 
    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20001,
            'ERROR: hms_operator does not exist. Run Security/01_roles_and_grants.sql first.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('hms_operator found — proceeding with grants...');
    END IF;
END;
/
 
 
-- =============================================================
-- SECTION 2: SELECT GRANTS on all 16 tables
-- Covers all base tables + both bridge tables
-- =============================================================
 
-- Core tables
GRANT SELECT ON hms_admin.PATIENT             TO hms_operator;
GRANT SELECT ON hms_admin.EMPLOYEE            TO hms_operator;
GRANT SELECT ON hms_admin.DEPARTMENT          TO hms_operator;
 
-- Appointment module (selected module for Part 2)
GRANT SELECT ON hms_admin.APPOINTMENT         TO hms_operator;
GRANT SELECT ON hms_admin.APPOINTMENT_HISTORY TO hms_operator;
 
-- Admission & Bed management
GRANT SELECT ON hms_admin.ADMISSION           TO hms_operator;
GRANT SELECT ON hms_admin.BED                 TO hms_operator;
GRANT SELECT ON hms_admin.ROOM                TO hms_operator;
 
-- Billing & Payments
GRANT SELECT ON hms_admin.BILLING             TO hms_operator;
GRANT SELECT ON hms_admin.PAYMENT             TO hms_operator;
 
-- Insurance (bridge table: PATIENT_INSURANCE)
GRANT SELECT ON hms_admin.INSURANCE           TO hms_operator;
GRANT SELECT ON hms_admin.PATIENT_INSURANCE   TO hms_operator;
 
-- Clinical
GRANT SELECT ON hms_admin.PRESCRIPTION        TO hms_operator;
 
-- Scheduling (bridge table: EMPLOYEE_SCHEDULE)
GRANT SELECT ON hms_admin.DOCTOR_SCHEDULE     TO hms_operator;
GRANT SELECT ON hms_admin.EMPLOYEE_SCHEDULE   TO hms_operator;
GRANT SELECT ON hms_admin.DOCTOR_VACATION     TO hms_operator;
 
 
-- =============================================================
-- SECTION 3: INSERT/UPDATE GRANTS on operational tables only
-- =============================================================
 
GRANT INSERT, UPDATE ON hms_admin.APPOINTMENT TO hms_operator;
GRANT INSERT, UPDATE ON hms_admin.PATIENT     TO hms_operator;
GRANT INSERT, UPDATE ON hms_admin.ADMISSION   TO hms_operator;
GRANT INSERT, UPDATE ON hms_admin.BILLING     TO hms_operator;
GRANT INSERT, UPDATE ON hms_admin.PAYMENT     TO hms_operator;
 
 
-- =============================================================
-- SECTION 4: VERIFY — confirm all grants applied
-- =============================================================
 
SELECT
    table_name,
    privilege,
    grantable
FROM   dba_tab_privs
WHERE  grantee  = 'HMS_OPERATOR'
  AND  owner    = 'HMS_ADMIN'
ORDER  BY table_name, privilege;
 
BEGIN
    DBMS_OUTPUT.PUT_LINE('02_operator_grants.sql completed successfully.');
END;
/