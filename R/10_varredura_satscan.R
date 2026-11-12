# ============================================================================ #
# 10_varredura_satscan.R  (varredura espacial oficial - SaTScan v10.3.2)
# ----------------------------------------------------------------------------
# Executa a Estatística de Varredura Espacial (Kulldorff, 1997) EXCLUSIVAMENTE
# sobre `data/processed/dataset_tcc_consolidado.rds` (painel consolidado do TCC), no
# ÚNICO desenho metodológico vigente (configuração do orientador):
#
#   * Casos:      total de casos prováveis acumulados no período por município
#   * População:  população média residente do período (base sob risco)
#   * Modelo:     Poisson discreto, varredura puramente espacial, janela
#                 circular, teto duplo (AND) de 16% da população sob risco E
#                 200 km de raio (UseDistanceFromCenterOption=y,
#                 MaxSpatialSizeInDistanceFromCenter=200; CoordinatesType=1,
#                 logo a distância é em km); hierárquicos y; SEM Gini
#                 (ReportGiniClusters=n; rodada única em 16%).
#   * Hierárquicos/secundários: p < 0,05, sem sobreposição geográfica
#                 (CriteriaForReportingSecondaryClusters = NoGeoOverlap),
#                 filtro direto sobre a rodada única.
#   * Inferência: B = 999 réplicas de Monte Carlo, semente 12345
#                 (parâmetro RandomizationSeed do SaTScan + set.seed no R),
#                 com PValueReportType=0 (modo padrão do SaTScan).
#
# O desenho alternativo com otimização pelo Coeficiente de Gini (teto de 15%,
# sem limite em km) NÃO é mais executado por esta rotina; seus artefatos
# históricos ficam preservados em `output/{figures,tables,models,macros,logs}/_legado/` e em
# `data/processed/_legado/` e não são sobrescritos.
#
# PERÍODO (env SATSCAN_PERIODO, default "completo"):
#   * completo: casos 2010-2025 (16 anos); datas do .prm 2010/01/01-2025/12/31.
#   * sem2024:  casos 2010-2023 e 2025 (15 anos; 2024 EXCLUÍDO da rotina).
#               As datas do .prm são rotuladas 2011/01/01-2025/12/31 apenas
#               para que a anualização interna do SaTScan (casos por 100 mil
#               ao ano) use a janela de 15 anos compatível com a agregação;
#               a varredura é puramente espacial e não usa as datas.
#   O sufixo de artefatos é "" (completo) ou "_sem2024".
#
# Modelos (env SATSCAN_AJUSTE_TERMICO): nao (puro) | sim (COVAR_TERMICA, calor)
#   | comp5 (COVAR_COMP5, padronização pelo máximo de 5 componentes, rotina
#   06 v4) | esgoto (COVAR_ESGOTO) | densurb (COVAR_DENSURB) |
#   propurb (COVAR_PROPURB) | agua (COVAR_AGUA) | lixo (COVAR_LIXO).
#   As individuais são lidas de
#   data/processed/mapbiomas/covar_individuais_2010_2025.rds (rotina 07
#   v4, tercis 1=melhor a 3=pior); comp5 vem de covar_composta_2010_2025.rds
#   (rotina 06 v4). O binário legado COVAR_COMPOSTA saiu desta rotina.
#   Observação: a padronização indireta é invariante a permutação de rótulos
#   de estrato, portanto a inversão 1=melhor/3=pior não altera os resultados
#   numéricos do SaTScan; os artefatos são regerados para manter consistência.
#
# WMAPE (qualidade do ajuste por covariável, in-sample):
#   Para cada rodada, o arquivo .rr do SaTScan traz OBSERVED e EXPECTED por
#   município sob a padronização indireta daquela covariável. Calcula-se
#   WMAPE = 100 * soma|O_i - E_i| / soma O_i (denominador nacional comum),
#   robusto a municípios com zero casos. O valor é um diagnóstico descritivo
#   in-sample da proximidade entre esperado padronizado e observado; NÃO é
#   validação preditiva. Verificações: soma(E) == soma(O) e, por zona
#   significativa, soma municipal de E confere com o E_Z reportado no .sci.
#
# SAÍDAS por rodada (sufixo por modelo _puro,_termica,_comp5,_esgoto,_densurb,
#   _propurb,_agua,_lixo + sufixo de período _sem2024 quando aplicável):
#   output/models/satscan/satscan_<modelo>[_sem2024].{cas,pop,
#       geo,prm,txt,col.dbf,sci.dbf,gis.dbf,rr.dbf}
#   output/models/resultado_satscan_<modelo>[_sem2024].rds (objeto rsatscan)
#   output/models/params/satscan_params[_sem2024].prm   (cópia de auditoria do cenário)
#   output/models/params/satscan_params_<modelo>[_sem2024].prm (cópia por rodada)
#   output/tables/tabela_clusters_satscan_<modelo>[_sem2024].tex
#   output/figures/fig_mapa_clusters_satscan_<modelo>[_sem2024].png
#   output/figures/fig_mapa_clusters_todos_uniforme_<modelo>[_sem2024].png
#   output/figures/fig_mapa_clusters_todos_uniforme_comparacao_<modelo>[_sem2024].png
#   output/figures/fig_mapa_rr_satscan_<modelo>[_sem2024].png
#   output/macros/macros_satscan_<modelo>[_sem2024].tex
#   output/logs/log_auditoria_satscan_<modelo>[_sem2024].txt
#   output/tables/wmape_municipal_satscan_<modelo>[_sem2024].tsv
#   output/tables/wmape_nacional_satscan_<modelo>[_sem2024].tsv
#   output/tables/comparacao_clusters_puro_<modelo>[_sem2024].tsv (modelos ajust.)
# ============================================================================ #

suppressPackageStartupMessages({
  library(dplyr); library(readr); library(sf)
  library(ggplot2); library(scales); library(ggspatial)
  library(colorspace)
  library(rsatscan)
})
sf_use_s2(FALSE)

# ---- Tipografia (SEM showtext) --------------------------------------------- #
# O showtext reescala os glifos ao rasterizar em alta resolução (bug de DPI:
# texto proporcionalmente menor nos PNGs de 600 dpi). Desativado aqui; usa-se
# a fonte serifada nativa do device (cairo/png), com tamanhos reais em pontos.
# O pacote showtext precisa estar CARREGADO para que a DLL do cairo seja
# encontrada pelo device cairo_pdf no R macOS (sem ele, o ggsave PDF falha
# silenciosamente). O reescalonamento de texto e DESATIVADO (showtext_auto
# FALSE) para manter tamanhos reais em pontos nos PNGs de 600 dpi.
if (requireNamespace("showtext", quietly = TRUE)) {
  library(showtext)
  showtext::showtext_auto(FALSE)
}
FAMILIA_FONTE <- "serif"
theme_set(theme_classic(base_size = 14, base_family = FAMILIA_FONTE))

# Tema cartografico padrao calibrado (canvas 7,0 x 6,2 in @ 600 dpi)
TEMA_CARTO <- theme_void(base_size = 11, base_family = "serif") +
  theme(
    legend.position   = "right",
    legend.title      = element_text(size = 11, face = "bold", family = "serif", lineheight = 1.15),
    legend.text       = element_text(size = 9.5, family = "serif"),
    legend.key.width  = unit(0.38, "cm"),
    legend.key.height = unit(0.30, "cm"),
    legend.spacing.y  = unit(0.04, "cm"),
    legend.margin     = margin(0, 0, 0, 0.1, "cm"),
    plot.margin       = margin(0.05, 0.05, 0.05, 0.05, "cm")
  )

GUIDE_BAR_COMPACTO <- guide_colorbar(
  barwidth        = unit(0.32, "cm"),
  barheight       = unit(2.8, "cm"),
  title.position  = "top",
  title.hjust     = 0,
  frame.colour    = "grey30",
  frame.linewidth = 0.25,
  ticks.colour    = "grey30"
)
GUIDE_BAR_RR <- GUIDE_BAR_COMPACTO


here::i_am("R/10_varredura_satscan.R")
DIR_FIGURAS <- here::here("output", "figures")
DIR_TABELAS <- here::here("output", "tables")
DIR_MACROS <- here::here("output", "macros")
DIR_LOGS <- here::here("output", "logs")
DIR_MODELOS <- here::here("output", "models")
DIR_PARAMS <- here::here("output", "models", "params")
for (diretorio in c(DIR_FIGURAS, DIR_TABELAS, DIR_MACROS, DIR_LOGS, DIR_MODELOS, DIR_PARAMS))
  dir.create(diretorio, showWarnings = FALSE, recursive = TRUE)
set.seed(12345)          # reprodutibilidade das etapas em R
SEMENTE_MC  <- 12345     # RandomizationSeed do SaTScan (Monte Carlo)
B_REPS      <- 999       # réplicas de Monte Carlo
JANELA_POP  <- 16        # % máxima da população na janela (config. orientador)
RAIO_MAX_KM <- 200       # teto adicional em km (AND com os 16%)
ARQ_DIR     <- file.path(DIR_MODELOS, "satscan")
dir.create(ARQ_DIR, showWarnings = FALSE, recursive = TRUE)
ARQ_CALOR   <- here::here("data", "processed", "clima", "onda_calor_municipal_2010_2025.rds")
ARQ_COMP    <- here::here("data", "processed", "mapbiomas", "covar_composta_2010_2025.rds")
ARQ_INDIV   <- here::here("data", "processed", "mapbiomas", "covar_individuais_2010_2025.rds")
AJUSTE_ENV  <- tolower(Sys.getenv("SATSCAN_AJUSTE_TERMICO", ""))
if (!AJUSTE_ENV %in% c("sim", "true", "1", "yes", "nao", "false", "0", "no",
                       "comp5", "esgoto", "densurb", "propurb",
                       "agua", "lixo")) {
  stop("Defina SATSCAN_AJUSTE_TERMICO=nao, sim, comp5, esgoto, densurb, propurb, agua ou lixo.")
}
PERIODO_ENV <- tolower(Sys.getenv("SATSCAN_PERIODO", "completo"))
if (!PERIODO_ENV %in% c("completo", "sem2024")) {
  stop("Defina SATSCAN_PERIODO=completo ou sem2024.")
}
SEM_2024 <- PERIODO_ENV == "sem2024"
ANOS_PERIODO <- if (SEM_2024) c(2010:2023, 2025L) else 2010:2025
# Datas do .prm: no cenário sem 2024, a janela de rótulo (2011-2025) garante a
# anualização interna de 15 anos compatível com a agregação; puramente espacial.
DATA_INI <- if (SEM_2024) "2011/01/01" else "2010/01/01"
DATA_FIM <- "2025/12/31"
AJUSTE_TERMICO  <- AJUSTE_ENV %in% c("sim", "true", "1", "yes")
AJUSTE_COMP5    <- AJUSTE_ENV == "comp5"
AJUSTE_ESGOTO   <- AJUSTE_ENV == "esgoto"
AJUSTE_DENSURB  <- AJUSTE_ENV == "densurb"
AJUSTE_PROPURB  <- AJUSTE_ENV == "propurb"
AJUSTE_AGUA     <- AJUSTE_ENV == "agua"
AJUSTE_LIXO     <- AJUSTE_ENV == "lixo"
COV_NOME <- if (AJUSTE_COMP5) "COVAR_COMP5" else
  if (AJUSTE_TERMICO) "COVAR_TERMICA" else
  if (AJUSTE_ESGOTO) "COVAR_ESGOTO" else if (AJUSTE_DENSURB) "COVAR_DENSURB" else
  if (AJUSTE_PROPURB) "COVAR_PROPURB" else if (AJUSTE_AGUA) "COVAR_AGUA" else
  if (AJUSTE_LIXO) "COVAR_LIXO" else NA_character_
COV_ARQ <- if (AJUSTE_COMP5) ARQ_COMP else if (AJUSTE_TERMICO) ARQ_CALOR else
  if (!is.na(COV_NOME)) ARQ_INDIV else NA_character_
if (!is.na(COV_NOME) && !file.exists(COV_ARQ)) {
  stop("SATSCAN_AJUSTE_TERMICO=", AJUSTE_ENV, " foi solicitado, mas o arquivo de covariavel nao existe: ", COV_ARQ)
}
SUFIXO_MODELO <- if (AJUSTE_COMP5) "_comp5" else
  if (AJUSTE_TERMICO) "_termica" else
  if (AJUSTE_ESGOTO) "_esgoto" else if (AJUSTE_DENSURB) "_densurb" else
  if (AJUSTE_PROPURB) "_propurb" else if (AJUSTE_AGUA) "_agua" else
  if (AJUSTE_LIXO) "_lixo" else "_puro"
SUFIXO_PERIODO <- if (SEM_2024) "_sem2024" else ""
SUFIXO <- paste0(SUFIXO_MODELO, SUFIXO_PERIODO)
RES_RDS <- if (AJUSTE_COMP5) file.path(DIR_MODELOS, paste0("resultado_satscan_comp5", SUFIXO_PERIODO, ".rds")) else
  if (AJUSTE_TERMICO) file.path(DIR_MODELOS, paste0("resultado_satscan_termica", SUFIXO_PERIODO, ".rds")) else
  if (AJUSTE_ESGOTO) file.path(DIR_MODELOS, paste0("resultado_satscan_esgoto", SUFIXO_PERIODO, ".rds")) else
  if (AJUSTE_DENSURB) file.path(DIR_MODELOS, paste0("resultado_satscan_densurb", SUFIXO_PERIODO, ".rds")) else
  if (AJUSTE_PROPURB) file.path(DIR_MODELOS, paste0("resultado_satscan_propurb", SUFIXO_PERIODO, ".rds")) else
  if (AJUSTE_AGUA) file.path(DIR_MODELOS, paste0("resultado_satscan_agua", SUFIXO_PERIODO, ".rds")) else
  if (AJUSTE_LIXO) file.path(DIR_MODELOS, paste0("resultado_satscan_lixo", SUFIXO_PERIODO, ".rds")) else
  file.path(DIR_MODELOS, paste0("resultado_satscan_acum", SUFIXO_PERIODO, ".rds"))
RES_PURO <- file.path(DIR_MODELOS, paste0("resultado_satscan_acum", SUFIXO_PERIODO, ".rds"))
STUB_BASE <- if (AJUSTE_COMP5) "satscan_comp5" else
  if (AJUSTE_TERMICO) "satscan_termica" else
  if (AJUSTE_ESGOTO) "satscan_esgoto" else if (AJUSTE_DENSURB) "satscan_densurb" else
  if (AJUSTE_PROPURB) "satscan_propurb" else if (AJUSTE_AGUA) "satscan_agua" else
  if (AJUSTE_LIXO) "satscan_lixo" else "satscan_puro"
STUB <- paste0(STUB_BASE, SUFIXO_PERIODO)
cat(sprintf("  modelo=%s | periodo=%s | stub=%s | rds=%s\n",
            SUFIXO_MODELO, PERIODO_ENV, STUB, RES_RDS))
SATSCAN_EXE <- file.path(Sys.getenv("HOME"), "bin")   # dir com SaTScanBatch


# Wrapper do ggsave: remove o destino antes de gravar (evita "write failed"
# no dev.off() ao sobrescrever artefatos parcialmente escritos no macOS).
ggsave <- function(filename, ...) {
  if (file.exists(filename)) unlink(filename)
  ggplot2::ggsave(filename, ...)
}
fmt_br <- function(x, d = 1) formatC(x, format = "f", digits = d,
                                     big.mark = ".", decimal.mark = ",")
# Converte nomes em CAIXA ALTA para Nome Próprio ("UNIÃO DE MINAS" ->
# "União de Minas"), preservando conectivos em minúsculas.
titular <- function(s) {
  conect <- c("de", "da", "do", "das", "dos", "e", "em", "d'")
  vapply(s, function(x) {
    palavras <- strsplit(tolower(x), " ")[[1]]
    out <- vapply(palavras, function(w) {
      if (w %in% conect) return(w)
      paste0(toupper(substr(w, 1, 1)), substr(w, 2, nchar(w)))
    }, character(1))
    paste(out, collapse = " ")
  }, character(1), USE.NAMES = FALSE)
}
# Quebras intermediarias harmonicas: exclui candidatos a menos de 15% dos
# extremos e reduz o miolo a no maximo n_inter marcas regularmente espacadas,
# produzindo de 4 a 5 marcacoes bem distribuidas por escala continua.
calc_breaks_harmonicos <- function(val_min, val_max, n_inter = 3, dec = 1) {
  delta <- val_max - val_min
  candidatos <- pretty(c(val_min, val_max), n = 8)
  miolo <- candidatos[candidatos > (val_min + 0.15 * delta) &
                        candidatos < (val_max - 0.15 * delta)]
  if (length(miolo) > n_inter) {
    idx <- unique(round(seq(1, length(miolo), length.out = n_inter)))
    miolo <- miolo[idx]
  }
  sort(unique(c(val_min, miolo, val_max)))
}
# Nome das UF (a malha só traz CD_UF)
UF_NOME <- c("11"="Rondônia","12"="Acre","13"="Amazonas","14"="Roraima",
             "15"="Pará","16"="Amapá","17"="Tocantins","21"="Maranhão",
             "22"="Piauí","23"="Ceará","24"="Rio Grande do Norte",
             "25"="Paraíba","26"="Pernambuco","27"="Alagoas","28"="Sergipe",
             "29"="Bahia","31"="Minas Gerais","32"="Espírito Santo",
             "33"="Rio de Janeiro","35"="São Paulo","41"="Paraná",
             "42"="Santa Catarina","43"="Rio Grande do Sul","50"="Mato Grosso do Sul",
             "51"="Mato Grosso","52"="Goiás","53"="Distrito Federal")

# ============================================================================ #
# 1. Preparação dos arquivos de entrada (.cas / .pop / .geo) ------------------
# ============================================================================ #
cat("==> [1/5] Preparando arquivos de entrada a partir do painel consolidado...\n")

dataset <- readRDS(here::here("data", "processed", "dataset_tcc_consolidado.rds"))
malha   <- readRDS(here::here("data", "raw", "malhas", "malha_BR_10.RDS"))
malha   <- malha %>% filter(ID_MN_RESI != "260545") %>% arrange(ID_MN_RESI)

stopifnot(identical(sort(unique(dataset$ID_MN_RESI)), malha$ID_MN_RESI))

dataset_periodo <- dataset %>% filter(ANO_EPI %in% ANOS_PERIODO)
stopifnot(nrow(dataset_periodo) == 5564L * length(ANOS_PERIODO))

# Casos prováveis acumulados no período e população média dos anos do período
mun <- dataset_periodo %>%
  group_by(ID_MN_RESI) %>%
  summarise(CASOS = sum(CASOS_PROV), POP = mean(POP), .groups = "drop")

# A covariavel so e ativada quando a rotina validada gerar o resumo. O
# painel mensal nao pode ser usado como substituto de Tmax diaria.
# Modelo comp5 usa COVAR_COMP5 da rotina 06; os modelos esgoto/densurb/
# propurb/agua/lixo usam as covariáveis individuais da 07.
COVARIADAS_ATIVAS <- !is.na(COV_NOME)
cov_temp <- NULL
if (COVARIADAS_ATIVAS) {
  cov_temp <- readRDS(COV_ARQ) %>%
    select(ID_MN_RESI, all_of(COV_NOME)) %>%
    mutate(across(all_of(COV_NOME), as.integer))
  stopifnot(nrow(cov_temp) == nrow(mun))
  mun <- mun %>% left_join(cov_temp, by = "ID_MN_RESI")
  stopifnot(!any(is.na(mun[[COV_NOME]])),
            identical(mun$ID_MN_RESI, sort(unique(dataset$ID_MN_RESI))))
}

# Centróides municipais (malha harmonizada 2010, SIRGAS 2000/EPSG:4674)
cgeom <- st_centroid(st_geometry(malha)) %>% st_coordinates() %>% as.data.frame()
colnames(cgeom) <- c("LONG", "LAT")

# Formato SaTScan: uma linha por local; ano = 2025 representa o periodo agregado.
cas_input <- data.frame(ID_MN_RESI = mun$ID_MN_RESI, CASOS = mun$CASOS,
                        ANO = 2025)
if (COVARIADAS_ATIVAS) cas_input[[COV_NOME]] <- mun[[COV_NOME]]
write.table(cas_input,
            file.path(ARQ_DIR, paste0(STUB, ".cas")),
            row.names = FALSE, col.names = FALSE, sep = " ")
pop_input <- data.frame(ID = mun$ID_MN_RESI, ANO = 2025,
                        POP = round(mun$POP))
if (COVARIADAS_ATIVAS) pop_input[[COV_NOME]] <- mun[[COV_NOME]]
write.table(pop_input,
            file.path(ARQ_DIR, paste0(STUB, ".pop")),
            row.names = FALSE, col.names = FALSE, sep = " ")
write.table(data.frame(ID = mun$ID_MN_RESI, LAT = cgeom$LAT, LONG = cgeom$LONG),
            file.path(ARQ_DIR, paste0(STUB, ".geo")),
            row.names = FALSE, col.names = FALSE, sep = " ")

cat(sprintf("  locais: %d | anos: %d | casos totais: %s | população média: %s\n",
            nrow(mun), length(ANOS_PERIODO), format(sum(mun$CASOS), big.mark = "."),
            format(round(sum(mun$POP)), big.mark = ".")))

# ============================================================================ #
# 2. Parâmetros (.prm) — desenho único do orientador --------------------------
# ============================================================================ #
cat("==> [2/5] Configurando parâmetros (.prm)...\n")

ss.options(reset = TRUE)
ss.options(list(
  CaseFile = paste0(STUB, ".cas"),
  PopulationFile = paste0(STUB, ".pop"),
  CoordinatesFile = paste0(STUB, ".geo"),
  ResultsFile = paste0(STUB, ".txt"),
  StartDate = DATA_INI,
  EndDate = DATA_FIM,
  PrecisionCaseTimes = 1,
  AnalysisType = 1,                 # Purely Spatial
  ModelType = 0,                    # Discrete Poisson
  ScanAreas = 1,                    # high rates
  MaxSpatialSizeInPopulationAtRisk = JANELA_POP,   # teto: 16% da população
  UseDistanceFromCenterOption = "y",               # teto adicional em km (AND)
  MaxSpatialSizeInDistanceFromCenter = RAIO_MAX_KM, # 200 km (CoordinatesType=1)
  SpatialWindowShapeType = 0,       # Circular
  MonteCarloReps = B_REPS,
  PValueReportType = 0,             # Default do SaTScan
  CriteriaForReportingSecondaryClusters = 0,       # NoGeoOverlap
  ReportHierarchicalClusters = "y", # saída hierárquica ligada (orientador)
  MinimumCasesInHighRateClusters = 2,
  OutputShapefiles = "n", OutputGoogleEarthKML = "n", OutputGoogleMaps = "n",
  CensusAreasReportedClustersDBase = "y",
  IncludeRelativeRisksCensusAreasDBase = "y",
  # --- Sem otimização pelo Coeficiente de Gini (rodada única em 16%) ---
  ReportGiniClusters = "n"          # sem coleção ótima de Gini
))
ss.options.extra(list(RandomizationSeed = SEMENTE_MC), section = "Inference")

# Grava o .prm (versão de auditoria) e confirma o conteúdo
rsatscan:::write.ss.prm(ARQ_DIR, STUB)
prm_path <- file.path(ARQ_DIR, paste0(STUB, ".prm"))
prm_linhas <- readLines(prm_path)
# O template padrão do rsatscan sempre grava as chaves do Gini; com
# ReportGiniClusters=n elas são ignoradas pelo SaTScan, mas a configuração do
# orientador exige ausência total: remove as 4 linhas residuais.
prm_linhas <- prm_linhas[!grepl(
  "^(GiniIndexClusterReportingType|GiniIndexClustersPValueCutOff|ReportGiniIndexCoefficents|SpatialMaxima)=",
  prm_linhas)]
writeLines(prm_linhas, prm_path)
file.copy(prm_path, file.path(DIR_PARAMS, paste0("satscan_params", SUFIXO_PERIODO, ".prm")), overwrite = TRUE)
prm_md5 <- tools::md5sum(prm_path)

chave <- function(p) prm_linhas[grepl(paste0("^", p, "="), prm_linhas)]
cat("  ", chave("StartDate"), "|", chave("EndDate"), "\n")
cat("  ", chave("AnalysisType"), "\n")
cat("  ", chave("ModelType"), "\n")
cat("  ", chave("MaxSpatialSizeInPopulationAtRisk"), "\n")
cat("  ", chave("UseDistanceFromCenterOption"), "\n")
cat("  ", chave("MaxSpatialSizeInDistanceFromCenter"), "\n")
cat("  ", chave("ReportHierarchicalClusters"), "\n")
cat("  ", chave("ReportGiniClusters"), "\n")
cat("  ", chave("MonteCarloReps"), "\n")
cat("  ", chave("PValueReportType"), "\n")
cat("  ", chave("CriteriaForReportingSecondaryClusters"), "\n")
cat("  ", chave("RandomizationSeed"), "\n")

# ============================================================================ #
# 3. Execução (com checkpoint validado por hash do .prm E dos arquivos de     #
#    entrada .cas/.pop/.geo: o checkpoint só é reutilizado se os parâmetros   #
#    e os DADOS de entrada não mudaram) -------------------------------------
# ============================================================================ #
entrada_md5 <- unname(tools::md5sum(file.path(ARQ_DIR, paste0(STUB, c(".cas", ".pop", ".geo")))))
chk_ok <- function(res_old) {
  identical(attr(res_old, "prm_md5"), unname(prm_md5)) &&
  identical(attr(res_old, "entrada_md5"), entrada_md5)
}
reutilizar <- FALSE
if (file.exists(RES_RDS)) {
  res_old <- readRDS(RES_RDS)
  if (chk_ok(res_old)) {
    reutilizar <- TRUE
  } else {
    cat("==> [3/5] Checkpoint inválido (parâmetros ou dados de entrada alterados); rerun\n")
  }
}
if (reutilizar) {
  cat("==> [3/5] Checkpoint: resultado existente reutilizado (hash .prm e entradas confere)\n")
  res <- res_old
} else {
  cat("==> [3/5] Executando SaTScan (B =", B_REPS, "réplicas, semente",
      SEMENTE_MC, ", teto", JANELA_POP, "% da população +", RAIO_MAX_KM,
      "km, hierárquicos, sem Gini, periodo", PERIODO_ENV, ")...\n")
  t0 <- Sys.time()
  res <- satscan(ARQ_DIR, STUB, sslocation = SATSCAN_EXE,
                 cleanup = FALSE, verbose = FALSE)
  cat(sprintf("  scan concluído em %.1f min\n",
              as.numeric(difftime(Sys.time(), t0, units = "mins"))))

  # Verificação de execução: o arquivo .txt do próprio stub precisa ter sido
  # regravado nesta rodada. Sem isso, o pacote pode reaproveitar um .txt antigo
  # (cleanup = FALSE) e o checkpoint gravaria um resultado velho com hash novo.
  txt_run <- file.path(ARQ_DIR, paste0(STUB, ".txt"))
  if (!file.exists(txt_run) || file.info(txt_run)$mtime < t0) {
    stop("SaTScan não regravou ", txt_run, " nesta execução; resultado inválido.")
  }

  attr(res, "prm_md5") <- unname(prm_md5)
  attr(res, "entrada_md5") <- entrada_md5
  saveRDS(res, RES_RDS)
}

cat("--- Resumo do run (main) ---\n")
cat(paste(utils::head(res$main, 22), collapse = "\n"), "\n")

# ============================================================================ #
# 3.1 Verificação: seção 'Gini Indexes' deve estar ausente ---------------------
# ============================================================================ #
cat("--- Verificação: seção 'Gini Indexes' deve estar ausente ---\n")
if (any(grepl("^Gini Indexes", res$main))) {
  cat(paste(grep("Gini", res$main, value = TRUE), collapse = "\n"), "\n")
} else {
  cat("  OK: seção 'Gini Indexes' ausente (sem Gini).")
  eco_gini <- grep("Gini", res$main, value = TRUE)
  if (length(eco_gini)) cat(sprintf(" Eco de parâmetro esperado: '%s'.\n", trimws(eco_gini[1])))
  else cat("\n")
}

# ============================================================================ #
# 4. Extração dos clusters (filtro direto p <= 0,05 sobre a rodada única) -----
# ============================================================================ #
cat("==> [4/5] Extraindo clusters (p<=0,05, rodada única 16%+200km) e gerando artefatos...\n")

# Cópia do PRM
file.copy(prm_path, file.path(DIR_PARAMS, paste0("satscan_params", SUFIXO, ".prm")), overwrite = TRUE)

sci <- res$sci %>% filter(CLUSTER > 0)
col <- res$col %>% filter(CLUSTER > 0)
gis <- res$gis %>% filter(CLUSTER > 0)

# Sem Gini: todos os clusters reportados entram no filtro direto p <= 0,05
# (p do SaTScan = (rank+1)/(B+1))
clusters <- sci %>%
  left_join(col %>% select(CLUSTER, RADIUS, NUMBER_LOC, P_VALUE, LLR),
            by = "CLUSTER") %>%
  filter(P_VALUE <= 0.05) %>%
  arrange(CLUSTER)

# ---- 4.0 Checagem de sobreposição ------------------------------------------ #
# Com ReportHierarchicalClusters=y (orientador), o .col pode trazer clusters
# aninhados. O join de membros por município (memb via .gis) assume disjunção;
# se houver município em >1 cluster significativo, a regra de plot precisa de
# ajuste (ex.: só nível superior).
sobreposicao_n <- gis %>%
  filter(CLUSTER %in% clusters$CLUSTER) %>%
  count(LOC_ID, name = "n_cl") %>%
  filter(n_cl > 1) %>%
  nrow()
sobreposicao_txt <- if (sobreposicao_n == 0) {
  "disjuntos (NoGeoOverlap confirmado; join direto por município válido)"
} else {
  sprintf("%d municípios em >1 cluster significativo: SOBREPOSIÇÃO DETECTADA", sobreposicao_n)
}
cat(sprintf("  sobreposição hierárquica: %s\n", sobreposicao_txt))

# Município polo = centróide da janela (primeiro LOC_ID do cluster no .col)
polos <- col %>%
  group_by(CLUSTER) %>%
  slice(1) %>%
  select(CLUSTER, LOC_ID) %>%
  left_join(malha %>% st_drop_geometry() %>% select(ID_MN_RESI, NM_MUN, CD_UF),
            by = c("LOC_ID" = "ID_MN_RESI")) %>%
  mutate(NM_UF = UF_NOME[CD_UF])

clusters <- clusters %>%
  left_join(polos, by = "CLUSTER") %>%
  mutate(PVAL_TXT = ifelse(P_VALUE < 0.001,
                           sprintf("< 0,001"),
                           sprintf("= %s", fmt_br(P_VALUE, 3))))

# Participação relativa do primário (população e casos do país). A população
# do arquivo .pop é a média do período arredondada por município; usar a mesma
# convenção evita divergência de poucas pessoas entre macro e eco do SaTScan.
N_CASOS <- sum(mun$CASOS); N_POP <- sum(round(mun$POP))
prim <- clusters %>% slice(1)
pct_pop_prim <- 100 * prim$POPULATION / N_POP
pct_casos_prim <- 100 * prim$OBSERVED / N_CASOS

# Cobertura agregada dos clusters significativos (sem sobreposição geográfica)
cob_mun  <- sum(clusters$NUMBER_LOC)
cob_cas  <- sum(clusters$OBSERVED)
cob_esp  <- sum(clusters$EXPECTED)
cob_pop  <- sum(clusters$POPULATION)
# Maior RR da coleção (polo e volume de casos para a redação)
max_rr <- clusters %>% slice(which.max(REL_RISK))

cat(sprintf("  clusters significativos (p<0,05, rodada única): %d\n", nrow(clusters)))
print(clusters %>%
        select(CLUSTER, NM_MUN, NUMBER_LOC, RADIUS, OBSERVED, EXPECTED,
               REL_RISK, P_VALUE))

# ============================================================================ #
# 4.0b WMAPE nacional por covariável (diagnóstico in-sample) ------------------
#   WMAPE = 100 * soma|O_i - E_i| / soma O_i, com O_i e E_i municipais do
#   arquivo .rr do SaTScan (padronização indireta específica da covariável).
#   Verificações: soma(E) == soma(O) e, por zona significativa, soma municipal
#   de E confere com o E_Z do .sci. Artefatos: TSV municipal (auditoria) e
#   TSV nacional (uma linha por rodada, para consolidação em 11).
# ============================================================================ #
rr <- res$rr
stopifnot(nrow(rr) == nrow(mun), !anyNA(rr$OBSERVED), !anyNA(rr$EXPECTED),
          all(rr$EXPECTED > 0), sum(rr$OBSERVED) > 0)

obs_mun <- rr$OBSERVED[match(mun$ID_MN_RESI, rr$LOC_ID)]
if (anyNA(obs_mun)) stop("Municípios do painel sem correspondência no arquivo .rr.")
# O observado do .rr deve reproduzir os casos do painel para cada município.
if (!isTRUE(all.equal(as.numeric(obs_mun), as.numeric(mun$CASOS), tolerance = 1e-9))) {
  stop(sprintf("Observado do .rr diverge do painel (desvio máximo %.4f).",
               max(abs(obs_mun - mun$CASOS))))
}

soma_obs <- sum(rr$OBSERVED); soma_esp <- sum(rr$EXPECTED)
dif_total <- abs(soma_esp - soma_obs)
if (dif_total > max(0.05, 1e-9 * soma_obs)) {
  stop(sprintf("soma(E) %.2f difere de soma(O) %.0f além da tolerância.", soma_esp, soma_obs))
}

# Conferência por zona significativa: soma municipal de E == E_Z do .sci
desvios_zona <- vapply(seq_len(nrow(clusters)), function(i) {
  ids <- gis %>% filter(CLUSTER == clusters$CLUSTER[i]) %>% pull(LOC_ID)
  sum(rr$EXPECTED[match(ids, rr$LOC_ID)]) - clusters$EXPECTED[i]
}, numeric(1))
desvio_zona_max <- max(abs(desvios_zona))
if (desvio_zona_max > 0.05) {
  stop(sprintf("Esperado municipal não confere com o E_Z das zonas (desvio máximo %.3f).",
               desvio_zona_max))
}

wmape_pct <- 100 * sum(abs(rr$OBSERVED - rr$EXPECTED)) / soma_obs

tab_wmape <- data.frame(
  ID_MN_RESI = as.character(rr$LOC_ID),
  NM_MUN = malha$NM_MUN[match(rr$LOC_ID, malha$ID_MN_RESI)],
  CD_UF = malha$CD_UF[match(rr$LOC_ID, malha$ID_MN_RESI)],
  OBSERVADO = rr$OBSERVED,
  ESPERADO = rr$EXPECTED,
  ERRO_ABS = abs(rr$OBSERVED - rr$EXPECTED),
  RESIDUO = rr$OBSERVED - rr$EXPECTED)
tab_wmape <- tab_wmape %>% arrange(ID_MN_RESI)
write_tsv(tab_wmape, file.path(DIR_TABELAS, paste0("wmape_municipal_", STUB, ".tsv")))

tab_nac <- data.frame(
  modelo = sub("^_", "", SUFIXO_MODELO),
  periodo = PERIODO_ENV,
  anos = paste0(min(ANOS_PERIODO), "-", max(ANOS_PERIODO), if (SEM_2024) " sem 2024" else ""),
  stub = STUB,
  n_municipios = nrow(tab_wmape),
  soma_observado = soma_obs,
  soma_esperado = soma_esp,
  soma_erro_abs = sum(tab_wmape$ERRO_ABS),
  wmape_pct = wmape_pct,
  n_zonas_sig = nrow(clusters),
  prim_polo = if (nrow(clusters)) titular(enc2utf8(clusters$NM_MUN[1])) else NA_character_,
  prim_uf = if (nrow(clusters)) clusters$NM_UF[1] else NA_character_,
  prim_rr = if (nrow(clusters)) clusters$REL_RISK[1] else NA_real_,
  checagem_soma_total = sprintf("ok (dif %.6f)", dif_total),
  checagem_zonas = sprintf("ok (%d zonas; desvio máx %.4f)", nrow(clusters), desvio_zona_max),
  stringsAsFactors = FALSE)
write_tsv(tab_nac, file.path(DIR_TABELAS, paste0("wmape_nacional_", STUB, ".tsv")))

cat(sprintf("  WMAPE (%s, %s): %.4f%% | soma_erro_abs=%.0f | soma_obs=%.0f\n",
            SUFIXO_MODELO, PERIODO_ENV, wmape_pct, sum(tab_wmape$ERRO_ABS), soma_obs))
cat(sprintf("  checagens: soma(E)-soma(O)=%.6f | desvio máx por zona=%.4f\n",
            dif_total, desvio_zona_max))

# ============================================================================ #
# 4.1 Tabela LaTeX (kableExtra, longtable, font_size 9) ---------------------- #
# N clusters significativos não cabem em uma única página: longtable com
# cabeçalho repetido e largura ajustada ao texto (full_width), em vez do
# scale_down de página única (que comprimiria a fonte para ~6pt).
# A coluna de valor-p foi REMOVIDA: todos os clusters listados já foram
# filtrados por P_VALUE <= 0,05 (rodada única; ver Seção 4). Municípios-
# polos sao usados apenas no texto narrativo e no log.
tbl <- data.frame(
  Cluster = clusters$CLUSTER,
  Municipios = clusters$NUMBER_LOC,
  Raio_km = fmt_br(clusters$RADIUS, 1),
  Casos_obs = fmt_br(clusters$OBSERVED, 0),
  Casos_esp = fmt_br(clusters$EXPECTED, 0),
  RR = fmt_br(clusters$REL_RISK, 2),
  stringsAsFactors = FALSE
)

# Descrição do ajuste para as rótulas (evita títulos idênticos entre modelos)
MODELO_TXT <- if (AJUSTE_COMP5) "sob padronização indireta pelo índice socioambiental composto" else
  if (AJUSTE_TERMICO) "sob padronização indireta pelos tercis de dias em onda de calor" else
  if (AJUSTE_ESGOTO) "sob padronização indireta pelos tercis de esgotamento adequado" else
  if (AJUSTE_DENSURB) "sob padronização indireta pelos tercis de densidade urbana" else
  if (AJUSTE_PROPURB) "sob padronização indireta pelos tercis de proporção urbana" else
  if (AJUSTE_AGUA) "sob padronização indireta pelos tercis de abastecimento de água por rede" else
  if (AJUSTE_LIXO) "sob padronização indireta pelos tercis de coleta de lixo" else
  "sem ajuste por covariáveis"

cap_tab <- paste0(
  "\\textit{Clusters} espaciais significativos de dengue detectados pela ",
  "varredura espacial ", MODELO_TXT, ", Brasil, 2010--2025",
  if (SEM_2024) " (2024 excluído)" else "", ".")

k <- kableExtra::kable(tbl, format = "latex", booktabs = TRUE, longtable = TRUE,
  escape = FALSE, caption = cap_tab, label = paste0("clusters_satscan", SUFIXO),
  col.names = c("\\textit{Cluster}", "Qtd. municípios",
                "Raio (km)", "Casos obs. ($C_Z$)", "Casos esp. ($E_Z$)",
                "Risco relativo ($RR_Z$)"),
  align = c("c", "c", "c", "c", "c", "c"))
k <- kableExtra::kable_styling(k, latex_options = c("repeat_header"),
                               font_size = 9, full_width = TRUE,
                               repeat_header_text = "\\textit{(continuação)}",
                               repeat_header_continued = "\\textit{(continuação)}")
write_lines(as.character(k), file.path(DIR_TABELAS, paste0("tabela_clusters_satscan", SUFIXO, ".tex")))
cat("  salvo: tabela_clusters_satscan.tex (longtable, font 9)\n")

# ---- 4.2 Mapas (PNG 600 dpi) ------------------------------------------------ #
malha_plot <- malha %>% st_transform(5880)
# A malha municipal não é topologicamente limpa: a dissolução por UF deixa
# anéis internos microscópicos (fissuras) entre municípios vizinhos, que
# imprimem como "pontinhos pretos". O helper mantém apenas o anel exterior de
# cada polígono dissolvido, removendo esses buracos de origem topológica.
sem_buracos <- function(g) {
  polys <- st_cast(st_sfc(g), "POLYGON", warn = FALSE)
  st_multipolygon(lapply(polys, function(p) list(p[[1]])))
}
estados <- malha_plot %>% group_by(CD_UF) %>%
  summarise(geometry = st_union(geometry), .groups = "drop")
estados$geometry <- st_sfc(lapply(estados$geometry, sem_buracos), crs = st_crs(estados))

# Mapa de clusters: municípios pertencentes a cada cluster significativo
memb <- gis %>%
  filter(CLUSTER %in% clusters$CLUSTER) %>%
  select(LOC_ID, CLUSTER)

# Estratificação da legenda: os Top 8 clusters de maior relevância (maior
# verossimilhança) são destacados individualmente; os demais entram
# na categoria agregada "demais" (p < 0,05) com cor neutra.
TOP8 <- 1:8
ids_ord <- sort(unique(memb$CLUSTER))
top8 <- ids_ord[ids_ord %in% TOP8]

# Siglas das UF para o log de auditoria (não entram mais na legenda)
UF_SIGLA <- c("11"="RO","12"="AC","13"="AM","14"="RR","15"="PA","16"="AP",
              "17"="TO","21"="MA","22"="PI","23"="CE","24"="RN","25"="PB",
              "26"="PE","27"="AL","28"="SE","29"="BA","31"="MG","32"="ES",
              "33"="RJ","35"="SP","41"="PR","42"="SC","43"="RS","50"="MS",
              "51"="MT","52"="GO","53"="DF")
# Legenda simplificada em plotmath (itálico): rótulos "Cluster 1..8" para a
# hierarquia dos Top 8; categorias agregadas "demais"/"sem" com itálico parcial.
map_cl <- malha_plot %>%
  left_join(memb, by = c("ID_MN_RESI" = "LOC_ID")) %>%
  mutate(LABEL = case_when(
    is.na(CLUSTER) ~ "sem",
    CLUSTER %in% top8 ~ as.character(CLUSTER),
    TRUE ~ "demais"
  ))
niveis <- c(as.character(top8), "demais", "sem")
map_cl$LABEL <- factor(map_cl$LABEL, levels = niveis)

# Paleta: cores contrastantes "Dark 3" (colorspace) para os Top 8; coral
# #F1605D para os demais clusters; cinza claro #E0E0E0 para
# municípios sem cluster
pal_cl <- c(setNames(colorspace::qualitative_hcl(length(top8), "Dark 3"),
                     as.character(top8)),
            "demais" = "#F1605D",
            "sem" = "#E0E0E0")

p1 <- ggplot(map_cl) +
  geom_sf(aes(fill = LABEL), colour = "grey40", linewidth = 0.03) +
  geom_sf(data = estados, fill = NA, colour = "grey25", linewidth = 0.25) +
  annotation_scale(location = "br", width_hint = 0.20,
                   text_col = "grey25", bar_cols = c("grey30", "grey80"),
                   height = unit(0.20, "cm"), text_cex = 0.75, text_family = "serif",
                   pad_x = unit(0.2, "cm"), pad_y = unit(0.2, "cm")) +
  annotation_north_arrow(location = "tr", which_north = "true",
                         style = north_arrow_fancy_orienteering,
                         height = unit(0.9, "cm"), width = unit(0.9, "cm"),
                         pad_x = unit(0.2, "cm"), pad_y = unit(0.2, "cm")) +
  scale_fill_manual(
    values = pal_cl,
    name = expression(bolditalic("Cluster")),
    drop = FALSE,
    labels = c(
      "1" = expression(italic("Cluster")~1),
      "2" = expression(italic("Cluster")~2),
      "3" = expression(italic("Cluster")~3),
      "4" = expression(italic("Cluster")~4),
      "5" = expression(italic("Cluster")~5),
      "6" = expression(italic("Cluster")~6),
      "7" = expression(italic("Cluster")~7),
      "8" = expression(italic("Cluster")~8),
      "demais" = expression(Demais~italic("clusters")~(p < 0.05)),
      "sem"    = expression(Sem~italic("cluster"))
    ),
    guide = guide_legend(keyheight = unit(0.30, "cm"),
                         keywidth  = unit(0.40, "cm"))
  ) +
  TEMA_CARTO

ggsave(file.path(DIR_FIGURAS, paste0("fig_mapa_clusters_satscan", SUFIXO, ".png")), p1,
       width = 7.0, height = 6.2, dpi = 600, bg = "white")
cat(sprintf("  salvo: fig_mapa_clusters_satscan.png (Top %d + demais clusters)\n",
            length(top8)))

# Mapa de risco relativo municipal estimado pela varredura (.rr)
# Escala epidemiológica: municípios com RR <= 1,0 (risco nulo ou efeito
# protetivo) são plotados em BRANCO PURO (#FFFFFF via na.value), mantendo o
# contorno municipal visível; o gradiente contínuo inicia em amarelo/laranja
# suave (RR ~ 1,01) e evolui ate vermelho escuro/bordo no maximo da serie.
rr_mun <- res$rr %>%
  select(LOC_ID, REL_RISK) %>%
  left_join(malha_plot %>% select(ID_MN_RESI, geometry), by = c("LOC_ID" = "ID_MN_RESI")) %>%
  st_as_sf()

max_rr_serie <- max(rr_mun$REL_RISK, na.rm = TRUE)
n_protetivo <- sum(rr_mun$REL_RISK <= 1)
cat(sprintf("  RR municipal: %d municipios <= 1,0 (brancos); maximo da serie = %s\n",
            n_protetivo, fmt_br(max_rr_serie, 2)))
rr_mun$RR_RISCO <- ifelse(rr_mun$REL_RISK > 1, rr_mun$REL_RISK, NA_real_)

p2 <- ggplot(rr_mun) +
  geom_sf(aes(fill = RR_RISCO), colour = "grey80", linewidth = 0.03) +
  geom_sf(data = estados, fill = NA, colour = "grey25", linewidth = 0.35) +
  annotation_scale(location = "br", width_hint = 0.20,
                   text_col = "grey25", bar_cols = c("grey30", "grey80"),
                   height = unit(0.20, "cm"), text_cex = 0.75, text_family = "serif",
                   pad_x = unit(0.2, "cm"), pad_y = unit(0.2, "cm")) +
  annotation_north_arrow(location = "tr", which_north = "true",
                         style = north_arrow_fancy_orienteering,
                         height = unit(0.9, "cm"), width = unit(0.9, "cm"),
                         pad_x = unit(0.2, "cm"), pad_y = unit(0.2, "cm")) +
  scale_fill_gradientn(
    colours = viridisLite::magma(200, direction = -1),
    limits = c(1, max_rr_serie),
    breaks = calc_breaks_harmonicos(1, max_rr_serie, n_inter = 3),
    labels = function(x) fmt_br(x, 2),
    na.value = "#FFFFFF",
    name = "Risco relativo\n(RR > 1,0)",
    guide = GUIDE_BAR_RR) +
  TEMA_CARTO

ggsave(file.path(DIR_FIGURAS, paste0("fig_mapa_rr_satscan", SUFIXO, ".png")), p2,
       width = 7.0, height = 6.2, dpi = 600, bg = "white")
cat("  salvo: fig_mapa_rr_satscan.png (continuo acima de RR=1; branco p/ RR<=1)\n")

# Mapa complementar: TODOS os clusters significativos em cor
# única (coral #F1605D); municípios fora de cluster em
# cinza claro (#E0E0E0); contornos estaduais reforçados em cinza escuro.
map_uni <- malha_plot %>%
  left_join(memb, by = c("ID_MN_RESI" = "LOC_ID")) %>%
  mutate(CLUSTER_STATUS = if_else(is.na(CLUSTER), "Sem", "Cluster"))

p_uni <- ggplot(map_uni) +
  geom_sf(aes(fill = CLUSTER_STATUS), colour = "grey55", linewidth = 0.03) +
  geom_sf(data = estados, fill = NA, colour = "grey20", linewidth = 0.35) +
  annotation_scale(location = "br", width_hint = 0.20,
                   text_col = "grey25", bar_cols = c("grey30", "grey80"),
                   height = unit(0.20, "cm"), text_cex = 0.75, text_family = "serif",
                   pad_x = unit(0.2, "cm"), pad_y = unit(0.2, "cm")) +
  annotation_north_arrow(location = "tr", which_north = "true",
                         style = north_arrow_fancy_orienteering,
                         height = unit(0.9, "cm"), width = unit(0.9, "cm"),
                         pad_x = unit(0.2, "cm"), pad_y = unit(0.2, "cm")) +
  scale_fill_manual(
    values = c("Cluster" = "#F1605D", "Sem" = "#E0E0E0"),
    labels = c(
      "Cluster" = expression(italic("Cluster")~significativo~(p < 0.05)),
      "Sem"   = expression(Sem~italic("cluster"))
    ),
    name = NULL,
    guide = guide_legend(override.aes = list(colour = NA))
  ) +
  TEMA_CARTO

# Mapa uniforme SEM legenda lateral (padrão do projeto): a codificação de cor
# é explicada na rótula/nota do manuscrito e dos slides (laranja = município em
# zona significativa; cinza = fora de zonas). O arquivo "_comparacao" mantém o
# mesmo conteúdo, para os nomes já referenciados nos documentos .tex.
p_uni_sem_legenda <- p_uni + theme(legend.position = "none")
ggsave(file.path(DIR_FIGURAS, paste0("fig_mapa_clusters_todos_uniforme", SUFIXO, ".png")), p_uni_sem_legenda,
       width = 7.0, height = 6.2, dpi = 600, bg = "white")
cat(sprintf("  salvo: fig_mapa_clusters_todos_uniforme.png (%d clusters, cor unica #F1605D, sem legenda)\n",
            length(unique(memb$CLUSTER))))

# Cópia para o nome de prancha comparativa (mesmo conteúdo, sem legenda).
file.copy(file.path(DIR_FIGURAS, paste0("fig_mapa_clusters_todos_uniforme", SUFIXO, ".png")),
          file.path(DIR_FIGURAS, paste0("fig_mapa_clusters_todos_uniforme_comparacao", SUFIXO, ".png")),
          overwrite = TRUE)

# ---- 4.3 Macros ------------------------------------------------------------- #
macro <- c(
  "% Macros dinamicas geradas por 10_varredura_satscan.R - nao editar manualmente",
  sprintf("\\newcommand{\\ScanTotalCasos}{%s}", fmt_br(N_CASOS, 0)),
  sprintf("\\newcommand{\\ScanPopulacao}{%s}", fmt_br(round(N_POP), 0)),
  sprintf("\\newcommand{\\ScanNumMunicipios}{%s}", fmt_br(nrow(mun), 0)),
  sprintf("\\newcommand{\\ScanB}{%s}", B_REPS),
  sprintf("\\newcommand{\\ScanSemente}{%s}", SEMENTE_MC),
  sprintf("\\newcommand{\\ScanJanelaPop}{%s\\%%}", JANELA_POP),
  sprintf("\\newcommand{\\ScanRaioMaxKm}{%s}", RAIO_MAX_KM),
  sprintf("\\newcommand{\\ScanNumClusters}{%s}", fmt_br(nrow(clusters), 0)),
  sprintf("\\newcommand{\\ScanPrimID}{%s}", prim$CLUSTER),
  sprintf("\\newcommand{\\ScanPrimPolo}{%s}", titular(enc2utf8(prim$NM_MUN))),
  sprintf("\\newcommand{\\ScanPrimUF}{%s}", prim$NM_UF),
  sprintf("\\newcommand{\\ScanPrimMunicipios}{%s}", fmt_br(prim$NUMBER_LOC, 0)),
  sprintf("\\newcommand{\\ScanPrimRaioKm}{%s}", fmt_br(prim$RADIUS, 1)),
  sprintf("\\newcommand{\\ScanPrimCasosObs}{%s}", fmt_br(prim$OBSERVED, 0)),
  sprintf("\\newcommand{\\ScanPrimCasosEsp}{%s}", fmt_br(prim$EXPECTED, 0)),
  sprintf("\\newcommand{\\ScanPrimRR}{%s}", fmt_br(prim$REL_RISK, 2)),
  sprintf("\\newcommand{\\ScanPrimPValor}{%s}", prim$PVAL_TXT),
  sprintf("\\newcommand{\\ScanPrimLLR}{%s}", fmt_br(prim$LLR, 0)),
  sprintf("\\newcommand{\\ScanPrimPop}{%s}", fmt_br(round(prim$POPULATION), 0)),
  sprintf("\\newcommand{\\ScanPrimPopPct}{%s\\%%}", fmt_br(pct_pop_prim, 1)),
  sprintf("\\newcommand{\\ScanPrimCasosPct}{%s\\%%}", fmt_br(pct_casos_prim, 1)),
  sprintf("\\newcommand{\\ScanCobMunicipios}{%s}", fmt_br(cob_mun, 0)),
  sprintf("\\newcommand{\\ScanCobMunicipiosPct}{%s\\%%}", fmt_br(100*cob_mun/nrow(mun), 1)),
  sprintf("\\newcommand{\\ScanCobCasos}{%s}", fmt_br(cob_cas, 0)),
  sprintf("\\newcommand{\\ScanCobCasosPct}{%s\\%%}", fmt_br(100*cob_cas/N_CASOS, 1)),
  sprintf("\\newcommand{\\ScanCobCasosEsp}{%s}", fmt_br(cob_esp, 0)),
  sprintf("\\newcommand{\\ScanCobPop}{%s}", fmt_br(round(cob_pop), 0)),
  sprintf("\\newcommand{\\ScanCobPopPct}{%s\\%%}", fmt_br(100*cob_pop/N_POP, 1)),
  sprintf("\\newcommand{\\ScanMaxRR}{%s}", fmt_br(max_rr$REL_RISK, 2)),
  sprintf("\\newcommand{\\ScanMaxRRPolo}{%s}", titular(enc2utf8(max_rr$NM_MUN))),
  sprintf("\\newcommand{\\ScanMaxRRUF}{%s}", max_rr$NM_UF),
  sprintf("\\newcommand{\\ScanMaxRRCasos}{%s}", fmt_br(max_rr$OBSERVED, 0)),
  sprintf("\\newcommand{\\ScanMaxRRMun}{%s}", fmt_br(max_rr$NUMBER_LOC, 0)),
  sprintf("\\newcommand{\\ScanWmape}{%s}", fmt_br(wmape_pct, 1))
)
if (nrow(clusters) >= 2) {
  sec <- clusters %>% slice(2)
  macro <- c(macro,
    sprintf("\\newcommand{\\ScanSecID}{%s}", sec$CLUSTER),
    sprintf("\\newcommand{\\ScanSecPolo}{%s}", titular(enc2utf8(sec$NM_MUN))),
    sprintf("\\newcommand{\\ScanSecUF}{%s}", sec$NM_UF),
    sprintf("\\newcommand{\\ScanSecMunicipios}{%s}", fmt_br(sec$NUMBER_LOC, 0)),
    sprintf("\\newcommand{\\ScanSecRaioKm}{%s}", fmt_br(sec$RADIUS, 1)),
    sprintf("\\newcommand{\\ScanSecCasosObs}{%s}", fmt_br(sec$OBSERVED, 0)),
    sprintf("\\newcommand{\\ScanSecCasosEsp}{%s}", fmt_br(sec$EXPECTED, 0)),
    sprintf("\\newcommand{\\ScanSecRR}{%s}", fmt_br(sec$REL_RISK, 2)),
    sprintf("\\newcommand{\\ScanSecPValor}{%s}", sec$PVAL_TXT))
}
if (nrow(clusters) >= 3) {
  ter <- clusters %>% slice(3)
  macro <- c(macro,
    sprintf("\\newcommand{\\ScanTerID}{%s}", ter$CLUSTER),
    sprintf("\\newcommand{\\ScanTerPolo}{%s}", titular(enc2utf8(ter$NM_MUN))),
    sprintf("\\newcommand{\\ScanTerUF}{%s}", ter$NM_UF),
    sprintf("\\newcommand{\\ScanTerMunicipios}{%s}", fmt_br(ter$NUMBER_LOC, 0)),
    sprintf("\\newcommand{\\ScanTerRaioKm}{%s}", fmt_br(ter$RADIUS, 1)),
    sprintf("\\newcommand{\\ScanTerCasosObs}{%s}", fmt_br(ter$OBSERVED, 0)),
    sprintf("\\newcommand{\\ScanTerCasosEsp}{%s}", fmt_br(ter$EXPECTED, 0)),
    sprintf("\\newcommand{\\ScanTerRR}{%s}", fmt_br(ter$REL_RISK, 2)),
    sprintf("\\newcommand{\\ScanTerPValor}{%s}", ter$PVAL_TXT))
}
write_lines(macro, file.path(DIR_MACROS, paste0("macros_satscan", SUFIXO, ".tex")))
cat("  salvo: macros_satscan.tex\n")


# ---- 4.4 Log ----------------------------------------------------------------- #
log <- c(
  sprintf("satscan_versao=SaTScan v10.3.2 (rsatscan %s)", as.character(packageVersion("rsatscan"))),
  sprintf("satscan_base=dataset_tcc_consolidado.rds"),
  sprintf("satscan_periodo=%s (%d anos: %s)%s", PERIODO_ENV, length(ANOS_PERIODO),
          paste0(min(ANOS_PERIODO), "-", max(ANOS_PERIODO)),
          if (SEM_2024) " com 2024 EXCLUIDO" else ""),
  sprintf("satscan_datas_prm=%s a %s (%s)", DATA_INI, DATA_FIM,
          if (SEM_2024) "rotulo de 15 anos p/ anualizacao interna; varredura espacial" else "periodo completo"),
  sprintf("satscan_casos=total casos provaveis do periodo = %.0f", N_CASOS),
  sprintf("satscan_populacao=populacao media residente do periodo = %.0f", N_POP),
  sprintf("satscan_locais=%d", nrow(mun)),
  sprintf("satscan_modelo=Poisson discreto, puramente espacial, janela circular"),
  sprintf("satscan_janela=teto duplo (AND): %d%% da populacao sob risco + %d km de raio", JANELA_POP, RAIO_MAX_KM),
  sprintf("satscan_hierarquicos=ReportHierarchicalClusters=y; secundarios p<0.05, sem sobreposicao geografica (NoGeoOverlap)"),
  sprintf("satscan_gini=desativado (ReportGiniClusters=n; rodada unica)"),
  sprintf("satscan_desenho=orientador (unico desenho vigente; sem rodada Gini)"),
  sprintf("satscan_montecarlo=%d repeticoes, RandomizationSeed=%d", B_REPS, SEMENTE_MC),
  sprintf("satscan_sobreposicao=%s", sobreposicao_txt),
  sprintf("satscan_clusters_significativos=%d", nrow(clusters)),
  sprintf("satscan_wmape=%.4f%% (soma|O-E|=%.0f; soma O=%.0f; denominador nacional)", wmape_pct, sum(tab_wmape$ERRO_ABS), soma_obs),
  sprintf("satscan_wmape_verificacao=soma(E)-soma(O)=%.6f; desvio max por zona=%.4f (%d zonas)",
          dif_total, desvio_zona_max, nrow(clusters)),
  sprintf("satscan_esperado_municipal=wmape_municipal_%s.tsv (5.564 municipios)", STUB),
  sprintf("satscan_wmape_nacional=wmape_nacional_%s.tsv", STUB))
cov_status <- if (AJUSTE_COMP5)
  "satscan_covariadas=ativada (COVAR_COMP5: tercis do escore de padronizacao pelo maximo de 5 componentes; 1=melhor a 3=pior; rotina 02c v4-max)" else
  if (AJUSTE_TERMICO)
  "satscan_covariadas=ativada (COVAR_TERMICA: 3 categorias de D_i, maximo de quatro instantaneos diarios; 1=menos calor a 3=mais calor; rotina 02b)" else
  if (AJUSTE_ESGOTO)
  "satscan_covariadas=ativada (COVAR_ESGOTO: tercis de prop_esgoto_adequado; 1=melhor/maior a 3=pior/menor; rotina 07 v4)" else if (AJUSTE_DENSURB)
  "satscan_covariadas=ativada (COVAR_DENSURB: tercis de DENS_URB_MEDIA; 1=menor a 3=maior; rotina 07 v4)" else if (AJUSTE_PROPURB)
  "satscan_covariadas=ativada (COVAR_PROPURB: tercis de PROP_URB_MEDIA; 1=menor a 3=maior; rotina 07 v4)" else if (AJUSTE_AGUA)
  "satscan_covariadas=ativada (COVAR_AGUA: tercis de prop_agua_rede; 1=melhor/maior a 3=pior/menor; rotina 07 v4)" else if (AJUSTE_LIXO)
  "satscan_covariadas=ativada (COVAR_LIXO: tercis de prop_lixo_coletado; 1=melhor/maior a 3=pior/menor; rotina 07 v4)" else
  "satscan_covariadas=desativada (modelo puro)"
log <- c(log, cov_status)

# Quando um modelo ajustado esta ativo, compara com o checkpoint puro do MESMO
# período. Métricas: número de clusters, polo primário, RR, cobertura e
# sobreposição municipal (Jaccard e recuperação) — insumos para a leitura
# conjunta de WMAPE e preservação de clusters residuais.
extrai_sig <- function(x) {
  sci_x <- x$sci %>% filter(CLUSTER > 0)
  col_x <- x$col %>% filter(CLUSTER > 0)
  polos_x <- col_x %>%
    group_by(CLUSTER) %>% slice(1) %>%
    select(CLUSTER, LOC_ID) %>%
    left_join(malha %>% st_drop_geometry() %>% select(ID_MN_RESI, NM_MUN, CD_UF),
              by = c("LOC_ID" = "ID_MN_RESI")) %>%
    mutate(NM_UF = UF_NOME[CD_UF]) %>%
    ungroup()
  final_x <- sci_x %>%
    left_join(col_x %>% select(CLUSTER, P_VALUE, RADIUS, NUMBER_LOC),
              by = "CLUSTER") %>%
    filter(P_VALUE <= 0.05) %>%
    arrange(CLUSTER) %>%
    left_join(polos_x, by = "CLUSTER")
  list(final = final_x,
       membros = unique(x$gis$LOC_ID[x$gis$CLUSTER %in% final_x$CLUSTER]))
}
if (COVARIADAS_ATIVAS && file.exists(RES_PURO)) {
  cmp_modo <- if (AJUSTE_COMP5) "comp5" else
    if (AJUSTE_TERMICO) "termico" else
    if (AJUSTE_ESGOTO) "esgoto" else if (AJUSTE_DENSURB) "densurb" else
    if (AJUSTE_PROPURB) "propurb" else if (AJUSTE_AGUA) "agua" else "lixo"
  cmp_arq <- sprintf("comparacao_clusters_puro_%s%s.tsv", cmp_modo, SUFIXO_PERIODO)
  res_puro <- readRDS(RES_PURO)
  info_puro <- extrai_sig(res_puro)
  info_mod <- list(final = clusters, membros = unique(memb$LOC_ID))
  inter_pp <- length(intersect(info_puro$membros, info_mod$membros))
  jac_pp <- 100 * inter_pp / length(union(info_puro$membros, info_mod$membros))
  rec_pp <- 100 * inter_pp / length(info_puro$membros)
  linha_cmp <- function(info, rotulo, jac, rec, wmape) {
    f <- info$final
    data.frame(rotulo = rotulo,
      periodo = PERIODO_ENV,
      clusters = nrow(f),
      prim_polo = if (nrow(f)) titular(enc2utf8(f$NM_MUN[1])) else NA_character_,
      prim_uf = if (nrow(f)) f$NM_UF[1] else NA_character_,
      prim_municipios = f$NUMBER_LOC[1],
      prim_raio_km = f$RADIUS[1],
      prim_rr = f$REL_RISK[1],
      prim_p = f$P_VALUE[1],
      cob_municipios = sum(f$NUMBER_LOC),
      cob_casos = sum(f$OBSERVED),
      cob_casos_pct = 100 * sum(f$OBSERVED) / soma_obs,
      jaccard_vs_puro_pct = jac,
      recuperacao_vs_puro_pct = rec,
      wmape_pct = wmape,
      stringsAsFactors = FALSE)
  }
  wmape_puro <- 100 * sum(abs(res_puro$rr$OBSERVED - res_puro$rr$EXPECTED)) / sum(res_puro$rr$OBSERVED)
  cmp <- rbind(
    linha_cmp(info_puro, "puro", 100, 100, wmape_puro),
    linha_cmp(info_mod, cmp_modo, jac_pp, rec_pp, wmape_pct))
  write.table(cmp, file.path(DIR_TABELAS, cmp_arq),
              sep = "\t", quote = FALSE, row.names = FALSE, fileEncoding = "UTF-8")
  log <- c(log, sprintf("comparacao=arquivo %s", cmp_arq))
  log <- c(log, sprintf("comparacao_jaccard=%.1f%% | recuperacao=%.1f%% | wmape puro=%.4f%% | wmape modelo=%.4f%%",
                        jac_pp, rec_pp, wmape_puro, wmape_pct))
}
for (i in seq_len(nrow(clusters)))
  log <- c(log, sprintf(
    "satscan_cluster_%d=%s | polo=%s | municipios=%d | raio=%.1f km | C_Z=%.0f | E_Z=%.0f | RR=%.3f | p=%.6f",
    clusters$CLUSTER[i], clusters$CD_UF[i], clusters$NM_MUN[i],
    clusters$NUMBER_LOC[i], clusters$RADIUS[i], clusters$OBSERVED[i],
    clusters$EXPECTED[i], clusters$REL_RISK[i], clusters$P_VALUE[i]))
write_lines(log,   file.path(DIR_LOGS, paste0("log_auditoria_satscan", SUFIXO, ".txt")))
cat("\n--- LOG (SATSCAN) ---\n"); cat(log, sep = "\n")

cat("\nArtefatos em output/:\n")
print(sort(list.files(here::here("output"), recursive = TRUE, pattern = paste0("satscan|clusters|rr_satscan|^wmape_|^comparacao_"))))
