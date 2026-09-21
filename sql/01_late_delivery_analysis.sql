-- Olist delivery analysis: setup and first two questions

-- View: delivered orders only, with delivery days and a late flag
CREATE VIEW delivered_orders AS
SELECT order_id,
       customer_id,
       order_purchase_timestamp,
       TIMESTAMPDIFF(DAY, order_purchase_timestamp, order_delivered_customer_date) AS delivery_days,
       DATEDIFF(order_delivered_customer_date, order_estimated_delivery_date)      AS delay_days,
       CASE WHEN DATEDIFF(order_delivered_customer_date, order_estimated_delivery_date) > 0
            THEN 1 ELSE 0 END AS is_late
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL;

-- Q1: What percentage of delivered orders arrive late?
SELECT COUNT(*) AS delivered_orders,
       ROUND(100 * AVG(is_late), 2) AS pct_late
FROM delivered_orders;

-- Q2: Do late orders get lower review scores?
-- Reviews are averaged per order first, because some orders have several reviews
SELECT CASE WHEN d.is_late = 1 THEN 'Late' ELSE 'On time' END AS delivery_status,
       COUNT(*) AS orders,
       ROUND(AVG(r.review_score), 2) AS avg_review
FROM delivered_orders d
JOIN (SELECT order_id, AVG(review_score) AS review_score
      FROM order_reviews
      GROUP BY order_id) r
  ON d.order_id = r.order_id
GROUP BY delivery_status;