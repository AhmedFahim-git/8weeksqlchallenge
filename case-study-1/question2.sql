SET search_path = dannys_diner;

SELECT customer_id,
       Count(DISTINCT order_date)
FROM   sales AS s
       inner join menu AS m
               ON s.product_id = m.product_id
GROUP  BY customer_id
ORDER  BY customer_id; 
