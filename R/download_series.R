# Download series from Banco Central do Brasil (BCB)
# Using rbcb::get_series

suppressPackageStartupMessages({
  library(rbcb)
  library(dplyr)
  library(readr)
})

# Create logs directory if it doesn't exist
dir.create("logs", showWarnings = FALSE)

# Define reference date (provided as parameter)
today <- as.Date("2026-06-01")
lookback_start <- today - 365 * 5  # 5 years back

# Define series to download
series_list <- list(
  ipca = list(code = 433, name = "IPCA mensal"),
  cambio = list(code = 1, name = "Câmbio R$/US$"),
  selic = list(code = 432, name = "Selic meta"),
  ibc_original = list(code = 24363, name = "IBC-Br original"),
  ibc_sa = list(code = 24364, name = "IBC-Br com ajuste sazonal")
)

# Create output directory
output_dir <- "output/dados"
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# Initialize results tracking
results <- list()
errors_log <- c()

# Download each series
for (series_name in names(series_list)) {
  series_code <- series_list[[series_name]]$code
  series_desc <- series_list[[series_name]]$name

  cat(sprintf("Downloading %s (SGS %d)...\n", series_desc, series_code))

  tryCatch({
    # Download series using rbcb::get_series
    # Note: rbcb returns a tibble with 'date' and column named after the code
    data <- rbcb::get_series(code = series_code)

    # Check if data is empty or NULL
    if (is.null(data) || nrow(data) == 0) {
      error_msg <- sprintf("Série %s (SGS %d): nenhum dado retornado", series_desc, series_code)
      errors_log <- c(errors_log, error_msg)
      results[[series_name]] <- list(status = "falha", rows = 0, error = error_msg)
      cat(sprintf("  ERROR: %s\n", error_msg))
      next
    }

    # Convert to appropriate format
    # The value column is named with the series code, so we need to get it dynamically
    value_col <- as.character(series_code)

    data <- data %>%
      rename(data = date, valor = all_of(value_col)) %>%
      select(data, valor) %>%
      filter(!is.na(valor)) %>%
      filter(data >= lookback_start & data <= today) %>%
      arrange(data)

    # Check if after filtering we still have data
    if (nrow(data) == 0) {
      error_msg <- sprintf("Série %s (SGS %d): nenhum dado no período especificado", series_desc, series_code)
      errors_log <- c(errors_log, error_msg)
      results[[series_name]] <- list(status = "falha", rows = 0, error = error_msg)
      cat(sprintf("  ERROR: %s\n", error_msg))
      next
    }

    # Define output filename
    output_file <- file.path(output_dir, sprintf("%s.csv", series_name))

    # Save as CSV
    write_csv(data, output_file)

    results[[series_name]] <- list(
      status = "sucesso",
      rows = nrow(data),
      file = output_file,
      date_range = sprintf("%s a %s", min(data$data), max(data$data))
    )

    cat(sprintf("  OK: %s (%d linhas, %s a %s)\n",
                output_file, nrow(data), min(data$data), max(data$data)))

  }, error = function(e) {
    error_msg <- sprintf("Série %s (SGS %d): %s", series_desc, series_code, e$message)
    errors_log <<- c(errors_log, error_msg)
    results[[series_name]] <<- list(status = "falha", error = error_msg)
    cat(sprintf("  ERRO: %s\n", e$message))
  })
}

# Write error log if there are any errors
if (length(errors_log) > 0) {
  error_file <- "logs/erros.md"
  cat("# Erros ao baixar séries\n\n", file = error_file)
  cat(sprintf("Data: %s\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S")), file = error_file, append = TRUE)
  cat(sprintf("Data de referência: %s\n\n", today), file = error_file, append = TRUE)
  for (error in errors_log) {
    cat(sprintf("- %s\n", error), file = error_file, append = TRUE)
  }
}

# Print summary
cat("\n========== RESUMO DO DOWNLOAD ==========\n")
cat(sprintf("Data de referência: %s\n", today))
cat(sprintf("Período: %s a %s\n\n", format(lookback_start, "%Y-%m-%d"), format(today, "%Y-%m-%d")))

successes <- 0
failures <- 0

for (series_name in names(results)) {
  result <- results[[series_name]]
  if (result$status == "sucesso") {
    successes <- successes + 1
    cat(sprintf("✓ %s\n", series_name))
    cat(sprintf("  Arquivo: %s\n", result$file))
    cat(sprintf("  Registros: %d\n", result$rows))
    cat(sprintf("  Período: %s\n\n", result$date_range))
  } else {
    failures <- failures + 1
    cat(sprintf("✗ %s (FALHA)\n", series_name))
    cat(sprintf("  Erro: %s\n\n", result$error))
  }
}

cat("=========================================\n")
cat(sprintf("Total: %d sucesso(s), %d falha(s)\n", successes, failures))

if (failures == length(series_list)) {
  cat("\nERRO: Todas as séries falharam!\n")
  quit(status = 1)
} else if (failures > 0) {
  cat("\nAVISO: Algumas séries falharam (veja logs/erros.md)\n")
  quit(status = 0)
} else {
  cat("\nSUCESSO: Todas as séries foram baixadas com sucesso!\n")
  quit(status = 0)
}
