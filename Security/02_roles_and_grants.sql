-- Operator: SELECT on all tables
GRANT SELECT ON hms_admin.PATIENT TO hms_operator;
GRANT SELECT ON hms_admin.EMPLOYEE TO hms_operator;
GRANT SELECT ON hms_admin.DEPARTMENT TO hms_operator;
GRANT SELECT ON hms_admin.APPOINTMENT TO hms_operator;
GRANT SELECT ON hms_admin.APPOINTMENT_HISTORY TO hms_operator;
GRANT SELECT ON hms_admin.ADMISSION TO hms_operator;
GRANT SELECT ON hms_admin.BED TO hms_operator;
GRANT SELECT ON hms_admin.ROOM TO hms_operator;
GRANT SELECT ON hms_admin.BILLING TO hms_operator;
GRANT SELECT ON hms_admin.PAYMENT TO hms_operator;
GRANT SELECT ON hms_admin.INSURANCE TO hms_operator;
GRANT SELECT ON hms_admin.PATIENT_INSURANCE TO hms_operator;
GRANT SELECT ON hms_admin.PRESCRIPTION TO hms_operator;
GRANT SELECT ON hms_admin.DOCTOR_SCHEDULE TO hms_operator;
GRANT SELECT ON hms_admin.EMPLOYEE_SCHEDULE TO hms_operator;
GRANT SELECT ON hms_admin.DOCTOR_VACATION TO hms_operator;

-- Operator: INSERT/UPDATE on operational tables
GRANT INSERT, UPDATE ON hms_admin.APPOINTMENT TO hms_operator;
GRANT INSERT, UPDATE ON hms_admin.PATIENT TO hms_operator;
GRANT INSERT, UPDATE ON hms_admin.ADMISSION TO hms_operator;
GRANT INSERT, UPDATE ON hms_admin.BILLING TO hms_operator;
GRANT INSERT, UPDATE ON hms_admin.PAYMENT TO hms_operator;