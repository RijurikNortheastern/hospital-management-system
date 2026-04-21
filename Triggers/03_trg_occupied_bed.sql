-- =============================================================
-- FILE   : Triggers/03_trg_occupied_bed.sql
-- PROJECT: Hospital Management System (DMDD 6210 - Table Turners)
-- RUN AS : hms_admin
-- PURPOSE: Prevent admission to an already occupied bed
--          Fires BEFORE INSERT ON ADMISSION
-- =============================================================
 
-- Part 1: BEFORE INSERT — block if bed already occupied
CREATE OR REPLACE TRIGGER trg_occupied_bed
BEFORE INSERT ON ADMISSION
FOR EACH ROW
DECLARE
    v_status CHAR(1);
BEGIN
    BEGIN
        SELECT is_occupied INTO v_status
        FROM   BED
        WHERE  bed_id = :NEW.BED_bed_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20103,
                'Bed ID ' || :NEW.BED_bed_id || ' does not exist.');
    END;
 
    IF v_status = 'Y' THEN
        RAISE_APPLICATION_ERROR(-20102,
            'Bed ' || :NEW.BED_bed_id || ' is already occupied.');
    END IF;
END trg_occupied_bed;
/
 
-- Part 2: AFTER INSERT — automatically mark bed as occupied
CREATE OR REPLACE TRIGGER trg_mark_bed_occupied
AFTER INSERT ON ADMISSION
FOR EACH ROW
BEGIN
    UPDATE BED
    SET    is_occupied = 'Y'
    WHERE  bed_id = :NEW.BED_bed_id;
END trg_mark_bed_occupied;
/
 
-- Part 3: AFTER UPDATE — release bed when patient discharged
CREATE OR REPLACE TRIGGER trg_release_bed_on_discharge
AFTER UPDATE ON ADMISSION
FOR EACH ROW
BEGIN
    IF :NEW.status = 'DISCHARGED' AND :OLD.status = 'ACTIVE' THEN
        UPDATE BED
        SET    is_occupied = 'N'
        WHERE  bed_id = :NEW.BED_bed_id;
    END IF;
END trg_release_bed_on_discharge;
/
 
-- Verify all 3
SELECT trigger_name, status, trigger_type, triggering_event
FROM   user_triggers
WHERE  trigger_name IN (
    'TRG_OCCUPIED_BED',
    'TRG_MARK_BED_OCCUPIED',
    'TRG_RELEASE_BED_ON_DISCHARGE'
)
ORDER BY trigger_name;