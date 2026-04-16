-- Insert 200 Patients: 180 Adults + 20 Minors
-- Minors have guardian_id pointing to adult patients


-- 180 Adults (no guardian)
BEGIN
  FOR i IN 1..180 LOOP
    INSERT INTO PATIENT VALUES (
      patient_seq.NEXTVAL,
      'First_' || i,
      'Last_' || i,
      ADD_MONTHS(SYSDATE, -12 * (20 + MOD(i, 45))),
      CASE WHEN MOD(i, 2) = 0 THEN 'M' ELSE 'F' END,
      '555-4' || LPAD(i, 4, '0'),
      'patient' || i || '@email.com',
      i || ' Main Street, Boston MA',
      CASE MOD(i, 8)
        WHEN 0 THEN 'A+' WHEN 1 THEN 'A-'
        WHEN 2 THEN 'B+' WHEN 3 THEN 'B-'
        WHEN 4 THEN 'O+' WHEN 5 THEN 'O-'
        WHEN 6 THEN 'AB+' ELSE 'AB-'
      END,
      '555-9' || LPAD(i, 4, '0'),
      SYSDATE - MOD(i, 365),
      NULL
    );
  END LOOP;
  COMMIT;
END;
/

-- 20 Minors (guardian_id points to first 20 adults)
BEGIN
  FOR i IN 1..20 LOOP
    INSERT INTO PATIENT VALUES (
      patient_seq.NEXTVAL,
      'Child_' || i,
      'Last_' || i,
      ADD_MONTHS(SYSDATE, -12 * (5 + MOD(i, 12))),
      CASE WHEN MOD(i, 2) = 0 THEN 'M' ELSE 'F' END,
      '555-5' || LPAD(i, 4, '0'),
      'minor' || i || '@email.com',
      i || ' Main Street, Boston MA',
      CASE MOD(i, 4)
        WHEN 0 THEN 'A+' WHEN 1 THEN 'B+'
        WHEN 2 THEN 'O+' ELSE 'AB+'
      END,
      '555-8' || LPAD(i, 4, '0'),
      SYSDATE - MOD(i, 100),
      i
    );
  END LOOP;
  COMMIT;
END;
/