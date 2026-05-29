SELECT COUNT(CASE WHEN churn = '1' THEN 1 ELSE NULL END) AS quantidade_clientes_churn,
       COUNT(*) as quantidade_clientes, 
       CAST(COUNT(CASE WHEN churn = '1' THEN 1 ELSE NULL END) * 100 AS DECIMAL(10,2)) 
       /
       CAST(COUNT(*) AS DECIMAL(10,2)) AS percentual_churn   
FROM tb_bank_customer_churn_prediction