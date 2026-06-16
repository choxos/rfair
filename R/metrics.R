# Loading and parsing of the FAIRsFAIR metric definitions, ported from
# fuji_server/helper/metric_helper.py.

# Cache of parsed metric specifications, keyed by version.
.metrics_cache <- new.env(parent = emptyenv())

# Regexes that extract the version-agnostic identifiers (metric_helper.py:22-23).
.METRIC_REGEX <- "^FsF-[FAIR][0-9]?(\\.[0-9])?-[0-9]+[MD]+|FRSM-[0-9]+-[FAIR][0-9]?(\\.[0-9])?"
.METRIC_TEST_REGEX <- "FsF-[FAIR][0-9]?(\\.[0-9])?-[0-9]+[MD]+(-[0-9\\+]+[a-z]?)|^FRSM-[0-9]+-[FAIR][0-9]?(\\.[0-9])?(?:-[a-zA-Z]+)?(-[0-9]+)?"

# Historical FsF metric files use older identifier spellings for tests that now
# share the same implementation. Keep this map deliberately small: metrics with
# materially different semantics get their own evaluator wrapper in zzz.R.
.METRIC_EVALUATOR_ALIASES <- c(
  "FsF-F1-01D" = "FsF-F1-01MD",
  "FsF-F1-01M" = "FsF-F1-01MD",
  "FsF-F1-01DD" = "FsF-F1-01MD",
  "FsF-F1-02D" = "FsF-F1-02MD",
  "FsF-F1-02M" = "FsF-F1-02MD",
  "FsF-F1-02DD" = "FsF-F1-02MD",
  "FsF-I1-02M" = "FsF-I2-01M",
  "FsF-R1-01MD" = "FsF-R1-01M"
)

#' First regex match of `pattern` in `x` (perl), or NA.
#' @noRd
re_first <- function(pattern, x) {
  if (!is_nonempty_string(x)) return(NA_character_)
  m <- regexpr(pattern, x, perl = TRUE)
  if (m == -1L) return(NA_character_)
  regmatches(x, m)
}

#' Canonical evaluator key for a metric identifier.
#' @noRd
canonical_metric_identifier <- function(metric_identifier) {
  agnostic <- re_first(.METRIC_REGEX, metric_identifier)
  if (is.na(agnostic)) return(NA_character_)
  if (agnostic %in% names(.METRIC_EVALUATOR_ALIASES)) .METRIC_EVALUATOR_ALIASES[[agnostic]] else agnostic
}

#' Normalize a metric version string to the bundled YAML file name.
#' @noRd
metric_file_name <- function(version) {
  v <- as.character(version)
  if (!grepl("\\.yaml$", v)) v <- paste0(v, ".yaml")
  if (!startsWith(v, "metrics_v")) v <- paste0("metrics_v", v)
  v
}

#' Load (and cache) a parsed metric specification.
#'
#' @param version Metric version, e.g. "0.8" or "metrics_v0.8".
#' @return A list with elements `config`, `metrics` (raw list), `custom`
#'   (named by agnostic identifier), `version`, and `metric_specification`.
#' @noRd
load_metrics <- function(version = "0.8") {
  fname <- metric_file_name(version)
  if (!is.null(.metrics_cache[[fname]])) return(.metrics_cache[[fname]])

  path <- system.file("extdata", "metrics", fname, package = "rfuji")
  if (!nzchar(path)) {
    stop(sprintf("Metric version '%s' is not bundled with rfuji (looked for %s).",
                 version, fname), call. = FALSE)
  }
  spec <- yaml::read_yaml(path)
  config <- spec$config %||% list()
  metrics <- spec$metrics %||% list()

  ver <- sub("^metrics_v(.*)\\.yaml$", "\\1", fname)
  metric_spec <- config$metric_specification %||% "https://doi.org/10.5281/zenodo.6461229"

  out <- list(
    config = config,
    metrics = metrics,
    custom = build_custom_metrics(metrics),
    version = ver,
    metric_specification = metric_spec
  )
  .metrics_cache[[fname]] <- out
  out
}

#' Build the agnostic-identifier-keyed metric map (metric_helper.get_custom_metrics).
#' @noRd
build_custom_metrics <- function(metrics) {
  out <- list()
  for (m in metrics) {
    mid <- m$metric_identifier %||% NA_character_
    agnostic <- re_first(.METRIC_REGEX, mid)
    if (is.na(agnostic)) next
    m$agnostic_identifier <- agnostic
    if (is.list(m$metric_tests)) {
      m$metric_tests <- lapply(m$metric_tests, function(t) {
        tid <- t$metric_test_identifier %||% NA_character_
        t$agnostic_test_identifier <- re_first(.METRIC_TEST_REGEX, tid)
        t
      })
    }
    out[[agnostic]] <- m
  }
  out
}

#' List the metric versions bundled with rfuji.
#' @return Character vector of available metric versions (e.g. "0.8").
#' @export
#' @examples
#' rfuji_metric_versions()
rfuji_metric_versions <- function() {
  dir <- system.file("extdata", "metrics", package = "rfuji")
  files <- list.files(dir, pattern = "^metrics_v.*\\.yaml$")
  versions <- sub("^metrics_v(.*)\\.yaml$", "\\1", files)
  preferred <- c("0.8", "0.5", "0.5ssv2", "0.5ss", "0.5env",
                 "0.7_software", "0.7_software_cessda",
                 "0.6a2a", "0.4", "0.3", "0.2")
  c(preferred[preferred %in% versions], sort(setdiff(versions, preferred)))
}
