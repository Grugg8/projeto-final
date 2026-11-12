here::i_am("R/05_consolidacao_dataset.R")

# ============================================================================ #
# 05_consolidacao_dataset.R
# ----------------------------------------------------------------------------
# Consolidação do dataset final do TCC: SINAN, população, Censo 2022 e clima.
#
# Definição operacional de casos prováveis (CALIBRADA com os totais oficiais
# do Ministério da Saúde, erro <= 2,5% nos anos de referência):
#   Casos prováveis = notificações de dengue (ID_AGRAVO A90) EXCETO
#     CLASSI_FIN 5 (descartado), 6 (chikungunya) e 7 (zika).
#   O painel espacial exige CLASSI_FIN não ausente; o perfil descritivo bruto
#   mantém registros sem classificação para preservar o universo de notificações.
#   Confirmados = CLASSI_FIN em {10,11,12}. Óbitos = EVOLUCAO == 2.
#
# População anual: 2010 (malha censitária + Nazária), 2011-2024 (POP.xlsx),
# 2025 (SIDRA Tabela 6579 - estimativas municipais).
#
# Unidade: painel 16 anos (2010-2025) x 5.564 municípios (malha 2010, sem
# Fernando de Noronha, municípios criados pós-2010 reagregados via tabela_compat
# + DICIONARIO_DE_PARA, aplicado a CASOS e POPULAÇÃO antes da agregação).
#
# Saídas:
#   * data/processed/sinan/base_contagem_2010_2025_v3.rds
#   * data/processed/populacao/pop_anual_compat.rds
#   * data/processed/dataset_tcc_consolidado.rds  (base final, LEAN - sem geometry)
#   * output/logs/sinan/log_auditoria_consolidacao.txt
# ============================================================================ #

# ---- 0. Setup -------------------------------------------------------------- #
suppressPackageStartupMessages({
  library(read.dbc)   # DBCs do SINAN
  library(dplyr)      # manipulação
  library(tidyr)      # pivot
  library(sf)         # malha / área
  library(readxl)     # POP.xlsx
  library(lubridate)  # epiyear
  library(sidrar)     # estimativas 2025
  library(arrow)      # exportação parquet de alta performance
})
sf_use_s2(FALSE)

DIR_DBCS <- here::here("data", "raw", "sinan")
DIR_POP <- here::here("data", "raw", "populacao")
DIR_MALHAS <- here::here("data", "raw", "malhas")
DIR_ERA5 <- here::here("data", "processed", "clima")
DIR_SINAN_PROC <- here::here("data", "processed", "sinan")
DIR_POP_PROC <- here::here("data", "processed", "populacao")
dir.create(DIR_SINAN_PROC, showWarnings = FALSE, recursive = TRUE)
dir.create(DIR_POP_PROC,  showWarnings = FALSE, recursive = TRUE)
DIR_LOG <- here::here("output", "logs", "sinan")
dir.create(DIR_LOG, showWarnings = FALSE, recursive = TRUE)

tabela_compat <- readRDS(here::here("data", "processed", "compatibilizacao", "tabela_compat.rds"))

# ============================================================================ #
# Dicionário de compatibilização municipal (de-para pós-2010 -> malha 2010).
# Municípios emancipados/criados após o Censo 2010 têm suas notificações SINAN
# e estimativas populacionais reatribuídas ao município de ORIGEM na malha de
# 2010, ANTES da agregação por ID_MN_RESI:
#   150475 Mojuí dos Campos/PA  -> 150680 Santarém/PA
#   421265 Pescaria Brava/SC    -> 420940 Laguna/SC
#   422000 Balneário Rincão/SC  -> 420700 Içara/SC
#   431454 Pinto Bandeira/RS    -> 430210 Bento Gonçalves/RS
#   500627 Paraíso das Águas/MS -> 500325 Costa Rica/MS
# (Os quatro primeiros coincidem com a tabela por maior área de sobreposição;
# Paraíso das Águas segue o dicionário do projeto -> Costa Rica. A tabela por
# área apontaria Água Clara/500020, com 64% da área sobreposta - divergência
# deliberada, documentada no manuscrito e no script 01_etl_censo_2022.R.
# OBS.: o código 500320 corresponde a CORUMBÁ/MS; Costa Rica/MS é 500325.)
# ============================================================================ #
DICIONARIO_DE_PARA <- c(
  "150475" = "150680",  # Mojuí dos Campos   -> Santarém (PA)
  "421265" = "420940",  # Pescaria Brava     -> Laguna (SC)
  "422000" = "420700",  # Balneário Rincão   -> Içara (SC)
  "431454" = "430210",  # Pinto Bandeira     -> Bento Gonçalves (RS)
  "500627" = "500325"   # Paraíso das Águas  -> Costa Rica (MS)
)

# Compatibilização EFETIVA (maior área + de-para do projeto), usada em todos
# os joins de população abaixo. O arquivo tabela_compat.rds permanece a versão
# por maior área (auditável).
tabela_compat_uso <- tabela_compat %>%
  mutate(ID_MN_RESI_10 = if_else(ID_MN_RESI_25 %in% names(DICIONARIO_DE_PARA),
                                 DICIONARIO_DE_PARA[ID_MN_RESI_25],
                                 ID_MN_RESI_10))

# De-para vetorizado para casos SINAN: cobre os mesmos códigos pós-2010 da
# população (ex.: Boa Esperança do Norte/510183 -> Nova Ubiratã/510624),
# mantendo coerência entre numerador e denominador.
DE_PARA_CASOS <- setNames(tabela_compat_uso$ID_MN_RESI_10,
                          tabela_compat_uso$ID_MN_RESI_25)
DE_PARA_CASOS <- DE_PARA_CASOS[!is.na(DE_PARA_CASOS) & names(DE_PARA_CASOS) != "260545"]

censo <- readRDS(here::here("data", "processed", "censo", "censo_2022_compat.rds"))
malha_10 <- readRDS(here::here("data", "raw", "malhas", "malha_BR_10.RDS"))

# Módulo de Calor Extremo (ERA5-Land Diário: P90 histórico + Ondas de Calor)
calor_extremo <- readRDS(file.path(DIR_ERA5, "indicadores_calor_anual_2010_2025.rds")) %>%
  mutate(
    ANO_EPI    = as.character(ano),
    ID_MN_RESI = as.character(ID_MN_RESI)
  ) %>%
  select(ANO_EPI, ID_MN_RESI, n_ondas_ano, dias_em_onda_ano,
         tmax_extrema_ano, tmedia_anual, noites_tropicais)

# ============================================================================ #
# 1. SINAN: contagem anual por município (2010-2025) -------------------------
# ============================================================================ #
cat("==> [1/5] SINAN: contagem de casos (2010-2025)...\n")
t0 <- Sys.time()

arquivo_contagem <- file.path(DIR_SINAN_PROC, "base_contagem_2010_2025_v3.rds")
arquivo_mensal   <- file.path(DIR_SINAN_PROC, "base_contagem_mensal_2010_2025_v3.rds")
if (file.exists(arquivo_contagem) && file.exists(arquivo_mensal)) {
  cat("  checkpoint: contagens existentes reutilizadas\n")
  base_contagem <- readRDS(arquivo_contagem)
  base_mensal   <- readRDS(arquivo_mensal)
  n_dedup_arquivo <- attr(base_contagem, "n_dedup_arquivo")
  if (is.null(n_dedup_arquivo)) n_dedup_arquivo <- NA_integer_
} else {
EXCLUIR_CLASSIF <- c("5", "6", "7")  # descartado, chikungunya, zika
CONFIRMADOS    <- c("10", "11", "12")

# Campos usados para detectar o mesmo caso em arquivos DBC de anos
# consecutivos (notificações atrasadas reaparecem no arquivo do ano seguinte).
CAMPOS_FP <- c("DT_NOTIFIC", "DT_SIN_PRI", "DT_DIGITA", "NU_IDADE_N",
               "CS_SEXO", "CS_RACA", "ID_MN_RESI", "CLASSI_FIN", "EVOLUCAO",
               "DT_ENCERRA", "DT_INTERNA", "DT_OBITO")
fingerprint <- function(d) {
  partes <- lapply(CAMPOS_FP, function(campo) {
    v <- if (campo %in% names(d)) as.character(d[[campo]]) else rep("", nrow(d))
    v[is.na(v)] <- ""
    v
  })
  do.call(paste, c(partes, list(sep = "|")))
}

n_dedup_arquivo <- 0L
fp_ano_anterior <- NULL
contagens <- list(); contagens_mes <- list()
anos_dbc <- 2010:2025
for (a in anos_dbc) {
  f <- file.path(DIR_DBCS, sprintf("DENGBR%d.dbc", a %% 100))
  if (!file.exists(f)) { cat("  AVISO: arquivo ausente:", f, "\n"); next }
  d <- read.dbc(f)
  if (!all(c("ID_AGRAVO", "CLASSI_FIN", "DT_NOTIFIC", "ID_MN_RESI", "EVOLUCAO") %in% names(d))) {
    cat("  AVISO: colunas ausentes em", f, "- ignorado\n"); next
  }
  d <- d %>%
    filter(ID_AGRAVO == "A90") %>%
    mutate(ANO_EPI = as.character(lubridate::epiyear(DT_NOTIFIC)),
           MES = lubridate::month(DT_NOTIFIC),
           ID_MN_RESI = as.character(ID_MN_RESI),
           CLASSI_FIN = as.character(CLASSI_FIN))

  # Deduplicação ENTRE arquivos: registros notificados em anos anteriores ao
  # ano do arquivo que já constam do arquivo do ano anterior são o mesmo caso
  # (duplicação de digitação atrasada, ex.: 2.180 registros de 30-31/12/2012
  # repetidos entre DENGBR12 e DENGBR13; note que a virada MMWR faz esses
  # registros pertencerem ao ano epidemiológico seguinte). A comparação usa o
  # fingerprint de 12 campos e é aplicada antes de qualquer agregação.
  d$FP <- fingerprint(d)
  d$NOTIF_ANO <- lubridate::year(d$DT_NOTIFIC)
  if (a > 2010 && !is.null(fp_ano_anterior)) {
    atrasados <- d$NOTIF_ANO < a
    if (any(atrasados)) {
      dup <- atrasados & (d$FP %in% fp_ano_anterior)
      n_dedup_arquivo <- n_dedup_arquivo + sum(dup)
      if (any(dup)) cat("  dedup inter-arquivos em", a, ":", sum(dup), "registros\n")
      d <- d[!dup, ]
    }
  }
  # Guarda o fingerprint dos registros notificados no próprio ano do arquivo
  # para a próxima iteração
  fp_ano_anterior <- d$FP[d$NOTIF_ANO == a]
  d$NOTIF_ANO <- NULL

  # De-para pós-2010 -> malha 2010 ANTES da agregação: dicionário deliberado,
  # códigos pós-2010 compatibilizados por maior área (ex.: 510183 -> 510624) e
  # bloco do Distrito Federal (códigos operacionais iniciados em 53, como
  # 5399xx, reatribuídos a Brasília/530010).
  d <- d %>%
    mutate(
      ID_MN_RESI = case_when(
        ID_MN_RESI %in% names(DICIONARIO_DE_PARA) ~ DICIONARIO_DE_PARA[ID_MN_RESI],
        ID_MN_RESI %in% names(DE_PARA_CASOS)      ~ DE_PARA_CASOS[ID_MN_RESI],
        substr(ID_MN_RESI, 1, 2) == "53" & ID_MN_RESI != "530010" ~ "530010",
        TRUE ~ ID_MN_RESI))

  # Agregação anual
  d_anual <- d %>%
    group_by(ANO_EPI, ID_MN_RESI) %>%
    summarise(
       CASOS_PROV = sum(!is.na(CLASSI_FIN) & !CLASSI_FIN %in% EXCLUIR_CLASSIF),
       CASOS_CONF = sum(!is.na(CLASSI_FIN) & CLASSI_FIN %in% CONFIRMADOS),
      NU_OBITOS  = sum(EVOLUCAO == 2, na.rm = TRUE),
      .groups = "drop")
  contagens[[as.character(a)]] <- d_anual

  # Agregação mensal (para sazonalidade e correlações clima x casos)
  d_mes <- d %>%
    group_by(ANO_EPI, MES, ID_MN_RESI) %>%
    summarise(CASOS_PROV = sum(!is.na(CLASSI_FIN) & !CLASSI_FIN %in% EXCLUIR_CLASSIF),
              .groups = "drop")
  contagens_mes[[as.character(a)]] <- d_mes

  cat("  ano", a, "->", format(nrow(d_anual), big.mark = "."), "linhas\n")
  rm(d, d_anual, d_mes, atrasados); gc()
}

base_contagem <- bind_rows(contagens) %>%
  # Deduplicação do par (ano epidemiológico, município): arquivos DBC podem
  # conter notificações de anos anteriores (digitação atrasada) com o mesmo
  # epiyear; são casos distintos -> somar as contagens.
  group_by(ANO_EPI, ID_MN_RESI) %>%
  summarise(CASOS_PROV = sum(CASOS_PROV),
            CASOS_CONF = sum(CASOS_CONF),
            NU_OBITOS  = sum(NU_OBITOS),
            .groups = "drop")

base_mensal <- bind_rows(contagens_mes) %>%
  group_by(ANO_EPI, MES, ID_MN_RESI) %>%
  summarise(CASOS_PROV = sum(CASOS_PROV), .groups = "drop")

attr(base_contagem, "n_dedup_arquivo") <- n_dedup_arquivo
saveRDS(base_contagem, arquivo_contagem)
saveRDS(base_mensal,   arquivo_mensal)
cat("  contagens OK em", round(difftime(Sys.time(), t0, units = "mins"), 1), "min\n")
cat("  registros duplicados removidos entre arquivos:", n_dedup_arquivo, "\n")
}
cat("  pares unicos (ano, municipio):", format(nrow(base_contagem), big.mark = "."),
    "| (ano, mes, municipio):", format(nrow(base_mensal), big.mark = "."), "\n\n")

# Auditoria do de-para e reaplicação defensiva (checkpoint gerado por versão
# antiga do script pode conter códigos pós-2010; idempotente para contagens
# novas, pois os códigos-fonte desaparecem após o primeiro remapeamento).
mapa_efetivo <- c(DICIONARIO_DE_PARA, DE_PARA_CASOS)
mapa_efetivo <- mapa_efetivo[!duplicated(names(mapa_efetivo))]
depara_audit <- base_contagem %>%
  filter(ID_MN_RESI %in% names(mapa_efetivo)) %>%
  group_by(ID_MN_RESI) %>%
  summarise(N = sum(CASOS_PROV), .groups = "drop")
if (nrow(depara_audit) > 0) {
  cat("  de-para (casos reatribuidos):",
      paste(sprintf("%s -> %s: %d", depara_audit$ID_MN_RESI,
                    mapa_efetivo[depara_audit$ID_MN_RESI],
                    depara_audit$N), collapse = " | "), "\n")
  base_contagem <- base_contagem %>%
    mutate(ID_MN_RESI = if_else(ID_MN_RESI %in% names(mapa_efetivo),
                                mapa_efetivo[ID_MN_RESI], ID_MN_RESI)) %>%
    group_by(ANO_EPI, ID_MN_RESI) %>%
    summarise(CASOS_PROV = sum(CASOS_PROV), CASOS_CONF = sum(CASOS_CONF),
              NU_OBITOS  = sum(NU_OBITOS), .groups = "drop")
  base_mensal <- base_mensal %>%
    mutate(ID_MN_RESI = if_else(ID_MN_RESI %in% names(mapa_efetivo),
                                mapa_efetivo[ID_MN_RESI], ID_MN_RESI)) %>%
    group_by(ANO_EPI, MES, ID_MN_RESI) %>%
    summarise(CASOS_PROV = sum(CASOS_PROV), .groups = "drop")
} else {
  cat("  de-para: nenhum código pós-2010 pendente (contagens já harmonizadas)\n")
}

# Diagnóstico de códigos fora da malha (mantidos fora do painel) e exclusão
# explícita de Fernando de Noronha (já fora do grid de 5.564 municípios).
ids_malha <- unique(malha_10$ID_MN_RESI[malha_10$ID_MN_RESI != "260545"])
diag_fora <- base_contagem %>%
  filter(!ID_MN_RESI %in% ids_malha, ID_MN_RESI != "260545") %>%
  summarise(codigos = n_distinct(ID_MN_RESI), casos = sum(CASOS_PROV))
diag_noronha <- base_contagem %>%
  filter(ID_MN_RESI == "260545") %>%
  summarise(casos = sum(CASOS_PROV))
cat(sprintf("  codigos fora da malha: %d | casos: %s\n",
            diag_fora$codigos, format(diag_fora$casos, big.mark = ".")))
cat(sprintf("  Noronha (excluida do painel): %s casos\n",
            format(diag_noronha$casos, big.mark = ".")))

# ============================================================================ #
# 2. População anual compatibilizada (2010-2025) ------------------------------
# ============================================================================ #
cat("==> [2/5] População anual (2010-2025)...\n")

# 2.1 População 2010: malha censitária + Nazária (código-base)
pop2010 <- st_read(file.path(DIR_MALHAS, "municipios_2010.shp"), quiet = TRUE) %>%
  st_drop_geometry() %>%
  select(ID_MN_RESI = codigo_ibg, POP = populacao) %>%
  mutate(ID_MN_RESI = substr(as.character(ID_MN_RESI), 1, 6),
         ANO_EPI = "2010",
         POP = as.numeric(POP)) %>%
  bind_rows(tibble(ANO_EPI = "2010", ID_MN_RESI = "220672", POP = 8039)) %>%
  left_join(tabela_compat_uso, by = c("ID_MN_RESI" = "ID_MN_RESI_25")) %>%
  mutate(ID_MN_RESI = if_else(!is.na(ID_MN_RESI_10), ID_MN_RESI_10, ID_MN_RESI)) %>%
  group_by(ANO_EPI, ID_MN_RESI) %>%
  summarise(POP = sum(POP, na.rm = TRUE), .groups = "drop")

# 2.2 População 2011-2024: POP.xlsx, com 2011 e 2018 lidos da tabela oficial
#     SIDRA 6579. A auditoria de 21/09/2026 identificou que a aba de 2018 do
#     POP.xlsx continha cópia dos valores de 2019 (POP idêntico nas 5.570
#     linhas) e que 2011 divergia da tabela oficial em -2.790 habitantes
#     (permuta de limites municipais no Maranhão entre as duas fontes).
pop_sidra_ano <- function(ano) {
  get_sidra(x = 6579, period = as.character(ano), geo = "City",
            variable = 9324, header = TRUE, value_type = "numeric") %>%
    select(ID_MN_RESI = `Município (Código)`, POP = Valor) %>%
    mutate(ID_MN_RESI = substr(as.character(ID_MN_RESI), 1, 6),
           POP = as.numeric(POP)) %>%
    left_join(tabela_compat_uso, by = c("ID_MN_RESI" = "ID_MN_RESI_25")) %>%
    mutate(ID_MN_RESI = if_else(!is.na(ID_MN_RESI_10), ID_MN_RESI_10, ID_MN_RESI)) %>%
    # Noronha sai completamente (não é reatribuída a Recife)
    filter(ID_MN_RESI != "260545") %>%
    group_by(ID_MN_RESI) %>%
    summarise(POP = sum(POP, na.rm = TRUE), .groups = "drop") %>%
    mutate(ANO_EPI = as.character(ano))
}

ler_pop <- function(ano) {
  read_excel(file.path(DIR_POP, "POP.xlsx"), sheet = as.character(ano)) %>%
    select(ID_MN_RESI, POP, ANO_EPI = ANO) %>%
    mutate(ID_MN_RESI = substr(as.character(ID_MN_RESI), 1, 6),
           ANO_EPI = as.character(ANO_EPI),
           POP = as.numeric(POP)) %>%
    filter(ID_MN_RESI != "260545") %>%
    # Compatibilização 2025 -> 2010: municípios criados pós-2010 são
    # reatribuídos ao município de origem (de-para + maior área). Sem este
    # passo, essas linhas seriam descartadas na junção com o painel de 5.564
    # municípios, subestimando a população dos municípios de origem.
    left_join(tabela_compat_uso, by = c("ID_MN_RESI" = "ID_MN_RESI_25")) %>%
    mutate(ID_MN_RESI = if_else(!is.na(ID_MN_RESI_10), ID_MN_RESI_10, ID_MN_RESI)) %>%
    select(ID_MN_RESI, POP, ANO_EPI)
}
pop_1114 <- bind_rows(lapply(setdiff(2011:2024, c(2011, 2018)), ler_pop),
                      pop_sidra_ano(2011),
                      pop_sidra_ano(2018)) %>%
  mutate(ANO_EPI = as.character(ANO_EPI)) %>%
  # Re-agregação pós-compatibilização: municípios criados pós-2010 passam a
  # compartilhar o código do município de origem (ex.: Mojuí dos Campos e
  # Santarém convergem para 150680); sem este passo, o painel ganharia pares
  # (ano, município) duplicados e o join multiplicaria linhas.
  group_by(ANO_EPI, ID_MN_RESI) %>%
  summarise(POP = sum(POP, na.rm = TRUE), .groups = "drop")

# 2.2b Validação das abas do POP.xlsx contra a tabela oficial (anos com
#      estimativa no SIDRA 6579). A comparação é feita após a harmonização
#      (mesma filtragem de Noronha e de-para) nos dois lados.
val_pop <- character()
for (ano_v in c(2011:2017, 2019:2021, 2024)) {
  xl <- try(ler_pop(ano_v), silent = TRUE)
  sd <- try(pop_sidra_ano(ano_v), silent = TRUE)
  if (inherits(xl, "try-error") || inherits(sd, "try-error")) next
  tot_xl <- sum(xl$POP, na.rm = TRUE)
  tot_sd <- sum(sd$POP, na.rm = TRUE)
  val_pop <- c(val_pop, sprintf("pop_%d_xlsx=%.0f pop_%d_sidra=%.0f dif=%+.0f",
                                ano_v, tot_xl, ano_v, tot_sd, tot_xl - tot_sd))
}
cat("  validação POP.xlsx x SIDRA 6579 (2011-2021, 2024):\n  ",
    paste(val_pop, collapse = "\n  "), "\n")

# 2.3 População 2025: SIDRA Tabela 6579 (estimativas municipais)
pop2025 <- pop_sidra_ano(2025)

pop_anual <- bind_rows(pop2010, pop_1114, pop2025) %>%
  # Garantia de unicidade do par (ano, município) após a harmonização.
  group_by(ANO_EPI, ID_MN_RESI) %>%
  summarise(POP = sum(POP, na.rm = TRUE), .groups = "drop")
saveRDS(pop_anual, file.path(DIR_POP_PROC, "pop_anual_compat.rds"))

# Verificação de completude populacional (5.564 por ano)
complet_pop <- pop_anual %>% count(ANO_EPI)
cat("  municípios com POP por ano:\n")
print(as.data.frame(complet_pop), row.names = FALSE)
cat("\n")

# ============================================================================ #
# 3. Painel epidemiológico completo (ano x município) -------------------------
# ============================================================================ #
cat("==> [3/5] Painel casos + população + TI...\n")

ids <- sort(unique(malha_10$ID_MN_RESI[malha_10$ID_MN_RESI != "260545"]))
stopifnot(length(ids) == 5564L)

painel <- expand.grid(ANO_EPI = as.character(2010:2025), ID_MN_RESI = ids,
                      KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE) %>%
  as_tibble() %>%
  left_join(base_contagem, by = c("ANO_EPI", "ID_MN_RESI")) %>%
  mutate(across(c(CASOS_PROV, CASOS_CONF, NU_OBITOS), ~ replace_na(.x, 0))) %>%
  left_join(pop_anual, by = c("ANO_EPI", "ID_MN_RESI")) %>%
  mutate(TI_100mil = CASOS_PROV / POP * 100000)

cat("  linhas:", nrow(painel), "| municípios:", n_distinct(painel$ID_MN_RESI),
    "| NA em POP:", sum(is.na(painel$POP)), "\n\n")

# ============================================================================ #
# 4. Indicadores socioespaciais (Censo 2022) e clima anual --------------------
# ============================================================================ #
cat("==> [4/5] Socioespacial (Censo 2022) e clima anualizado...\n")

# Área municipal (km2) a partir da malha 2010 em EPSG:5880 (Brazil Polyconic)
area_km2 <- malha_10 %>%
  filter(ID_MN_RESI != "260545") %>%
  mutate(AREA_KM2 = as.numeric(st_area(st_transform(geometry, 5880))) / 1e6) %>%
  st_drop_geometry() %>%
  select(ID_MN_RESI, AREA_KM2)

# Densidade demográfica e proporção em favelas. O denominador é a população
# residente do Censo 2022 (universo do recenseamento), e não a estimativa
# anual, para manter numerador e denominador no mesmo universo.
censo_geo <- censo %>%
  left_join(area_km2, by = "ID_MN_RESI") %>%
  mutate(prop_pop_favela = pop_favela / pop_censo_2022 * 100,
         dens_demografica_2022 = pop_censo_2022 / AREA_KM2) %>%
  select(ID_MN_RESI, dom_total, prop_agua_rede, prop_esgoto_rede,
         prop_esgoto_adequado, prop_lixo_coletado, prop_pop_favela,
         dens_demografica_2022)

# Clima Anual: integra ondas de calor + precipitação/umidade (se presentes)
arqs_mensais <- list.files(DIR_ERA5,
                           pattern = "^clima_mensal_municipal_.*\\.rds$", full.names = TRUE)

if (length(arqs_mensais) > 0) {
  clima_mensal <- bind_rows(lapply(arqs_mensais, readRDS)) %>%
    distinct(mes, ID_MN_RESI, .keep_all = TRUE) %>%
    mutate(ANO_EPI = as.character(year(mes)), ID_MN_RESI = as.character(ID_MN_RESI)) %>%
    group_by(ANO_EPI, ID_MN_RESI) %>%
    summarise(
      umid_rel_min    = min(umid_rel, na.rm = TRUE),
      umid_rel_media  = mean(umid_rel, na.rm = TRUE),
      umid_rel_max    = max(umid_rel, na.rm = TRUE),
      precip_mm_min   = min(precip_mm, na.rm = TRUE),
      precip_mm_media = mean(precip_mm, na.rm = TRUE),
      precip_mm_max   = max(precip_mm, na.rm = TRUE),
      precip_mm_acum  = sum(precip_mm, na.rm = TRUE),
      .groups = "drop"
    )

  clima_anual <- calor_extremo %>%
    left_join(clima_mensal, by = c("ANO_EPI", "ID_MN_RESI")) %>%
    # Acumulado anual nulo é artefato de dado ausente: nenhum par
    # município-ano real tem chuva zero no Brasil.
    mutate(n_precip_zero = sum(precip_mm_acum == 0, na.rm = TRUE),
           precip_mm_acum = if_else(precip_mm_acum == 0, NA_real_, precip_mm_acum))
  cat(sprintf("  município-anos com chuva anual zero tratados como ausentes: %d\n",
              unique(clima_anual$n_precip_zero)))
} else {
  clima_anual <- calor_extremo
}

# ============================================================================ #
# 5. Dataset consolidado final -------------------------------------------------
# ============================================================================ #
cat("==> [5/5] Consolidação final e auditoria...\n")

dataset <- painel %>%
  left_join(censo_geo,   by = "ID_MN_RESI") %>%
  left_join(clima_anual, by = c("ANO_EPI", "ID_MN_RESI")) %>%
  left_join(malha_10 %>% filter(ID_MN_RESI != "260545") %>%
              st_drop_geometry() %>%
              select(ID_MN_RESI, CD_MUN, NM_MUN, CD_UF),
            by = "ID_MN_RESI") %>%
  select(ANO_EPI, ID_MN_RESI, CD_MUN, NM_MUN, CD_UF,
         CASOS_PROV, CASOS_CONF, NU_OBITOS, POP, TI_100mil,
         dom_total, prop_agua_rede, prop_esgoto_rede, prop_esgoto_adequado,
         prop_lixo_coletado, prop_pop_favela, dens_demografica_2022,
         # Indicadores de Calor Extremo (ERA5-Land Diário)
         n_ondas_ano, dias_em_onda_ano, tmax_extrema_ano, tmedia_anual, noites_tropicais,
         # Umidade e Precipitação (se presentes)
         any_of(c("umid_rel_min", "umid_rel_media", "umid_rel_max",
                  "precip_mm_min", "precip_mm_media", "precip_mm_max", "precip_mm_acum"))) %>%
  arrange(ANO_EPI, ID_MN_RESI)

# ---- Auditoria ------------------------------------------------------------- #
log <- character()
log <- c(log,
         sprintf("linhas_esperadas=%d", 16 * 5564),
         sprintf("linhas_obtidas=%d", nrow(dataset)),
         sprintf("municipios_unicos=%d", n_distinct(dataset$ID_MN_RESI)),
         sprintf("anos_unicos=%d", n_distinct(dataset$ANO_EPI)),
         sprintf("total_casos_painel=%.0f", sum(dataset$CASOS_PROV)),
         sprintf("total_2025=%.0f", sum(dataset$CASOS_PROV[dataset$ANO_EPI == "2025"])),
         sprintf("registros_deduplicados_entre_arquivos=%d", n_dedup_arquivo),
         sprintf("casos_fora_da_malha=%d (codigos=%d)", diag_fora$casos, diag_fora$codigos),
         sprintf("casos_noronha_excluidos=%d", diag_noronha$casos),
         sprintf("na_pop=%d", sum(is.na(dataset$POP))),
         sprintf("na_ti=%d", sum(is.na(dataset$TI_100mil))),
         sprintf("na_censo=%d", sum(is.na(dataset$prop_agua_rede))),
         sprintf("na_ondas_ano=%d", sum(is.na(dataset$n_ondas_ano))),
         sprintf("na_dias_onda=%d", sum(is.na(dataset$dias_em_onda_ano))),
         sprintf("na_tmax_extrema=%d", sum(is.na(dataset$tmax_extrema_ano))),
         sprintf("na_tmedia_anual=%d", sum(is.na(dataset$tmedia_anual))),
         sprintf("na_noites_tropicais=%d", sum(is.na(dataset$noites_tropicais))),
         if ("umid_rel_media" %in% names(dataset)) sprintf("na_umid_media=%d", sum(is.na(dataset$umid_rel_media))) else "umid_rel=nao_incluso",
         if ("precip_mm_acum" %in% names(dataset)) sprintf("na_precip_acum=%d", sum(is.na(dataset$precip_mm_acum))) else "precip_acum=nao_incluso",
         "tmax_definicao=maximo dos quatro instantaneos diarios ERA5-Land; P90 historico municipal (2010-2025)",
         sprintf("pop_2018=sidra_6579 (correcao de aba duplicada no POP.xlsx)"),
         val_pop)

# Auditoria do de-para de municípios pós-2010
if (nrow(depara_audit) > 0) {
  for (i in seq_len(nrow(depara_audit))) {
    log <- c(log, sprintf("de_para_%s->%s_casos=%d", depara_audit$ID_MN_RESI[i],
                          DICIONARIO_DE_PARA[depara_audit$ID_MN_RESI[i]],
                          depara_audit$N[i]))
  }
} else {
  log <- c(log, "de_para=nenhum codigo pos-2010 pendente")
}

# Totais anuais de casos prováveis vs referências oficiais (MS)
oficial <- c("2010"=1011548, "2013"=1452489, "2015"=1688688, "2016"=1483623,
             "2019"=1540961, "2022"=1423018, "2024"=6464269)
tot_ano <- dataset %>% group_by(ANO_EPI) %>%
  summarise(n = sum(CASOS_PROV), .groups = "drop")
for (a in names(oficial)) {
  v <- tot_ano$n[tot_ano$ANO_EPI == a]
  if (length(v)) log <- c(log, sprintf("total_%s=%.0f (oficial %s, dif %+.1f%%)",
                                       a, v, oficial[[a]],
                                       100 * (v - oficial[[a]]) / oficial[[a]]))
}

writeLines(log, file.path(DIR_LOG, "log_auditoria_consolidacao.txt"))

# Checagens defensivas obrigatórias (AGENTS.md): dimensões, ausência de NA nas
# variáveis analíticas e correspondência exata dos códigos com a malha.
stopifnot(
  nrow(dataset) == 16L * 5564L,
  n_distinct(dataset$ID_MN_RESI) == 5564L,
  n_distinct(dataset$ANO_EPI) == 16L,
  !any(is.na(dataset$POP)),
  !any(is.na(dataset$TI_100mil)),
  !any(is.na(dataset$prop_agua_rede)),
  !any(is.na(dataset$prop_esgoto_adequado)),
  !any(is.na(dataset$prop_lixo_coletado)),
  identical(sort(unique(dataset$ID_MN_RESI)), sort(ids)))

# Exportação final (RDS e Parquet)
saveRDS(dataset, here::here("data", "processed", "dataset_tcc_consolidado.rds"))
write_parquet(dataset, here::here("data", "processed", "dataset_tcc_consolidado.parquet"))

cat("\n--- LOG DE AUDITORIA (CONSOLIDAÇÃO) ---\n")
cat(log, sep = "\n")
cat("\nDataset final RDS:     data/processed/dataset_tcc_consolidado.rds\n")
cat("Dataset final Parquet: data/processed/dataset_tcc_consolidado.parquet\n")

cat("Tamanho RDS em disco:  ", format(file.size(here::here("data", "processed", "dataset_tcc_consolidado.rds")), big.mark = "."), " bytes\n")
