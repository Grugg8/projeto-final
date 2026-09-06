# ============================================================================ #
# 01_etl_censo_2022.R
# ----------------------------------------------------------------------------
# ETL dos dados socioespaciais do Censo Demográfico 2022 (IBGE/SIDRA) para a
# malha municipal harmonizada de 2010 (5.564 municípios, excl. Fernando de
# Noronha/PE e reagregação dos municípios criados pós-2010).
#
# Indicadores de domicílios (Censo 2022, Tabelas SIDRA):
#   * 6803 - Abastecimento de água: ligação à rede geral usada como forma
#            principal (categoria c1821 = "Possui ligação à rede geral e a
#            utiliza como forma principal").
#   * 6805 - Esgotamento sanitário por tipo (c11558). "Adequado (rede)" =
#            "Rede geral, rede pluvial ou fossa ligada à rede"; "Adequado
#            (amplo)" = rede + fossa séptica (ligada ou não à rede).
#   * 6892 - Destino do lixo (c67): "Coletado" (serviço de limpeza direto ou
#            caçamba) -- categoria agregada validada (direta + caçamba).
#   * 9887 - População residente em Favelas e Comunidades Urbanas (656
#            municípios; demais municípios assumem 0).
#
# A proporção de população em favelas e a densidade demográfica dependem da
# população residente anual (POP) e são calculadas no script 03 (consolidação),
# que já dispõe da POP compatibilizada. Este script exporta as CONTAGENS e as
# proporções de domicílios (água, esgoto, lixo).
#
# Saídas:
#   * 03. Dados/Originais/Compatibilizacao/tabela_compat.rds
#   * 03. Dados/Originais/Censo_2022/censo_saneamento_bruto_2022.rds (bruto)
#   * 03. Dados/Originais/Censo_2022/censo_2022_compat.rds (processado)
#   * 03. Dados/Originais/Censo_2022/log_auditoria_censo.txt
# ============================================================================ #

# ---- 0. Setup -------------------------------------------------------------- #
suppressPackageStartupMessages({
  library(sidrar)   # download SIDRA
  library(dplyr)    # manipulação
  library(tidyr)    # pivot
  library(stringr)   # padronização de códigos
  library(sf)       # malhas e geometria
})

# Caminhos relativos à raiz do projeto (TCC.Rproj)
DIR_ORIGINAIS  <- "03. Dados/Originais"
DIR_MALHAS     <- file.path(DIR_ORIGINAIS, "Malhas")
DIR_CENSO      <- file.path(DIR_ORIGINAIS, "Censo_2022")
DIR_COMPAT     <- file.path(DIR_ORIGINAIS, "Compatibilizacao")
dir.create(DIR_CENSO,  showWarnings = FALSE, recursive = TRUE)
dir.create(DIR_COMPAT, showWarnings = FALSE, recursive = TRUE)

# Geometria planar para a interseção de malhas (evita falhas do s2 com
# polígonos litorâneos/fronteiriços).
sf_use_s2(FALSE)

# ---- 1. Tabela de compatibilização (malha 2025 -> malha 2010) -------------- #
# Reconstrução fiel à lógica do código-base.R: interseção da malha 2025 com a
# malha 2010 (maior área de sobreposição) + Fernando de Noronha -> Recife.

cat("==> [1/5] Construindo tabela de compatibilização (2025 -> 2010)...\n")

malha_10 <- readRDS("03. Dados/malha_BR_10.RDS") %>%   # 5.565 (inclui Noronha)
  st_make_valid()
malha_25 <- read_sf(file.path(DIR_MALHAS, "BR_Municipios_2025.shp")) %>%
  st_make_valid()

# Padroniza identificadores como character de 7 dígitos e renomeia colunas da
# malha 2025 antes da interseção (robustez: não depende do sufixo ".1").
pad_mun <- function(x) stringr::str_pad(x, width = 7, pad = "0")
malha_10 <- malha_10 %>%
  mutate(CD_MUN = pad_mun(as.character(CD_MUN)),
         NM_MUN = toupper(NM_MUN))
malha_25 <- malha_25 %>%
  mutate(CD_MUN = pad_mun(as.character(CD_MUN)),
         NM_MUN = toupper(NM_MUN)) %>%
  rename(CD_MUN_25 = CD_MUN, NM_MUN_25 = NM_MUN)

# Municípios presentes na malha 2025 e ausentes na de 2010
muni_diff <- malha_25 %>%
  filter(!CD_MUN_25 %in% malha_10$CD_MUN)

# Intersecção com a malha 2010: cada município novo recebe o código 2010 do
# polígono com maior área de sobreposição.
tabela_compat <- muni_diff %>%
  st_intersection(malha_10) %>%
  mutate(area_intersec = as.numeric(st_area(.))) %>%
  st_drop_geometry() %>%
  group_by(CD_MUN_25) %>%
  slice_max(area_intersec, n = 1) %>%
  ungroup() %>%
  select(cod_mun_2025 = CD_MUN_25,
         nome_2025    = NM_MUN_25,
         cod_mun_2010 = CD_MUN,
         nome_2010    = NM_MUN)

# Regra manual: Fernando de Noronha (2605459) compatibilizado a Recife (2611606)
# (mantém a definição do projeto: exclui Noronha como unidade de análise).
if (!"2605459" %in% tabela_compat$cod_mun_2025) {
  tabela_compat <- bind_rows(
    tabela_compat,
    tibble(cod_mun_2025 = "2605459", nome_2025 = "Fernando de Noronha",
           cod_mun_2010 = "2611606", nome_2010 = "RECIFE")
  )
}

tabela_compat <- tabela_compat %>%
  mutate(ID_MN_RESI_25 = substr(cod_mun_2025, 1, 6),
         ID_MN_RESI_10 = substr(cod_mun_2010, 1, 6)) %>%
  arrange(ID_MN_RESI_25)

cat("   Municípios novos compatibilizados:", nrow(tabela_compat), "\n")
print(data.frame(tabela_compat[, c("ID_MN_RESI_25", "ID_MN_RESI_10", "nome_2025")]))

# Salva a tabela por MAIOR ÁREA de sobreposição (versão auditável, imutável).
saveRDS(tabela_compat, file.path(DIR_COMPAT, "tabela_compat.rds"))

# ---------------------------------------------------------------------------- #
# Dicionário de compatibilização municipal (de-para pós-2010 -> malha 2010).
# Municípios emancipados/criados após o Censo 2010 têm suas contagens
# (população e, no script 03, casos SINAN) reatribuídas ao município de ORIGEM
# na malha de 2010, ANTES de qualquer agregação por ID_MN_RESI.
# Os quatro primeiros coincidem com a tabela por maior área de sobreposição;
# Paraíso das Águas (500627) segue o dicionário do projeto -> Costa Rica
# (500325). A tabela por área apontaria Água Clara (500020, 64% da área
# sobreposta); a divergência é deliberada e documentada no manuscrito.
# OBS.: o código 500320 corresponde a CORUMBÁ/MS; Costa Rica/MS é 500325.
DICIONARIO_DE_PARA <- c(
  "150475" = "150680",  # Mojuí dos Campos   -> Santarém (PA)
  "421265" = "420940",  # Pescaria Brava     -> Laguna (SC)
  "422000" = "420700",  # Balneário Rincão   -> Içara (SC)
  "431454" = "430210",  # Pinto Bandeira     -> Bento Gonçalves (RS)
  "500627" = "500325"   # Paraíso das Águas  -> Costa Rica (MS)
)

# Compatibilização EFETIVA (maior área + de-para do projeto), usada apenas no
# processamento abaixo; o arquivo salvo acima permanece a versão por área.
tabela_compat <- tabela_compat %>%
  mutate(ID_MN_RESI_10 = if_else(ID_MN_RESI_25 %in% names(DICIONARIO_DE_PARA),
                                 DICIONARIO_DE_PARA[ID_MN_RESI_25],
                                 ID_MN_RESI_10))

# ---- 2. Download das tabelas do SIDRA (Censo 2022, nível municipal) -------- #
cat("==> [2/5] Baixando tabelas do SIDRA (Censo 2022, municípios)...\n")

# Função de download com tentativas (a API do SIDRA é instável)
get_sidra_retry <- function(x, variable, classific, category, period = "2022",
                            geo = "City", tentativas = 5) {
  for (t in seq_len(tentativas)) {
    res <- tryCatch(
      get_sidra(x = x, period = period, geo = geo, variable = variable,
                classific = classific, category = category,
                header = TRUE, value_type = "numeric"),
      error = function(e) e
    )
    if (is.data.frame(res)) return(res)
    Sys.sleep(3 * t)  # backoff
  }
  stop("Falha no download da tabela ", x, " após ", tentativas, " tentativas.")
}

# Checkpoint do bruto SIDRA: se o arquivo imutável já existe, reutiliza-o
# (evita re-download das tabelas 6803/6805/6892/9887 a cada execução).
arquivo_bruto <- file.path(DIR_CENSO, "censo_saneamento_bruto_2022.rds")
if (file.exists(arquivo_bruto)) {
  cat("   checkpoint: bruto SIDRA existente reutilizado (sem download)\n")
  censo_bruto <- readRDS(arquivo_bruto)
  df_agua   <- censo_bruto$agua
  df_esgoto <- censo_bruto$esgoto
  df_lixo   <- censo_bruto$lixo
  df_favela <- censo_bruto$favela
} else {
  # Tabela 6803 - água (rede geral como forma principal)
  df_agua <- get_sidra_retry(
    x = 6803, variable = 381, classific = "c1821",
    category = list(c1821 = c("72129", "72144"))  # Total | Rede geral principal
  )

  # Tabela 6805 - esgotamento sanitário (tipo)
  df_esgoto <- get_sidra_retry(
    x = 6805, variable = 381, classific = "c11558",
    category = list(c11558 = c("46292", "46290", "72112"))
    # Total | Rede geral/pluvial ou fossa ligada | Fossa séptica não ligada
  )

  # Tabela 6892 - destino do lixo
  df_lixo <- get_sidra_retry(
    x = 6892, variable = 381, classific = "c67",
    category = list(c67 = c("10972", "2520"))  # Total | Coletado (agregado)
  )

  # Tabela 9887 - população em favelas e comunidades urbanas (só 656 municípios)
  df_favela <- get_sidra_retry(
    x = 9887, variable = 9612, classific = "c3",
    category = list(c3 = c("59993"))  # População residente, Total
  )

  # Guarda do bruto imutável (fonte)
  censo_bruto <- list(agua = df_agua, esgoto = df_esgoto,
                      lixo = df_lixo, favela = df_favela)
  saveRDS(censo_bruto, arquivo_bruto)
  cat("   Downloads OK:",
      nrow(df_agua), "água |", nrow(df_esgoto), "esgoto |",
      nrow(df_lixo), "lixo |", nrow(df_favela), "favela\n")
}

# ---- 3. Processamento e compatibilização à malha 2010 ---------------------- #
cat("==> [3/5] Compatibilizando códigos municipais (2025 -> 2010)...\n")

# Extrai o valor de UMA categoria específica: filtra a coluna de classificação
# pelo código da categoria antes de somar por município (evita somar "Total"
# junto com a categoria-alvo, que dobraria os totais).
extrai_valor <- function(df, nome_var, col_classif, cat_codigo) {
  df %>%
    select(ID_MN_RESI_25 = `Município (Código)`,
           col_classif = all_of(col_classif),
           Valor) %>%
    filter(col_classif == cat_codigo) %>%
    select(-col_classif) %>%
    mutate(Valor = as.numeric(Valor),
           # Código municipal de 7 dígitos -> ID de 6 dígitos (malha 2010)
           ID_MN_RESI_25 = substr(as.character(ID_MN_RESI_25), 1, 6)) %>%
    left_join(tabela_compat, by = "ID_MN_RESI_25") %>%
    mutate(ID_MN_RESI = if_else(!is.na(ID_MN_RESI_10), ID_MN_RESI_10, ID_MN_RESI_25)) %>%
    group_by(ID_MN_RESI) %>%
    summarise(!!nome_var := sum(Valor, na.rm = TRUE), .groups = "drop")
}

# Nomes das colunas de classificação em cada tabela baixada
col_c1821  <- "Existência de ligação à rede geral de distribuição de água e principal forma de abastecimento de água (Código)"
col_c11558 <- "Tipo de esgotamento sanitário (Código)"
col_c67    <- "Destino do lixo (Código)"
col_c3     <- "Espécie (Código)"

censo <- extrai_valor(df_agua,   "dom_total",        col_c1821,  "72129") %>%
  left_join(extrai_valor(df_agua,   "dom_agua_rede",    col_c1821,  "72144"), by = "ID_MN_RESI") %>%
  left_join(extrai_valor(df_esgoto, "dom_esgoto_rede",  col_c11558, "46290"), by = "ID_MN_RESI") %>%
  left_join(extrai_valor(df_esgoto, "dom_esgoto_fossa", col_c11558, "72112"), by = "ID_MN_RESI") %>%
  left_join(extrai_valor(df_lixo,   "dom_lixo_coletado", col_c67,   "2520"),  by = "ID_MN_RESI") %>%
  left_join(extrai_valor(df_favela, "pop_favela",       col_c3,    "59993"), by = "ID_MN_RESI")

# Municípios sem favela registrada assumem 0
censo$pop_favela[is.na(censo$pop_favela)] <- 0

# Exclusão de Fernando de Noronha (260545) como unidade de análise, em
# coerência com a base_final (painel expandido sem o ID 260545).
censo <- censo %>% filter(ID_MN_RESI != "260545")

# ---- 4. Indicadores derivados (proporções de domicílios) ------------------- #
cat("==> [4/5] Calculando indicadores...\n")

censo <- censo %>%
  mutate(
    prop_agua_rede       = dom_agua_rede   / dom_total * 100,
    prop_esgoto_rede     = dom_esgoto_rede / dom_total * 100,   # restrito
    prop_esgoto_adequado = (dom_esgoto_rede + dom_esgoto_fossa) / dom_total * 100,
    prop_lixo_coletado   = dom_lixo_coletado / dom_total * 100
  ) %>%
  arrange(ID_MN_RESI)

# ---- 5. Auditoria de integridade e exportação ------------------------------ #
cat("==> [5/5] Auditoria e exportação...\n")

log_linhas <- character()

# 5.1 Municípios: espera-se 5.564 (malha 2010 sem Fernando de Noronha)
n_esperado <- 5564L
n_obtido   <- nrow(censo)
log_linhas <- c(log_linhas, sprintf("municipios_esperado=%d", n_esperado),
                sprintf("municipios_obtido=%d", n_obtido))
if (n_obtido != n_esperado) {
  ids_malha <- unique(readRDS("03. Dados/malha_BR_10.RDS")$ID_MN_RESI)
  fora <- setdiff(censo$ID_MN_RESI, ids_malha)
  falta <- setdiff(ids_malha, censo$ID_MN_RESI)
  log_linhas <- c(log_linhas,
    sprintf("ATENCAO: codigos fora da malha 2010: %s", paste(fora, collapse = ",")),
    sprintf("ATENCAO: codigos da malha ausentes no censo: %s", paste(falta, collapse = ",")))
}

# 5.2 Ausência de NA nas proporções
na_props <- sum(is.na(censo$prop_agua_rede) | is.na(censo$prop_esgoto_adequado) |
                is.na(censo$prop_lixo_coletado))
log_linhas <- c(log_linhas, sprintf("na_em_proporcoes=%d", na_props))

# 5.3 Plausibilidade dos totais nacionais (comparação com a soma bruta)
#    Soma da categoria "rede geral" no bruto (5.570 mun) vs soma pós-
#    compatibilização (5.564 mun): a diferença = casos dos municípios novos.
tot_bruto_agua   <- sum(as.numeric(df_agua$Valor[df_agua[[col_c1821]] == "72144"]),
                        na.rm = TRUE)
tot_comp_agua    <- sum(censo$dom_agua_rede, na.rm = TRUE)
log_linhas <- c(log_linhas,
  sprintf("total_bruto_agua_rede=%.0f", tot_bruto_agua),
  sprintf("total_compat_agua_rede=%.0f", tot_comp_agua),
  sprintf("diff_agua_bruto_compat=%.0f", tot_comp_agua - tot_bruto_agua))

# 5.4 Resumo nacional para conferência rápida
log_linhas <- c(log_linhas,
  sprintf("BR_prop_agua_rede=%.2f",  weighted.mean(censo$prop_agua_rede, censo$dom_total)),
  sprintf("BR_prop_esgoto_adequado=%.2f", weighted.mean(censo$prop_esgoto_adequado, censo$dom_total)),
  sprintf("BR_prop_lixo_coletado=%.2f", weighted.mean(censo$prop_lixo_coletado, censo$dom_total)),
  sprintf("BR_pop_favela=%.0f", sum(censo$pop_favela)))

writeLines(log_linhas, file.path(DIR_CENSO, "log_auditoria_censo.txt"))

saveRDS(censo, file.path(DIR_CENSO, "censo_2022_compat.rds"))

cat("\n--- LOG DE AUDITORIA ---\n")
cat(log_linhas, sep = "\n")
cat("\nConcluído. Arquivos:\n")
cat("  ", file.path(DIR_COMPAT, "tabela_compat.rds"), "\n")
cat("  ", file.path(DIR_CENSO, "censo_saneamento_bruto_2022.rds"), "\n")
cat("  ", file.path(DIR_CENSO, "censo_2022_compat.rds"), "\n")
