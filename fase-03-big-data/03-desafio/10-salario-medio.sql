SELECT churn,
       COUNT(*) AS total_clientes,
       ROUND(AVG(CAST(estimated_salary AS DECIMAL(14,2))), 2) AS salario_medio
FROM tb_bank_customer_churn_prediction
GROUP BY churn