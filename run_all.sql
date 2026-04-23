-- =============================================================
-- FILE   : run_all.sql
-- PROJECT: Hospital Management System (DMDD 6210 - Table Turners)
-- RUN AS : hms_admin
-- PURPOSE: Master script - runs all components in order
-- =============================================================

-- DDL
@DDL/01_create_tables.sql
@DDL/02_constraints.sql
@DDL/03_sequences.sql
@DDL/04_emergency_alter.sql

-- DML
@DML/01_insert_departments.sql
@DML/02_insert_employees.sql
@DML/03_insert_patients.sql
@DML/04_insert_rooms_beds.sql
@DML/05_insert_insurance.sql
@DML/06_insert_schedules.sql
@DML/07_insert_appointments.sql
@DML/08_insert_admissions.sql
@DML/09_insert_billing_payments.sql
@DML/10_Data_Load_Verification.sql

-- Procedures
@Procedures/01_book_appointment.sql
@Procedures/02_cancel_appointment.sql
@Procedures/03_reschedule_appointment.sql
@Procedures/04_admit_patient.sql
@Procedures/05_generate_bill.sql
@Procedures/06_book_emergency.sql

-- Triggers
@Triggers/01_trg_occupied_bed.sql

-- Reports
@Reports/01_daily_appointments.sql
@Reports/02_doctor_schedule.sql
@Reports/03_bed_occupancy.sql
@Reports/04_revenue_report.sql
@Reports/05_cancellation_stats.sql
@Reports/06_emergency_report.sql

-- Tests
@Tests/test_cases.sql