# ============================================================================ #
# 11_wmape_satscan.R
# ----------------------------------------------------------------------------
# Consolidação dos resultados de WMAPE e da comparação espacial das rodadas do
# SaTScan produzidas por `10_varredura_satscan.R` (desenho único do orientador;
# cenários completo = 2010-2025 e sem2024 = 2010-2023 + 2025).
#
# Para cada modelo (puro, termica, comp5, esgoto, densurb, propurb, agua, lixo)
# e cenário:
#   * lê o TSV nacional (wmape_nacional_satscan_<modelo>[_sem2024].tsv);
#   * CONFERE o WMAPE de forma independente a partir do TSV municipal
#     (wmape_municipal_satscan_<modelo>[_sem2024].tsv), recalculando
#     soma|O-E|/soma(O) e comparando com o valor registrado;
#   * reconstrói o conjunto de municípios das zonas significativas (p<=0,05)
#     a partir do RDS do run, para os índices de Jaccard.
#
# Saídas em output/tables/ e output/logs/:
#   * wmape_satscan_resumo.tsv        (por modelo x cenário, com checagens)
#   * sensibilidade_2024_satscan.tsv  (zonas, polos e Jaccard entre cenários)
#   * jaccard_satscan_completo.tsv    (matriz 8x8 de Jaccard, 2010-2025)
#   * jaccard_satscan_sem2024.tsv     (matriz 8x8 de Jaccard, sem 2024)
#   * tabela_wmape_satscan.tex        (tabela do manuscrito: zonas + WMAPE nos
#                                      dois cenários, com redução vs puro)
#   * tabela_sensibilidade_satscan.tex(tabela do manuscrito: zonas e polos
#                                      primários nos dois cenários + Jaccard)
#   * log_auditoria_wmape_satscan.txt
# ============================================================================ #

suppressPackageStartupMessages({
  library(dplyr); library(readr); library(kableExtra)
})

here::i_am("R/11_wmape_satscan.R")
DIR_TABELAS <- here::here("output", "tables")
DIR_LOGS <- here::here("output", "logs")
DIR_MODELOS <- here::here("output", "models")
for (diretorio in c(DIR_TABELAS, DIR_LOGS, DIR_MODELOS))
  dir.create(diretorio, showWarnings = FALSE, recursive = TRUE)

fmt_br <- function(x, d = 1) formatC(x, format = "f", digits = d,
                                     big.mark = ".", decimal.mark = ",")

rotulos <- c(puro = "Sem ajuste", termica = "Calor",
             esgoto = "Esgoto adequado", densurb = "Densidade urbana",
             propurb = "Proporção urbana", agua = "Água por rede",
             lixo = "Coleta de lixo", comp5 = "Índice composto")
cenarios <- c(completo = "", sem2024 = "_sem2024")

# Nomes dos RDS por modelo/cenário (ver 10_varredura_satscan.R)
rds_run <- function(modelo, sufixo) {
  base <- if (modelo == "puro") "resultado_satscan_acum" else paste0("resultado_satscan_", modelo)
  file.path(DIR_MODELOS, paste0(base, sufixo, ".rds"))
}

# Zonas significativas (p<=0,05) e conjunto de municípios em zonas, como no 10
sig_zonas <- function(x) {
  col_x <- x$col %>% filter(CLUSTER > 0)
  x$sci %>%
    filter(CLUSTER > 0) %>%
    left_join(col_x %>% select(CLUSTER, P_VALUE, NUMBER_LOC), by = "CLUSTER") %>%
    filter(P_VALUE <= 0.05) %>%
    arrange(CLUSTER)
}
membros_sig <- function(x) unique(x$gis$LOC_ID[x$gis$CLUSTER %in% sig_zonas(x)$CLUSTER])
jaccard_pct <- function(a, b) 100 * length(intersect(a, b)) / length(union(a, b))

# ---- 1. Leitura e conferência dos WMAPE nacionais --------------------------- #
resumo <- list(); membros <- list(); municipais <- list()
for (mod in names(rotulos)) {
  for (cen in names(cenarios)) {
    sufixo <- cenarios[[cen]]
    stub <- paste0("satscan_", mod, sufixo)
    arq_nac <- file.path(DIR_TABELAS, paste0("wmape_nacional_", stub, ".tsv"))
    arq_mun <- file.path(DIR_TABELAS, paste0("wmape_municipal_", stub, ".tsv"))
    if (!file.exists(arq_nac) || !file.exists(arq_mun)) {
      cat(sprintf("  [aviso] ausente: %s%s\n", stub, if (!file.exists(arq_nac)) " (nacional)" else "", if (!file.exists(arq_mun)) " (municipal)" else ""))
      next
    }
    nac <- read_tsv(arq_nac, show_col_types = FALSE)
    mun <- read_tsv(arq_mun, show_col_types = FALSE)
    # Conferência independente do WMAPE a partir do TSV municipal
    wmape_recalc <- 100 * sum(mun$ERRO_ABS) / sum(mun$OBSERVADO)
    dif_wmape <- abs(wmape_recalc - nac$wmape_pct)
    if (dif_wmape > 1e-6) {
      stop(sprintf("WMAPE divergente em %s: registro %.6f vs recálculo %.6f", stub, nac$wmape_pct, wmape_recalc))
    }
    rr <- readRDS(rds_run(mod, sufixo))
    fz <- sig_zonas(rr)
    membros[[paste(mod, cen, sep = "_")]] <- membros_sig(rr)
    municipais[[paste(mod, cen, sep = "_")]] <- mun
    resumo[[length(resumo) + 1]] <- data.frame(
      modelo = mod, rotulo = rotulos[[mod]], cenario = cen,
      n_zonas = nac$n_zonas_sig, prim_polo = nac$prim_polo, prim_uf = nac$prim_uf,
      prim_rr = nac$prim_rr, soma_observado = nac$soma_observado,
      soma_erro_abs = nac$soma_erro_abs, wmape_pct = nac$wmape_pct,
      wmape_recalculo_pct = wmape_recalc,
      cob_municipios = sum(fz$NUMBER_LOC),
      cob_casos = sum(fz$OBSERVED),
      cob_casos_pct = 100 * sum(fz$OBSERVED) / nac$soma_observado,
      checagem = if (dif_wmape <= 1e-6) "ok" else "FALHA",
      stringsAsFactors = FALSE)
  }
}
resumo <- bind_rows(resumo)
write_tsv(resumo, file.path(DIR_TABELAS, "wmape_satscan_resumo.tsv"))

# Redução do WMAPE vs puro, dentro de cada cenário
resumo <- resumo %>%
  group_by(cenario) %>%
  mutate(wmape_puro = wmape_pct[modelo == "puro"],
         reducao_pp = wmape_puro - wmape_pct) %>%
  ungroup()

# ---- 2. Jaccard vs puro e entre cenários ------------------------------------ #
linhas_sens <- list()
for (mod in names(rotulos)) {
  chave_c <- paste(mod, "completo", sep = "_")
  chave_s <- paste(mod, "sem2024", sep = "_")
  if (!is.null(membros[[chave_c]]) && !is.null(membros[[chave_s]])) {
    jac_cen <- jaccard_pct(membros[[chave_c]], membros[[chave_s]])
  } else {
    jac_cen <- NA_real_
  }
  jac_puro_c <- if (!is.null(membros[[chave_c]]) && !is.null(membros[["puro_completo"]]))
    jaccard_pct(membros[["puro_completo"]], membros[[chave_c]]) else NA_real_
  jac_puro_s <- if (!is.null(membros[[chave_s]]) && !is.null(membros[["puro_sem2024"]]))
    jaccard_pct(membros[["puro_sem2024"]], membros[[chave_s]]) else NA_real_
  rc <- resumo %>% filter(modelo == mod, cenario == "completo")
  rs <- resumo %>% filter(modelo == mod, cenario == "sem2024")
  linhas_sens[[length(linhas_sens) + 1]] <- data.frame(
    modelo = mod, rotulo = rotulos[[mod]],
    zonas_completo = if (nrow(rc)) rc$n_zonas else NA_integer_,
    zonas_sem2024 = if (nrow(rs)) rs$n_zonas else NA_integer_,
    prim_polo_completo = if (nrow(rc)) rc$prim_polo else NA_character_,
    prim_uf_completo = if (nrow(rc)) rc$prim_uf else NA_character_,
    prim_polo_sem2024 = if (nrow(rs)) rs$prim_polo else NA_character_,
    prim_uf_sem2024 = if (nrow(rs)) rs$prim_uf else NA_character_,
    prim_rr_completo = if (nrow(rc)) rc$prim_rr else NA_real_,
    prim_rr_sem2024 = if (nrow(rs)) rs$prim_rr else NA_real_,
    wmape_completo = if (nrow(rc)) rc$wmape_pct else NA_real_,
    wmape_sem2024 = if (nrow(rs)) rs$wmape_pct else NA_real_,
    jaccard_entre_cenarios_pct = jac_cen,
    jaccard_vs_puro_completo_pct = jac_puro_c,
    jaccard_vs_puro_sem2024_pct = jac_puro_s,
    stringsAsFactors = FALSE)
}
sens <- bind_rows(linhas_sens)
write_tsv(sens, file.path(DIR_TABELAS, "sensibilidade_2024_satscan.tsv"))

# Matrizes de Jaccard entre modelos (dentro de cada cenário)
mat_jaccard <- function(cen) {
  mods <- names(rotulos)
  chaves <- paste(mods, cen, sep = "_")
  disp <- !vapply(chaves, function(k) is.null(membros[[k]]), logical(1))
  mods <- mods[disp]; chaves <- chaves[disp]
  m <- matrix(NA_real_, nrow = length(chaves), ncol = length(chaves),
              dimnames = list(rotulos[mods], rotulos[mods]))
  for (i in seq_along(chaves)) for (j in seq_along(chaves)) {
    m[i, j] <- jaccard_pct(membros[[chaves[i]]], membros[[chaves[j]]])
  }
  m
}
mj_c <- mat_jaccard("completo")
mj_s <- mat_jaccard("sem2024")
write.table(round(mj_c, 2), file.path(DIR_TABELAS, "jaccard_satscan_completo.tsv"),
            sep = "\t", quote = FALSE, col.names = NA, fileEncoding = "UTF-8")
write.table(round(mj_s, 2), file.path(DIR_TABELAS, "jaccard_satscan_sem2024.tsv"),
            sep = "\t", quote = FALSE, col.names = NA, fileEncoding = "UTF-8")

# ---- 3. Tabelas LaTeX ------------------------------------------------------- #
# 3.1 Tabela comparativa dos ajustes (2010-2025): zonas, polo, RR, cobertura
#     e WMAPE nacional, com a redução do WMAPE em relação ao modelo sem ajuste.
UF_SIGLA <- c("11"="RO","12"="AC","13"="AM","14"="RR","15"="PA","16"="AP",
              "17"="TO","21"="MA","22"="PI","23"="CE","24"="RN","25"="PB",
              "26"="PE","27"="AL","28"="SE","29"="BA","31"="MG","32"="ES",
              "33"="RJ","35"="SP","41"="PR","42"="SC","43"="RS","50"="MS",
              "51"="MT","52"="GO","53"="DF")
UF_NOME_SIGLA <- c("Rondônia"="RO","Acre"="AC","Amazonas"="AM","Roraima"="RR",
  "Pará"="PA","Amapá"="AP","Tocantins"="TO","Maranhão"="MA","Piauí"="PI",
  "Ceará"="CE","Rio Grande do Norte"="RN","Paraíba"="PB","Pernambuco"="PE",
  "Alagoas"="AL","Sergipe"="SE","Bahia"="BA","Minas Gerais"="MG",
  "Espírito Santo"="ES","Rio de Janeiro"="RJ","São Paulo"="SP","Paraná"="PR",
  "Santa Catarina"="SC","Rio Grande do Sul"="RS","Mato Grosso do Sul"="MS",
  "Mato Grosso"="MT","Goiás"="GO","Distrito Federal"="DF")

cmp_tab <- resumo %>%
  filter(cenario == "completo") %>%
  mutate(ord = match(modelo, names(rotulos))) %>%
  arrange(ord) %>%
  transmute(
    Ajuste = rotulo,
    Zonas = fmt_br(n_zonas, 0),
    Polo = sprintf("%s (%s)", prim_polo, UF_SIGLA[match(prim_uf, names(UF_NOME_SIGLA))]),
    RR = fmt_br(prim_rr, 2),
    Cob = sprintf("%s\\%%", fmt_br(cob_casos_pct, 1)),
    WMAPE = fmt_br(wmape_pct, 1),
    Reducao = ifelse(modelo == "puro", "—", fmt_br(reducao_pp, 1)))

cria_tabela_comparacao <- function() {
  k <- kable(cmp_tab, format = "latex", booktabs = TRUE, escape = FALSE,
             col.names = c("Ajuste", "Zonas", "Primário (polo)", "$RR$",
                           "\\% dos casos", "WMAPE (\\%)", "Redução (p.p.)"),
             align = c("l", "c", "l", "c", "c", "c", "c"),
             caption = "Comparação dos ajustes por covariáveis na varredura espacial: zonas significativas, polo primário, risco relativo, cobertura de casos e WMAPE nacional, Brasil, 2010--2025.",
             label = "comparacao_satscan")
  k <- kable_styling(k, latex_options = c("scale_down", "hold_position"), font_size = 9)
  as.character(k)
}
write_lines(cria_tabela_comparacao(), file.path(DIR_TABELAS, "tabela_comparacao_satscan.tex"))

# 3.2 Sensibilidade: zonas, polos e Jaccard entre cenários
cria_tabela_sens <- function() {
  df <- data.frame(
    Ajuste = sens$rotulo,
    Zonas_com = fmt_br(sens$zonas_completo, 0),
    Zonas_sem = fmt_br(sens$zonas_sem2024, 0),
    Prim_com = ifelse(is.na(sens$prim_polo_completo), "—",
                      sprintf("%s (%s)", sens$prim_polo_completo,
                              UF_SIGLA[match(sens$prim_uf_completo, names(UF_NOME_SIGLA))])),
    Prim_sem = ifelse(is.na(sens$prim_polo_sem2024), "—",
                      sprintf("%s (%s)", sens$prim_polo_sem2024,
                              UF_SIGLA[match(sens$prim_uf_sem2024, names(UF_NOME_SIGLA))])),
    Jaccard = ifelse(is.na(sens$jaccard_entre_cenarios_pct), "—",
                     sprintf("%s\\%%", fmt_br(sens$jaccard_entre_cenarios_pct, 0))),
    stringsAsFactors = FALSE)
  k <- kable(df, format = "latex", booktabs = TRUE, escape = FALSE,
             col.names = c("Ajuste", "Com 2024", "Sem 2024",
                           "Com 2024", "Sem 2024", "Jaccard"),
             align = c("l", "c", "c", "l", "l", "c"),
             caption = "Sensibilidade à exclusão de 2024 na varredura espacial: número de zonas, polo primário e sobreposição municipal entre os cenários (2010--2025 e sem 2024), Brasil.",
             label = "sensibilidade_satscan")
  # Subcabeçalhos "Com 2024" / "Sem 2024" identificam cada cenário sob os grupos
  # de topo (zonas e polo primário), evitando os rótulos repetidos anteriores.
  k <- add_header_above(k, c(" " = 1, "Zonas (n)" = 2, "Polo primário" = 2,
                             "Sobreposição entre cenários" = 1))
  k <- kable_styling(k, latex_options = c("scale_down", "hold_position"), font_size = 9)
  as.character(k)
}
write_lines(cria_tabela_sens(), file.path(DIR_TABELAS, "tabela_sensibilidade_satscan.tex"))

# ---- 3.3 Decomposição regional (diagnóstico suplementar) -------------------- #
# WMAPE por Grande Região e por modelo/cenário, a partir dos TSV municipais.
# Diagnóstico suplementar: o WMAPE nacional pondera os casos e pode ocultar
# heterogeneidade regional no ajuste.
uf_regiao <- data.frame(
  CD_UF = c("11","12","13","14","15","16","17","21","22","23","24","25","26",
            "27","28","29","31","32","33","35","41","42","43","50","51","52","53"),
  REGIAO = c(rep("Norte", 7), rep("Nordeste", 9), rep("Sudeste", 4),
             rep("Sul", 3), rep("Centro-Oeste", 4)),
  stringsAsFactors = FALSE)
dec_reg <- bind_rows(lapply(names(municipais), function(k) {
  mun <- municipais[[k]]
  chave <- strsplit(k, "_", fixed = TRUE)[[1]]
  mod <- chave[1]; cen <- paste(chave[-1], collapse = "_")
  mun %>%
    mutate(CD_UF = sprintf("%02d", as.integer(CD_UF))) %>%
    left_join(uf_regiao, by = "CD_UF") %>%
    group_by(REGIAO) %>%
    summarise(erro_abs = sum(ERRO_ABS), observado = sum(OBSERVADO),
              wmape_pct = 100 * sum(ERRO_ABS) / sum(OBSERVADO), .groups = "drop") %>%
    mutate(modelo = mod, cenario = cen,
           pct_erro_total = 100 * erro_abs / sum(erro_abs)) %>%
    select(modelo, cenario, REGIAO, wmape_pct, erro_abs, observado, pct_erro_total)
}))
write_tsv(dec_reg, file.path(DIR_TABELAS, "wmape_regional_satscan.tsv"))

# ---- 3.4 Decomposição dentro/fora das zonas do modelo sem ajuste ------------ #
# Separa o erro agregado em dois grupos de municípios: os que pertencem às zonas
# significativas do modelo sem ajuste (sinal espacial) e os demais (baseline).
# Leitura descritiva: um ajuste interessante reduz o erro na baseline sem
# absorver o sinal das zonas do modelo sem ajuste.
dec_decomp <- bind_rows(lapply(names(municipais), function(k) {
  mun <- municipais[[k]]
  chave <- strsplit(k, "_", fixed = TRUE)[[1]]
  mod <- chave[1]; cen <- paste(chave[-1], collapse = "_")
  memb <- membros[[paste("puro", cen, sep = "_")]]
  if (is.null(memb)) return(NULL)
  mun$GRUPO <- ifelse(mun$ID_MN_RESI %in% as.character(memb),
                      "dentro_zonas_puro", "fora_zonas_puro")
  mun %>%
    group_by(GRUPO) %>%
    summarise(n_municipios = n(), observado = sum(OBSERVADO),
              erro_abs = sum(ERRO_ABS),
              wmape_pct = 100 * sum(ERRO_ABS) / sum(OBSERVADO), .groups = "drop") %>%
    mutate(modelo = mod, cenario = cen) %>%
    select(modelo, cenario, GRUPO, n_municipios, observado, erro_abs, wmape_pct)
}))
write_tsv(dec_decomp, file.path(DIR_TABELAS, "wmape_dentro_fora_zonas_satscan.tsv"))

# ---- 4. Log ----------------------------------------------------------------- #
linhas_log <- c(
  "log_auditoria_wmape_satscan - consolidação das rodadas do SaTScan",
  sprintf("modelos_lidos=%d/%d (2 cenários)", nrow(resumo), 2 * length(rotulos)),
  sprintf("checagens_wmape=%s", if (all(resumo$checagem == "ok")) "todas ok (recálculo independente confere)" else "FALHAS DETECTADAS"),
  sprintf("cenario_completo: %s", paste(sprintf("%s=%.2f%%", resumo$rotulo[resumo$cenario == "completo"], resumo$wmape_pct[resumo$cenario == "completo"]), collapse = " | ")),
  sprintf("cenario_sem2024: %s", paste(sprintf("%s=%.2f%%", resumo$rotulo[resumo$cenario == "sem2024"], resumo$wmape_pct[resumo$cenario == "sem2024"]), collapse = " | ")),
  sprintf("sensibilidade_2024 (Jaccard entre cenários): %s",
          paste(sprintf("%s=%.0f%%", sens$rotulo, sens$jaccard_entre_cenarios_pct), collapse = " | ")))
write_lines(linhas_log, file.path(DIR_LOGS, "log_auditoria_wmape_satscan.txt"))

cat("\n--- RESUMO CONSOLIDADO (por modelo x cenário) ---\n")
print(as.data.frame(resumo %>% select(modelo, cenario, n_zonas, prim_polo, prim_rr, wmape_pct, reducao_pp, checagem)), row.names = FALSE)
cat("\n--- SENSIBILIDADE (completo vs sem 2024) ---\n")
print(as.data.frame(sens %>% select(modelo, zonas_completo, zonas_sem2024, prim_polo_completo, prim_polo_sem2024, jaccard_entre_cenarios_pct)), row.names = FALSE)
cat("\nArtefatos:\n")
print(sort(list.files(here::here("output"), recursive = TRUE, pattern = "^(wmape_|sensibilidade_|jaccard_|tabela_(comparacao|sensibilidade)|log_auditoria_wmape)")))
