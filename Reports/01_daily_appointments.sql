-- =============================================================
-- FILE   : Reports/01_daily_appointments.sql
-- PROJECT: Hospital Management System (DMDD 6210 - Table Turners)
-- RUN AS : hms_admin
-- PURPOSE: Daily appointments report with patient and doctor details
-- USAGE  : Run as-is for today's appointments
--          Change TRUNC(SYSDATE) to a specific date to filter:
--          WHERE a.appointment_date = DATE '2026-04-16'
-- =============================================================
 
SELECT
    a.appointment_id,
    a.appointment_date,
    TO_CHAR(a.appointment_time, 'HH24:MI')      AS appointment_time,
    a.status,
    a.reason,
    p.first_name || ' ' || p.last_name          AS patient_name,
    p.phone                                      AS patient_phone,
    e.first_name || ' ' || e.last_name          AS doctor_name,
    e.specialization,
    d.department_name
FROM   APPOINTMENT a
JOIN   PATIENT          p  ON p.patient_id          = a.PATIENT_patient_id
JOIN   EMPLOYEE_SCHEDULE es ON es.bridge_id          = a.EMPLOYEE_SCHEDULE_bridge_id
JOIN   EMPLOYEE         e  ON e.employee_id          = es.EMPLOYEE_employee_id
JOIN   DEPARTMENT       d  ON d.department_id        = e.DEPARTMENT_department_id
WHERE  a.appointment_date = TRUNC(SYSDATE)
ORDER  BY a.appointment_time;
