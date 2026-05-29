WITH faixa_etaria AS (
    SELECT CASE WHEN CAST(age AS INTEGER) < 20 THEN 'Faixa 1 - até 19 anos'
                WHEN CAST(age AS INTEGER) BETWEEN 20 AND 29 THEN 'Faixa 2 - entre 20 e 29 anos'
                WHEN CAST(age AS INTEGER) BETWEEN 30 AND 39 THEN 'Faixa 3 - entre 30 e 39 anos'
                WHEN CAST(age AS INTEGER) BETWEEN 40 AND 49 THEN 'Faixa 4 - entre 40 e 49 anos'
                WHEN CAST(age AS INTEGER) BETWEEN 50 AND 59 THEN 'Faixa 5 - entre 50 e 59 anos'
                WHEN CAST(age AS INTEGER) > 59 THEN 'Faixa 6 - mais de 59 anos'
                ELSE 'Faixa desconhecida'
           END AS descricao,
           churn
    FROM tb_bank_customer_churn_prediction
),
totais AS (
    SELECT COUNT(*) AS total_clientes,
           COUNT(CASE WHEN churn = '1' THEN 1 END) AS total_saiu,
           COUNT(CASE WHEN churn = '0' THEN 1 END) AS total_nao_saiu
    FROM faixa_etaria
)
SELECT fe.descricao,
       COUNT(*) AS quantidade,
       t.total_clientes AS quantidade_clientes,
       ROUND(COUNT(*) * 100.0 / t.total_clientes, 2) AS percentual_total_faixa_etaria,
       COUNT(CASE WHEN fe.churn = '1' THEN 1 END) AS quantidade_saiu,
       COUNT(CASE WHEN fe.churn = '0' THEN 1 END) AS quantidade_nao_saiu,
       ROUND(COUNT(CASE WHEN fe.churn = '1' THEN 1 END) * 100.0 / COUNT(*), 2) AS percentual_saiu_faixa_etaria,
       ROUND(COUNT(CASE WHEN fe.churn = '0' THEN 1 END) * 100.0 / COUNT(*), 2) AS percentual_nao_saiu_faixa_etaria,
       ROUND(COUNT(CASE WHEN fe.churn = '1' THEN 1 END) * 100.0 / t.total_clientes, 2) AS percentual_saiu_total,
       ROUND(COUNT(CASE WHEN fe.churn = '0' THEN 1 END) * 100.0 / t.total_clientes, 2) AS percentual_nao_saiu_total
FROM faixa_etaria fe CROSS JOIN 
     totais t
GROUP BY fe.descricao, 
         t.total_clientes
ORDER BY CASE WHEN fe.descricao LIKE 'Faixa 1%' THEN 1
              WHEN fe.descricao LIKE 'Faixa 2%' THEN 2
              WHEN fe.descricao LIKE 'Faixa 3%' THEN 3
              WHEN fe.descricao LIKE 'Faixa 4%' THEN 4
              WHEN fe.descricao LIKE 'Faixa 5%' THEN 5
              WHEN fe.descricao LIKE 'Faixa 6%' THEN 5
              ELSE 7
         END