SELECT country AS pais,
       COUNT(CASE WHEN churn = '1' THEN 1 ELSE NULL END) AS quantidade_clientes_churn_pais,
       COUNT(*) as quantidade_clientes_pais, 
       CAST(COUNT(CASE WHEN churn = '1' THEN 1 ELSE NULL END) * 100 AS DECIMAL(10,2)) 
       /
       CAST(COUNT(*) AS DECIMAL(10,2)) AS percentual_churn_pais  
FROM tb_bank_customer_churn_prediction
GROUP BY country