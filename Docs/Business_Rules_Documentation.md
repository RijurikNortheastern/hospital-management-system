# Business Rule Documentation
## Hospital Management System - DMDD 6210
## Team: Table Turners

---

## 1. Patient Management Rules

| Rule ID | Rule | Implementation |
|---------|------|----------------|
| BR-P1 | Every patient must have a unique email address | UNIQUE constraint on PATIENT.email |
| BR-P2 | Patient date of birth is mandatory | NOT NULL constraint on PATIENT.dob |
| BR-P3 | Minor patients (under 18) must have a guardian | Self-referencing FK: PATIENT.guardian_id → PATIENT.patient_id |
| BR-P4 | Guardian must be an adult patient in the system | guardian_id references existing adult patient |
| BR-P5 | Patient phone number is mandatory | NOT NULL constraint on PATIENT.phone |

---

## 2. Employee Management Rules

| Rule ID | Rule | Implementation |
|---------|------|----------------|
| BR-E1 | Employee role must be DOCTOR, NURSE, TECHNICIAN, or ADMIN | CHECK constraint: EMP_ROLE_CHK |
| BR-E2 | Every employee must belong to a department | NOT NULL FK: EMPLOYEE.DEPARTMENT_department_id |
| BR-E3 | Employee email must be unique | UNIQUE constraint: EMPLOYEE_EMAIL_UN |
| BR-E4 | Doctor license number must be unique | UNIQUE constraint: EMPLOYEE_LICENSE_NO_UN |
| BR-E5 | Only employees with role DOCTOR can be booked for appointments | Validated in book_appointment procedure |
| BR-E6 | Only employees with role DOCTOR can admit patients | Validated in admit_patient procedure |
| BR-E7 | Doctor cannot belong to multiple departments | Single FK to DEPARTMENT table |

---

## 3. Appointment Management Rules

| Rule ID | Rule | Implementation |
|---------|------|----------------|
| BR-A1 | Duplicate appointments not allowed — same patient, slot, date and time | Validated in book_appointment procedure (Validation 4) |
| BR-A2 | Only AVAILABLE schedule slots can be booked | Validated in book_appointment procedure (Validation 2) |
| BR-A3 | Doctor on approved vacation cannot be booked | Validated in book_appointment procedure (Validation 5) |
| BR-A4 | Maximum 5 appointments per doctor per day | Validated in book_appointment procedure (Validation 6) |
| BR-A5 | Appointments cannot be cancelled within 24 hours | Validated in cancel_appointment procedure |
| BR-A6 | Cancelled or completed appointments cannot be rescheduled | Validated in reschedule_appointment procedure |
| BR-A7 | Appointment status must be SCHEDULED, COMPLETED, CANCELLED, or RESCHEDULED | CHECK constraint: APPT_STATUS_CHK |
| BR-A8 | Every appointment change must be logged in APPOINTMENT_HISTORY | Inserted in book/cancel/reschedule procedures |
| BR-A9 | Schedule slot must be released when appointment is cancelled | UPDATE EMPLOYEE_SCHEDULE in cancel_appointment |
| BR-A10 | Old slot released and new slot marked when rescheduled | UPDATE EMPLOYEE_SCHEDULE in reschedule_appointment |

---

## 4. Admission & Bed Management Rules

| Rule ID | Rule | Implementation |
|---------|------|----------------|
| BR-B1 | A patient cannot be admitted to an already occupied bed | trg_occupied_bed — BEFORE INSERT trigger |
| BR-B2 | Bed is automatically marked occupied after admission | trg_mark_bed_occupied — AFTER INSERT trigger |
| BR-B3 | Bed is automatically released when patient is discharged | trg_release_bed_on_discharge — AFTER UPDATE trigger |
| BR-B4 | A patient cannot have more than one ACTIVE admission | Validated in admit_patient procedure |
| BR-B5 | Discharged admission must have a discharge date | Verified in DML/10 Business Rule BR4 |
| BR-B6 | Admission status must be ACTIVE, DISCHARGED, or TRANSFERRED | CHECK constraint: ADM_STATUS_CHK |
| BR-B7 | ICU bed admission requires doctor approval | Enforced by admit_patient — only DOCTOR role can admit |

---

## 5. Insurance Rules

| Rule ID | Rule | Implementation |
|---------|------|----------------|
| BR-I1 | Insurance coverage percentage must be between 0 and 100 | CHECK constraint: INS_COVERAGE_CHK |
| BR-I2 | Insurance policy number must be unique | UNIQUE constraint: INSURANCE_POLICY_NUMBER_UN |
| BR-I3 | A patient cannot have more than one PRIMARY insurance policy | Verified in DML/10 Business Rule BR2 |
| BR-I4 | Insurance validity dates must be valid (valid_to > valid_from) | CHECK constraint: PI_DATE_CHK |
| BR-I5 | Insurance must be active (within valid_from and valid_to) before discount applies | Validated in generate_bill procedure |

---

## 6. Billing & Payment Rules

| Rule ID | Rule | Implementation |
|---------|------|----------------|
| BR-BL1 | Bills with insurance must apply correct discount | Insurance discount applied in generate_bill procedure |
| BR-BL2 | Net amount must equal total amount minus discount | Verified in DML/10 Business Rule BR5 |
| BR-BL3 | Bill status must be PENDING, PAID, PARTIALLY_PAID, or CANCELLED | CHECK constraint: BILL_STATUS_CHK |
| BR-BL4 | Payment amount must be greater than zero | CHECK constraint: PAY_AMT_CHK |
| BR-BL5 | Every bill must be linked to either an admission or appointment | Validated in generate_bill procedure |
| BR-BL6 | No duplicate PENDING bills for same patient and source | Validated in generate_bill procedure |
| BR-BL7 | Total amount must be greater than zero | Validated in generate_bill procedure |

---

## 7. Schedule Rules

| Rule ID | Rule | Implementation |
|---------|------|----------------|
| BR-S1 | Schedule end time must be after start time | CHECK constraint: SCHED_TIME_CHK |
| BR-S2 | Vacation end date must be >= start date | CHECK constraint: VAC_DATE_CHK |
| BR-S3 | Employee schedule status must be AVAILABLE, UNAVAILABLE, or ON_LEAVE | CHECK constraint: EMP_SCHED_STATUS_CHK |
| BR-S4 | Doctor schedule cannot overlap | Enforced by EMPLOYEE_SCHEDULE bridge table structure |

---

## 8. Transaction Validations (Mandatory)

### 8.1 Duplicate Booking Prevention
```
When:   INSERT into APPOINTMENT via book_appointment procedure
Check:  Same patient + same slot + same date + same time + status != CANCELLED
Error:  ORA-20016 — Duplicate appointment not allowed
Where:  book_appointment procedure — Validation 4
```

### 8.2 Occupied Bed Prevention
```
When:   INSERT into ADMISSION
Check:  BED.is_occupied = 'Y'
Error:  ORA-20102 — Bed is already occupied
Where:  trg_occupied_bed trigger — BEFORE INSERT on ADMISSION
```

### 8.3 Insurance Discount
```
When:   INSERT into BILLING via generate_bill procedure
Logic:  Looks up patient primary active insurance
        discount   = total_amount × coverage_pct / 100
        net_amount = total_amount - discount
        Rounded to 2 decimal places
Where:  generate_bill procedure
```

---

## 9. Security & Roles

| User | Role | Access |
|------|------|--------|
| hmsdbadmin | Database Admin | Full system access — runs Security scripts |
| hms_admin | Schema Owner | Full DDL + DML — runs all project scripts |
| hms_operator | Operator | SELECT all 16 tables + INSERT/UPDATE on operational tables |

### Operator Permissions
| Table | SELECT | INSERT | UPDATE |
|-------|--------|--------|--------|
| APPOINTMENT | ✅ | ✅ | ✅ |
| PATIENT | ✅ | ✅ | ✅ |
| ADMISSION | ✅ | ✅ | ✅ |
| BILLING | ✅ | ✅ | ✅ |
| PAYMENT | ✅ | ✅ | ✅ |
| All other 11 tables | ✅ | ❌ | ❌ |

---

## 10. Test Case Results

| Test | Procedure | Scenario | Expected Error | Result |
|------|-----------|----------|----------------|--------|
| 1a | book_appointment | Valid booking | Success | ✅ PASSED |
| 1b | book_appointment | Duplicate booking | ORA-20016 | ✅ PASSED |
| 1c | book_appointment | Non-existent patient | ORA-20010 | ✅ PASSED |
| 1d | book_appointment | Max 5 appointments per day | ORA-20018 | ✅ PASSED |
| 2a | cancel_appointment | Cancel within 24hrs | ORA-20023 | ✅ PASSED |
| 2b | cancel_appointment | Non-existent appointment | ORA-20020 | ✅ PASSED |
| 3a | reschedule_appointment | Slot not available | ORA-20034 | ✅ PASSED |
| 3b | reschedule_appointment | Non-existent appointment | ORA-20030 | ✅ PASSED |
| 4a | admit_patient | Bed already occupied | ORA-20042 | ✅ PASSED |
| 4b | admit_patient | Non-doctor employee | ORA-20045 | ✅ PASSED |
| 4c | admit_patient | Valid admission | Success | ✅ PASSED |
| 5a | generate_bill | Zero amount | ORA-20051 | ✅ PASSED |
| 5b | generate_bill | No source provided | ORA-20052 | ✅ PASSED |
| 5c | generate_bill | Valid bill with insurance | Success | ✅ PASSED |

**14/14 Tests Passed ✅**
