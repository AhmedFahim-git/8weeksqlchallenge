SET search_path = dannys_diner;

SELECT customer_id,
       s.product_id,
       product_name,
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
       join menu AS m
         ON s.product_id = m.product_id
WHERE  count_rank = 1
ORDER  BY customer_id,
          s.product_id; 