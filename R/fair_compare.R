# Compare two FAIR assessments metric by metric or test by test.

#' @noRd
assessment_tests <- function(x) {
  rows <- lapply(x$results, function(r) {
    lapply(r$metric_tests %||% list(), function(t) data.frame(
      metric_identifier = r$metric_identifier,
      test_identifier = t$metric_test_identifier,
      earned = as.numeric(t$metric_test_score$earned %||% 0),
      status = t$metric_test_status %||% NA_character_,
      stringsAsFactors = FALSE))
  })
  out <- do.call(rbind, unlist(rows, recursive = FALSE))
  if (is.null(out)) {
    out <- data.frame(metric_identifier = character(), test_identifier = character(),
                      earned = numeric(), status = character(), stringsAsFactors = FALSE)
  }
  out
}

#' Compare two FAIR assessments
#'
#' Joins two assessments, for example of the same record before and after a
#' metadata fix, or under two metric versions, and reports what changed.
#'
#' @param a,b [fair_assessment] objects; `a` is the baseline.
#' @param level `"metric"` (default) for one row per metric, or `"test"` for
#'   one row per metric test.
#' @return A data frame with the identifiers, `earned_a`, `earned_b`,
#'   `status_a`, `status_b`, `delta` (`earned_b - earned_a`), and `change`
#'   (`"improved"`, `"worse"`, `"same"`, or `"only in a"`/`"only in b"`), in
#'   the metric order of `a`.
#' @seealso [fair_recommendations()]
#' @export
#' @examples
#' data(fair_example)
#' fixed <- fair_example
#' fixed$results[[1]]$score$earned <- fixed$results[[1]]$score$total
#' fair_compare(fair_example, fixed)[1:3, ]
fair_compare <- function(a, b, level = c("metric", "test")) {
  if (!inherits(a, "fair_assessment") || !inherits(b, "fair_assessment")) {
    stop("`a` and `b` must be <fair_assessment> objects (from assess_fair()).", call. = FALSE)
  }
  level <- match.arg(level)
  if (level == "metric") {
    keys <- "metric_identifier"
    da <- as.data.frame(a)[c("metric_identifier", "metric_name", "earned", "status")]
    db <- as.data.frame(b)[c("metric_identifier", "earned", "status")]
  } else {
    keys <- c("metric_identifier", "test_identifier")
    da <- assessment_tests(a)
    db <- assessment_tests(b)
  }
  m <- merge(da, db, by = keys, all = TRUE, suffixes = c("_a", "_b"), sort = FALSE)
  m$delta <- m$earned_b - m$earned_a
  m$change <- ifelse(is.na(m$earned_b), "only in a",
              ifelse(is.na(m$earned_a), "only in b",
              ifelse(m$delta > 0, "improved", ifelse(m$delta < 0, "worse", "same"))))
  ord <- match(do.call(paste, m[keys]), do.call(paste, da[keys]))
  m <- m[order(ord, na.last = TRUE), , drop = FALSE]
  rownames(m) <- NULL
  m
}
