-- =============================================================
-- FILE   : Security/01_roles_and_grants.sql
-- PROJECT: Hospital Management System (DMDD 6210 - Table Turners)
-- RUN AS : ADMIN (OCI Autonomous Database)
-- PURPOSE: Create users and assign roles only
--          Object-level grants are in 02_operator_grants.sql
--          which must run AFTER DDL creates the tables
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
 
BEGIN
    DBMS_OUTPUT.PUT_LINE('hms_admin created and granted.');
END;
/
 
 
-- =============================================================
-- SECTION 3: CREATE OPERATOR USER
-- Read-only + limited operational DML
-- =============================================================
 
CREATE USER hms_operator IDENTIFIED BY "HospitalOper2026#";
 
GRANT CREATE SESSION TO hms_operator;
 
BEGIN
    DBMS_OUTPUT.PUT_LINE('hms_operator created and granted.');
END;
/
 
 
-- =============================================================
-- SECTION 4: VERIFY
-- =============================================================
 
SELECT username, account_status, created
FROM   dba_users
WHERE  username IN ('HMS_ADMIN', 'HMS_OPERATOR')
ORDER  BY username;