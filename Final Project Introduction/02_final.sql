```sql
CREATE DATABASE dental_clinic_db;

CREATE SCHEMA dental_clinic;

SET search_path TO dental_clinic;

CREATE TABLE insurance_plans (
    plan_id SERIAL PRIMARY KEY,
    provider_name VARCHAR(100) NOT NULL,
    coverage_percent NUMERIC(5,2) NOT NULL
        CHECK (coverage_percent >= 0 AND coverage_percent <= 100),
    monthly_cost NUMERIC(10,2) NOT NULL
        CHECK (monthly_cost >= 0)
);

CREATE TABLE patients (
    patient_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    gender VARCHAR(10) NOT NULL
        CHECK (gender IN ('Male', 'Female', 'Other')),
    birth_date DATE NOT NULL,
    phone VARCHAR(20) NOT NULL UNIQUE,
    email VARCHAR(120) UNIQUE,
    insurance_plan_id INT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_patient_insurance
        FOREIGN KEY (insurance_plan_id)
        REFERENCES insurance_plans(plan_id)
        ON DELETE SET NULL
);

CREATE TABLE dentists (
    dentist_id SERIAL PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    specialization VARCHAR(80) NOT NULL,
    salary NUMERIC(10,2) NOT NULL
        CHECK (salary >= 0),
    hire_date DATE NOT NULL
        CHECK (hire_date > '2026-01-01'),
    license_number VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE procedures (
    procedure_id SERIAL PRIMARY KEY,
    procedure_name VARCHAR(100) NOT NULL UNIQUE,
    base_price NUMERIC(10,2) NOT NULL
        CHECK (base_price >= 0),
    duration_minutes INT NOT NULL
        CHECK (duration_minutes > 0)
);

CREATE TABLE appointments (
    appointment_id SERIAL PRIMARY KEY,
    patient_id INT NOT NULL,
    dentist_id INT NOT NULL,
    appointment_date TIMESTAMP NOT NULL,
    status VARCHAR(20) NOT NULL
        CHECK (status IN ('Scheduled', 'Completed', 'Cancelled')),
    notes TEXT,

    CONSTRAINT fk_appointment_patient
        FOREIGN KEY (patient_id)
        REFERENCES patients(patient_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_appointment_dentist
        FOREIGN KEY (dentist_id)
        REFERENCES dentists(dentist_id)
        ON DELETE RESTRICT
);

CREATE TABLE appointment_procedures (
    appointment_id INT NOT NULL,
    procedure_id INT NOT NULL,
    quantity INT NOT NULL DEFAULT 1
        CHECK (quantity > 0),

    unit_price NUMERIC(10,2) NOT NULL
        CHECK (unit_price >= 0),

    total_price NUMERIC(10,2)
        GENERATED ALWAYS AS (quantity * unit_price) STORED,

    PRIMARY KEY (appointment_id, procedure_id),

    CONSTRAINT fk_ap_appointment
        FOREIGN KEY (appointment_id)
        REFERENCES appointments(appointment_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_ap_procedure
        FOREIGN KEY (procedure_id)
        REFERENCES procedures(procedure_id)
        ON DELETE RESTRICT
);

CREATE TABLE invoices (
    invoice_id SERIAL PRIMARY KEY,
    appointment_id INT NOT NULL UNIQUE,
    total_amount NUMERIC(10,2) NOT NULL
        CHECK (total_amount >= 0),

    payment_status VARCHAR(20) NOT NULL
        CHECK (payment_status IN ('Paid', 'Pending', 'Overdue')),

    issued_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_invoice_appointment
        FOREIGN KEY (appointment_id)
        REFERENCES appointments(appointment_id)
        ON DELETE CASCADE
);

CREATE TABLE treatment_history (
    history_id SERIAL PRIMARY KEY,
    patient_id INT NOT NULL,
    diagnosis TEXT NOT NULL,
    treatment_notes TEXT,
    recorded_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_history_patient
        FOREIGN KEY (patient_id)
        REFERENCES patients(patient_id)
        ON DELETE RESTRICT
);


ALTER TABLE patients
ADD COLUMN emergency_contact VARCHAR(100);

ALTER TABLE appointments
RENAME COLUMN notes TO appointment_notes;

ALTER TABLE patients
ALTER COLUMN phone TYPE VARCHAR(25);

ALTER TABLE appointments
ALTER COLUMN status SET DEFAULT 'Scheduled';

ALTER TABLE dentists
ADD CONSTRAINT unique_full_name UNIQUE(full_name);


-- insurance_plans
INSERT INTO insurance_plans (
    provider_name,
    coverage_percent,
    monthly_cost
)
VALUES
('DentalCare Plus', 80.00, 25000),
('Smile Protect', 60.00, 18000),
('HealthDent Premium', 90.00, 32000);

-- patients
INSERT INTO patients (
    first_name,
    last_name,
    gender,
    birth_date,
    phone,
    email,
    insurance_plan_id
)
VALUES
(
    'Korkem',
    'Igilik',
    'Female',
    '2005-03-15',
    '+77010000001',
    'korkem@mail.com',
    (
        SELECT plan_id
        FROM insurance_plans
        WHERE provider_name = 'DentalCare Plus'
    )
),
(
    'Aktoty',
    'Shahmet',
    'Female',
    '2005-06-20',
    '+77010000002',
    'aktoty@mail.com',
    (
        SELECT plan_id
        FROM insurance_plans
        WHERE provider_name = 'Smile Protect'
    )
),
(
    'Arnur',
    'Kamai',
    'Male',
    '2004-09-10',
    '+77010000003',
    'arnur@mail.com',
    (
        SELECT plan_id
        FROM insurance_plans
        WHERE provider_name = 'HealthDent Premium'
    )
),
(
    'Aruzhan',
    'Tolegenova',
    'Female',
    '2005-01-25',
    '+77010000004',
    'aruzhan@mail.com',
    (
        SELECT plan_id
        FROM insurance_plans
        WHERE provider_name = 'DentalCare Plus'
    )
);

-- dentists
INSERT INTO dentists (
    full_name,
    specialization,
    salary,
    hire_date,
    license_number
)
VALUES
(
    'Dr. Ermekov Dias',
    'Orthodontist',
    850000,
    '2026-02-15',
    'DNT-2026-001'
),
(
    'Dr. Rakhym Kundyz',
    'Therapist',
    720000,
    '2026-03-10',
    'DNT-2026-002'
);

-- procedures
INSERT INTO procedures (
    procedure_name,
    base_price,
    duration_minutes
)
VALUES
('Teeth Cleaning', 15000, 40),
('Root Canal', 55000, 120),
('Dental Filling', 22000, 60);

-- appointments
INSERT INTO appointments (
    patient_id,
    dentist_id,
    appointment_date,
    status,
    appointment_notes
)
VALUES
(
    (
        SELECT patient_id
        FROM patients
        WHERE phone = '+77010000001'
    ),
    (
        SELECT dentist_id
        FROM dentists
        WHERE license_number = 'DNT-2026-001'
    ),
    '2026-06-10 14:00:00',
    'Scheduled',
    'Initial consultation'
),
(
    (
        SELECT patient_id
        FROM patients
        WHERE phone = '+77010000002'
    ),
    (
        SELECT dentist_id
        FROM dentists
        WHERE license_number = 'DNT-2026-002'
    ),
    '2026-06-12 10:30:00',
    'Completed',
    'Tooth pain treatment'
);

-- appointment_procedures
INSERT INTO appointment_procedures (
    appointment_id,
    procedure_id,
    quantity,
    unit_price
)
VALUES
(
    (
        SELECT appointment_id
        FROM appointments
        WHERE appointment_date = '2026-06-10 14:00:00'
    ),
    (
        SELECT procedure_id
        FROM procedures
        WHERE procedure_name = 'Teeth Cleaning'
    ),
    1,
    15000
),
(
    (
        SELECT appointment_id
        FROM appointments
        WHERE appointment_date = '2026-06-12 10:30:00'
    ),
    (
        SELECT procedure_id
        FROM procedures
        WHERE procedure_name = 'Root Canal'
    ),
    1,
    55000
);

-- invoices
INSERT INTO invoices (
    appointment_id,
    total_amount,
    payment_status
)
VALUES
(
    (
        SELECT appointment_id
        FROM appointments
        WHERE appointment_date = '2026-06-10 14:00:00'
    ),
    15000,
    'Pending'
),
(
    (
        SELECT appointment_id
        FROM appointments
        WHERE appointment_date = '2026-06-12 10:30:00'
    ),
    55000,
    'Paid'
);

-- treatment_history
INSERT INTO treatment_history (
    patient_id,
    diagnosis,
    treatment_notes
)
VALUES
(
    (
        SELECT patient_id
        FROM patients
        WHERE phone = '+77010000001'
    ),
    'Mild plaque buildup',
    'Professional cleaning recommended every 6 months'
),
(
    (
        SELECT patient_id
        FROM patients
        WHERE phone = '+77010000002'
    ),
    'Deep tooth infection',
    'Root canal successfully completed'
);


UPDATE procedures
SET base_price = 60000
WHERE procedure_name = 'Root Canal';

UPDATE appointments
SET status = 'Completed'
WHERE appointment_id = 1;


DELETE FROM appointments
WHERE status = 'Cancelled';

DELETE FROM treatment_history
WHERE recorded_at < '2026-01-01';


CREATE ROLE receptionist_role;

GRANT SELECT, INSERT, UPDATE
ON patients, appointments, invoices
TO receptionist_role;

CREATE USER receptionist_user
WITH PASSWORD 'clinic123';

GRANT receptionist_role
TO receptionist_user;

REVOKE UPDATE
ON invoices
FROM receptionist_role;

SELECT * FROM patients;
SELECT * FROM dentists;
SELECT * FROM appointments;
SELECT * FROM invoices;
```
