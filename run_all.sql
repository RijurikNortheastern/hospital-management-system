-- DDL
@DDL/01_create_tables.sql
@DDL/02_constraints.sql
@DDL/03_sequences.sql

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

-- Triggers
@Triggers/01_trg_duplicate_booking.sql
@Triggers/02_trg_insurance_discount.sql
@Triggers/03_trg_occupied_bed.sql

-- Tests
@Tests/test_cases.sql
