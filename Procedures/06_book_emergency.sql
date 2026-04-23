-- =============================================================
-- FILE   : Procedures/06_book_emergency.sql
-- PROJECT: Hospital Management System (DMDD 6210 - Table Turners)
-- RUN AS : hms_admin
-- PURPOSE: Book emergency appointment with auto ICU bed,
--          auto admission and auto bill generation
-- =============================================================

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
    v_bed_id        NUMBER;
    v_admission_id  NUMBER;
    v_bill_id       NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_patient_cnt
    FROM   PATIENT WHERE patient_id = p_patient_id;
    IF v_patient_cnt = 0 THEN
        RAISE_APPLICATION_ERROR(-20060,'Patient ID '||p_patient_id||' does not exist.');
    END IF;

    BEGIN
        SELECT e.employee_id INTO v_doctor_id
        FROM   EMPLOYEE e
        WHERE  e.role = 'DOCTOR'
          AND  e.DEPARTMENT_DEPARTMENT_ID = p_dept_id
          AND  e.employee_id NOT IN (
                    SELECT dv.EMPLOYEE_employee_id FROM DOCTOR_VACATION dv
                    WHERE  dv.status = 'APPROVED'
                    AND    p_date BETWEEN dv.start_date AND dv.end_date)
          AND  ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20061,'No doctors available in department '||p_dept_id||' on '||TO_CHAR(p_date,'YYYY-MM-DD')||'.');
    END;

    BEGIN
        SELECT bridge_id INTO v_bridge_id
        FROM   EMPLOYEE_SCHEDULE
        WHERE  EMPLOYEE_employee_id = v_doctor_id
          AND  status = 'AVAILABLE'
          AND  ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20062,'No available slots for emergency doctor '||v_doctor_id||'.');
    END;

    BEGIN
        SELECT b.bed_id INTO v_bed_id
        FROM   BED b JOIN ROOM r ON r.room_id = b.ROOM_room_id
        WHERE  b.is_occupied = 'N' AND r.room_type = 'ICU' AND ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            BEGIN
                SELECT bed_id INTO v_bed_id FROM BED
                WHERE  is_occupied = 'N' AND ROWNUM = 1;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    RAISE_APPLICATION_ERROR(-20063,'No beds available for emergency admission.');
            END;
    END;

    v_new_appt_id := APPOINTMENT_SEQ.NEXTVAL;
    INSERT INTO APPOINTMENT (appointment_id,appointment_date,appointment_time,status,reason,created_at,is_emergency,PATIENT_patient_id,EMPLOYEE_SCHEDULE_bridge_id)
    VALUES (v_new_appt_id,p_date,SYSDATE,'SCHEDULED',p_reason,SYSDATE,'Y',p_patient_id,v_bridge_id);

    UPDATE EMPLOYEE_SCHEDULE SET status = 'UNAVAILABLE' WHERE bridge_id = v_bridge_id;

    INSERT INTO APPOINTMENT_HISTORY (history_id,action,action_date,old_date,new_date,notes,APPOINTMENT_appointment_id)
    VALUES (HISTORY_SEQ.NEXTVAL,'EMERGENCY_CREATED',SYSDATE,NULL,p_date,'Emergency booking — auto assigned doctor '||v_doctor_id,v_new_appt_id);

    v_admission_id := ADMISSION_SEQ.NEXTVAL;
    INSERT INTO ADMISSION (admission_id,admit_date,admit_reason,status,admission_type,PATIENT_PATIENT_ID,BED_BED_ID,EMPLOYEE_EMPLOYEE_ID)
    VALUES (v_admission_id,SYSDATE,p_reason,'ACTIVE','EMERGENCY',p_patient_id,v_bed_id,v_doctor_id);

    -- Manual bed update to ensure visibility
    UPDATE BED SET is_occupied = 'Y' WHERE bed_id = v_bed_id;

    v_bill_id := BILL_SEQ.NEXTVAL;
    INSERT INTO BILLING (bill_id,bill_date,total_amount,discount,net_amount,status,PATIENT_PATIENT_ID,ADMISSION_ADMISSION_ID)
    VALUES (v_bill_id,SYSDATE,5000,0,5000,'PENDING',p_patient_id,v_admission_id);

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('========================================');
    DBMS_OUTPUT.PUT_LINE('EMERGENCY MODULE COMPLETE');
    DBMS_OUTPUT.PUT_LINE('Appointment ID : '||v_new_appt_id);
    DBMS_OUTPUT.PUT_LINE('Doctor ID      : '||v_doctor_id);
    DBMS_OUTPUT.PUT_LINE('Bed ID         : '||v_bed_id);
    DBMS_OUTPUT.PUT_LINE('Admission ID   : '||v_admission_id);
    DBMS_OUTPUT.PUT_LINE('Bill ID        : '||v_bill_id);
    DBMS_OUTPUT.PUT_LINE('========================================');

EXCEPTION
    WHEN OTHERS THEN ROLLBACK; RAISE;
END book_emergency;
/

SELECT object_name, status FROM user_objects WHERE object_name = 'BOOK_EMERGENCY';