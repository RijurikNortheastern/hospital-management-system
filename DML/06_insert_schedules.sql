-- Insert Doctor Schedules + Employee-Schedule bridge
-- DOCTOR_SCHEDULE: template time slots
-- EMPLOYEE_SCHEDULE: links doctors to slots on specific dates


-- Schedule templates (time slots for each day)
INSERT INTO DOCTOR_SCHEDULE VALUES (schedule_seq.NEXTVAL, 'MONDAY',
  TO_DATE('09:00','HH24:MI'), TO_DATE('13:00','HH24:MI'));
INSERT INTO DOCTOR_SCHEDULE VALUES (schedule_seq.NEXTVAL, 'MONDAY',
  TO_DATE('14:00','HH24:MI'), TO_DATE('17:00','HH24:MI'));
INSERT INTO DOCTOR_SCHEDULE VALUES (schedule_seq.NEXTVAL, 'TUESDAY',
  TO_DATE('09:00','HH24:MI'), TO_DATE('13:00','HH24:MI'));
INSERT INTO DOCTOR_SCHEDULE VALUES (schedule_seq.NEXTVAL, 'TUESDAY',
  TO_DATE('14:00','HH24:MI'), TO_DATE('17:00','HH24:MI'));
INSERT INTO DOCTOR_SCHEDULE VALUES (schedule_seq.NEXTVAL, 'WEDNESDAY',
  TO_DATE('09:00','HH24:MI'), TO_DATE('13:00','HH24:MI'));
INSERT INTO DOCTOR_SCHEDULE VALUES (schedule_seq.NEXTVAL, 'WEDNESDAY',
  TO_DATE('14:00','HH24:MI'), TO_DATE('17:00','HH24:MI'));
INSERT INTO DOCTOR_SCHEDULE VALUES (schedule_seq.NEXTVAL, 'THURSDAY',
  TO_DATE('09:00','HH24:MI'), TO_DATE('13:00','HH24:MI'));
INSERT INTO DOCTOR_SCHEDULE VALUES (schedule_seq.NEXTVAL, 'THURSDAY',
  TO_DATE('14:00','HH24:MI'), TO_DATE('17:00','HH24:MI'));
INSERT INTO DOCTOR_SCHEDULE VALUES (schedule_seq.NEXTVAL, 'FRIDAY',
  TO_DATE('09:00','HH24:MI'), TO_DATE('13:00','HH24:MI'));
INSERT INTO DOCTOR_SCHEDULE VALUES (schedule_seq.NEXTVAL, 'FRIDAY',
  TO_DATE('14:00','HH24:MI'), TO_DATE('17:00','HH24:MI'));
COMMIT;

-- Employee-Schedule bridge: assign doctors to schedule slots
-- Each doctor gets assigned to 4-5 slots across the next 30 days
BEGIN
  FOR doc_id IN 1..15 LOOP
    FOR day_offset IN 0..29 LOOP
      -- Each doctor works on days matching their pattern
      IF MOD(day_offset, 3) != MOD(doc_id, 3) THEN
        INSERT INTO EMPLOYEE_SCHEDULE VALUES (
          emp_sched_seq.NEXTVAL,
          TRUNC(SYSDATE) + day_offset,
          'AVAILABLE',
          doc_id,
          MOD(day_offset * 2 + doc_id, 10) + 1
        );
      END IF;
    END LOOP;
  END LOOP;
  COMMIT;
END;
/

-- Doctor vacations (3 doctors on upcoming leave)
INSERT INTO DOCTOR_VACATION VALUES (
  vacation_seq.NEXTVAL, SYSDATE + 5, SYSDATE + 10,
  'Family vacation', 'APPROVED', 1);
INSERT INTO DOCTOR_VACATION VALUES (
  vacation_seq.NEXTVAL, SYSDATE + 15, SYSDATE + 20,
  'Conference', 'APPROVED', 5);
INSERT INTO DOCTOR_VACATION VALUES (
  vacation_seq.NEXTVAL, SYSDATE + 2, SYSDATE + 4,
  'Personal leave', 'PENDING', 10);
COMMIT;