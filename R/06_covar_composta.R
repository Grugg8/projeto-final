here::i_am("R/06_covar_composta.R")

# ============================================================================ #
# 06_covar_composta.R
# ----------------------------------------------------------------------------
# Covariável composta do SaTScan + escore-z de 5 variáveis (modelo "comp5").
# Versão v3-adequada-comp5:
#
# Binário legado COVAR_COMPOSTA (NÃO apagar; saiu de cena, sem rerun):
#   EXPOSTO = 1 se (calor = 1 E esgoto = 1 E urbano = 1), senão 0, onde:
#   - calor:  dias_onda_total >= 415 (tercil superior; P90/ondas do script 04)
#   - esgoto: prop_esgoto_adequado < mediana municipal nacional não ponderada
#             (v3: SWAP rede->adequada; recalculada aqui; esperado ~59,35%)
#   - urbano: PROP_URB_MEDIA > mediana municipal nacional não ponderada, onde
#             PROP_URB_MEDIA[i] = média 2010-2025 de
#               (area_urbana_km2[t,i] / AREA_KM2[i])
#
# Composto principal COVAR_COMP5 (v4-max) = tercis do escore de adversidade,
# soma de 5 componentes padronizados pelo MÁXIMO municipal do próprio universo
# (5.564 municípios, 2010-2025), todos orientados como adversidade crescente:
#   escore = dias_onda_total / max(dias_onda_total)
#          + (1 - prop_esgoto_adequado / max(prop_esgoto_adequado))
#          + PROP_URB_MEDIA / max(PROP_URB_MEDIA)
#          + (1 - prop_agua_rede / max(prop_agua_rede))
#          + (1 - prop_lixo_coletado / max(prop_lixo_coletado)).
#   Cada componente pertence a [0,1]; o escore pertence a [0,5] e cresce na
#   direção da pior condição. COVAR_COMP5 = ntile(escore, 3), com
#   nível 1 = menor escore (melhor condição) e nível 3 = maior escore (pior).
#   Esperado: ~1.855/1.855/1.854 municípios por nível.
#   (Histórico: a v3 usava soma de escore-z com scale(); substituída pela
#   padronização pelo máximo, que fixa os denominadores no próprio universo.)
#
# Fontes do componente urbano (v2):
#   - area_urbana_km2: data/processed/mapbiomas/
#     area_urbana_municipal_2010_2025.rds (ID_MN_RESI chr 6d, ano,
#     area_urbana_km2; grade 5564 x 16 da malha 2010, sem Noronha)
#   - AREA_KM2: malha data/raw/malhas/malha_BR_10.RDS via
#     st_area(st_transform(geometry, 5880)) / 1e6, excluindo Noronha 260545
#     (mesma fórmula de 05_consolidacao_dataset.R).
#
# Histórico: a v1 usava densidade urbana média (POP_URB interpolada SIDRA /
# área MapBiomas). O bloco SIDRA/pop urbana interpolada foi REMOVIDO por virar
# código morto — a proporção v2 não usa população. O checkpoint bruto
# pop_urb_sidra_bruto_2010_2022.rds é mantido no disco, mas a v2 não o lê,
# não o grava e não depende dele (sem download SIDRA; sem pacote sidrar).
#
# Regra de fallback: se expostos < 100 municípios, relaxa SÓ o calor para
# acima da mediana (dias_onda_total > mediana recalculada), mantendo
# esgoto/proporção urbana. O log registra qual regra valeu.
#
# Este script não altera nenhum outro script do pipeline.
#
# Saídas (MESMO RDS, nova coluna + auditoria; binária vira legado):
#   * data/processed/mapbiomas/covar_composta_2010_2025.rds
#       (ID_MN_RESI, COVAR_COMPOSTA int 0/1 [legado v3, critério adequada] +
#        COVAR_COMP5 int 1-3 + escore_comp5 + colunas de auditoria:
#        dias_onda_total, CALOR, prop_esgoto_adequado, prop_esgoto_rede
#        (legado v2, só auditoria), ESGOTO, PROP_URB_MEDIA, URBANO,
#        prop_agua_rede, prop_lixo_coletado)
#   * output/logs/mapbiomas/log_auditoria_covar_composta.txt
#       (marcado "v4-max-comp5"; o binário redefinido é SÓ registro —
#        NÃO rerodar o modelo composto binário)
#   * output/logs/mapbiomas/log_auditoria_covar_composta_v4.txt
#       (cópia versionada do log v4; o log v3 é histórico e não é sobrescrito)
# ============================================================================ #

# ---- 0. Setup -------------------------------------------------------------- #
suppressPackageStartupMessages({
  library(dplyr)    # manipulação
  library(sf)       # área municipal (EPSG:5880)
})

DIR_MAPB      <- here::here("data", "processed", "mapbiomas")
DIR_MAPB_RAW  <- here::here("data", "raw", "mapbiomas")
DIR_LOG       <- here::here("output", "logs", "mapbiomas")
DIR_ERA5_PROC <- here::here("data", "processed", "clima")
dir.create(DIR_MAPB, showWarnings = FALSE, recursive = TRUE)
dir.create(DIR_LOG, showWarnings = FALSE, recursive = TRUE)

ARQ_BRUTO <- file.path(DIR_MAPB_RAW, "pop_urb_sidra_bruto_2010_2022.rds")  # legado v1; v2 não utiliza
ARQ_SAIDA <- file.path(DIR_MAPB, "covar_composta_2010_2025.rds")
ARQ_LOG   <- file.path(DIR_LOG, "log_auditoria_covar_composta.txt")
ARQ_LOG_V3 <- file.path(DIR_LOG, "log_auditoria_covar_composta_v3.txt")  # histórico (não sobrescrever)
ARQ_LOG_V4 <- file.path(DIR_LOG, "log_auditoria_covar_composta_v4.txt")
ARQ_AREA  <- file.path(DIR_MAPB, "area_urbana_municipal_2010_2025.rds")

VERSAO <- "v4-max-comp5"

# ---- 1. Proporção de área urbana média 2010-2025 ---------------------------- #
cat("==> [1/5] Proporção de área urbana (MapBiomas / AREA_KM2 malha 5880)...\n")

area <- readRDS(ARQ_AREA) %>%
  transmute(ID_MN_RESI = as.character(ID_MN_RESI),
            ANO = as.integer(ano),
            AREA_URBANA = as.numeric(area_urbana_km2))
stopifnot(nrow(area) == 5564L * 16L, !anyNA(area$AREA_URBANA),
          min(area$AREA_URBANA) > 0)

malha <- readRDS(here::here("data", "raw", "malhas", "malha_BR_10.RDS"))
area_km2 <- malha %>%
  filter(ID_MN_RESI != "260545") %>%
  mutate(AREA_KM2 = as.numeric(st_area(st_transform(geometry, 5880))) / 1e6) %>%
  st_drop_geometry() %>%
  select(ID_MN_RESI, AREA_KM2)
stopifnot(nrow(area_km2) == 5564L, !anyNA(area_km2$AREA_KM2),
          min(area_km2$AREA_KM2) > 0)

painel_prop <- area %>%
  inner_join(area_km2, by = "ID_MN_RESI") %>%
  mutate(PROP_URB = AREA_URBANA / AREA_KM2)
stopifnot(nrow(painel_prop) == 5564L * 16L, !anyNA(painel_prop$PROP_URB),
          min(painel_prop$PROP_URB) > 0, max(painel_prop$PROP_URB) <= 1)

prop_media <- painel_prop %>%
  group_by(ID_MN_RESI) %>%
  summarise(PROP_URB_MEDIA = mean(PROP_URB), .groups = "drop")
stopifnot(nrow(prop_media) == 5564L, !anyNA(prop_media$PROP_URB_MEDIA))

MED_PROP <- median(prop_media$PROP_URB_MEDIA)  # mediana não ponderada

# ---- 2. Calor, saneamento e regra composta ---------------------------------- #
cat("==> [2/5] Calor + esgoto(adequada) + agua + lixo + regra composta...\n")

calor <- readRDS(file.path(DIR_ERA5_PROC, "onda_calor_municipal_2010_2025.rds")) %>%
  transmute(ID_MN_RESI = as.character(ID_MN_RESI),
            dias_onda_total = as.integer(dias_onda_total))
stopifnot(nrow(calor) == 5564L)

consolidado <- readRDS(here::here("data", "processed", "dataset_tcc_consolidado.rds"))
san <- consolidado %>%
  filter(!duplicated(ID_MN_RESI)) %>%
  transmute(ID_MN_RESI = as.character(ID_MN_RESI),
            prop_esgoto_adequado = as.numeric(prop_esgoto_adequado),
            prop_esgoto_rede = as.numeric(prop_esgoto_rede),
            prop_agua_rede = as.numeric(prop_agua_rede),
            prop_lixo_coletado = as.numeric(prop_lixo_coletado))
stopifnot(nrow(san) == 5564L, !anyNA(san$prop_esgoto_adequado),
          !anyNA(san$prop_esgoto_rede), !anyNA(san$prop_agua_rede),
          !anyNA(san$prop_lixo_coletado))

MED_ESGOTO <- median(san$prop_esgoto_adequado)  # mediana não ponderada (v3: adequada)
MED_CALOR  <- median(calor$dias_onda_total)    # mediana não ponderada
CORTE_CALOR_ESTRITO <- 415L

base <- prop_media %>%
  inner_join(calor, by = "ID_MN_RESI") %>%
  inner_join(san, by = "ID_MN_RESI") %>%
  mutate(
    CALOR  = as.integer(dias_onda_total >= CORTE_CALOR_ESTRITO),
    ESGOTO = as.integer(prop_esgoto_adequado < MED_ESGOTO),
    URBANO = as.integer(PROP_URB_MEDIA > MED_PROP)
  )
stopifnot(nrow(base) == 5564L)

n_estrito <- sum(base$CALOR == 1 & base$ESGOTO == 1 & base$URBANO == 1)

if (n_estrito >= 100L) {
  REGRA <- "estrita: calor = dias_onda_total >= 415"
  base <- base %>% mutate(COVAR_COMPOSTA = as.integer(CALOR == 1 & ESGOTO == 1 & URBANO == 1))
} else {
  # Fallback: relaxa SÓ o calor para acima da mediana; esgoto/proporção mantidos.
  REGRA <- sprintf("fallback: calor = dias_onda_total > %.0f (mediana)", MED_CALOR)
  base <- base %>% mutate(
    CALOR = as.integer(dias_onda_total > MED_CALOR),
    COVAR_COMPOSTA = as.integer(CALOR == 1 & ESGOTO == 1 & URBANO == 1)
  )
}
stopifnot(!anyNA(base$COVAR_COMPOSTA))

# ---- 2b. COVAR_COMP5 (principal): padronização pelo máximo, tercis --------- #
# Máximos municipais não ponderados no próprio universo analisado; cada
# componente em [0,1] orientado como adversidade crescente. O escore final
# pertence a [0,5]: nível 1 = menor escore (melhor condição), 3 = pior.
MAX_DIAS <- max(base$dias_onda_total)
MAX_ESG  <- max(base$prop_esgoto_adequado)
MAX_URB  <- max(base$PROP_URB_MEDIA)
MAX_AGUA <- max(base$prop_agua_rede)
MAX_LIXO <- max(base$prop_lixo_coletado)
stopifnot(MAX_DIAS > 0, MAX_ESG > 0, MAX_URB > 0, MAX_AGUA > 0, MAX_LIXO > 0)

base <- base %>%
  mutate(
    escore_comp5 = as.numeric(
      dias_onda_total / MAX_DIAS +
        (1 - prop_esgoto_adequado / MAX_ESG) +
        PROP_URB_MEDIA / MAX_URB +
        (1 - prop_agua_rede / MAX_AGUA) +
        (1 - prop_lixo_coletado / MAX_LIXO)),
    COVAR_COMP5 = as.integer(dplyr::ntile(escore_comp5, 3))
  )
stopifnot(!anyNA(base$escore_comp5), !anyNA(base$COVAR_COMP5),
          all(base$escore_comp5 >= 0), all(base$escore_comp5 <= 5),
          all(base$COVAR_COMP5 %in% 1:3),
          sum(base$COVAR_COMP5 == 1L) + sum(base$COVAR_COMP5 == 2L) +
            sum(base$COVAR_COMP5 == 3L) == 5564L)

saida <- base %>%
  transmute(ID_MN_RESI,
            COVAR_COMPOSTA,
            COVAR_COMP5,
            escore_comp5,
            dias_onda_total,
            CALOR,
            prop_esgoto_adequado,
            prop_esgoto_rede,
            ESGOTO,
            PROP_URB_MEDIA,
            URBANO,
            prop_agua_rede,
            prop_lixo_coletado)
attr(saida, "versao") <- VERSAO
attr(saida, "regra") <- REGRA
attr(saida, "corte_calor") <- if (n_estrito >= 100L) CORTE_CALOR_ESTRITO else MED_CALOR
attr(saida, "med_esgoto") <- MED_ESGOTO
attr(saida, "med_prop_urb_media") <- MED_PROP
attr(saida, "med_dias_onda") <- MED_CALOR
attr(saida, "comp5_maximos") <- c(dias_onda_total = MAX_DIAS,
                                  prop_esgoto_adequado = MAX_ESG,
                                  prop_urb_media = MAX_URB,
                                  prop_agua_rede = MAX_AGUA,
                                  prop_lixo_coletado = MAX_LIXO)

# Checagem contra a malha 2010 (sem Noronha)
ids_malha <- sort(unique(malha$ID_MN_RESI[malha$ID_MN_RESI != "260545"]))
stopifnot(length(ids_malha) == 5564L,
          identical(sort(unique(saida$ID_MN_RESI)), ids_malha))

saveRDS(saida, ARQ_SAIDA)

# ---- 3. Log de validação --------------------------------------------------- #
cat("==> [3/5] Validação por estrato (casos/pop/TI)...\n")

tot_mun <- consolidado %>%
  group_by(ID_MN_RESI) %>%
  summarise(casos = sum(CASOS_PROV), pop = sum(POP), .groups = "drop") %>%
  inner_join(saida %>% select(ID_MN_RESI, COVAR_COMPOSTA, COVAR_COMP5), by = "ID_MN_RESI")

estrato <- function(v) {
  s <- tot_mun %>% filter(COVAR_COMPOSTA == v)
  sprintf("estrato %d: mun=%d | casos=%.0f | pop-ano=%.0f | TI=%.1f/100mil",
          v, nrow(s), sum(s$casos), sum(s$pop),
          sum(s$casos) / sum(s$pop) * 1e5)
}

tercil_comp5 <- function(v) {
  s <- tot_mun %>% filter(COVAR_COMP5 == v)
  sprintf("comp5 nivel %d: mun=%d | casos=%.0f | pop-ano=%.0f | TI=%.1f/100mil",
          v, nrow(s), sum(s$casos), sum(s$pop),
          sum(s$casos) / sum(s$pop) * 1e5)
}

n_exp <- sum(saida$COVAR_COMPOSTA == 1L)

sidra_nota <- if (file.exists(ARQ_BRUTO)) {
  "checkpoint SIDRA v1 (pop_urb_sidra_bruto_2010_2022.rds) mantido no disco; v2-proporcao NAO o utiliza (componente urbano sem populacao)"
} else {
  "checkpoint SIDRA v1 ausente no disco; v2-proporcao NAO o utiliza (componente urbano sem populacao)"
}

log <- c(
  sprintf("versao=%s", VERSAO),
  sprintf("regra_aplicada=%s", REGRA),
  sprintf("corte_calor_estrito=415 | n_estrito=%d", n_estrito),
  sprintf("mediana_prop_esgoto_adequado=%.2f (v3: SWAP rede->adequada)", MED_ESGOTO),
  sprintf("mediana_prop_esgoto_rede_legado=%.2f (v2, só auditoria)", median(saida$prop_esgoto_rede)),
  sprintf("mediana_prop_urb_media=%.7f", MED_PROP),
  sprintf("mediana_dias_onda_total=%.0f", MED_CALOR),
  sprintf("expostos_binario_redefinido=%d (%.2f%% de 5564; v2 era 226; SÓ REGISTRO — modelo binario NAO rerodado, saiu de cena)", n_exp, 100 * n_exp / 5564),
  estrato(1),
  estrato(0),
  sprintf("comp5_metodo=padronizacao pelo maximo municipal (5 componentes em [0,1]; escore 0-5 crescente = pior condicao)"),
  sprintf("comp5_maximos=dias_onda_total=%.0f | prop_esgoto_adequado=%.2f | prop_urb_media=%.7f | prop_agua_rede=%.2f | prop_lixo_coletado=%.2f",
          MAX_DIAS, MAX_ESG, MAX_URB, MAX_AGUA, MAX_LIXO),
  sprintf("comp5_escore_faixa=%.4f a %.4f", min(saida$escore_comp5), max(saida$escore_comp5)),
  sprintf("comp5_n_nivel1=%d | comp5_n_nivel2=%d | comp5_n_nivel3=%d",
          sum(saida$COVAR_COMP5 == 1L), sum(saida$COVAR_COMP5 == 2L),
          sum(saida$COVAR_COMP5 == 3L)),
  sprintf("comp5_faixa_escore_nivel1=%.4f a %.4f", min(saida$escore_comp5[saida$COVAR_COMP5 == 1L]), max(saida$escore_comp5[saida$COVAR_COMP5 == 1L])),
  sprintf("comp5_faixa_escore_nivel2=%.4f a %.4f", min(saida$escore_comp5[saida$COVAR_COMP5 == 2L]), max(saida$escore_comp5[saida$COVAR_COMP5 == 2L])),
  sprintf("comp5_faixa_escore_nivel3=%.4f a %.4f", min(saida$escore_comp5[saida$COVAR_COMP5 == 3L]), max(saida$escore_comp5[saida$COVAR_COMP5 == 3L])),
  tercil_comp5(1),
  tercil_comp5(2),
  tercil_comp5(3),
  sidra_nota,
  sprintf("checagem_prop_urb=min %.7f max %.4f", min(painel_prop$PROP_URB), max(painel_prop$PROP_URB)),
  sprintf("checagem_area_malha_5880=min %.1f max %.1f km2", min(area_km2$AREA_KM2), max(area_km2$AREA_KM2))
)

writeLines(log, ARQ_LOG)
writeLines(log, ARQ_LOG_V4)

cat("\n--- LOG DE VALIDACAO (COVAR COMPOSTA) ---\n")
cat(log, sep = "\n")
cat("\nArquivos:\n")
cat("  ", ARQ_SAIDA, "\n")
cat("  ", ARQ_LOG, "\n")
cat("  ", ARQ_LOG_V4, "\n")
