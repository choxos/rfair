# FAIR score aggregation, ported from
# fuji_server/controllers/fair_check.py::get_assessment_summary (:638-729).

#' Aggregate per-metric results into F/A/I/R summary scores.
#'
#' @param results List of finalized metric result lists.
#' @param input_id The assessed identifier (preserves an upstream easter egg).
#' @return A list with `score_earned`, `score_total`, `score_percent`,
#'   `maturity`, `status_total`, and `status_passed`, each keyed by FAIR
#'   category (F/A/I/R), principle (F1, R1.1, ...), and overall "FAIR".
#' @noRd
get_assessment_summary <- function(results, input_id = NULL) {
  cat_ <- character(0); prin <- character(0)
  earned <- numeric(0); total <- numeric(0); mat <- numeric(0); stat <- numeric(0)

  egg <- is_nonempty_string(input_id) && input_id %in% c(
    "https://www.rd-alliance.org/users/mustapha-mokrane",
    "https://www.rd-alliance.org/users/ilona-von-stein"
  )

  for (res in results) {
    mid <- res$metric_identifier
    if (!is_nonempty_string(mid)) next
    m <- regmatches(mid, regexec("^(?:FRSM-[0-9]+|FsF)-(([FAIR])[0-9](\\.[0-9])?)", mid, perl = TRUE))[[1]]
    if (length(m) < 3L) next
    prin <- c(prin, m[2]); cat_ <- c(cat_, m[3])
    if (egg) {
      earned <- c(earned, res$score$total); mat <- c(mat, 3L); stat <- c(stat, 1)
    } else {
      earned <- c(earned, res$score$earned)
      mat <- c(mat, res$maturity)
      stat <- c(stat, if (identical(res$test_status, "pass")) 1 else 0)
    }
    total <- c(total, res$score$total)
  }

  if (length(earned) == 0L) {
    return(list(score_earned = list(), score_total = list(), score_percent = list(),
                maturity = list(), status_total = list(), status_passed = list()))
  }

  as_named_list <- function(x) {
    x <- as.list(x); x
  }
  clamp_mat <- function(x) { mu <- mean(x); if (mu < 1 && mu > 0) 1 else round(mu) }

  se_cat <- tapply(earned, cat_, sum); se_pri <- tapply(earned, prin, sum)
  st_cat <- tapply(total,  cat_, sum); st_pri <- tapply(total,  prin, sum)

  score_earned <- c(as_named_list(se_cat), as_named_list(se_pri))
  score_earned[["FAIR"]] <- round(sum(earned), 2)

  score_total <- c(as_named_list(st_cat), as_named_list(st_pri))
  score_total[["FAIR"]] <- round(sum(total), 2)

  score_percent <- c(as_named_list(round(se_cat / st_cat * 100, 2)),
                     as_named_list(round(se_pri / st_pri * 100, 2)))
  score_percent[["FAIR"]] <- round(sum(earned) / sum(total) * 100, 2)

  mat_cat <- tapply(mat, cat_, clamp_mat); mat_pri <- tapply(mat, prin, clamp_mat)
  maturity <- c(as_named_list(mat_cat), as_named_list(mat_pri))
  total_mat <- sum(vapply(c("F", "A", "I", "R"), function(k) {
    if (k %in% names(mat_cat)) as.numeric(mat_cat[[k]]) else 0
  }, numeric(1)))
  maturity[["FAIR"]] <- round(if (total_mat / 4 < 1 && total_mat / 4 > 0) 1 else total_mat / 4, 2)

  stt_pri <- tapply(stat, prin, length); stt_cat <- tapply(stat, cat_, length)
  status_total <- c(as_named_list(stt_pri), as_named_list(stt_cat))
  status_total[["FAIR"]] <- length(stat)

  stp_pri <- tapply(stat, prin, sum); stp_cat <- tapply(stat, cat_, sum)
  status_passed <- c(as_named_list(stp_pri), as_named_list(stp_cat))
  status_passed[["FAIR"]] <- sum(stat)

  list(score_earned = score_earned, score_total = score_total,
       score_percent = score_percent, maturity = maturity,
       status_total = status_total, status_passed = status_passed)
}
