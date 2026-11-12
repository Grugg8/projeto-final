# Legenda quantitativa do painel de RR da defesa; os mapas originais são preservados.
# Executar a partir da raiz do projeto.
suppressPackageStartupMessages({library(ggplot2); library(cowplot); library(viridisLite)})
here::i_am("R/14_gerar_legenda_rr_slides.R")
DIR_FIGURAS <- here::here("output", "figures")
DIR_LOGS <- here::here("output", "logs")
DIR_MODELOS <- here::here("output", "models")
for (diretorio in c(DIR_FIGURAS, DIR_LOGS, DIR_MODELOS))
  dir.create(diretorio, showWarnings = FALSE, recursive = TRUE)
arquivos <- c(file.path(DIR_MODELOS, "resultado_satscan_acum.rds"), file.path(DIR_MODELOS, "resultado_satscan_termica.rds"))
limite <- max(vapply(arquivos, function(f) max(readRDS(f)$rr$REL_RISK), numeric(1)))
stopifnot(is.finite(limite), limite > 1)
quebras <- seq(1, limite, length.out = 5)
p <- ggplot(data.frame(x = c(1, 2), y = 1, rr = c(1, limite)), aes(x, y, fill = rr)) +
  geom_tile() +
  scale_fill_gradientn(colours = magma(200, direction = -1), limits = c(1, limite),
    breaks = quebras,
    labels = function(x) formatC(x, format = "f", digits = 1, big.mark = ".", decimal.mark = ","),
    name = "Risco relativo municipal (escala comum)",
    guide = guide_colorbar(direction = "horizontal", title.position = "top",
      title.hjust = 0.5, barwidth = grid::unit(12, "cm"), barheight = grid::unit(0.24, "cm"))) +
  theme_void(base_family = "serif") +
  theme(legend.position = "bottom", legend.title = element_text(size = 10),
        legend.text = element_text(size = 9), legend.margin = margin(0, 0, 0, 0))
legenda <- cowplot::get_legend(p)
destino <- file.path(DIR_FIGURAS, "legenda_rr_slides_puro_calor.pdf")
tmp <- tempfile(pattern = "legenda-rr-", tmpdir = DIR_FIGURAS, fileext = ".pdf")
ggsave(tmp, cowplot::ggdraw(legenda), width = 17.8, height = 1.6, units = "cm", device = "pdf", bg = "white")
if (!file.rename(tmp, destino)) stop("Falha ao concluir a gravação da legenda.")
writeLines(c("Legenda comum do painel de RR da defesa", "Paleta: magma(200, direction = -1), igual ao script 13.",
 sprintf("Limites: 1 a %.12f", limite),
 "Limite superior reconstruído do máximo das duas tabelas municipais de RR.",
 "Mapas originais e suas escalas de cores preservados."), file.path(DIR_LOGS, "log_legenda_rr_slides.txt"))
cat("Legenda gravada. Limite superior:", limite, "\n")
