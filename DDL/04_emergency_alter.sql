-- ============================================
-- DDL: Emergency Module - ALTER TABLE
-- Hospital Management System - DMDD 6210
-- Idempotent - safe to run multiple times
-- ============================================

-- Add is_emergency to APPOINTMENT (if not exists)
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM user_tab_columns
    WHERE table_name  = 'APPOINTMENT'
    AND   column_name = 'IS_EMERGENCY';
    
    IF v_count = 0 THEN
        EXECUTE IMMEDIATE 'ALTER TABLE APPOINTMENT 
                           ADD (is_emergency CHAR(1) DEFAULT ''N'')';
        DBMS_OUTPUT.PUT_LINE('is_emergency column added');
    ELSE
        DBMS_OUTPUT.PUT_LINE('is_emergency column already exists - skipped');
    END IF;
END;
/

-- Add constraint (if not exists)
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM user_constraints
    WHERE table_name      = 'APPOINTMENT'
    AND   constraint_name = 'APPT_EMERGENCY_CHK';
    
    IF v_count = 0 THEN
        EXECUTE IMMEDIATE 'ALTER TABLE APPOINTMENT
                           ADD CONSTRAINT appt_emergency_chk
                           CHECK (is_emergency IN (''Y'',''N''))';
        DBMS_OUTPUT.PUT_LINE('appt_emergency_chk constraint added');
    ELSE
        DBMS_OUTPUT.PUT_LINE('appt_emergency_chk already exists - skipped');
    END IF;
END;
/

-- Add admission_type to ADMISSION (if not exists)
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM user_tab_columns
    WHERE table_name  = 'ADMISSION'
    AND   column_name = 'ADMISSION_TYPE';
    
    IF v_count = 0 THEN
        EXECUTE IMMEDIATE 'ALTER TABLE ADMISSION
                           ADD (admission_type VARCHAR2(20) DEFAULT ''PLANNED'')';
        DBMS_OUTPUT.PUT_LINE('admission_type column added');
    ELSE
        DBMS_OUTPUT.PUT_LINE('admission_type column already exists - skipped');
    END IF;
END;
/

-- Add constraint (if not exists)
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM user_constraints
    WHERE table_name      = 'ADMISSION'
    AND   constraint_name = 'ADMISSION_TYPE_CHK';
    
    IF v_count = 0 THEN
        EXECUTE IMMEDIATE 'ALTER TABLE ADMISSION
                           ADD CONSTRAINT admission_type_chk
                           CHECK (admission_type IN (''PLANNED'',''EMERGENCY''))';
        DBMS_OUTPUT.PUT_LINE('admission_type_chk constraint added');
    ELSE
        DBMS_OUTPUT.PUT_LINE('admission_type_chk already exists - skipped');
    END IF;
END;
/

-- Verify
SELECT column_name, data_type, data_default
FROM user_tab_columns
WHERE table_name  IN ('APPOINTMENT', 'ADMISSION')
AND   column_name IN ('IS_EMERGENCY', 'ADMISSION_TYPE')
ORDER BY table_name;