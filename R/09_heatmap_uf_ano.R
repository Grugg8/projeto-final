# ============================================================================ #
# 09_heatmap_uf_ano.R
# Heatmap da taxa de incidencia de dengue por UF e ano, 2010-2025.
# Le o dataset como esta em disco e gera figura, macros e dados.
# Nao altera o dataset.
# ============================================================================ #

# ---- 0. Setup -------------------------------------------------------------- #
suppressPackageStartupMessages({
  library(dplyr); library(readr); library(ggplot2); library(scales)
})
if (requireNamespace("showtext", quietly = TRUE)) {
  library(showtext)
  showtext::showtext_auto(FALSE)
}
FAMILIA_FONTE <- "serif"
theme_set(theme_classic(base_size = 14, base_family = FAMILIA_FONTE))

here::i_am("R/09_heatmap_uf_ano.R")
DIR_FIGURAS <- here::here("output", "figures")
DIR_TABELAS <- here::here("output", "tables")
DIR_MACROS <- here::here("output", "macros")
for (diretorio in c(DIR_FIGURAS, DIR_TABELAS, DIR_MACROS))
  dir.create(diretorio, showWarnings = FALSE, recursive = TRUE)

# Wrapper do ggsave: grava em arquivo temporario (mantendo a extensao) e
# renomeia ao final, evitando o "write failed" do dev.off() no macOS.
ggsave <- function(filename, ...) {
  ext <- tools::file_ext(filename)
  tmp <- sub(paste0("\\.", ext, "$"), paste0(".tmp-", Sys.getpid(), ".", ext), filename)
  ggplot2::ggsave(tmp, ...)
  if (file.exists(filename)) unlink(filename)
  if (!file.rename(tmp, filename)) stop("falha ao renomear ", tmp, " para ", filename)
  invisible(filename)
}

# Padrao numerico brasileiro
fmt_br <- function(x, d = 1) formatC(x, format = "f", digits = d,
                                     big.mark = ".", decimal.mark = ",")
lbl_br <- label_number(big.mark = ".", decimal.mark = ",")

# Estilo editorial: eixos pretos finos, sem fundo
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

# ---- 1. Agregacao UF x ano ------------------------------------------------- #
# TI de UF recalculada aqui: soma casos e pop dos municipios, depois divide.
dataset <- readRDS(here::here("data", "processed", "dataset_tcc_consolidado.rds"))

uf_sigla <- c("11" = "RO", "12" = "AC", "13" = "AM", "14" = "RR",
  "15" = "PA", "16" = "AP", "17" = "TO", "21" = "MA", "22" = "PI",
  "23" = "CE", "24" = "RN", "25" = "PB", "26" = "PE", "27" = "AL",
  "28" = "SE", "29" = "BA", "31" = "MG", "32" = "ES", "33" = "RJ",
  "35" = "SP", "41" = "PR", "42" = "SC", "43" = "RS", "50" = "MS",
  "51" = "MT", "52" = "GO", "53" = "DF")
ordem_cd <- names(uf_sigla)  # ja em ordem Norte -> Sul
ordem_sigla <- unname(uf_sigla[ordem_cd])

uf_ano <- dataset %>%
  group_by(CD_UF, ANO_EPI) %>%
  summarise(CASOS = sum(CASOS_PROV), POP = sum(POP), .groups = "drop") %>%
  mutate(TI = CASOS / POP * 1e5,
         SIGLA = unname(uf_sigla[CD_UF]),
         # Norte no topo: inverte a ordem no eixo y
         SIGLA = factor(SIGLA, levels = rev(ordem_sigla)),
         ANO_EPI = as.integer(as.character(ANO_EPI))) %>%
  filter(!is.na(SIGLA), !is.na(ANO_EPI), TI > 0) %>%
  arrange(CD_UF, ANO_EPI)

ti_min <- min(uf_ano$TI, na.rm = TRUE)
ti_max <- max(uf_ano$TI, na.rm = TRUE)
lin_max <- uf_ano %>% slice_max(TI, n = 1)
lin_min <- uf_ano %>% slice_min(TI, n = 1)

cat(sprintf("TI UF-ano: min=%.2f (%s %d) | max=%.1f (%s %d) | n=%d\n",
  ti_min, as.character(lin_min$SIGLA), lin_min$ANO_EPI,
  ti_max, as.character(lin_max$SIGLA), lin_max$ANO_EPI, nrow(uf_ano)))

# ---- 2. Heatmap ------------------------------------------------------------ #
# Escala log10: a TI vai de menos de 1 a quase 9 mil, e a escala linear
# achata tudo num canto so.
# Escala: minimo e maximo entram obrigatoriamente e os intermediarios sao
# equiespacados na escala em uso (log10). A regra dos rotulos equiespacados NO
# VALOR, adotada nos mapas de escala linear, deixaria os quatro rotulos
# superiores a menos de 1 mm de distancia visual na barra logaritmica; aqui o
# equivalente geometrico e a progressao entre ti_min e ti_max.
brks <- 10^seq(log10(ti_min), log10(ti_max), length.out = 5)

p <- ggplot(uf_ano, aes(x = ANO_EPI, y = SIGLA, fill = TI)) +
  geom_tile(colour = "white", linewidth = 0.2) +
  scale_x_continuous(breaks = sort(unique(uf_ano$ANO_EPI)), expand = c(0, 0)) +
  scale_fill_gradientn(
    colours = viridisLite::magma(200, direction = -1),
    trans = "log10",
    limits = c(ti_min, ti_max),
    breaks = brks,
    labels = function(x) ifelse(x < 10, fmt_br(x, 1), fmt_br(x, 0)),
    name = "TI (/100 mil)",
    guide = GUIDE_BAR_COMPACTO
  ) +
  labs(x = "Ano", y = "UF") +
  TEMA_EDITORIAL +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 10),
        axis.text.y = element_text(size = 10))

ggsave(file.path(DIR_FIGURAS, "fig_heatmap_incidencia_uf_ano.pdf"), p,
       width = 8.5, height = 7.5, device = "pdf")
cat("  salvo: fig_heatmap_incidencia_uf_ano.pdf\n")

# ---- 3. Dados e macros ------------------------------------------------------ #
write_tsv(uf_ano %>% select(CD_UF, SIGLA, ANO_EPI, CASOS, POP, TI) %>% arrange(CD_UF, ANO_EPI),
          file.path(DIR_TABELAS, "dados_heatmap_uf_ano.tsv"))
cat("  salvo: dados_heatmap_uf_ano.tsv\n")

mac <- c(
  "% Macros geradas por 09_heatmap_uf_ano.R - nao editar manualmente",
  sprintf("\\newcommand{\\TIMaxUF}{%s}", as.character(lin_max$SIGLA)),
  sprintf("\\newcommand{\\TIMaxUFAno}{%d}", lin_max$ANO_EPI),
  sprintf("\\newcommand{\\TIMaxTI}{%s}", fmt_br(lin_max$TI, 1)),
  sprintf("\\newcommand{\\TIMinUF}{%s}", as.character(lin_min$SIGLA)),
  sprintf("\\newcommand{\\TIMinUFAno}{%d}", lin_min$ANO_EPI),
  sprintf("\\newcommand{\\TIMinTI}{%s}", fmt_br(lin_min$TI, 1))
)
write_lines(mac, file.path(DIR_MACROS, "macros_heatmap_uf.tex"))
cat("  salvo: macros_heatmap_uf.tex\n")
