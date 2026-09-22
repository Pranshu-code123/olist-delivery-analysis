-- Olist delivery analysis: further SQL queries

-- Q3: Late delivery rate by state
SELECT c.customer_state,
       COUNT(*) AS orders,
       ROUND(100 * AVG(d.is_late), 1) AS pct_late,
       ROUND(AVG(d.delivery_days), 1) AS avg_delivery_days
FROM delivered_orders d
JOIN customers c ON d.customer_id = c.customer_id
GROUP BY c.customer_state
ORDER BY pct_late DESC;

-- Q3b: Promised vs actual delivery time by state
-- Checks whether states with high late rates have thinner buffers
-- between the promised date and actual delivery
SELECT c.customer_state,
       COUNT(*) AS orders,
       ROUND(AVG(DATEDIFF(o.order_estimated_delivery_date, o.order_purchase_timestamp)), 1) AS avg_promised_days,
       ROUND(AVG(DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp)), 1) AS avg_actual_days,
       ROUND(100 * AVG(d.is_late), 1) AS pct_late
FROM delivered_orders d
JOIN orders o    ON d.order_id = o.order_id
JOIN customers c ON d.customer_id = c.customer_id
GROUP BY c.customer_state
ORDER BY pct_late DESC;

-- Q4: Review score by delay severity
SELECT CASE
         WHEN d.delay_days <= 0  THEN '1. On time'
         WHEN d.delay_days <= 3  THEN '2. 1-3 days late'
         WHEN d.delay_days <= 7  THEN '3. 4-7 days late'
         WHEN d.delay_days <= 14 THEN '4. 8-14 days late'
         ELSE '5. 15+ days late'
       END AS delay_bucket,
       COUNT(*) AS orders,
       ROUND(AVG(r.review_score), 2) AS avg_review
FROM delivered_orders d
JOIN (SELECT order_id, AVG(review_score) AS review_score
      FROM order_reviews
      GROUP BY order_id) r
  ON d.order_id = r.order_id
GROUP BY delay_bucket
ORDER BY delay_bucket;

-- Q5: Sellers with the worst late delivery rates (min 30 orders)
WITH order_seller AS (
  SELECT DISTINCT order_id, seller_id
  FROM order_items
)
SELECT s.seller_id,
       s.seller_state,
       COUNT(*) AS orders,
       ROUND(100 * AVG(d.is_late), 1) AS pct_late
FROM delivered_orders d
JOIN order_seller os ON d.order_id = os.order_id
JOIN sellers s ON os.seller_id = s.seller_id
GROUP BY s.seller_id, s.seller_state
HAVING COUNT(*) >= 30
ORDER BY pct_late DESC
LIMIT 10;

-- Q6: Revenue by product category (top 10)
SELECT COALESCE(t.product_category_name_english, p.product_category_name) AS category,
       COUNT(DISTINCT oi.order_id) AS orders,
       ROUND(SUM(oi.price), 2) AS revenue,
       ROUND(AVG(oi.price), 2) AS avg_item_price
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
LEFT JOIN product_category_name_translation t
  ON p.product_category_name = t.product_category_name
GROUP BY category
ORDER BY revenue DESC
LIMIT 10;

-- Q7: Monthly order volume and revenue
-- Note: Sep-Dec 2016 (platform ramp-up) and Sep 2018 (data cutoff)
-- have very few orders and should be excluded from trend charts
SELECT DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS month,
       COUNT(DISTINCT o.order_id) AS orders,
       ROUND(SUM(oi.price), 2) AS revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status NOT IN ('unavailable', 'canceled')
GROUP BY month
ORDER BY month;