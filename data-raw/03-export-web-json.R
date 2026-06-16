# data-raw/03-export-web-json.R
#
# Export the metrics + reference lookup tables as JSON into inst/extdata/web/.
# These files are the single source of truth consumed by the TypeScript web
# app (which reimplements the scoring logic but must use identical data).
#
# Usage (run after 01 and 02):
#   FUJI_SRC=~/Documents/GitHub/fuji/fuji_server Rscript data-raw/03-export-web-json.R

`%||%` <- function(x, y) if (is.null(x) || length(x) == 0L) y else x

find_pkg_root <- function(start = getwd()) {
  d <- normalizePath(start, mustWork = FALSE)
  repeat {
    if (file.exists(file.path(d, "DESCRIPTION"))) return(d)
    parent <- dirname(d)
    if (identical(parent, d)) stop("Could not find package root (DESCRIPTION).")
    d <- parent
  }
}
pkg_root <- find_pkg_root()

load(file.path(pkg_root, "R", "sysdata.rda"))  # -> rfuji_data
web_dir <- file.path(pkg_root, "inst", "extdata", "web")
dir.create(web_dir, recursive = TRUE, showWarnings = FALSE)

write_min <- function(x, name, pretty = FALSE) {
  f <- file.path(web_dir, name)
  jsonlite::write_json(x, f, auto_unbox = TRUE, null = "null", na = "null", pretty = pretty)
  message(sprintf("  wrote web/%s (%s)", name,
                  format(structure(file.size(f), class = "object_size"), units = "auto")))
}

## metrics (parsed) ----------------------------------------------------------
metrics_dir <- file.path(pkg_root, "inst", "extdata", "metrics")
metrics_files <- list.files(metrics_dir, pattern = "^metrics_v.*\\.yaml$", full.names = TRUE)
metrics_files <- metrics_files[order(match(basename(metrics_files), c(
  "metrics_v0.8.yaml",
  "metrics_v0.5.yaml",
  "metrics_v0.5ssv2.yaml",
  "metrics_v0.5ss.yaml",
  "metrics_v0.5env.yaml",
  "metrics_v0.7_software.yaml",
  "metrics_v0.7_software_cessda.yaml",
  "metrics_v0.6a2a.yaml",
  "metrics_v0.4.yaml",
  "metrics_v0.3.yaml",
  "metrics_v0.2.yaml"
)), basename(metrics_files))]
for (metrics_file in metrics_files) {
  out_name <- sub("\\.yaml$", ".json", basename(metrics_file))
  write_min(yaml::read_yaml(metrics_file), out_name, pretty = TRUE)
}

## SPDX licenses (trimmed) ---------------------------------------------------
spdx_min <- lapply(rfuji_data$spdx, function(L) list(
  licenseId = L$licenseId, name = L$name,
  detailsUrl = L$detailsUrl, isOsiApproved = L$isOsiApproved,
  seeAlso = as.list(L$seeAlso)
))
write_min(spdx_min, "licenses.json")

## File formats (mime membership) -------------------------------------------
write_min(list(
  science   = as.list(names(rfuji_data$science_file_formats)),
  long_term = as.list(names(rfuji_data$long_term_file_formats)),
  open      = as.list(names(rfuji_data$open_file_formats))
), "file_formats.json")

## Access rights (flattened code/uri -> condition) --------------------------
ar_flat <- list()
for (vocab_name in names(rfuji_data$access_rights)) {
  vocab <- rfuji_data$access_rights[[vocab_name]]
  for (m in (vocab$members %||% list())) {
    ar_flat[[length(ar_flat) + 1L]] <- list(
      vocab            = vocab_name,
      id               = m$id,
      uri              = m$uri,
      access_condition = m$access_condition,
      label            = m$label
    )
  }
}
write_min(ar_flat, "access_rights.json")

## Standard protocols --------------------------------------------------------
write_min(rfuji_data$standard_protocols, "standard_protocols.json")

message(sprintf("Exported web JSON into %s", web_dir))
