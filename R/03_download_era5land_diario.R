here::i_am("R/03_download_era5land_diario.R")

library(ecmwfr)

dir_saida <- here::here("data", "raw", "clima", "era5land_diario")
dir.create(dir_saida, showWarnings = FALSE, recursive = TRUE)

# Credencial do CDS: configure CDS_EMAIL no ambiente, nunca no código versionado.
SEU_EMAIL <- Sys.getenv("CDS_EMAIL")
if (!nzchar(SEU_EMAIL)) {
  stop("Defina CDS_EMAIL no ambiente antes de executar o download.")
}

anos_restantes <- 2010:2025
falhas <- character()

cat(sprintf("Iniciando download ERA5-Land (%d anos pendentes)...\n\n", length(anos_restantes)))

for (ano in anos_restantes) {
  arq_nc <- file.path(dir_saida, sprintf("era5land_t2m_%d.nc", ano))
  
  if (file.exists(arq_nc)) {
    cat(sprintf("[%d] Já existe em disco. Pulando...\n", ano))
    next
  }
  
  cat(sprintf("[%d] Enviando requisição ao CDS API...\n", ano))
  t0 <- Sys.time()
  
  req <- list(
    dataset_short_name = "reanalysis-era5-land",
    variable           = "2m_temperature",
    year               = as.character(ano),
    month              = sprintf("%02d", 1:12),
    day                = sprintf("%02d", 1:31),
    time               = c("00:00", "06:00", "12:00", "18:00"),
     area               = c(5.5, -74.0, -34.5, -34.0), # norte, oeste, sul, leste
    data_format        = "netcdf",
    download_format    = "unarchived",
    target             = basename(arq_nc)
  )
  
  tryCatch({
    wf_request(
      user     = SEU_EMAIL,
      request  = req,
      transfer = TRUE,
      path     = dir_saida,
      time_out = 7200
    )
    tempo_gasto <- round(difftime(Sys.time(), t0, units = "mins"), 1)
    cat(sprintf("[%d] Concluído em %s minutos.\n\n", ano, tempo_gasto))
  }, error = function(e) {
    falhas <<- c(falhas, sprintf("%d: %s", ano, e$message))
    cat(sprintf("[%d] ERRO: %s\n\n", ano, e$message))
  })
}

arquivos <- file.path(dir_saida, sprintf("era5land_t2m_%d.nc", anos_restantes))
ausentes <- arquivos[!file.exists(arquivos)]
info_arquivos <- file.info(arquivos)
vazios <- arquivos[file.exists(arquivos) & !is.na(info_arquivos$size) & info_arquivos$size <= 0]
if (length(falhas) || length(ausentes) || length(vazios)) {
  stop(
    "Download ERA5-Land incompleto. Falhas: ", paste(falhas, collapse = " | "),
    "; ausentes: ", paste(basename(ausentes), collapse = ", "),
    "; vazios: ", paste(basename(vazios), collapse = ", ")
  )
}

cat("Pipeline de download concluído; 16 arquivos verificados.\n")
