------------------------------------------------- 
--         Case Study #1 - Danny's Diner       --
-- https://8weeksqlchallenge.com/case-study-1/ --
------------------------------------------------- 

-- Author: Ahmed Fahim
-- Date: 2022-04-24
-- Tool used: pgAdmin 4
-- Database: PostgreSQL v14

----------------- 
--  Schema SQL --
----------------- 

/* 
Note: The following code was provided as part of the callenge. However, it was slightly modified 
      to allow it to be run multiple times without error.
*/

CREATE SCHEMA IF NOT EXISTS dannys_diner;
SET search_path = dannys_diner;

DROP TABLE IF EXISTS sales;
CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 
DROP TABLE IF EXISTS menu;
CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  
DROP TABLE IF EXISTS members;
CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');


--------------------------
-- Case Study Questions --
--------------------------


/* 
Note: In order to run the queries separately make sure to run the above code at least once. And execute the command 
	  `SET search_path = dannys_diner;` before running any of the queries below.
*/


-- 1. What is the total amount each customer spent at the restaurant?

SELECT customer_id,
       Concat('$', SUM(price)) AS total_spent
FROM   sales AS s
       inner join menu AS m
               ON s.product_id = m.product_id
GROUP  BY customer_id
ORDER  BY customer_id;


-- 2. How many days has each customer visited the restaurant?

SELECT customer_id,
       Count(DISTINCT order_date) AS number_of_visits
FROM   sales AS s
       inner join menu AS m
               ON s.product_id = m.product_id
GROUP  BY customer_id
ORDER  BY customer_id; 


-- 3. What was the first item from the menu purchased by each customer?

/* 
Note: The order_date column is of date type, so it's not possible to break ties within the same day.
*/

WITH date_ranked_purchase
     AS (SELECT customer_id,
                product_name,
                Rank()
                  over(
                    PARTITION BY customer_id
                    ORDER BY order_date) AS date_rank
         FROM   sales AS s
                inner join menu AS m
                        ON s.product_id = m.product_id
         ORDER  BY order_date)

SELECT customer_id,
       String_agg(DISTINCT product_name, ', ') AS first_dishes
FROM   date_ranked_purchase
WHERE  date_rank = 1
GROUP  BY customer_id
ORDER  BY customer_id; 


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT product_name AS most_purchased_item,
       times_purchased
FROM   (SELECT product_id,
               Count(*)                    AS times_purchased,
               Rank()
                 over(
                   ORDER BY Count(*) DESC) AS frequency_rank
        FROM   sales
        GROUP  BY product_id) AS sub
       inner join menu AS m
               ON sub.product_id = m.product_id
WHERE  frequency_rank = 1; 


-- 5. Which item was the most popular for each customer?

SELECT customer_id,
       String_agg(product_name, ', ') AS most_popular_items,
       times_ordered
FROM   (SELECT customer_id,
               product_id,
               Count(*)                    AS times_ordered,
               Rank()
                 over(
                   PARTITION BY customer_id
                   ORDER BY Count(*) DESC) AS count_rank
        FROM   sales
        GROUP  BY customer_id,
                  product_id) AS s
       inner join menu AS m
               ON s.product_id = m.product_id
WHERE  count_rank = 1
GROUP  BY customer_id,
          times_ordered
ORDER  BY customer_id; 


-- 6. Which item was purchased first by the customer after they became a member?

/* 
Note: It was assumed that on the day that a customer becomes a member, he/she becomes a member 
      before making any purchase.
*/

WITH first_post_member_purchase
     AS (SELECT customer_id,
                product_id
         FROM   (SELECT s.customer_id,
                        product_id,
                        Rank()
                          over(
                            PARTITION BY s.customer_id
                            ORDER BY order_date) AS date_rank
                 FROM   sales AS s
                        inner join members AS m
                                ON s.customer_id = m.customer_id
                 WHERE  order_date >= join_date) AS subquery
         WHERE  date_rank = 1)

SELECT customer_id,
       String_agg(product_name, ', ') AS first_item_purchased
FROM   first_post_member_purchase AS fpmp
       inner join menu AS m
               ON fpmp.product_id = m.product_id
GROUP  BY customer_id
ORDER  BY customer_id; 


-- 7. Which item was purchased just before the customer became a member?

/* 
Note: It was assumed that on the day that a customer becomes a member, he/she becomes a member 
      before making any purchase.
*/

WITH last_pre_member_purchase
     AS (SELECT customer_id,
                product_id
         FROM   (SELECT s.customer_id,
                        product_id,
                        Rank()
                          over(
                            PARTITION BY s.customer_id
                            ORDER BY order_date DESC) AS date_rank
                 FROM   sales AS s
                        inner join members AS m
                                ON s.customer_id = m.customer_id
                 WHERE  order_date < join_date) AS subquery
         WHERE  date_rank = 1)

SELECT customer_id,
       String_agg(product_name, ', ') AS last_pre_member_purchase
FROM   last_pre_member_purchase AS lpmp
       inner join menu AS m
               ON lpmp.product_id = m.product_id
GROUP  BY customer_id
ORDER  BY customer_id; 


-- 8. What is the total items and amount spent for each member before they became a member?

WITH pre_member_purchase
     AS (SELECT s.customer_id,
                product_id
         FROM   sales AS s
                inner join members AS m
                        ON s.customer_id = m.customer_id
         WHERE  order_date < join_date)

SELECT customer_id,
       Count(*)                AS num_items_bought,
       Concat('$', SUM(price)) AS total_spent
FROM   pre_member_purchase AS pmp
       inner join menu AS m
               ON pmp.product_id = m.product_id
GROUP  BY customer_id
ORDER  BY customer_id; 


-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

-- For all customers

WITH points_table
     AS (SELECT product_id,
                CASE
                  WHEN product_name = 'sushi' THEN 20 * price
                  ELSE 10 * price
                END AS points
         FROM   menu)

SELECT customer_id,
       SUM(points) AS total_points
FROM   sales AS s
       inner join points_table AS p
               ON s.product_id = p.product_id
GROUP  BY customer_id
ORDER  BY customer_id; 

-- Only for members after they became members

WITH points_table
     AS (SELECT product_id,
                CASE
                  WHEN product_name = 'sushi' THEN 20 * price
                  ELSE 10 * price
                END AS points
         FROM   menu)

SELECT s.customer_id,
       SUM(points) AS total_points
FROM   sales AS s
       join points_table AS p
         ON s.product_id = p.product_id
       inner join members AS m
               ON s.customer_id = m.customer_id
WHERE  order_date >= join_date
GROUP  BY s.customer_id
ORDER  BY s.customer_id;


-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

-- For members with points from both before and after becoming member

SELECT s.customer_id,
       SUM(CASE
             WHEN order_date BETWEEN join_date AND ( join_date + Cast('1 week'
                                                     AS
                                                     INTERVAL)
                                                   ) THEN 2 * 10 * price
             WHEN product_name = 'sushi' THEN 2 * 10 * price
             ELSE price * 10
           END) AS total_points
FROM   sales AS s
       inner join members AS mem
               ON s.customer_id = mem.customer_id
       inner join menu AS mnu
               ON s.product_id = mnu.product_id
WHERE  order_date <= '2021-01-31'
GROUP  BY s.customer_id
ORDER  BY s.customer_id; 

-- For members with points only after becoming member

SELECT s.customer_id,
       SUM(CASE
             WHEN order_date BETWEEN join_date AND ( join_date + Cast('1 week'
                                                     AS
                                                     INTERVAL)
                                                   ) THEN 20 * price
             WHEN product_name = 'sushi' THEN 20 * price
             ELSE price * 10
           END) AS total_points
FROM   sales AS s
       inner join members AS mem
               ON s.customer_id = mem.customer_id
       inner join menu AS mnu
               ON s.product_id = mnu.product_id
WHERE  order_date <= '2021-01-31'
       AND order_date >= join_date
GROUP  BY s.customer_id
ORDER  BY s.customer_id; 



---------------------
-- Bonus Questions --
---------------------

-- Join All The Things

SELECT s.customer_id,
       order_date,
       product_name,
       price,
       CASE
         WHEN order_date >= join_date THEN 'Y'
         ELSE 'N'
       END AS member
FROM   sales AS s
       left join members AS mem
              ON s.customer_id = mem.customer_id
       inner join menu AS mnu
               ON s.product_id = mnu.product_id
ORDER  BY s.customer_id,
          order_date; 


-- Rank All The Things

SELECT s.customer_id,
       order_date,
       product_name,
       price,
       CASE
         WHEN order_date >= join_date THEN 'Y'
         ELSE 'N'
       END AS member,
       CASE
         WHEN order_date >= join_date THEN Rank()
         over (
           PARTITION BY s.customer_id
           ORDER BY order_date >= join_date DESC,
         order_date )
       END AS ranking
FROM   sales AS s
       left join members AS mem
              ON s.customer_id = mem.customer_id
       inner join menu AS mnu
               ON s.product_id = mnu.product_id
ORDER  BY s.customer_id,
          order_date; 