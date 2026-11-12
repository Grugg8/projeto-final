here::i_am("R/07_covar_individuais.R")

# ============================================================================ #
# 07_covar_individuais.R
# ----------------------------------------------------------------------------
# Covariáveis INDIVIDUAIS do SaTScan (uma por modelo), categóricas com 3 níveis
# por tercis de frequência (ntile(x, 3), padrão do TCC).
# Versão v5-melhor-pior (apresentação do melhor para o pior; nível 1 = melhor;
# tercis com tamanhos uniformes 1855/1855/1854 em todos os indicadores):
#
#   1. COVAR_CALOR   = tercis de dias_onda_total (idêntico ao COVAR_TERMICA
#                      vigente; só releitura do arquivo pronto do script 04).
#                      Nível 1 = menos calor (melhor) a 3 = mais calor (pior).
#   2. COVAR_ESGOTO  = tercis de prop_esgoto_adequado (v3: SWAP rede->adequada;
#                      primeiro valor por município no painel consolidado).
#                      v4: invertido para 1 = MELHOR (maior cobertura) a
#                      3 = PIOR (menor cobertura); v5: tercis calculados na
#                      ordem decrescente (ntile(-x, 3)) para que o nível 1
#                      receba o grupo maior, como nas demais variáveis
#                      (1855/1855/1854). Coluna legada prop_esgoto_rede
#                      mantida só como auditoria (não define os tercis).
#   3. COVAR_DENSURB = tercis de DENS_URB_MEDIA (média 2010-2025 das densidades
#                      urbanas anuais = POP_URB / area_urbana). Maior densidade
#                      é tratada como pior condição: 1 = menor densidade a
#                      3 = maior densidade.
#   4. COVAR_PROPURB = tercis de PROP_URB_MEDIA (média 2010-2025 de
#                      area_urbana_km2 / AREA_KM2). Maior proporção urbana é
#                      tratada como pior condição: 1 = menor a 3 = maior.
#   5. COVAR_AGUA    = tercis de prop_agua_rede (primeiro valor por município).
#                      v4: invertido para 1 = MELHOR (maior cobertura) a
#                      3 = PIOR (menor cobertura); v5: ntile(-x, 3), tamanhos
#                      1855/1855/1854.
#   6. COVAR_LIXO    = tercis de prop_lixo_coletado (primeiro valor por
#                      município). v4: invertido para 1 = MELHOR a 3 = PIOR;
#                      v5: ntile(-x, 3), tamanhos 1855/1855/1854.
#
# Observação: 5.564 municípios não dividem igualmente por 3; a função de
# tercis distribui os 2 excedentes nos primeiros níveis (1855, 1855, 1854).
# A v4 aplicava 4 - ntile(x, 3), espelhando também o padrão de tamanho
# (1854, 1855, 1855 no sentido melhor->pior); a v5 calcula os tercis
# diretamente na ordem decrescente, uniformizando o padrão. Diferentemente da
# simples permutação de rótulos (que é invariante na padronização indireta),
# a v5 desloca a fronteira de um município entre níveis vizinhos, o que exige
# reexecutar as rodadas esgoto/água/lixo do SaTScan (checkpoint invalida
# automaticamente pelos hashes das entradas).
#
# Fontes:
#   - calor: data/processed/clima/
#     onda_calor_municipal_2010_2025.rds (ID_MN_RESI, COVAR_TERMICA,
#     dias_onda_total; 5.564 linhas).
#   - esgoto/POP/casos: data/processed/dataset_tcc_consolidado.rds (painel 89.024).
#   - pop urbana: checkpoint bruto SIDRA
#     data/raw/mapbiomas/pop_urb_sidra_bruto_2010_2022.rds
#     (lista urb2010: SIDRA 1378/2010; urb2022: SIDRA 9923/2022; colunas Total /
#     Urbana / Rural por código municipal de 7 dígitos). p = Urbana / Total;
#     2022 tem 5 códigos novos exatos do DICIONARIO_DE_PARA, somados ao
#     município de origem (Urb e Tot) antes de calcular p; Noronha excluída.
#     Série anual: p2010/p2022 observadas, interpolação linear 2011-2021,
#     freeze 2023-2025 (= p2022), clamp [0,1]; POP_URB = POP_painel x p.
#   - área urbana: data/processed/mapbiomas/area_urbana_municipal_2010_2025.rds
#     (grade 5.564 x 16 da malha 2010, sem Noronha).
#   - AREA_KM2: malha data/raw/malhas/malha_BR_10.RDS via
#     st_area(st_transform(geometry, 5880)) / 1e6, sem Noronha 260545
#     (mesma fórmula de 05_consolidacao_dataset.R e 06).
#
# Dicionário de-para (5 entradas, códigos de 6 dígitos):
#   150475->150680, 421265->420940, 422000->420700, 431454->430210,
#   500627->500325.
#
# Este script não altera nenhum outro script do pipeline.
#
# Saída (ARQUIVO ÚNICO):
#   * data/processed/mapbiomas/covar_individuais_2010_2025.rds
#       (ID_MN_RESI + COVAR_CALOR, COVAR_ESGOTO (v3: tercis de adequada),
#        COVAR_DENSURB, COVAR_PROPURB, COVAR_AGUA (v3), COVAR_LIXO (v3)
#        int 1-3 + auditoria contínua: dias_onda_total, prop_esgoto_adequado,
#        prop_esgoto_rede (legado v2, só auditoria), DENS_URB_MEDIA,
#        PROP_URB_MEDIA, prop_agua_rede, prop_lixo_coletado;
#        5.564 linhas, zero NA, IDs = malha)
# Log: impresso no console (limites dos tercis, n por nível, TI por nível)
#   + cópia em output/logs/mapbiomas/log_auditoria_covar_individuais.txt
#   (marcado "v3-adequada-agua-lixo") e cópia versionada *_v3.txt.
# ============================================================================ #

# ---- 0. Setup -------------------------------------------------------------- #
suppressPackageStartupMessages({
  library(dplyr)    # manipulação + ntile
  library(sf)       # área municipal (EPSG:5880)
})

DIR_MAPB      <- here::here("data", "processed", "mapbiomas")
DIR_MAPB_RAW  <- here::here("data", "raw", "mapbiomas")
DIR_LOG       <- here::here("output", "logs", "mapbiomas")
DIR_ERA5_PROC <- here::here("data", "processed", "clima")
dir.create(DIR_MAPB, showWarnings = FALSE, recursive = TRUE)
dir.create(DIR_LOG, showWarnings = FALSE, recursive = TRUE)

ARQ_CALOR <- file.path(DIR_ERA5_PROC, "onda_calor_municipal_2010_2025.rds")
ARQ_SIDRA <- file.path(DIR_MAPB_RAW, "pop_urb_sidra_bruto_2010_2022.rds")
ARQ_AREA  <- file.path(DIR_MAPB, "area_urbana_municipal_2010_2025.rds")
ARQ_SAIDA <- file.path(DIR_MAPB, "covar_individuais_2010_2025.rds")
ARQ_LOG   <- file.path(DIR_LOG, "log_auditoria_covar_individuais.txt")
ARQ_LOG_V3 <- file.path(DIR_LOG, "log_auditoria_covar_individuais_v3.txt")  # histórico (não sobrescrever)
ARQ_LOG_V4 <- file.path(DIR_LOG, "log_auditoria_covar_individuais_v4.txt")  # histórico (não sobrescrever)
ARQ_LOG_V5 <- file.path(DIR_LOG, "log_auditoria_covar_individuais_v5.txt")

VERSAO <- "v5-melhor-pior"

DICIONARIO_DE_PARA <- c(
  "150475" = "150680",  # Mojuí dos Campos   -> Santarém (PA)
  "421265" = "420940",  # Pescaria Brava     -> Laguna (SC)
  "422000" = "420700",  # Balneário Rincão   -> Içara (SC)
  "431454" = "430210",  # Pinto Bandeira     -> Bento Gonçalves (RS)
  "500627" = "500325"   # Paraíso das Águas  -> Costa Rica (MS)
)

# ---- 1. Calor (releitura do arquivo pronto do script 04) ------------------- #
cat("==> [1/5] Calor (releitura do COVAR_TERMICA vigente)...\n")

calor <- readRDS(ARQ_CALOR) %>%
  transmute(ID_MN_RESI = as.character(ID_MN_RESI),
            COVAR_CALOR = as.integer(COVAR_TERMICA),
            dias_onda_total = as.integer(dias_onda_total))
stopifnot(nrow(calor) == 5564L, !anyNA(calor$ID_MN_RESI),
          !anyNA(calor$COVAR_CALOR), !anyNA(calor$dias_onda_total),
          all(calor$COVAR_CALOR %in% 1:3),
          length(unique(calor$ID_MN_RESI)) == 5564L)

# ---- 2. Esgoto v3 (SWAP rede->adequada; 1=pior -> 3=melhor) --------------- #
cat("==> [2/6] Esgoto v3 (tercis de prop_esgoto_adequado)...\n")

consolidado <- readRDS(here::here("data", "processed", "dataset_tcc_consolidado.rds"))
stopifnot(nrow(consolidado) == 5564L * 16L)

esgoto <- consolidado %>%
  arrange(ID_MN_RESI) %>%
  filter(!duplicated(ID_MN_RESI)) %>%
  transmute(ID_MN_RESI = as.character(ID_MN_RESI),
            prop_esgoto_adequado = as.numeric(prop_esgoto_adequado),
            prop_esgoto_rede = as.numeric(prop_esgoto_rede),
            prop_agua_rede = as.numeric(prop_agua_rede),
            prop_lixo_coletado = as.numeric(prop_lixo_coletado)) %>%
  arrange(ID_MN_RESI) %>%
  # v5: tercis na ordem decrescente (ntile(-x, 3)): 1 = melhor (maior cobertura)
  # e o grupo maior (1855) fica no nível 1, uniformizando todos os indicadores
  # em 1855/1855/1854.
  mutate(COVAR_ESGOTO = as.integer(ntile(-prop_esgoto_adequado, 3)),
         COVAR_AGUA   = as.integer(ntile(-prop_agua_rede, 3)),
         COVAR_LIXO   = as.integer(ntile(-prop_lixo_coletado, 3)))
stopifnot(nrow(esgoto) == 5564L, !anyNA(esgoto$prop_esgoto_adequado),
          !anyNA(esgoto$prop_esgoto_rede),
          !anyNA(esgoto$prop_agua_rede), !anyNA(esgoto$prop_lixo_coletado),
          !anyNA(esgoto$COVAR_ESGOTO), all(esgoto$COVAR_ESGOTO %in% 1:3),
          !anyNA(esgoto$COVAR_AGUA), all(esgoto$COVAR_AGUA %in% 1:3),
          !anyNA(esgoto$COVAR_LIXO), all(esgoto$COVAR_LIXO %in% 1:3))

# ---- 3. Componente urbano: área, AREA_KM2 e p urbana SIDRA ----------------- #
cat("==> [3/6] Área urbana + AREA_KM2 (5880) + p urbana SIDRA...\n")

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

# p urbana por município (Urbana/Total): soma origem+novo no de-para, sem Noronha
extrai_p <- function(df) {
  cod7 <- as.character(df[["Município (Código)"]])
  sit  <- as.character(df[["Situação do domicílio"]])
  val  <- suppressWarnings(as.numeric(df[["Valor"]]))
  # SIDRA grava NA no Rural de municípios 100% urbanos (Total == Urbana);
  # nesses casos o Rural é 0 por definição. Total/Urbana nunca têm NA.
  stopifnot(all(sit[is.na(val)] == "Rural"))
  val[is.na(val)] <- 0
  stopifnot(!anyNA(cod7), !anyNA(sit), !anyNA(val))
  base <- data.frame(cod7 = cod7, sit = sit, val = val, stringsAsFactors = FALSE)
  por_cod7 <- base %>%
    group_by(cod7) %>%
    summarise(Tot = sum(val[sit == "Total"]),
              Urb = sum(val[sit == "Urbana"]), .groups = "drop")
  por_cod7$cod6 <- substr(por_cod7$cod7, 1, 6)
  por_cod7 <- por_cod7 %>% filter(cod6 != "260545")
  por_cod7$cod6m <- ifelse(por_cod7$cod6 %in% names(DICIONARIO_DE_PARA),
                           DICIONARIO_DE_PARA[por_cod7$cod6], por_cod7$cod6)
  agg <- por_cod7 %>%
    group_by(cod6m) %>%
    summarise(Tot = sum(Tot), Urb = sum(Urb), .groups = "drop")
  out <- agg %>% transmute(ID_MN_RESI = cod6m, p = Urb / Tot)
  out$p <- pmin(pmax(out$p, 0), 1)
  out
}

bruto_sidra <- readRDS(ARQ_SIDRA)
p2010 <- extrai_p(bruto_sidra$urb2010)
p2022 <- extrai_p(bruto_sidra$urb2022)
names(p2010)[names(p2010) == "p"] <- "p2010"
names(p2022)[names(p2022) == "p"] <- "p2022"
pp <- inner_join(p2010, p2022, by = "ID_MN_RESI")
stopifnot(nrow(pp) == 5564L, !anyNA(pp$p2010), !anyNA(pp$p2022),
          all(pp$p2010 >= 0 & pp$p2010 <= 1),
          all(pp$p2022 >= 0 & pp$p2022 <= 1))

# Grade anual de p: interpolação linear 2011-2021, freeze 2023-2025, clamp [0,1]
grade_p <- expand.grid(ID_MN_RESI = pp$ID_MN_RESI, ANO = 2010:2025,
                       stringsAsFactors = FALSE) %>%
  left_join(pp, by = "ID_MN_RESI") %>%
  mutate(p = if_else(ANO <= 2022L,
                     p2010 + (p2022 - p2010) * (ANO - 2010L) / 12,
                     p2022),
         p = pmin(pmax(p, 0), 1))
stopifnot(nrow(grade_p) == 5564L * 16L, !anyNA(grade_p$p),
          all(grade_p$p >= 0 & grade_p$p <= 1))

pop_painel <- consolidado %>%
  transmute(ID_MN_RESI = as.character(ID_MN_RESI),
            ANO = as.integer(ANO_EPI),
            POP = as.numeric(POP),
            CASOS = as.numeric(CASOS_PROV))
stopifnot(nrow(pop_painel) == 5564L * 16L, !anyNA(pop_painel$POP),
          !anyNA(pop_painel$CASOS), all(pop_painel$POP > 0))

# ---- 4. DENS_URB_MEDIA, PROP_URB_MEDIA e tercis ---------------------------- #
cat("==> [4/6] Densidade/proporção urbana médias + tercis...\n")

painel_urb <- grade_p %>%
  inner_join(pop_painel, by = c("ID_MN_RESI", "ANO")) %>%
  mutate(POP_URB = POP * p) %>%
  inner_join(area, by = c("ID_MN_RESI", "ANO")) %>%
  mutate(DENS_URB = POP_URB / AREA_URBANA)
stopifnot(nrow(painel_urb) == 5564L * 16L, !anyNA(painel_urb$DENS_URB),
          all(painel_urb$DENS_URB > 0))

dens_media <- painel_urb %>%
  group_by(ID_MN_RESI) %>%
  summarise(DENS_URB_MEDIA = mean(DENS_URB), .groups = "drop")
stopifnot(nrow(dens_media) == 5564L, !anyNA(dens_media$DENS_URB_MEDIA),
          all(dens_media$DENS_URB_MEDIA > 0))

painel_prop <- area %>%
  inner_join(area_km2, by = "ID_MN_RESI") %>%
  mutate(PROP_URB = AREA_URBANA / AREA_KM2)
stopifnot(nrow(painel_prop) == 5564L * 16L, !anyNA(painel_prop$PROP_URB),
          min(painel_prop$PROP_URB) > 0, max(painel_prop$PROP_URB) <= 1)

prop_media <- painel_prop %>%
  group_by(ID_MN_RESI) %>%
  summarise(PROP_URB_MEDIA = mean(PROP_URB), .groups = "drop")
stopifnot(nrow(prop_media) == 5564L, !anyNA(prop_media$PROP_URB_MEDIA))

dens_cat <- dens_media %>%
  arrange(ID_MN_RESI) %>%
  mutate(COVAR_DENSURB = as.integer(ntile(DENS_URB_MEDIA, 3)))
prop_cat <- prop_media %>%
  arrange(ID_MN_RESI) %>%
  mutate(COVAR_PROPURB = as.integer(ntile(PROP_URB_MEDIA, 3)))
stopifnot(all(dens_cat$COVAR_DENSURB %in% 1:3),
          all(prop_cat$COVAR_PROPURB %in% 1:3))

saida <- calor %>%
  inner_join(esgoto, by = "ID_MN_RESI") %>%
  inner_join(dens_cat, by = "ID_MN_RESI") %>%
  inner_join(prop_cat, by = "ID_MN_RESI") %>%
  transmute(ID_MN_RESI,
            COVAR_CALOR, COVAR_ESGOTO, COVAR_DENSURB, COVAR_PROPURB,
            COVAR_AGUA, COVAR_LIXO,
            dias_onda_total, prop_esgoto_adequado, prop_esgoto_rede,
            DENS_URB_MEDIA, PROP_URB_MEDIA, prop_agua_rede, prop_lixo_coletado)
attr(saida, "versao") <- VERSAO

# Checagens finais contra a malha 2010 (sem Noronha)
ids_malha <- sort(unique(malha$ID_MN_RESI[malha$ID_MN_RESI != "260545"]))
tamanhos_ok <- function(v) identical(as.integer(table(v)), c(1855L, 1855L, 1854L))
stopifnot(nrow(saida) == 5564L,
          length(ids_malha) == 5564L,
          identical(sort(unique(saida$ID_MN_RESI)), ids_malha),
          !anyNA(saida),
          all(saida$COVAR_CALOR %in% 1:3),
          all(saida$COVAR_ESGOTO %in% 1:3),
          all(saida$COVAR_DENSURB %in% 1:3),
          all(saida$COVAR_PROPURB %in% 1:3),
          all(saida$COVAR_AGUA %in% 1:3),
          all(saida$COVAR_LIXO %in% 1:3),
          tamanhos_ok(saida$COVAR_CALOR), tamanhos_ok(saida$COVAR_ESGOTO),
          tamanhos_ok(saida$COVAR_DENSURB), tamanhos_ok(saida$COVAR_PROPURB),
          tamanhos_ok(saida$COVAR_AGUA), tamanhos_ok(saida$COVAR_LIXO))

saveRDS(saida, ARQ_SAIDA)

# ---- 5. Log de validação: limites, n e TI por nível ------------------------ #
cat("==> [5/6] Validação por nível (limites, n, TI acumulada)...\n")

tot_mun <- pop_painel %>%
  group_by(ID_MN_RESI) %>%
  summarise(casos = sum(CASOS), pop = sum(POP), .groups = "drop")

relata <- function(col_covar, col_cont, rotulo, fmt_cont) {
  cov <- saida %>% select(ID_MN_RESI, nivel = all_of(col_covar),
                          v = all_of(col_cont)) %>%
    inner_join(tot_mun, by = "ID_MN_RESI")
  tab <- cov %>%
    group_by(nivel) %>%
    summarise(n = n(),
              vmin = min(v), vmed = median(v), vmax = max(v),
              casos = sum(casos), pop = sum(pop),
              TI = sum(casos) / sum(pop) * 1e5, .groups = "drop") %>%
    arrange(nivel)
  stopifnot(sum(tab$n) == 5564L)
  cat(sprintf("\n-- %s (n=%d) --\n", rotulo, nrow(saida)))
  for (i in seq_len(nrow(tab))) {
    cat(sprintf("nivel %d: n=%d | faixa %s a %s (mediana %s) | casos=%.0f | pop-ano=%.0f | TI=%.1f/100mil\n",
                tab$nivel[i], tab$n[i],
                sprintf(fmt_cont, tab$vmin[i]), sprintf(fmt_cont, tab$vmax[i]),
                sprintf(fmt_cont, tab$vmed[i]),
                tab$casos[i], tab$pop[i], tab$TI[i]))
  }
}

cat("\n--- LOG DE VALIDACAO (COVARIAVEIS INDIVIDUAIS) ---\n")
cat(sprintf("versao=%s\n", VERSAO))
cat(sprintf("linhas=%d | NAs=%d | IDs identicos a malha=%s\n",
            nrow(saida), sum(is.na(saida)),
            identical(sort(unique(saida$ID_MN_RESI)), ids_malha)))
cat(sprintf("mediana_dias_onda_total=%.0f | mediana_prop_esgoto_adequado=%.2f | mediana_prop_esgoto_rede_legado=%.2f\n",
            median(saida$dias_onda_total), median(saida$prop_esgoto_adequado),
            median(saida$prop_esgoto_rede)))
cat(sprintf("mediana_prop_agua_rede=%.2f | mediana_prop_lixo_coletado=%.2f\n",
            median(saida$prop_agua_rede), median(saida$prop_lixo_coletado)))
cat(sprintf("mediana_DENS_URB_MEDIA=%.1f hab/km2 | mediana_PROP_URB_MEDIA=%.7f\n",
            median(saida$DENS_URB_MEDIA), median(saida$PROP_URB_MEDIA)))

relata("COVAR_CALOR", "dias_onda_total",
       "COVAR_CALOR = tercis de dias_onda_total (1=MELHOR/menos calor -> 3=PIOR/mais calor)", "%.0f")
relata("COVAR_ESGOTO", "prop_esgoto_adequado",
       "COVAR_ESGOTO = tercis de prop_esgoto_adequado (1=MELHOR/maior -> 3=PIOR/menor cobertura)", "%.2f")
relata("COVAR_DENSURB", "DENS_URB_MEDIA",
       "COVAR_DENSURB = tercis de DENS_URB_MEDIA hab/km2 (1=MELHOR/menor -> 3=PIOR/maior)", "%.1f")
relata("COVAR_PROPURB", "PROP_URB_MEDIA",
       "COVAR_PROPURB = tercis de PROP_URB_MEDIA (1=MELHOR/menor -> 3=PIOR/maior)", "%.7f")
relata("COVAR_AGUA", "prop_agua_rede",
       "COVAR_AGUA = tercis de prop_agua_rede (1=MELHOR/maior -> 3=PIOR/menor cobertura)", "%.2f")
relata("COVAR_LIXO", "prop_lixo_coletado",
       "COVAR_LIXO = tercis de prop_lixo_coletado (1=MELHOR/maior -> 3=PIOR/menor cobertura)", "%.2f")

cat("\nArquivo:\n")
cat("  ", ARQ_SAIDA, "\n")

# ---- 6. Log em arquivo (versionado v3) ------------------------------------- #
cat("==> [6/6] Gravando log em arquivo...\n")
tot_mun2 <- pop_painel %>%
  group_by(ID_MN_RESI) %>%
  summarise(casos = sum(CASOS), pop = sum(POP), .groups = "drop")
linha_ti <- function(col_covar, col_cont) {
  cov <- saida %>% select(ID_MN_RESI, nivel = all_of(col_covar),
                          v = all_of(col_cont)) %>%
    inner_join(tot_mun2, by = "ID_MN_RESI")
  tab <- cov %>%
    group_by(nivel) %>%
    summarise(n = n(), vmin = min(v), vmax = max(v),
              TI = sum(casos) / sum(pop) * 1e5, .groups = "drop") %>%
    arrange(nivel)
  # Formatação com 4 algarismos significativos: proporções pequenas
  # (PROP_URB_MEDIA etc.) ficariam zeradas com %.2f.
  fmt4 <- function(z) format(signif(z, 4), scientific = FALSE, trim = TRUE)
  sprintf("%s: %s", col_covar,
          paste(sprintf("nivel%d n=%d [%s-%s] TI=%.1f",
                        tab$nivel, tab$n, fmt4(tab$vmin), fmt4(tab$vmax), tab$TI),
                collapse = " | "))
}
log_arq <- c(
  sprintf("versao=%s", VERSAO),
  sprintf("linhas=%d | NAs=%d | IDs identicos a malha=%s",
          nrow(saida), sum(is.na(saida)),
          identical(sort(unique(saida$ID_MN_RESI)), ids_malha)),
  sprintf("mediana_dias_onda_total=%.0f", median(saida$dias_onda_total)),
  sprintf("mediana_prop_esgoto_adequado=%.2f", median(saida$prop_esgoto_adequado)),
  sprintf("mediana_prop_esgoto_rede_legado=%.2f", median(saida$prop_esgoto_rede)),
  sprintf("mediana_prop_agua_rede=%.2f", median(saida$prop_agua_rede)),
  sprintf("mediana_prop_lixo_coletado=%.2f", median(saida$prop_lixo_coletado)),
  linha_ti("COVAR_CALOR", "dias_onda_total"),
  linha_ti("COVAR_ESGOTO", "prop_esgoto_adequado"),
  linha_ti("COVAR_DENSURB", "DENS_URB_MEDIA"),
  linha_ti("COVAR_PROPURB", "PROP_URB_MEDIA"),
  linha_ti("COVAR_AGUA", "prop_agua_rede"),
  linha_ti("COVAR_LIXO", "prop_lixo_coletado")
)
writeLines(log_arq, ARQ_LOG)
writeLines(log_arq, ARQ_LOG_V5)
cat("  ", ARQ_LOG, "\n")
cat("  ", ARQ_LOG_V5, "\n")

# ---- 7. Tabela consolidada de incidência por tercis (manuscrito) ----------- #
# Reúne os 7 indicadores usados na varredura (6 individuais + índice composto
# da rotina 06), com faixa, municípios, casos, população-ano e incidência
# média anual por 100 mil pessoas-ano. Ordem: covariáveis individuais primeiro
# e índice composto por último; níveis sempre do 1 (melhor) ao 3 (pior).
cat("==> [7/7] Tabela consolidada de incidência por tercis...\n")

suppressPackageStartupMessages({
  library(readr)
  library(kableExtra)
})

ARQ_COMP5 <- file.path(DIR_MAPB, "covar_composta_2010_2025.rds")
if (!file.exists(ARQ_COMP5)) {
  stop("Rode 06_covar_composta.R antes de 07 (", ARQ_COMP5, " ausente).")
}
comp5 <- readRDS(ARQ_COMP5) %>%
  transmute(ID_MN_RESI = as.character(ID_MN_RESI),
            COVAR_COMP5 = as.integer(COVAR_COMP5),
            escore_comp5 = as.numeric(escore_comp5))
stopifnot(nrow(comp5) == 5564L, !anyNA(comp5))

base_tab <- tot_mun2 %>%
  inner_join(saida, by = "ID_MN_RESI") %>%
  inner_join(comp5, by = "ID_MN_RESI")
stopifnot(nrow(base_tab) == 5564L)

fmt_br <- function(x, d = 1) formatC(x, format = "f", digits = d,
                                     big.mark = ".", decimal.mark = ",")
fmt_prop <- function(z) sub("\\.", ",", format(signif(z, 4), scientific = FALSE, trim = TRUE))
# Percentuais: sem ",00" redundante em valores inteiros (0, 100)
fmt_pct <- function(z) ifelse(abs(z - round(z)) < 1e-9, fmt_br(z, 0), fmt_br(z, 2))

spec_tab <- list(
  list(rot = "Dias sob ondas de calor", cov = "COVAR_CALOR",
       cont = "dias_onda_total", fmt = function(z) fmt_br(z, 0)),
  list(rot = "Esgotamento adequado (%)", cov = "COVAR_ESGOTO",
       cont = "prop_esgoto_adequado", fmt = fmt_pct),
  list(rot = "Densidade urbana (hab/km²)", cov = "COVAR_DENSURB",
       cont = "DENS_URB_MEDIA", fmt = function(z) fmt_br(z, 2)),
  list(rot = "Proporção urbana (fração da área municipal)", cov = "COVAR_PROPURB",
       cont = "PROP_URB_MEDIA", fmt = fmt_prop),
  list(rot = "Abastecimento de água por rede (%)", cov = "COVAR_AGUA",
       cont = "prop_agua_rede", fmt = fmt_pct),
  list(rot = "Coleta de lixo (%)", cov = "COVAR_LIXO",
       cont = "prop_lixo_coletado", fmt = fmt_pct),
  list(rot = "Índice socioambiental (escore 0 a 5)", cov = "COVAR_COMP5",
       cont = "escore_comp5", fmt = function(z) fmt_br(z, 2))
)

linhas_tex <- list(); linhas_tsv <- list()
for (sp in spec_tab) {
  tab <- base_tab %>%
    transmute(nivel = .data[[sp$cov]], v = .data[[sp$cont]],
              casos = casos, pop = pop) %>%
    group_by(nivel) %>%
    summarise(n = n(), vmin = min(v), vmax = max(v),
              casos = sum(casos), pop = sum(pop),
              TI = sum(casos) / sum(pop) * 1e5, .groups = "drop") %>%
    arrange(nivel)
  stopifnot(nrow(tab) == 3L, sum(tab$n) == 5564L)
  for (i in seq_len(nrow(tab))) {
    linhas_tsv[[length(linhas_tsv) + 1]] <- data.frame(
      Indicador = sp$rot, Nivel = tab$nivel[i],
      Faixa_min = tab$vmin[i], Faixa_max = tab$vmax[i],
      n_municipios = tab$n[i], casos = tab$casos[i],
      populacao_ano = tab$pop[i], TI_por_100mil_pessoa_ano = tab$TI[i],
      stringsAsFactors = FALSE)
    linhas_tex[[length(linhas_tex) + 1]] <- data.frame(
      Nivel = tab$nivel[i],
      Faixa = sprintf("%s a %s", sp$fmt(tab$vmin[i]), sp$fmt(tab$vmax[i])),
      Municipios = fmt_br(tab$n[i], 0),
      Casos = fmt_br(tab$casos[i], 0),
      PopAno = fmt_br(tab$pop[i] / 1e6, 1),
      stringsAsFactors = FALSE)
  }
}
tab_tsv <- do.call(rbind, linhas_tsv)
tab_tex <- do.call(rbind, linhas_tex)

DIR_SAIDA <- here::here("output", "tables")
dir.create(DIR_SAIDA, showWarnings = FALSE, recursive = TRUE)

# Títulos longos quebrados em duas linhas com \shortstack (LaTeX padrão, sempre
# disponível no preâmbulo do manuscrito) para que a tabela caiba na largura do
# texto sem comprimir a fonte (v7: sem a coluna de incidência, que é resultado;
# a tabela documenta a estratificação em Métodos).
kt <- kable(tab_tex, format = "latex", booktabs = TRUE, escape = FALSE,
            col.names = c("Nível", "Faixa", "Municípios", "Casos",
                          "\\shortstack{População-ano\\\\ (milhões)}"),
            align = c("c", "c", "c", "c", "c"),
            caption = "Estratificação de tercis dos indicadores usados na padronização indireta da varredura espacial, Brasil, 2010--2025.",
            label = "incidencia_tercis")
# pack_rows escapa os rótulos (escape = TRUE), então "%" vira "\%" sem
# duplicar a barra invertida.
rotulos <- vapply(spec_tab, function(sp) sp$rot, character(1))
kt <- pack_rows(kt, index = setNames(rep(3L, length(rotulos)), rotulos))
# hold_position (mantém a posição) sem scale_down: a tabela ocupa a largura do
# texto com fonte 9, igual às demais tabelas do manuscrito.
kt <- kable_styling(kt, latex_options = "hold_position", font_size = 9)
write_lines(as.character(kt), file.path(DIR_SAIDA, "tabela_incidencia_tercis.tex"))
write_tsv(tab_tsv, file.path(DIR_SAIDA, "dados_incidencia_tercis.tsv"))

cat("\n--- TABELA CONSOLIDADA (tercis dos indicadores; o TSV mantém a TI para auditoria) ---\n")
print(tab_tsv, row.names = FALSE)
cat("Arquivos:\n")
cat("  ", file.path(DIR_SAIDA, "tabela_incidencia_tercis.tex"), "\n")
cat("  ", file.path(DIR_SAIDA, "dados_incidencia_tercis.tsv"), "\n")
