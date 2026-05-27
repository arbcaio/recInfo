-- =============================================================
-- main.sql
-- All-in-one script: run this single file in pgAdmin to
-- set up the complete IR system and execute all 10 queries.
--
-- Before running, replace every occurrence of "grupo" with
-- your group name (e.g., grupo1).
-- =============================================================


-- -- 1. Schema -------------------------------------------------

CREATE SCHEMA IF NOT EXISTS grupo;
SET search_path TO grupo;


-- -- 2. Documents table ----------------------------------------

CREATE TABLE IF NOT EXISTS documentos (
    id                      SERIAL PRIMARY KEY,
    titulo                  TEXT NOT NULL,
    conteudo                TEXT NOT NULL,
    representacao_documento TSVECTOR GENERATED ALWAYS AS (
        setweight(to_tsvector('portuguese', COALESCE(titulo,   '')), 'A') ||
        setweight(to_tsvector('portuguese', COALESCE(conteudo, '')), 'B')
    ) STORED
);


-- -- 3. Documents ----------------------------------------------

INSERT INTO documentos (titulo, conteudo) VALUES

('Nova versão do PostgreSQL melhora desempenho',
 'A comunidade do PostgreSQL anunciou melhorias significativas de desempenho '
 'em consultas complexas, com foco em paralelismo e otimização de índices. '
 'A atualização também traz avanços em replicação e segurança.'),

('Oracle Corporation investe em banco de dados autônomo',
 'A Oracle segue expandindo seu banco de dados autônomo, que utiliza '
 'inteligência artificial para automação de tuning, backup e escalabilidade, '
 'reduzindo a necessidade de administração manual.'),

('Cresce uso do MongoDB em aplicações modernas',
 'Empresas continuam adotando bancos NoSQL como o MongoDB para aplicações '
 'que exigem flexibilidade de esquema e alta escalabilidade, especialmente '
 'em ambientes de microserviços.'),

('Microsoft amplia recursos do Azure SQL',
 'O Azure SQL recebeu novos recursos de análise em tempo real e integração '
 'com ferramentas de machine learning, facilitando a construção de aplicações '
 'orientadas a dados na nuvem.'),

('Debate sobre privacidade impacta bancos de dados',
 'Especialistas alertam que regulamentações de proteção de dados estão '
 'mudando a forma como bancos de dados são projetados, exigindo maior '
 'controle de acesso, auditoria e criptografia.'),

('OpenAI lança novos modelos mais eficientes',
 'A OpenAI anunciou uma nova geração de modelos de IA com melhor desempenho '
 'e menor consumo computacional, ampliando o uso em aplicações comerciais '
 'e educacionais.'),

('Google avança em IA generativa',
 'O Google apresentou melhorias em seus sistemas de IA generativa, com foco '
 'em integração entre busca, produtividade e criação de conteúdo multimodal.'),

('Microsoft expande uso de IA no trabalho',
 'A Microsoft está incorporando inteligência artificial em ferramentas '
 'corporativas, automatizando tarefas como análise de dados, redação e '
 'atendimento ao cliente.'),

('Regulamentação de IA ganha força na União Europeia',
 'Novas leis buscam garantir transparência e segurança no uso de IA, '
 'impondo regras mais rígidas para sistemas considerados de alto risco.'),

('IA transforma setor de saúde',
 'Hospitais e clínicas estão adotando soluções baseadas em IA para '
 'diagnóstico precoce e análise de exames, aumentando a precisão e '
 'reduzindo custos operacionais.');


-- -- 4. GIN index ----------------------------------------------

CREATE INDEX IF NOT EXISTS idx_documentos_fts
    ON documentos
    USING GIN (representacao_documento);


-- -- 5. Functions ----------------------------------------------

CREATE OR REPLACE FUNCTION representacao_consulta(consulta TEXT)
RETURNS tsquery AS $$
    SELECT websearch_to_tsquery('portuguese', consulta);
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION buscar(consulta TEXT)
RETURNS TABLE (
    rank                    REAL,
    id                      INT,
    titulo                  TEXT,
    conteudo                TEXT,
    representacao_documento TSVECTOR
) AS $$
    SELECT
        ts_rank(d.representacao_documento,
                representacao_consulta(consulta)) AS rank,
        d.id,
        d.titulo,
        d.conteudo,
        d.representacao_documento
    FROM  documentos d
    WHERE d.representacao_documento @@ representacao_consulta(consulta)
    ORDER BY rank DESC;
$$ LANGUAGE SQL STABLE;


-- -- 6. Verify documents ---------------------------------------

SELECT id, titulo, representacao_documento FROM documentos;


-- -- 7. Queries ------------------------------------------------

-- Q1
SELECT rank, id, titulo FROM buscar('inteligência artificial');

-- Q2
SELECT rank, id, titulo FROM buscar('banco de dados');

-- Q3
SELECT rank, id, titulo FROM buscar('PostgreSQL');

-- Q4 - stop-word test (expects 0 results)
SELECT rank, id, titulo FROM buscar('IA');

-- Q5
SELECT rank, id, titulo FROM buscar('desempenho');

-- Q6
SELECT rank, id, titulo FROM buscar('segurança');

-- Q7
SELECT rank, id, titulo FROM buscar('regulamentação');

-- Q8
SELECT rank, id, titulo FROM buscar('machine learning');

-- Q9
SELECT rank, id, titulo FROM buscar('dados');

-- Q10
SELECT rank, id, titulo FROM buscar('saúde');
