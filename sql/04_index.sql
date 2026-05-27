-- =============================================================
-- 04_index.sql
-- Creates a GIN (Generalized Inverted Index) over the
-- representacao_documento tsvector column.
--
-- GIN maps each lexeme to the set of document IDs that contain
-- it, enabling O(log N + K) lookup instead of a full table scan.
-- =============================================================

SET search_path TO grupo;

CREATE INDEX IF NOT EXISTS idx_documentos_fts
    ON documentos
    USING GIN (representacao_documento);
