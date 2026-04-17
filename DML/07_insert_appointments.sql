-- Insert 50 Appointments
-- References EMPLOYEE_SCHEDULE bridge_id
-- Mix of SCHEDULED, COMPLETED, CANCELLED, RESCHEDULED

BEGIN
  FOR i IN 1..50 LOOP
    INSERT INTO APPOINTMENT VALUES (
      appointment_seq.NEXTVAL,
      TRUNC(SYSDATE) + MOD(i, 20) - 10,
      TO_DATE(LPAD(8 + MOD(i, 8), 2, '0') || ':00', 'HH24:MI'),
      CASE
        WHEN MOD(i, 5) = 0 THEN 'CANCELLED'
        WHEN MOD(i, 3) = 0 THEN 'COMPLETED'
        WHEN MOD(i, 7) = 0 THEN 'RESCHEDULED'
        ELSE 'SCHEDULED'
      END,
      'Reason for visit ' || i,
      SYSDATE - MOD(i, 30),
      MOD(i - 1, 200) + 1,
      MOD(i - 1, 300) + 1
    );
  END LOOP;
  COMMIT;
END;
/