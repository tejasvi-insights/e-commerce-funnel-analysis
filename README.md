# E-Commerce Funnel Analysis
### Electronics Store — Conversion Funnel, Brand Intelligence & Revenue Patterns
![Python](https://img.shields.io/badge/Python-3.12-blue)
![SQL](https://img.shields.io/badge/PostgreSQL-Analytics-blue)
![Power BI](https://img.shields.io/badge/PowerBI-Dashboard-yellow)
![License](https://img.shields.io/badge/License-MIT-green)
--


End-to-end **funnel analytics project** analyzing 884K+ real e-commerce events across 5 months (Sep 2020 – Feb 2021) from an electronics store using PostgreSQL, Python, and Power BI.
The goal is to identify where users drop off in the purchase journey (view → cart → purchase), understand what drives conversion  
The analysis focuses on **conversion drop-off, brand and category performance, price optimisation, and user behaviour patterns**.

![Dashboard Preview](images/dashboard_preview.png)

---

**Business questions answered:** 

This project builds a complete analytics pipeline from raw clickstream data to an executive business dashboard.

- Where in the funnel do we lose the most users?
- Which brands and categories convert best and worst?
- What price range drives the most revenue and highest conversion?
- When are users most likely to purchase?
- Do returning users convert at a higher rate?

---
### Key Highlights

- **Analyzed 884,312 real user events** across 407K users (Sep 2020 – Feb 2021)
- **Identified 90.92% drop-off at View → Cart** — the core conversion problem
- **Discovered upper-mid products ($200–$499) drive 50% of revenue** despite 21% of purchases
- **Found multi-session users convert at 4.6x the rate** of single-session visitors
- **Revenue grew 15x** from $96K (Sep 2020) to $1.49M (Jan 2021)
- **GPU brands convert 3x above store average** — sapphire leads at 15.90%

---

## Project Architecture

```
Raw CSV (885K rows)
        ↓
PostgreSQL (Data ingestion & validation)
        ↓
Python Notebooks (Data cleaning & feature engineering)
        ↓
PostgreSQL Table (events_clean — 884,312 rows)
        ↓
SQL Analysis (6 scripts — funnel, brand, category, price, session, time)
        ↓
Python EDA (5 notebooks — 20 charts exported)
        ↓
Power BI Dashboard (3 pages — live PostgreSQL connection)
```

---

## Repository Structure

```
e-commerce_funnel_analysis/
│
├── data/
│   ├── events.csv                     # Raw dataset
│   └── events_clean.csv               # Cleaned dataset
│
├── sql/
│   ├──	data_overview                  # Data Overview
│   ├── 01_funnel_dropoff.sql          # Core funnel metrics
│   ├── 02_brand_funnel.sql            # Brand conversion analysis
│   ├── 03_category_funnel.sql         # Category performance
│   ├── 04_price_analysis.sql          # Price segment analysis
│   ├── 05_session_analysis.sql        # Session & user behaviour
│   └── 06_time_trends.sql             # Time-based trends
│
├── python/
│   ├── db_connection.py               # PostgreSQL connection module
│   ├── 01_data_preparation.ipynb      # Data loading & cleaning
│   ├── 02_funnel_analysis.ipynb       # Funnel visualisations
│   ├── 03_brand_analysis.ipynb        # Brand charts
│   ├── 04_category_analysis.ipynb     # Category charts
│   ├── 05_price_analysis.ipynb        # Price segment charts
│   └── 06_time_trends.ipynb           # Time trend charts
│
├── images/                            # All exported charts (20 charts)
├── powerbi/
│   └── ecommerce_funnel.pbix          # Power BI dashboard (3 pages)
│
└── README.md
```

---

## Technologies & Tools

| Category | Tools |
|---|---|
| **Programming** | Python 3.12 (Pandas, Matplotlib, Seaborn) |
| **Database** | PostgreSQL 14, SQLAlchemy |
| **SQL Techniques** | CTEs, Window Functions (LAG, ROW_NUMBER), FILTER aggregation |
| **Visualisation** | Power BI (DAX, Data Modelling), Matplotlib, Seaborn |
| **Environment** | JupyterLab, pgAdmin |

---

## Dataset Overview

**Source:** [eCommerce Events History in Electronics Store — Kaggle](https://www.kaggle.com/datasets/mkechinov/ecommerce-events-history-in-electronics-store)  
**Publisher:** REES46 Marketing Platform

| Metric | Value |
|---|---|
| **Raw Rows** | 885,129 |
| **Cleaned Rows** | 884,312 |
| **Date Range** | Sep 2020 – Feb 2021 |
| **Unique Users** | 407,237 |
| **Unique Products** | 53,452 |
| **Unique Brands** | 999 |
| **Event Types** | view, cart, purchase |
| **Total Revenue** | $5.13M |

### Data Quality Assessment

**Issues Identified & Resolved:**

- ❌ 655 duplicate rows — same timestamp + product + user + session (removed)
- ❌ 212,194 rows (24%) with null brand — documented, excluded from brand analysis only
- ❌ 165 rows with null user_session — dropped (negligible 0.02%)
- ❌ 1,424 rows (0.16%) with price > $2,000 — enterprise outliers, documented separately
- ❌ 10,362 sessions spanning > 24 hours — capped at 1,440 minutes for session analysis

**Cleaning Approach:**
- Systematic quality audit before any analysis
- Null brand rows retained in all funnel metrics — only excluded where brand is the dimension
- Enterprise outliers ($2,000+) documented with a note rather than silently dropped
- Category_code column split into L1, L2, L3 for granular analysis

---

## Methodology & Analysis Pipeline

### Phase 1: Data Preparation (Notebook 01)

**Objective:** Transform raw clickstream data into analysis-ready dataset.

**Key Steps:**
1. Loaded raw CSV, inspected schema and data types
2. Identified 5 data quality issues with impact assessment
3. Removed duplicates, parsed category hierarchy, fixed datetime types
4. Standardised text columns (brand, event_type, category)
5. Loaded clean table to PostgreSQL via COPY command (bulk load — 30 seconds vs 5+ minutes with to_sql)

**Output:** `events_clean` table — 884,312 rows, 12 columns, ready for analysis.

---

### Phase 2: SQL Funnel Analysis (6 Scripts)

**Objective:** Answer all business questions using SQL before visualising.

#### Script 01 — Core Funnel Drop-off

| Stage | Unique Users | Conversion | Drop-off |
|---|---|---|---|
| View | 406,817 | — | — |
| Cart | 36,948 | 9.08% | **90.92%** |
| Purchase | 21,304 | 57.66% from cart | 42.34% |

**Overall conversion: 5.24%** (industry avg for electronics: 1–3%)

Key SQL technique:
```sql
SELECT
    COUNT(DISTINCT CASE WHEN event_type = 'view'
          THEN user_id END) AS users_viewed,
    COUNT(DISTINCT CASE WHEN event_type = 'cart'
          THEN user_id END) AS users_carted,
    COUNT(DISTINCT CASE WHEN event_type = 'purchase'
          THEN user_id END) AS users_purchased
FROM events_clean;
```

---

#### Script 02 — Brand Funnel Analysis

| Brand | Conversion Rate | vs Store Avg |
|---|---|---|
| Sapphire | 15.90% | +10.66pp |
| MSI | 14.58% | +9.34pp |
| Gigabyte | 11.97% | +6.73pp |
| Hammer | 0.00% | -5.24pp |
| Honor | 0.66% | -4.58pp |

**Finding:** GPU brands convert 3x above average. Consumer electronics brands (Sony, Nokia, Philips) convert below 2% — users browse but likely purchase elsewhere.

---

#### Script 03 — Category Funnel Analysis

| Category | Conversion | Cart Abandonment | Revenue |
|---|---|---|---|
| Computers | 8.16% | 44.81% | $3.73M |
| Stationery | 6.72% | **32.66%** | $109K |
| Electronics | 4.62% | 40.68% | $450K |
| Apparel | 0.00% | **100%** | $0 |

**Finding:** Computers drive 80.5% of total revenue. Stationery is the hidden gem — second highest conversion with lowest cart abandonment. Apparel: zero purchases across 5 months.

---

#### Script 04 — Price Segment Analysis

| Segment | Conversion | Revenue Share | AOV |
|---|---|---|---|
| Budget (<$50) | 4.79% | 7.5% | $24.02 |
| Mid ($50–$199) | 4.53% | 23.8% | $103.56 |
| **Upper-mid ($200–$499)** | **7.09%** | **50.0%** | **$313.76** |
| Premium ($500–$1999) | 5.09% | 18.2% | $660.53 |
| Enterprise ($2000+) | 0.65% | 0.5% | $2,955 |

**Counter-intuitive finding:** Cheaper products do NOT convert better. Upper-mid products convert 35% above store average and drive half the revenue. The $250–$300 price bucket is the single best converting range at 7.40%.

---

#### Script 05 — Session & User Behaviour (Window Functions)

| Sessions | Users | Conversion Rate |
|---|---|---|
| 1 session | 354,890 | 3.26% |
| 2 sessions | 40,918 | 15.05% |
| 3–5 sessions | 9,591 | 29.48% |
| 6+ sessions | 1,838 | **40.48%** |

Key SQL technique — LAG window function:
```sql
LAG(event_time) OVER (
    PARTITION BY user_id, product_id
    ORDER BY event_time
) AS prev_event_time
```

**Finding:** Cart → purchase takes only 5 minutes on average. Purchase intent is formed before checkout, making product discovery the primary bottleneck rather than checkout friction.

---

#### Script 06 — Time Trends Analysis

| Finding | Detail |
|---|---|
| Peak conversion hour | 10:00 AM — 5.38% |
| Best day | Wednesday — 4.89% |
| Peak month revenue | Jan 2021 — $1.49M |
| Conversion trend | 4.10% (Sep) → 5.88% (Jan) |

**Finding:** Electronics is a work-hours purchase category. January 2021 computers revenue spiked to $1.22M — single category, single month — likely GPU shortage driving urgency purchases.

---

### Phase 3: Python EDA (5 Notebooks, 20 Charts)

**Objective:** Visualise SQL findings for dashboard and documentation.

| Notebook | Key Chart | Insight Visualised |
|---|---|---|
| 02_funnel_analysis | Funnel bar + waterfall | 90.92% view→cart drop |
| 03_brand_analysis | Horizontal bar + scatter | Sapphire 3x above avg |
| 04_category_analysis | Heatmap + pie combo | Computers 80.5% revenue |
| 05_price_analysis | Bucket bars + summary table | $250–$300 sweet spot |
| 06_time_trends | Hourly + weekly area charts | Jan spike + 10AM peak |

---

## Power BI Dashboard

3-page interactive dashboard connected live to PostgreSQL.

### Page 1 — Executive Summary

**KPI Cards:** Total Revenue ($5.13M) · View→Cart Rate (9.08%) · Overall Conversion (5.24%) · Cart Abandonment (42.34%)

**Visuals:** Funnel conversion chart · Monthly revenue + conversion trend · Revenue by category

**Insight:** *Only 5.24% of viewers convert to purchase. The biggest drop happens at View → Cart (90.92%). Revenue grew 15x from Sep 2020 to Jan 2021. Once users add to cart, 57.66% complete the purchase — checkout is not the problem, discovery is.*

---

### Page 2 — Product & Brand Intelligence

**KPI Cards:** Unique Viewers · Unique Buyers · Avg Order Value ($137.24) · Total Purchases (37K) · Overall Conversion (5.24%)

**Visuals:** Revenue & conversion by price segment · Cart abandonment by category · Category conversion rate · Brand conversion rate

**Insight:** *Upper-mid priced products ($200–$499) drive 50% of revenue despite 21% of purchases. GPU brands (Sapphire, MSI) convert 3x above average. Apparel has 100% cart abandonment — zero purchases across 5 months. Stationery is the hidden gem with the lowest abandonment rate at 32.66%.*

---

### Page 3 — User Behaviour & Conversion Timing

**KPI Cards:** Total Sessions · Session Conversion Rate · Single Session Conv · Multi Session Conv

**Visuals:** Hourly conversion rate · Day of week performance · Session segment conversion · Weekly conversion trend

**Insight:** *Users who return for a second session convert at 4.6x the rate of first-time visitors (15.05% vs 3.26%). Peak conversion hour is 10 AM. Wednesday outperforms Saturday by 6% — this is a weekday purchase store.*

**Slicers:** Month · Brand · Category — all pages fully filterable

---

## Business Recommendations

### Immediate Actions (Month 1–3)

#### 1. Invest in Retargeting Returning Visitors
**Objective:** Convert the 40,918 users who return for a second session (15.05% conversion potential)

**Actions:**
- Deploy retargeting ads targeting users who viewed but didn't cart
- Email/push campaigns for users who added to cart but didn't purchase
- Personalised product recommendations based on viewed categories

**Expected Impact:** Even 5% improvement in view→cart rate = ~20,000 additional cart additions

---

#### 2. Investigate the $300–$350 Pricing Dead Zone
**Objective:** Fix the conversion gap between $250–$300 (7.40%) and $400–$450 (7.18%)

**Actions:**
- Audit products in $300–$350 range against competitor pricing
- Test repositioning some products into the $280–$299 bracket
- Review product descriptions and imagery for this range

**Expected Impact:** Lifting $300–$350 conversion to match adjacent buckets = ~$50K additional revenue

---

#### 3. Review and Clean Dead Categories
**Objective:** Eliminate or fix zero-revenue categories

**Actions:**
- Apparel: 0 purchases in 5 months — wrong audience, consider removing or repricing
- electronics → fax: 503 views, 0 purchases — delist product
- Hammer brand: 1,409 views, 0 purchases — investigate pricing or stock availability

**Expected Impact:** Cleaner catalogue improves user experience and reduces wasted ad spend

---

#### 4. Prioritise Morning Traffic Monetisation
**Objective:** Double down on the peak conversion window (9–11 AM)

**Actions:**
- Schedule promotional emails to arrive at 8:30–9:00 AM
- Run paid ads with higher bids during 9–11 AM window
- Ensure customer support is fully staffed during peak hours

**Expected Impact:** Concentrating marketing spend in peak window improves ROAS

---

### Medium-Term Initiatives (Month 4–12)

#### 5. Build a GPU/Components Category Strategy
Computers drive 80.5% of revenue. GPU brands (Sapphire, MSI, Gigabyte) are the conversion leaders. A dedicated strategy for this subcategory — stock depth, competitive pricing, brand partnerships — could significantly grow the highest-value segment.

#### 6. Stationery Expansion
Stationery has the second highest conversion (6.72%) and lowest cart abandonment (32.66%) — users who browse stationery know exactly what they want. Expanding the stationery catalogue could drive disproportionate revenue relative to investment.

---

### Challenges & Solutions

❌ **Challenge:** 24% of rows have null brand values  
✅ **Solution:** Retained in all funnel metrics, excluded only from brand-level analysis. Documented as a source data quality issue.

❌ **Challenge:** Session durations inflated by open browser tabs  
✅ **Solution:** Identified 10,362 sessions > 24 hours (2.1%) via distribution analysis, capped at 1,440 minutes for all session calculations.

❌ **Challenge:** PostgreSQL bulk load via `to_sql` too slow (5+ minutes for 884K rows)  
✅ **Solution:** Switched to native PostgreSQL COPY command via SQLAlchemy — loaded 884K rows in under 30 seconds.

❌ **Challenge:** Inconsistent conversion rate methodology (events vs users)  
✅ **Solution:** Standardised on `COUNT(DISTINCT user_id)` for all conversion metrics across SQL, Python, and Power BI DAX measures — ensures like-for-like comparison throughout.

---

## Key Results Summary

| Metric | Value |
|---|---|
| Total Revenue (5 months) | $5.13M |
| Overall Conversion Rate | 5.24% |
| View → Cart Rate | 9.08% |
| Cart → Purchase Rate | 57.66% |
| Cart Abandonment Rate | 42.34% |
| Best Converting Brand | Sapphire (15.90%) |
| Best Converting Category | Computers (8.16%) |
| Revenue Sweet Spot | $200–$499 (50% of revenue) |
| Peak Conversion Hour | 10:00 AM (5.38%) |
| Multi-session Conversion Uplift | 4.6x vs single session |
| Revenue Growth (Sep → Jan) | 15x ($96K → $1.49M) |

---

## How to Run

### Prerequisites
- PostgreSQL 14+
- Python 3.12+
- Power BI Desktop

```bash
pip install pandas sqlalchemy psycopg2-binary matplotlib seaborn jupyter
```

### Setup

**1. Clone the repository**
```bash
git clone https://github.com/yourusername/e-commerce-funnel-analysis.git
cd e-commerce-funnel-analysis
```

**2. Download the dataset**
Download from [Kaggle](https://www.kaggle.com/datasets/mkechinov/ecommerce-events-history-in-electronics-store) and place `events.csv` in the `data/` folder.

**3. Set up PostgreSQL**
```sql
CREATE DATABASE ecommerce_funnel;
```

**4. Configure database connection**
Update `python/db_connection.py`:
```python
def get_engine():
    return create_engine(
        "postgresql://username:password@localhost:5432/ecommerce_funnel"
    )
```

**5. Run notebooks in order**
```
01_data_preparation.ipynb  ← loads, cleans, writes to PostgreSQL
02_funnel_analysis.ipynb
03_brand_analysis.ipynb
04_category_analysis.ipynb
05_price_analysis.ipynb
06_time_trends.ipynb
```

**6. Run SQL scripts**
Open pgAdmin → connect to `ecommerce_funnel` → run scripts in `sql/` in order.

**7. Open Power BI**
Open `powerbi/ecommerce_funnel.pbix` → update PostgreSQL connection credentials.

---

## Author

**Tejasvi Bhavsar**  
Data Analyst | Python · SQL · Power BI

🔗 GitHub: https://github.com/tejasvi-insights 
🔗 LinkedIn: http://linkedin.com/in/tejasvi-bhavsar-57429b135

---

*Data source: REES46 Marketing Platform via Kaggle. Project built for portfolio demonstration purposes.*  
*Last Updated: April 2026*
