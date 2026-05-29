WITH min_max AS (
    SELECT MIN(CAST(credit_score AS INTEGER)) AS min_pontuacao_credito,
           MAX(CAST(credit_score AS INTEGER)) AS max_pontuacao_credito
    FROM tb_bank_customer_churn_prediction
),
faixas AS (
    SELECT min_pontuacao_credito,
           max_pontuacao_credito,
           (max_pontuacao_credito - min_pontuacao_credito) / 5 AS tamanho_faixa
    FROM min_max
),
classificacao AS (
    SELECT  churn, pontuacao_credito, -- faixas.*,
            CASE WHEN pontuacao_credito BETWEEN faixas.min_pontuacao_credito AND faixas.min_pontuacao_credito + faixas.tamanho_faixa THEN 1
                 WHEN pontuacao_credito BETWEEN faixas.min_pontuacao_credito + faixas.tamanho_faixa AND faixas.min_pontuacao_credito + 2 * faixas.tamanho_faixa THEN 2
                 WHEN pontuacao_credito BETWEEN faixas.min_pontuacao_credito + 2 * faixas.tamanho_faixa AND faixas.min_pontuacao_credito + 3 * faixas.tamanho_faixa THEN 3
                 WHEN pontuacao_credito BETWEEN faixas.min_pontuacao_credito + 3 * faixas.tamanho_faixa AND faixas.min_pontuacao_credito + 4 * faixas.tamanho_faixa THEN 4
                 WHEN pontuacao_credito BETWEEN faixas.min_pontuacao_credito + 4 * faixas.tamanho_faixa AND faixas.max_pontuacao_credito THEN 5
                 ELSE NULL
            END AS faixa_id,
            CASE WHEN pontuacao_credito BETWEEN faixas.min_pontuacao_credito AND faixas.min_pontuacao_credito + faixas.tamanho_faixa
                     THEN CONCAT('Faixa 1 - ', CAST(faixas.min_pontuacao_credito AS VARCHAR(15)), ' até ', CAST(ROUND(faixas.min_pontuacao_credito + faixas.tamanho_faixa,2) AS VARCHAR(15)))
                 WHEN pontuacao_credito BETWEEN faixas.min_pontuacao_credito + faixas.tamanho_faixa+1 AND faixas.min_pontuacao_credito + 2 * faixas.tamanho_faixa
                     THEN CONCAT('Faixa 2 - ', CAST(faixas.min_pontuacao_credito + faixas.tamanho_faixa+1 AS VARCHAR(15)), ' até ', CAST(ROUND(faixas.min_pontuacao_credito + 2 * faixas.tamanho_faixa,2) AS VARCHAR(15)))
                 WHEN pontuacao_credito BETWEEN faixas.min_pontuacao_credito + 2 * faixas.tamanho_faixa+1 AND faixas.min_pontuacao_credito + 3 * faixas.tamanho_faixa
                     THEN CONCAT('Faixa 3 - ', CAST(faixas.min_pontuacao_credito + 2 * faixas.tamanho_faixa+1  AS VARCHAR(15)), ' até ', CAST(ROUND(faixas.min_pontuacao_credito + 3 * faixas.tamanho_faixa,2) AS VARCHAR(15)))
                 WHEN pontuacao_credito BETWEEN faixas.min_pontuacao_credito + 3 * faixas.tamanho_faixa+1 AND faixas.min_pontuacao_credito + 4 * faixas.tamanho_faixa
                     THEN CONCAT('Faixa 4 - ', CAST(faixas.min_pontuacao_credito + 3 * faixas.tamanho_faixa+1 AS VARCHAR(15)), ' até ', CAST(ROUND(faixas.min_pontuacao_credito + 4 * faixas.tamanho_faixa,2) AS VARCHAR(15)))
                 WHEN pontuacao_credito BETWEEN faixas.min_pontuacao_credito + 4 * faixas.tamanho_faixa+1 AND faixas.max_pontuacao_credito
                     THEN CONCAT('Faixa 5 - ', CAST(faixas.min_pontuacao_credito + 4 * faixas.tamanho_faixa+0.01 AS VARCHAR(15)), ' até ', CAST(ROUND(faixas.max_pontuacao_credito,2) AS VARCHAR(15)))
                 ELSE 'Fora das faixas'
            END AS faixa_pontuacao_credito
    FROM (SELECT CAST(credit_score AS INTEGER) AS pontuacao_credito, churn
          FROM tb_bank_customer_churn_prediction
    ) t CROSS JOIN faixas
)
--select * from classificacao

SELECT faixa_pontuacao_credito,
       COUNT(*) AS quantidade,
       COUNT(CASE WHEN churn = '1' THEN 1 END) AS quantidade_saiu,
       COUNT(CASE WHEN churn = '0' THEN 1 END) AS quantidade_nao_saiu,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentual_clientes_total,
       ROUND(COUNT(CASE WHEN churn = '1' THEN 1 END) * 100.0 / COUNT(*), 2) AS percentual_saiu_faixa,
       ROUND(COUNT(CASE WHEN churn = '0' THEN 1 END) * 100.0 / COUNT(*), 2) AS percentual_nao_saiu_faixa,
       ROUND(COUNT(CASE WHEN churn = '1' THEN 1 END) * 100.0 / SUM(COUNT(CASE WHEN churn = '1' THEN 1 END)) OVER (), 2) AS percentual_saiu_total_geral,
       ROUND(COUNT(CASE WHEN churn = '0' THEN 1 END) * 100.0 / SUM(COUNT(CASE WHEN churn = '0' THEN 1 END)) OVER (), 2) AS percentual_nao_saiu_total_geral, 
       ROUND(AVG(pontuacao_credito), 2) AS pontuacao_credito_medio_faixa
       
FROM classificacao
WHERE faixa_id IS NOT NULL
GROUP BY faixa_id, faixa_pontuacao_credito
ORDER BY faixa_id;
