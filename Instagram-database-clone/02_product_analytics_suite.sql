-- =====================================================================
-- INSTAGRAM DATA MODEL: PRODUCT ANALYTICS & USER BEHAVIOR INTELLIGENCE
-- Author: Saicharan Uchiha
-- Stack: MySQL 8.0 (CTEs, Window Functions, Anti-Joins, Fraud Detection)
-- Target Database: instagram_clone
-- =====================================================================

USE instagram_clone;

-- ---------------------------------------------------------------------
-- 1. Acquisition Timing: Registration Velocity by Day of Week
-- Optimizes marketing ad spend and push notification schedules.
-- ---------------------------------------------------------------------
SELECT 
    DAYNAME(created_at) AS registration_day,
    COUNT(id) AS new_user_count,
    ROUND(100.0 * COUNT(id) / SUM(COUNT(id)) OVER (), 2) AS pct_of_total_signups,
    DENSE_RANK() OVER (ORDER BY COUNT(id) DESC) AS volume_rank
FROM users
GROUP BY registration_day
ORDER BY volume_rank ASC;


-- ---------------------------------------------------------------------
-- 2. User Churn Risk: Dormancy & Zero-Post Funnel Dropoff
-- Identifies inactive signups with 0 content uploads for reactivation campaigns.
-- ---------------------------------------------------------------------
SELECT 
    u.id AS user_id,
    u.username,
    u.created_at AS signup_date,
    DATEDIFF(CURRENT_DATE(), u.created_at) AS account_age_days
FROM users u
LEFT JOIN photos p ON u.id = p.user_id
WHERE p.id IS NULL
ORDER BY account_age_days DESC;


-- ---------------------------------------------------------------------
-- 3. Content Virality: Top Performing Media & Engagement Density
-- Evaluates viral reach using window functions to rank posts by engagement.
-- ---------------------------------------------------------------------
WITH engagement_metrics AS (
    SELECT 
        p.id AS photo_id,
        u.username AS creator,
        p.image_url,
        COUNT(DISTINCT l.user_id) AS total_likes,
        COUNT(DISTINCT c.id) AS total_comments
    FROM photos p
    JOIN users u ON p.user_id = u.id
    LEFT JOIN likes l ON p.id = l.photo_id
    LEFT JOIN comments c ON p.id = c.photo_id
    GROUP BY p.id, u.username, p.image_url
)
SELECT 
    photo_id,
    creator,
    total_likes,
    total_comments,
    (total_likes + total_comments) AS gross_engagement,
    DENSE_RANK() OVER (ORDER BY total_likes DESC) AS virality_rank
FROM engagement_metrics
ORDER BY virality_rank ASC
LIMIT 10;


-- ---------------------------------------------------------------------
-- 4. Platform Health: Creator-to-Consumer Ratio & Content Velocity
-- Assesses supply liquidity across the total user base.
-- ---------------------------------------------------------------------
SELECT 
    (SELECT COUNT(*) FROM photos) AS total_photos_posted,
    (SELECT COUNT(*) FROM users) AS total_registered_users,
    ROUND((SELECT COUNT(*) FROM photos) / (SELECT COUNT(*) FROM users), 2) AS avg_posts_per_user,
    ROUND(
        100.0 * (SELECT COUNT(DISTINCT user_id) FROM photos) / (SELECT COUNT(*) FROM users), 
        2
    ) AS creator_conversion_rate_pct;


-- ---------------------------------------------------------------------
-- 5. Ad Targeting & Tag Affinity: Top 5 Trending Content Verticals
-- Informs the algorithmic recommendation feed and ad category targeting.
-- ---------------------------------------------------------------------
SELECT 
    t.id AS tag_id,
    t.tag_name,
    COUNT(pt.photo_id) AS tag_usage_frequency,
    DENSE_RANK() OVER (ORDER BY COUNT(pt.photo_id) DESC) AS popularity_rank
FROM tags t
JOIN photo_tags pt ON t.id = pt.tag_id
GROUP BY t.id, t.tag_name
ORDER BY popularity_rank ASC
LIMIT 5;


-- ---------------------------------------------------------------------
-- 6. Platform Integrity: Automated Bot & Fraud Detection
-- Isolates inorganic accounts that have liked every single photo on the platform.
-- ---------------------------------------------------------------------
WITH platform_benchmarks AS (
    SELECT COUNT(*) AS total_photo_count FROM photos
)
SELECT 
    u.id AS user_id,
    u.username,
    COUNT(l.photo_id) AS total_likes_given
FROM users u
JOIN likes l ON u.id = l.user_id
GROUP BY u.id, u.username
HAVING COUNT(l.photo_id) = (SELECT total_photo_count FROM platform_benchmarks)
ORDER BY u.id ASC;