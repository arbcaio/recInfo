-- =============================================================
-- 05_functions.sql
-- Two helper functions that implement the retrieval pipeline:
--
--   representacao_consulta(text) -> tsquery
--     Converts a free-text query into a tsquery using the
--     Portuguese lexeme configuration.  websearch_to_tsquery
--     also supports Google-style operators: -word, "phrase".
--
--   buscar(text) -> TABLE
--     Matches documents against the query via the @@ operator,
--     scores them with ts_rank (TF-like + setweight bonuses),
--     and returns results ordered by rank descending.
-- =============================================================

SET search_path TO grupo;

-- ── Query representation ──────────────────────────────────────

CREATE OR REPLACE FUNCTION representacao_consulta(consulta TEXT)
RETURNS tsquery AS $$
    SELECT websearch_to_tsquery('portuguese', consulta);
$$ LANGUAGE SQL IMMUTABLE;

-- ── Search, matching and ranking ──────────────────────────────

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
                representacao_consulta(consulta))   AS rank,
        d.id,
        d.titulo,
        d.conteudo,
        d.representacao_documento
    FROM  documentos d
    WHERE d.representacao_documento @@ representacao_consulta(consulta)
    ORDER BY rank DESC;
$$ LANGUAGE SQL STABLE;
