# Registry mapping metric identifiers to evaluator functions.
#
# An evaluator is a function `function(ctx, res)` that inspects the engine state
# `ctx` (harvested metadata, resolved identifier, ...) and mutates the metric
# evaluation environment `res` via the criterium-engine helpers (e.g. crit_pass).
# Phase 1 onward registers concrete evaluators here keyed by agnostic identifier.

.evaluator_registry <- new.env(parent = emptyenv())

#' Register an evaluator for a metric.
#' @param agnostic_id Agnostic metric identifier (e.g. "FsF-R1.1-01M").
#' @param fn Evaluator function `function(ctx, res)`.
#' @noRd
register_evaluator <- function(agnostic_id, fn) {
  .evaluator_registry[[agnostic_id]] <- fn
  invisible()
}

#' Look up the evaluator for a metric identifier (matched on its agnostic id).
#' @noRd
get_evaluator <- function(metric_identifier) {
  agnostic <- re_first(.METRIC_REGEX, metric_identifier)
  if (is.na(agnostic)) return(NULL)
  .evaluator_registry[[agnostic]]
}
