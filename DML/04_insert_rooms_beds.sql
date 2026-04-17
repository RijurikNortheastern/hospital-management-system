-- Insert Rooms and Beds
-- 25 rooms x 2 beds = 50 beds
-- 25 rooms x 1 bed  = 25 beds
-- Total: 50 rooms, 75 beds


-- 25 rooms with 2 beds each
BEGIN
  FOR i IN 1..25 LOOP
    INSERT INTO ROOM VALUES (
      room_seq.NEXTVAL,
      'R' || LPAD(i, 3, '0'),
      CASE
        WHEN i <= 5 THEN 'ICU'
        WHEN i <= 15 THEN 'GENERAL'
        ELSE 'PRIVATE'
      END,
      CEIL(i / 10),
      'AVAILABLE'
    );

    INSERT INTO BED VALUES (
      bed_seq.NEXTVAL,
      'R' || LPAD(i, 3, '0') || '-A',
      'N',
      i
    );
    INSERT INTO BED VALUES (
      bed_seq.NEXTVAL,
      'R' || LPAD(i, 3, '0') || '-B',
      'N',
      i
    );
  END LOOP;
  COMMIT;
END;
/

-- 25 rooms with 1 bed each
BEGIN
  FOR i IN 26..50 LOOP
    INSERT INTO ROOM VALUES (
      room_seq.NEXTVAL,
      'R' || LPAD(i, 3, '0'),
      CASE
        WHEN i <= 30 THEN 'ICU'
        WHEN i <= 40 THEN 'PRIVATE'
        ELSE 'GENERAL'
      END,
      CEIL(i / 10),
      'AVAILABLE'
    );

    INSERT INTO BED VALUES (
      bed_seq.NEXTVAL,
      'R' || LPAD(i, 3, '0') || '-A',
      'N',
      i
    );
  END LOOP;
  COMMIT;
END;
/