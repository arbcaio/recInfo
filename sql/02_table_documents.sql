-- =============================================================
-- 02_table_documents.sql
-- Creates the documents table with an auto-generated tsvector
-- column that represents each document for full-text search.
--
-- The representation_documento column:
--   - Weight A: titulo  (higher relevance)
--   - Weight B: conteudo (lower relevance)
-- =============================================================

SET search_path TO grupo;

CREATE TABLE IF NOT EXISTS documentos (
    id                      SERIAL PRIMARY KEY,
    titulo                  TEXT NOT NULL,
    conteudo                TEXT NOT NULL,
    representacao_documento TSVECTOR GENERATED ALWAYS AS (
        setweight(to_tsvector('portuguese', COALESCE(titulo,   '')), 'A') ||
        setweight(to_tsvector('portuguese', COALESCE(conteudo, '')), 'B')
    ) STORED
);
