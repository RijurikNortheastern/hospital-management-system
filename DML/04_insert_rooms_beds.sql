-- =============================================================
-- FILE   : DML/04_insert_rooms_beds.sql
-- PROJECT: Hospital Management System (DMDD 6210 - Table Turners)
-- RUN AS : hms_admin
-- PURPOSE: Seed 50 rooms and 75 beds
--            25 rooms × 2 beds = 50 beds
--            25 rooms × 1 bed  = 25 beds
--            Total: 50 rooms, 75 beds
-- DEPENDS: DDL/01, DDL/02, DDL/03 must run first
-- SAFE   : Idempotent — deletes ROOM/BED rows before re-inserting
-- ROOM DISTRIBUTION:
--   Rooms  1–5   → ICU      (5 rooms, 2 beds each = 10 beds)
--   Rooms  6–15  → GENERAL  (10 rooms, 2 beds each = 20 beds)
--   Rooms 16–25  → PRIVATE  (10 rooms, 2 beds each = 20 beds)
--   Rooms 26–30  → ICU      (5 rooms,  1 bed  each =  5 beds)
--   Rooms 31–40  → PRIVATE  (10 rooms, 1 bed  each = 10 beds)
--   Rooms 41–50  → GENERAL  (10 rooms, 1 bed  each = 10 beds)
--   ICU total: 15 beds | GENERAL: 30 beds | PRIVATE: 30 beds
-- =============================================================
 
 
-- =============================================================
-- SECTION 1: CLEAN EXISTING DATA (FK order: BED before ROOM)
-- =============================================================
 
BEGIN
    DELETE FROM BED;
    DELETE FROM ROOM;
    DBMS_OUTPUT.PUT_LINE('BED and ROOM tables cleared.');
END;
/
 
 
-- =============================================================
-- SECTION 2: INSERT 25 ROOMS WITH 2 BEDS EACH (rooms 1–25)
--      always references the correct just-inserted room_id
--      instead of hardcoded loop index i (breaks on re-run)
-- =============================================================
 
BEGIN
    FOR i IN 1..25 LOOP
        -- Insert room
        INSERT INTO ROOM (
            room_id,
            room_number,
            room_type,
            floor_num,
            status
        ) VALUES (
            room_seq.NEXTVAL,
            'R' || LPAD(i, 3, '0'),
            CASE
                WHEN i <= 5  THEN 'ICU'
                WHEN i <= 15 THEN 'GENERAL'
                ELSE              'PRIVATE'
            END,
            CEIL(i / 10),
            'AVAILABLE'
        );
 
        -- Insert Bed A — reference the room just inserted via CURRVAL
        INSERT INTO BED (
            bed_id,
            bed_number,
            is_occupied,
            ROOM_room_id
        ) VALUES (
            bed_seq.NEXTVAL,
            'R' || LPAD(i, 3, '0') || '-A',
            'N',
            room_seq.CURRVAL    -- always matches the room inserted above
        );
 
        -- Insert Bed B
        INSERT INTO BED (
            bed_id,
            bed_number,
            is_occupied,
            ROOM_room_id
        ) VALUES (
            bed_seq.NEXTVAL,
            'R' || LPAD(i, 3, '0') || '-B',
            'N',
            room_seq.CURRVAL    -- same room
        );
    END LOOP;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('25 rooms (2 beds each) inserted — 50 beds total.');
END;
/
 
 
-- =============================================================
-- SECTION 3: INSERT 25 ROOMS WITH 1 BED EACH (rooms 26–50)
-- =============================================================
 
BEGIN
    FOR i IN 26..50 LOOP
        -- Insert room
        INSERT INTO ROOM (
            room_id,
            room_number,
            room_type,
            floor_num,
            status
        ) VALUES (
            room_seq.NEXTVAL,
            'R' || LPAD(i, 3, '0'),
            CASE
                WHEN i <= 30 THEN 'ICU'
                WHEN i <= 40 THEN 'PRIVATE'
                ELSE              'GENERAL'
            END,
            CEIL(i / 10),
            'AVAILABLE'
        );
 
        -- Insert single Bed A
        INSERT INTO BED (
            bed_id,
            bed_number,
            is_occupied,
            ROOM_room_id
        ) VALUES (
            bed_seq.NEXTVAL,
            'R' || LPAD(i, 3, '0') || '-A',
            'N',
            room_seq.CURRVAL    -- matches the room inserted above
        );
    END LOOP;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('25 rooms (1 bed each) inserted — 25 beds total.');
END;
/
 
 
-- =============================================================
-- SECTION 4: VERIFY
-- =============================================================
 
-- Room count by type
SELECT
    room_type,
    COUNT(*)          AS room_count,
    SUM(COUNT(*)) OVER() AS total_rooms
FROM   ROOM
GROUP  BY room_type
ORDER  BY room_type;
 
-- Bed count by room type
SELECT
    r.room_type,
    COUNT(b.bed_id)   AS bed_count
FROM   ROOM r
JOIN   BED  b ON b.ROOM_room_id = r.room_id
GROUP  BY r.room_type
ORDER  BY r.room_type;
 
-- Total rooms and beds
SELECT
    (SELECT COUNT(*) FROM ROOM) AS total_rooms,
    (SELECT COUNT(*) FROM BED)  AS total_beds
FROM   DUAL;
 
BEGIN
    DBMS_OUTPUT.PUT_LINE('DML/04 completed — 50 rooms, 75 beds inserted.');
END;
/