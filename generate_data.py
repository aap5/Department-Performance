"""
Generate a synthetic HR workforce analytics dataset.
Designed to have realistic, discoverable patterns (not pure noise) so that
SQL analysis surfaces genuine insights:
  - Sales & Field Ops have higher attrition than Engineering/Finance
  - Low performance + no recent raise -> higher attrition
  - High overtime hours correlate with higher attrition and lower satisfaction
  - Gender pay gap present but modest within same role/level (for a realistic
    equity analysis)
  - Attrition risk climbs sharply after 1 year without promotion
"""
import numpy as np
import pandas as pd
from datetime import date, timedelta

rng = np.random.default_rng(42)
N = 1800

departments = {
    "Engineering":   {"weight": 0.20, "base_attrition": 0.09, "base_salary": 105000},
    "Sales":         {"weight": 0.18, "base_attrition": 0.22, "base_salary": 78000},
    "Customer Support": {"weight": 0.15, "base_attrition": 0.24, "base_salary": 52000},
    "Operations":    {"weight": 0.14, "base_attrition": 0.16, "base_salary": 60000},
    "Marketing":     {"weight": 0.09, "base_attrition": 0.13, "base_salary": 74000},
    "Finance":       {"weight": 0.08, "base_attrition": 0.07, "base_salary": 88000},
    "HR":            {"weight": 0.06, "base_attrition": 0.10, "base_salary": 68000},
    "IT":            {"weight": 0.10, "base_attrition": 0.11, "base_salary": 82000},
}

job_levels = ["Entry", "Associate", "Senior", "Lead", "Manager", "Director"]
level_multiplier = {"Entry": 0.75, "Associate": 1.0, "Senior": 1.3, "Lead": 1.55, "Manager": 1.9, "Director": 2.6}
level_weights = [0.22, 0.28, 0.24, 0.13, 0.10, 0.03]

education = ["High School", "Associate Degree", "Bachelor's", "Master's", "PhD"]
education_weights = [0.10, 0.14, 0.48, 0.24, 0.04]

first_names_m = ["James","Michael","Robert","John","David","William","Richard","Joseph","Thomas","Christopher",
                  "Daniel","Paul","Mark","Anthony","Steven","Kevin","Brian","George","Edward","Ronald",
                  "Jason","Jeffrey","Ryan","Jacob","Gary","Nicholas","Eric","Jonathan","Stephen","Larry"]
first_names_f = ["Mary","Patricia","Jennifer","Linda","Elizabeth","Barbara","Susan","Jessica","Sarah","Karen",
                  "Nancy","Lisa","Margaret","Betty","Sandra","Ashley","Kimberly","Emily","Donna","Michelle",
                  "Carol","Amanda","Melissa","Deborah","Stephanie","Rebecca","Laura","Sharon","Cynthia","Amy"]
last_names = ["Smith","Johnson","Williams","Brown","Jones","Garcia","Miller","Davis","Rodriguez","Martinez",
              "Hernandez","Lopez","Gonzalez","Wilson","Anderson","Thomas","Taylor","Moore","Jackson","Martin",
              "Lee","Perez","Thompson","White","Harris","Sanchez","Clark","Ramirez","Lewis","Robinson",
              "Walker","Young","Allen","King","Wright","Scott","Torres","Nguyen","Hill","Flores"]

dept_names = list(departments.keys())
dept_p = [departments[d]["weight"] for d in dept_names]
dept_p = np.array(dept_p) / np.sum(dept_p)

today = date(2026, 8, 26)

rows = []
for i in range(1, N + 1):
    emp_id = f"E{10000+i}"
    gender = rng.choice(["Female", "Male"], p=[0.49, 0.51])
    first = rng.choice(first_names_f if gender == "Female" else first_names_m)
    last = rng.choice(last_names)
    name = f"{first} {last}"

    dept = rng.choice(dept_names, p=dept_p)
    level = rng.choice(job_levels, p=level_weights)

    # Tenure: hire date between 8 years ago and 1 month ago
    tenure_days = int(rng.uniform(30, 8 * 365))
    hire_date = today - timedelta(days=tenure_days)
    tenure_years = tenure_days / 365.25

    level_age_bump = {"Entry": 0, "Associate": 3, "Senior": 7, "Lead": 10, "Manager": 13, "Director": 18}[level]
    age = int(np.clip(rng.normal(loc=25 + tenure_years + level_age_bump, scale=5), 21, 65))

    edu = rng.choice(education, p=education_weights)

    # Salary: base * level multiplier * dept factor * small experience bump * noise
    base = departments[dept]["base_salary"]
    salary = base * level_multiplier[level] * (1 + 0.015 * min(tenure_years, 10))
    # modest, realistic gender gap (~4-6%) baked in on average -- used for equity analysis
    if gender == "Male":
        salary *= rng.normal(1.045, 0.03)
    else:
        salary *= rng.normal(1.0, 0.03)
    salary = round(float(np.clip(salary, 34000, 260000)), -2)

    # Performance rating 1-5 (5 best), skewed to 3
    perf = int(np.clip(rng.normal(3.3, 0.9), 1, 5))

    # Months since last promotion/raise
    months_since_promo = int(np.clip(rng.exponential(scale=18), 0, min(tenure_days / 30, 96)))

    # Overtime hours per month
    overtime_base = {"Sales": 14, "Customer Support": 16, "Operations": 12, "Engineering": 8,
                      "Marketing": 7, "Finance": 6, "HR": 5, "IT": 9}[dept]
    overtime_hours = float(np.clip(rng.normal(overtime_base, 5), 0, 45))

    # Satisfaction 1-5, driven down by overtime & up by performance/pay recency
    satisfaction = np.clip(
        3.6 - 0.03 * overtime_hours + 0.15 * (perf - 3) - 0.01 * months_since_promo + rng.normal(0, 0.6),
        1, 5
    )
    satisfaction = round(float(satisfaction), 1)

    commute_miles = round(float(np.clip(rng.exponential(scale=9), 0.5, 60)), 1)
    remote = rng.choice(["Onsite", "Hybrid", "Remote"], p=[0.35, 0.45, 0.20])

    training_hours = int(np.clip(rng.normal(20, 10), 0, 80))

    # ---- Attrition model ----
    base_attr = departments[dept]["base_attrition"]
    logit = np.log(base_attr / (1 - base_attr))
    logit += 0.55 if tenure_years < 1 else 0.0
    logit += 0.35 if (perf <= 2) else (-0.25 if perf >= 4 else 0)
    logit += 0.02 * max(overtime_hours - 10, 0)
    logit += 0.015 * max(months_since_promo - 18, 0)
    logit += -0.35 if remote == "Remote" else (0.05 if remote == "Onsite" else 0)
    logit += -0.20 * (satisfaction - 3)
    logit += 0.10 if commute_miles > 25 else 0
    p_attr = 1 / (1 + np.exp(-logit))
    p_attr = float(np.clip(p_attr, 0.01, 0.85))
    attrited = rng.random() < p_attr

    if attrited:
        # left sometime after hire, before today, weighted toward later tenure but can be early
        min_days_employed = 30
        days_employed = int(rng.uniform(min_days_employed, tenure_days))
        term_date = hire_date + timedelta(days=days_employed)
        if term_date > today:
            term_date = today
        status = "Terminated"
        term_reason = rng.choice(
            ["Voluntary - Better Opportunity", "Voluntary - Personal", "Voluntary - Relocation",
             "Involuntary - Performance", "Involuntary - Restructuring"],
            p=[0.34, 0.16, 0.10, 0.22, 0.18]
        )
    else:
        term_date = None
        status = "Active"
        term_reason = None

    rows.append(dict(
        employee_id=emp_id, full_name=name, gender=gender, age=age,
        department=dept, job_level=level, education=education if False else edu,
        hire_date=hire_date.isoformat(),
        termination_date=term_date.isoformat() if term_date else None,
        employment_status=status, termination_reason=term_reason,
        annual_salary=salary, performance_rating=perf,
        months_since_last_promotion=months_since_promo,
        monthly_overtime_hours=round(overtime_hours, 1),
        job_satisfaction=satisfaction, commute_miles=commute_miles,
        work_arrangement=remote, training_hours_last_year=training_hours,
    ))

df = pd.DataFrame(rows)
df.to_csv("/home/claude/hr_project/hr_workforce_data.csv", index=False)
print(df.shape)
print(df["employment_status"].value_counts())
print(df.groupby("department")["employment_status"].apply(lambda s: (s == "Terminated").mean()).sort_values(ascending=False))
