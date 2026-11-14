# Brazilian E-Commerce Customer Behavior & Retention Analysis

An end-to-end data analytics project exploring customer purchasing behavior, sales performance, RFM segmentation, cohort retention, and delivery performance using the Brazilian Olist E-Commerce dataset.

## 1. Project Overview

This project analyzes the Brazilian E-Commerce Public Dataset by Olist to understand customer behavior and business performance.

The project follows an end-to-end data analytics workflow, starting with data cleaning and preparation using Python, followed by exploratory and advanced analysis using PostgreSQL, and finally presenting key findings through an interactive Power BI dashboard.

The main focus is to identify customer purchasing patterns, evaluate repeat purchase behavior, understand customer segments, measure cohort retention, and examine the relationship between delivery performance and customer reviews.

## 2. Business Objectives

- Analyze overall sales performance and customer purchasing behavior.
- Measure customer repeat purchase activity and purchase frequency.
- Identify customer segments using RFM analysis.
- Evaluate customer retention through cohort analysis.
- Analyze delivery performance and customer review scores.
- Provide data-driven insights and business recommendations.

## 3. Tools & Technologies

| Tool | Purpose |
|---|---|
| Python | Data cleaning and preprocessing |
| Pandas | Data manipulation and transformation |
| Google Colab | Python development environment |
| PostgreSQL | Data storage and SQL analysis |
| SQL | Exploratory and advanced data analysis |
| Power BI | Interactive dashboard and visualization |
| GitHub | Project documentation and version control |

## 4. Dataset

**Source:** [Brazilian E-Commerce Public Dataset by Olist – Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)

The dataset contains information about orders, customers, products, payments, order items, and customer reviews from the Brazilian e-commerce marketplace.

The project uses original datasets for initial exploration and cleaned datasets exported from Google Colab for subsequent PostgreSQL analysis.

## 5. Project Workflow

### 01. Data Cleaning & Preparation – Python

Used Python and Pandas in Google Colab to inspect, clean, and prepare the original datasets.

Main activities:
- Inspecting dataset structure and data types.
- Identifying missing and inconsistent values.
- Checking and handling duplicate records where appropriate.
- Preparing cleaned datasets for PostgreSQL analysis.

### 02. Exploratory Data Analysis – PostgreSQL

Performed exploratory analysis to understand overall business performance.

Analysis areas:
- Order and customer distribution.
- Order status and payment analysis.
- Monthly sales trends.
- Product category performance.
- Geographic sales distribution.

### 03. Customer Behavior Analysis – PostgreSQL

Analyzed customer purchasing patterns and repeat purchase activity.

Key metrics:
- Total unique customers.
- One-time and repeat customers.
- Repeat purchase rate.
- Purchase intervals.
- Customer purchasing frequency.

### 04. RFM Customer Segmentation – SQL & Power BI

Applied Recency, Frequency, and Monetary analysis to categorize customers based on their purchasing behavior.

Customer segments:
- Champions
- Loyal Customers
- Potential Loyalists
- New / Recent Customers
- At Risk
- Hibernating

### 05. Cohort Retention Analysis – SQL & Power BI

Performed monthly cohort analysis based on customers' first delivered purchase month.

Analysis areas:
- Customer acquisition by cohort month.
- Monthly active purchasing customers.
- Retention rate by cohort index.
- Cohort retention heatmap.

### 06. Delivery & Review Analysis – PostgreSQL & Power BI

Analyzed delivery performance by comparing actual delivery dates with estimated delivery dates.

The analysis also examined customer review scores across delivery performance groups to understand differences in customer experience.

## 6. Power BI Dashboard

The interactive Power BI dashboard consists of four analytical pages.

### 01. Dashboard Overview

Provides an overview of e-commerce business performance, including customer metrics, order metrics, gross sales trends, RFM customer spending, and product category performance.

![Dashboard Overview](Images/01%20%E2%80%94%20Dashboard%20Overview.png)

### 02. RFM Customer Segmentation

Presents customer segmentation results, purchasing frequency, customer distribution, and other customer behavior metrics.

![RFM Customer Segmentation](Images/02%20%E2%80%94%20RFM%20Customer%20Segmentation.png)

### 03. Customer Cohort & Retention

Visualizes customer acquisition cohorts, monthly retention rates, active customers, and retention patterns through a cohort heatmap.

![Customer Cohort and Retention](Images/03%20%E2%80%94%20Customer%20Cohort%20%26%20Retention.png)

### 04. Business Insights

Summarizes the main analytical findings and business recommendations related to customer behavior, RFM segmentation, delivery performance, customer reviews, and cohort retention.

![Business Insights](Images/04%20%E2%80%94%20Business%20Insights.png)

### Download Power BI Dashboard

[Download Olist E-Commerce Power BI Dashboard (.pbix)](https://github.com/hilmardiansyah/ecommerce-customer-behavior-retention-analysis/releases/latest)

## 7. Key Findings

### Customer Behavior

- Total delivered customers: **93,358**
- One-time customers: **90,557**
- Repeat customers: **2,801**
- Repeat purchase rate: **3.00%**

Most customers made only one delivered purchase, indicating relatively low repeat purchasing activity.

### RFM Customer Segmentation

The two largest customer segments were:

- Hibernating: **37,318 customers**
- New / Recent Customers: **37,198 customers**

Together, these segments represented approximately **79.81%** of delivered customers.

### Cohort Retention

- Total customer cohorts: **23**
- Observation period: **September 2016 – August 2018**
- Highest Month 1 retention: **0.72%**, recorded by the October 2017 cohort.

Most cohorts showed low Month 1 retention, indicating limited repeat purchasing activity in subsequent months.

### Delivery Performance & Customer Reviews

- Late delivery rate: **6.77%** of valid delivered orders with delivery classification.
- Average review score for On Time / Early deliveries: **4.29**
- Average review score for Late deliveries: **2.27**

Late deliveries were associated with substantially lower average customer review scores. This is a descriptive relationship and does not establish causation.

## 8. Business Recommendations

Based on the analysis, the following recommendations are proposed:

1. **Improve Customer Retention**  
   Develop post-purchase engagement campaigns and loyalty incentives to encourage customers to make repeat purchases.

2. **Implement Targeted Customer Campaigns**  
   Focus on nurturing recent customers and reactivating inactive customers through targeted marketing strategies.

3. **Strengthen Delivery Performance**  
   Monitor delivery delays and improve coordination with logistics partners to support a better customer experience.

4. **Use RFM Segmentation for Marketing Strategies**  
   Create differentiated marketing campaigns based on customer recency, purchase frequency, and monetary value.

## 9. Repository Structure

```text
## 9. Repository Structure

```text
ecommerce-customer-behavior-retention-analysis/
│
├── DATA/
│   ├── Processed/
│   │   ├── customers.csv
│   │   ├── order_items.csv
│   │   ├── orders.csv
│   │   ├── payments.csv
│   │   └── products.csv
│   │
│   └── Raw/
│       └── olist_order_reviews_dataset.csv
│
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
## 10. Conclusion

This project demonstrates an end-to-end data analytics workflow, combining Python-based data preparation, PostgreSQL analysis, customer segmentation, cohort retention analysis, and Power BI visualization.

The findings highlight opportunities to improve customer retention, strengthen customer engagement, and enhance delivery performance through data-driven business decisions.

---

**Project Category:** Data Analytics  
**Domain:** E-Commerce  
**Tools:** Python, PostgreSQL, SQL, Power BI
