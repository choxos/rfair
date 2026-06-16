# data-raw/02-build-extdata.R
#
# Bundle the F-UJI metrics YAML definitions into inst/extdata/metrics/ so the
# engine can load them at runtime (and users can select a metric version).
# Larger, lazily-loaded reference tables (e.g. community metadata standards for
# Phase 3) are added here later.
#
# Usage:
#   FUJI_SRC=~/Documents/GitHub/fuji/fuji_server Rscript data-raw/02-build-extdata.R

fuji_src <- path.expand(Sys.getenv("FUJI_SRC", unset = "~/Documents/GitHub/fuji/fuji_server"))
yaml_dir <- file.path(fuji_src, "yaml")
stopifnot("FUJI_SRC yaml dir not found" = dir.exists(yaml_dir))

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

# Metric versions rfuji supports (default first). These mirror the public
# f-uji.net selector plus older release-specific YAMLs kept in upstream tags.
supported <- c(
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
)

dest_dir <- file.path(pkg_root, "inst", "extdata", "metrics")
dir.create(dest_dir, recursive = TRUE, showWarnings = FALSE)

for (f in supported) {
  src <- file.path(yaml_dir, f)
  stopifnot(file.exists(src))
  ok <- file.copy(src, file.path(dest_dir, f), overwrite = TRUE)
  message(sprintf("  %s metrics/%s", if (ok) "copied" else "FAILED", f))
}

message(sprintf("Bundled %d metric file(s) into %s", length(supported), dest_dir))
