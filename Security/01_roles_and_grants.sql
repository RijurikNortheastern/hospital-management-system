-- =============================================================
-- FILE   : Security/01_roles_and_grants.sql
-- PROJECT: Hospital Management System (DMDD 6210 - Table Turners)
-- RUN AS : ADMIN (OCI Autonomous Database)
-- PURPOSE: Create users, assign roles and grants
-- SAFE   : Idempotent — can be re-run multiple times safely
-- =============================================================
 
 
-- =============================================================
-- SECTION 1: DROP EXISTING USERS (for clean re-run)
-- Cascading drop removes all owned objects automatically
-- =============================================================
 
BEGIN
    FOR u IN (SELECT username FROM dba_users WHERE username IN ('HMS_ADMIN', 'HMS_OPERATOR')) LOOP
        EXECUTE IMMEDIATE 'DROP USER ' || u.username || ' CASCADE';
        DBMS_OUTPUT.PUT_LINE('Dropped user: ' || u.username);
    END LOOP;
END;
/
 
 
-- =============================================================
-- SECTION 2: CREATE APPLICATION ADMIN USER
-- Full DDL + DML access for schema owner
-- =============================================================
 
CREATE USER hms_admin IDENTIFIED BY "HospitalMgmt2026#";
 
GRANT DWROLE                TO hms_admin;
GRANT UNLIMITED TABLESPACE  TO hms_admin;
GRANT CREATE SESSION        TO hms_admin;
GRANT CREATE TABLE          TO hms_admin;
GRANT CREATE VIEW           TO hms_admin;
GRANT CREATE PROCEDURE      TO hms_admin;
GRANT CREATE SEQUENCE       TO hms_admin;
GRANT CREATE TRIGGER        TO hms_admin;
 
DBMS_OUTPUT.PUT_LINE('hms_admin created and granted.');
 
 
-- =============================================================
-- SECTION 3: CREATE OPERATOR USER
-- Read-only + limited operational DML
-- =============================================================
 
CREATE USER hms_operator IDENTIFIED BY "HospitalOper2026#";
 
GRANT CREATE SESSION TO hms_operator;
 
DBMS_OUTPUT.PUT_LINE('hms_operator created and granted.');
 
 
-- =============================================================
-- SECTION 4: OBJECT-LEVEL GRANTS TO OPERATOR
-- Run AFTER all tables are created by hms_admin
-- NOTE: All 16 tables covered (including both bridge tables)
-- =============================================================
 
-- READ access (SELECT) on all 16 tables
GRANT SELECT ON hms_admin.PATIENT             TO hms_operator;
GRANT SELECT ON hms_admin.EMPLOYEE            TO hms_operator;
GRANT SELECT ON hms_admin.DEPARTMENT          TO hms_operator;
GRANT SELECT ON hms_admin.APPOINTMENT         TO hms_operator;
GRANT SELECT ON hms_admin.APPOINTMENT_HISTORY TO hms_operator;
GRANT SELECT ON hms_admin.ADMISSION           TO hms_operator;
GRANT SELECT ON hms_admin.BED                 TO hms_operator;
GRANT SELECT ON hms_admin.ROOM                TO hms_operator;
GRANT SELECT ON hms_admin.BILLING             TO hms_operator;
GRANT SELECT ON hms_admin.PAYMENT             TO hms_operator;
GRANT SELECT ON hms_admin.INSURANCE           TO hms_operator;
GRANT SELECT ON hms_admin.PATIENT_INSURANCE   TO hms_operator;
GRANT SELECT ON hms_admin.PRESCRIPTION        TO hms_operator;
GRANT SELECT ON hms_admin.DOCTOR_SCHEDULE     TO hms_operator;
GRANT SELECT ON hms_admin.EMPLOYEE_SCHEDULE   TO hms_operator;
GRANT SELECT ON hms_admin.DOCTOR_VACATION     TO hms_operator;
 
-- WRITE access (INSERT/UPDATE) on operational tables
GRANT INSERT, UPDATE ON hms_admin.APPOINTMENT TO hms_operator;
GRANT INSERT, UPDATE ON hms_admin.PATIENT     TO hms_operator;
GRANT INSERT, UPDATE ON hms_admin.ADMISSION   TO hms_operator;
GRANT INSERT, UPDATE ON hms_admin.BILLING     TO hms_operator;
GRANT INSERT, UPDATE ON hms_admin.PAYMENT     TO hms_operator;
 
DBMS_OUTPUT.PUT_LINE('All object-level grants applied to hms_operator.');
 
 
-- =============================================================
-- SECTION 5: VERIFY (optional sanity check)
-- =============================================================
 
SELECT username, account_status, created
FROM   dba_users
WHERE  username IN ('HMS_ADMIN', 'HMS_OPERATOR')
ORDER  BY username;
 
SELECT owner, table_name, privilege
FROM   dba_tab_privs
WHERE  grantee = 'HMS_OPERATOR'
ORDER  BY table_name, privilege;