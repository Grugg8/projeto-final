# ============================================================================ #
# 02b_ondas_calor_era5land.R
# ----------------------------------------------------------------------------
# Extrai Tmax diaria ERA5-Land, estima P90 municipal e calcula a carga D_i de
# ondas de calor (>= 3 dias consecutivos com Tmax >= P90 local).
#
# A fonte diaria deve ser fornecida em TMAX_DIARIA_NC ou no caminho padrao abaixo.
# O NetCDF mensal versionado nao e aceito como substituto.
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

DIR_ERA5 <- "03. Dados/Originais/Dados de temperatura - ERA5_ERA5LAND"
DIR_OUT <- file.path(DIR_ERA5, "processado")
ARQ_TMAX <- Sys.getenv(
  "TMAX_DIARIA_NC",
  file.path(DIR_ERA5, "ERA5-Land", "dados_diarios_ERA5-Land.nc")
)
ARQ_DIA <- file.path(DIR_OUT, "tmax_diaria_municipal_2010_2025.rds")
ARQ_RES <- file.path(DIR_OUT, "onda_calor_municipal_2010_2025.rds")

if (!file.exists(ARQ_TMAX)) {
  stop(
    "Fonte diaria de Tmax ausente: ", ARQ_TMAX,
    ". Disponibilize um NetCDF ERA5-Land diario em TMAX_DIARIA_NC; ",
    "o arquivo mensal versionado nao pode ser usado para ondas de calor."
  )
}

malha <- readRDS("03. Dados/malha_BR_10.RDS") %>%
  filter(ID_MN_RESI != "260545") %>%
  st_transform(4326) %>%
  arrange(ID_MN_RESI)
stopifnot(nrow(malha) == 5564L)

r <- rast(ARQ_TMAX)
datas <- as.Date(time(r))
if (length(datas) != nlyr(r) || anyNA(datas)) {
  stop("NetCDF diario precisa expor uma data valida por camada.")
}

# Aceita camadas horarias ou subdiarias, agregando o maximo por data. Se a
# fonte ja for diaria, preserva as camadas sem reprocessamento desnecessario.
if (length(unique(datas)) < nlyr(r)) {
  r <- tapp(r, index = as.character(datas), fun = max, na.rm = TRUE)
  datas <- as.Date(unique(datas))
  time(r) <- datas
}

if (min(datas) > as.Date("2010-01-01") || max(datas) < as.Date("2025-12-31")) {
  stop("Fonte diaria nao cobre integralmente 2010-01-01 a 2025-12-31.")
}

vals <- exact_extract(r, malha, fun = "mean", weights = "area") %>%
  as.data.frame()
stopifnot(ncol(vals) == length(datas))
if (max(vals, na.rm = TRUE) > 200) vals <- vals - 273.15
names(vals) <- as.character(datas)

tmax_diaria <- vals %>%
  mutate(ID_MN_RESI = malha$ID_MN_RESI, .before = 1) %>%
  pivot_longer(-ID_MN_RESI, names_to = "data", values_to = "Tmax_C") %>%
  mutate(data = as.Date(data)) %>%
  filter(data >= as.Date("2010-01-01"), data <= as.Date("2025-12-31"))
saveRDS(tmax_diaria, ARQ_DIA)

# Conta dias pertencentes a episodios validos, sem ligar sequencias separadas
# por lacunas no calendario ou por dias abaixo do limiar.
conta_ondas <- function(data, extremo, duracao_min = 3L) {
  if (!length(data)) return(c(D_i = 0L, N_episodios = 0L))
  quebra <- c(TRUE, diff(data) != 1 | extremo[-1] != extremo[-length(extremo)])
  grupo <- cumsum(quebra)
  runs <- tibble(extremo = extremo, grupo = grupo) %>%
    group_by(grupo) %>%
    summarise(extremo = first(extremo), duracao = n(), .groups = "drop") %>%
    filter(extremo, duracao >= duracao_min)
  c(D_i = sum(runs$duracao), N_episodios = nrow(runs))
}

resumo <- tmax_diaria %>%
  group_by(ID_MN_RESI) %>%
  group_modify(~ {
    p90 <- as.numeric(quantile(.x$Tmax_C, probs = 0.90, na.rm = TRUE,
                               names = FALSE))
    carga <- conta_ondas(.x$data, .x$Tmax_C >= p90)
    tibble(P90_local_C = p90, D_i = as.integer(carga[["D_i"]]),
           N_episodios = as.integer(carga[["N_episodios"]]))
  }) %>%
  ungroup() %>%
  mutate(
    # Pontos de corte definidos antes da varredura: ate 1 ano, 1--3 anos,
    # acima de 3 anos de dias acumulados no periodo de 16 anos.
    CATEGORIA_TERMICA = cut(
      D_i, breaks = c(-Inf, 365, 1095, Inf),
      labels = c("Baixa", "Média", "Alta"), right = TRUE
    ),
    COVAR_TERMICA = as.integer(CATEGORIA_TERMICA)
  )

stopifnot(nrow(resumo) == nrow(malha), !anyNA(resumo$COVAR_TERMICA))
saveRDS(resumo, ARQ_RES)
writeLines(c(
  "definicao=Tmax >= P90 local por pelo menos 3 dias consecutivos",
  "periodo=2010-01-01 a 2025-12-31",
  "categorias=Baixa D_i<=365; Média 366-1095; Alta D_i>1095",
  sprintf("municipios=%d", nrow(resumo)),
  sprintf("dias_onda_total=%d", sum(resumo$D_i))
), file.path(DIR_OUT, "log_auditoria_ondas_calor.txt"))

cat("Ondas de calor calculadas em:", ARQ_RES, "\n")
