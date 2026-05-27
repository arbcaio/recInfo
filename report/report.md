# Relatório - Sistema de Recuperação da Informação em PostgreSQL

**Disciplina:** Recuperação de Informação  
**Professor:** Prof. Dr. Bruno Tenório Ávila  
**Tarefa:** Aula 7 - Recuperação da Informação em Bancos de Dados Relacionais

---

## 1. Descrição do Sistema

O sistema foi implementado utilizando o módulo de **Full Text Search (FTS)** nativo do PostgreSQL. A abordagem escolhida armazena documentos em uma tabela relacional com uma coluna `tsvector` gerada automaticamente que representa o documento de forma otimizada para buscas.

### Componentes

| Componente | Descrição |
|---|---|
| `documentos` | Tabela com `titulo`, `conteudo` e `representacao_documento` (tsvector gerado) |
| `representacao_consulta()` | Converte texto livre em `tsquery` via `websearch_to_tsquery('portuguese', ...)` |
| `buscar()` | Executa o casamento (`@@`), ranqueia com `ts_rank` e retorna resultados ordenados |
| GIN Index | Índice invertido generalizado sobre `representacao_documento` |

### Pesos de indexação

| Campo | Peso | Justificativa |
|---|---|---|
| `titulo` | **A** (mais alto) | O título resume o tema do documento |
| `conteudo` | **B** | Contexto detalhado, relevância secundária |

---

## 2. Documentos

| ID | Título | Tema |
|----|--------|------|
| 1 | Nova versão do PostgreSQL melhora desempenho | Banco de dados relacional |
| 2 | Oracle Corporation investe em banco de dados autônomo | Banco de dados + IA |
| 3 | Cresce uso do MongoDB em aplicações modernas | Banco de dados NoSQL |
| 4 | Microsoft amplia recursos do Azure SQL | Banco de dados + Nuvem |
| 5 | Debate sobre privacidade impacta bancos de dados | Privacidade / Segurança |
| 6 | OpenAI lança novos modelos mais eficientes | Inteligência Artificial |
| 7 | Google avança em IA generativa | Inteligência Artificial |
| 8 | Microsoft expande uso de IA no trabalho | Inteligência Artificial |
| 9 | Regulamentação de IA ganha força na União Europeia | IA + Regulamentação |
| 10 | IA transforma setor de saúde | IA + Saúde |

---

## 3. Consultas e Avaliação de Desempenho

### Fórmulas utilizadas

```
Precisão  (P) = |Relevantes ∩ Retornados| / |Retornados|
Cobertura (R) = |Relevantes ∩ Retornados| / |Relevantes|
F-measure (F) = 2 × P × R / (P + R)
```

---

### Q1 - `inteligência artificial`

| Doc | Título | Relevante | Retornado |
|-----|--------|:---------:|:---------:|
| 1 | Nova versão do PostgreSQL melhora desempenho | | |
| 2 | Oracle Corporation investe em banco de dados autônomo | ✓ | ✓ |
| 3 | Cresce uso do MongoDB em aplicações modernas | | |
| 4 | Microsoft amplia recursos do Azure SQL | | |
| 5 | Debate sobre privacidade impacta bancos de dados | | |
| 6 | OpenAI lança novos modelos mais eficientes | ✓ | |
| 7 | Google avança em IA generativa | ✓ | |
| 8 | Microsoft expande uso de IA no trabalho | ✓ | ✓ |
| 9 | Regulamentação de IA ganha força na União Europeia | ✓ | |
| 10 | IA transforma setor de saúde | ✓ | |

**Análise:** Apenas os documentos 2 e 8 grafam "inteligência artificial" por extenso. Os documentos 6, 7, 9 e 10 usam somente a sigla "IA", que não corresponde ao tsquery gerado - ilustrando a limitação com sinônimos e abreviações.

| TP | FP | FN | Precisão | Cobertura | F-measure |
|:--:|:--:|:--:|:--------:|:---------:|:---------:|
| 2 | 0 | 4 | **1,00** | **0,33** | **0,50** |

---

### Q2 - `banco de dados`

| Doc | Título | Relevante | Retornado |
|-----|--------|:---------:|:---------:|
| 1 | Nova versão do PostgreSQL melhora desempenho | ✓ | ✓ |
| 2 | Oracle Corporation investe em banco de dados autônomo | ✓ | ✓ |
| 3 | Cresce uso do MongoDB em aplicações modernas | ✓ | |
| 4 | Microsoft amplia recursos do Azure SQL | ✓ | |
| 5 | Debate sobre privacidade impacta bancos de dados | ✓ | ✓ |
| 6 | OpenAI lança novos modelos mais eficientes | | |
| 7 | Google avança em IA generativa | | |
| 8 | Microsoft expande uso de IA no trabalho | | |
| 9 | Regulamentação de IA ganha força na União Europeia | | |
| 10 | IA transforma setor de saúde | | |

**Análise:** O tsquery exige a co-ocorrência de "banc" AND "dad". O documento 3 contém "bancos" mas não "dados"; o documento 4 contém "dados" mas não "banco". Ambos são relevantes mas não retornados - falsos negativos.

| TP | FP | FN | Precisão | Cobertura | F-measure |
|:--:|:--:|:--:|:--------:|:---------:|:---------:|
| 3 | 0 | 2 | **1,00** | **0,60** | **0,75** |

---

### Q3 - `PostgreSQL`

| Doc | Título | Relevante | Retornado |
|-----|--------|:---------:|:---------:|
| 1 | Nova versão do PostgreSQL melhora desempenho | ✓ | ✓ |

**Análise:** Consulta altamente específica. Apenas o documento 1 menciona PostgreSQL. Resultado perfeito.

| TP | FP | FN | Precisão | Cobertura | F-measure |
|:--:|:--:|:--:|:--------:|:---------:|:---------:|
| 1 | 0 | 0 | **1,00** | **1,00** | **1,00** |

---

### Q4 - `IA`

| Doc | Título | Relevante | Retornado |
|-----|--------|:---------:|:---------:|
| 2 | Oracle Corporation investe em banco de dados autônomo | ✓ | |
| 6 | OpenAI lança novos modelos mais eficientes | ✓ | |
| 7 | Google avança em IA generativa | ✓ | |
| 8 | Microsoft expande uso de IA no trabalho | ✓ | |
| 9 | Regulamentação de IA ganha força na União Europeia | ✓ | |
| 10 | IA transforma setor de saúde | ✓ | |

**Análise:** Em português, "ia" é uma *stop word* (pretérito imperfeito de "ir"). A função `websearch_to_tsquery('portuguese', 'IA')` retorna uma tsquery vazia e, portanto, **nenhum documento é retornado**. Este resultado demonstra a limitação do sistema com acrônimos e stop words.

| TP | FP | FN | Precisão | Cobertura | F-measure |
|:--:|:--:|:--:|:--------:|:---------:|:---------:|
| 0 | 0 | 6 | **0,00** | **0,00** | **0,00** |

---

### Q5 - `desempenho`

| Doc | Título | Relevante | Retornado |
|-----|--------|:---------:|:---------:|
| 1 | Nova versão do PostgreSQL melhora desempenho | ✓ | ✓ |
| 6 | OpenAI lança novos modelos mais eficientes | ✓ | ✓ |
| 10 | IA transforma setor de saúde | ✓ | |

**Análise:** O documento 10 é relevante (a IA melhora a precisão/desempenho do diagnóstico médico), porém usa o termo "precisão" em vez de "desempenho" - falso negativo por falta de sinônimos.

| TP | FP | FN | Precisão | Cobertura | F-measure |
|:--:|:--:|:--:|:--------:|:---------:|:---------:|
| 2 | 0 | 1 | **1,00** | **0,67** | **0,80** |

---

### Q6 - `segurança`

| Doc | Título | Relevante | Retornado |
|-----|--------|:---------:|:---------:|
| 1 | Nova versão do PostgreSQL melhora desempenho | ✓ | ✓ |
| 5 | Debate sobre privacidade impacta bancos de dados | ✓ | |
| 9 | Regulamentação de IA ganha força na União Europeia | ✓ | ✓ |

**Análise:** O documento 5 trata de proteção de dados e segurança, mas utiliza os termos "criptografia", "controle de acesso" e "auditoria" - nunca o radical de "segurança". Falso negativo por falta de expansão de vocabulário.

| TP | FP | FN | Precisão | Cobertura | F-measure |
|:--:|:--:|:--:|:--------:|:---------:|:---------:|
| 2 | 0 | 1 | **1,00** | **0,67** | **0,80** |

---

### Q7 - `regulamentação`

| Doc | Título | Relevante | Retornado |
|-----|--------|:---------:|:---------:|
| 5 | Debate sobre privacidade impacta bancos de dados | ✓ | ✓ |
| 9 | Regulamentação de IA ganha força na União Europeia | ✓ | ✓ |

**Análise:** Resultado perfeito. O documento 9 rankeia mais alto porque "Regulamentação" aparece no título (peso A).

| TP | FP | FN | Precisão | Cobertura | F-measure |
|:--:|:--:|:--:|:--------:|:---------:|:---------:|
| 2 | 0 | 0 | **1,00** | **1,00** | **1,00** |

---

### Q8 - `machine learning`

| Doc | Título | Relevante | Retornado |
|-----|--------|:---------:|:---------:|
| 4 | Microsoft amplia recursos do Azure SQL | ✓ | ✓ |

**Análise:** Resultado perfeito. Somente o documento 4 menciona "machine learning".

| TP | FP | FN | Precisão | Cobertura | F-measure |
|:--:|:--:|:--:|:--------:|:---------:|:---------:|
| 1 | 0 | 0 | **1,00** | **1,00** | **1,00** |

---

### Q9 - `dados`

| Doc | Título | Relevante | Retornado |
|-----|--------|:---------:|:---------:|
| 1 | Nova versão do PostgreSQL melhora desempenho | ✓ | ✓ |
| 2 | Oracle Corporation investe em banco de dados autônomo | ✓ | ✓ |
| 3 | Cresce uso do MongoDB em aplicações modernas | ✓ | |
| 4 | Microsoft amplia recursos do Azure SQL | ✓ | ✓ |
| 5 | Debate sobre privacidade impacta bancos de dados | ✓ | ✓ |
| 8 | Microsoft expande uso de IA no trabalho | | ✓ |

**Análise:** Demonstra **falso positivo** (doc 8: "análise de *dados*" faz o documento ser retornado, mas seu tema principal é IA no trabalho, não banco de dados) e **falso negativo** (doc 3: trata de banco de dados NoSQL mas nunca usa a palavra "dados" no texto).

| TP | FP | FN | Precisão | Cobertura | F-measure |
|:--:|:--:|:--:|:--------:|:---------:|:---------:|
| 4 | 1 | 1 | **0,80** | **0,80** | **0,80** |

---

### Q10 - `saúde`

| Doc | Título | Relevante | Retornado |
|-----|--------|:---------:|:---------:|
| 10 | IA transforma setor de saúde | ✓ | ✓ |

**Análise:** Resultado perfeito. Somente o documento 10 cobre o setor de saúde.

| TP | FP | FN | Precisão | Cobertura | F-measure |
|:--:|:--:|:--:|:--------:|:---------:|:---------:|
| 1 | 0 | 0 | **1,00** | **1,00** | **1,00** |

---

## 4. Consolidação dos Resultados

| # | Consulta | Rel | Ret | TP | FP | FN | Precisão | Cobertura | F-measure |
|:-:|----------|:---:|:---:|:--:|:--:|:--:|:--------:|:---------:|:---------:|
| 1 | inteligência artificial | 6 | 2 | 2 | 0 | 4 | 1,00 | 0,33 | 0,50 |
| 2 | banco de dados | 5 | 3 | 3 | 0 | 2 | 1,00 | 0,60 | 0,75 |
| 3 | PostgreSQL | 1 | 1 | 1 | 0 | 0 | 1,00 | 1,00 | 1,00 |
| 4 | IA | 6 | 0 | 0 | 0 | 6 | 0,00 | 0,00 | 0,00 |
| 5 | desempenho | 3 | 2 | 2 | 0 | 1 | 1,00 | 0,67 | 0,80 |
| 6 | segurança | 3 | 2 | 2 | 0 | 1 | 1,00 | 0,67 | 0,80 |
| 7 | regulamentação | 2 | 2 | 2 | 0 | 0 | 1,00 | 1,00 | 1,00 |
| 8 | machine learning | 1 | 1 | 1 | 0 | 0 | 1,00 | 1,00 | 1,00 |
| 9 | dados | 5 | 5 | 4 | 1 | 1 | 0,80 | 0,80 | 0,80 |
| 10 | saúde | 1 | 1 | 1 | 0 | 0 | 1,00 | 1,00 | 1,00 |
| | **MÉDIA** | | | | | | **0,88** | **0,71** | **0,76** |

---

## 5. Análise das Limitações Observadas

### 5.1 Acrônimos e Stop Words (Q4)
A consulta `'IA'` não retornou nenhum resultado porque "ia" é uma *stop word* no dicionário português do PostgreSQL (pretérito imperfeito do verbo "ir"). Isso elimina completamente a recuperação dos documentos 6, 7, 9 e 10, que usam predominantemente a sigla.

**Impacto:** Cobertura = 0 para a consulta Q4, reduzindo a média geral de Cobertura para 0,71.

### 5.2 Sinônimos e Formas Alternativas (Q1, Q5, Q6)
- `'inteligência artificial'` não recupera documentos que usam apenas "IA" - perda de 4 documentos relevantes.
- `'desempenho'` não recupera o doc 10 que usa "precisão" com sentido equivalente.
- `'segurança'` não recupera o doc 5 que usa "criptografia", "controle de acesso", "auditoria".

**Solução possível:** Implementar um dicionário de sinônimos (`CREATE TEXT SEARCH DICTIONARY ... thesaurus`) no PostgreSQL.

### 5.3 Consulta Parcial sem Co-ocorrência (Q2)
`'banco de dados'` exige que ambos os radicais estejam no mesmo documento. Documentos que abordam bancos de dados mas omitem um dos termos não são recuperados.

### 5.4 Falso Positivo por Polissemia (Q9)
A consulta `'dados'` retorna o doc 8 ("análise de *dados*" no contexto de IA), que não é um documento sobre sistemas de banco de dados. O FTS não distingue o uso do termo em contextos diferentes.

### 5.5 Pontos Fortes
- Precisão média de **0,88** - os documentos retornados são, em sua grande maioria, relevantes.
- O operador `setweight` garante que correspondências no título recebam maior pontuação, melhorando a ordenação dos resultados.
- Suporte a operadores estilo Google (`-palavra`, `"frase exata"`) via `websearch_to_tsquery`.

---

## 6. Conclusão

O sistema de recuperação da informação implementado com o PostgreSQL FTS demonstrou alta **precisão** (0,88 em média) e **cobertura** moderada (0,71 em média), resultando em um **F-measure médio de 0,76**.

As principais limitações identificadas estão relacionadas ao tratamento de acrônimos (stop words), à ausência de expansão por sinônimos e à dependência de co-ocorrência exata de termos compostos. Essas limitações são conhecidas do FTS relacional e, para contextos de maior escala ou vocabulário mais rico, motores especializados como Elasticsearch (baseado no Apache Lucene) seriam mais adequados.
                                    