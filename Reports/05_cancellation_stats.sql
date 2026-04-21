-- =============================================================
-- FILE   : Reports/05_cancellation_stats.sql
-- PROJECT: Hospital Management System (DMDD 6210 - Table Turners)
-- RUN AS : hms_admin
-- PURPOSE: Appointment cancellation rates by doctor, department,
--          and weekly trend
-- =============================================================
 
-- Cancellation rate by doctor
SELECT
    e.first_name || ' ' || e.last_name          AS doctor_name,
    e.specialization,
    d.department_name,
    COUNT(a.appointment_id)                      AS total_appointments,
    COUNT(CASE WHEN a.status = 'CANCELLED' THEN 1 END) AS cancelled,
    COUNT(CASE WHEN a.status = 'COMPLETED' THEN 1 END) AS completed,
    COUNT(CASE WHEN a.status = 'SCHEDULED' THEN 1 END) AS upcoming,
    ROUND(
        COUNT(CASE WHEN a.status = 'CANCELLED' THEN 1 END) * 100.0
        / COUNT(a.appointment_id), 1
    )                                            AS cancel_pct
FROM   APPOINTMENT a
JOIN   EMPLOYEE_SCHEDULE es ON es.bridge_id             = a.EMPLOYEE_SCHEDULE_bridge_id
JOIN   EMPLOYEE          e  ON e.employee_id             = es.EMPLOYEE_employee_id
JOIN   DEPARTMENT        d  ON d.department_id           = e.DEPARTMENT_department_id
GROUP  BY e.first_name, e.last_name, e.specialization, d.department_name
ORDER  BY cancel_pct DESC;
 
-- Cancellation rate by department
SELECT
    d.department_name,
    COUNT(a.appointment_id)                      AS total_appointments,
    COUNT(CASE WHEN a.status = 'CANCELLED' THEN 1 END) AS cancelled,
    ROUND(
        COUNT(CASE WHEN a.status = 'CANCELLED' THEN 1 END) * 100.0
        / COUNT(a.appointment_id), 1
    )                                            AS cancel_pct
FROM   APPOINTMENT a
JOIN   EMPLOYEE_SCHEDULE es ON es.bridge_id             = a.EMPLOYEE_SCHEDULE_bridge_id
JOIN   EMPLOYEE          e  ON e.employee_id             = es.EMPLOYEE_employee_id
JOIN   DEPARTMENT        d  ON d.department_id           = e.DEPARTMENT_department_id
GROUP  BY d.department_name
ORDER  BY cancel_pct DESC;
 
-- Cancellation trend by week
SELECT
    TO_CHAR(a.appointment_date, 'IYYY-IW')       AS week,
    COUNT(a.appointment_id)                      AS total,
    COUNT(CASE WHEN a.status = 'CANCELLED' THEN 1 END) AS cancelled,
    ROUND(
        COUNT(CASE WHEN a.status = 'CANCELLED' THEN 1 END) * 100.0
        / COUNT(a.appointment_id), 1
    )                                            AS cancel_pct
FROM   APPOINTMENT a
GROUP  BY TO_CHAR(a.appointment_date, 'IYYY-IW')
ORDER  BY week;