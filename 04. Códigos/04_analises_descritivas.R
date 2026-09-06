# ============================================================================ #
# 04_analises_descritivas.R
# Analises descritivas, LISA, cartografia regional e exportacao editorial.
# ============================================================================ #

# ---- 0. Setup -------------------------------------------------------------- #
suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(readr)
  library(ggplot2); library(scales); library(sf)
  library(ggspatial); library(classInt); library(colorspace)
  library(spdep)      # índice global de Moran
  library(kableExtra) # tabelas LaTeX (scale_down)
  library(read.dbc)   # perfil demográfico (DBCs)
  library(lubridate)  # datas
})
sf_use_s2(FALSE)

DIR_SAIDA <- "05. Saídas"
dir.create(DIR_SAIDA, showWarnings = FALSE, recursive = TRUE)

# Wrapper do ggsave: remove o destino antes de gravar. Arquivos parcialmente
# escritos em execucoes interrompidas ficam em estado que causa "write failed"
# no dev.off() do device (bug observado no macOS ao sobrescrever PDF/PNG).
ggsave <- function(filename, ...) {
  if (file.exists(filename)) unlink(filename)
  ggplot2::ggsave(filename, ...)
}

dataset <- readRDS("03. Dados/dataset_tcc_consolidado.rds")
malha   <- readRDS("03. Dados/malha_BR_10.RDS")
malha   <- malha %>% filter(ID_MN_RESI != "260545") %>% arrange(ID_MN_RESI)

# UF -> Grande Região
uf_regiao <- tibble(
  CD_UF = c("11","12","13","14","15","16","17","21","22","23","24","25","26",
            "27","28","29","31","32","33","35","41","42","43","50","51","52","53"),
  REGIAO = c(rep("Norte", 7), rep("Nordeste", 9), rep("Sudeste", 4),
             rep("Sul", 3), rep("Centro-Oeste", 4)))
dataset <- dataset %>% left_join(uf_regiao, by = "CD_UF")

# Padrão numérico brasileiro
fmt_br <- function(x, d = 1) formatC(x, format = "f", digits = d,
                                     big.mark = ".", decimal.mark = ",")
lbl_br <- label_number(big.mark = ".", decimal.mark = ",")

# Meses em português (abreviados) para eixos sazonais
meses_pt <- c("Jan", "Fev", "Mar", "Abr", "Mai", "Jun",
              "Jul", "Ago", "Set", "Out", "Nov", "Dez")

# ---- Tipografia (SEM showtext) --------------------------------------------- #
# O showtext reescala os glifos ao rasterizar em alta resolução (bug de DPI:
# texto proporcionalmente menor nos PNGs de 600 dpi). Por isso ele é
# desativado (caso outro script o tenha carregado) e usa-se a fonte serifada
# nativa do device (cairo/png), com tamanhos reais em pontos.
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

# Estilo editorial clássico: eixos pretos finos, marcas discretas, sem fundo
TEMA_EDITORIAL <- theme(
  axis.line   = element_line(colour = "black", linewidth = 0.3),
  axis.ticks  = element_line(colour = "black", linewidth = 0.3),
  panel.grid  = element_blank(),
  panel.background = element_blank(),
  plot.background = element_blank(),
  legend.key = element_blank()
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

escala_continua <- function(values, colours, name, digits = 1, breaks = NULL) {
  val_min <- min(values, na.rm = TRUE)
  val_max <- max(values, na.rm = TRUE)
  if (identical(val_min, val_max)) val_max <- val_min + 1e-6
  brks <- if (is.null(breaks)) calc_breaks_harmonicos(val_min, val_max) else breaks
  scale_fill_gradientn(
    colours = colours,
    limits = c(val_min, val_max),
    breaks = brks,
    labels = function(x) fmt_br(x, digits),
    name = name,
    guide = GUIDE_BAR_COMPACTO
  )
}

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

log <- character()

# ============================================================================ #
# 1. Perfil demográfico dos casos prováveis (sexo e faixa etária) -------------
# ============================================================================ #
cat("==> [1/7] Perfil demográfico dos casos (DBCs 2010-2025)...\n")
t0 <- Sys.time()

arquivo_perfil <- "03. Dados/Originais/SINAN_Processado/perfil_demografico.rds"
if (file.exists(arquivo_perfil)) {
  cat("  checkpoint: perfil existente reutilizado\n")
  perfil <- readRDS(arquivo_perfil)
} else {
  EXCLUIR <- c("5", "6", "7")  # descartado, chikungunya, zika
  fx <- function(idade) {
    # NU_IDADE_N: 1xxx=horas, 2xxx=dias, 3xxx=meses, 4xxx=anos (código-base)
    a <- ifelse(idade >= 4000, idade - 4000, 0)
    cut(a, breaks = c(0, 4, 9, 14, 19, 39, 59, Inf),
        labels = c("0 a 4", "5 a 9", "10 a 14", "15 a 19",
                   "20 a 39", "40 a 59", "60 ou mais"),
        right = TRUE)
  }
  caso_list <- list()
  for (a in 2010:2025) {
    f <- sprintf("03. Dados/Originais/DBCs/DENGBR%d.dbc", a %% 100)
    if (!file.exists(f)) next
    d <- read.dbc(f)
    if (!all(c("CLASSI_FIN", "CS_SEXO", "NU_IDADE_N", "DT_NOTIFIC") %in% names(d))) next
    d <- d %>%
      filter(!as.character(CLASSI_FIN) %in% EXCLUIR) %>%
      mutate(ANO_EPI = as.character(lubridate::epiyear(as.Date(DT_NOTIFIC)))) %>%
      filter(ANO_EPI >= "2010" & ANO_EPI <= "2025") %>%
      mutate(SEXO = as.character(CS_SEXO),
             SEXO = if_else(is.na(SEXO) | SEXO == "", "I", SEXO),
             FX = as.character(fx(NU_IDADE_N)),
             FX = if_else(is.na(FX), "Ignorado", FX)) %>%
      count(SEXO, FX, name = "n")
    caso_list[[as.character(a)]] <- d
    rm(d); gc()
  }
  perfil <- bind_rows(caso_list)
  saveRDS(perfil, arquivo_perfil)
  cat("  perfil OK em", round(difftime(Sys.time(), t0, units = "mins"), 1), "min\n")
}

tot_sexo <- perfil %>% group_by(SEXO) %>% summarise(n = sum(n), .groups = "drop")
tot_fx   <- perfil %>% group_by(FX)   %>% summarise(n = sum(n), .groups = "drop")
tot_casos_perfil <- sum(perfil$n)
pct_sexo <- tot_sexo %>% mutate(pct = 100 * n / tot_casos_perfil)
pct_fx   <- tot_fx   %>% mutate(pct = 100 * n / tot_casos_perfil)

cat("  casos no perfil:", format(tot_casos_perfil, big.mark = "."),
    "| sexo M/F/I:", paste(sprintf("%s=%.1f%%", pct_sexo$SEXO, pct_sexo$pct), collapse = " | "), "\n\n")

# ============================================================================ #
# 2. Agregações (Brasil/Região), sazonalidade e estratificação de risco -------
# ============================================================================ #
cat("==> [2/7] Agregações e estratificação de risco...\n")

# TI nacional e regional por ano
br_anual <- dataset %>%
  group_by(ANO_EPI) %>%
  summarise(CASOS = sum(CASOS_PROV), POP = sum(POP), OBITOS = sum(NU_OBITOS),
            .groups = "drop") %>%
  mutate(TI = CASOS / POP * 1e5)

reg_anual <- dataset %>%
  group_by(REGIAO, ANO_EPI) %>%
  summarise(CASOS = sum(CASOS_PROV), POP = sum(POP), .groups = "drop") %>%
  mutate(TI = CASOS / POP * 1e5)

# Sazonalidade (média mensal de casos 2010-2025)
base_mes <- readRDS("03. Dados/Originais/SINAN_Processado/base_contagem_mensal_2010_2025.rds")
sazon <- base_mes %>%
  group_by(ANO_EPI, MES) %>% summarise(CASOS = sum(CASOS_PROV), .groups = "drop") %>%
  filter(ANO_EPI != "2009") %>%
  group_by(MES) %>% summarise(CASOS_MED = mean(CASOS), .groups = "drop")

# Taxa de incidencia acumulada no periodo para mapas e estratificacao.
mun_resumo <- dataset %>%
  group_by(ID_MN_RESI) %>%
  summarise(CASOS = sum(CASOS_PROV), POP = mean(POP), .groups = "drop") %>%
  mutate(TI_ACUM = CASOS / POP * 1e5) %>%
  mutate(ESTRATO = case_when(TI_ACUM < 100 ~ "Baixa",
                             TI_ACUM <= 300 ~ "Média",
                             TRUE ~ "Alta"))

# Estratificacao descritiva: <100 baixa; 100--300 media; >300 alta.
estrato_reg <- mun_resumo %>%
  left_join(dataset %>% distinct(ID_MN_RESI, REGIAO), by = "ID_MN_RESI") %>%
  count(REGIAO, ESTRATO) %>%
  group_by(REGIAO) %>%
  mutate(pct = 100 * n / sum(n)) %>%
  ungroup()

# Persistência epidêmica: nº de anos com TI > 300/100 mil (2010-2025)
persist <- dataset %>%
  mutate(EPI = TI_100mil > 300) %>%
  group_by(ID_MN_RESI) %>%
  summarise(ANOS_EPI = sum(EPI), .groups = "drop")

cat("  municípios por estrato (Brasil):",
    paste(sprintf("%s=%.1f%%", "Alta", 100 * mean(mun_resumo$ESTRATO == "Alta")),
          sprintf("%s=%.1f%%", "Média", 100 * mean(mun_resumo$ESTRATO == "Média")),
          sprintf("%s=%.1f%%", "Baixa", 100 * mean(mun_resumo$ESTRATO == "Baixa")),
          collapse = " "), "\n")

# ============================================================================ #
# 3. Índice Global de Moran por ano (2010-2025) -------------------------------
# ============================================================================ #
cat("==> [3/7] Índice Global de Moran anual...\n")

# Matriz de vizinhança: contiguidade QUEEN sobre a malha harmonizada 2010
# (borda OU vértice em comum). Justificativa: em saúde pública, municípios que
# se tocam apenas por um vértice (ex.: divisas fluviais) ainda compartilham
# dinâmica de transmissão; a opção rook (só bordas) subestimaria essas
# conexões. Pesos row-standardized (style = "W"), padrão da literatura.
nb <- poly2nb(st_geometry(malha), queen = TRUE)
sem_viz <- card(nb) == 0
if (any(sem_viz)) {
  cat("  municipios sem vizinhos queen:", sum(sem_viz),
      "(", paste(malha$NM_MUN[sem_viz], collapse = ", "), ") - 1NN global\n")
  # 1NN entre TODOS os centróides (o subconjunto isolado não tem com quem casar)
  k1 <- knn2nb(knearneigh(st_point_on_surface(st_geometry(malha)), k = 1))
  nb[sem_viz] <- k1[sem_viz]
}
lw <- nb2listw(nb, style = "W", zero.policy = TRUE)

moran_linhas <- list()
for (a in 2010:2025) {
  ti <- dataset$TI_100mil[dataset$ANO_EPI == as.character(a)]
  mt <- moran.test(ti, lw, zero.policy = TRUE)
  moran_linhas[[as.character(a)]] <- tibble(ANO_EPI = as.character(a),
                                            I = unname(mt$estimate["Moran I statistic"]),
                                            p = mt$p.value)
  cat(sprintf("  %d: I = %.4f (p = %.4g)\n", a, unname(mt$estimate["Moran I statistic"]), mt$p.value))
}
moran_df <- bind_rows(moran_linhas)

# ============================================================================ #
# 4. LISA com checkpoint -------------------------------------------------------
# ============================================================================ #
cat("==> [4/7] Indicadores locais de associacao espacial...\n")
LISA_RDS <- "03. Dados/lisa_2010_2025.rds"
lisa_md5 <- unname(tools::md5sum("03. Dados/dataset_tcc_consolidado.rds"))
lisa_ok <- FALSE
if (file.exists(LISA_RDS)) {
  lisa_old <- readRDS(LISA_RDS)
  lisa_ok <- identical(lisa_old$input_md5, lisa_md5) &&
    is.data.frame(lisa_old$mun) && nrow(lisa_old$mun) == nrow(malha) &&
    all(c("TI_ACUM", "CAT_LISA", "P_LOC") %in% names(lisa_old$mun))
}

if (lisa_ok) {
  lisa <- lisa_old
  cat("  checkpoint LISA reutilizado\n")
} else {
  lm <- localmoran_perm(mun_resumo$TI_ACUM, lw, nsim = 999L,
                        zero.policy = TRUE, iseed = 12345L)
  lisa_mun <- mun_resumo %>%
    mutate(II = lm[, "Ii"], E_II = lm[, "E.Ii"], Z_II = lm[, "Z.Ii"],
           P_LOC = lm[, "Pr(z != E(Ii)) Sim"])
  z <- lisa_mun$TI_ACUM - mean(lisa_mun$TI_ACUM)
  wz <- lag.listw(lw, z, zero.policy = TRUE)
  lisa_mun$QUADRANTE <- case_when(
    z > 0 & wz > 0 ~ "Alto-Alto",
    z < 0 & wz < 0 ~ "Baixo-Baixo",
    z > 0 & wz < 0 ~ "Alto-Baixo",
    z < 0 & wz > 0 ~ "Baixo-Alto",
    TRUE ~ "Sem desvio")
  lisa_mun$CAT_LISA <- ifelse(lisa_mun$P_LOC < 0.05,
                              lisa_mun$QUADRANTE, "Nao Significativo")
  lisa <- list(mun = lisa_mun, input_md5 = lisa_md5,
               nsim = 999L, seed = 12345L)
  saveRDS(lisa, LISA_RDS)
}

lisa_mun <- lisa$mun
tab_lisa <- lisa_mun %>% count(CAT_LISA) %>%
  mutate(pct = 100 * n / sum(n)) %>%
  arrange(match(CAT_LISA, c("Alto-Alto", "Baixo-Baixo", "Alto-Baixo",
                            "Baixo-Alto", "Nao Significativo")))
n_lisa_sig <- sum(tab_lisa$n[tab_lisa$CAT_LISA != "Nao Significativo"])

cores_lisa <- c("Alto-Alto" = "#D73027", "Baixo-Baixo" = "#2166AC",
                "Alto-Baixo" = "#F4A582", "Baixo-Alto" = "#92C5DE",
                "Nao Significativo" = "#D9D9D9")
malha_plot <- malha %>% st_transform(5880)
estados <- malha_plot %>% group_by(CD_UF) %>%
  summarise(geometry = st_union(geometry), .groups = "drop")
map_lisa <- lisa_mun %>%
  select(ID_MN_RESI, CAT_LISA) %>%
  left_join(malha_plot %>% select(ID_MN_RESI, geometry), by = "ID_MN_RESI") %>%
  st_as_sf()
p_lisa <- ggplot(map_lisa) +
  geom_sf(aes(fill = CAT_LISA), colour = "grey40", linewidth = 0.03) +
  geom_sf(data = estados, fill = NA, colour = "grey25", linewidth = 0.25) +
  annotation_scale(location = "br", width_hint = 0.20, text_col = "grey25",
                   bar_cols = c("grey30", "grey80"), height = unit(0.20, "cm"),
                   text_cex = 0.75, text_family = "serif", pad_x = unit(0.2, "cm"),
                   pad_y = unit(0.2, "cm")) +
  annotation_north_arrow(location = "tr", which_north = "true",
                         style = north_arrow_fancy_orienteering,
                         height = unit(0.9, "cm"), width = unit(0.9, "cm"),
                         pad_x = unit(0.2, "cm"), pad_y = unit(0.2, "cm")) +
  scale_fill_manual(values = cores_lisa, name = "LISA", drop = FALSE,
                    guide = guide_legend(override.aes = list(colour = NA))) +
  TEMA_CARTO
ggsave(file.path(DIR_SAIDA, "fig_mapa_lisa.png"), p_lisa,
       width = 7.0, height = 6.2, dpi = 600, bg = "white")

lisa_macro <- c(
  "% Macros dinamicas geradas por 04_analises_descritivas.R",
  sprintf("\\newcommand{\\LisaHH}{%s}", fmt_br(tab_lisa$n[tab_lisa$CAT_LISA == "Alto-Alto"], 0)),
  sprintf("\\newcommand{\\LisaLL}{%s}", fmt_br(tab_lisa$n[tab_lisa$CAT_LISA == "Baixo-Baixo"], 0)),
  sprintf("\\newcommand{\\LisaHL}{%s}", fmt_br(tab_lisa$n[tab_lisa$CAT_LISA == "Alto-Baixo"], 0)),
  sprintf("\\newcommand{\\LisaLH}{%s}", fmt_br(tab_lisa$n[tab_lisa$CAT_LISA == "Baixo-Alto"], 0)),
  sprintf("\\newcommand{\\LisaNS}{%s}", fmt_br(tab_lisa$n[tab_lisa$CAT_LISA == "Nao Significativo"], 0)),
  sprintf("\\newcommand{\\LisaSig}{%s}", fmt_br(n_lisa_sig, 0)),
  sprintf("\\newcommand{\\LisaPctHH}{%s\\%%}", fmt_br(tab_lisa$pct[tab_lisa$CAT_LISA == "Alto-Alto"], 1)),
  sprintf("\\newcommand{\\LisaPctLL}{%s\\%%}", fmt_br(tab_lisa$pct[tab_lisa$CAT_LISA == "Baixo-Baixo"], 1)),
  sprintf("\\newcommand{\\LisaPctHL}{%s\\%%}", fmt_br(tab_lisa$pct[tab_lisa$CAT_LISA == "Alto-Baixo"], 1)),
  sprintf("\\newcommand{\\LisaPctLH}{%s\\%%}", fmt_br(tab_lisa$pct[tab_lisa$CAT_LISA == "Baixo-Alto"], 1)),
  sprintf("\\newcommand{\\LisaPctNS}{%s\\%%}", fmt_br(tab_lisa$pct[tab_lisa$CAT_LISA == "Nao Significativo"], 1)),
  sprintf("\\newcommand{\\LisaPctSig}{%s\\%%}", fmt_br(100 * n_lisa_sig / nrow(lisa_mun), 1))
)
write_lines(lisa_macro, file.path(DIR_SAIDA, "macros_lisa.tex"))
lisa_log <- c(
  "lisa_incidencia=TI acumulada 2010-2025",
  "lisa_nb=queen + 1NN para municipio sem vizinho",
  "lisa_p=permutacao espacial condicional (nsim=999, semente=12345), corte 0.05",
  sprintf("lisa_n_significativos=%d (%.1f%%)", n_lisa_sig, 100 * n_lisa_sig / nrow(lisa_mun)))
for (i in seq_len(nrow(tab_lisa)))
  lisa_log <- c(lisa_log, sprintf("lisa_%s=%d (%.2f%%)", tab_lisa$CAT_LISA[i],
                                  tab_lisa$n[i], tab_lisa$pct[i]))
write_lines(lisa_log, file.path(DIR_SAIDA, "log_lisa.txt"))

# ============================================================================ #
# 5. Figuras PDF (series temporais e Moran) -----------------------------------
# ============================================================================ #
cat("==> [5/7] Figuras PDF...\n")

# --- 4.1 Série temporal nacional (anual + sazonalidade) --------------------- #
p_anual <- br_anual %>%
  ggplot(aes(x = as.integer(ANO_EPI), y = TI)) +
  geom_line(linewidth = 0.7, colour = "#8B0000") +
  geom_point(size = 1.8, colour = "#8B0000") +
  geom_point(data = br_anual %>% filter(ANO_EPI == "2025"),
             size = 2.6, colour = "#E69F00", shape = 17) +
  scale_x_continuous(breaks = seq(2010, 2025, 1)) +
  scale_y_continuous(labels = lbl_br) +
  labs(x = "Ano", y = "Incidência (casos/100 mil hab.)") +
  TEMA_EDITORIAL

p_sazon <- sazon %>%
  ggplot(aes(x = factor(MES, levels = 1:12, labels = meses_pt), y = CASOS_MED, group = 1)) +
  geom_area(fill = "#F4A582", colour = "#8B0000", linewidth = 0.6, alpha = 0.7) +
  scale_y_continuous(labels = lbl_br) +
  labs(x = "Mês", y = "Casos prováveis (média mensal)") +
  TEMA_EDITORIAL

ggsave(file.path(DIR_SAIDA, "fig_serie_temporal_dengue.pdf"),
       cowplot::plot_grid(p_anual, p_sazon, ncol = 1, labels = c("(a)", "(b)"),
                          label_size = 14, align = "v"),
       width = 6.5, height = 8, device = "pdf")
cat("  salvo: fig_serie_temporal_dengue.pdf\n")

# --- 4.2 Séries por Grande Região ------------------------------------------- #
p_reg <- reg_anual %>%
  left_join(br_anual %>% select(ANO_EPI, TI_BR = TI), by = "ANO_EPI") %>%
  ggplot(aes(x = as.integer(ANO_EPI), y = TI)) +
  geom_line(aes(colour = REGIAO), linewidth = 0.8) +
  geom_line(aes(y = TI_BR), linetype = "dashed", colour = "grey50", linewidth = 0.4) +
  facet_wrap(~ REGIAO, ncol = 2, scales = "free_y") +
  scale_colour_manual(values = c("Norte" = "#1B7837", "Nordeste" = "#7B3294",
                                 "Sudeste" = "#8B0000", "Sul" = "#2C7BB6",
                                 "Centro-Oeste" = "#E69F00")) +
  scale_x_continuous(breaks = seq(2010, 2025, 3)) +
  scale_y_continuous(labels = lbl_br) +
  labs(x = "Ano", y = "Incidência (casos/100 mil hab.)") +
  TEMA_EDITORIAL +
  theme(legend.position = "none")

ggsave(file.path(DIR_SAIDA, "fig_series_regioes.pdf"), p_reg,
       width = 8, height = 7, device = "pdf")
cat("  salvo: fig_series_regioes.pdf\n")

# --- 4.3 Evolução do Índice Global de Moran --------------------------------- #
E_I <- -1 / (nrow(malha) - 1)  # valor esperado sob aleatoriedade
p_moran <- moran_df %>%
  ggplot(aes(x = as.integer(ANO_EPI), y = I)) +
  geom_hline(yintercept = E_I, linetype = "dotted", colour = "grey60", linewidth = 0.5) +
  geom_line(linewidth = 0.7, colour = "#1B7837") +
  geom_point(size = 2, aes(colour = p < 0.05), show.legend = FALSE) +
  scale_colour_manual(values = c("FALSE" = "#1B7837", "TRUE" = "#00441B")) +
  geom_text(aes(label = sprintf("%.3f", I),
                vjust = ifelse(as.integer(ANO_EPI) == 2024, -2.0, -1.1)),
            size = 4.0, fontface = "bold", colour = "grey20") +
  scale_x_continuous(breaks = seq(2010, 2025, 1)) +
  scale_y_continuous(labels = lbl_br,
                     expand = expansion(mult = c(0.05, 0.25))) +
  labs(x = "Ano", y = expression(paste("Índice Global de Moran (", italic(I), ")"))) +
  TEMA_EDITORIAL

ggsave(file.path(DIR_SAIDA, "fig_evolucao_moran.pdf"), p_moran,
       width = 8, height = 4.5, device = "pdf")
cat("  salvo: fig_evolucao_moran.pdf\n")

# --- 4.4 Série temporal longitudinal de boxplots de temperatura (2010-2025) ---
# Série mensal contínua de 192 meses (16 anos x 12 meses: Jan/2010 a Dez/2025).
# Cada caixa resume a distribuicao municipal do indicador termico mensal.
# A fonte atual e mensal; a maxima diaria exige um arquivo diario separado.
cat("==> [4b] Série temporal longitudinal de boxplots de temperatura municipal...\n")
clima_mes <- readRDS("03. Dados/Originais/Dados de temperatura - ERA5_ERA5LAND/processado/clima_mensal_municipal_2010.rds")

if (!"temp_C_max" %in% names(clima_mes)) {
  clima_mes$temp_C_max <- clima_mes$temp_C
  cat("  aviso: usando t2m mensal como proxy de Tmax mensal; fonte diaria ausente\n")
}

box_df <- clima_mes %>%
  filter(!is.na(temp_C_max)) %>%
  mutate(CD_UF = substr(ID_MN_RESI, 1, 2)) %>%
  left_join(uf_regiao, by = "CD_UF") %>%
  mutate(mes = as.Date(mes))

stopifnot(length(unique(box_df$mes)) == 192)

# Versão Facetada: Brasil + 5 Grandes Regiões (6 painéis, grade 3 x 2)
# (fig_serie_boxplot_temperatura.pdf)
box_all <- bind_rows(box_df, box_df %>% mutate(REGIAO = "Brasil")) %>%
  mutate(REGIAO = factor(REGIAO, levels = c("Brasil", "Norte", "Nordeste",
                                            "Sudeste", "Sul", "Centro-Oeste")))

p_box_reg <- ggplot(box_all, aes(x = mes, y = temp_C, group = mes)) +
  geom_boxplot(aes(y = temp_C_max), outlier.shape = NA, fill = "#F4A582",
               colour = "#7F3B08", linewidth = 0.25, alpha = 0.7, width = 20) +
  facet_wrap(~ REGIAO, ncol = 2, scales = "free_y") +
  scale_x_date(breaks = seq(as.Date("2010-01-01"), as.Date("2025-01-01"),
                            by = "3 years"),
               date_labels = "%Y",
               expand = expansion(mult = c(0.01, 0.01))) +
  scale_y_continuous(labels = lbl_br) +
  labs(x = "Ano", y = "Temperatura máxima mensal (°C)") +
  TEMA_EDITORIAL +
  theme(axis.text.x = element_text(angle = 0, hjust = 0.5))

ggsave(file.path(DIR_SAIDA, "fig_serie_boxplot_temperatura.pdf"), p_box_reg,
       width = 8.5, height = 10, device = "pdf")
cat("  salvo: fig_serie_boxplot_temperatura.pdf (Brasil + 5 Grandes Regiões, 6 painéis, 192 meses)\n")

rm(clima_mes, box_df, box_all); gc()

# ============================================================================ #
# 5. Mapas coropléticos municipais (PNG 600 dpi) -------------------------------
# ============================================================================ #
cat("==> [5/7] Mapas coropléticos (600 dpi)...\n")

# Base cartografica: malha harmonizada 2010 em EPSG:5880.

# Mapa 1 - Incidencia acumulada (escala continua, paleta magma).
map_inc <- mun_resumo %>%
  left_join(malha_plot %>% select(ID_MN_RESI, geometry), by = "ID_MN_RESI") %>%
  st_as_sf()

# Quebras fixas para manter a leitura cartografica comparavel ao longo das
# execucoes e destacar os municipios nos extremos do gradiente.
brks_inc <- c(0, 20000, 40000, 60000, 80000, 92157)

p_inc <- ggplot(map_inc) +
  geom_sf(aes(fill = TI_ACUM), colour = "grey70", linewidth = 0.03) +
  geom_sf(data = estados, fill = NA, colour = "grey25", linewidth = 0.25) +
  annotation_scale(location = "br", width_hint = 0.20,
                   text_col = "grey25", bar_cols = c("grey30", "grey80"),
                   height = unit(0.20, "cm"), text_cex = 0.75, text_family = "serif",
                   pad_x = unit(0.2, "cm"), pad_y = unit(0.2, "cm")) +
  annotation_north_arrow(location = "tr", which_north = "true",
                         style = north_arrow_fancy_orienteering,
                         height = unit(0.9, "cm"), width = unit(0.9, "cm"),
                         pad_x = unit(0.2, "cm"), pad_y = unit(0.2, "cm")) +
  escala_continua(map_inc$TI_ACUM, viridisLite::magma(200, direction = -1),
                  "Incidência acumulada\n(casos/100 mil hab.)", 0,
                  breaks = brks_inc) +
  TEMA_CARTO

ggsave(file.path(DIR_SAIDA, "fig_mapa_incidencia_acumulada.png"), p_inc,
       width = 7.0, height = 6.2, dpi = 600, bg = "white")
cat("  salvo: fig_mapa_incidencia_acumulada.png (continuo, magma)\n")

# Mapas 2-4 - clima municipal.
clima_mun <- dataset %>%
  group_by(ID_MN_RESI) %>%
  summarise(TEMP_MAX = mean(temp_C_max),
            UMID = mean(umid_rel_media),
            PRECIP = mean(precip_mm_acum), .groups = "drop") %>%
  left_join(malha_plot %>% select(ID_MN_RESI, geometry), by = "ID_MN_RESI") %>%
  st_as_sf()

# Mapa 2 - temperatura maxima mensal disponivel.
p_temp <- ggplot(clima_mun) +
  geom_sf(aes(fill = TEMP_MAX), colour = "grey40", linewidth = 0.03) +
  geom_sf(data = estados, fill = NA, colour = "grey25", linewidth = 0.25) +
  annotation_scale(location = "br", width_hint = 0.20,
                   text_col = "grey25", bar_cols = c("grey30", "grey80"),
                   height = unit(0.20, "cm"), text_cex = 0.75, text_family = "serif",
                   pad_x = unit(0.2, "cm"), pad_y = unit(0.2, "cm")) +
  annotation_north_arrow(location = "tr", which_north = "true",
                         style = north_arrow_fancy_orienteering,
                         height = unit(0.9, "cm"), width = unit(0.9, "cm"),
                         pad_x = unit(0.2, "cm"), pad_y = unit(0.2, "cm")) +
  escala_continua(clima_mun$TEMP_MAX, sequential_hcl(200, "YlOrRd", rev = TRUE),
                  "Temperatura máxima mensal\n(°C)", 1) +
  TEMA_CARTO

ggsave(file.path(DIR_SAIDA, "fig_mapa_temperatura.png"), p_temp,
       width = 7.0, height = 6.2, dpi = 600, bg = "white")
cat("  salvo: fig_mapa_temperatura.png (continuo, YlOrRd)\n")

# Mapa 3 - Precipitação média anual (escala contínua, Blues 3)
p_precip <- ggplot(clima_mun) +
  geom_sf(aes(fill = PRECIP), colour = "grey40", linewidth = 0.03) +
  geom_sf(data = estados, fill = NA, colour = "grey25", linewidth = 0.25) +
  annotation_scale(location = "br", width_hint = 0.20,
                   text_col = "grey25", bar_cols = c("grey30", "grey80"),
                   height = unit(0.20, "cm"), text_cex = 0.75, text_family = "serif",
                   pad_x = unit(0.2, "cm"), pad_y = unit(0.2, "cm")) +
  annotation_north_arrow(location = "tr", which_north = "true",
                         style = north_arrow_fancy_orienteering,
                         height = unit(0.9, "cm"), width = unit(0.9, "cm"),
                         pad_x = unit(0.2, "cm"), pad_y = unit(0.2, "cm")) +
  escala_continua(clima_mun$PRECIP, sequential_hcl(200, "Blues 3", rev = TRUE),
                  "Precipitação acumulada\n(mm/ano)", 0) +
  TEMA_CARTO

ggsave(file.path(DIR_SAIDA, "fig_mapa_precipitacao.png"), p_precip,
       width = 7.0, height = 6.2, dpi = 600, bg = "white")
cat("  salvo: fig_mapa_precipitacao.png (contínuo, Blues 3)\n")

# Mapa 4 - Umidade relativa média (escala contínua, GnBu)
p_umid <- ggplot(clima_mun) +
  geom_sf(aes(fill = UMID), colour = "grey40", linewidth = 0.03) +
  geom_sf(data = estados, fill = NA, colour = "grey25", linewidth = 0.25) +
  annotation_scale(location = "br", width_hint = 0.20,
                   text_col = "grey25", bar_cols = c("grey30", "grey80"),
                   height = unit(0.20, "cm"), text_cex = 0.75, text_family = "serif",
                   pad_x = unit(0.2, "cm"), pad_y = unit(0.2, "cm")) +
  annotation_north_arrow(location = "tr", which_north = "true",
                         style = north_arrow_fancy_orienteering,
                         height = unit(0.9, "cm"), width = unit(0.9, "cm"),
                         pad_x = unit(0.2, "cm"), pad_y = unit(0.2, "cm")) +
  escala_continua(clima_mun$UMID, sequential_hcl(200, "GnBu", rev = TRUE),
                  "Umidade relativa\nmédia (%)", 0) +
  TEMA_CARTO

ggsave(file.path(DIR_SAIDA, "fig_mapa_umidade.png"), p_umid,
       width = 7.0, height = 6.2, dpi = 600, bg = "white")
cat("  salvo: fig_mapa_umidade.png (contínuo, GnBu)\n")

# Mapa 5 - Persistência epidêmica (variável DISCRETA de 0 a 16 anos)
# 17 níveis (0..16) mapeados diretamente como fator; paleta sequencial Magma
# (17 cores: roxo escuro/preto = 0 ano; amarelo claro = 16 anos); legenda
# discreta ordenada com 16 no topo e 0 na base (reverse = TRUE).
map_pers <- persist %>%
  left_join(malha_plot %>% select(ID_MN_RESI, geometry), by = "ID_MN_RESI") %>%
  st_as_sf()

# Variável discreta: contagem inteira de anos epidêmicos como fator (0..16)
map_pers$FAIXA_EPI <- factor(map_pers$ANOS_EPI, levels = 0:16,
                             labels = as.character(0:16))
# Paleta magma autentica com 17 cores discretas, uma por ano (0 a 16):
# direction = -1 faz 0 anos receber o amarelo claro da extremidade clara e
# 16 anos o roxo escuro da extremidade escura da rampa.
pal_pers17 <- setNames(viridisLite::magma(17, direction = -1),
                       as.character(0:16))

p_pers <- ggplot(map_pers) +
  geom_sf(aes(fill = FAIXA_EPI), colour = "grey70", linewidth = 0.03) +
  geom_sf(data = estados, fill = NA, colour = "grey25", linewidth = 0.3) +
  annotation_scale(location = "br", width_hint = 0.20,
                   text_col = "grey25", bar_cols = c("grey30", "grey80"),
                   height = unit(0.20, "cm"), text_cex = 0.75, text_family = "serif",
                   pad_x = unit(0.2, "cm"), pad_y = unit(0.2, "cm")) +
  annotation_north_arrow(location = "tr", which_north = "true",
                         style = north_arrow_fancy_orienteering,
                         height = unit(0.9, "cm"), width = unit(0.9, "cm"),
                         pad_x = unit(0.2, "cm"), pad_y = unit(0.2, "cm")) +
  scale_fill_manual(
    values = pal_pers17,
    name   = "Anos epidêmicos\n(TI > 300/100 mil)",
    drop   = FALSE,
    guide  = guide_legend(
      ncol        = 2,
      byrow       = FALSE,
       reverse     = FALSE,         # Coluna 1 = 0..8; coluna 2 = 9..16
      keyheight   = unit(0.28, "cm"),
      keywidth    = unit(0.35, "cm"),
      title.hjust = 0
    )
  ) +
  TEMA_CARTO +
  theme(
    legend.title = element_text(size = 10.5, face = "bold", family = "serif", lineheight = 1.15),
    legend.spacing.x = unit(0.45, "cm"),
    legend.text  = element_text(size = 8.5, family = "serif",
                                margin = margin(r = 0.25, unit = "cm"))
  )

ggsave(file.path(DIR_SAIDA, "fig_mapa_persistencia_epidemica.png"), p_pers,
       width = 7.0, height = 6.2, dpi = 600, bg = "white")
cat("  salvo: fig_mapa_persistencia_epidemica.png (discreto 0-16 anos, Magma, 17 níveis)\n")

# ============================================================================ #
# 6. Mapa das Grandes Regioes --------------------------------------------------
# ============================================================================ #
regioes_br <- st_read(file.path("03. Dados", "Originais", "Malhas",
                               "BR_Regioes_2025.shp"), quiet = TRUE) %>%
  st_transform(5880)
ufs_br <- st_read(file.path("03. Dados", "Originais", "Malhas",
                           "BR_UF_2025.shp"), quiet = TRUE) %>%
  st_transform(5880)
cores_regioes <- c("Norte" = "#8FC79B", "Nordeste" = "#E89B5F",
                   "Centro-oeste" = "#D4A837", "Sudeste" = "#C75B9E",
                   "Sul" = "#B695C2")
p_regioes <- ggplot() +
  geom_sf(data = regioes_br, aes(fill = NM_REGIAO), colour = NA) +
  geom_sf(data = ufs_br, fill = NA, colour = "white", linewidth = 0.3) +
  geom_sf(data = regioes_br, fill = NA, colour = "grey30", linewidth = 0.5) +
  scale_fill_manual(values = cores_regioes, name = "Grandes Regiões",
                    drop = FALSE) +
  annotation_north_arrow(location = "tr", which_north = "true",
                         style = north_arrow_fancy_orienteering,
                         height = unit(0.9, "cm"), width = unit(0.9, "cm"),
                         pad_x = unit(0.2, "cm"), pad_y = unit(0.2, "cm")) +
  annotation_scale(location = "br", width_hint = 0.20, text_col = "grey25",
                   bar_cols = c("grey30", "grey80"), height = unit(0.20, "cm"),
                   text_cex = 0.75, text_family = "serif", pad_x = unit(0.2, "cm"),
                   pad_y = unit(0.2, "cm")) +
  coord_sf(datum = st_crs(5880)) + TEMA_CARTO
ggsave(file.path(DIR_SAIDA, "fig_mapa_grandes_regioes.png"), p_regioes,
       width = 7.0, height = 6.2, dpi = 600, bg = "white")

# ============================================================================ #
# 7. Tabelas LaTeX -------------------------------------------------------------
# ============================================================================ #
cat("==> [6/7] Tabelas LaTeX...\n")

medidas <- function(x) {
  c(Media = mean(x), DP = sd(x), Mediana = median(x),
    IIQ = IQR(x), Min = min(x), Max = max(x))
}

grupos_rot <- list(Brasil = NULL, Norte = "Norte", Nordeste = "Nordeste",
                   Sudeste = "Sudeste", Sul = "Sul", CO = "Centro-Oeste")

linha_medidas <- function(vars) {
  out <- character()
  for (v in vars) {
    out <- c(out, sprintf("\\multicolumn{7}{l}{\\textbf{%s}} \\\\", attr(v, "label")))
    # Média (D.P.)
    cel <- sapply(grupos_rot, function(g) {
      m <- if (is.null(g)) medidas(dataset[[v]]) else medidas(dataset[[v]][dataset$REGIAO == g])
      sprintf("%s (%s)", fmt_br(m["Media"]), fmt_br(m["DP"]))
    })
    out <- c(out, sprintf("Média (D.P.) & %s \\\\", paste(cel, collapse = " & ")))
    # Mediana (IIQ)
    cel <- sapply(grupos_rot, function(g) {
      m <- if (is.null(g)) medidas(dataset[[v]]) else medidas(dataset[[v]][dataset$REGIAO == g])
      sprintf("%s (%s)", fmt_br(m["Mediana"]), fmt_br(m["IIQ"]))
    })
    out <- c(out, sprintf("Mediana (IIQ) & %s \\\\", paste(cel, collapse = " & ")))
    # Mínimo–Máximo
    cel <- sapply(grupos_rot, function(g) {
      m <- if (is.null(g)) medidas(dataset[[v]]) else medidas(dataset[[v]][dataset$REGIAO == g])
      sprintf("%s – %s", fmt_br(m["Min"]), fmt_br(m["Max"]))
    })
    out <- c(out, sprintf("Mínimo–Máximo & %s \\\\", paste(cel, collapse = " & ")))
    out <- c(out, "\\addlinespace[0.3em]")
  }
  out
}

# ---- Tabelas 3-5 com kableExtra ---------------------------------------------- #
# Ajuste de largura: scale_down + hold_position + font_size 9; cabeçalhos por
# extenso (inclusive "Centro-Oeste", sem abreviações).

monta_df_medidas <- function(vars) {
  df_list <- list(); nomes <- character()
  for (v in vars) {
    cel_grupo <- function(g) {
      m <- if (is.null(g)) medidas(dataset[[v]]) else medidas(dataset[[v]][dataset$REGIAO == g])
      c(sprintf("%s (%s)", fmt_br(m["Media"]), fmt_br(m["DP"])),
        sprintf("%s (%s)", fmt_br(m["Mediana"]), fmt_br(m["IIQ"])),
        sprintf("%s – %s", fmt_br(m["Min"]), fmt_br(m["Max"])))
    }
    df_list[[length(df_list) + 1]] <- data.frame(
      Medida = c("Média (D.P.)", "Mediana (IIQ)", "Mínimo–Máximo"),
      Brasil = cel_grupo(NULL), Norte = cel_grupo("Norte"),
      Nordeste = cel_grupo("Nordeste"), Sudeste = cel_grupo("Sudeste"),
      Sul = cel_grupo("Sul"), CentroOeste = cel_grupo("Centro-Oeste"),
      check.names = FALSE, stringsAsFactors = FALSE)
    nomes <- c(nomes, rep(attr(v, "label"), 3))
  }
  list(df = bind_rows(df_list), grupos = nomes)
}

exporta_kable <- function(df, col_nomes, labels_grupos = NULL,
                          caption = NULL, label = NULL) {
  k <- kable(df, format = "latex", booktabs = TRUE, escape = FALSE,
             col.names = col_nomes, align = c("l", rep("c", ncol(df) - 1)),
             caption = caption, label = label)
  if (!is.null(labels_grupos)) k <- pack_rows(k, index = labels_grupos)
  k <- kable_styling(k, latex_options = c("scale_down", "hold_position"),
                     font_size = 9)
  as.character(k)
}

colunas_regioes <- c("Medida", "Brasil", "Norte", "Nordeste", "Sudeste", "Sul",
                     "Centro-Oeste")

# 6.1 Socioespacial (Censo 2022)
vars_socio <- list(
  structure("prop_agua_rede", label = "Abastecimento de água por rede geral (%)"),
  structure("prop_esgoto_rede", label = "Esgotamento sanitário por rede (%)"),
  structure("prop_lixo_coletado", label = "Coleta de lixo (%)"),
  structure("prop_pop_favela", label = "População em favelas (%)"),
  structure("dens_demografica_2022", label = "Densidade demográfica (hab/km²)"))
socio_md <- monta_df_medidas(vars_socio)
tex_socio <- exporta_kable(socio_md$df, colunas_regioes,
                           setNames(rep(3, length(vars_socio)), sapply(vars_socio, attr, "label")),
                            caption = "Medidas-resumo das variáveis socioespaciais por Grande Região (Censo 2022).",
                           label = "resumo_socioespacial")
write_lines(tex_socio, file.path(DIR_SAIDA, "tabela_resumo_socioespacial.tex"))

# 6.2 Clima
vars_clima <- list(
  structure("temp_C_max", label = "Temperatura máxima mensal (°C)"),
  structure("umid_rel_media", label = "Umidade relativa média (%)"),
  structure("precip_mm_acum", label = "Precipitação anual acumulada (mm)"))
clima_md <- monta_df_medidas(vars_clima)
tex_clima <- exporta_kable(clima_md$df, colunas_regioes,
                           setNames(rep(3, length(vars_clima)), sapply(vars_clima, attr, "label")),
                            caption = "Medidas-resumo das variáveis climáticas por Grande Região, Brasil, 2010--2025.",
                           label = "resumo_clima")
write_lines(tex_clima, file.path(DIR_SAIDA, "tabela_resumo_clima.tex"))

# 6.3 Estratificação de risco (Ministério da Saúde)
ord_estrato <- c("Baixa", "Média", "Alta")
estr_df <- data.frame(Estrato = ord_estrato, stringsAsFactors = FALSE)
for (g in names(grupos_rot)) {
  estr_df[[g]] <- sapply(ord_estrato, function(e) {
    sub <- if (is.null(grupos_rot[[g]])) estrato_reg else estrato_reg %>% filter(REGIAO == grupos_rot[[g]])
    n <- sum(sub$n[sub$ESTRATO == e]); tot <- sum(sub$n)
    sprintf("%s (%.1f\\%%)", fmt_br(n, 0), 100 * n / tot)
  })
}
tex_estr <- exporta_kable(estr_df, c("Estrato", colunas_regioes[-1]),
                            caption = "Distribuição dos municípios por estrato de risco e Grande Região, Brasil, 2010--2025.",
                            label = "estratificacao_risco")
write_lines(tex_estr, file.path(DIR_SAIDA, "tabela_estratificacao_risco.tex"))

# 6.4 Perfil demográfico
n_obitos <- sum(dataset$NU_OBITOS)
letalid <- 100 * n_obitos / tot_casos_perfil
ord_fx <- c("0 a 4", "5 a 9", "10 a 14", "15 a 19", "20 a 39", "40 a 59",
            "60 ou mais", "Ignorado")
pct_fx_ord <- pct_fx %>% mutate(FX = factor(FX, levels = ord_fx)) %>% arrange(FX)
tex_perf <- c(
  "\\begin{tabular}{lc}",
  "\\toprule",
  "\\textbf{Indicador} & \\textbf{Valor} \\\\",
  "\\midrule",
  sprintf("Total de casos prováveis & %s \\\\", fmt_br(tot_casos_perfil, 0)),
  sprintf("\\addlinespace[0.2em] \\multicolumn{2}{l}{\\textbf{Sexo (\\%%)}} \\\\"),
  sprintf("Feminino & %s \\\\", fmt_br(pct_sexo$pct[pct_sexo$SEXO == "F"], 1)),
  sprintf("Masculino & %s \\\\", fmt_br(pct_sexo$pct[pct_sexo$SEXO == "M"], 1)),
  sprintf("Ignorado & %s \\\\", fmt_br(sum(pct_sexo$pct[pct_sexo$SEXO == "I"]), 1)),
  sprintf("\\addlinespace[0.2em] \\multicolumn{2}{l}{\\textbf{Faixa etária (\\%%)}} \\\\"))
for (i in seq_len(nrow(pct_fx_ord))) {
  tex_perf <- c(tex_perf, sprintf("%s & %s \\\\", as.character(pct_fx_ord$FX[i]), fmt_br(pct_fx_ord$pct[i], 1)))
}
tex_perf <- c(tex_perf,
  sprintf("\\addlinespace[0.2em] Óbitos & %s \\\\", fmt_br(n_obitos, 0)),
  sprintf("Letalidade (\\%%) & %s \\\\", fmt_br(letalid, 2)),
  "\\bottomrule", "\\end{tabular}")
write_lines(tex_perf, file.path(DIR_SAIDA, "tabela_perfil_demografico.tex"))

# ============================================================================ #
# 7. Macros dinâmicas e log ----------------------------------------------------
# ============================================================================ #
cat("==> [7/7] Macros e log...\n")

ti_reg <- dataset %>% group_by(REGIAO) %>%
  summarise(TI = sum(CASOS_PROV) / sum(POP) * 1e5, .groups = "drop")

# Base para proporcoes socioespaciais: ano 2022 (Censo), ponderacao pelo
# NUMERO DE DOMICILIOS nas variaveis de domicilios (agua/esgoto/lixo) e pela
# POPULACAO nas metricas populacionais (favela/densidade) -- coerente com o
# log de auditoria do script 01 (weighted.mean por dom_total).
censo_2022 <- dataset %>% filter(ANO_EPI == "2022")
pond_dom <- function(v) weighted.mean(censo_2022[[v]], censo_2022$dom_total)
pond_pop <- function(v) weighted.mean(censo_2022[[v]], censo_2022$POP)
media_mun <- function(v) mean(censo_2022[[v]])

macro <- c(
  "% Macros dinâmicas geradas por 04_analises_descritivas.R - nao editar manualmente",
  sprintf("\\newcommand{\\NumMunicipios}{%s}", fmt_br(5564, 0)),
  sprintf("\\newcommand{\\PeriodoEstudo}{2010--2025}"),
  sprintf("\\newcommand{\\TotalCasosProvaveis}{%s}", fmt_br(tot_casos_perfil, 0)),
  sprintf("\\newcommand{\\TotalObitos}{%s}", fmt_br(n_obitos, 0)),
  sprintf("\\newcommand{\\Letalidade}{%s\\%%}", fmt_br(letalid, 2)),
  sprintf("\\newcommand{\\TIAccumBrasil}{%s}", fmt_br(sum(mun_resumo$CASOS) / sum(mun_resumo$POP) * 1e5, 1)),
  sprintf("\\newcommand{\\CasosDoisMilVinteQuatro}{%s}", fmt_br(br_anual$CASOS[br_anual$ANO_EPI == "2024"], 0)),
  sprintf("\\newcommand{\\TIDoisMilVinteQuatro}{%s}", fmt_br(br_anual$TI[br_anual$ANO_EPI == "2024"], 1)),
  sprintf("\\newcommand{\\CasosDoisMilVinteCinco}{%s}", fmt_br(br_anual$CASOS[br_anual$ANO_EPI == "2025"], 0)),
  sprintf("\\newcommand{\\PctSexoFeminino}{%s\\%%}", fmt_br(pct_sexo$pct[pct_sexo$SEXO == "F"], 1)),
  sprintf("\\newcommand{\\PctSexoMasculino}{%s\\%%}", fmt_br(pct_sexo$pct[pct_sexo$SEXO == "M"], 1)),
  sprintf("\\newcommand{\\PctFaixaZeroAQuatro}{%s\\%%}", fmt_br(pct_fx_ord$pct[which(pct_fx_ord$FX == "0 a 4")], 1)),
  sprintf("\\newcommand{\\PctFaixaVinteATrintaNove}{%s\\%%}", fmt_br(pct_fx_ord$pct[which(pct_fx_ord$FX == "20 a 39")], 1)),
  sprintf("\\newcommand{\\PctFaixaSessentaMais}{%s\\%%}", fmt_br(pct_fx_ord$pct[which(pct_fx_ord$FX == "60 ou mais")], 1)),
  sprintf("\\newcommand{\\TempMaxBrasil}{%s\\textdegree C}", fmt_br(weighted.mean(dataset$temp_C_max, dataset$POP), 1)),
  sprintf("\\newcommand{\\UmidMediaBrasil}{%s\\%%}", fmt_br(weighted.mean(dataset$umid_rel_media, dataset$POP), 1)),
  sprintf("\\newcommand{\\PrecipAnualBrasil}{%s mm}", fmt_br(weighted.mean(dataset$precip_mm_acum, dataset$POP), 0)),
  sprintf("\\newcommand{\\PropAguaRedeBrasil}{%s\\%%}", fmt_br(pond_dom("prop_agua_rede"), 1)),
  sprintf("\\newcommand{\\PropEsgotoRedeBrasil}{%s\\%%}", fmt_br(pond_dom("prop_esgoto_rede"), 1)),
  sprintf("\\newcommand{\\PropLixoBrasil}{%s\\%%}", fmt_br(pond_dom("prop_lixo_coletado"), 1)),
  sprintf("\\newcommand{\\PropFavelaBrasil}{%s\\%%}", fmt_br(pond_pop("prop_pop_favela"), 1)),
  sprintf("\\newcommand{\\MediaMunAgua}{%s\\%%}", fmt_br(media_mun("prop_agua_rede"), 1)),
  sprintf("\\newcommand{\\MediaMunEsgoto}{%s\\%%}", fmt_br(media_mun("prop_esgoto_rede"), 1)),
  sprintf("\\newcommand{\\MediaMunLixo}{%s\\%%}", fmt_br(media_mun("prop_lixo_coletado"), 1)),
  sprintf("\\newcommand{\\MediaMunFavela}{%s\\%%}", fmt_br(media_mun("prop_pop_favela"), 1)),
  sprintf("\\newcommand{\\PctMunAltoRisco}{%s\\%%}",
          fmt_br(100 * sum(estrato_reg$n[estrato_reg$ESTRATO == "Alta"]) / sum(estrato_reg$n), 1)),
  sprintf("\\newcommand{\\PctMunMedioRisco}{%s\\%%}",
          fmt_br(100 * sum(estrato_reg$n[estrato_reg$ESTRATO == "Média"]) / sum(estrato_reg$n), 1)),
  sprintf("\\newcommand{\\PctMunBaixoRisco}{%s\\%%}",
          fmt_br(100 * sum(estrato_reg$n[estrato_reg$ESTRATO == "Baixa"]) / sum(estrato_reg$n), 1)),
  sprintf("\\newcommand{\\PctMunPersistencia}{%s\\%%}",
          fmt_br(100 * mean(persist$ANOS_EPI >= 10), 1)),
  sprintf("\\newcommand{\\MoranMin}{%s}", fmt_br(min(moran_df$I), 3)),
  sprintf("\\newcommand{\\MoranMax}{%s}", fmt_br(max(moran_df$I), 3)),
  sprintf("\\newcommand{\\MoranDoisMilVinteQuatro}{%s}", fmt_br(moran_df$I[moran_df$ANO_EPI == "2024"], 3)),
  sprintf("\\newcommand{\\TIRegiaoCentroOeste}{%s}", fmt_br(ti_reg$TI[ti_reg$REGIAO == "Centro-Oeste"], 1)),
  sprintf("\\newcommand{\\TIRegiaoSudeste}{%s}", fmt_br(ti_reg$TI[ti_reg$REGIAO == "Sudeste"], 1)),
  sprintf("\\newcommand{\\TIRegiaoSul}{%s}", fmt_br(ti_reg$TI[ti_reg$REGIAO == "Sul"], 1)),
  sprintf("\\newcommand{\\TIRegiaoNordeste}{%s}", fmt_br(ti_reg$TI[ti_reg$REGIAO == "Nordeste"], 1)),
  sprintf("\\newcommand{\\TIRegiaoNorte}{%s}", fmt_br(ti_reg$TI[ti_reg$REGIAO == "Norte"], 1))
)
write_lines(macro, file.path(DIR_SAIDA, "macros_descritivas.tex"))

# ---- Log -------------------------------------------------------------------- #
log <- c(log,
  sprintf("total_casos_prov_2010_2025=%.0f", tot_casos_perfil),
  sprintf("total_obitos=%.0f", n_obitos),
  sprintf("letalidade_pct=%.2f", letalid),
  sprintf("pct_sexo_F=%.2f", pct_sexo$pct[pct_sexo$SEXO == "F"]),
  sprintf("pct_sexo_M=%.2f", pct_sexo$pct[pct_sexo$SEXO == "M"]),
  sprintf("moran_2024=%.4f", moran_df$I[moran_df$ANO_EPI == "2024"]),
  sprintf("moran_min=%.4f", min(moran_df$I)),
  sprintf("moran_max=%.4f", max(moran_df$I)),
  sprintf("incidencia=taxa acumulada 2010-2025; denominador=populacao media do periodo"),
  sprintf("tmax=ma maxima mensal de t2m mensal; fonte diaria ausente"),
  sprintf("pct_mun_alto_risco=%.2f", 100 * sum(estrato_reg$n[estrato_reg$ESTRATO == "Alta"]) / sum(estrato_reg$n)),
  sprintf("pct_mun_persistencia_10mais=%.2f", 100 * mean(persist$ANOS_EPI >= 10)))
for (i in seq_len(nrow(moran_df)))
  log <- c(log, sprintf("moran_%s=%.4f (p=%.4g)", moran_df$ANO_EPI[i], moran_df$I[i], moran_df$p[i]))
write_lines(log, file.path(DIR_SAIDA, "log_auditoria_descritivas.txt"))

cat("\n--- LOG (DESCRITIVAS) ---\n"); cat(log, sep = "\n")
cat("\nArtefatos em 05. Saídas/:\n")
print(sort(list.files(DIR_SAIDA, pattern = "fig_|tabela_|macros_")))
