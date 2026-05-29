WITH clientes_ativos_inativos AS (
    SELECT active_member,
           COUNT(*) AS quantidade_total_clientes,
           COUNT(CASE WHEN churn = '1' THEN 1 END) AS quantidade_clientes_saiu,
           COUNT(CASE WHEN churn = '0' THEN 1 END) AS quantidade_clientes_nao_saiu
    FROM tb_bank_customer_churn_prediction
    GROUP BY active_member
),
totais AS (
    SELECT SUM(quantidade_total_clientes) AS total_geral,
           SUM(quantidade_clientes_saiu) AS total_saiu,
           SUM(quantidade_clientes_nao_saiu) AS total_nao_saiu
    FROM clientes_ativos_inativos
)
SELECT npc.active_member,
       total_geral,
       npc.quantidade_total_clientes AS quantidade_clientes,
       npc.quantidade_clientes_saiu AS quantidade_clientes_saiu,
       npc.quantidade_clientes_nao_saiu AS quantidade_clientes_nao_saiu,
       ROUND(npc.quantidade_clientes_saiu * 100.0 / npc.quantidade_total_clientes, 2) AS percentual_saiu,
       ROUND(npc.quantidade_clientes_nao_saiu * 100.0 / npc.quantidade_total_clientes, 2) AS percentual_nao_saiu,
       ROUND(npc.quantidade_clientes_saiu * 100.0 / t.total_geral, 2) AS percentual_saiu_total,
       ROUND(npc.quantidade_clientes_nao_saiu * 100.0 / t.total_geral, 2) AS percentual_nao_saiu_total,
       ROUND(npc.quantidade_total_clientes * 100.0 / t.total_geral, 2) AS percentual_clientes_total
FROM clientes_ativos_inativos npc CROSS JOIN 
     totais t
ORDER BY npc.active_member