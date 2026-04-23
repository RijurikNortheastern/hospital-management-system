-- ============================================
-- PROCEDURE: book_emergency
-- Hospital Management System - DMDD 6210
-- Idempotent - CREATE OR REPLACE
-- ============================================

CREATE OR REPLACE PROCEDURE book_emergency (
    p_patient_id    IN NUMBER,
    p_dept_id       IN NUMBER,
    p_reason        IN VARCHAR2,
    p_date          IN DATE
) AS
    v_doctor_id     NUMBER;
    v_bridge_id     NUMBER;
    v_patient_cnt   NUMBER;
    v_new_appt_id   NUMBER;
BEGIN
    -- VALIDATION 1: Patient exists?
    SELECT COUNT(*) INTO v_patient_cnt
    FROM   PATIENT
    WHERE  patient_id = p_patient_id;

    IF v_patient_cnt = 0 THEN
        RAISE_APPLICATION_ERROR(-20060,
            'Patient ID ' || p_patient_id || ' does not exist.');
    END IF;

    -- VALIDATION 2: Find available doctor in department
    BEGIN
        SELECT e.employee_id INTO v_doctor_id
        FROM   EMPLOYEE e
        WHERE  e.role = 'DOCTOR'
          AND  e.DEPARTMENT_DEPARTMENT_ID = p_dept_id
          AND  e.employee_id NOT IN (
                    SELECT dv.EMPLOYEE_employee_id
                    FROM   DOCTOR_VACATION dv
                    WHERE  dv.status = 'APPROVED'
                    AND    p_date BETWEEN dv.start_date AND dv.end_date)
          AND  ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20061,
                'No doctors available in department ' ||
                p_dept_id || ' on ' ||
                TO_CHAR(p_date, 'YYYY-MM-DD') || '.');
    END;

    -- VALIDATION 3: Find first AVAILABLE slot for that doctor
    BEGIN
        SELECT bridge_id INTO v_bridge_id
        FROM   EMPLOYEE_SCHEDULE
        WHERE  EMPLOYEE_employee_id = v_doctor_id
          AND  status = 'AVAILABLE'
          AND  ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20062,
                'No available slots for emergency doctor ' ||
                v_doctor_id || '.');
    END;

    -- ALL VALIDATIONS PASSED - INSERT EMERGENCY APPOINTMENT
    v_new_appt_id := APPOINTMENT_SEQ.NEXTVAL;

    INSERT INTO APPOINTMENT (
        appointment_id,
        appointment_date,
        appointment_time,
        status,
        reason,
        created_at,
        is_emergency,
        PATIENT_patient_id,
        EMPLOYEE_SCHEDULE_bridge_id
    ) VALUES (
        v_new_appt_id,
        p_date,
        SYSDATE,
        'SCHEDULED',
        p_reason,
        SYSDATE,
        'Y',
        p_patient_id,
        v_bridge_id
    );

    -- Mark slot UNAVAILABLE
    UPDATE EMPLOYEE_SCHEDULE
    SET    status = 'UNAVAILABLE'
    WHERE  bridge_id = v_bridge_id;

    -- Insert history
    INSERT INTO APPOINTMENT_HISTORY (
        history_id,
        action,
        action_date,
        old_date,
        new_date,
        notes,
        APPOINTMENT_appointment_id
    ) VALUES (
        HISTORY_SEQ.NEXTVAL,
        'EMERGENCY_CREATED',
        SYSDATE,
        NULL,
        p_date,
        'Emergency booking — auto assigned doctor ' || v_doctor_id,
        v_new_appt_id
    );

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('Emergency appointment ' || v_new_appt_id ||
                         ' created for patient ' || p_patient_id ||
                         ' with doctor ' || v_doctor_id ||
                         ' on slot ' || v_bridge_id);

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END book_emergency;
/

-- Verify
SELECT object_name, status
FROM   user_objects
WHERE  object_name = 'BOOK_EMERGENCY';