-- Insert Departments

INSERT INTO DEPARTMENT VALUES (department_seq.NEXTVAL, 'Cardiology', 'Building A, Floor 2', '555-0001');
INSERT INTO DEPARTMENT VALUES (department_seq.NEXTVAL, 'Neurology', 'Building A, Floor 3', '555-0002');
INSERT INTO DEPARTMENT VALUES (department_seq.NEXTVAL, 'Orthopedics', 'Building B, Floor 1', '555-0003');
INSERT INTO DEPARTMENT VALUES (department_seq.NEXTVAL, 'Pediatrics', 'Building B, Floor 2', '555-0004');
INSERT INTO DEPARTMENT VALUES (department_seq.NEXTVAL, 'General Medicine', 'Building C, Floor 1', '555-0005');
COMMIT;

select * from department;