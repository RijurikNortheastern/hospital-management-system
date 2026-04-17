-- Report 1: Daily Appointments Report
-- Shows all appointments for today with patient and doctor details
-- To check for a specific date:
-- WHERE a.appointment_date = DATE '2026-04-16'
SELECT 
  a.appointment_id,
  a.appointment_date,
  a.appointment_time,
  a.status,
  a.reason,
  p.first_name || ' ' || p.last_name AS patient_name,
  p.phone AS patient_phone,
  e.first_name || ' ' || e.last_name AS doctor_name,
  e.specialization,
  d.department_name
FROM APPOINTMENT a
JOIN PATIENT p ON a.PATIENT_patient_id = p.patient_id
JOIN EMPLOYEE_SCHEDULE es ON a.EMPLOYEE_SCHEDULE_bridge_id = es.bridge_id
JOIN EMPLOYEE e ON es.EMPLOYEE_employee_id = e.employee_id
JOIN DEPARTMENT d ON e.DEPARTMENT_department_id = d.department_id
WHERE a.appointment_date = TRUNC(SYSDATE)
ORDER BY a.appointment_time;

