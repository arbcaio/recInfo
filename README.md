# Recuperação da Informação em Bancos de Dados Relacionais

> Trabalho prático da disciplina **Recuperação de Informação** - implementação de um sistema de busca usando o módulo Full Text Search (FTS) nativo do PostgreSQL.

---

##  Grupo

Agenor Luiz
Caio Braga
Dayvid Willams
Luiz Anjos
Maria Luiza

**Professor:** Prof. Dr. Bruno Tenório Ávila  
**Disciplina:** Recuperação de Informação - UFPE  

---

##  Descrição

O objetivo deste trabalho é criar um **sistema de recuperação da informação** dentro de um banco de dados relacional PostgreSQL, explorando o recurso nativo de *Full Text Search* (FTS).

O sistema realiza todas as etapas clássicas de um motor de busca:

1. **Aquisição** - 10 documentos em português inseridos diretamente no banco.
2. **Representação** - cada documento é indexado como um `tsvector` com pesos diferenciados por campo (título = peso A, conteúdo = peso B).
3. **Índice invertido** - criação de um índice GIN (*Generalized Inverted Index*) sobre o `tsvector`.
4. **Recuperação** - função `buscar()` que converte a consulta em `tsquery`, casa com os documentos via operador `@@` e os ordena por `ts_rank`.
5. **Avaliação** - cálculo de Precisão, Cobertura (Recall) e F-measure para cada uma das 10 consultas realizadas.

---

##  Estrutura do Projeto

```
recInfo/
├-- sql/
│   ├-- 01_schema.sql           # Cria o esquema do grupo
│   ├-- 02_table_documents.sql  # Cria a tabela com coluna tsvector gerada
│   ├-- 03_insert_documents.sql # Insere os 10 documentos
│   ├-- 04_index.sql            # Cria o índice GIN invertido
│   ├-- 05_functions.sql        # Funções representacao_consulta() e buscar()
│   ├-- 06_queries.sql          # Executa as 10 consultas
│   └-- main.sql                # Script único (tudo em um) para o pgAdmin
├-- evaluation/
│   ├-- relevance.json          # Julgamentos de relevância manuais
│   ├-- evaluate.py             # Script Python que calcula as métricas
│   └-- results.csv             # Saída gerada pelo evaluate.py
├-- report/
│   └-- report.md               # Relatório completo com análise de desempenho
├-- setup.ps1                   # Script PowerShell de execução automática
├-- .gitignore
├-- requirements.txt
└-- README.md
```

---

##  Execução via Script (Recomendado)

O arquivo `setup.ps1` automatiza toda a instalação e execução - instala o PostgreSQL se necessário, configura o esquema e roda as métricas.

### No servidor da UFPE

> Requer conexão ao WiFi da UFPE ou VPN.

Abra o PowerShell na pasta do projeto e execute:

```powershell
.\setup.ps1 -DbHost "agade.ufpe.br" -DbUser "disciplinas" -DbName "disciplinas"
```

Quando solicitado, informe a senha: `@g@d4`

### Localmente

```powershell
.\setup.ps1
```

Quando solicitado, informe a senha do usuário `postgres` definida na instalação. O script instala o PostgreSQL automaticamente via `winget` se não estiver presente.

### O que o script faz

1. Localiza o `psql` no PATH ou nas pastas padrão de instalação
2. Instala o PostgreSQL via `winget` se não encontrado
3. Testa a conexão com o servidor
4. Cria o banco `disciplinas` se não existir (apenas na execução local)
5. Substitui `grupo` por `grupo1` no `main.sql` e executa no servidor
6. Roda `evaluate.py` e exibe as métricas de Precisão/Cobertura/F-measure

### Parâmetros disponíveis

| Parâmetro | Padrão | Descrição |
|-----------|--------|-----------|
| `-esquemaName` | `grupo1` | Nome do esquema criado no banco |
| `-DbName` | `disciplinas` | Nome do banco de dados |
| `-DbUser` | `postgres` | Usuário do PostgreSQL |
| `-DbHost` | `localhost` | Endereço do servidor |
| `-DbPort` | `5432` | Porta do servidor |

---

##  Execução Manual (pgAdmin)

### Pré-requisitos

- **pgAdmin 4** instalado -> [pgadmin.org/download](https://www.pgadmin.org/download/)
- **Python 3.8+** instalado -> [python.org/downloads](https://www.python.org/downloads/) *(somente para as métricas)*
- Acesso à rede da UFPE (ou VPN, se estiver fora do campus)

---

#### Passo 1 - Criar o servidor no pgAdmin

1. Abra o **pgAdmin 4**.
2. No painel esquerdo, clique com o botão direito em **Servers** -> **Register -> Server…**
3. Na aba **General**, defina o nome como `UFPE`.
4. Na aba **Connection**, preencha:

   | Campo | Valor |
   |-------|-------|
   | Host name / address | `agade.ufpe.br` |
   | Port | `5432` |
   | Maintenance database | `disciplinas` |
   | Username | `disciplinas` |
   | Password | `@g@d4` |

5. Marque **Save password** e clique em **Save**.

---

#### Passo 2 - Renomear o esquema no script

>  Cada grupo deve usar um esquema exclusivo para não conflitar com os demais.

Abra `sql/main.sql` e use Localizar e Substituir (`Ctrl+H`):
- Localizar: `grupo`
- Substituir por: o nome do seu grupo (ex: `grupo1`)

---

#### Passo 3 - Executar o script

1. No pgAdmin, expanda **UFPE -> Databases -> disciplinas**.
2. Clique com o botão direito em **disciplinas** -> **Query Tool**.
3. Abra `sql/main.sql` com `Ctrl+O` e pressione `F5`.

Você deve ver no painel de mensagens:
```
CREATE SCHEMA
CREATE TABLE
INSERT 0 10
CREATE INDEX
CREATE FUNCTION
CREATE FUNCTION
```

---

#### Passo 4 - Calcular as métricas (Python)

```bash
python evaluation/evaluate.py
```

---

##  Resumo dos Resultados

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

##  Conceitos-chave

| Termo | Descrição |
|-------|-----------|
| `tsvector` | Representação interna do documento: radicais ordenados + pesos |
| `tsquery` | Representação da consulta em radicais |
| `GIN` | Índice invertido generalizado - busca em O(log N + K) |
| `ts_rank` | Função de pontuação (frequência + peso por campo) |
| `setweight` | Atribui peso A (título) ou B (conteúdo) aos tokens |
| Precisão | \|Relevantes ∩ Retornados\| / \|Retornados\| |
| Cobertura | \|Relevantes ∩ Retornados\| / \|Relevantes\| |
| F-measure | 2 × P × R / (P + R) |

---

##  Referências

- [PostgreSQL - Chapter 12: Full Text Search](https://www.postgresql.org/docs/current/textsearch.html)
- [Apache Lucene](https://lucene.apache.org/)
- [Elasticsearch](https://www.elastic.co/)
- [Apache Solr](https://solr.apache.org/)
