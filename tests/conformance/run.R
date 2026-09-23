# rfair <-> F-UJI conformance harness  (non-CRAN; requires network)
#
# Runs a fixed set of identifiers through both the native rfair engine and a
# reference F-UJI server, then reports per-metric agreement and an overall
# fidelity %. Use it to track how closely the R port matches upstream as
# evaluators are added.
#
# Configure the reference server via environment variables:
#   FUJI_ENDPOINT  (default http://localhost:1071/fuji/api/v1/evaluate)
#   FUJI_USER, FUJI_PASS  (HTTP basic auth, if the instance requires it)
#   FUJI_METRIC_VERSION   (default 0.8; sent to F-UJI and used by rfair)
#   CONFORMANCE_OUT       (optional CSV path for the per-metric comparison)
# The scheduled workflow .github/workflows/conformance.yaml runs this against
# the F-UJI Docker image.
# Start a local, version-matched reference first (see tests/conformance/README.md).
#
# Usage:
#   Rscript tests/conformance/run.R                # all fixtures
#   Rscript tests/conformance/run.R <id> [<id>...] # specific identifiers

suppressMessages(devtools::load_all(quiet = TRUE))

endpoint <- Sys.getenv("FUJI_ENDPOINT", "http://localhost:1071/fuji/api/v1/evaluate")
user <- Sys.getenv("FUJI_USER", ""); pass <- Sys.getenv("FUJI_PASS", "")
metric_version <- Sys.getenv("FUJI_METRIC_VERSION", "0.8")

#' Query a reference F-UJI server and return per-metric earned/total/status.
fuji_reference <- function(id, timeout = 120) {
  body <- list(object_identifier = id, test_debug = FALSE, use_datacite = TRUE,
               metadata_service_endpoint = "", use_github = FALSE,
               metric_version = paste0("metrics_v", metric_version))
  req <- httr2::request(endpoint) |>
    httr2::req_method("POST") |>
    httr2::req_body_json(body) |>
    httr2::req_headers(Accept = "application/json") |>
    httr2::req_timeout(timeout) |>
    httr2::req_error(is_error = function(resp) FALSE)
  if (nzchar(user)) req <- httr2::req_auth_basic(req, user, pass)
  resp <- tryCatch(httr2::req_perform(req), error = function(e) NULL)
  if (is.null(resp) || httr2::resp_status(resp) >= 400) {
    message(sprintf("  ! reference F-UJI returned %s for %s",
                    if (is.null(resp)) "no response" else httr2::resp_status(resp), id))
    return(NULL)
  }
  out <- httr2::resp_body_json(resp)
  do.call(rbind, lapply(out$results, function(r) data.frame(
    metric_identifier = r$metric_identifier %||% NA_character_,
    ref_earned = r$score$earned %||% NA_real_,
    ref_total = r$score$total %||% NA_real_,
    ref_status = r$test_status %||% NA_character_,
    stringsAsFactors = FALSE)))
}

#' Compare rfair vs reference for one identifier.
compare_one <- function(id) {
  message("- ", id)
  rf <- as.data.frame(assess_fair(id, metric_version = metric_version, timeout = 60))[
    , c("metric_identifier", "earned", "total", "status")]
  ref <- fuji_reference(id)
  if (is.null(ref)) return(NULL)
  m <- merge(rf, ref, by = "metric_identifier", all = TRUE)
  m$earned_match <- !is.na(m$earned) & !is.na(m$ref_earned) & m$earned == m$ref_earned
  m$id <- id
  m
}

ids <- commandArgs(trailingOnly = TRUE)
if (!length(ids)) ids <- as.character(yaml::read_yaml("tests/conformance/identifiers.yaml"))

all <- do.call(rbind, Filter(Negate(is.null), lapply(ids, compare_one)))
if (is.null(all) || !nrow(all)) { message("No comparisons (reference server unreachable?)."); quit(status = 1) }

fidelity <- mean(all$earned_match, na.rm = TRUE)
by_metric <- aggregate(earned_match ~ metric_identifier, all, mean)
cat("\n==== per-metric earned-score agreement ====\n")
print(by_metric, row.names = FALSE)
cat(sprintf("\nOverall fidelity (earned-score match): %.1f%% over %d metric comparisons, %d identifiers\n",
            100 * fidelity, nrow(all), length(unique(all$id))))
out <- Sys.getenv("CONFORMANCE_OUT", "")
if (nzchar(out)) {
  all$metric_version <- metric_version
  all$rfair_version <- as.character(utils::packageVersion("rfair"))
  utils::write.csv(all, out, row.names = FALSE)
}
