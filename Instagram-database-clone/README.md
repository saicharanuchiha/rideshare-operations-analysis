# 📸 Instagram Data Model: Product Analytics & Integrity Suite

An advanced SQL product analytics study evaluating user acquisition patterns, platform liquidity, viral content engagement, and automated bot networks across a relational social media architecture.

---

## 🏗️ Relational Data Architecture

The database is built on a 3NF relational schema modeling core social interactions:

```text
users (id, username, created_at)
  ├── photos (id, image_url, user_id, created_at)
  │     ├── comments (id, comment_text, photo_id, user_id, created_at)
  │     ├── likes (user_id, photo_id, created_at)
  │     └── photo_tags (photo_id, tag_id) ── tags (id, tag_name)
  └── follows (follower_id, followee_id, created_at)
```

---

## 🔍 Core Product Insights & Analytical Queries

### 1. User Retention & Churn Prevention (Zero-Post Dropoff)
* **Objective:** Identify inactive accounts to trigger targeted lifecycle re-engagement campaigns.
* **Technique:** `LEFT JOIN` anti-joins isolating accounts where `photos.id IS NULL`.

### 2. Platform Liquidity & Creator Velocity
* **Objective:** Measure overall network health by calculating the ratio of content creators against passive consumers.
* **Metric:** Platform-wide post-per-user averages and creator conversion percentages.

### 3. Algorithmic Content & Ad Targeting
* **Objective:** Discover top viral content categories to optimize ad placement and user interest tags.
* **Technique:** Multi-table relational joins between `tags` and `photo_tags` using `DENSE_RANK()`.

### 4. Trust & Safety: Automated Bot / Fraud Detection
* **Objective:** Protect advertising attribution and platform credibility by identifying automated activity.
* **Technique:** Dynamic subqueries filtering users whose lifetime like count equals 100% of all published photos (`COUNT(likes) = (SELECT COUNT(*) FROM photos)`).

---

## 🛠️ Tech Stack & SQL Competencies

* **RDBMS:** MySQL 8.0
* **Advanced SQL:** Common Table Expressions (CTEs), Window Functions (`DENSE_RANK`, `SUM() OVER()`), Anti-Joins, Conditional Aggregation, Grouping Sets.
* **Domain:** Product Analytics, User Growth, Lifecycle Funnels, Trust & Safety Operations.

---

## 🚀 How to Run Locally

1. Clone this repository:
   ```bash
   git clone [https://github.com/saicharanuchiha/Instagram-database-clone.git](https://github.com/saicharanuchiha/Instagram-database-clone.git)
   ```
2. In MySQL Workbench, open and execute `01_schema_and_data_seed.sql` to build the schema and seed the dataset.
3. Open and run `02_product_analytics_suite.sql` to execute the analytical queries.