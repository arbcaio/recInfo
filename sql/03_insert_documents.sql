-- =============================================================
-- 03_insert_documents.sql
-- Inserts 10 documents covering two main topics:
--   - Relational/NoSQL database systems (docs 1–5)
--   - Artificial Intelligence and its applications (docs 6–10)
--
-- The topical split is intentional: several queries span both
-- groups, making the evaluation of Recall more interesting.
-- =============================================================

SET search_path TO grupo;

INSERT INTO documentos (titulo, conteudo) VALUES

-- ── DATABASE SYSTEMS ──────────────────────────────────────────

(
    'Nova versão do PostgreSQL melhora desempenho',
    'A comunidade do PostgreSQL anunciou melhorias significativas de desempenho '
    'em consultas complexas, com foco em paralelismo e otimização de índices. '
    'A atualização também traz avanços em replicação e segurança.'
),

(
    'Oracle Corporation investe em banco de dados autônomo',
    'A Oracle segue expandindo seu banco de dados autônomo, que utiliza '
    'inteligência artificial para automação de tuning, backup e escalabilidade, '
    'reduzindo a necessidade de administração manual.'
),

(
    'Cresce uso do MongoDB em aplicações modernas',
    'Empresas continuam adotando bancos NoSQL como o MongoDB para aplicações '
    'que exigem flexibilidade de esquema e alta escalabilidade, especialmente '
    'em ambientes de microserviços.'
),

(
    'Microsoft amplia recursos do Azure SQL',
    'O Azure SQL recebeu novos recursos de análise em tempo real e integração '
    'com ferramentas de machine learning, facilitando a construção de aplicações '
    'orientadas a dados na nuvem.'
),

(
    'Debate sobre privacidade impacta bancos de dados',
    'Especialistas alertam que regulamentações de proteção de dados estão '
    'mudando a forma como bancos de dados são projetados, exigindo maior '
    'controle de acesso, auditoria e criptografia.'
),

-- ── ARTIFICIAL INTELLIGENCE ───────────────────────────────────

(
    'OpenAI lança novos modelos mais eficientes',
    'A OpenAI anunciou uma nova geração de modelos de IA com melhor desempenho '
    'e menor consumo computacional, ampliando o uso em aplicações comerciais '
    'e educacionais.'
),

(
    'Google avança em IA generativa',
    'O Google apresentou melhorias em seus sistemas de IA generativa, com foco '
    'em integração entre busca, produtividade e criação de conteúdo multimodal.'
),

(
    'Microsoft expande uso de IA no trabalho',
    'A Microsoft está incorporando inteligência artificial em ferramentas '
    'corporativas, automatizando tarefas como análise de dados, redação e '
    'atendimento ao cliente.'
),

(
    'Regulamentação de IA ganha força na União Europeia',
    'Novas leis buscam garantir transparência e segurança no uso de IA, '
    'impondo regras mais rígidas para sistemas considerados de alto risco.'
),

(
    'IA transforma setor de saúde',
    'Hospitais e clínicas estão adotando soluções baseadas em IA para '
    'diagnóstico precoce e análise de exames, aumentando a precisão e '
    'reduzindo custos operacionais.'
);
