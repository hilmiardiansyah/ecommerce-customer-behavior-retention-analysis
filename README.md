# Brazilian E-Commerce Customer Behavior & Retention Analysis

An end-to-end data analytics project exploring customer behavior, purchasing patterns, customer segmentation, cohort retention, and delivery performance using the Brazilian Olist E-Commerce dataset.

The project demonstrates a complete analytics workflow, from data cleaning and preparation to SQL analysis and interactive dashboard development.

## Project Overview

This project analyzes Brazilian e-commerce transactions to understand how customers purchase, how frequently they return, which customer segments contribute to spending, and how delivery performance relates to customer reviews.

The analysis focuses on:

- Customer purchasing behavior and repeat purchases
- RFM (Recency, Frequency, Monetary) customer segmentation
- Customer cohort and retention analysis
- Sales performance and product category analysis
- Delivery performance and customer review analysis

## Tools & Technologies

| Tool | Purpose |
|---|---|
| Python (Google Colab) | Data cleaning and preparation |
| Pandas | Data manipulation and transformation |
| PostgreSQL | Data storage and querying |
| SQL | Exploratory and customer behavior analysis |
| Power BI | Interactive dashboard and visualization |
| GitHub | Project documentation and version control |

## Project Workflow

### 1. Data Cleaning & Preparation — Python

- Loaded and explored the original datasets.
- Checked missing values, duplicates, and data types.
- Cleaned and prepared datasets for further analysis.
- Exported processed datasets for PostgreSQL analysis.

Notebook: [`Olist_Notebook.ipynb`](Notebook/Olist_Notebook.ipynb)

### 2. Data Analysis — PostgreSQL

The SQL analysis is organized into six scripts:

| SQL File | Analysis |
|---|---|
| `01_data_validation.sql` | Data validation and quality checks |
| `02_exploratory_data_analysis.sql` | Exploratory data analysis |
| `03_customer_behavior_analysis.sql` | Customer purchasing behavior and repeat purchases |
| `04_rfm_customer_segmentation.sql` | RFM customer segmentation |
| `05_cohort_retention_analysis.sql` | Customer cohort and retention analysis |
| `06_delivery_review_analysis.sql` | Delivery performance and customer review analysis |

SQL scripts: [`SQL/`](SQL/)

### 3. Data Visualization — Power BI

An interactive Power BI dashboard was developed to present the analysis through four pages:

1. **Dashboard** — Overall e-commerce performance, sales trends, and customer spending by RFM segment.
2. **RFM** — Customer segmentation, purchasing frequency, and customer behavior.
3. **Cohort** — Customer acquisition cohorts and monthly retention patterns.
4. **Insight** — Key findings and business recommendations.

## Key Findings & Business Insights

### Customer Behavior

- Total delivered customers: **93,358**
- One-time customers: **90,557**
- Repeat customers: **2,801**
- Repeat purchase rate: **3.00%**

Most customers made only one delivered purchase, indicating an opportunity to improve repeat purchasing activity through post-purchase engagement and customer retention initiatives.

### RFM Customer Segmentation

| Customer Segment | Customers |
|---|---:|
| Hibernating | 37,318 |
| New / Recent Customers | 37,198 |
| Potential Loyalists | 18,614 |
| Loyal Customers | 151 |
| At Risk | 71 |
| Champions | 6 |
| **Total** | **93,358** |

Hibernating and New / Recent Customers represent the largest customer segments. This highlights opportunities for customer nurturing and targeted reactivation campaigns.

### Cohort Retention

- The analysis identified **23 customer cohorts**.
- The observation period covers **September 2016 to August 2018**.
- October 2017 recorded the highest Month 1 retention rate at **0.72%**.

Most cohorts showed low Month 1 retention, indicating limited repeat purchasing activity in the following month.

### Delivery Performance & Customer Reviews

| Delivery Status | Average Review Score |
|---|---:|
| On Time / Early | 4.29 |
| Late Delivery | 2.27 |

Late deliveries were associated with substantially lower average review scores. This suggests that delivery performance is an important area to monitor when evaluating customer experience.

*These findings describe observed relationships and do not establish causation.*

## Dashboard Preview

### 1. Overall E-Commerce Dashboard

![Dashboard Overview](Images/01%20%E2%80%94%20Dashboard%20Overview.png)

### 2. RFM Customer Segmentation

![RFM Customer Segmentation](Images/02%20%E2%80%94%20RFM%20Customer%20Segmentation.png)

### 3. Customer Cohort & Retention

![Customer Cohort and Retention](Images/03%20%E2%80%94%20Customer%20Cohort%20%26%20Retention.png)

### 4. Business Insights

![Business Insights](Images/04%20%E2%80%94%20Business%20Insights.png)

## Repository Structure

```text
ecommerce-customer-behavior-retention-analysis/
│
├── DATA/
│   ├── Raw/
│   │   ├── olist_order_reviews_dataset.csv
│   │   └── README.md
│   │
│   ├── Processed/
│   │   ├── customers.csv
│   │   ├── order_items.csv
│   │   ├── orders.csv
│   │   ├── payments.csv
│   │   ├── products.csv
│   │   └── README.md
│   │
├── Images/
│   ├── 01 — Dashboard Overview.png
│   ├── 02 — RFM Customer Segmentation.png
│   ├── 03 — Customer Cohort & Retention.png
│   └── 04 — Business Insights.png
│
├── Notebook/
│   └── Olist_Notebook.ipynb
│
├── SQL/
│   ├── 01_data_validation.sql
│   ├── 02_exploratory_data_analysis.sql
│   ├── 03_customer_behavior_analysis.sql
│   ├── 04_rfm_customer_segmentation.sql
│   ├── 05_cohort_retention_analysis.sql
│   └── 06_delivery_review_analysis.sql
│
└── README.md
```

## Download Power BI Dashboard

The Power BI project file is available through GitHub Releases.

[Download Olist E-Commerce Power BI Dashboard (.pbix)](https://github.com/hilmiardiansyah/ecommerce-customer-behavior-retention-analysis/releases/tag/v1.0.0)

## Project Objectives

This project was developed to strengthen practical skills in:

- Data cleaning and preparation using Python.
- Data querying and analysis using PostgreSQL and SQL.
- Customer segmentation using RFM methodology.
- Cohort-based customer retention analysis.
- Data visualization and dashboard development using Power BI.
- Translating analytical findings into actionable business insights.

---

**Author:** Hilmi Ardiansyah  
**Project:** Brazilian E-Commerce Customer Behavior & Retention Analysis
