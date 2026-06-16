# Top-level assessment orchestrator, mirroring
# fuji_server/controllers/fair_object_controller.py::assess_by_id and the
# FAIRCheck driver in controllers/fair_check.py.

#' Create the engine state environment (the R analogue of `FAIRCheck`).
#' @noRd
metadata_service_types <- function() {
  c("oai_pmh", "ogc_csw", "sparql", "dcat", "schema_org", "datacite",
    "crossref", "signposting", "typed_links", "ro_crate", "ckan", "other")
}

new_engine_ctx <- function(id, metrics_meta, use_datacite = TRUE, test_debug = FALSE,
                           metadata_service_endpoint = NULL,
                           metadata_service_type = NULL) {
  ctx <- new.env(parent = emptyenv())
  ctx$id <- id
  ctx$use_datacite <- use_datacite
  ctx$test_debug <- test_debug
  ctx$metadata_service_endpoint <- metadata_service_endpoint
  ctx$metadata_service_type <- metadata_service_type
  ctx$metrics <- metrics_meta
  ctx$pid <- NULL
  ctx$pid_url <- NA_character_
  ctx$id_scheme <- NA_character_
  ctx$pid_scheme <- NA_character_
  ctx$is_persistent <- FALSE
  ctx$landing_url <- NA_character_
  ctx$landing_html <- NULL
  ctx$landing_content_type <- NA_character_
  ctx$landing_headers <- NULL
  ctx$typed_links <- list()
  ctx$metadata_merged <- list()
  ctx$metadata_unmerged <- list()
  ctx$metadata_sources <- list()
  ctx$related_resources <- list()
  ctx$pid_collector <- list()
  ctx$content_identifier <- list()
  ctx$github_data <- list()
  ctx$log <- list()
  ctx
}

#' Append a debug log message to the engine state.
#' @noRd
ctx_log <- function(ctx, metric, level, msg) {
  if (isTRUE(ctx$test_debug)) {
    ctx$log[[length(ctx$log) + 1L]] <- sprintf("%s|%s: %s", metric, toupper(level), msg)
  }
  invisible()
}

#' Run every metric's evaluator (or a baseline fail) over the engine state.
#' @noRd
run_evaluators <- function(ctx, metrics_meta) {
  results <- vector("list", length(metrics_meta$metrics))
  for (i in seq_along(metrics_meta$metrics)) {
    metric_def <- metrics_meta$metrics[[i]]
    res <- new_metric_evaluation(metric_def)
    evaluator <- get_evaluator(metric_def$metric_identifier %||% "")
    if (!is.null(evaluator)) {
      tryCatch(evaluator(ctx, res), error = function(e) {
        ctx_log(ctx, metric_def$metric_identifier, "failure",
                paste("evaluator error:", conditionMessage(e)))
      })
    }
    results[[i]] <- finalize_result(res)
  }
  ord <- order(vapply(results, function(r) r$id %||% NA_integer_, integer(1)), na.last = TRUE)
  results[ord]
}

#' Assess the FAIRness of a research data object.
#'
#' Resolves a persistent identifier or URL, harvests its metadata, and scores it
#' against the FAIRsFAIR metrics, entirely in R.
#'
#' @param id A persistent identifier or URL (DOI, Handle, ARK, URN, ...).
#' @param metric_version Metric version to use (see [rfuji_metric_versions()]).
#' @param use_datacite Whether to query DataCite for registry metadata.
#' @param metadata_service_endpoint Optional metadata service endpoint or
#'   metadata document URL (for example OAI-PMH, OGC CSW, SPARQL, DCAT,
#'   schema.org JSON-LD, DataCite, Crossref, Signposting, typed links,
#'   RO-Crate, or CKAN).
#' @param metadata_service_type Type of `metadata_service_endpoint`.
#' @param test_debug If `TRUE`, collect debug log messages in the result.
#' @param resolve If `TRUE`, resolve the identifier to its landing page.
#' @param timeout Per-request timeout in seconds.
#' @param use_headless If `TRUE` and the optional `chromote` package is
#'   installed, render JavaScript-heavy landing pages with a headless browser
#'   before harvesting embedded metadata.
#' @return A [fair_assessment] object.
#' @export
#' @examples
#' \donttest{
#' a <- assess_fair("https://doi.org/10.5281/zenodo.8347772")
#' summary(a)
#' }
assess_fair <- function(id, metric_version = "0.8", use_datacite = TRUE,
                        metadata_service_endpoint = NULL,
                        metadata_service_type = metadata_service_types(),
                        test_debug = FALSE, resolve = TRUE, timeout = 15,
                        use_headless = FALSE) {
  if (!is_nonempty_string(id)) stop("`id` must be a non-empty identifier or URL.", call. = FALSE)
  metadata_service_endpoint <- trimws(as.character(metadata_service_endpoint %||% ""))
  if (!nzchar(metadata_service_endpoint)) metadata_service_endpoint <- NULL
  metadata_service_type <- match.arg(metadata_service_type)
  start_time <- format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z")
  metrics_meta <- load_metrics(metric_version)
  ctx <- new_engine_ctx(
    id, metrics_meta, use_datacite = use_datacite, test_debug = test_debug,
    metadata_service_endpoint = metadata_service_endpoint,
    metadata_service_type = metadata_service_type
  )

  parsed <- id_parse(id)
  ctx$pid <- parsed
  ctx$pid_url <- parsed$identifier_url %||% id
  ctx$id_scheme <- parsed$preferred_schema
  ctx$is_persistent <- parsed$is_persistent

  if (isTRUE(resolve)) {
    landing <- tryCatch(resolve_landing_page(ctx$pid_url, timeout = timeout),
                        error = function(e) NULL)
    if (!is.null(landing) && isTRUE(landing$ok)) {
      ctx$landing_url <- landing$landing_url
      ctx$landing_html <- landing$content
      ctx$landing_content_type <- landing$content_type
      ctx$landing_headers <- landing$headers
    } else {
      ctx$landing_url <- ctx$pid_url
    }
  }

  if (isTRUE(resolve)) {
    # optionally render JS-heavy landing pages before harvesting embedded metadata
    if (isTRUE(use_headless) && is_nonempty_string(ctx$landing_url)) {
      rendered <- tryCatch(render_headless(ctx$landing_url, timeout = timeout * 2),
                           error = function(e) NULL)
      if (is_nonempty_string(rendered)) ctx$landing_html <- rendered
    }
    tryCatch(harvest_all_metadata(ctx, timeout = timeout), error = function(e) {
      ctx_log(ctx, "harvest", "failure", conditionMessage(e))
    })
  }

  results <- run_evaluators(ctx, metrics_meta)
  summary <- get_assessment_summary(results, input_id = id)

  # Reviewer-driven context beyond F-UJI: license reusability, controlled-access
  # / sensitivity, and identifier hygiene.
  reuse <- reuse_from_metadata(ctx$metadata_merged$license)
  content_urls <- as_chr(lapply(ctx$metadata_merged$object_content_identifier %||% list(),
                                function(x) if (is.list(x)) x$url else x))
  access <- classify_access(access_level = ctx$metadata_merged$access_level,
                            urls = unique(c(ctx$landing_url, ctx$pid_url, content_urls)))
  hygiene <- identifier_hygiene(id)
  end_time <- format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z")

  request <- list(object_identifier = id, metric_version = metrics_meta$version,
                  use_datacite = use_datacite,
                  metadata_service_endpoint = metadata_service_endpoint %||% "",
                  metadata_service_type = if (is.null(metadata_service_endpoint)) "" else metadata_service_type,
                  test_debug = test_debug)
  new_fair_assessment(
    id = id, request = request, results = results, summary = summary,
    resolved_url = ctx$landing_url %||% NA_character_, metrics_meta = metrics_meta,
    metadata = as.list(ctx$metadata_merged), start_time = start_time,
    end_time = end_time, log = if (test_debug) ctx$log else list(),
    reuse = reuse, access = access, identifier_hygiene = hygiene
  )
}
