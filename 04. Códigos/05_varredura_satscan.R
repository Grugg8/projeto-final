# ============================================================================ #
# 05_varredura_satscan.R  (varredura espacial oficial - SaTScan v10.3.2)
# ----------------------------------------------------------------------------
# Executa a Estatística de Varredura Espacial (Kulldorff, 1997) EXCLUSIVAMENTE
# sobre `03. Dados/dataset_tcc_consolidado.rds` (painel consolidado do TCC):
#
#   * Casos:      total de casos prováveis acumulados por município (2010-2025)
#   * População:  população média residente do período (base sob risco)
#   * Modelo:     Poisson discreto, varredura puramente espacial, janela
#                 circular com raio máximo de 15% da população sob risco
#   * Otimização: tamanho ótimo dos clusters selecionado pela maximização
#                 do Coeficiente de Gini sobre a Curva de Lorenz das zonas
#                 candidatas (Han et al., 2016), com cutoff p <= 0,05 para as
#                 zonas usadas no cálculo do índice (GiniIndexClustersPValueCutOff)
#                 e reporte apenas da coleção ótima (GiniIndexClusterReportingType=0)
#   * Inferência: B = 999 réplicas de Monte Carlo, semente 12345
#                 (parâmetro RandomizationSeed do SaTScan + set.seed no R),
#                 com PValueReportType=0 (cauda Gumbel padrão do SaTScan)
#   * Secundários: p < 0,05, sem sobreposição geográfica
#                 (CriteriaForReportingSecondaryClusters = NoGeoOverlap)
#
# O arquivo .prm é versionado (cópia de auditoria em 03. Dados/Originais/
# Arquivos_SaTScan/satscan_params.prm e em 05. Saídas/satscan_params.prm).
# O objeto binário completo do run é preservado em
# 03. Dados/resultado_satscan_acum.rds, com hash do .prm embutido para
# invalidar o checkpoint caso os parâmetros mudem.
#
# SAÍDAS:
#   03. Dados/Originais/Arquivos_SaTScan/satscan_params.{cas,pop,geo,prm,txt,
#       col.dbf,sci.dbf,gis.dbf,rr.dbf}
#   03. Dados/resultado_satscan_acum.rds   (objeto rsatscan completo)
#   05. Saídas/satscan_params.prm          (cópia de auditoria dos parâmetros)
#   05. Saídas/tabela_clusters_satscan.tex (longtable; sem coluna de valor-p)
#   05. Saídas/fig_mapa_clusters_satscan.png  (PNG 600 dpi, Top 8 + demais)
#   05. Saídas/fig_mapa_clusters_todos_uniforme.png (PNG 600 dpi, cor única)
#   05. Saídas/fig_mapa_rr_satscan.png        (PNG 600 dpi, contínuo a partir de RR>1)
#   05. Saídas/macros_satscan.tex
#   05. Saídas/log_auditoria_satscan.txt
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

escala_continua <- function(values, colours, name, digits = 1) {
  val_min <- min(values, na.rm = TRUE)
  val_max <- max(values, na.rm = TRUE)
  if (identical(val_min, val_max)) val_max <- val_min + 1e-6
  brks <- sort(unique(c(val_min, pretty(c(val_min, val_max), n = 3), val_max)))
  scale_fill_gradientn(
    colours = colours,
    limits = c(val_min, val_max),
    breaks = brks,
    labels = function(x) fmt_br(x, digits),
    name = name,
    guide = GUIDE_BAR_COMPACTO
  )
}

set.seed(12345)          # reprodutibilidade das etapas em R
SEMENTE_MC  <- 12345     # RandomizationSeed do SaTScan (Monte Carlo)
B_REPS      <- 999       # réplicas de Monte Carlo
JANELA_POP  <- 15        # % máxima da população sob risco na janela circular
GINI_PCUT   <- 0.05      # cutoff de p para zonas usadas no cálculo do Gini
ARQ_DIR     <- "03. Dados/Originais/Arquivos_SaTScan"
DIR_SAIDA   <- "05. Saídas"
ARQ_CALOR   <- "03. Dados/Originais/Dados de temperatura - ERA5_ERA5LAND/processado/onda_calor_municipal_2010_2025.rds"
AJUSTE_ENV  <- tolower(Sys.getenv("SATSCAN_AJUSTE_TERMICO", "auto"))
AJUSTE_TERMICO <- AJUSTE_ENV %in% c("sim", "true", "1", "yes") ||
  (AJUSTE_ENV == "auto" && file.exists(ARQ_CALOR))
if (AJUSTE_TERMICO && !file.exists(ARQ_CALOR)) {
  stop("SATSCAN_AJUSTE_TERMICO foi solicitado, mas a rotina de ondas de calor nao gerou ", ARQ_CALOR)
}
RES_RDS     <- if (AJUSTE_TERMICO) "03. Dados/resultado_satscan_termica.rds" else
  "03. Dados/resultado_satscan_acum.rds"
RES_PURO    <- "03. Dados/resultado_satscan_acum.rds"
STUB        <- "satscan_params"   # prefixo dos arquivos do run
SATSCAN_EXE <- file.path(Sys.getenv("HOME"), "bin")   # dir com SaTScanBatch

dir.create(DIR_SAIDA, showWarnings = FALSE, recursive = TRUE)

# Wrapper do ggsave: remove o destino antes de gravar (evita "write failed"
# no dev.off() ao sobrescrever artefatos parcialmente escritos no macOS).
ggsave <- function(filename, ...) {
  if (file.exists(filename)) unlink(filename)
  ggplot2::ggsave(filename, ...)
}
fmt_br <- function(x, d = 1) formatC(x, format = "f", digits = d,
                                     big.mark = ".", decimal.mark = ",")
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

dataset <- readRDS("03. Dados/dataset_tcc_consolidado.rds")
malha   <- readRDS("03. Dados/malha_BR_10.RDS")
malha   <- malha %>% filter(ID_MN_RESI != "260545") %>% arrange(ID_MN_RESI)

stopifnot(identical(sort(unique(dataset$ID_MN_RESI)), malha$ID_MN_RESI))

# Casos prováveis acumulados (2010-2025) e população média do período
mun <- dataset %>%
  group_by(ID_MN_RESI) %>%
  summarise(CASOS = sum(CASOS_PROV), POP = mean(POP), .groups = "drop")

# A covariavel so e ativada quando a rotina diaria validada gerar o resumo. O
# painel mensal nao pode ser usado como substituto de Tmax diaria.
COVARIADAS_ATIVAS <- AJUSTE_TERMICO
cov_temp <- NULL
if (COVARIADAS_ATIVAS) {
  cov_temp <- readRDS(ARQ_CALOR) %>%
    select(ID_MN_RESI, COVAR_TERMICA) %>%
    mutate(COVAR_TERMICA = as.integer(COVAR_TERMICA))
  stopifnot(nrow(cov_temp) == nrow(mun))
  mun <- mun %>% left_join(cov_temp, by = "ID_MN_RESI")
  stopifnot(!any(is.na(mun$COVAR_TERMICA)),
            identical(mun$ID_MN_RESI, sort(unique(dataset$ID_MN_RESI))))
}

# Centróides municipais (malha harmonizada 2010, SIRGAS 2000/EPSG:4674)
cgeom <- st_centroid(st_geometry(malha)) %>% st_coordinates() %>% as.data.frame()
colnames(cgeom) <- c("LONG", "LAT")

# Formato SaTScan: uma linha por local; ano = 2025 representa o periodo agregado.
cas_input <- data.frame(ID_MN_RESI = mun$ID_MN_RESI, CASOS = mun$CASOS,
                        ANO = 2025)
if (COVARIADAS_ATIVAS) cas_input$COVAR_TERMICA <- mun$COVAR_TERMICA
write.table(cas_input,
            file.path(ARQ_DIR, paste0(STUB, ".cas")),
            row.names = FALSE, col.names = FALSE, sep = " ")
pop_input <- data.frame(ID = mun$ID_MN_RESI, ANO = 2025,
                        POP = round(mun$POP))
if (COVARIADAS_ATIVAS) pop_input$COVAR_TERMICA <- mun$COVAR_TERMICA
write.table(pop_input,
            file.path(ARQ_DIR, paste0(STUB, ".pop")),
            row.names = FALSE, col.names = FALSE, sep = " ")
write.table(data.frame(ID = mun$ID_MN_RESI, LAT = cgeom$LAT, LONG = cgeom$LONG),
            file.path(ARQ_DIR, paste0(STUB, ".geo")),
            row.names = FALSE, col.names = FALSE, sep = " ")

cat(sprintf("  locais: %d | casos totais: %s | população média: %s\n",
            nrow(mun), format(sum(mun$CASOS), big.mark = "."),
            format(round(sum(mun$POP)), big.mark = ".")))

# ============================================================================ #
# 2. Parâmetros (.prm) ---------------------------------------------------------
# ============================================================================ #
cat("==> [2/5] Configurando parâmetros (.prm)...\n")

ss.options(reset = TRUE)
ss.options(list(
  CaseFile = paste0(STUB, ".cas"),
  PopulationFile = paste0(STUB, ".pop"),
  CoordinatesFile = paste0(STUB, ".geo"),
  ResultsFile = paste0(STUB, ".txt"),
  StartDate = "2010/01/01",
  EndDate = "2025/12/31",
  PrecisionCaseTimes = 1,
  AnalysisType = 1,                 # Purely Spatial
  ModelType = 0,                    # Discrete Poisson
  ScanAreas = 1,                    # high rates
  MaxSpatialSizeInPopulationAtRisk = JANELA_POP,   # teto: 15% da população
  SpatialWindowShapeType = 0,       # Circular
  MonteCarloReps = B_REPS,
  PValueReportType = 0,              # Default: cauda Gumbel para extremos
  CriteriaForReportingSecondaryClusters = 0,       # NoGeoOverlap
  ReportHierarchicalClusters = "n",
  MinimumCasesInHighRateClusters = 2,
  OutputShapefiles = "n", OutputGoogleEarthKML = "n", OutputGoogleMaps = "n",
  CensusAreasReportedClustersDBase = "y",
  IncludeRelativeRisksCensusAreasDBase = "y",
  # --- Otimização pelo Coeficiente de Gini (Han et al., 2016) ---
  ReportGiniClusters = "y",         # reporta a coleção ótima de Gini
  GiniIndexClusterReportingType = 0,        # 0 = coleção ótima apenas
  GiniIndexClustersPValueCutOff = GINI_PCUT, # só zonas com p<=0,05 entram no índice
  ReportGiniIndexCoefficents = "y", # coeficientes de Gini no arquivo de resultados
  SpatialMaxima = "1,2,3,4,5,6,8,10,12,15"  # paradas de tamanho até o teto
))
ss.options.extra(list(RandomizationSeed = SEMENTE_MC), section = "Inference")

# Grava o .prm (versão de auditoria) e confirma o conteúdo
rsatscan:::write.ss.prm(ARQ_DIR, STUB)
prm_path <- file.path(ARQ_DIR, paste0(STUB, ".prm"))
prm_linhas <- readLines(prm_path)
file.copy(prm_path, file.path(DIR_SAIDA, "satscan_params.prm"), overwrite = TRUE)
prm_md5 <- tools::md5sum(prm_path)

chave <- function(p) prm_linhas[grepl(paste0("^", p, "="), prm_linhas)]
cat("  ", chave("AnalysisType"), "\n")
cat("  ", chave("ModelType"), "\n")
cat("  ", chave("MaxSpatialSizeInPopulationAtRisk"), "\n")
cat("  ", chave("ReportGiniClusters"), "\n")
cat("  ", chave("GiniIndexClusterReportingType"), "\n")
cat("  ", chave("GiniIndexClustersPValueCutOff"), "\n")
cat("  ", chave("ReportGiniIndexCoefficents"), "\n")
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
      SEMENTE_MC, ", teto", JANELA_POP, "% da população, Gini)...\n")
  t0 <- Sys.time()
  res <- satscan(ARQ_DIR, STUB, sslocation = SATSCAN_EXE,
                 cleanup = FALSE, verbose = FALSE)
  cat(sprintf("  scan concluído em %.1f min\n",
              as.numeric(difftime(Sys.time(), t0, units = "mins"))))
  attr(res, "prm_md5") <- unname(prm_md5)
  attr(res, "entrada_md5") <- entrada_md5
  saveRDS(res, RES_RDS)
}

cat("--- Resumo do run (main) ---\n")
cat(paste(utils::head(res$main, 22), collapse = "\n"), "\n")

# ============================================================================ #
# 3.1 Coeficiente de Gini ótimo reportado pelo SaTScan -------------------------
# ============================================================================ #
cat("--- Linhas com 'Gini' no arquivo de resultados ---\n")
cat(paste(grep("Gini", res$main, value = TRUE), collapse = "\n"), "\n")

# A seção "Gini Indexes" traz o coeficiente por parada de tamanho (SpatialMaxima)
# e a linha "Optimal Gini coefficient found at X% maxima". O coeficiente ótimo é
# o máximo da tabela; o tamanho ótimo é a parada correspondente.
GINI_OTIMO <- NA_real_
GINI_PCT_OTIMO <- NA_character_
idx_sec <- grep("^Gini Indexes", res$main)
if (length(idx_sec) > 0) {
  fim <- min(idx_sec[1] + 40, length(res$main))
  sec <- res$main[idx_sec[1]:fim]
  m <- regmatches(sec, regexec("^\\s*([0-9]+) percent[^0-9]*:\\s*([0-9]+\\.[0-9]+)", sec))
  ok <- vapply(m, function(x) length(x) > 1, logical(1))
  if (any(ok)) {
    tab_gini <- data.frame(
      pct = as.integer(vapply(m[ok], function(x) x[2], "")),
      gini = as.numeric(vapply(m[ok], function(x) x[3], "")))
    linha_ot <- grep("Optimal Gini coefficient found at", sec, value = TRUE)
    mo <- regmatches(linha_ot, regexec("at ([0-9]+)\\% maxima", linha_ot))
    pct_ot <- if (length(mo) > 0 && length(mo[[1]]) > 1) as.integer(mo[[1]][2]) else NA_integer_
    if (!is.na(pct_ot) && pct_ot %in% tab_gini$pct) {
      GINI_OTIMO <- tab_gini$gini[tab_gini$pct == pct_ot]
      GINI_PCT_OTIMO <- pct_ot
    } else {
      GINI_OTIMO <- max(tab_gini$gini)
      GINI_PCT_OTIMO <- tab_gini$pct[which.max(tab_gini$gini)]
    }
  }
}
cat(sprintf("  Gini ótimo: %s (parada de %s%% da população)\n",
            ifelse(is.na(GINI_OTIMO), "não localizado", fmt_br(GINI_OTIMO, 4)),
            ifelse(is.na(GINI_PCT_OTIMO), "?", GINI_PCT_OTIMO)))

# ============================================================================ #
# 4. Extração dos clusters da coleção ótima de Gini -----------------------------
# ============================================================================ #
cat("==> [4/5] Extraindo clusters (coleção ótima de Gini) e gerando artefatos...\n")

sci <- res$sci %>% filter(CLUSTER > 0)
col <- res$col %>% filter(CLUSTER > 0)
gis <- res$gis %>% filter(CLUSTER > 0)

# Pertinência à coleção ótima: campo GINI_CLUST do .col (disponível no SaTScan
# quando ReportGiniClusters=y); fallback: todos os clusters do .sci reportados.
if ("GINI_CLUST" %in% names(col)) {
  gini_col <- col %>% filter(GINI_CLUST) %>% pull(CLUSTER) %>% unique()
} else {
  gini_col <- unique(sci$CLUSTER)
}

# Clusters da coleção ótima com p <= 0,05 (p do SaTScan = (rank+1)/(B+1))
clusters <- sci %>%
  left_join(col %>% select(CLUSTER, RADIUS, NUMBER_LOC, P_VALUE, LLR),
            by = "CLUSTER") %>%
  filter(CLUSTER %in% gini_col, P_VALUE <= 0.05) %>%
  arrange(CLUSTER)

# Município polo = centróide da janela (primeiro LOC_ID do cluster no .col)
polos <- col %>%
  group_by(CLUSTER) %>%
  slice(1) %>%
  select(CLUSTER, LOC_ID) %>%
  left_join(malha %>% select(ID_MN_RESI, NM_MUN, CD_UF),
            by = c("LOC_ID" = "ID_MN_RESI")) %>%
  mutate(NM_UF = UF_NOME[CD_UF])

clusters <- clusters %>%
  left_join(polos, by = "CLUSTER") %>%
  mutate(PVAL_TXT = ifelse(P_VALUE < 0.001,
                           sprintf("< 0,001"),
                           sprintf("= %s", fmt_br(P_VALUE, 3))))

# Participação relativa do primário (população e casos do país)
N_CASOS <- sum(mun$CASOS); N_POP <- sum(mun$POP)
prim <- clusters %>% slice(1)
pct_pop_prim <- 100 * prim$POPULATION / N_POP
pct_casos_prim <- 100 * prim$OBSERVED / N_CASOS

# Cobertura agregada da coleção ótima (clusters sem sobreposição geográfica)
cob_mun  <- sum(clusters$NUMBER_LOC)
cob_cas  <- sum(clusters$OBSERVED)
cob_esp  <- sum(clusters$EXPECTED)
cob_pop  <- sum(clusters$POPULATION)
# Maior RR da coleção (polo e volume de casos para a redação)
max_rr <- clusters %>% slice(which.max(REL_RISK))

cat(sprintf("  clusters na coleção ótima de Gini (p<0,05): %d\n", nrow(clusters)))
print(clusters %>%
        select(CLUSTER, NM_MUN, NUMBER_LOC, RADIUS, OBSERVED, EXPECTED,
               REL_RISK, P_VALUE))

# ---- 4.1 Tabela LaTeX (kableExtra, longtable, font_size 9) ----------------- #
# Converte nomes em CAIXA ALTA para Nome Próprio ("UNIÃO DE MINAS" ->
# "União de Minas"), preservando conectivos em minúsculas. Função vetorizada:
# recebe um vetor de nomes e devolve um rótulo por elemento.
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

# 92 linhas (coleção ótima) não cabem em uma única página: longtable com
# cabeçalho repetido e largura ajustada ao texto (full_width), em vez do
# scale_down de página única (que comprimiria a fonte para ~6pt).
# A coluna de valor-p foi REMOVIDA: todos os clusters listados pertencem à
# coleção ótima de Gini já filtrada por P_VALUE <= 0,05 (ver Seção 4). Municípios-
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

cap_tab <- paste0(
  "\\textit{Clusters} espaciais significativos de dengue detectados pela ",
  "varredura espacial, Brasil, 2010--2025.")

k <- kableExtra::kable(tbl, format = "latex", booktabs = TRUE, longtable = TRUE,
  escape = FALSE, caption = cap_tab, label = "clusters_satscan",
  col.names = c("\\textit{Cluster}", "Qtd. municípios",
                "Raio (km)", "Casos obs. ($C_Z$)", "Casos esp. ($E_Z$)",
                "Risco relativo ($RR_Z$)"),
  align = c("c", "c", "c", "c", "c", "c"))
k <- kableExtra::kable_styling(k, latex_options = c("repeat_header"),
                               font_size = 9, full_width = TRUE,
                               repeat_header_text = "\\textit{(continuação)}",
                               repeat_header_continued = "\\textit{(continuação)}")
write_lines(as.character(k), file.path(DIR_SAIDA, "tabela_clusters_satscan.tex"))
cat("  salvo: tabela_clusters_satscan.tex (longtable, font 9)\n")

# ---- 4.2 Mapas (PNG 600 dpi) ------------------------------------------------ #
malha_plot <- malha %>% st_transform(5880)
estados <- malha_plot %>% group_by(CD_UF) %>%
  summarise(geometry = st_union(geometry), .groups = "drop")

# Mapa de clusters: municípios pertencentes a cada cluster da coleção ótima
memb <- gis %>%
  filter(CLUSTER %in% clusters$CLUSTER) %>%
  select(LOC_ID, CLUSTER)

# Estratificação da legenda: os Top 8 clusters de maior relevância (maior
# verossimilhança) são destacados individualmente; os demais (9 a 92) entram
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

# Paleta: cores contrastantes "Dark 3" (colorspace) para os Top 8; laranja
# neutro #FDB863 para os demais clusters; cinza claro #E0E0E0 para
# municípios sem cluster
pal_cl <- c(setNames(colorspace::qualitative_hcl(length(top8), "Dark 3"),
                     as.character(top8)),
            "demais" = "#FDB863",
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

ggsave(file.path(DIR_SAIDA, "fig_mapa_clusters_satscan.png"), p1,
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

ggsave(file.path(DIR_SAIDA, "fig_mapa_rr_satscan.png"), p2,
       width = 7.0, height = 6.2, dpi = 600, bg = "white")
cat("  salvo: fig_mapa_rr_satscan.png (continuo acima de RR=1; branco p/ RR<=1)\n")

# Mapa complementar: TODOS os clusters da coleção ótima de Gini em cor
# única (laranja escuro/terracota #E66101); municípios fora de cluster em
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
    values = c("Cluster" = "#E66101", "Sem" = "#E0E0E0"),
    labels = c(
      "Cluster" = expression(italic("Cluster")~significativo~(p < 0.05)),
      "Sem"   = expression(Sem~italic("cluster"))
    ),
    name = NULL,
    guide = guide_legend(override.aes = list(colour = NA))
  ) +
  TEMA_CARTO

ggsave(file.path(DIR_SAIDA, "fig_mapa_clusters_todos_uniforme.png"), p_uni,
       width = 7.0, height = 6.2, dpi = 600, bg = "white")
cat(sprintf("  salvo: fig_mapa_clusters_todos_uniforme.png (%d clusters, cor unica #E66101)\n",
            length(unique(memb$CLUSTER))))

# ---- 4.3 Macros ------------------------------------------------------------- #
macro <- c(
  "% Macros dinamicas geradas por 05_varredura_satscan.R - nao editar manualmente",
  sprintf("\\newcommand{\\ScanTotalCasos}{%s}", fmt_br(N_CASOS, 0)),
  sprintf("\\newcommand{\\ScanPopulacao}{%s}", fmt_br(round(N_POP), 0)),
  sprintf("\\newcommand{\\ScanNumMunicipios}{%s}", fmt_br(nrow(mun), 0)),
  sprintf("\\newcommand{\\ScanB}{%s}", B_REPS),
  sprintf("\\newcommand{\\ScanSemente}{%s}", SEMENTE_MC),
  sprintf("\\newcommand{\\ScanJanelaPop}{%s\\%%}", JANELA_POP),
  sprintf("\\newcommand{\\ScanGini}{%s}",
          ifelse(is.na(GINI_OTIMO), "—", fmt_br(GINI_OTIMO, 4))),
  sprintf("\\newcommand{\\ScanGiniPctOtimo}{%s\\%%}",
          ifelse(is.na(GINI_PCT_OTIMO), "?", GINI_PCT_OTIMO)),
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
  sprintf("\\newcommand{\\ScanMaxRRMun}{%s}", fmt_br(max_rr$NUMBER_LOC, 0))
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
write_lines(macro, file.path(DIR_SAIDA, "macros_satscan.tex"))
cat("  salvo: macros_satscan.tex\n")

# ---- 4.4 Log ----------------------------------------------------------------- #
log <- c(
  sprintf("satscan_versao=SaTScan v10.3.2 (rsatscan %s)", as.character(packageVersion("rsatscan"))),
  sprintf("satscan_base=dataset_tcc_consolidado.rds"),
  sprintf("satscan_casos=total casos provaveis acumulados 2010-2025 = %.0f", N_CASOS),
  sprintf("satscan_populacao=populacao media residente do periodo = %.0f", N_POP),
  sprintf("satscan_locais=%d", nrow(mun)),
  sprintf("satscan_modelo=Poisson discreto, puramente espacial, janela circular"),
  sprintf("satscan_janela=teto de %d%% da populacao sob risco", JANELA_POP),
  sprintf("satscan_gini=otimizacao pelo Coeficiente de Gini (Han et al., 2016)"),
  sprintf("satscan_gini_cutoff_p=%.2f (zonas elegiveis ao indice)", GINI_PCUT),
  sprintf("satscan_gini_otimo=%s (parada de %s%%)",
          ifelse(is.na(GINI_OTIMO), "NA", fmt_br(GINI_OTIMO, 4)),
          ifelse(is.na(GINI_PCT_OTIMO), "?", GINI_PCT_OTIMO)),
  sprintf("satscan_montecarlo=%d repeticoes, RandomizationSeed=%d", B_REPS, SEMENTE_MC),
  sprintf("satscan_secundarios=colecao otima de Gini, sem sobreposicao geografica, p<0.05"),
  sprintf("satscan_clusters_significativos=%d", nrow(clusters)))
cov_status <- if (COVARIADAS_ATIVAS)
  "satscan_covariadas=ativada (COVAR_TERMICA: 3 categorias de D_i, Tmax diaria)" else
  "satscan_covariadas=desativada; fonte diaria de Tmax ausente"
log <- c(log, cov_status)

# Quando o resultado termico esta ativo, compara a colecao ajustada com o
# checkpoint puro preservado. A comparacao e descritiva, nao uma nova inferencia.
if (COVARIADAS_ATIVAS && file.exists(RES_PURO)) {
  resumo_run <- function(x) {
    col <- x$col %>% filter(CLUSTER > 0)
    data.frame(clusters = nrow(col),
               prim_rr = if (nrow(col)) col$REL_RISK[1] else NA_real_,
               prim_p = if (nrow(col)) col$P_VALUE[1] else NA_real_)
  }
  cmp <- rbind(puro = resumo_run(readRDS(RES_PURO)),
               termico = resumo_run(res))
  write.table(cmp, file.path(DIR_SAIDA, "comparacao_clusters_puro_termico.tsv"),
              sep = "\t", quote = FALSE, col.names = NA)
  log <- c(log, sprintf("comparacao=arquivo comparacao_clusters_puro_termico.tsv"))
}
for (i in seq_len(nrow(clusters)))
  log <- c(log, sprintf(
    "satscan_cluster_%d=%s | polo=%s | municipios=%d | raio=%.1f km | C_Z=%.0f | E_Z=%.0f | RR=%.3f | p=%.6f",
    clusters$CLUSTER[i], clusters$CD_UF[i], clusters$NM_MUN[i],
    clusters$NUMBER_LOC[i], clusters$RADIUS[i], clusters$OBSERVED[i],
    clusters$EXPECTED[i], clusters$REL_RISK[i], clusters$P_VALUE[i]))
write_lines(log, file.path(DIR_SAIDA, "log_auditoria_satscan.txt"))
cat("\n--- LOG (SATSCAN) ---\n"); cat(log, sep = "\n")

cat("\nArtefatos em 05. Saídas/:\n")
print(sort(list.files(DIR_SAIDA, pattern = "satscan|clusters|rr_satscan")))
