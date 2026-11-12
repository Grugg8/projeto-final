# Séries regionais para a defesa: duas linhas, três colunas e Brasil ao final.
# Executar da raiz: Rscript "R/15_gerar_series_regionais_slides.R"
# A figura do manuscrito é preservada; este arquivo tem destino próprio.
suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(scales)
})
here::i_am("R/15_gerar_series_regionais_slides.R")
DIR_FIGURAS <- here::here("output", "figures")
DIR_TABELAS <- here::here("output", "tables")
DIR_LOGS <- here::here("output", "logs")
for (diretorio in c(DIR_FIGURAS, DIR_TABELAS, DIR_LOGS))
  dir.create(diretorio, showWarnings = FALSE, recursive = TRUE)
base <- readRDS(here::here("data", "processed", "dataset_tcc_consolidado.rds"))
malha <- readRDS(here::here("data", "raw", "malhas", "malha_BR_10.RDS"))
ids_malha <- sort(malha$ID_MN_RESI[malha$ID_MN_RESI != "260545"])
stopifnot(nrow(base) == 89024L,
          identical(sort(unique(base$ID_MN_RESI)), ids_malha),
          !anyNA(base[c("CASOS_PROV", "POP", "CD_UF", "ANO_EPI")]),
          all(base$POP > 0), all(base$CASOS_PROV >= 0))
mapa <- c("11"="Norte", "12"="Norte", "13"="Norte", "14"="Norte",
          "15"="Norte", "16"="Norte", "17"="Norte", "21"="Nordeste",
          "22"="Nordeste", "23"="Nordeste", "24"="Nordeste", "25"="Nordeste",
          "26"="Nordeste", "27"="Nordeste", "28"="Nordeste", "29"="Nordeste",
          "31"="Sudeste", "32"="Sudeste", "33"="Sudeste", "35"="Sudeste",
          "41"="Sul", "42"="Sul", "43"="Sul", "50"="Centro-Oeste",
          "51"="Centro-Oeste", "52"="Centro-Oeste", "53"="Centro-Oeste")
base <- base %>% mutate(REGIAO = unname(mapa[as.character(CD_UF)]),
                        ANO = as.integer(as.character(ANO_EPI)))
stopifnot(!anyNA(base$REGIAO), identical(sort(unique(base$ANO)), 2010:2025))
nacional <- base %>% group_by(ANO) %>%
  summarise(CASOS = sum(CASOS_PROV), POP = sum(POP), .groups = "drop") %>%
  mutate(TI = 1e5 * CASOS / POP)
regional <- base %>% group_by(REGIAO, ANO) %>%
  summarise(CASOS = sum(CASOS_PROV), POP = sum(POP), .groups = "drop") %>%
  mutate(TI = 1e5 * CASOS / POP)
conferencia <- regional %>% group_by(ANO) %>%
  summarise(CASOS = sum(CASOS), POP = sum(POP), .groups = "drop")
stopifnot(identical(conferencia$CASOS, nacional$CASOS),
          isTRUE(all.equal(conferencia$POP, nacional$POP)),
          sum(nacional$CASOS) == 22098006)
# Preservar a ordem regional da figura anterior; a sexta posição é nacional.
ordem <- c("Centro-Oeste", "Nordeste", "Norte", "Sudeste", "Sul", "Brasil")
series <- bind_rows(regional, mutate(nacional, REGIAO = "Brasil")) %>%
  mutate(REGIAO = factor(REGIAO, levels = ordem))
referencia <- regional %>% select(REGIAO, ANO) %>%
  left_join(nacional %>% select(ANO, TI), by = "ANO") %>%
  mutate(REGIAO = factor(REGIAO, levels = ordem))
cores <- c("Norte"="#1B7837", "Nordeste"="#7B3294", "Sudeste"="#8B0000",
           "Sul"="#2C7BB6", "Centro-Oeste"="#E69F00", "Brasil"="#18374C")
p <- ggplot(series, aes(ANO, TI)) +
  geom_line(data = referencia, linetype = "dashed", colour = "grey50",
            linewidth = 0.35) +
  geom_line(aes(colour = REGIAO), linewidth = 0.65) +
  facet_wrap(~REGIAO, ncol = 3, nrow = 2, scales = "free_y", drop = FALSE) +
  scale_colour_manual(values = cores) +
  scale_x_continuous(breaks = c(2010, 2015, 2020, 2025)) +
  scale_y_continuous(labels = label_number(big.mark = ".", decimal.mark = ","),
                     expand = expansion(mult = c(0.03, 0.08))) +
  labs(x = "Ano", y = "Incidência (casos por 100 mil habitantes)") +
  theme_classic(base_size = 11, base_family = "serif") +
  theme(legend.position = "none", strip.background = element_blank(),
        strip.text = element_text(face = "bold", size = 11),
        axis.line = element_line(linewidth = 0.25),
        axis.ticks = element_line(linewidth = 0.25),
        axis.text = element_text(colour = "grey20", size = 9),
        axis.title = element_text(size = 10),
        panel.spacing = grid::unit(0.6, "lines"),
        plot.margin = margin(4, 6, 4, 4))
destino <- file.path(DIR_FIGURAS, "fig_series_regioes_slides_2x3.pdf")
temporario <- tempfile(pattern = "series-regioes-", tmpdir = DIR_FIGURAS, fileext = ".pdf")
ggsave(temporario, p, width = 11, height = 4.5, device = "pdf", bg = "white")
if (!file.rename(temporario, destino)) stop("Não foi possível concluir a gravação do PDF.")
write.table(series %>% mutate(REGIAO = as.character(REGIAO)) %>% arrange(match(REGIAO, ordem), ANO),
            file.path(DIR_TABELAS, "dados_series_regioes_slides_2x3.tsv"), sep = "\t",
            row.names = FALSE, quote = FALSE, fileEncoding = "UTF-8")
writeLines(c("Auditoria da figura regional 2 x 3 para os slides",
             "Painel: 89.024 observações; 5.564 municípios; 16 anos.",
             "Casos: 22.098.006; somas regionais reproduzem o Brasil em todos os anos.",
             "TI = soma dos casos / soma da população x 100.000.",
             "Ordem: Centro-Oeste, Nordeste, Norte, Sudeste, Sul, Brasil.",
             "Linha tracejada: série nacional em cada painel regional.",
             "Eixos verticais próprios por painel, como na figura do manuscrito.",
             "Saída vetorial com device pdf, fonte serifada e gravação temporária."),
           file.path(DIR_LOGS, "log_series_regioes_slides_2x3.txt"))
cat("Figura regional 2 x 3 gravada e contagens conferidas.\n")
