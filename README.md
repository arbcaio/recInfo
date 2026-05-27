# Recuperação da Informação em Bancos de Dados Relacionais

> Trabalho prático da disciplina **Recuperação de Informação** — implementação de um sistema de busca usando o módulo Full Text Search (FTS) nativo do PostgreSQL.

---

## 👥 Grupo

| Nome | Matrícula |
|------|-----------|
| Agenor Luiz | — |
| Caio Braga | — |
| Dayvid Willams | — |
| Luiz Anjos | — |
| Maria Luiza | — |

**Professor:** Prof. Dr. Bruno Tenório Ávila  
**Disciplina:** Recuperação de Informação — UFPE  
**Entrega:** 01/06/2026 até às 19:00

---

## 📋 Descrição

O objetivo deste trabalho é criar um **sistema de recuperação da informação** dentro de um banco de dados relacional PostgreSQL, explorando o recurso nativo de *Full Text Search* (FTS).

O sistema realiza todas as etapas clássicas de um motor de busca:

1. **Aquisição** — 10 documentos em português inseridos diretamente no banco.
2. **Representação** — cada documento é indexado como um `tsvector` com pesos diferenciados por campo (título = peso A, conteúdo = peso B).
3. **Índice invertido** — criação de um índice GIN (*Generalized Inverted Index*) sobre o `tsvector`.
4. **Recuperação** — função `buscar()` que converte a consulta em `tsquery`, casa com os documentos via operador `@@` e os ordena por `ts_rank`.
5. **Avaliação** — cálculo de Precisão, Cobertura (Recall) e F-measure para cada uma das 10 consultas realizadas.

---

## 🗂️ Estrutura do Projeto

```
recInfo/
├── sql/
│   ├── 01_schema.sql           # Cria o schema do grupo
│   ├── 02_table_documents.sql  # Cria a tabela com coluna tsvector gerada
│   ├── 03_insert_documents.sql # Insere os 10 documentos
│   ├── 04_index.sql            # Cria o índice GIN invertido
│   ├── 05_functions.sql        # Funções representacao_consulta() e buscar()
│   ├── 06_queries.sql          # Executa as 10 consultas
│   └── main.sql                # Script único (tudo em um) para o pgAdmin
├── evaluation/
│   ├── relevance.json          # Julgamentos de relevância manuais
│   ├── evaluate.py             # Script Python que calcula as métricas
│   └── results.csv             # Saída gerada pelo evaluate.py
├── report/
│   └── report.md               # Relatório completo com análise de desempenho
├── .gitignore
├── requirements.txt
└── README.md
```

---

## 🚀 Como Executar

### 1. Conectar ao banco via pgAdmin

```
host:     agade.ufpe.br
port:     5432
database: disciplinas
username: disciplinas
password: @g@d4
```

### 2. Renomear o schema

Abra `sql/main.sql` e substitua **todas** as ocorrências de `grupo` pelo nome do seu grupo (ex: `grupo1`).

### 3. Rodar o script no pgAdmin

Abra `sql/main.sql` no *Query Tool* e execute. O script cria o schema, a tabela, o índice, as funções e roda as 10 consultas em sequência.

---

## 📊 Calcular Métricas Localmente

Requer Python 3.8+. Nenhuma dependência externa é necessária.

```bash
python evaluation/evaluate.py
```

Resultado impresso no terminal e salvo em `evaluation/results.csv`.

### Resumo dos resultados

| # | Consulta | Precisão | Cobertura | F-measure |
|:-:|----------|:--------:|:---------:|:---------:|
| 1 | inteligência artificial | 1,00 | 0,33 | 0,50 |
| 2 | banco de dados | 1,00 | 0,60 | 0,75 |
| 3 | PostgreSQL | 1,00 | 1,00 | 1,00 |
| 4 | IA *(stop word)* | 0,00 | 0,00 | 0,00 |
| 5 | desempenho | 1,00 | 0,67 | 0,80 |
| 6 | segurança | 1,00 | 0,67 | 0,80 |
| 7 | regulamentação | 1,00 | 1,00 | 1,00 |
| 8 | machine learning | 1,00 | 1,00 | 1,00 |
| 9 | dados | 0,80 | 0,80 | 0,80 |
| 10 | saúde | 1,00 | 1,00 | 1,00 |
| | **Média** | **0,88** | **0,71** | **0,76** |

---

## 🔑 Conceitos-chave

| Termo | Descrição |
|-------|-----------|
| `tsvector` | Representação interna do documento: radicais ordenados + pesos |
| `tsquery` | Representação da consulta em radicais |
| `GIN` | Índice invertido generalizado — busca em O(log N + K) |
| `ts_rank` | Função de pontuação (frequência + peso por campo) |
| `setweight` | Atribui peso A (título) ou B (conteúdo) aos tokens |
| Precisão | \|Relevantes ∩ Retornados\| / \|Retornados\| |
| Cobertura | \|Relevantes ∩ Retornados\| / \|Relevantes\| |
| F-measure | 2 × P × R / (P + R) |

---

## 📚 Referências

- [PostgreSQL — Chapter 12: Full Text Search](https://www.postgresql.org/docs/current/textsearch.html)
- [Apache Lucene](https://lucene.apache.org/)
- [Elasticsearch](https://www.elastic.co/)
- [Apache Solr](https://solr.apache.org/)
