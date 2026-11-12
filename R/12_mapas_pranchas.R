# ============================================================================ #
# 12_mapas_pranchas.R
# ----------------------------------------------------------------------------
# Figuras de mapas derivadas das rodadas do SaTScan (desenho único do
# orientador; cenários completo e sem2024). Roda DEPOIS de 10 e 11.
#
# Gera:
#   CORPO
#   * fig_mapa_clusters_2x1_puro_calor.png  : gride 2x1 com o modelo sem ajuste
#     e o ajuste por calor (menor WMAPE), sem legenda por painel.
#   * fig_mapa_rr_2x1_puro_calor.png        : risco relativo municipal dos
#     mesmos dois modelos, escala de cor COMUM aos dois painéis.
#   * fig_mapa_clusters_2x1_puro_com_sem2024.png  : gride 2x1 do modelo sem
#     ajuste no cenário completo (2010-2025) e no cenário sem 2024.
#   * fig_mapa_clusters_2x1_calor_com_sem2024.png : gride 2x1 do ajuste por
#     calor nos dois mesmos cenários.
#   * fig_mapa_persistencia_ajustes.png     : quantas das oito formulações
#     colocam cada município em zona significativa (gradiente discreto 1 a 8;
#     cinza = fora de zonas). Acompanha dados_persistencia_ajustes.tsv.
#   APÊNDICE (pranchas compactas, redesenho limpo: uma escala e uma rosa dos
#   ventos por prancha, sem contorno municipal individual por painel)
#   * fig_prancha_clusters_completo.png     : 8 painéis (4x2), 2010-2025.
#   * fig_prancha_clusters_sem2024.png      : 8 painéis (4x2), sem 2024.
#   * fig_prancha_rr_completo.png           : 6 painéis (3x2) com o risco
#     relativo das demais formulações (esgoto, densidade, proporção, água,
#     lixo e índice composto).
#
# Padrão gráfico: canvas renderizado no TAMANHO FINAL de impressão (fontes e
# traços em pontos reais), 600 dpi, fundo branco, sem legenda nas figuras (a
# codificação é explicada na rótula/nota do manuscrito).
# ============================================================================ #

suppressPackageStartupMessages({
  library(dplyr); library(readr); library(sf)
  library(ggplot2); library(ggspatial); library(patchwork)
  library(viridisLite)
})
sf_use_s2(FALSE)

here::i_am("R/12_mapas_pranchas.R")
DIR_FIGURAS <- here::here("output", "figures")
DIR_TABELAS <- here::here("output", "tables")
DIR_LOGS <- here::here("output", "logs")
DIR_MODELOS <- here::here("output", "models")
for (diretorio in c(DIR_FIGURAS, DIR_TABELAS, DIR_LOGS, DIR_MODELOS))
  dir.create(diretorio, showWarnings = FALSE, recursive = TRUE)

# ---- 0. Insumos ------------------------------------------------------------- #
malha <- readRDS(here::here("data", "raw", "malhas", "malha_BR_10.RDS")) %>%
  filter(ID_MN_RESI != "260545") %>% arrange(ID_MN_RESI)
malha_plot <- malha %>% st_transform(5880)

# A malha municipal não é topologicamente limpa: a dissolução por UF deixa
# anéis internos microscópicos (fissuras) entre municípios vizinhos, que
# imprimem como "pontinhos pretos". O helper mantém apenas o anel exterior de
# cada polígono dissolvido, removendo esses buracos de origem topológica.
sem_buracos <- function(g) {
  polys <- st_cast(st_sfc(g), "POLYGON", warn = FALSE)
  st_multipolygon(lapply(polys, function(p) list(p[[1]])))
}
# Conta os anéis internos (buracos) de um conjunto de geometrias (conferência).
conta_aneis_internos <- function(sfc_g) {
  sum(vapply(sfc_g, function(gg) {
    polys <- st_cast(st_sfc(gg), "POLYGON", warn = FALSE)
    sum(vapply(polys, function(p) length(p) - 1L, integer(1)))
  }, integer(1)))
}

estados <- malha_plot %>% group_by(CD_UF) %>%
  summarise(geometry = st_union(geometry), .groups = "drop")
aneis_antes <- conta_aneis_internos(estados$geometry)
estados$geometry <- st_sfc(lapply(estados$geometry, sem_buracos), crs = st_crs(estados))
aneis_depois <- conta_aneis_internos(estados$geometry)
cat(sprintf("  contornos estaduais: anéis internos (fissuras topológicas) %d -> %d\n",
            aneis_antes, aneis_depois))

MODELOS <- c(puro = "Sem ajuste", termica = "Calor", esgoto = "Esgoto",
             densurb = "Densidade urbana", propurb = "Proporção urbana",
             agua = "Água", lixo = "Lixo", comp5 = "Índice composto")
ORDEM <- names(MODELOS)   # ordem da tabela/narrativa: covariáveis e composto ao final
CENARIOS <- c(completo = "", sem2024 = "_sem2024")

rds_run <- function(modelo, sufixo) {
  base <- if (modelo == "puro") "resultado_satscan_acum" else paste0("resultado_satscan_", modelo)
  file.path(DIR_MODELOS, paste0(base, sufixo, ".rds"))
}

# Zonas significativas (p<=0,05) e municípios em zonas, como em 10/11
sig_zonas <- function(x) {
  col_x <- x$col %>% filter(CLUSTER > 0)
  x$sci %>% filter(CLUSTER > 0) %>%
    left_join(col_x %>% select(CLUSTER, P_VALUE), by = "CLUSTER") %>%
    filter(P_VALUE <= 0.05) %>% arrange(CLUSTER)
}
membros_sig <- function(x) unique(x$gis$LOC_ID[x$gis$CLUSTER %in% sig_zonas(x)$CLUSTER])

le_run <- function(modelo, cen) readRDS(rds_run(modelo, CENARIOS[[cen]]))

# ---- 1. Painéis ------------------------------------------------------------- #
tema_painel <- function(base_family = "serif", tam_titulo = 8.5) {
  theme_void(base_family = base_family) +
    theme(plot.title = element_text(size = tam_titulo, hjust = 0.5, face = "plain",
                                    margin = margin(b = 1.5)),
          plot.margin = margin(0.6, 0.6, 0.6, 0.6))
}

# Painel binário de zonas (laranja = município em zona significativa). A escala
# gráfica e a rosa dos ventos entram apenas nos painéis dos cantos da prancha
# (um de cada por figura), no mesmo padrão das figuras individuais.
painel_clusters <- function(ids, titulo, escala = FALSE, rosa = FALSE, tam_titulo = 8.5) {
  d <- malha_plot %>%
    left_join(data.frame(ID_MN_RESI = as.character(ids), ZONA = "Zona"),
              by = "ID_MN_RESI") %>%
    mutate(ZONA = ifelse(is.na(ZONA), "Fora", ZONA))
  p <- ggplot(d) +
    geom_sf(aes(fill = ZONA), colour = NA) +
    geom_sf(data = estados, fill = NA, colour = "grey15", linewidth = 0.4) +
    scale_fill_manual(values = c("Zona" = "#F1605D", "Fora" = "#E0E0E0"), guide = "none") +
    labs(title = titulo) +
    tema_painel(tam_titulo = tam_titulo)
  if (escala) p <- p + ANOT_ESCALA()
  if (rosa)   p <- p + ANOT_ROSA()
  p
}

# Painel do risco relativo municipal (branco em RR <= 1; magma invertida acima)
painel_rr <- function(rr_df, titulo, lim_max, escala = FALSE, rosa = FALSE, tam_titulo = 8.5) {
  d <- malha_plot %>%
    left_join(rr_df %>% mutate(ID_MN_RESI = as.character(LOC_ID)) %>%
                select(ID_MN_RESI, REL_RISK),
              by = "ID_MN_RESI")
  d$RR_RISCO <- ifelse(d$REL_RISK > 1, d$REL_RISK, NA_real_)
  p <- ggplot(d) +
    geom_sf(aes(fill = RR_RISCO), colour = NA) +
    geom_sf(data = estados, fill = NA, colour = "grey15", linewidth = 0.4) +
    scale_fill_gradientn(colours = magma(200, direction = -1),
                         limits = c(1, lim_max), na.value = "#FFFFFF", guide = "none") +
    labs(title = titulo) +
    tema_painel(tam_titulo = tam_titulo)
  if (escala) p <- p + ANOT_ESCALA(0.65)
  if (rosa)   p <- p + ANOT_ROSA(0.75)
  p
}

# Componentes cartográficos de apoio (padrão das figuras individuais do 10)
ANOT_ESCALA <- function(texto_cex = 0.75, altura = 0.20) {
  annotation_scale(location = "br", width_hint = 0.20,
                   text_col = "grey25", text_cex = texto_cex, text_family = "serif",
                   bar_cols = c("grey30", "grey80"),
                   height = unit(altura, "cm"),
                   pad_x = unit(0.2, "cm"), pad_y = unit(0.2, "cm"))
}
ANOT_ROSA <- function(altura = 0.85) {
  annotation_north_arrow(location = "tr", which_north = "true",
                         style = north_arrow_fancy_orienteering,
                         height = unit(altura, "cm"), width = unit(altura, "cm"),
                         pad_x = unit(0.15, "cm"), pad_y = unit(0.15, "cm"))
}

# Monta uma prancha (grade de painéis) no tamanho final de impressão (cm).
monta_prancha <- function(paineis, ncol, arq, larg_cm, alt_cm) {
  prancha <- wrap_plots(paineis, ncol = ncol)
  if (file.exists(arq)) unlink(arq)
  ggsave(arq, prancha, width = larg_cm / 2.54, height = alt_cm / 2.54,
         dpi = 600, bg = "white", limitsize = FALSE)
  invisible(arq)
}

# Índices dos painéis que recebem a escala (canto inferior direito da prancha)
# e a rosa dos ventos (canto superior direito), para grades em ordem de leitura.
idx_cantos <- function(n, ncol) {
  nrow_g <- ceiling(n / ncol)
  list(escala = nrow_g * ncol,          # último painel da direita
       rosa   = min(ncol, n))           # primeiro painel da direita
}

# ---- 2. Contagem de persistência (quantas formulações põem o município) ----- #
cat("==> [1/4] Contagem de persistência por município (cenário completo)...\n")
membros <- lapply(ORDEM, function(m) membros_sig(le_run(m, "completo")))
names(membros) <- ORDEM
ids_zona <- sort(unique(unlist(membros)))
cnt <- data.frame(
  ID_MN_RESI = as.character(ids_zona),
  NM_MUN = malha$NM_MUN[match(as.character(ids_zona), malha$ID_MN_RESI)],
  n_formulacoes = as.integer(vapply(ids_zona, function(id) sum(vapply(membros, function(s) id %in% s, logical(1))), integer(1))),
  stringsAsFactors = FALSE)
write_tsv(cnt, file.path(DIR_TABELAS, "dados_persistencia_ajustes.tsv"))

# Mapa-síntese (escala discreta 1 a 8; cinza = fora de zonas). O recorte da
# rampa (25% a 90%) evita que o nível 1 se confunda com o cinza e que o nível 8
# fique preto puro na impressão.
rampa_cnt <- magma(100, direction = -1)
cores_cnt <- rampa_cnt[round(seq(25, 90, length.out = 8))]
map_cnt <- malha_plot %>%
  left_join(cnt %>% mutate(n_formulacoes = factor(n_formulacoes, levels = 1:8)),
            by = "ID_MN_RESI") %>%
  mutate(CLASSE = ifelse(is.na(n_formulacoes), "Fora", as.character(n_formulacoes)))
map_cnt$CLASSE <- factor(map_cnt$CLASSE, levels = c(as.character(1:8), "Fora"))
pal_cnt <- c(setNames(cores_cnt, as.character(1:8)), "Fora" = "#E0E0E0")
p_sintese <- ggplot(map_cnt) +
  geom_sf(aes(fill = CLASSE), colour = NA) +
  geom_sf(data = estados, fill = NA, colour = "grey15", linewidth = 0.4) +
  scale_fill_manual(
    values = pal_cnt,
    name = "Formulações",
    breaks = c(as.character(1:8), "Fora"),
    labels = c(as.character(1:8), "Fora das zonas"),
    guide = guide_legend(keyheight = unit(0.30, "cm"), keywidth = unit(0.40, "cm"),
                         override.aes = list(colour = NA))) +
  labs(title = NULL) +
  tema_painel() + ANOT_ESCALA() + ANOT_ROSA() +
  theme(legend.position      = c(0.02, 0.02),
        legend.justification = c(0, 0),
        legend.key           = element_blank(),
        legend.title         = element_text(size = 11, face = "bold", family = "serif", lineheight = 1.15),
        legend.text          = element_text(size = 9.5, family = "serif"),
        legend.key.width     = unit(0.38, "cm"),
        legend.key.height    = unit(0.30, "cm"),
        legend.spacing.y     = unit(0.04, "cm"),
        legend.margin        = margin(0, 0, 0, 0.1, "cm"))
monta_prancha(list(p_sintese), ncol = 1,
              file.path(DIR_FIGURAS, "fig_mapa_persistencia_ajustes.png"),
              larg_cm = 17.78, alt_cm = 15.75)
cat(sprintf("  mapa-síntese: %d municípios em >=1 formulação | >=6: %d | =8: %d\n",
            nrow(cnt), sum(cnt$n_formulacoes >= 6), sum(cnt$n_formulacoes == 8)))

# Constrói a lista de painéis marcando, em cada grade, quais recebem a escala
# (canto inferior direito) e a rosa dos ventos (canto superior direito).
constroi <- function(fabricas, ncol) {
  ic <- idx_cantos(length(fabricas), ncol)
  lapply(seq_along(fabricas), function(i)
    fabricas[[i]](escala = i == ic$escala, rosa = i == ic$rosa))
}

# ---- 3. Corpo: 2x1 sem ajuste + calor (zonas e risco relativo) -------------- #
cat("==> [2/4] Corpo: pranchas 2x1 (puro e calor)...\n")
f_lar <- lapply(c("puro", "termica"), function(m) {
  force(m)
  titulo <- if (m == "termica") "Ajuste por calor" else MODELOS[[m]]
  function(escala, rosa) painel_clusters(membros[[m]], titulo, escala, rosa)
})
monta_prancha(constroi(f_lar, ncol = 1),
              ncol = 1, file.path(DIR_FIGURAS, "fig_mapa_clusters_2x1_puro_calor.png"),
              larg_cm = 10.6, alt_cm = 19.4)

rr_puro <- le_run("puro", "completo")$rr
rr_term <- le_run("termica", "completo")$rr
lim_par <- max(rr_puro$REL_RISK, rr_term$REL_RISK)
f_rr_par <- lapply(list(rr_puro, rr_term), function(r) {
  force(r); function(escala, rosa) painel_rr(r, NULL, lim_par, escala, rosa)
})
paineis_rr_par <- constroi(f_rr_par, ncol = 1)
paineis_rr_par[[1]] <- paineis_rr_par[[1]] + labs(title = "Sem ajuste")
paineis_rr_par[[2]] <- paineis_rr_par[[2]] + labs(title = "Ajuste por calor")
monta_prancha(paineis_rr_par, ncol = 1,
              file.path(DIR_FIGURAS, "fig_mapa_rr_2x1_puro_calor.png"),
              larg_cm = 10.6, alt_cm = 19.4)
cat(sprintf("  RR 2x1: escala comum de 1,0 a %s\n", format(round(lim_par, 1), decimal.mark = ",")))

# Comparação de cenários (com 2024 vs sem 2024), no mesmo padrão 2x1 do corpo:
# painel de cima (rosa dos ventos) e painel de baixo (escala gráfica).
rot_cenario <- function(base, cen) if (cen == "completo") paste0(base, ", 2010--2025") else paste0(base, ", sem 2024")
f_cmp <- function(modelo, base_titulo) {
  lapply(c("completo", "sem2024"), function(cen) {
    force(cen); force(modelo); force(base_titulo)
    function(escala, rosa)
      painel_clusters(membros_sig(le_run(modelo, cen)), rot_cenario(base_titulo, cen), escala, rosa)
  })
}
monta_prancha(constroi(f_cmp("puro", "Sem ajuste"), ncol = 1), ncol = 1,
              file.path(DIR_FIGURAS, "fig_mapa_clusters_2x1_puro_com_sem2024.png"),
              larg_cm = 10.6, alt_cm = 19.4)
monta_prancha(constroi(f_cmp("termica", "Ajuste por calor"), ncol = 1), ncol = 1,
              file.path(DIR_FIGURAS, "fig_mapa_clusters_2x1_calor_com_sem2024.png"),
              larg_cm = 10.6, alt_cm = 19.4)
cat("  cenários 2x1 (com/sem 2024): puro e calor gerados\n")

# ---- 4. Apêndice: pranchas compactas --------------------------------------- #
cat("==> [3/4] Apêndice: pranchas de zonas (completo e sem2024)...\n")
for (cen in names(CENARIOS)) {
  f <- lapply(ORDEM, function(m) {
    force(m); function(escala, rosa) painel_clusters(membros_sig(le_run(m, cen)), MODELOS[[m]], escala, rosa, tam_titulo = 7.5)
  })
  monta_prancha(constroi(f, ncol = 2), ncol = 2,
                file.path(DIR_FIGURAS, paste0("fig_prancha_clusters_", cen, ".png")),
                larg_cm = 10.3, alt_cm = 19.2)
}

cat("==> [4/4] Apêndice: prancha de risco relativo (6 demais ajustes)...\n")
mods_rr <- setdiff(ORDEM, c("puro", "termica"))
rrs <- lapply(mods_rr, function(m) le_run(m, "completo")$rr)
lim_rr <- max(vapply(rrs, function(x) max(x$REL_RISK), numeric(1)))
f_rr6 <- lapply(seq_along(mods_rr), function(i) {
  force(i); function(escala, rosa) painel_rr(rrs[[i]], MODELOS[[mods_rr[i]]], lim_rr, escala, rosa, tam_titulo = 7.5)
})
monta_prancha(constroi(f_rr6, ncol = 2), ncol = 2,
              file.path(DIR_FIGURAS, "fig_prancha_rr_completo.png"),
              larg_cm = 13.8, alt_cm = 19.2)
cat(sprintf("  RR prancha: escala comum de 1,0 a %s\n", format(round(lim_rr, 1), decimal.mark = ",")))

# ---- 5. Log ----------------------------------------------------------------- #
log <- c(
  "log_auditoria_mapas_pranchas - figuras de mapas derivadas do SaTScan",
  sprintf("persistencia_municipios_em_zona=%d", nrow(cnt)),
  sprintf("persistencia_distribuicao=%s", paste(sprintf("%d=%d", 1:8, tabulate(cnt$n_formulacoes, nbins = 8)), collapse = " | ")),
  sprintf("persistencia_ge6=%d (%.1f%% do painel) | =8=%d (%.1f%%)",
          sum(cnt$n_formulacoes >= 6), 100 * sum(cnt$n_formulacoes >= 6) / 5564,
          sum(cnt$n_formulacoes == 8), 100 * sum(cnt$n_formulacoes == 8) / 5564),
  sprintf("contornos_estaduais_aneis_internos=%d->%d (fissuras topológicas removidas)", aneis_antes, aneis_depois),
  sprintf("rr_limite_2x1_puro_calor=%.2f", lim_par),
  sprintf("rr_limite_prancha_apendice=%.2f", lim_rr),
  "figuras=fig_mapa_persistencia_ajustes.png | fig_mapa_clusters_2x1_puro_calor.png | fig_mapa_rr_2x1_puro_calor.png | fig_mapa_clusters_2x1_puro_com_sem2024.png | fig_mapa_clusters_2x1_calor_com_sem2024.png | fig_prancha_clusters_completo.png | fig_prancha_clusters_sem2024.png | fig_prancha_rr_completo.png")
writeLines(log, file.path(DIR_LOGS, "log_auditoria_mapas_pranchas.txt"))
cat("\n--- LOG ---\n"); cat(log, sep = "\n")
cat("\nArtefatos:\n")
print(sort(list.files(here::here("output"), recursive = TRUE, pattern = "^(fig_mapa_(persistencia|clusters_2x1|rr_2x1)|fig_prancha|dados_persistencia)")))
