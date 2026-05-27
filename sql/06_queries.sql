-- =============================================================
-- 06_queries.sql
-- Executes the 10 information retrieval queries.
--
-- Expected results are documented inline for reference.
-- The evaluation (Precision / Recall / F-measure) is computed
-- by evaluation/evaluate.py based on evaluation/relevance.json.
-- =============================================================

SET search_path TO grupo;

-- -- Q1: Explicit full-form AI query --------------------------
-- Expected returned docs: 2, 8
-- (only these two use "inteligência artificial" in full)
SELECT rank, id, titulo FROM buscar('inteligência artificial');

-- -- Q2: Database systems -------------------------------------
-- Expected returned docs: 1, 2, 5
-- (doc 3 has "bancos" but no "dados"; doc 4 has "dados" but no "banco")
SELECT rank, id, titulo FROM buscar('banco de dados');

-- -- Q3: PostgreSQL-specific -----------------------------------
-- Expected returned docs: 1
SELECT rank, id, titulo FROM buscar('PostgreSQL');

-- -- Q4: Acronym query - demonstrates stop-word limitation ----
-- "ia" is a Portuguese stop word (past imperfect of "ir"),
-- so websearch_to_tsquery returns an empty query -> 0 results.
-- Expected returned docs: none
SELECT rank, id, titulo FROM buscar('IA');

-- -- Q5: Performance ------------------------------------------
-- Expected returned docs: 1, 6
-- (doc 10 is relevant -AI precision in medicine- but uses
--  "precisão", not "desempenho", so it is missed)
SELECT rank, id, titulo FROM buscar('desempenho');

-- -- Q6: Security ---------------------------------------------
-- Expected returned docs: 1, 9
-- (doc 5 is relevant but uses "criptografia"/"controle de acesso",
--  never the stem of "segurança")
SELECT rank, id, titulo FROM buscar('segurança');

-- -- Q7: Regulation -------------------------------------------
-- Expected returned docs: 5, 9
SELECT rank, id, titulo FROM buscar('regulamentação');

-- -- Q8: Machine Learning -------------------------------------
-- Expected returned docs: 4
SELECT rank, id, titulo FROM buscar('machine learning');

-- -- Q9: Raw "dados" - demonstrates false positive ------------
-- Expected returned docs: 1, 2, 4, 5, 8
-- Doc 8 is returned ("análise de dados") but is not a database
-- doc; doc 3 is a database doc but uses "bancos" without "dados".
SELECT rank, id, titulo FROM buscar('dados');

-- -- Q10: Healthcare ------------------------------------------
-- Expected returned docs: 10
SELECT rank, id, titulo FROM buscar('saúde');
