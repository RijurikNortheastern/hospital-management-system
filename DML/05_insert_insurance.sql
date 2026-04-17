-- Insert Insurance Providers + Patient-Insurance links
-- INSURANCE: provider master data
-- PATIENT_INSURANCE: bridge table (M:N)


-- 6 Insurance providers
INSERT INTO INSURANCE VALUES (insurance_seq.NEXTVAL, 'BlueCross', 'POL-BC-001', 80);
INSERT INTO INSURANCE VALUES (insurance_seq.NEXTVAL, 'Aetna', 'POL-AE-002', 70);
INSERT INTO INSURANCE VALUES (insurance_seq.NEXTVAL, 'United Health', 'POL-UH-003', 75);
INSERT INTO INSURANCE VALUES (insurance_seq.NEXTVAL, 'Cigna', 'POL-CI-004', 60);
INSERT INTO INSURANCE VALUES (insurance_seq.NEXTVAL, 'Star Health', 'POL-SH-005', 85);
INSERT INTO INSURANCE VALUES (insurance_seq.NEXTVAL, 'Max Bupa', 'POL-MB-006', 65);
COMMIT;

-- Link 100 patients to insurance (patients 1-100)
-- Some patients get 2 policies (primary + secondary) to demonstrate M:N
BEGIN
  -- 80 patients with 1 primary insurance
  FOR i IN 1..80 LOOP
    INSERT INTO PATIENT_INSURANCE VALUES (
      patient_ins_seq.NEXTVAL,
      ADD_MONTHS(SYSDATE, -12),
      ADD_MONTHS(SYSDATE, 12),
      'Y',
      i,
      MOD(i - 1, 6) + 1
    );
  END LOOP;

  -- 20 patients with a second (secondary) insurance
  FOR i IN 1..20 LOOP
    INSERT INTO PATIENT_INSURANCE VALUES (
      patient_ins_seq.NEXTVAL,
      ADD_MONTHS(SYSDATE, -6),
      ADD_MONTHS(SYSDATE, 6),
      'N',
      i,
      MOD(i, 6) + 1
    );
  END LOOP;

  COMMIT;
END;
/