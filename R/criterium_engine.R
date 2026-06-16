# Generic metric-test/scoring engine, ported from the base FAIREvaluator in
# fuji_server/evaluators/fair_evaluator.py (:115-198).
#
# A metric evaluation is held in an environment so evaluator predicates can
# mutate it in place (mirroring Python's instance-attribute mutation).

#' Build the per-test criterium list for a metric (initializeMetricTests).
#' @noRd
init_metric_tests <- function(metric_def) {
  tests <- metric_def$metric_tests %||% list()
  out <- list()
  for (t in tests) {
    tid <- t$metric_test_identifier %||% NA_character_
    if (is.na(tid)) next
    out[[tid]] <- list(
      metric_test_identifier   = tid,
      metric_test_name         = t$metric_test_name %||% NA_character_,
      agnostic_test_identifier = t$agnostic_test_identifier %||% re_first(.METRIC_TEST_REGEX, tid),
      metric_test_score        = list(earned = 0, total = as.numeric(t$metric_test_score %||% 0)),
      metric_test_maturity     = as.integer(t$metric_test_maturity %||% 0),
      metric_test_status       = "fail",
      evidence                 = character(0)
    )
  }
  out
}

#' Create a fresh metric evaluation environment for a metric definition.
#' @noRd
new_metric_evaluation <- function(metric_def) {
  res <- new.env(parent = emptyenv())
  res$metric_def        <- metric_def
  res$id                <- as.integer(metric_def$metric_number %||% NA_integer_)
  res$metric_identifier <- metric_def$metric_identifier %||% NA_character_
  res$metric_name       <- metric_def$metric_name %||% NA_character_
  res$total_score       <- as.numeric(metric_def$total_score %||% 0)
  res$score_earned      <- 0
  res$maturity          <- 0L
  res$test_status       <- "fail"
  res$tests             <- init_metric_tests(metric_def)
  res$output            <- NULL
  res
}

#' @noRd
crit_is_defined <- function(res, test_id) !is.null(res$tests[[test_id]])

#' Metric-test ids matching a canonical suffix (e.g. "-1", "-2").
#'
#' Domain-specific metric files often append a suffix to the metric id
#' (`FsF-F2-01M-ss`) but put it after the test number
#' (`FsF-F2-01M-3-ss`). Matching on agnostic test identifiers keeps evaluators
#' reusable across FsF metric releases.
#' @noRd
crit_test_ids <- function(res, suffix) {
  agnostic <- re_first(.METRIC_REGEX, res$metric_identifier)
  canonical <- canonical_metric_identifier(res$metric_identifier)
  prefixes <- unique(stats::na.omit(c(res$metric_identifier, agnostic, canonical)))
  targets <- paste0(prefixes, suffix)
  ids <- names(res$tests)
  ids[vapply(ids, function(id) {
    test <- res$tests[[id]]
    id %in% targets || (test$agnostic_test_identifier %||% "") %in% targets
  }, logical(1))]
}

#' @noRd
crit_is_defined_suffix <- function(res, suffix) length(crit_test_ids(res, suffix)) > 0L

#' Required metadata-property names declared by a metric test's requirements.
#' @noRd
crit_required_names <- function(res, test_id) {
  tests <- res$metric_def$metric_tests %||% list()
  for (t in tests) {
    if (identical(t$metric_test_identifier, test_id)) {
      req <- (t$metric_test_requirements %||% list())[[1]]$required
      if (is.null(req)) return(character(0))
      return(as_chr(if (is.list(req)) req$name else req))
    }
  }
  character(0)
}

#' @noRd
crit_required_names_suffix <- function(res, suffix) {
  ids <- crit_test_ids(res, suffix)
  if (!length(ids)) return(character(0))
  crit_required_names(res, ids[[1]])
}

#' @noRd
crit_test_score <- function(res, test_id) {
  if (!crit_is_defined(res, test_id)) return(0)
  res$tests[[test_id]]$metric_test_score$total
}

#' @noRd
crit_test_maturity <- function(res, test_id) {
  if (!crit_is_defined(res, test_id)) return(0L)
  res$tests[[test_id]]$metric_test_maturity
}

#' Mark a metric test as passed and accumulate score/maturity (setEvaluationCriteriumScore).
#' @noRd
crit_pass <- function(res, test_id, evidence = NULL) {
  if (!crit_is_defined(res, test_id)) return(invisible(res))
  score <- crit_test_score(res, test_id)
  mat   <- crit_test_maturity(res, test_id)
  res$tests[[test_id]]$metric_test_status <- "pass"
  res$tests[[test_id]]$metric_test_score$earned <- score
  if (!is.null(evidence)) res$tests[[test_id]]$evidence <- as_chr(evidence)
  res$score_earned <- res$score_earned + score
  res$maturity     <- max(res$maturity, mat)
  res$test_status  <- "pass"
  invisible(res)
}

#' Mark all tests matching a canonical suffix as passed.
#' @noRd
crit_pass_suffix <- function(res, suffix, evidence = NULL) {
  ids <- crit_test_ids(res, suffix)
  for (id in ids) crit_pass(res, id, evidence = evidence)
  invisible(res)
}

#' Finalize a metric evaluation environment into a plain result list.
#' @noRd
finalize_result <- function(res) {
  earned <- min(res$score_earned, res$total_score)
  percent <- if (res$total_score > 0) round(earned / res$total_score * 100, 2) else 0
  list(
    id = res$id,
    metric_identifier = res$metric_identifier,
    metric_name = res$metric_name,
    metric_tests = res$tests,
    test_status = res$test_status,
    score = list(earned = earned, total = res$total_score, percent = percent),
    maturity = as.integer(res$maturity),
    output = res$output
  )
}
