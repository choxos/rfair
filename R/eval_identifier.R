# Identifier metrics: FsF-F1-01MD (unique) and FsF-F1-02MD (persistent).
# Ported from fair_evaluator_unique_identifier_metadata.py and
# fair_evaluator_persistent_identifier_metadata_data.py.

#' FsF-F1-01MD: metadata is assigned a globally unique identifier.
#' @noRd
eval_unique_identifier_metadata <- function(ctx, res) {
  tid <- paste0(res$metric_identifier, "-1")
  if (!crit_is_defined(res, tid)) return(invisible())
  scheme <- ctx$pid$preferred_schema
  if (is_nonempty_string(scheme)) {
    crit_pass(res, tid, evidence = scheme)
    res$output <- list(guid = ctx$id, guid_scheme = scheme)
    ctx_log(ctx, res$metric_identifier, "success",
            paste("Unique identifier scheme detected:", scheme))
  }
}

#' FsF-F1-02MD: metadata is assigned a persistent identifier.
#' @noRd
eval_persistent_identifier <- function(ctx, res) {
  mid <- res$metric_identifier
  t1 <- paste0(mid, "-1")
  if (crit_is_defined(res, t1) && isTRUE(ctx$is_persistent)) {
    crit_pass(res, t1, evidence = ctx$pid$preferred_schema)
  }
  # registered/maintained by a PID authority: evidenced by successful resolution
  t2 <- paste0(mid, "-2")
  resolved <- is_nonempty_string(ctx$landing_url) &&
    !identical(ctx$landing_url, ctx$pid_url)
  if (crit_is_defined(res, t2) && isTRUE(ctx$is_persistent) && resolved) {
    crit_pass(res, t2, evidence = ctx$landing_url)
  }
  res$output <- list(pid = ctx$pid_url, pid_scheme = ctx$pid$preferred_schema,
                     resolved_url = ctx$landing_url)
}
