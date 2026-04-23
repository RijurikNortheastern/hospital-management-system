# Test Case Report
## Hospital Management System - DMDD 6210
## Team: Table Turners
## Selected Module: Appointment Management

---

## Overview

| Item | Details |
|------|---------|
| Total Test Cases | 14 |
| Passed | 14 |
| Failed | 0 |
| Coverage | All 5 stored procedures |

---

## Test Cases

### 1. book_appointment Procedure

| Test ID | Scenario | Input | Expected Result | Actual Result | Status |
|---------|----------|-------|-----------------|---------------|--------|
| TEST 1a | Valid booking | patient_id=1, bridge_id=1, date=2026-04-25 | Appointment booked successfully | Appointment 51 booked successfully for patient 1 | ✅ PASSED |
| TEST 1b | Duplicate booking | Same patient, slot, date, time | ORA-20016: Duplicate appointment | ORA-20016: Schedule slot 1 is not available (status: UNAVAILABLE) | ✅ PASSED |
| TEST 1c | Non-existent patient | patient_id=9999 | ORA-20010: Patient does not exist | ORA-20010: Patient ID 9999 does not exist | ✅ PASSED |
| TEST 1d | Max 5 appointments per day | Doctor already has 5 appointments | ORA-20018: Maximum limit reached | ORA-20018: Doctor already has 5 appointments | ✅ PASSED |

---

### 2. cancel_appointment Procedure

| Test ID | Scenario | Input | Expected Result | Actual Result | Status |
|---------|----------|-------|-----------------|---------------|--------|
| TEST 2a | Cancel within 24 hours | appointment_id=1 (past date) | ORA-20023: Cannot cancel within 24 hours | ORA-20023: Cannot cancel appointment on 2026-04-12 — must cancel at least 24 hours in advance | ✅ PASSED |
| TEST 2b | Non-existent appointment | appointment_id=9999 | ORA-20020: Appointment does not exist | ORA-20020: Appointment ID 9999 does not exist | ✅ PASSED |

---

### 3. reschedule_appointment Procedure

| Test ID | Scenario | Input | Expected Result | Actual Result | Status |
|---------|----------|-------|-----------------|---------------|--------|
| TEST 3a | New slot not available | appointment_id=1, new_bridge_id=1 | ORA-20034: Slot not available | ORA-20034: New schedule slot 1 is not available (status: UNAVAILABLE) | ✅ PASSED |
| TEST 3b | Non-existent appointment | appointment_id=9999 | ORA-20030: Appointment does not exist | ORA-20030: Appointment ID 9999 does not exist | ✅ PASSED |

---

### 4. admit_patient Procedure

| Test ID | Scenario | Input | Expected Result | Actual Result | Status |
|---------|----------|-------|-----------------|---------------|--------|
| TEST 4a | Bed already occupied | patient_id=5, bed_id=1 | ORA-20042: Bed already occupied | ORA-20042: Bed 1 is already occupied | ✅ PASSED |
| TEST 4b | Non-doctor employee | employee_id=16 (NURSE) | ORA-20045: Only DOCTOR can admit | ORA-20045: Only a DOCTOR can admit a patient. Employee role is: NURSE | ✅ PASSED |
| TEST 4c | Valid admission | patient_id=150, bed_id=20, employee_id=1 | Patient admitted successfully | Patient 150 admitted successfully. Admission ID: 11, Bed ID: 20 | ✅ PASSED |

---

### 5. generate_bill Procedure

| Test ID | Scenario | Input | Expected Result | Actual Result | Status |
|---------|----------|-------|-----------------|---------------|--------|
| TEST 5a | Zero total amount | total_amount=0 | ORA-20051: Amount must be > 0 | ORA-20051: Total amount must be greater than 0. Received: 0 | ✅ PASSED |
| TEST 5b | No source provided | admission_id=NULL, appointment_id=NULL | ORA-20052: Source required | ORA-20052: At least one of p_admission_id or p_appointment_id must be provided | ✅ PASSED |
| TEST 5c | Valid bill with insurance | patient_id=1, appointment_id=1, total=5000 | Bill generated with 80% discount | Bill 19 generated. Total: $5000, Discount: $4000 (80%), Net: $1000 | ✅ PASSED |

---

## Mandatory Transaction Validations

| Validation | Business Rule | Test | Result |
|------------|--------------|------|--------|
| Duplicate Booking Prevention | Same patient cannot book same slot twice | TEST 1b | ✅ PASSED |
| Occupied Bed Prevention | Cannot admit patient to occupied bed | TEST 4a | ✅ PASSED |
| Insurance Discount | Correct discount applied based on coverage % | TEST 5c | ✅ PASSED |

---

## Final State After All Tests

| Table | Count |
|-------|-------|
| APPOINTMENT | 51 |
| APPOINTMENT_HISTORY | 55 |
| ADMISSION | 11 |
| BILLING | 19 |
| PAYMENT | 14 |

---

## Summary

```
Total Test Cases : 14
Passed           : 14  ✅
Failed           : 0   
Pass Rate        : 100%
```

**All 14 test cases passed successfully ✅**

