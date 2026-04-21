-- =============================================================
-- FILE   : Reports/02_doctor_schedule.sql
-- PROJECT: Hospital Management System (DMDD 6210 - Table Turners)
-- RUN AS : hms_admin
-- PURPOSE: Doctor weekly schedule and upcoming vacation report
-- =============================================================
 
-- Weekly schedule templates per doctor
SELECT
    e.first_name || ' ' || e.last_name  AS doctor_name,
    e.specialization,
    d.department_name,
    ds.day_of_week,
    TO_CHAR(ds.start_time, 'HH24:MI')   AS shift_start,
    TO_CHAR(ds.end_time,   'HH24:MI')   AS shift_end,
    es.availability_date,
    es.status                            AS slot_status
FROM   EMPLOYEE_SCHEDULE es
JOIN   EMPLOYEE      e  ON e.employee_id          = es.EMPLOYEE_employee_id
JOIN   DEPARTMENT    d  ON d.department_id         = e.DEPARTMENT_department_id
JOIN   DOCTOR_SCHEDULE ds ON ds.schedule_id        = es.DOCTOR_SCHEDULE_schedule_id
WHERE  e.role             = 'DOCTOR'
  AND  es.status          = 'AVAILABLE'
  AND  es.availability_date BETWEEN TRUNC(SYSDATE) AND TRUNC(SYSDATE) + 7
ORDER  BY e.last_name, es.availability_date;
 
-- Upcoming vacations
SELECT
    e.first_name || ' ' || e.last_name  AS doctor_name,
    v.start_date,
    v.end_date,
    v.reason,
    v.status                             AS vacation_status
FROM   DOCTOR_VACATION v
JOIN   EMPLOYEE e ON e.employee_id = v.EMPLOYEE_employee_id
WHERE  v.end_date >= TRUNC(SYSDATE)
ORDER  BY v.start_date;