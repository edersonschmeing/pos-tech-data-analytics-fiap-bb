WITH min_max AS (
    SELECT MIN(CAST(balance AS DECIMAL(14,2))) AS min_saldo,
           MAX(CAST(balance AS DECIMAL(14,2))) AS max_saldo
    FROM tb_bank_customer_churn_prediction
),
faixas AS (
    SELECT min_saldo,
           max_saldo,
           --(max_saldo - min_saldo) / 5 AS tamanho_faixa
           50000 as tamanho_faixa
    FROM min_max
),
classificacao AS (
    SELECT  churn, saldo, -- faixas.*,
            CASE WHEN saldo BETWEEN faixas.min_saldo AND faixas.min_saldo + faixas.tamanho_faixa THEN 1
                 WHEN saldo BETWEEN faixas.min_saldo + faixas.tamanho_faixa AND faixas.min_saldo + 2 * faixas.tamanho_faixa THEN 2
                 WHEN saldo BETWEEN faixas.min_saldo + 2 * faixas.tamanho_faixa AND faixas.min_saldo + 3 * faixas.tamanho_faixa THEN 3
                 WHEN saldo BETWEEN faixas.min_saldo + 3 * faixas.tamanho_faixa AND faixas.min_saldo + 4 * faixas.tamanho_faixa THEN 4
                 WHEN saldo BETWEEN faixas.min_saldo + 4 * faixas.tamanho_faixa AND faixas.max_saldo THEN 5
                 ELSE NULL
            END AS faixa_id,
            CASE WHEN saldo BETWEEN faixas.min_saldo AND faixas.min_saldo + faixas.tamanho_faixa
                     THEN CONCAT('Faixa 1 - ', CAST(ROUND(faixas.min_saldo,2) AS VARCHAR(15)), ' até ', CAST(ROUND(faixas.min_saldo + faixas.tamanho_faixa,2) AS VARCHAR(15)))
                 WHEN saldo BETWEEN faixas.min_saldo + faixas.tamanho_faixa+0.01 AND faixas.min_saldo + 2 * faixas.tamanho_faixa
                     THEN CONCAT('Faixa 2 - ', CAST(ROUND(faixas.min_saldo + faixas.tamanho_faixa+0.01,2) AS VARCHAR(15)), ' até ', CAST(ROUND(faixas.min_saldo + 2 * faixas.tamanho_faixa,2) AS VARCHAR(15)))
                 WHEN saldo BETWEEN faixas.min_saldo + 2 * faixas.tamanho_faixa+0.01 AND faixas.min_saldo + 3 * faixas.tamanho_faixa
                     THEN CONCAT('Faixa 3 - ', CAST(ROUND(faixas.min_saldo + 2 * faixas.tamanho_faixa+0.01,2)  AS VARCHAR(15)), ' até ', CAST(ROUND(faixas.min_saldo + 3 * faixas.tamanho_faixa,2) AS VARCHAR(15)))
                 WHEN saldo BETWEEN faixas.min_saldo + 3 * faixas.tamanho_faixa+0.01 AND faixas.min_saldo + 4 * faixas.tamanho_faixa
                     THEN CONCAT('Faixa 4 - ', CAST(ROUND(faixas.min_saldo + 3 * faixas.tamanho_faixa+0.01,2) AS VARCHAR(15)), ' até ', CAST(ROUND(faixas.min_saldo + 4 * faixas.tamanho_faixa,2) AS VARCHAR(15)))
                 WHEN saldo BETWEEN faixas.min_saldo + 4 * faixas.tamanho_faixa+0.01 AND faixas.max_saldo
                     THEN CONCAT('Faixa 5 - ', CAST(ROUND(faixas.min_saldo + 4 * faixas.tamanho_faixa+0.01,2) AS VARCHAR(15)), ' até ', CAST(ROUND(faixas.max_saldo,2) AS VARCHAR(15)))
                 ELSE 'Fora das faixas'
            END AS faixa_saldo
    FROM (SELECT CAST(balance AS DECIMAL(14,2)) AS saldo, churn
          FROM tb_bank_customer_churn_prediction
    ) t CROSS JOIN faixas
)
--select * from classificacao
SELECT faixa_saldo,
       COUNT(*) AS quantidade,
       COUNT(CASE WHEN churn = '1' THEN 1 END) AS quantidade_saiu,
       COUNT(CASE WHEN churn = '0' THEN 1 END) AS quantidade_nao_saiu,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentual_clientes_total,
       ROUND(COUNT(CASE WHEN churn = '1' THEN 1 END) * 100.0 / COUNT(*), 2) AS percentual_saiu_faixa,
       ROUND(COUNT(CASE WHEN churn = '0' THEN 1 END) * 100.0 / COUNT(*), 2) AS percentual_nao_saiu_faixa,
       ROUND(COUNT(CASE WHEN churn = '1' THEN 1 END) * 100.0 / SUM(COUNT(CASE WHEN churn = '1' THEN 1 END)) OVER (), 2) AS percentual_saiu_total_geral,
       ROUND(COUNT(CASE WHEN churn = '0' THEN 1 END) * 100.0 / SUM(COUNT(CASE WHEN churn = '0' THEN 1 END)) OVER (), 2) AS percentual_nao_saiu_total_geral, 
       ROUND(AVG(saldo), 2) AS saldo_medio_faixa
       
FROM classificacao
WHERE faixa_id IS NOT NULL
GROUP BY faixa_id, faixa_saldo
ORDER BY faixa_id;
