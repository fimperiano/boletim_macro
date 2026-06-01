#!/usr/bin/env Rscript

library(rbcb)

# Configuration
ref_date <- as.Date("2026-06-01")
start_date <- ref_date - 365 * 5  # 5 years back

# Series definition
series_list <- list(
  list(code = 433, name = "ipca", filename = "ipca.csv"),
  list(code = 1, name = "cambio", filename = "cambio.csv"),
  list(code = 432, name = "selic", filename = "selic.csv"),
  list(code = 24363, name = "ibc_original", filename = "ibc_original.csv"),
  list(code = 24364, name = "ibc_sa", filename = "ibc_sa.csv")
)

output_dir <- "c:\\Users\\Amanda Tavares\\OneDrive\\Documentos\\GitHub\\boletim_macro\\output\\dados"
errors_log <- "c:\\Users\\Amanda Tavares\\OneDrive\\Documentos\\GitHub\\boletim_macro\\logs\\erros.md"

# Create logs directory if needed
dir.create("c:\\Users\\Amanda Tavares\\OneDrive\\Documentos\\GitHub\\boletim_macro\\logs", showWarnings = FALSE)

# Initialize log
write("# Download Log\n", file = errors_log, append = FALSE)

results <- list()

for (series in series_list) {
  cat(sprintf("Downloading series %s (%d)...\n", series$name, series$code))

  tryCatch({
    # Download series
    data <- get_series(
      code = series$code,
      start_date = start_date,
      end_date = ref_date
    )

    # Check if data is empty
    if (is.null(data) || nrow(data) == 0) {
      stop("No data returned")
    }

    # Format data: ensure we have data and valor columns, convert date to ISO format
    df <- as.data.frame(data)
    names(df) <- c("data", "valor")
    df$data <- as.character(as.Date(df$data))
    df <- df[order(df$data), ]

    # Save to CSV
    filepath <- file.path(output_dir, series$filename)
    write.csv(df, file = filepath, row.names = FALSE, quote = FALSE)

    n_rows <- nrow(df)
    results[[series$name]] <- list(
      status = "success",
      file = filepath,
      rows = n_rows
    )

    cat(sprintf("  OK: %d rows\n", n_rows))

  }, error = function(e) {
    results[[series$name]] <<- list(
      status = "error",
      message = as.character(e)
    )

    cat(sprintf("  ERROR: %s\n", as.character(e)))

    # Log error
    write(
      sprintf("## %s (SGS %d)\n\nError: %s\n\n", series$name, series$code, as.character(e)),
      file = errors_log,
      append = TRUE
    )
  })
}

# Summary report
cat("\n=== SUMMARY ===\n")
cat("Generated files:\n")
for (name in names(results)) {
  res <- results[[name]]
  if (res$status == "success") {
    cat(sprintf("  - %s: %d rows\n", res$file, res$rows))
  } else {
    cat(sprintf("  - %s: FAILED (%s)\n", name, res$message))
  }
}

# Exit with appropriate code
failed_count <- sum(sapply(results, function(x) x$status == "error"))
if (failed_count == length(results)) {
  cat("\nAll series failed. Stop.\n")
  quit(status = 1)
} else if (failed_count > 0) {
  cat(sprintf("\n%d/%d series failed. Continuing.\n", failed_count, length(results)))
  quit(status = 0)
} else {
  cat("\nAll series downloaded successfully.\n")
  quit(status = 0)
}
