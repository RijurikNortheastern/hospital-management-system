-- =============================================================
-- FILE   : DML/02_insert_employees.sql
-- PROJECT: Hospital Management System (DMDD 6210 - Table Turners)
-- RUN AS : hms_admin
-- PURPOSE: Seed 23 employees — 15 Doctors, 5 Nurses, 3 Admin
-- DEPENDS: DML/01 (departments must exist — IDs 1–5)
-- SAFE   : Idempotent — deletes EMPLOYEE rows before re-inserting
-- NOTE   : DELETE will cascade-fail if EMPLOYEE_SCHEDULE rows exist;
--          always re-run the full DML suite in order 01→09
-- =============================================================
 
 
-- =============================================================
-- SECTION 1: CLEAN EXISTING DATA
-- =============================================================
 
BEGIN
    DELETE FROM EMPLOYEE;
    DBMS_OUTPUT.PUT_LINE('EMPLOYEE table cleared.');
END;
/
 
 
-- =============================================================
-- SECTION 2: INSERT 15 DOCTORS
-- Specializations rotate across all 5 departments
-- hire_date uses MOD(i,10)+1 to avoid 0-year gap (SYSDATE - 0)
-- license_no is unique per DDL/02 UNIQUE constraint
-- =============================================================
 
BEGIN
    FOR i IN 1..15 LOOP
        INSERT INTO EMPLOYEE (
            employee_id,
            first_name,
            last_name,
            role,
            phone,
            email,
            hire_date,
            salary,
            specialization,
            license_no,
            DEPARTMENT_department_id
        ) VALUES (
            employee_seq.NEXTVAL,
            'DrFirst_' || i,
            'DrLast_'  || i,
            'DOCTOR',
            '555-1' || LPAD(i, 3, '0'),
            'doctor' || i || '@hospital.com',
            SYSDATE - (365 * (MOD(i, 10) + 1)),   -- +1 avoids hire_date = SYSDATE
            150000 + (i * 5000),
            CASE MOD(i, 5)
                WHEN 0 THEN 'Cardiologist'
                WHEN 1 THEN 'Neurologist'
                WHEN 2 THEN 'Orthopedic Surgeon'
                WHEN 3 THEN 'Pediatrician'
                ELSE        'General Physician'
            END,
            'LIC-DOC-' || LPAD(i, 5, '0'),        -- prefix avoids collision with future staff
            MOD(i - 1, 5) + 1                      -- distributes evenly across dept IDs 1–5
        );
    END LOOP;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('15 doctors inserted.');
END;
/
 
 
-- =============================================================
-- SECTION 3: INSERT 5 NURSES
-- No specialization or license (non-doctor staff)
-- hire_date staggered so all nurses don't have identical dates
-- =============================================================
 
BEGIN
    FOR i IN 1..5 LOOP
        INSERT INTO EMPLOYEE (
            employee_id,
            first_name,
            last_name,
            role,
            phone,
            email,
            hire_date,
            salary,
            specialization,
            license_no,
            DEPARTMENT_department_id
        ) VALUES (
            employee_seq.NEXTVAL,
            'Nurse_'     || i,
            'NurseLast_' || i,
            'NURSE',
            '555-2' || LPAD(i, 3, '0'),
            'nurse' || i || '@hospital.com',
            SYSDATE - (500 + (i * 30)),            -- staggered hire dates
            60000 + (i * 2000),
            NULL,                                  -- no specialization for nurses
            NULL,                                  -- no license for nurses
            MOD(i - 1, 5) + 1
        );
    END LOOP;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('5 nurses inserted.');
END;
/
 
 
-- =============================================================
-- SECTION 4: INSERT 3 ADMIN STAFF
-- No specialization or license
-- hire_date staggered
-- =============================================================
 
BEGIN
    FOR i IN 1..3 LOOP
        INSERT INTO EMPLOYEE (
            employee_id,
            first_name,
            last_name,
            role,
            phone,
            email,
            hire_date,
            salary,
            specialization,
            license_no,
            DEPARTMENT_department_id
        ) VALUES (
            employee_seq.NEXTVAL,
            'Admin_'     || i,
            'AdminLast_' || i,
            'ADMIN',
            '555-3' || LPAD(i, 3, '0'),
            'admin' || i || '@hospital.com',
            SYSDATE - (300 + (i * 20)),            -- staggered hire dates
            45000 + (i * 1000),
            NULL,                                  -- no specialization for admin
            NULL,                                  -- no license for admin
            MOD(i - 1, 5) + 1
        );
    END LOOP;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('3 admin staff inserted.');
END;
/
 
 
-- =============================================================
-- SECTION 5: VERIFY
-- =============================================================
 
SELECT
    employee_id,
    first_name || ' ' || last_name   AS full_name,
    role,
    specialization,
    license_no,
    DEPARTMENT_department_id          AS dept_id,
    hire_date,
    salary
FROM   EMPLOYEE
ORDER  BY role, employee_id;
 
-- Summary count by role
SELECT role, COUNT(*) AS total
FROM   EMPLOYEE
GROUP  BY role
ORDER  BY role;
 
BEGIN
    DBMS_OUTPUT.PUT_LINE('DML/02 completed — 23 employees inserted (15 doctors, 5 nurses, 3 admin).');
END;
/