-- =============================================================
-- FILE   : Reports/03_bed_occupancy.sql
-- PROJECT: Hospital Management System (DMDD 6210 - Table Turners)
-- RUN AS : hms_admin
-- PURPOSE: Current bed occupancy status across all rooms
-- =============================================================
 
-- Detailed bed status
SELECT
    r.room_number,
    r.room_type,
    r.floor_num,
    b.bed_number,
    CASE b.is_occupied
        WHEN 'Y' THEN 'Occupied'
        ELSE          'Available'
    END                                         AS bed_status,
    p.first_name || ' ' || p.last_name         AS patient_name,
    a.admit_date,
    e.first_name || ' ' || e.last_name         AS attending_doctor
FROM   ROOM r
JOIN   BED       b  ON b.ROOM_room_id          = r.room_id
LEFT JOIN ADMISSION  a  ON a.BED_bed_id        = b.bed_id AND a.status = 'ACTIVE'
LEFT JOIN PATIENT    p  ON p.patient_id        = a.PATIENT_patient_id
LEFT JOIN EMPLOYEE   e  ON e.employee_id       = a.EMPLOYEE_employee_id
ORDER  BY r.room_number, b.bed_number;
 
-- Summary by room type
SELECT
    r.room_type,
    COUNT(b.bed_id)                                                                     AS total_beds,
    SUM(CASE WHEN b.is_occupied = 'Y' THEN 1 ELSE 0 END)                               AS occupied,
    SUM(CASE WHEN b.is_occupied = 'N' THEN 1 ELSE 0 END)                               AS available,
    ROUND(SUM(CASE WHEN b.is_occupied = 'Y' THEN 1 ELSE 0 END) * 100.0 / COUNT(b.bed_id), 1) AS occupancy_pct
FROM   ROOM r
JOIN   BED b ON b.ROOM_room_id = r.room_id
GROUP  BY r.room_type
ORDER  BY r.room_type;