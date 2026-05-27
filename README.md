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

## 🚀 Passo a Passo para Executar

### Pré-requisitos

- **pgAdmin 4** instalado → [pgadmin.org/download](https://www.pgadmin.org/download/)
- **Python 3.8+** instalado → [python.org/downloads](https://www.python.org/downloads/) *(somente para calcular as métricas localmente)*
- Acesso à rede da UFPE (ou VPN, se estiver fora do campus)

---

### Parte 1 — Executar o sistema no PostgreSQL (pgAdmin)

#### Passo 1 — Abrir o pgAdmin e criar o servidor

1. Abra o **pgAdmin 4**.
2. No painel esquerdo (*Browser*), clique com o botão direito em **Servers** → **Register → Server…**
3. Na aba **General**, preencha o campo *Name* com qualquer nome, por exemplo: `UFPE`.
4. Na aba **Connection**, preencha:

   | Campo | Valor |
   |-------|-------|
   | Host name / address | `agade.ufpe.br` |
   | Port | `5432` |
   | Maintenance database | `disciplinas` |
   | Username | `disciplinas` |
   | Password | `@g@d4` |

5. Marque **Save password** para não precisar digitar toda vez.
6. Clique em **Save**. O servidor `UFPE` aparecerá na árvore do Browser.

---

#### Passo 2 — Renomear o schema no script

> ⚠️ Cada grupo deve usar um schema exclusivo para não conflitar com os demais.

1. Abra o arquivo `sql/main.sql` em qualquer editor de texto (VS Code, Notepad++, etc.).
2. Use o **Localizar e Substituir** (`Ctrl+H` no VS Code):
   - Localizar: `grupo`
   - Substituir por: o nome do seu grupo, por exemplo `grupo1`
3. Salve o arquivo.

---

#### Passo 3 — Abrir o Query Tool

1. No painel esquerdo do pgAdmin, expanda: **UFPE → Databases → disciplinas**.
2. Clique com o botão direito em **disciplinas** → **Query Tool**.
3. Uma aba de editor SQL será aberta.

---

#### Passo 4 — Carregar e executar o script

1. No Query Tool, clique no ícone de pasta 📂 (*Open File*) ou use `Ctrl+O`.
2. Navegue até a pasta do projeto e selecione **`sql/main.sql`**.
3. Clique em **▶ Execute / Refresh** (ou pressione `F5`) para rodar o script inteiro.
4. Acompanhe o painel de *Messages* na parte inferior — você deve ver mensagens como:
   ```
   CREATE SCHEMA
   CREATE TABLE
   INSERT 0 10
   CREATE INDEX
   CREATE FUNCTION
   CREATE FUNCTION
   ```

---

#### Passo 5 — Verificar os documentos indexados

Após a execução, rode manualmente a query abaixo para confirmar que os 10 documentos foram inseridos e o `tsvector` foi gerado corretamente:

```sql
SET search_path TO grupo1;   -- use o nome do seu grupo
SELECT id, titulo, representacao_documento FROM documentos;
```

A coluna `representacao_documento` deve exibir os radicais e seus pesos, por exemplo:
```
'anunc':11B 'atualiz':28B 'avanc':31B ...
```

---

#### Passo 6 — Executar as consultas individualmente

As 10 consultas são executadas automaticamente pelo `main.sql`. Para rodá-las uma a uma, use o arquivo `sql/06_queries.sql` ou copie diretamente no Query Tool:

```sql
SET search_path TO grupo1;

SELECT rank, id, titulo FROM buscar('inteligência artificial');
SELECT rank, id, titulo FROM buscar('banco de dados');
SELECT rank, id, titulo FROM buscar('PostgreSQL');
SELECT rank, id, titulo FROM buscar('IA');
SELECT rank, id, titulo FROM buscar('desempenho');
SELECT rank, id, titulo FROM buscar('segurança');
SELECT rank, id, titulo FROM buscar('regulamentação');
SELECT rank, id, titulo FROM buscar('machine learning');
SELECT rank, id, titulo FROM buscar('dados');
SELECT rank, id, titulo FROM buscar('saúde');
```

> 💡 No pgAdmin, selecione **apenas uma linha** e pressione `F5` para executar somente aquela consulta e ver seu resultado separadamente.

---

### Parte 2 — Calcular as métricas (Python)

#### Passo 7 — Rodar o script de avaliação

Abra um terminal na pasta raiz do projeto e execute:

```bash
python evaluation/evaluate.py
```

A saída esperada no terminal é:

```
------------------------------------------------------------------------------
 #  Query                         Relev  Retr  TP  FP  FN   Prec    Rec      F
------------------------------------------------------------------------------
 1  inteligência artificial           6     2   2   0   4   1.00   0.33   0.50
 2  banco de dados                    5     3   3   0   2   1.00   0.60   0.75
 3  PostgreSQL                        1     1   1   0   0   1.00   1.00   1.00
 4  IA                                6     0   0   0   6   0.00   0.00   0.00
 5  desempenho                        3     2   2   0   1   1.00   0.67   0.80
 6  segurança                         3     2   2   0   1   1.00   0.67   0.80
 7  regulamentação                    2     2   2   0   0   1.00   1.00   1.00
 8  machine learning                  1     1   1   0   0   1.00   1.00   1.00
 9  dados                             5     5   4   1   1   0.80   0.80   0.80
10  saúde                             1     1   1   0   0   1.00   1.00   1.00
------------------------------------------------------------------------------
    AVERAGE                                                 0.88   0.71   0.76
------------------------------------------------------------------------------
```

Os resultados também são salvos em `evaluation/results.csv`.

---

### ❗ Solução de Problemas

| Problema | Causa provável | Solução |
|----------|---------------|---------|
| `could not connect to server` | Fora da rede UFPE | Conecte à VPN da UFPE |
| `schema "grupo" already exists` | Script rodado sem renomear | Substitua `grupo` pelo nome do seu grupo no `main.sql` |
| `function buscar() does not exist` | Script não foi executado por completo | Rode `main.sql` inteiro (`F5` sem seleção) |
| `ERROR: duplicate key value` | Script rodado mais de uma vez | Execute `DROP SCHEMA grupo1 CASCADE;` e rode novamente |
| `buscar('IA')` retorna 0 resultados | `ia` é *stop word* em português no FTS | Comportamento esperado — documentado no relatório |

---

## 📊 Resumo dos Resultados

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
