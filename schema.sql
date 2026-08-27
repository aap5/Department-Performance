-- ============================================================
-- HR Workforce Analytics — Schema
-- Single denormalized fact table (typical of an HRIS export).
-- In a production warehouse this would be split into
-- dim_employee / dim_department / fact_employment_events, but a
-- single table mirrors what most analysts actually receive from
-- an HR system export and keeps the SQL approachable.
-- ============================================================

CREATE TABLE employees (
    employee_id                  TEXT PRIMARY KEY,   -- e.g. E10001
    full_name                    TEXT,
    gender                       TEXT,                -- Female / Male
    age                          INTEGER,
    department                   TEXT,
    job_level                    TEXT,                -- Entry..Director
    education                    TEXT,
    hire_date                    DATE,
    termination_date             DATE,                -- NULL if still active
    employment_status            TEXT,                -- Active / Terminated
    termination_reason           TEXT,                -- NULL if still active
    annual_salary                REAL,
    performance_rating           INTEGER,             -- 1 (low) .. 5 (high)
    months_since_last_promotion  INTEGER,
    monthly_overtime_hours       REAL,
    job_satisfaction             REAL,                -- 1.0 (low) .. 5.0 (high)
    commute_miles                REAL,
    work_arrangement             TEXT,                -- Onsite / Hybrid / Remote
    training_hours_last_year     INTEGER
);

CREATE INDEX idx_dept   ON employees(department);
CREATE INDEX idx_status ON employees(employment_status);
