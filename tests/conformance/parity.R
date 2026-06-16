# Cross-engine parity: R engine vs TypeScript (web) engine.
#
# The TS engine is registry-only (browser CORS), so it cannot harvest landing
# pages; it should therefore score <= the R engine. This harness checks that for
# the metrics derivable from registry (DataCite/Crossref) metadata the two
# engines AGREE, catching logic drift between the two implementations.
#
# The web app lives on the separate `webapp` branch. Materialize it into ./webapp
# and install its deps first:
#   git worktree add webapp webapp && (cd webapp && npm install)
#   Rscript tests/conformance/parity.R [<id> ...]

suppressMessages(devtools::load_all(quiet = TRUE))

webapp <- "webapp"
if (!dir.exists(webapp)) {
  stop("Check out the web app branch into ./webapp first:\n",
       "  git worktree add webapp webapp && (cd webapp && npm install)",
       call. = FALSE)
}
data_dir <- normalizePath(file.path(webapp, "public", "data"), mustWork = TRUE)
bundle <- tempfile(fileext = ".mjs")
message("Bundling TS engine...")
esbuild <- file.path(webapp, "node_modules", ".bin", "esbuild")
if (!file.exists(esbuild)) {
  stop("Install web app deps first: (cd webapp && npm install)", call. = FALSE)
}
system2(esbuild, c(file.path(webapp, "scripts", "parity-entry.mts"),
                   "--bundle", "--platform=node", "--format=esm",
                   paste0("--outfile=", bundle), "--log-level=error"))

Sys.setenv(RFUJI_DATA = data_dir)
ts_scores <- function(id) {
  out <- system2("node", c(bundle, shQuote(id)), stdout = TRUE, stderr = FALSE)
  df <- jsonlite::fromJSON(paste(out, collapse = ""))
  stats::setNames(df$earned, df$metric)
}

# metrics derivable from registry metadata alone (no landing-page harvest)
CORE <- c("FsF-F1-01MD", "FsF-F1-02MD", "FsF-F2-01M", "FsF-R1.1-01M",
          "FsF-R1.2-01M", "FsF-R1.3-01M")

ids <- commandArgs(trailingOnly = TRUE)
if (!length(ids)) ids <- as.character(yaml::read_yaml("tests/conformance/identifiers.yaml"))

agree <- 0L; total <- 0L
for (id in ids) {
  message("- ", id)
  rdf <- as.data.frame(assess_fair(id, timeout = 60))
  r <- stats::setNames(rdf$earned, rdf$metric_identifier)
  ts <- tryCatch(ts_scores(id), error = function(e) { message("  TS error: ", conditionMessage(e)); NULL })
  if (is.null(ts)) next
  for (m in CORE) {
    if (!is.na(r[[m]]) && !is.null(ts[[m]])) {
      total <- total + 1L
      if (isTRUE(r[[m]] == ts[[m]])) agree <- agree + 1L
      else message(sprintf("  DRIFT %s: R=%s TS=%s", m, r[[m]], ts[[m]]))
    }
  }
}
cat(sprintf("\nR<->TS parity on registry-core metrics: %d/%d (%.0f%%)\n",
            agree, total, if (total) 100 * agree / total else 0))
