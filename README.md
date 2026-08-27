# Workforce Analytics: Attrition & Pay Equity Review

A complete, portfolio-ready data analyst project: a synthetic HR dataset, a
SQL analysis layer, and a BI-style interactive dashboard — the same
workflow (raw data → SQL → dashboard → written findings) used for a real
People Analytics deliverable.

## 1. Business problem

A mid-size company (1,800 employee records, 8 departments, FY2018–2026)
wants to know:

1. Where is attrition concentrated, and why?
2. Which employees are the highest-value flight risks right now?
3. Is compensation equitable across gender, controlling for job level?

## 2. Project structure

```
hr_project/
├── generate_data.py       # synthetic data generator (seeded, reproducible)
├── hr_workforce_data.csv  # the raw dataset (1,800 rows x 19 columns)
├── schema.sql             # table definition + indexes
├── hr_analytics.db        # SQLite database loaded from the CSV
├── queries.sql            # 14 business-question SQL queries (Q1–Q14)
├── query_results.json     # output of every query, used to power the dashboard
├── dashboard.html         # interactive BI-style dashboard (open in any browser)
└── README.md              # this file
```

## 3. Data

`hr_workforce_data.csv` / `employees` table — one row per employee record,
19 columns: demographics (gender, age, education), job info (department,
job level, hire/termination date, status), performance & engagement
(performance rating, months since last promotion, monthly overtime hours,
job satisfaction, training hours), and logistics (commute miles, work
arrangement).

This is **synthetic data**, generated with a seeded random process so the
project is fully reproducible (`python3 generate_data.py`). Patterns were
built in deliberately — tenure-driven attrition risk, overtime/satisfaction
correlation, a modest gender pay gap — so the SQL analysis has real signal
to find, the same way a real HRIS export would.

## 4. Method

1. **Generate** — `generate_data.py` builds the workforce with realistic
   department mixes, salary bands by job level, and a logistic attrition
   model driven by tenure, performance, overtime, promotion recency, work
   arrangement, and commute distance.
2. **Load** — the CSV is loaded into `hr_analytics.db`, a single
   `employees` table indexed on `department` and `employment_status`
   (see `schema.sql`).
3. **Analyze** — `queries.sql` answers 14 specific business questions
   with pure SQL (aggregations, bucketed CASE statements, window-free
   groupings — deliberately kept to standard SQL any analyst could run
   against a real HRIS export).
4. **Visualize** — `dashboard.html` is a single self-contained HTML file
   (Chart.js) with four tabs — Overview, Attrition, Compensation, Retention
   Risk — reading directly from the query output. No server or build step
   required; open the file in a browser.

## 5. Key findings

**Overall attrition is 18.8%** (338 of 1,800 records), but it is far from
evenly distributed:

- **Department.** Customer Support (29.9%) and Sales (26.9%) run roughly
  4x the attrition rate of Finance (7.5%) and Engineering (10.6%).
- **Tenure is the strongest single driver.** Employees under 1 year on the
  job leave at **47.8%**, dropping to 26.6% in year 1–2, 18.4% in year 2–4,
  and just 1.0% past year 7. The first 12 months is where retention effort
  has the most leverage.
- **Overtime tracks with both attrition and satisfaction.** Attrition rises
  from 12.8% (under 5 hrs/month overtime) to 43.8% (25+ hrs/month), while
  average satisfaction falls from 3.41 to 2.89 over the same range.
- **Remote workers churn less** (14.9%) than hybrid (18.2%) or onsite
  (21.6%) staff — worth investigating whether this is a work-arrangement
  effect or a confound with role/department.
- **Departures split roughly evenly between voluntary and involuntary.**
  "Better opportunity" is the single largest reason (30.2% of exits), but
  involuntary performance-related exits (27.8%) and restructuring (18.0%)
  together account for nearly half of all separations — a meaningful
  signal for hiring-quality and workforce-planning conversations,
  respectively.
- **Pay equity.** A modest gender pay gap favoring men appears at every
  job level (1.4%–5.8%, average ~3.6%), widest at Associate and Lead. It's
  not extreme, but it's consistent rather than random, which is the
  pattern worth flagging in a real compensation audit.
- **Actionable shortlist.** The dashboard's Retention Risk tab surfaces 25
  active, high-performing employees (rating ≥ 4) with satisfaction ≤ 2.5 —
  a ready-made outreach list for HR business partners.

## 6. How to reproduce / extend

```bash
python3 generate_data.py          # regenerate the dataset
sqlite3 hr_analytics.db < schema.sql   # (if rebuilding the DB from scratch)
sqlite3 hr_analytics.db            # then run any query from queries.sql interactively
```

Open `dashboard.html` directly in a browser — it has no dependencies beyond
two CDN-hosted libraries (Google Fonts, Chart.js) and works fully offline
once those are cached.

**Natural next steps** for extending this into a larger project: swap in a
real HRIS export, add a `dim_department` table with headcount budgets to
compute over/under-staffing, or layer in a simple logistic regression in
Python to turn the descriptive attrition drivers here into a predictive
flight-risk score per employee.
