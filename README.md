# Recuperação da Informação em Bancos de Dados Relacionais

**Discipline:** Recuperação de Informação  
**Professor:** Prof. Dr. Bruno Tenório Ávila  
**Assignment:** Aula 7 — Sistema de RI com PostgreSQL Full Text Search  
**Deadline:** 01/06/2026 até às 19:00

---

## Objective

Build an information retrieval system inside a PostgreSQL relational database using the native Full Text Search (FTS) module. The system must:

1. Store 10 documents.
2. Perform 10 queries using the `buscar()` function.
3. Manually identify relevant documents for each query.
4. Calculate **Precision**, **Recall (Cobertura)**, and **F-measure** for each query.

---

## Project Structure

```
recInfo/
├── sql/
│   ├── 01_schema.sql           # Create schema
│   ├── 02_table_documents.sql  # Create table with tsvector column
│   ├── 03_insert_documents.sql # Insert 10 documents
│   ├── 04_index.sql            # Create GIN inverted index
│   ├── 05_functions.sql        # Search helper functions
│   ├── 06_queries.sql          # 10 queries
│   └── main.sql                # All-in-one script
├── evaluation/
│   ├── relevance.json          # Manual relevance judgments
│   ├── evaluate.py             # Metrics computation script (Python)
│   └── results.csv             # Output from evaluate.py
└── report/
    └── report.md               # Final performance evaluation report
```

---

## How to Run

### 1. Connect to the database in pgAdmin

```
host:     agade.ufpe.br
port:     5432
database: disciplinas
username: disciplinas
password: @g@d4
```

### 2. Rename the schema (required — each group uses a unique schema)

Open `sql/main.sql` and replace every occurrence of `grupo` with your group name (e.g., `grupo1`).

### 3. Execute the main script

Open `sql/main.sql` in the pgAdmin Query Tool and run it.  
This will create the schema, table, index, functions, and run all queries.

---

## How to Calculate Metrics Locally

Make sure Python 3 is installed, then run:

```bash
python evaluation/evaluate.py
```

Results are printed to the terminal and saved to `evaluation/results.csv`.

---

## Key Concepts

| Term | Description |
|------|-------------|
| `tsvector` | PostgreSQL's internal representation of a document (stemmed tokens + weights) |
| `tsquery` | Representation of a search query |
| `GIN index` | Generalized Inverted Index — efficient for FTS |
| `ts_rank` | Scoring function based on term frequency and weight |
| `setweight` | Assigns weight A (title) or B (content) to tokens |
| Precision | Proportion of retrieved documents that are relevant |
| Recall | Proportion of relevant documents that are retrieved |
| F-measure | Harmonic mean of Precision and Recall |
