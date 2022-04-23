SET search_path = dannys_diner;
SELECT product_id,
       times_ordered
FROM   (SELECT product_id,
               Count(*)                    AS times_ordered,
               Rank()
                 over(
                   ORDER BY Count(*) DESC) AS frequency_rank
        FROM   sales
        GROUP  BY product_id) AS subquery
WHERE  frequency_rank = 1; 