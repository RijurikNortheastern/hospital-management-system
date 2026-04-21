# Hospital Management System - DMDD 6210

## Project Overview
Centralized database for hospital operations covering:
- Patient Management (with self-referencing guardian)
- Employee Management (merged Doctor + Staff)
- Appointment Management (selected module for Part 2)
- Admission & Bed Management
- Billing & Payments with Insurance bridge table

## Database
- RDBMS: Oracle Autonomous Database (OCI)
- Tables: 16 (including 2 bridge tables)
- Foreign Keys: 22
- CHECK Constraints: 13
- UNIQUE Constraints: 5
- Sequences: 16
- Stored Procedures: 5
- Triggers: 1 file (3 triggers)
- Reports: 5

## Bridge Tables
- EMPLOYEE_SCHEDULE: Resolves M:N between Employee and Doctor_Schedule
- PATIENT_INSURANCE: Resolves M:N between Patient and Insurance

## Selected Module: Appointment Management

## Folder Structure
- DDL/ - Table creation, constraints, sequences
- DML/ - Sample data insertion scripts (idempotent)
- Procedures/ - Stored procedures for business logic
- Triggers/ - Bed occupancy management triggers
- Reports/ - 5 required reports
- Security/ - User creation and grants
- Tests/ - Test case scripts
- run_all.sql - Master script to run full project

## How to Run

### Option 1 — Run File by File
1. Connect as ADMIN: Run `Security/01_roles_and_grants.sql`
2. Connect as hms_admin:
   - Run `DDL/01_create_tables.sql`
   - Run `DDL/02_constraints.sql`
   - Run `DDL/03_sequences.sql`
   - Run `DML/01` through `DML/10` in order
   - Run `Procedures/01` through `Procedures/05` in order
   - Run `Triggers/01_trg_occupied_bed.sql`
   - Run `Reports/01` through `Reports/05`
   - Run `Tests/test_cases.sql`
3. Connect as ADMIN: Run `Security/02_operator_grants.sql`

### Option 2 — Run All at Once (Recommended)
1. Connect as ADMIN: Run `Security/01_roles_and_grants.sql`
2. Connect as hms_admin: Run `run_all.sql`
3. Connect as ADMIN: Run `Security/02_operator_grants.sql`

## Stored Procedures
| # | Procedure | Description |
|---|-----------|-------------|
| 01 | book_appointment | Books appointment with 5 validations |
| 02 | cancel_appointment | Cancels with 24-hour rule |
| 03 | reschedule_appointment | Reschedules with slot management |
| 04 | admit_patient | Admits patient with doctor validation |
| 05 | generate_bill | Generates bill with insurance discount |

## Triggers
| Trigger | Type | Description |
|---------|------|-------------|
| trg_occupied_bed | BEFORE INSERT | Blocks admission to occupied bed |
| trg_mark_bed_occupied | AFTER INSERT | Marks bed occupied after admission |
| trg_release_bed_on_discharge | AFTER UPDATE | Releases bed when patient discharged |

## Data Requirements
- 200 Patients (180 adults + 20 minors with guardians)
- 23 Employees (15 Doctors + 5 Nurses + 3 Admin)
- 50 Appointments
- 10 Admissions (4 Active + 6 Discharged)
- 50 Rooms with 75 Beds
- 18 Bills + 14 Payments

## Users
| User | Role | Access |
|------|------|--------|
| hmsdbadmin | Database Admin | Full system access — runs Security scripts |
| hms_admin | Schema Owner | Full DDL + DML — runs all project scripts |
| hms_operator | Operator | SELECT all tables + INSERT/UPDATE operational tables |

## Responsibilities
| Name | Responsibility |
|------|---------------|
| Rijurik Saha | ER Diagram, DDL Script, Reports |
| Arundhati Kandelkar | Normalization, Procedures, Triggers, Test Cases |

## Team: Table Turners
```
Rijurik Saha                 Arundhati Kandelkar
DMDD 6210 - Table Turners SEC Spring 2026
```





