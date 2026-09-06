# ============================================================================ #
# 03_consolidacao_dataset.R
# ----------------------------------------------------------------------------
# Consolidação do dataset final do TCC: SINAN, população, Censo 2022 e clima.
#
# Definição operacional de casos prováveis (CALIBRADA com os totais oficiais
# do Ministério da Saúde, erro <= 2,5% nos anos de referência):
#   Casos prováveis = notificações de dengue (ID_AGRAVO A90) EXCETO
#     CLASSI_FIN 5 (descartado), 6 (chikungunya) e 7 (zika).
#   Isso equivale a CLASSI_FIN em {1,2,3,4,8,10,11,12} ou NA (sem classificação),
#   coerente com a definição operacional do MS ("notificados menos descartados").
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
#   * 03. Dados/Originais/SINAN_Processado/base_contagem_2010_2025.rds
#   * 03. Dados/Originais/Populacao_Processado/pop_anual_compat.rds
#   * 03. Dados/dataset_tcc_consolidado.rds  (base final, LEAN - sem geometry)
#   * 03. Dados/Originais/.../log_auditoria_consolidacao.txt
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
})
sf_use_s2(FALSE)

DIR_DBCS <- "03. Dados/Originais/DBCs"
DIR_POP  <- "03. Dados/Originais/População"
DIR_MALHAS <- "03. Dados/Originais/Malhas"
DIR_ERA5 <- "03. Dados/Originais/Dados de temperatura - ERA5_ERA5LAND"
DIR_SINAN_PROC <- "03. Dados/Originais/SINAN_Processado"
DIR_POP_PROC  <- "03. Dados/Originais/Populacao_Processado"
dir.create(DIR_SINAN_PROC, showWarnings = FALSE, recursive = TRUE)
dir.create(DIR_POP_PROC,  showWarnings = FALSE, recursive = TRUE)

tabela_compat <- readRDS("03. Dados/Originais/Compatibilizacao/tabela_compat.rds")

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
censo <- readRDS("03. Dados/Originais/Censo_2022/censo_2022_compat.rds")
clima <- readRDS(file.path(DIR_ERA5, "processado", "clima_mensal_municipal_2010.rds"))
malha_10 <- readRDS("03. Dados/malha_BR_10.RDS")

# ============================================================================ #
# 1. SINAN: contagem anual por município (2010-2025) -------------------------
# ============================================================================ #
cat("==> [1/5] SINAN: contagem de casos (2010-2025)...\n")
t0 <- Sys.time()

arquivo_contagem <- file.path(DIR_SINAN_PROC, "base_contagem_2010_2025.rds")
arquivo_mensal   <- file.path(DIR_SINAN_PROC, "base_contagem_mensal_2010_2025.rds")
if (file.exists(arquivo_contagem) && file.exists(arquivo_mensal)) {
  cat("  checkpoint: contagens existentes reutilizadas\n")
  base_contagem <- readRDS(arquivo_contagem)
  base_mensal   <- readRDS(arquivo_mensal)
} else {

EXCLUIR_CLASSIF <- c("5", "6", "7")  # descartado, chikungunya, zika
CONFIRMADOS    <- c("10", "11", "12")

contagens <- list(); contagens_mes <- list()
anos_dbc <- 2010:2025
for (a in anos_dbc) {
  f <- file.path(DIR_DBCS, sprintf("DENGBR%d.dbc", a %% 100))
  if (!file.exists(f)) { cat("  AVISO: arquivo ausente:", f, "\n"); next }
  d <- read.dbc(f)
  if (!all(c("CLASSI_FIN", "DT_NOTIFIC", "ID_MN_RESI", "EVOLUCAO") %in% names(d))) {
    cat("  AVISO: colunas ausentes em", f, "- ignorado\n"); next
  }
  d <- d %>%
    mutate(ANO_EPI = as.character(lubridate::epiyear(DT_NOTIFIC)),
           MES = lubridate::month(DT_NOTIFIC),
           ID_MN_RESI = as.character(ID_MN_RESI),
           CLASSI_FIN = as.character(CLASSI_FIN))

  # De-para pós-2010 -> malha 2010 ANTES da agregação: casos de municípios
  # emancipados após 2010 são reatribuídos ao município de origem (ex.: Mojuí
  # dos Campos/150475 -> Santarém/150680), garantindo que a contagem já nasça
  # no código da malha de 2010 (idempotente: códigos-fonte não reaparecem).
  d <- d %>%
    mutate(ID_MN_RESI = if_else(ID_MN_RESI %in% names(DICIONARIO_DE_PARA),
                                DICIONARIO_DE_PARA[ID_MN_RESI], ID_MN_RESI))

  # Agregação anual
  d_anual <- d %>%
    group_by(ANO_EPI, ID_MN_RESI) %>%
    summarise(
      CASOS_PROV = sum(!CLASSI_FIN %in% EXCLUIR_CLASSIF),
      CASOS_CONF = sum(CLASSI_FIN %in% CONFIRMADOS),
      NU_OBITOS  = sum(EVOLUCAO == 2, na.rm = TRUE),
      .groups = "drop")
  contagens[[as.character(a)]] <- d_anual

  # Agregação mensal (para sazonalidade e correlações clima x casos)
  d_mes <- d %>%
    group_by(ANO_EPI, MES, ID_MN_RESI) %>%
    summarise(CASOS_PROV = sum(!CLASSI_FIN %in% EXCLUIR_CLASSIF),
              .groups = "drop")
  contagens_mes[[as.character(a)]] <- d_mes

  cat("  ano", a, "->", format(nrow(d_anual), big.mark = "."), "linhas\n")
  rm(d, d_anual, d_mes); gc()
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

saveRDS(base_contagem, arquivo_contagem)
saveRDS(base_mensal,   arquivo_mensal)
cat("  contagens OK em", round(difftime(Sys.time(), t0, units = "mins"), 1), "min\n")
}
cat("  pares unicos (ano, municipio):", format(nrow(base_contagem), big.mark = "."),
    "| (ano, mes, municipio):", format(nrow(base_mensal), big.mark = "."), "\n\n")

# Auditoria do de-para e reaplicação defensiva (checkpoint gerado por versão
# antiga do script pode conter códigos pós-2010; idempotente para contagens
# novas, pois os códigos-fonte desaparecem após o primeiro remapeamento).
depara_audit <- base_contagem %>%
  filter(ID_MN_RESI %in% names(DICIONARIO_DE_PARA)) %>%
  group_by(ID_MN_RESI) %>%
  summarise(N = sum(CASOS_PROV), .groups = "drop")
if (nrow(depara_audit) > 0) {
  cat("  de-para (casos reatribuidos):",
      paste(sprintf("%s -> %s: %d", depara_audit$ID_MN_RESI,
                    DICIONARIO_DE_PARA[depara_audit$ID_MN_RESI],
                    depara_audit$N), collapse = " | "), "\n")
  base_contagem <- base_contagem %>%
    mutate(ID_MN_RESI = if_else(ID_MN_RESI %in% names(DICIONARIO_DE_PARA),
                                DICIONARIO_DE_PARA[ID_MN_RESI], ID_MN_RESI)) %>%
    group_by(ANO_EPI, ID_MN_RESI) %>%
    summarise(CASOS_PROV = sum(CASOS_PROV), CASOS_CONF = sum(CASOS_CONF),
              NU_OBITOS  = sum(NU_OBITOS), .groups = "drop")
  base_mensal <- base_mensal %>%
    mutate(ID_MN_RESI = if_else(ID_MN_RESI %in% names(DICIONARIO_DE_PARA),
                                DICIONARIO_DE_PARA[ID_MN_RESI], ID_MN_RESI)) %>%
    group_by(ANO_EPI, MES, ID_MN_RESI) %>%
    summarise(CASOS_PROV = sum(CASOS_PROV), .groups = "drop")
} else {
  cat("  de-para: nenhum código pós-2010 pendente (contagens já harmonizadas)\n")
}

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

# 2.2 População 2011-2024: POP.xlsx
ler_pop <- function(ano) {
  read_excel(file.path(DIR_POP, "POP.xlsx"), sheet = as.character(ano)) %>%
    select(ID_MN_RESI, POP, ANO_EPI = ANO) %>%
    mutate(ID_MN_RESI = substr(as.character(ID_MN_RESI), 1, 6),
           POP = as.numeric(POP)) %>%
    # Compatibilização 2025 -> 2010: municípios criados pós-2010 são
    # reatribuídos ao município de origem (de-para + maior área). Sem este
    # passo, essas linhas seriam descartadas na junção com o painel de 5.564
    # municípios, subestimando a população dos municípios de origem.
    left_join(tabela_compat_uso, by = c("ID_MN_RESI" = "ID_MN_RESI_25")) %>%
    mutate(ID_MN_RESI = if_else(!is.na(ID_MN_RESI_10), ID_MN_RESI_10, ID_MN_RESI)) %>%
    select(ID_MN_RESI, POP, ANO_EPI)
}
pop_1114 <- bind_rows(lapply(2011:2024, ler_pop)) %>%
  mutate(ANO_EPI = as.character(ANO_EPI)) %>%
  # Re-agregação pós-compatibilização: municípios criados pós-2010 passam a
  # compartilhar o código do município de origem (ex.: Mojuí dos Campos e
  # Santarém convergem para 150680); sem este passo, o painel ganharia pares
  # (ano, município) duplicados e o join multiplicaria linhas.
  group_by(ANO_EPI, ID_MN_RESI) %>%
  summarise(POP = sum(POP, na.rm = TRUE), .groups = "drop")

# 2.3 População 2025: SIDRA Tabela 6579 (estimativas municipais)
pop2025 <- get_sidra(x = 6579, period = "2025", geo = "City",
                     variable = 9324, header = TRUE, value_type = "numeric") %>%
  select(ID_MN_RESI_25 = `Município (Código)`, POP = Valor) %>%
  mutate(ID_MN_RESI_25 = substr(as.character(ID_MN_RESI_25), 1, 6)) %>%
  left_join(tabela_compat_uso, by = "ID_MN_RESI_25") %>%
  mutate(ID_MN_RESI = if_else(!is.na(ID_MN_RESI_10), ID_MN_RESI_10, ID_MN_RESI_25)) %>%
  group_by(ID_MN_RESI) %>%
  summarise(POP = sum(POP, na.rm = TRUE), .groups = "drop") %>%
  mutate(ANO_EPI = "2025")

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

# Área municipal (km2) a partir da malha 2010 em projeção de área (Brazil
# Polyconic, EPSG:5880) -- aproximação para densidade demográfica.
area_km2 <- malha_10 %>%
  filter(ID_MN_RESI != "260545") %>%
  mutate(AREA_KM2 = as.numeric(st_area(st_transform(geometry, 5880))) / 1e6) %>%
  st_drop_geometry() %>%
  select(ID_MN_RESI, AREA_KM2)

# Densidade = POP 2022 / área. População residente 2022 vem do POP.xlsx.
pop2022 <- pop_anual %>% filter(ANO_EPI == "2022") %>% select(ID_MN_RESI, POP2022 = POP)

censo_geo <- censo %>%
  left_join(pop2022, by = "ID_MN_RESI") %>%
  left_join(area_km2, by = "ID_MN_RESI") %>%
  mutate(prop_pop_favela = pop_favela / POP2022 * 100,
         dens_demografica_2022 = POP2022 / AREA_KM2) %>%
  select(ID_MN_RESI, dom_total, prop_agua_rede, prop_esgoto_rede,
         prop_esgoto_adequado, prop_lixo_coletado, prop_pop_favela,
         dens_demografica_2022)

# Clima anual: extremos e medias mensais; precipitação acumulada no ano.
clima_anual <- clima %>%
  mutate(ANO_EPI = as.character(year(mes))) %>%
  group_by(ANO_EPI, ID_MN_RESI) %>%
  summarise(
            temp_C_min = min(temp_C, na.rm = TRUE),
            temp_C_media = mean(temp_C, na.rm = TRUE),
            temp_C_max = max(temp_C, na.rm = TRUE),
            umid_rel_min = min(umid_rel, na.rm = TRUE),
            umid_rel_media = mean(umid_rel, na.rm = TRUE),
            umid_rel_max = max(umid_rel, na.rm = TRUE),
            precip_mm_min = min(precip_mm, na.rm = TRUE),
            precip_mm_media = mean(precip_mm, na.rm = TRUE),
            precip_mm_max = max(precip_mm, na.rm = TRUE),
            precip_mm_acum = sum(precip_mm, na.rm = TRUE),
            .groups = "drop")

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
         temp_C_min, temp_C_media, temp_C_max,
         umid_rel_min, umid_rel_media, umid_rel_max,
         precip_mm_min, precip_mm_media, precip_mm_max, precip_mm_acum) %>%
  arrange(ANO_EPI, ID_MN_RESI)

# ---- Auditoria ------------------------------------------------------------- #
log <- character()
log <- c(log, sprintf("linhas_esperadas=%d", 16 * 5564),
         sprintf("linhas_obtidas=%d", nrow(dataset)),
         sprintf("municipios_unicos=%d", n_distinct(dataset$ID_MN_RESI)),
         sprintf("anos_unicos=%d", n_distinct(dataset$ANO_EPI)),
         sprintf("na_pop=%d", sum(is.na(dataset$POP))),
         sprintf("na_ti=%d", sum(is.na(dataset$TI_100mil))),
          sprintf("na_censo=%d", sum(is.na(dataset$prop_agua_rede))),
          sprintf("na_temp_min=%d", sum(is.na(dataset$temp_C_min))),
          sprintf("na_temp_media=%d", sum(is.na(dataset$temp_C_media))),
          sprintf("na_temp_max=%d", sum(is.na(dataset$temp_C_max))),
          sprintf("na_umid_media=%d", sum(is.na(dataset$umid_rel_media))),
          sprintf("na_precip_acum=%d", sum(is.na(dataset$precip_mm_acum))),
          "tmax_definicao=maxima mensal de t2m mensal; fonte diaria nao disponivel")
# Auditoria do de-para de municípios pós-2010 (casos reatribuídos ao origem)
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
writeLines(log, file.path(DIR_SINAN_PROC, "log_auditoria_consolidacao.txt"))
saveRDS(dataset, "03. Dados/dataset_tcc_consolidado.rds")

cat("\n--- LOG DE AUDITORIA (CONSOLIDAÇÃO) ---\n"); cat(log, sep = "\n")
cat("\nDataset final: 03. Dados/dataset_tcc_consolidado.rds\n")
cat("Tamanho em disco:", format(file.size("03. Dados/dataset_tcc_consolidado.rds"),
                                big.mark = "."), "bytes\n")
