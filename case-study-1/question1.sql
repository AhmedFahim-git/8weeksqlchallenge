SET search_path = dannys_diner;

SELECT customer_id,
       SUM(price) AS total_spent
FROM   sales AS s
       inner join menu AS m
               ON s.product_id = m.product_id
GROUP  BY customer_id
ORDER  BY customer_id;
