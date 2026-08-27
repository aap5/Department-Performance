-- ============================================================
-- HR Workforce Analytics — Analysis Queries
-- Run against hr_analytics.db (SQLite). Each query answers a
-- specific business question a People/HR team would ask.
-- ============================================================

-- ------------------------------------------------------------
-- Q1. Headcount & attrition rate by department
-- ------------------------------------------------------------
SELECT
    department,
    COUNT(*)                                                   AS total_ever_employed,
    SUM(CASE WHEN employment_status = 'Active' THEN 1 ELSE 0 END)      AS current_headcount,
    SUM(CASE WHEN employment_status = 'Terminated' THEN 1 ELSE 0 END)  AS separations,
    ROUND(100.0 * SUM(CASE WHEN employment_status = 'Terminated' THEN 1 ELSE 0 END)
          / COUNT(*), 1)                                        AS attrition_rate_pct
FROM employees
GROUP BY department
ORDER BY attrition_rate_pct DESC;

-- ------------------------------------------------------------
-- Q2. Company-wide attrition rate (headline KPI)
-- ------------------------------------------------------------
SELECT
    ROUND(100.0 * SUM(CASE WHEN employment_status = 'Terminated' THEN 1 ELSE 0 END)
          / COUNT(*), 1) AS overall_attrition_rate_pct,
    COUNT(*) AS total_ever_employed,
    SUM(CASE WHEN employment_status = 'Active' THEN 1 ELSE 0 END) AS current_headcount
FROM employees;

-- ------------------------------------------------------------
-- Q3. Attrition rate by tenure bucket ("flight risk window")
-- ------------------------------------------------------------
SELECT
    CASE
        WHEN tenure_years < 1  THEN '0. Under 1 year'
        WHEN tenure_years < 2  THEN '1. 1-2 years'
        WHEN tenure_years < 4  THEN '2. 2-4 years'
        WHEN tenure_years < 7  THEN '3. 4-7 years'
        ELSE '4. 7+ years'
    END AS tenure_bucket,
    COUNT(*) AS headcount,
    ROUND(100.0 * SUM(CASE WHEN employment_status = 'Terminated' THEN 1 ELSE 0 END)
          / COUNT(*), 1) AS attrition_rate_pct
FROM (
    SELECT *,
        (JULIANDAY(COALESCE(termination_date, '2026-08-26')) - JULIANDAY(hire_date)) / 365.25 AS tenure_years
    FROM employees
)
GROUP BY tenure_bucket
ORDER BY tenure_bucket;

-- ------------------------------------------------------------
-- Q4. Attrition rate by performance rating
-- ------------------------------------------------------------
SELECT
    performance_rating,
    COUNT(*) AS headcount,
    ROUND(100.0 * SUM(CASE WHEN employment_status = 'Terminated' THEN 1 ELSE 0 END)
          / COUNT(*), 1) AS attrition_rate_pct
FROM employees
GROUP BY performance_rating
ORDER BY performance_rating;

-- ------------------------------------------------------------
-- Q5. Attrition rate by monthly overtime bucket
-- ------------------------------------------------------------
SELECT
    CASE
        WHEN monthly_overtime_hours < 5   THEN '0. <5 hrs'
        WHEN monthly_overtime_hours < 15  THEN '1. 5-15 hrs'
        WHEN monthly_overtime_hours < 25  THEN '2. 15-25 hrs'
        ELSE '3. 25+ hrs'
    END AS overtime_bucket,
    COUNT(*) AS headcount,
    ROUND(100.0 * SUM(CASE WHEN employment_status = 'Terminated' THEN 1 ELSE 0 END)
          / COUNT(*), 1) AS attrition_rate_pct,
    ROUND(AVG(job_satisfaction), 2) AS avg_satisfaction
FROM employees
GROUP BY overtime_bucket
ORDER BY overtime_bucket;

-- ------------------------------------------------------------
-- Q6. Attrition rate by work arrangement (onsite/hybrid/remote)
-- ------------------------------------------------------------
SELECT
    work_arrangement,
    COUNT(*) AS headcount,
    ROUND(100.0 * SUM(CASE WHEN employment_status = 'Terminated' THEN 1 ELSE 0 END)
          / COUNT(*), 1) AS attrition_rate_pct
FROM employees
GROUP BY work_arrangement
ORDER BY attrition_rate_pct DESC;

-- ------------------------------------------------------------
-- Q7. Pay equity check — average salary by gender within each
--     job level (controls for level so it's an apples-to-apples
--     comparison, not just a raw average).
-- ------------------------------------------------------------
SELECT
    job_level,
    ROUND(AVG(CASE WHEN gender = 'Male'   THEN annual_salary END), 0) AS avg_salary_male,
    ROUND(AVG(CASE WHEN gender = 'Female' THEN annual_salary END), 0) AS avg_salary_female,
    ROUND(100.0 * (AVG(CASE WHEN gender = 'Male' THEN annual_salary END)
          - AVG(CASE WHEN gender = 'Female' THEN annual_salary END))
          / AVG(CASE WHEN gender = 'Female' THEN annual_salary END), 1) AS pct_gap_male_over_female
FROM employees
WHERE employment_status = 'Active'
GROUP BY job_level
ORDER BY CASE job_level
    WHEN 'Entry' THEN 1 WHEN 'Associate' THEN 2 WHEN 'Senior' THEN 3
    WHEN 'Lead' THEN 4 WHEN 'Manager' THEN 5 WHEN 'Director' THEN 6 END;

-- ------------------------------------------------------------
-- Q8. Average tenure at exit: active employees vs. those who left
-- ------------------------------------------------------------
SELECT
    employment_status,
    ROUND(AVG((JULIANDAY(COALESCE(termination_date, '2026-08-26')) - JULIANDAY(hire_date)) / 365.25), 1)
        AS avg_tenure_years
FROM employees
GROUP BY employment_status;

-- ------------------------------------------------------------
-- Q9. Top reasons employees left (voluntary vs involuntary mix)
-- ------------------------------------------------------------
SELECT
    termination_reason,
    COUNT(*) AS count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM employees WHERE employment_status = 'Terminated'), 1)
        AS pct_of_all_departures
FROM employees
WHERE employment_status = 'Terminated'
GROUP BY termination_reason
ORDER BY count DESC;

-- ------------------------------------------------------------
-- Q10. Time-since-last-promotion vs attrition ("stagnation risk")
-- ------------------------------------------------------------
SELECT
    CASE
        WHEN months_since_last_promotion < 12 THEN '0. <12 mo'
        WHEN months_since_last_promotion < 24 THEN '1. 12-24 mo'
        WHEN months_since_last_promotion < 36 THEN '2. 24-36 mo'
        ELSE '3. 36+ mo'
    END AS months_since_promo_bucket,
    COUNT(*) AS headcount,
    ROUND(100.0 * SUM(CASE WHEN employment_status = 'Terminated' THEN 1 ELSE 0 END)
          / COUNT(*), 1) AS attrition_rate_pct
FROM employees
GROUP BY months_since_promo_bucket
ORDER BY months_since_promo_bucket;

-- ------------------------------------------------------------
-- Q11. Median & average salary by department (active employees)
-- ------------------------------------------------------------
SELECT
    department,
    COUNT(*) AS headcount,
    ROUND(AVG(annual_salary), 0) AS avg_salary
FROM employees
WHERE employment_status = 'Active'
GROUP BY department
ORDER BY avg_salary DESC;

-- ------------------------------------------------------------
-- Q12. Hiring trend by year
-- ------------------------------------------------------------
SELECT
    CAST(STRFTIME('%Y', hire_date) AS INTEGER) AS hire_year,
    COUNT(*) AS hires
FROM employees
GROUP BY hire_year
ORDER BY hire_year;

-- ------------------------------------------------------------
-- Q13. High performers at flight risk
--      (rating >= 4, satisfaction <= 2.5, still active) —
--      the list a retention program should act on first.
-- ------------------------------------------------------------
SELECT
    employee_id, full_name, department, job_level, performance_rating,
    job_satisfaction, monthly_overtime_hours, months_since_last_promotion
FROM employees
WHERE employment_status = 'Active'
  AND performance_rating >= 4
  AND job_satisfaction <= 2.5
ORDER BY job_satisfaction ASC, performance_rating DESC
LIMIT 25;

-- ------------------------------------------------------------
-- Q14. Job-level distribution of current headcount
-- ------------------------------------------------------------
SELECT
    job_level,
    COUNT(*) AS headcount,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM employees WHERE employment_status = 'Active'), 1) AS pct_of_workforce
FROM employees
WHERE employment_status = 'Active'
GROUP BY job_level
ORDER BY CASE job_level
    WHEN 'Entry' THEN 1 WHEN 'Associate' THEN 2 WHEN 'Senior' THEN 3
    WHEN 'Lead' THEN 4 WHEN 'Manager' THEN 5 WHEN 'Director' THEN 6 END;
