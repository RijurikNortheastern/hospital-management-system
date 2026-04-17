-- Report 5: Cancellation Statistics
-- Shows cancellation rates by doctor and department


-- Cancellation rate by doctor
SELECT 
  e.first_name || ' ' || e.last_name AS doctor_name,
  e.specialization,
  d.department_name,
  COUNT(a.appointment_id) AS total_appointments,
  COUNT(CASE WHEN a.status = 'CANCELLED' THEN 1 END) AS cancelled,
  COUNT(CASE WHEN a.status = 'COMPLETED' THEN 1 END) AS completed,
  COUNT(CASE WHEN a.status = 'SCHEDULED' THEN 1 END) AS upcoming,
  ROUND(
    COUNT(CASE WHEN a.status = 'CANCELLED' THEN 1 END) * 100.0 
    / COUNT(a.appointment_id), 1
  ) AS cancel_pct
FROM APPOINTMENT a
JOIN EMPLOYEE_SCHEDULE es ON a.EMPLOYEE_SCHEDULE_bridge_id = es.bridge_id
JOIN EMPLOYEE e ON es.EMPLOYEE_employee_id = e.employee_id
JOIN DEPARTMENT d ON e.DEPARTMENT_department_id = d.department_id
GROUP BY e.first_name, e.last_name, e.specialization, d.department_name
ORDER BY cancel_pct DESC;

-- Cancellation rate by department
SELECT 
  d.department_name,
  COUNT(a.appointment_id) AS total_appointments,
  COUNT(CASE WHEN a.status = 'CANCELLED' THEN 1 END) AS cancelled,
  ROUND(
    COUNT(CASE WHEN a.status = 'CANCELLED' THEN 1 END) * 100.0 
    / COUNT(a.appointment_id), 1
  ) AS cancel_pct
FROM APPOINTMENT a
JOIN EMPLOYEE_SCHEDULE es ON a.EMPLOYEE_SCHEDULE_bridge_id = es.bridge_id
JOIN EMPLOYEE e ON es.EMPLOYEE_employee_id = e.employee_id
JOIN DEPARTMENT d ON e.DEPARTMENT_department_id = d.department_id
GROUP BY d.department_name
ORDER BY cancel_pct DESC;

-- Cancellation trend (by week)
SELECT 
  TO_CHAR(a.appointment_date, 'IYYY-IW') AS week,
  COUNT(a.appointment_id) AS total,
  COUNT(CASE WHEN a.status = 'CANCELLED' THEN 1 END) AS cancelled,
  ROUND(
    COUNT(CASE WHEN a.status = 'CANCELLED' THEN 1 END) * 100.0 
    / COUNT(a.appointment_id), 1
  ) AS cancel_pct
FROM APPOINTMENT a
GROUP BY TO_CHAR(a.appointment_date, 'IYYY-IW')
ORDER BY week;