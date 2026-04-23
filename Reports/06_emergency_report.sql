-- =============================================================
-- FILE   : Reports/06_emergency_report.sql
-- PROJECT: Hospital Management System (DMDD 6210 - Table Turners)
-- RUN AS : hms_admin
-- PURPOSE: Emergency appointments report
-- =============================================================

SET SERVEROUTPUT ON;

PROMPT ============================================================
PROMPT  EMERGENCY APPOINTMENTS REPORT
PROMPT  Hospital Management System
PROMPT ============================================================

SELECT
    a.appointment_id                            AS "Appt ID",
    p.first_name || ' ' || p.last_name          AS "Patient Name",
    e.first_name || ' ' || e.last_name          AS "Doctor Name",
    d.department_name                           AS "Department",
    TO_CHAR(a.appointment_date, 'YYYY-MM-DD')   AS "Date",
    TO_CHAR(a.appointment_time, 'HH24:MI')      AS "Time",
    a.reason                                    AS "Reason",
    a.status                                    AS "Status",
    a.is_emergency                              AS "Emergency"
FROM   APPOINTMENT a
JOIN   PATIENT p
       ON p.patient_id = a.PATIENT_patient_id
JOIN   EMPLOYEE_SCHEDULE es
       ON es.bridge_id = a.EMPLOYEE_SCHEDULE_bridge_id
JOIN   EMPLOYEE e
       ON e.employee_id = es.EMPLOYEE_employee_id
JOIN   DEPARTMENT d
       ON d.department_id = e.DEPARTMENT_DEPARTMENT_ID
WHERE  a.is_emergency = 'Y'
ORDER  BY a.appointment_date DESC, a.appointment_time DESC;

PROMPT ============================================================
PROMPT  EMERGENCY SUMMARY
PROMPT ============================================================

SELECT
    COUNT(*)                                                AS "Total Emergency Appts",
    SUM(CASE WHEN status = 'SCHEDULED'  THEN 1 ELSE 0 END) AS "Scheduled",
    SUM(CASE WHEN status = 'COMPLETED'  THEN 1 ELSE 0 END) AS "Completed",
    SUM(CASE WHEN status = 'CANCELLED'  THEN 1 ELSE 0 END) AS "Cancelled"
FROM   APPOINTMENT
WHERE  is_emergency = 'Y';