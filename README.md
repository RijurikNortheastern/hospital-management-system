# \# Hospital Management System - DMDD 6210

# 

# \## Team: Table Turners

# | Name | Responsibility |

# |------|---------------|

# | Rijurik Saha | ER Diagram, DDL Script, Procedures |

# | Arundhati Kandelkar | Normalization, Triggers, Test Cases |

# 

# \## Project Overview

# Centralized database for hospital operations covering:

# \- Patient Management (with self-referencing guardian)

# \- Employee Management (merged Doctor + Staff)

# \- Appointment Management (selected module for Part 2)

# \- Admission \& Bed Management

# \- Billing \& Payments with Insurance bridge table

# 

# \## Database

# \- RDBMS: Oracle 11g

# \- Tables: 16 (including 2 bridge tables)

# \- Foreign Keys: 22

# \- CHECK Constraints: 13

# \- UNIQUE Constraints: 5

# 

# \## Bridge Tables

# \- EMPLOYEE\_SCHEDULE: Resolves M:N between Employee and Doctor\_Schedule

# \- PATIENT\_INSURANCE: Resolves M:N between Patient and Insurance

# 

# \## Selected Module: Appointment Management

# 

# \## Folder Structure

# \- DDL/ - Table creation, constraints, sequences

# \- DML/ - Sample data insertion scripts

# \- Procedures/ - Stored procedures for business logic

# \- Triggers/ - Transaction validation triggers

# \- Reports/ - 5 required reports

# \- Security/ - User roles and grants

# \- Tests/ - Test case scripts

# \- Docs/ - Design documents

# 

# \## How to Run

# 1\. Connect as SYS: Run Security/01\_roles\_and\_grants.sql

# 2\. Connect as hms\_admin: Run DDL scripts in order 01, 02, 03

# 3\. Run DML scripts in order 01 through 09

# 4\. Run Procedures, Triggers, Reports

# 5\. Run Tests: Tests/test\_cases.sql

# 

# \## Data Requirements

# \- 200 Patients (180 adults + 20 minors with guardians)

# \- 15 Doctors + Staff in EMPLOYEE table

# \- 50 Appointments

# \- 10 Admissions

# \- 50 Rooms with 75 Beds

