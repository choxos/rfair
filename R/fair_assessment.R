# The `fair_assessment` S3 object returned by [assess_fair()], plus its
# print/format/as.data.frame/summary methods.

#' The `fair_assessment` object
#'
#' [assess_fair()] returns an object of class `fair_assessment`. It has
#' `print()`, `format()`, [summary()][summary.fair_assessment], and
#' [as.data.frame()][as.data.frame.fair_assessment] methods, and can be exported
#' with [as_fuji_json()] and [as_rdf()].
#'
#' Useful list elements: `summary` (F/A/I/R scores), `results` (per-metric),
#' `metadata` (harvested), `reuse` (license reusability), `access`
#' (access/sensitivity), and `identifier_hygiene`.
#'
#' @name fair_assessment
#' @seealso [assess_fair()]
NULL

#' Construct a `fair_assessment` object.
#' @noRd
new_fair_assessment <- function(id, request, results, summary, resolved_url,
                                metrics_meta, metadata = list(),
                                start_time = NULL, end_time = NULL, log = list(),
                                reuse = NULL, access = NULL,
                                identifier_hygiene = NULL) {
  structure(
    list(
      id = id,
      resolved_url = resolved_url,
      request = request,
      software_version = as.character(utils::packageVersion("rfair")),
      metric_version = metrics_meta$version,
      metric_specification = metrics_meta$metric_specification,
      start_timestamp = start_time,
      end_timestamp = end_time,
      total_metrics = length(results),
      results = results,
      summary = summary,
      metadata = metadata,
      reuse = reuse,
      access = access,
      identifier_hygiene = identifier_hygiene,
      log = log
    ),
    class = "fair_assessment"
  )
}

#' @noRd
principle_of <- function(metric_identifier) {
  m <- regmatches(metric_identifier,
                  regexec("^(?:FRSM-[0-9]+|FsF)-(([FAIR])[0-9](\\.[0-9])?)",
                          metric_identifier, perl = TRUE))[[1]]
  if (length(m) < 3L) return(c(principle = NA_character_, category = NA_character_))
  c(principle = m[2], category = m[3])
}

#' Convert a FAIR assessment to a per-metric data frame.
#'
#' @param x A `fair_assessment` object.
#' @param ... Ignored.
#' @return A data frame with one row per metric.
#' @export
as.data.frame.fair_assessment <- function(x, ...) {
  empty <- data.frame(
    metric_identifier = character(), principle = character(),
    category = character(), metric_name = character(), earned = numeric(),
    total = numeric(), percent = numeric(), maturity = integer(),
    status = character(), stringsAsFactors = FALSE
  )
  if (!length(x$results)) return(empty)
  rows <- lapply(x$results, function(r) {
    pc <- principle_of(r$metric_identifier %||% "")
    data.frame(
      metric_identifier = r$metric_identifier %||% NA_character_,
      principle = unname(pc["principle"]),
      category = unname(pc["category"]),
      metric_name = r$metric_name %||% NA_character_,
      earned = r$score$earned %||% NA_real_,
      total = r$score$total %||% NA_real_,
      percent = r$score$percent %||% NA_real_,
      maturity = r$maturity %||% NA_integer_,
      status = r$test_status %||% NA_character_,
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

#' Summarize a FAIR assessment as an F/A/I/R score table.
#'
#' @param object A `fair_assessment` object.
#' @param ... Ignored.
#' @return A data frame with earned, total, percent, and maturity per FAIR
#'   category and overall.
#' @export
summary.fair_assessment <- function(object, ...) {
  s <- object$summary
  keys <- c("F", "A", "I", "R", "FAIR")
  getv <- function(lst, k) { v <- lst[[k]]; if (is.null(v)) NA_real_ else as.numeric(v) }
  df <- data.frame(
    category = keys,
    earned = vapply(keys, function(k) getv(s$score_earned, k), numeric(1)),
    total = vapply(keys, function(k) getv(s$score_total, k), numeric(1)),
    percent = vapply(keys, function(k) getv(s$score_percent, k), numeric(1)),
    maturity = vapply(keys, function(k) getv(s$maturity, k), numeric(1)),
    row.names = NULL, stringsAsFactors = FALSE
  )
  df
}

#' @export
format.fair_assessment <- function(x, ...) {
  s <- summary(x)
  lines <- c(
    sprintf("<fair_assessment> %s", x$id),
    if (is_nonempty_string(x$resolved_url)) sprintf("  resolved: %s", x$resolved_url),
    sprintf("  metrics: v%s (%d metrics)", x$metric_version %||% "?", x$total_metrics),
    "",
    sprintf("  %-5s %9s %8s %9s", "FAIR", "earned", "percent", "maturity")
  )
  for (i in seq_len(nrow(s))) {
    lines <- c(lines, sprintf("  %-5s %9s %7s%% %9s",
                              s$category[i],
                              sprintf("%g/%g", s$earned[i], s$total[i]),
                              formatC(s$percent[i], format = "f", digits = 1),
                              formatC(s$maturity[i], format = "g")))
  }

  # reviewer-driven context: reusability, access/sensitivity, identifier hygiene
  if (!is.null(x$reuse) && length(x$reuse$licenses)) {
    cats <- vapply(x$reuse$licenses, function(l) l$category, character(1))
    lines <- c(lines, "", sprintf("  reuse:    %s%s",
                                  paste(unique(cats), collapse = "; "),
                                  if (isFALSE(x$reuse$any_open)) "  [license present but NOT open for reuse]" else ""))
  }
  if (!is.null(x$access) && (isTRUE(x$access$controlled_access) || isTRUE(x$access$sensitive))) {
    tags <- c(if (isTRUE(x$access$controlled_access)) "controlled-access", if (isTRUE(x$access$sensitive)) "sensitive")
    lines <- c(lines, sprintf("  access:   %s (%s)  [restricted access may be legitimate; not a FAIR failure]",
                              x$access$access, paste(tags, collapse = ", ")))
  }
  if (!is.null(x$identifier_hygiene) && isFALSE(x$identifier_hygiene$hygiene_ok)) {
    lines <- c(lines, sprintf("  id hygiene: %d issue(s) (see $identifier_hygiene)",
                              length(x$identifier_hygiene$issues)))
  }
  paste(lines, collapse = "\n")
}

#' @export
print.fair_assessment <- function(x, ...) {
  cat(format(x, ...), "\n", sep = "")
  invisible(x)
}
