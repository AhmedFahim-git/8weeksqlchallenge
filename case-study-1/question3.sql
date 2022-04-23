SET search_path = dannys_diner;

WITH cte
     AS (SELECT customer_id,
                order_date,
                s.product_id,
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
       order_date,
       product_id,
       product_name
FROM   cte
WHERE  date_rank = 1
ORDER  BY customer_id; 