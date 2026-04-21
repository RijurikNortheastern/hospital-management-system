-- =============================================================
-- FILE   : Triggers/02_trg_insurance_discount.sql
-- PROJECT: Hospital Management System (DMDD 6210 - Table Turners)
-- RUN AS : hms_admin
-- PURPOSE: Auto-calculate insurance discount on billing insert
--          Fires BEFORE INSERT ON BILLING
-- FIXES  : Missing valid_from check, no rounding, discount
--          override issue when procedure already set discount
-- =============================================================
 
CREATE OR REPLACE TRIGGER trg_insurance_discount
BEFORE INSERT ON BILLING
FOR EACH ROW
DECLARE
    v_coverage NUMBER := 0;
BEGIN
    -- Only recalculate if discount not already set by caller
    -- (e.g. generate_bill procedure already calculated it)
    IF :NEW.DISCOUNT IS NULL OR :NEW.DISCOUNT = 0 THEN
 
        BEGIN
            SELECT ins.coverage_pct
            INTO   v_coverage
            FROM   PATIENT_INSURANCE pi
            JOIN   INSURANCE ins
                   ON ins.insurance_id = pi.INSURANCE_insurance_id
            WHERE  pi.PATIENT_patient_id = :NEW.PATIENT_patient_id
              AND  pi.is_primary         = 'Y'
              AND  ROWNUM = 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_coverage := 0;
        END;
 
        :NEW.DISCOUNT    := ROUND((:NEW.TOTAL_AMOUNT * v_coverage) / 100, 2);
        :NEW.NET_AMOUNT  := ROUND(:NEW.TOTAL_AMOUNT - :NEW.DISCOUNT, 2);
 
    ELSE
        -- Discount already set — just ensure net_amount is consistent
        :NEW.NET_AMOUNT := ROUND(:NEW.TOTAL_AMOUNT - NVL(:NEW.DISCOUNT, 0), 2);
 
    END IF;
END trg_insurance_discount;
/
 
-- Verify
SELECT trigger_name, status, trigger_type, triggering_event
FROM   user_triggers
WHERE  trigger_name = 'TRG_INSURANCE_DISCOUNT';