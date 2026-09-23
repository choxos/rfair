# Curator guidance: turn failed metric tests into concrete actions.

.recommendations_cache <- new.env(parent = emptyenv())

#' @noRd
recommendation_table <- function() {
  if (is.null(.recommendations_cache$table)) {
    path <- system.file("extdata", "recommendations.yaml", package = "rfair")
    .recommendations_cache$table <- yaml::read_yaml(path)
  }
  .recommendations_cache$table
}

#' Recommend how to fix the failed tests of a FAIR assessment
#'
#' Lists every metric test that did not pass, with one concrete action a data
#' curator or software maintainer can take to pass it (for example "Add a
#' license to the metadata as a URL or SPDX identifier"). Actions come from a
#' curated table covering the FsF data metrics and the FRSM software metrics;
#' tests of legacy metric versions fall back to a metric-level action.
#'
#' @param x A [fair_assessment] from [assess_fair()].
#' @return A data frame, most valuable fixes first, with columns
#'   `metric_identifier`, `test_identifier`, `test_name`, `points` (the score
#'   the test would add), and `recommendation`.
#' @seealso [fair_compare()] to check the effect of a fix.
#' @export
#' @examples
#' data(fair_example)
#' head(fair_recommendations(fair_example))
fair_recommendations <- function(x) {
  if (!inherits(x, "fair_assessment")) {
    stop("`x` must be a <fair_assessment> (from assess_fair()).", call. = FALSE)
  }
  tbl <- recommendation_table()
  rows <- list()
  for (r in x$results) {
    metric_key <- canonical_metric_identifier(r$metric_identifier %||% "")
    for (t in r$metric_tests %||% list()) {
      if (identical(t$metric_test_status, "pass")) next
      test_key <- t$agnostic_test_identifier %||% t$metric_test_identifier
      advice <- tbl[[t$metric_test_identifier]] %||% tbl[[test_key]] %||%
        tbl[[metric_key %||% ""]] %||% NA_character_
      rows[[length(rows) + 1L]] <- data.frame(
        metric_identifier = r$metric_identifier,
        test_identifier = t$metric_test_identifier,
        test_name = t$metric_test_name %||% NA_character_,
        points = as.numeric(t$metric_test_score$total %||% NA_real_),
        recommendation = advice,
        stringsAsFactors = FALSE)
    }
  }
  if (!length(rows)) {
    return(data.frame(metric_identifier = character(), test_identifier = character(),
                      test_name = character(), points = numeric(),
                      recommendation = character(), stringsAsFactors = FALSE))
  }
  out <- do.call(rbind, rows)
  out <- out[order(-out$points, seq_len(nrow(out))), , drop = FALSE]
  rownames(out) <- NULL
  out
}
