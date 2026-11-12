here::i_am("R/04_ondas_calor_era5land.R")

# ============================================================================ #
# 04_ondas_calor_era5land.R
# Processamento em lote da série diária ERA5-Land (2010–2025) sobre a malha de
# 5.564 municípios e cálculo dos indicadores anuais de calor extremo.
# ============================================================================ #

suppressPackageStartupMessages({
  library(terra)
  library(exactextractr)
  library(sf)
  library(dplyr)
  library(tidyr)
  library(lubridate)
})

sf_use_s2(FALSE)
terraOptions(memfrac = 0.5)

DIR_NC   <- here::here("data", "raw", "clima", "era5land_diario")
DIR_OUT  <- here::here("data", "processed", "clima")
dir.create(DIR_OUT, showWarnings = FALSE, recursive = TRUE)

# 1. Carrega e prepara a malha municipal de 2010
malha <- readRDS(here::here("data", "raw", "malhas", "malha_BR_10.RDS")) %>%
  filter(ID_MN_RESI != "260545") %>%
  st_transform(4326) %>%
  arrange(ID_MN_RESI)

stopifnot(nrow(malha) == 5564L)
cent <- st_centroid(malha)

# Função para extração zonal diária de uma métrica agregada
extrair_metrica <- function(r_stat, malha, dias, nome_var) {
  ex <- exact_extract(r_stat, malha, fun = "mean", weights = "area", progress = FALSE)
  ex <- as.data.frame(ex)
  names(ex) <- as.character(dias)
  ex$ID_MN_RESI <- malha$ID_MN_RESI

  ex %>%
    pivot_longer(-ID_MN_RESI, names_to = "data", values_to = nome_var) %>%
    mutate(data = as.Date(data))
}

anos <- 2010:2025

for (ano in anos) {
  arq_rds <- file.path(DIR_OUT, sprintf("t2m_diario_municipal_%d.rds", ano))
  if (file.exists(arq_rds)) {
    cat(sprintf("[%d] Painel diário já processado. Pulando...\n", ano))
    next
  }

  arq_nc <- file.path(DIR_NC, sprintf("era5land_t2m_%d.nc", ano))
  if (!file.exists(arq_nc)) {
    cat(sprintf("[%d] Arquivo NetCDF não encontrado!\n", ano))
    next
  }

  cat(sprintf("\n===> [%d] Iniciando processamento...\n", ano))
  t0 <- Sys.time()

  r <- rast(arq_nc)
  datas_camadas <- as.Date(as.POSIXct(time(r), origin = "1970-01-01", tz = "UTC"))
  dias_ano <- sort(unique(datas_camadas))

  # Agregações diárias (K -> °C)
  r_max  <- tapp(r, index = datas_camadas, fun = max)  - 273.15
  r_min  <- tapp(r, index = datas_camadas, fun = min)  - 273.15
  r_mean <- tapp(r, index = datas_camadas, fun = mean) - 273.15

  # Extração zonal
  df_max  <- extrair_metrica(r_max,  malha, dias_ano, "tmax_C")
  df_min  <- extrair_metrica(r_min,  malha, dias_ano, "tmin_C")
  df_mean <- extrair_metrica(r_mean, malha, dias_ano, "tmean_C")

  painel_ano <- df_max %>%
    left_join(df_min,  by = c("ID_MN_RESI", "data")) %>%
    left_join(df_mean, by = c("ID_MN_RESI", "data"))

  # Imputação espacial para ilhas/litoral com NA (ex.: Itaparica)
  muns_na <- painel_ano %>%
    group_by(ID_MN_RESI) %>%
    summarise(todos_na = all(is.na(tmax_C)), .groups = "drop") %>%
    filter(todos_na) %>%
    pull(ID_MN_RESI)

  if (length(muns_na) > 0) {
    cent_na <- cent %>% filter(ID_MN_RESI %in% muns_na)
    cent_ok <- cent %>% filter(!ID_MN_RESI %in% muns_na)
    idx_vizinho <- st_nearest_feature(cent_na, cent_ok)
    doadores <- cent_ok$ID_MN_RESI[idx_vizinho]

    for (i in seq_along(muns_na)) {
      alvo   <- muns_na[i]
      doador <- doadores[i]
      dados_doador <- painel_ano %>% filter(ID_MN_RESI == doador)

      painel_ano <- painel_ano %>%
        rows_update(
          dados_doador %>% mutate(ID_MN_RESI = alvo),
          by = c("ID_MN_RESI", "data")
        )
    }
  }

  saveRDS(painel_ano, arq_rds)

  # Limpeza preventiva de memória
  rm(r, r_max, r_min, r_mean, df_max, df_min, df_mean, painel_ano)
  gc(verbose = FALSE)
  terra::tmpFiles(remove = TRUE)

  tempo_min <- round(difftime(Sys.time(), t0, units = "mins"), 1)
  cat(sprintf("[%d] Finalizado e salvo em %s min.\n", ano, tempo_min))
}

cat("\nProcessamento em lote concluído com sucesso.\n")

# ============================================================================ #
# Conferência rápida da integridade dos arquivos processados #
# ============================================================================ #

library(dplyr)
library(lubridate)

dir_proc <- here::here("data", "processed", "clima")
arqs <- list.files(dir_proc, pattern = "^t2m_diario_municipal_\\d{4}\\.rds$", full.names = TRUE)

stopifnot(length(arqs) == 16L)

conferencia <- lapply(arqs, function(f) {
  ano <- as.integer(sub(".*_(\\d{4})\\.rds$", "\\1", basename(f)))
  df <- readRDS(f)
  dias_esperados <- if (leap_year(ano)) 366L else 365L
  linhas_esperadas <- 5564L * dias_esperados

  tibble(
    ano = ano,
    n_linhas = nrow(df),
    integridade_linhas = nrow(df) == linhas_esperadas,
    nas_tmax = sum(is.na(df$tmax_C)),
    nas_tmin = sum(is.na(df$tmin_C)),
    tmin_media = round(mean(df$tmin_C, na.rm = TRUE), 2),
    tmax_media = round(mean(df$tmax_C, na.rm = TRUE), 2)
  )
}) %>% bind_rows() %>% arrange(ano)

print(conferencia, n = 16)

# ============================================================================ #
# Cálculo do P90 climatológico e indicadores anuais de calor extremo #
# ============================================================================ #

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(data.table)
})

dir_proc <- here::here("data", "processed", "clima")
arqs <- sort(list.files(dir_proc, pattern = "^t2m_diario_municipal_\\d{4}\\.rds$", full.names = TRUE))

cat("===> Passo 1: Extraindo série histórica para calcular o P90 climatológico...\n")

# Lê apenas colunas essenciais para o quantil, acumulando de forma enxuta
lista_tmax <- lapply(arqs, function(f) {
  df <- readRDS(f)
  df[, c("ID_MN_RESI", "tmax_C")]
})

df_tmax_hist <- bind_rows(lista_tmax)
rm(lista_tmax)
gc(verbose = FALSE)

# P90 histórico fixo por município (distribuição 2010–2025)
p90_historico <- df_tmax_hist %>%
  group_by(ID_MN_RESI) %>%
  summarise(p90_local = quantile(tmax_C, probs = 0.90, na.rm = TRUE), .groups = "drop")

rm(df_tmax_hist)
gc(verbose = FALSE)

cat("P90 climatológico calculado com sucesso para os 5.564 municípios.\n")

cat("\n===> Passo 2: Computando métricas anuais de calor extremo...\n")

# RLE deve usar a série completa: uma onda que atravessa dezembro/janeiro não
# pode ser quebrada artificialmente ao processar cada ano isoladamente.
cat("Processando a série completa para preservar ondas entre anos...\n")
df_hist <- bind_rows(lapply(arqs, readRDS)) %>%
  left_join(p90_historico, by = "ID_MN_RESI") %>%
  arrange(ID_MN_RESI, data) %>%
  mutate(dia_onda = tmax_C >= p90_local)

df_hist <- df_hist %>%
  group_by(ID_MN_RESI) %>%
  group_modify(~ {
    runs <- rle(.x$dia_onda)
    em_onda <- rep(runs$values & (runs$lengths >= 3), runs$lengths)
    inicio_onda <- em_onda & !dplyr::lag(em_onda, default = FALSE)
    .x$em_onda <- em_onda
    .x$inicio_onda <- inicio_onda
    .x
  }) %>%
  ungroup()

painel_calor_anual <- df_hist %>%
  group_by(ID_MN_RESI, ano = lubridate::year(data)) %>%
  summarise(
    n_ondas_ano      = sum(inicio_onda, na.rm = TRUE),
    dias_em_onda_ano = sum(em_onda, na.rm = TRUE),
    tmax_extrema_ano = max(tmax_C, na.rm = TRUE),
    tmedia_anual     = mean(tmean_C, na.rm = TRUE),
    noites_tropicais = sum(tmin_C >= 20.0, na.rm = TRUE),
    .groups = "drop"
  )

rm(df_hist)
gc(verbose = FALSE)

# Consolidação final do painel balanceado de calor
painel_calor_anual <- painel_calor_anual %>% arrange(ID_MN_RESI, ano)

stopifnot(nrow(painel_calor_anual) == 5564L * 16L)

caminho_saida <- file.path(dir_proc, "indicadores_calor_anual_2010_2025.rds")
saveRDS(painel_calor_anual, caminho_saida)

cat(sprintf("\nBase consolidada com sucesso: %s\n", caminho_saida))
print(glimpse(painel_calor_anual))

# ============================================================================ #
# Consistência climatológica #
# =========================================================================== #

library(dplyr)

painel_calor <- readRDS(here::here("data", "processed", "clima", "indicadores_calor_anual_2010_2025.rds"))

# Média nacional dos indicadores por ano
resumo_anual <- painel_calor %>%
  group_by(ano) %>%
  summarise(
    media_ondas_ano    = round(mean(n_ondas_ano), 1),
    dias_em_onda_media = round(mean(dias_em_onda_ano), 1),
    tmax_media_nac     = round(mean(tmax_extrema_ano), 1),
    noites_trop_media  = round(mean(noites_tropicais), 1)
  )

print(resumo_anual, n = 16)

# ============================================================================ #
# Passo 3: Covariável térmica acumulada para o SaTScan (2010–2025)
# Estratificação em tercis (3 categorias de D_i) a partir dos dias sob onda
# ============================================================================ #
cat("\n===> Passo 3: Gerando covariável térmica acumulada para o SaTScan...\n")

# Utiliza painel_calor (já lido na linha 231) ou faz fallback se necessário
df_acumulado <- (if (exists("painel_calor_anual")) painel_calor_anual else painel_calor) %>%
  group_by(ID_MN_RESI) %>%
  summarise(
    dias_onda_total = sum(dias_em_onda_ano, na.rm = TRUE),
    n_ondas_total   = sum(n_ondas_ano, na.rm = TRUE),
    tmax_media_16a  = mean(tmax_extrema_ano, na.rm = TRUE),
    .groups = "drop"
  )

# Estratificação em 3 tercis de igual frequência (1 = Baixa, 2 = Média, 3 = Alta)
df_covar_satscan <- df_acumulado %>%
  mutate(
    COVAR_TERMICA = as.integer(ntile(dias_onda_total, 3)),
    ID_MN_RESI    = as.character(ID_MN_RESI)
  ) %>%
  select(ID_MN_RESI, COVAR_TERMICA, dias_onda_total)

stopifnot(nrow(df_covar_satscan) == 5564L)
stopifnot(!any(is.na(df_covar_satscan$COVAR_TERMICA)))

arq_covar <- file.path(dir_proc, "onda_calor_municipal_2010_2025.rds")
saveRDS(df_covar_satscan, arq_covar)

cat(sprintf("Arquivo de covariável térmica salvo com sucesso: %s\n", arq_covar))

# Resumo dos estratos para conferência
print(df_covar_satscan %>%
        group_by(COVAR_TERMICA) %>%
        summarise(
          n_municipios = n(),
          min_dias     = min(dias_onda_total),
          mediana_dias = median(dias_onda_total),
          max_dias     = max(dias_onda_total),
          .groups = "drop"
        ))
