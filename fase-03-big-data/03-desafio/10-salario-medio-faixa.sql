WITH min_max AS (
    SELECT MIN(CAST(estimated_salary AS DECIMAL(14,2))) AS min_salario,
           MAX(CAST(estimated_salary AS DECIMAL(14,2))) AS max_salario
    FROM tb_bank_customer_churn_prediction
),
faixas AS (
    SELECT 0 as min_salario,
           max_salario,
           --(max_salario - min_salario) / 5 AS tamanho_faixa
           40000 AS tamanho_faixa
    FROM min_max
),
classificacao AS (
    SELECT  churn, salario, -- faixas.*,
            CASE WHEN salario BETWEEN faixas.min_salario AND faixas.min_salario + faixas.tamanho_faixa THEN 1
                 WHEN salario BETWEEN faixas.min_salario + faixas.tamanho_faixa AND faixas.min_salario + 2 * faixas.tamanho_faixa THEN 2
                 WHEN salario BETWEEN faixas.min_salario + 2 * faixas.tamanho_faixa AND faixas.min_salario + 3 * faixas.tamanho_faixa THEN 3
                 WHEN salario BETWEEN faixas.min_salario + 3 * faixas.tamanho_faixa AND faixas.min_salario + 4 * faixas.tamanho_faixa THEN 4
                 WHEN salario BETWEEN faixas.min_salario + 4 * faixas.tamanho_faixa AND faixas.max_salario THEN 5
                 ELSE NULL
            END AS faixa_id,
            CASE WHEN salario BETWEEN faixas.min_salario AND faixas.min_salario + faixas.tamanho_faixa
                     THEN CONCAT('Faixa 1 - ', CAST(ROUND(faixas.min_salario,2) AS VARCHAR(15)), ' até ', CAST(ROUND(faixas.min_salario + faixas.tamanho_faixa,2) AS VARCHAR(15)))
                 WHEN salario BETWEEN faixas.min_salario + faixas.tamanho_faixa+0.01 AND faixas.min_salario + 2 * faixas.tamanho_faixa
                     THEN CONCAT('Faixa 2 - ', CAST(ROUND(faixas.min_salario + faixas.tamanho_faixa+0.01,2) AS VARCHAR(15)), ' até ', CAST(ROUND(faixas.min_salario + 2 * faixas.tamanho_faixa,2) AS VARCHAR(15)))
                 WHEN salario BETWEEN faixas.min_salario + 2 * faixas.tamanho_faixa+0.01 AND faixas.min_salario + 3 * faixas.tamanho_faixa
                     THEN CONCAT('Faixa 3 - ', CAST(ROUND(faixas.min_salario + 2 * faixas.tamanho_faixa+0.01,2)  AS VARCHAR(15)), ' até ', CAST(ROUND(faixas.min_salario + 3 * faixas.tamanho_faixa,2) AS VARCHAR(15)))
                 WHEN salario BETWEEN faixas.min_salario + 3 * faixas.tamanho_faixa+0.01 AND faixas.min_salario + 4 * faixas.tamanho_faixa
                     THEN CONCAT('Faixa 4 - ', CAST(ROUND(faixas.min_salario + 3 * faixas.tamanho_faixa+0.01,2) AS VARCHAR(15)), ' até ', CAST(ROUND(faixas.min_salario + 4 * faixas.tamanho_faixa,2) AS VARCHAR(15)))
                 WHEN salario BETWEEN faixas.min_salario + 4 * faixas.tamanho_faixa+0.01 AND faixas.max_salario
                     THEN CONCAT('Faixa 5 - ', CAST(ROUND(faixas.min_salario + 4 * faixas.tamanho_faixa+0.01,2) AS VARCHAR(15)), ' até ', CAST(ROUND(faixas.max_salario,2) AS VARCHAR(15)))
                 ELSE 'Fora das faixas'
            END AS faixa_salario
    FROM (SELECT CAST(estimated_salary AS DECIMAL(14,2)) AS salario, churn
          FROM tb_bank_customer_churn_prediction
    ) t CROSS JOIN faixas
)
--select * from classificacao
SELECT faixa_salario,
       COUNT(*) AS quantidade,
       COUNT(CASE WHEN churn = '1' THEN 1 END) AS quantidade_saiu,
       COUNT(CASE WHEN churn = '0' THEN 1 END) AS quantidade_nao_saiu,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentual_clientes_total,
       ROUND(COUNT(CASE WHEN churn = '1' THEN 1 END) * 100.0 / COUNT(*), 2) AS percentual_saiu_faixa,
       ROUND(COUNT(CASE WHEN churn = '0' THEN 1 END) * 100.0 / COUNT(*), 2) AS percentual_nao_saiu_faixa,
       ROUND(COUNT(CASE WHEN churn = '1' THEN 1 END) * 100.0 / SUM(COUNT(CASE WHEN churn = '1' THEN 1 END)) OVER (), 2) AS percentual_saiu_total_geral,
       ROUND(COUNT(CASE WHEN churn = '0' THEN 1 END) * 100.0 / SUM(COUNT(CASE WHEN churn = '0' THEN 1 END)) OVER (), 2) AS percentual_nao_saiu_total_geral, 
       ROUND(AVG(salario), 2) AS salario_medio_faixa
           
FROM classificacao
WHERE faixa_id IS NOT NULL
GROUP BY faixa_id, faixa_salario
ORDER BY faixa_id
