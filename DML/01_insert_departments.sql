-- =============================================================
-- FILE   : DML/01_insert_departments.sql
-- PROJECT: Hospital Management System (DMDD 6210 - Table Turners)
-- RUN AS : hms_admin
-- PURPOSE: Seed 5 departments
-- DEPENDS: DDL/01, DDL/02, DDL/03 must run first
-- SAFE   : Idempotent — deletes all department rows before insert
-- =============================================================
 
 
-- =============================================================
-- SECTION 1: CLEAN EXISTING DATA
-- Must delete in child-first order to respect FK constraints
-- DEPARTMENT is parent to EMPLOYEE — truncate employees first
-- NOTE: Full cascade cleanup is handled in DML/09_cleanup.sql
--       Here we only clean DEPARTMENT rows safely
-- =============================================================
 
BEGIN
    -- Disable FK temporarily not needed — just delete child rows first
    -- If re-running only this file, employees referencing departments
    -- must not exist yet (run full suite from DML/01 in order)
    DELETE FROM DEPARTMENT;
    DBMS_OUTPUT.PUT_LINE('DEPARTMENT table cleared.');
END;
/
 
 
-- =============================================================
-- SECTION 2: INSERT 5 DEPARTMENTS
-- =============================================================
 
INSERT INTO DEPARTMENT VALUES (department_seq.NEXTVAL, 'Cardiology',       'Building A, Floor 2', '555-0001');
INSERT INTO DEPARTMENT VALUES (department_seq.NEXTVAL, 'Neurology',         'Building A, Floor 3', '555-0002');
INSERT INTO DEPARTMENT VALUES (department_seq.NEXTVAL, 'Orthopedics',       'Building B, Floor 1', '555-0003');
INSERT INTO DEPARTMENT VALUES (department_seq.NEXTVAL, 'Pediatrics',        'Building B, Floor 2', '555-0004');
INSERT INTO DEPARTMENT VALUES (department_seq.NEXTVAL, 'General Medicine',  'Building C, Floor 1', '555-0005');
 
COMMIT;
 
 
-- =============================================================
-- SECTION 3: VERIFY
-- =============================================================
 
SELECT
    department_id,
    department_name,
    location,
    phone
FROM   DEPARTMENT
ORDER  BY department_id;
 
BEGIN
    DBMS_OUTPUT.PUT_LINE('DML/01 completed — 5 departments inserted.');
END;
/