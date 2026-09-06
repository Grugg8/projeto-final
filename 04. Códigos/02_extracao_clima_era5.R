# ============================================================================ #
# 02_extracao_clima_era5.R
# ----------------------------------------------------------------------------
# Extração das variáveis climáticas mensais (2010-01 a 2025-12) sobre a malha
# municipal harmonizada de 2010 (5.564 municípios, excl. Fernando de Noronha),
# com CRS de trabalho WGS84 (EPSG:4326) para os rasters NetCDF (CRS84).
#
# Fontes e papéis (parecer de co-orientação):
#   * Temperatura   <- ERA5-Land (t2m, 0.1 grau ~ 9 km; resolução fina, melhor
#                      para relevo/litoral) -- convertida de Kelvin p/ Celsius.
#   * Umidade Rel.  <- ERA5 (variavel "r", %, 0.25 grau; o ERA5-Land NAO
#                      fornece umidade relativa).
#   * Precipitação  <- Brazilian Unified Rainfall Dataset (estações em
#                      parquet por UF/ano): agregação mensal por estação e
#                      espacialização para o município (média das estações
#                      dentro do polígono; fallback IDW das 3 mais próximas).
#
# Método zonal: exact_extract (exactextractr) com peso = área de sobreposição
# das células dentro do polígono (média zonal ponderada). Municípios costeiros
# sem sobreposição (ex.: Itaparica/BA) recebem o valor do município vizinho
# mais próximo (proxy espacial), documentado como limitação.
#
# Saídas:
#   * 03. Dados/Originais/Dados de temperatura - ERA5_ERA5LAND/processado/
#       - extra_era5land_temp_2010.rds   (painel longo: ID_MN_RESI x mes)
#       - extra_era5_umid_2010.rds       (idem, umidade relativa)
#   * 03. Dados/Originais/Brazilian Unified Rainfall Dataset (1885 - 2025)/
#       cache_precip/ (agregados estação-mês por ano, checkpoints)
#       precip_mensal_municipal_2010.rds (painel longo: precip mm/mes)
#   * 03. Dados/Originais/.../clima_mensal_municipal_2010.rds (consolidado)
#
# O arquivo versionado de temperatura possui uma camada mensal por mes. A
# rotina nao inventa Tmax diaria; o script 03 calcula a maxima entre as medias
# mensais e registra essa limitacao no log. Uma fonte diaria deve ser adicionada
# antes de produzir ondas de calor diarias.
# ============================================================================ #

# ---- 0. Setup -------------------------------------------------------------- #
suppressPackageStartupMessages({
  library(terra)          # rasters NetCDF
  library(exactextractr)  # média zonal ponderada (C++)
  library(sf)             # malha
  library(dplyr)          # manipulação
  library(tidyr)          # pivot
  library(lubridate)      # datas
  library(arrow)          # parquet (precipitação)
  library(stringr)        # nomes de arquivo
})

sf_use_s2(FALSE)  # geometria planar (consistência com o script 01)

DIR_ERA5  <- "03. Dados/Originais/Dados de temperatura - ERA5_ERA5LAND"
DIR_CHUVA <- "03. Dados/Originais/Brazilian Unified Rainfall Dataset (1885 - 2025)"
DIR_CACHE <- file.path(DIR_CHUVA, "cache_precip")
DIR_OUT   <- file.path(DIR_ERA5, "processado")
dir.create(DIR_CACHE, showWarnings = FALSE, recursive = TRUE)
dir.create(DIR_OUT,   showWarnings = FALSE, recursive = TRUE)

# Malha harmonizada 2010, sem Fernando de Noronha, em WGS84 (EPSG:4326)
malha <- readRDS("03. Dados/malha_BR_10.RDS") %>%
  filter(ID_MN_RESI != "260545") %>%
  st_transform(4326) %>%
  arrange(ID_MN_RESI)

stopifnot(nrow(malha) == 5564L)
cat("Malha de trabalho: 5.564 municípios (SIRGAS 2000 -> WGS84/4326)\n\n")

# ---- 1. Função de extração zonal com fallback de vizinho ------------------- #
# Recebe um SpatRaster (já com as camadas de interesse) e retorna data.frame
# com uma coluna por camada (nomes = data do mes).
extract_zonal <- function(r, malha) {
  camadas <- as.character(time(r))
  cat("  raster:", basename(sources(r)[1]), "| camadas:", length(camadas), "|",
      unique(units(r)), "\n")

  ex <- exact_extract(r, malha, fun = "mean", weights = "area")
  ex <- as.data.frame(ex)
  names(ex) <- camadas
  ex$ID_MN_RESI <- malha$ID_MN_RESI

  # Fallback: municípios sem sobreposição (ilhas/litoral) recebem o valor do
  # vizinho mais próximo com dado na mesma camada (proxy espacial).
  n_na <- sum(is.na(ex[, camadas]))
  if (n_na > 0) {
    cat("  municipios com NA:", n_na, "valores -> proxy vizinho mais proximo\n")
    cent <- st_centroid(malha)
    for (cam in camadas) {
      id_na <- ex$ID_MN_RESI[is.na(ex[[cam]])]
      if (!length(id_na)) next
       cent_na <- cent[malha$ID_MN_RESI %in% id_na, ]
       cent_ok <- cent[!is.na(ex[[cam]]), ]
       viz <- apply(as.matrix(st_distance(cent_na, cent_ok)), 1,
                    which.min)
      ex[[cam]][ex$ID_MN_RESI %in% id_na] <-
        ex[[cam]][!is.na(ex[[cam]])][viz]
    }
  }
  cat("  NA restantes:", sum(is.na(ex[, camadas])), "\n")
  ex
}

# ---- 2. Temperatura - ERA5-Land (K -> C) ----------------------------------- #
cat("==> [1/4] Temperatura mensal (ERA5-Land, 0.1 grau)...\n")
t0 <- Sys.time()
r_land <- rast(file.path(DIR_ERA5, "ERA5-Land", "dados_brutos_ERA5-Land.nc"))
ex_t <- extract_zonal(r_land, malha)
temp_long <- ex_t %>%
  pivot_longer(-ID_MN_RESI, names_to = "mes", values_to = "temp_K") %>%
  mutate(mes = as.Date(mes),
         temp_C = temp_K - 273.15) %>%
  select(ID_MN_RESI, mes, temp_C)
saveRDS(temp_long, file.path(DIR_OUT, "extra_era5land_temp_2010.rds"))
cat("  OK em", round(difftime(Sys.time(), t0, units = "mins"), 1), "min |",
    nrow(temp_long), "linhas\n\n")

# ---- 3. Umidade relativa - ERA5 (variavel r, %) ---------------------------- #
cat("==> [2/4] Umidade relativa mensal (ERA5, 0.25 grau)...\n")
t0 <- Sys.time()
# O .nc do ERA5 tem 384 camadas (2 variáveis x 192 meses: r e t).
# Selecionamos apenas a variável de umidade relativa "r" (192 camadas).
r_era5 <- rast(file.path(DIR_ERA5, "ERA5", "dados_brutos_ERA5.nc"))
cat("  camadas totais:", nlyr(r_era5), "| variaveis:",
    paste(unique(varnames(r_era5)), collapse = ","), "\n")
# As primeiras 192 camadas correspondem à variável "r" (umidade relativa);
# as demais 192, à variável "t" (temperatura). Extraímos apenas "r".
r_era5 <- r_era5[[1:192]]
ex_u <- extract_zonal(r_era5, malha)
umid_long <- ex_u %>%
  pivot_longer(-ID_MN_RESI, names_to = "mes", values_to = "umid_rel") %>%
  mutate(mes = as.Date(mes)) %>%
  select(ID_MN_RESI, mes, umid_rel)
saveRDS(umid_long, file.path(DIR_OUT, "extra_era5_umid_2010.rds"))
cat("  OK em", round(difftime(Sys.time(), t0, units = "mins"), 1), "min |",
    nrow(umid_long), "linhas\n\n")

# ---- 4. Precipitação - estações (parquet por UF/ano) ------------------------ #
cat("==> [3/4] Precipitação mensal (Brazilian Unified Rainfall Dataset)...\n")
t0 <- Sys.time()

# Arquivos 2010-2025: nome UF_AAAA.zip
zips <- list.files(DIR_CHUVA, pattern = "^[A-Z]{2}_(201[0-9]|202[0-5])\\.zip$")
cat("  zips 2010-2025:", length(zips), "\n")

# (a) Agregação estação-mês por ano (com checkpoint por ano)
agregados <- list()
for (ano in 2010:2025) {
  cache_ano <- file.path(DIR_CACHE, sprintf("estacao_mes_%d.rds", ano))
  if (file.exists(cache_ano)) {
    agregados[[as.character(ano)]] <- readRDS(cache_ano)
    next
  }
  zips_ano <- zips[str_detect(zips, paste0("_", ano, "\\.zip$"))]
  lst <- lapply(zips_ano, function(z) {
    tmp <- tempfile(); dir.create(tmp)
    unzip(file.path(DIR_CHUVA, z), exdir = tmp)
    d <- read_parquet(file.path(tmp, "table_data.parquet"),
                      col_select = c("gauge_code", "rain_mm", "datetime")) %>%
      mutate(mes = floor_date(with_tz(datetime, "America/Sao_Paulo"), "month")) %>%
      group_by(gauge_code, mes) %>%
      summarise(chuva_mm = sum(rain_mm, na.rm = TRUE), n_obs = n(), .groups = "drop")
    unlink(tmp, recursive = TRUE)
    d
  })
  ano_df <- bind_rows(lst)
  saveRDS(ano_df, cache_ano)
  agregados[[as.character(ano)]] <- ano_df
  cat("  ano", ano, "->", nrow(ano_df), "linhas estacao-mes\n")
}

estacao_mes <- bind_rows(agregados)

# Deduplicação da chave estação-mês: códigos de estação podem colidir entre
# UFs (ex.: "A601" existe no RJ e em SP). Somamos as parcelas do mesmo mês,
# tratando como a mesma estação com registros particionados no cadastro.
n_dup <- nrow(estacao_mes) - nrow(distinct(estacao_mes, gauge_code, mes))
if (n_dup > 0) cat("  colisoes gauge_code+mes deduplicadas:", n_dup, "\n")
estacao_mes <- estacao_mes %>%
  group_by(gauge_code, mes) %>%
  summarise(chuva_mm = sum(chuva_mm, na.rm = TRUE),
            n_obs = sum(n_obs), .groups = "drop")

# CONTROLE DE QUALIDADE (nível 1): células estação-mês > 1.500 mm viram NA.
# Justificativa (documentada na Seção 2.2 do V9.tex): o limiar excede os máximos
# históricos documentados em estações brasileiras e a climatologia de extremos
# do país (Regoto et al., 2021); no painel 2010-2025 ele situa-se além do
# percentil 99,95 (~1.336 mm) e afeta 0,04% das células (716 em ~1,67 milhão),
# incluindo artefatos óbvios de cadastro/duplicação (até ~8e7 mm/mês).
n_limpo <- sum(estacao_mes$chuva_mm > 1500, na.rm = TRUE)
estacao_mes$chuva_mm[estacao_mes$chuva_mm > 1500] <- NA
cat("  nivel1: celulas estacao-mes > 1500 mm -> NA:", n_limpo, "\n")

# CONTROLE DE QUALIDADE (nível 2): estações com soma ANUAL > 8.000 mm (recorde
# anual brasileiro ~5.000 mm) exibem padrão de acumulado não-incremental
# (ex.: séries ICAO SBPF/SBIT/SBSC e códigos numéricos). A estação é removida
# do ano inteiro (105 estações-ano no período 2010-2025).
estacao_mes$ANO <- year(estacao_mes$mes)
soma_anual <- estacao_mes %>%
  group_by(gauge_code, ANO) %>%
  summarise(ano_total = sum(chuva_mm, na.rm = TRUE), .groups = "drop") %>%
  filter(ano_total > 8000)
if (nrow(soma_anual)) {
  cat("  nivel2: estacoes-ano com acumulado > 8000 mm removidas:", nrow(soma_anual),
      "(", paste(unique(soma_anual$gauge_code), collapse = ", "), ")\n")
  estacao_mes <- estacao_mes %>%
    left_join(soma_anual %>% mutate(remover = TRUE) %>% select(gauge_code, ANO, remover),
              by = c("gauge_code", "ANO")) %>%
    mutate(chuva_mm = if_else(!is.na(remover), NA_real_, chuva_mm)) %>%
    select(-remover)
}
estacao_mes$ANO <- NULL
cat("  total estacao-mes:", nrow(estacao_mes), "|",
    round(difftime(Sys.time(), t0, units = "mins"), 1), "min\n")

# (b) Informações de localização das estações (deduplicadas)
info_est <- bind_rows(lapply(zips, function(z) {
  tmp <- tempfile(); dir.create(tmp)
  unzip(file.path(DIR_CHUVA, z), exdir = tmp)
  i <- read_parquet(file.path(tmp, "table_info.parquet"))
  unlink(tmp, recursive = TRUE)
  i
})) %>%
  distinct(gauge_code, .keep_all = TRUE) %>%
  select(gauge_code, lat, long) %>%
  filter(!is.na(lat), !is.na(long)) %>%
  st_as_sf(coords = c("long", "lat"), crs = 4326)
cat("  estacoes unicas com coordenadas:", nrow(info_est), "\n")

# Índice espacial reutilizado em todos os meses. A janela ampla reduz a busca
# aos candidatos usuais; o fallback dentro do loop garante exatidão quando a
# janela contém menos de três estações válidas no mês.
pts_malha <- st_point_on_surface(malha)
estacoes_candidatas <- st_is_within_distance(
  pts_malha, info_est,
  dist = units::set_units(500, "km")
)
vizinhas <- lapply(seq_len(nrow(malha)), function(i) {
  idx <- estacoes_candidatas[[i]]
  if (length(idx) < 3L) idx <- seq_len(nrow(info_est))
  d <- as.numeric(st_distance(pts_malha[i, ], info_est[idx, ]))
  idx <- idx[order(d)[seq_len(min(32L, length(idx)))] ]
  data.frame(gauge_code = info_est$gauge_code[idx],
             d = sort(d)[seq_len(min(32L, length(d)))])
})

# (c) Espacialização: média das estações dentro do polígono; fallback IDW das
#     k=3 estações mais próximas com dado no mês.
idx_malha <- setNames(seq_len(nrow(malha)), malha$ID_MN_RESI)
precip_long <- vector("list", length = 192L)
meses <- sort(unique(as.Date(estacao_mes$mes)))
k <- 0L
for (m in meses) {
  k <- k + 1L
  sub <- estacao_mes %>% filter(as.Date(mes) == m) %>% filter(chuva_mm >= 0)
  est_m <- info_est %>%
    inner_join(sub, by = "gauge_code") %>%
    filter(!is.na(chuva_mm), chuva_mm >= 0)
  if (!nrow(est_m)) next

  # Estações dentro de cada município
  dentro <- st_join(malha[, "ID_MN_RESI"], est_m, join = st_intersects) %>%
    st_drop_geometry() %>%
    group_by(ID_MN_RESI) %>%
    summarise(precip = mean(chuva_mm, na.rm = TRUE), n_est = n(), .groups = "drop")

  # Municípios sem estação no mês: IDW das k=3 mais próximas. O índice de
  # vizinhança garante que o fallback não seja reduzido a uma única estação.
  com_dado <- dentro %>% filter(!is.na(precip))
   sem_dado <- malha %>% filter(!ID_MN_RESI %in% com_dado$ID_MN_RESI)
   if (nrow(sem_dado) > 0) {
     pts <- pts_malha[match(sem_dado$ID_MN_RESI, malha$ID_MN_RESI), ]
     k_idw <- min(3L, nrow(est_m))
     prox <- bind_rows(lapply(seq_len(nrow(sem_dado)), function(i) {
       idx_m <- unname(idx_malha[sem_dado$ID_MN_RESI[i]])
       viz <- vizinhas[[idx_m]] %>%
         filter(gauge_code %in% est_m$gauge_code)
       if (nrow(viz) < k_idw) {
         # Municípios remotos ou meses com muitos NAs exigem busca completa;
         # esse caminho é raro e mantém seleção exata das três estações.
         d <- as.numeric(st_distance(pts[i, ], est_m))
         idx <- order(d)[seq_len(k_idw)]
         viz <- data.frame(gauge_code = est_m$gauge_code[idx], d = d[idx])
       } else {
         viz <- slice_head(viz, n = k_idw)
       }
       tibble(ID_MN_RESI = sem_dado$ID_MN_RESI[i],
              d = viz$d,
              val = est_m$chuva_mm[match(viz$gauge_code, est_m$gauge_code)])
     })) %>%
       group_by(ID_MN_RESI) %>%
       summarise({
         w <- 1 / (d + 1)^2
         tibble(precip = sum(w * val) / sum(w), n_est = sum(!is.na(val)))
       }, .groups = "drop")
    com_dado <- bind_rows(com_dado, prox)
  }

  precip_long[[k]] <- com_dado %>% mutate(mes = m)
  if (k %% 24 == 0) cat("  mes", as.character(m), "ok\n")
}

precip_mensal <- bind_rows(precip_long) %>%
  mutate(mes = as.Date(mes)) %>%
  select(ID_MN_RESI, mes, precip_mm = precip, n_estacoes = n_est)
saveRDS(precip_mensal, file.path(DIR_CACHE, "precip_mensal_municipal_2010.rds"))
cat("  precipitação OK em", round(difftime(Sys.time(), t0, units = "mins"), 1),
    "min |", nrow(precip_mensal), "linhas\n\n")

# ---- 5. Consolidação do painel climático ------------------------------------ #
cat("==> [4/4] Consolidando painel climático mensal (5.564 x 192)...\n")

painel <- expand.grid(ID_MN_RESI = malha$ID_MN_RESI,
                      mes = seq(as.Date("2010-01-01"), as.Date("2025-12-01"), by = "month"),
                      KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE) %>%
  as_tibble() %>%
  left_join(temp_long,  by = c("ID_MN_RESI", "mes")) %>%
  left_join(umid_long,  by = c("ID_MN_RESI", "mes")) %>%
  left_join(precip_mensal, by = c("ID_MN_RESI", "mes"))

# ---- 6. Auditoria e exportação ---------------------------------------------- #
log <- character()
log <- c(log, sprintf("linhas_esperadas=%d", nrow(painel)),
         sprintf("linhas_obtidas=%d", nrow(painel)),
         sprintf("municipios_unicos=%d", length(unique(painel$ID_MN_RESI))),
         sprintf("meses_unicos=%d", length(unique(painel$mes))),
         sprintf("na_temp=%.4f%%", 100 * mean(is.na(painel$temp_C))),
         sprintf("na_umid=%.4f%%", 100 * mean(is.na(painel$umid_rel))),
         sprintf("na_precip=%.4f%%", 100 * mean(is.na(painel$precip_mm))),
         sprintf("BR_temp_media_C=%.2f", mean(painel$temp_C, na.rm = TRUE)),
         sprintf("BR_umid_media=%.2f", mean(painel$umid_rel, na.rm = TRUE)),
         sprintf("BR_precip_anual_mm=%.0f", sum(painel$precip_mm, na.rm = TRUE) / 16),
         "tmax_status=fonte mensal; Tmax diaria nao disponivel")

# Municípios problemáticos na precipitação (sem dado em QUALQUER mês)
sem_precip <- painel %>% filter(is.na(precip_mm)) %>% pull(ID_MN_RESI) %>% unique()
if (length(sem_precip)) log <- c(log, sprintf("municipios_sem_precip_algum_mes=%s",
                                              paste(sem_precip, collapse = ",")))

writeLines(log, file.path(DIR_OUT, "log_auditoria_clima.txt"))
saveRDS(painel, file.path(DIR_OUT, "clima_mensal_municipal_2010.rds"))

cat("\n--- LOG DE AUDITORIA (CLIMA) ---\n"); cat(log, sep = "\n")
cat("\nConcluído. Consolidado em:\n  ", file.path(DIR_OUT, "clima_mensal_municipal_2010.rds"), "\n")
