suppressPackageStartupMessages({
  library(dplyr)
  library(sf)
  library(ggplot2)
  library(ggspatial)
  library(patchwork)
  library(units)
  library(viridisLite)
})

sf_use_s2(FALSE)

here::i_am("R/13_mapas_slides.R")
DIR_FIGURAS <- here::here("output", "figures")
DIR_MODELOS <- here::here("output", "models")
for (diretorio in c(DIR_FIGURAS, DIR_MODELOS))
  dir.create(diretorio, showWarnings = FALSE, recursive = TRUE)

malha <- readRDS(here::here("data", "raw", "malhas", "malha_BR_10.RDS")) %>%
  filter(ID_MN_RESI != "260545") %>%
  arrange(ID_MN_RESI) %>%
  st_transform(5880)

sem_buracos <- function(g) {
  polys <- st_cast(st_sfc(g), "POLYGON", warn = FALSE)
  st_multipolygon(lapply(polys, function(p) list(p[[1]])))
}

estados <- malha %>%
  group_by(CD_UF) %>%
  summarise(geometry = st_union(geometry), .groups = "drop")
estados$geometry <- st_sfc(lapply(estados$geometry, sem_buracos), crs = st_crs(estados))

sig_municipios <- function(arquivo) {
  x <- readRDS(arquivo)
  col_x <- x$col %>% filter(CLUSTER > 0)
  clusters <- x$sci %>%
    filter(CLUSTER > 0) %>%
    left_join(col_x %>% select(CLUSTER, P_VALUE), by = "CLUSTER") %>%
    filter(P_VALUE <= 0.05) %>%
    pull(CLUSTER)
  unique(as.character(x$gis$LOC_ID[x$gis$CLUSTER %in% clusters]))
}

anot_escala <- annotation_scale(
  location = "br",
  width_hint = 0.20,
  text_col = "grey30",
  text_cex = 0.75,
  text_family = "serif",
  bar_cols = c("grey30", "grey80"),
  height = unit(0.20, "cm"),
  pad_x = unit(0.2, "cm"),
  pad_y = unit(0.2, "cm")
)

anot_rosa <- annotation_north_arrow(
  location = "tr",
  which_north = "true",
  style = north_arrow_fancy_orienteering,
  height = unit(0.85, "cm"),
  width = unit(0.85, "cm"),
  pad_x = unit(0.15, "cm"),
  pad_y = unit(0.15, "cm")
)

painel <- function(ids, titulo) {
  d <- malha %>%
    left_join(data.frame(ID_MN_RESI = ids, ZONA = "Zona"), by = "ID_MN_RESI") %>%
    mutate(ZONA = ifelse(is.na(ZONA), "Fora", ZONA))
  ggplot(d) +
    geom_sf(aes(fill = ZONA), colour = NA) +
    geom_sf(data = estados, fill = NA, colour = "grey15", linewidth = 0.4) +
    scale_fill_manual(values = c("Zona" = "#F1605D", "Fora" = "#E0E0E0"), guide = "none") +
    labs(title = titulo) +
    theme_void(base_family = "serif") +
    theme(
      plot.title = element_text(size = 13, hjust = 0.5, face = "plain", margin = margin(b = 2)),
      plot.margin = margin(1, 1, 1, 1)
    ) +
    anot_escala +
    anot_rosa
}

gera_painel <- function(arquivos, titulos, saida) {
  graficos <- Map(function(arquivo, titulo) painel(sig_municipios(arquivo), titulo), arquivos, titulos)
  prancha <- wrap_plots(graficos, ncol = 2)
  caminho <- file.path(DIR_FIGURAS, saida)
  temporario <- tempfile(pattern = "slides-", tmpdir = DIR_FIGURAS, fileext = ".png")
  ggsave(temporario, prancha, width = 27.5 / 2.54, height = 13.5 / 2.54, dpi = 600, bg = "white", limitsize = FALSE)
  if (file.exists(caminho)) unlink(caminho)
  if (!file.rename(temporario, caminho)) stop("Não foi possível gravar ", caminho)
  invisible(caminho)
}

gera_painel(
  c(file.path(DIR_MODELOS, "resultado_satscan_acum.rds"), file.path(DIR_MODELOS, "resultado_satscan_termica.rds")),
  c("Sem ajuste · 2010–2025", "Ajuste por calor · 2010–2025"),
  "fig_slides_clusters_puro_calor.png"
)

gera_painel(
  c(file.path(DIR_MODELOS, "resultado_satscan_acum.rds"), file.path(DIR_MODELOS, "resultado_satscan_acum_sem2024.rds")),
  c("Com 2024 · 2010–2025", "Sem 2024 · 2010–2023 e 2025"),
  "fig_slides_clusters_puro_sem2024.png"
)

painel_rr <- function(arquivo, titulo, limite) {
  x <- readRDS(arquivo)
  d <- malha %>%
    left_join(x$rr %>% mutate(ID_MN_RESI = as.character(LOC_ID)) %>% select(ID_MN_RESI, REL_RISK), by = "ID_MN_RESI")
  d$RR_RISCO <- ifelse(d$REL_RISK > 1, d$REL_RISK, NA_real_)
  ggplot(d) +
    geom_sf(aes(fill = RR_RISCO), colour = NA) +
    geom_sf(data = estados, fill = NA, colour = "grey15", linewidth = 0.4) +
    scale_fill_gradientn(colours = magma(200, direction = -1), limits = c(1, limite), na.value = "#FFFFFF", guide = "none") +
    labs(title = titulo) +
    theme_void(base_family = "serif") +
    theme(
      plot.title = element_text(size = 13, hjust = 0.5, face = "plain", margin = margin(b = 2)),
      plot.margin = margin(1, 1, 1, 1)
    ) +
    anot_escala +
    anot_rosa
}

rr_arquivos <- c(file.path(DIR_MODELOS, "resultado_satscan_acum.rds"), file.path(DIR_MODELOS, "resultado_satscan_termica.rds"))
rr_limite <- max(vapply(rr_arquivos, function(f) max(readRDS(f)$rr$REL_RISK), numeric(1)))
rr_graficos <- Map(
  function(arquivo, titulo) painel_rr(arquivo, titulo, rr_limite),
  rr_arquivos,
  c("Sem ajuste", "Ajuste por calor")
)
rr_prancha <- wrap_plots(rr_graficos, ncol = 2)
rr_caminho <- file.path(DIR_FIGURAS, "fig_slides_rr_puro_calor.png")
rr_temporario <- tempfile(pattern = "slides-rr-", tmpdir = DIR_FIGURAS, fileext = ".png")
ggsave(rr_temporario, rr_prancha, width = 27.5 / 2.54, height = 13.5 / 2.54, dpi = 600, bg = "white", limitsize = FALSE)
if (file.exists(rr_caminho)) unlink(rr_caminho)
if (!file.rename(rr_temporario, rr_caminho)) stop("Não foi possível gravar ", rr_caminho)
