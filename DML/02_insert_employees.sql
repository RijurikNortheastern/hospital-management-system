-- Insert Employees: 15 Doctors + 5 Nurses + 3 Admin


-- 15 Doctors
BEGIN
  FOR i IN 1..15 LOOP
    INSERT INTO EMPLOYEE VALUES (
      employee_seq.NEXTVAL,
      'DrFirst_' || i,
      'DrLast_' || i,
      'DOCTOR',
      '555-1' || LPAD(i, 3, '0'),
      'doctor' || i || '@hospital.com',
      SYSDATE - (365 * MOD(i, 10)),
      150000 + (i * 5000),
      CASE MOD(i, 5)
        WHEN 0 THEN 'Cardiologist'
        WHEN 1 THEN 'Neurologist'
        WHEN 2 THEN 'Orthopedic Surgeon'
        WHEN 3 THEN 'Pediatrician'
        ELSE 'General Physician'
      END,
      'LIC-' || LPAD(i, 5, '0'),
      MOD(i - 1, 5) + 1
    );
  END LOOP;
  COMMIT;
END;
/

-- 5 Nurses
BEGIN
  FOR i IN 1..5 LOOP
    INSERT INTO EMPLOYEE VALUES (
      employee_seq.NEXTVAL,
      'Nurse_' || i,
      'NurseLast_' || i,
      'NURSE',
      '555-2' || LPAD(i, 3, '0'),
      'nurse' || i || '@hospital.com',
      SYSDATE - 500,
      60000 + (i * 2000),
      NULL,
      NULL,
      MOD(i - 1, 5) + 1
    );
  END LOOP;
  COMMIT;
END;
/

-- 3 Admin staff
BEGIN
  FOR i IN 1..3 LOOP
    INSERT INTO EMPLOYEE VALUES (
      employee_seq.NEXTVAL,
      'Admin_' || i,
      'AdminLast_' || i,
      'ADMIN',
      '555-3' || LPAD(i, 3, '0'),
      'admin' || i || '@hospital.com',
      SYSDATE - 300,
      45000 + (i * 1000),
      NULL,
      NULL,
      MOD(i - 1, 5) + 1
    );
  END LOOP;
  COMMIT;
END;
/