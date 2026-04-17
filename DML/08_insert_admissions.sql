-- Insert 10 Admissions
-- 4 ACTIVE (beds occupied) + 6 DISCHARGED (beds freed)


BEGIN
  -- 4 Active admissions (beds stay occupied)
  FOR i IN 1..4 LOOP
    UPDATE BED SET is_occupied = 'Y' WHERE bed_id = i;

    INSERT INTO ADMISSION VALUES (
      admission_seq.NEXTVAL,
      SYSDATE - (20 - i * 2),
      NULL,
      'Admission reason ' || i,
      'ACTIVE',
      i,
      i,
      MOD(i - 1, 15) + 1
    );
  END LOOP;

  -- 6 Discharged admissions (beds freed)
  FOR i IN 5..10 LOOP
    INSERT INTO ADMISSION VALUES (
      admission_seq.NEXTVAL,
      SYSDATE - (30 - i * 2),
      SYSDATE - (i - 4),
      'Admission reason ' || i,
      'DISCHARGED',
      i,
      i,
      MOD(i - 1, 15) + 1
    );
    -- Bed stays 'N' (already default) since patient discharged
  END LOOP;

  COMMIT;
END;
/