---
output:
  pdf_document: default
  html_document: default
---
# Notas de pesquisa: ajuste de covariáveis no SaTScan

> **Data:** 24/08/2026 (tarde)
> **Motivação:** sugestão do orientador (Prof. Rafael Erbisti) para pesquisar o ajuste de covariáveis na varredura espacial.
> **Escopo:** apenas pesquisa e leitura — nenhum script foi executado nem alterado.
> **Fontes:** SaTScan User Guide v10.1 (satscan.org, PDF baixado), manual CRAN do pacote `rsatscan`, PubMed e OpenAlex (via Feynman).

---

## 1. Como o ajuste por covariáveis funciona no SaTScan

### 1.1 Requisito central

O orientador está correto: **o SaTScan não ajusta covariáveis contínuas diretamente**. Para o modelo **Poisson discreto** (o usado no TCC), o ajuste aceita apenas **covariáveis categóricas** (numéricas ou texto), inseridas como **colunas extras nos arquivos de entrada** (`.cas` e `.pop`).

> "With the discrete Poisson and space-time permutation models, an unlimited number of covariates can be adjusted for, by including them in the case and population files." — SaTScan User Guide v10.1, seção *Probability Model Comparison*.

> "To do so, simply enter the covariates as extra columns in the case file (both models) and the population file (Poisson model). There is no need to enter any information on any of the window tabs." — User Guide, seção *Covariate Adjustment Using the Input Files*.

### 1.2 Mecanismo estatístico (padronização indireta)

Sem ajuste (análise puramente espacial):

```
E[c] = p * C / P
```

Com ajuste por categorias de covariáveis:

```
E[c] = Σᵢ E[cᵢ] = Σᵢ pᵢ * Cᵢ / Pᵢ
```

onde `i` indexa as combinações de categorias das covariáveis, `pᵢ` é a população do local na categoria `i`, e `Cᵢ`/`Pᵢ` são o total de casos e de população na categoria `i` em nível nacional.

**Interpretação:** cada município passa a ser comparado com a taxa nacional *da sua categoria* (perfil), em vez da taxa nacional geral. O esperado ajustado é calculado com os casos e a população de cada estrato.

### 1.3 Formatos de arquivo (User Guide, seções *Case File* p. 32 e *Population File* p. 34)

**Arquivo de casos (`.cas`)**: `location_id, time, cases, [cov1, cov2, ...]`

**Arquivo de população (`.pop`)**: `location_id, time, population, [cov1, cov2, ...]`

- As covariáveis devem ser **as mesmas nos dois arquivos** (mesmas colunas, mesmos valores/rótulos de categoria).
- Quando a covariável é individual (ex.: idade × sexo), o `.pop` precisa de **uma linha por combinação de categorias** por local/ano (exemplo oficial: 18 faixas etárias × 2 sexos = 36 linhas por local/ano).
- Quando a covariável é **característica do município** (caso do TCC), basta **1 linha por município** com o rótulo da categoria.
- **Nenhum parâmetro novo no `.prm`**: o SaTScan detecta as colunas extras automaticamente.

### 1.4 Avisos da documentação

- **Não exagerar no número de categorias**: "Too many covariate categories can create problems" — com poucos casos por estrato, a aleatorização perde sentido. Recomendação prática: 2–4 categorias por covariável e 1–3 covariáveis.
- **Covariáveis contínuas** só podem ser usadas por dois caminhos alternativos:
  1. **Categorização** (prévia, no R);
  2. **Regressão externa**: ajustar um GLM Poisson (casos ~ offset(pop) + covariáveis) no R e **substituir a coluna de população do `.pop` pelos esperados ajustados** (procedimento dos artigos de Kulldorff et al., 1997, e Klassen et al., 2005).
- **Múltiplos datasets** (`MultipleDataSetsPurposeType=1`) é outra via, mas é computacionalmente lenta e limitada a 12 categorias — **não recomendada** para 5.564 municípios.

---

## 2. Variáveis candidatas no dataset do TCC

Variáveis disponíveis no painel consolidado (`03. Dados/dataset_tcc_consolidado.rds`, por município): `CASOS_PROV`, `POP`, `prop_agua_rede`, `prop_esgoto_rede`, `prop_esgoto_adequado`, `prop_lixo_coletado`, `prop_pop_favela`, `dens_demografica_2022`, `temp_C_media`, `umid_rel_media`, `precip_mm_acum`.

| Variável | Tipo no dataset | Categorização proposta | Justificativa |
|---|---|---|---|
| **Densidade demográfica** (`dens_demografica_2022`) | numérica (hab/km²) | 3 classes: <25 (baixa), 25–100 (média), >100 (alta) — alinhadas à classificação do IBGE | Urbanização é o principal modificador de transmissão de dengue; densidade alta confunde a detecção de clusters |
| **Esgotamento sanitário** (`prop_esgoto_rede`) | numérica (%) | 3 classes: <50%, 50–80%, >80% | Déficit de saneamento é o determinante socioespacial central do trabalho; ajustar remove o excesso "explicado" por infraestrutura |
| **População em favelas** (`prop_pop_favela`) | numérica (%) | 3 classes: 0, (0–10%], >10% | Vulnerabilidade social; distribuição muito assimétrica (muitos zeros) — usar 0 como classe própria |
| **Temperatura média** (`temp_C_media`) | numérica (°C) | 3 classes por tercis (≈ <22, 22–25, >25 °C) | Clima é determinante ecológico; ajustar isola o componente "não climático" do agrupamento |
| **Estrutura etária** | *não disponível no painel* | exigiria casos e população por faixa etária (SINAN tem idade; DATASUS/SIDRA tem população por faixa) | Covariável clássica em varredura espacial (Klassen et al., 2005); só viável com expansão do ETL |

**Não ajustar:** população (já é o offset do modelo), UF/região (colapsaria a varredura). Cuidado com covariáveis fortemente correlacionadas entre si (ex.: esgoto × favela × densidade) — estratos esparsos degradam o teste.

---

## 3. Considerações metodológicas (discutir com o orientador)

- No desenho acumulado atual (1 linha por município, sem dimensão temporal real), as covariáveis são **constantes dentro do município**. O ajuste equivale a comparar cada município com a taxa nacional do seu perfil.
- O resultado é uma **análise de sensibilidade**: os clusters que *persistem* após o ajuste são excessos **não explicados** pelo perfil socioambiental.
- Isso enriquece o TCC, mas **muda a interpretação dos RR** (passam a ser "excesso dado o perfil"). Recomenda-se reportar como **análise complementar**, não substituta da varredura sem ajuste.
- Sugestão: começar com **uma única covariável** (densidade ou esgoto) com 3 categorias; rodar lado a lado com o resultado atual; só então avaliar uma segunda covariável.

---

## 4. Implementação na rotina `04. Códigos/05_varredura_satscan.R`

Mudanças cirúrgicas apenas na **etapa 1** (preparação dos arquivos). O `.prm` e as etapas 2–5 ficam intactos; o **checkpoint por hash** invalida automaticamente quando os arquivos de entrada mudam.

```r
# 1. Criar as categorias no objeto mun (antes do write.table)
mun <- mun %>%
  mutate(DENS_CAT = cut(dens_demografica_2022,
                        breaks = c(-Inf, 25, 100, Inf),
                        labels = c("1", "2", "3")),          # 1=baixa 2=media 3=alta
         ESG_CAT  = cut(prop_esgoto_rede,
                        breaks = c(-Inf, 50, 80, Inf),
                        labels = c("1", "2", "3")))          # 1=<50% 2=50-80% 3=>80%

# 2. .cas com colunas extras de covariáveis (mesmas categorias)
write.table(mun %>% select(ID_MN_RESI, CASOS) %>% mutate(ANO = 2025) %>%
              bind_cols(mun %>% select(DENS_CAT, ESG_CAT)),
            file.path(ARQ_DIR, paste0(STUB, ".cas")),
            row.names = FALSE, col.names = FALSE, sep = " ")

# 3. .pop com as MESMAS colunas de covariáveis (1 linha por município x categoria)
write.table(data.frame(ID = mun$ID_MN_RESI, ANO = 2025,
                       POP = round(mun$POP),
                       DENS_CAT = mun$DENS_CAT, ESG_CAT = mun$ESG_CAT),
            file.path(ARQ_DIR, paste0(STUB, ".pop")),
            row.names = FALSE, col.names = FALSE, sep = " ")
```

- O `rsatscan` escreve o data.frame como está — nenhuma configuração extra.
- Macros, tabelas e mapas das etapas 4–5 não mudam.
- Para idade/sexo no futuro: `.cas` com casos por faixa (linhas múltiplas por município) e `.pop` com população por faixa (SIDRA) — ou a via GLM externo para covariáveis contínuas.

---

## 5. Referências verificadas (para citar na monografia)

| Referência | Detalhes | Identificador |
|---|---|---|
| Jung I. A generalized linear models approach to spatial scan statistics for covariate adjustment. *Statistics in Medicine*, 2009 | Referência metodológica central (equivalência com padronização indireta) | PMID 19177339, DOI 10.1002/sim.3535 |
| Kulldorff M, Feuer EJ, Miller BA, Freedman LS. Breast cancer clusters in Northeastern United States. *Am J Epidemiol*, 1997;146:161–170 | Aplicação clássica com ajuste | citado no User Guide (ref. 24) |
| Klassen A, Kulldorff M, Curriero F. Geographical clustering of prostate cancer grade and stage at diagnosis, before and after adjustment for risk factors. *Int J Health Geogr*, 2005;4:1 | Comparação clusters com/sem ajuste — modelo para a análise de sensibilidade | citado no User Guide (ref. 26) |
| Kleinman K, Abrams A, Kulldorff M, Platt R. A model-adjusted space-time scan statistic with an application to syndromic surveillance. *Epidemiol Infect*, 2005;133:409–419 | Base do ajuste via modelo (GLMM) | citado no User Guide (ref. 25) |
| Sabel CE, Wilson JG, Kingham S, Tisch C, Epton M. Spatial implications of covariate adjustment on patterns of risk. *Soc Sci Med*, 2007 | Como o ajuste altera o padrão espacial | PMID 17467863, DOI 10.1016/j.socscimed.2007.02.040 |
| Kulldorff M. SaTScan User Guide v10.1 (satscan.org) | Detalhe operacional dos arquivos `.cas`/`.pop` e da padronização indireta | — |

---

## 6. Próximos passos sugeridos

- [ ] Decidir com o orientador a covariável principal (sugestão: densidade ou esgoto) e a categorização
- [ ] Esboçar o código completo da análise de sensibilidade (sem executar) — etapa 1 do `05_varredura_satscan.R`
- [ ] Definir a redação da seção de metodologia ("análise de robustez com ajuste por covariáveis")
- [ ] Verificar disponibilidade de dados por faixa etária (SINAN/DATASUS) caso a estrutura etária seja priorizada
