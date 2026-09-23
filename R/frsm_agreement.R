# Validation support for the heuristic FRSM software scores.

#' Cohen's kappa for two logical vectors (NA when chance agreement is 1).
#' @noRd
cohen_kappa <- function(a, b) {
  ok <- !is.na(a) & !is.na(b)
  a <- a[ok]; b <- b[ok]
  if (!length(a)) return(NA_real_)
  po <- mean(a == b)
  pe <- mean(a) * mean(b) + (1 - mean(a)) * (1 - mean(b))
  if (isTRUE(all.equal(pe, 1))) return(NA_real_)
  (po - pe) / (1 - pe)
}

#' Agreement between rfair's FRSM scores and expert ratings
#'
#' rfair scores the FRSM software metrics from repository signals (file names,
#' API fields, metadata files). These heuristics have not yet been validated
#' against expert judgement, so every FRSM result carries
#' `evidence_type = "heuristic"`. `frsm_agreement()` supports that validation:
#' raters judge each FRSM test for a sample of repositories (start from the
#' template in `system.file("extdata", "frsm_validation_template.csv",
#' package = "rfair")`), and the function compares rfair's pass/fail result with
#' the raters' majority judgement, test by test.
#'
#' @param assessments A list of [fair_assessment] objects scored with an FRSM
#'   metric version (for example the `"assessments"` attribute of
#'   `assess_fair_batch(..., metric_version = "0.7_software", keep = TRUE)`),
#'   or a single assessment.
#' @param ratings A data frame with columns `identifier` (as passed to
#'   [assess_fair()]), `test_identifier` (for example `"FRSM-14-R1-2"`), `rater`,
#'   and `passed` (logical; did the software satisfy the test?).
#' @return A data frame with one row per test: `test_identifier`, `n` (rated
#'   items), `rfair_pass` and `rater_pass` (pass rates), `agreement` (share of
#'   items where rfair matches the raters' majority), `kappa` (Cohen's kappa of
#'   rfair against the majority), and `rater_kappa` (kappa between the first two
#'   raters, when two or more rated the test). Ties between raters are dropped.
#' @export
#' @examples
#' data(fair_example)
#' ratings <- data.frame(identifier = fair_example$id,
#'                       test_identifier = "FsF-F1-01MD-1", rater = "A", passed = TRUE)
#' # fair_example is a data assessment, so this only shows the shape of the output
#' frsm_agreement(fair_example, ratings)
frsm_agreement <- function(assessments, ratings) {
  if (inherits(assessments, "fair_assessment")) assessments <- list(assessments)
  if (!all(vapply(assessments, inherits, logical(1), "fair_assessment"))) {
    stop("`assessments` must be a list of <fair_assessment> objects.", call. = FALSE)
  }
  need <- c("identifier", "test_identifier", "rater", "passed")
  if (!is.data.frame(ratings) || !all(need %in% names(ratings))) {
    stop("`ratings` needs the columns: ", paste(need, collapse = ", "), call. = FALSE)
  }
  ratings$passed <- as.logical(ratings$passed)
  scored <- do.call(rbind, lapply(assessments, function(a) {
    t <- assessment_tests(a)
    if (!nrow(t)) return(NULL)
    data.frame(identifier = a$id, test_identifier = t$test_identifier,
               rfair = t$status == "pass", stringsAsFactors = FALSE)
  }))
  majority <- stats::aggregate(passed ~ identifier + test_identifier, ratings, function(v) {
    m <- mean(v)
    if (m == 0.5) NA else m > 0.5
  }, na.action = stats::na.pass)
  m <- merge(scored, majority, by = c("identifier", "test_identifier"))
  m <- m[!is.na(m$passed), , drop = FALSE]
  tests <- unique(m$test_identifier)
  rows <- lapply(tests, function(tid) {
    d <- m[m$test_identifier == tid, , drop = FALSE]
    r <- ratings[ratings$test_identifier == tid & ratings$identifier %in% d$identifier, ,
                 drop = FALSE]
    raters <- unique(r$rater)
    rater_kappa <- NA_real_
    if (length(raters) >= 2L) {
      pair <- merge(r[r$rater == raters[1], c("identifier", "passed")],
                    r[r$rater == raters[2], c("identifier", "passed")], by = "identifier")
      rater_kappa <- cohen_kappa(pair$passed.x, pair$passed.y)
    }
    data.frame(test_identifier = tid, n = nrow(d), rfair_pass = mean(d$rfair),
               rater_pass = mean(d$passed), agreement = mean(d$rfair == d$passed),
               kappa = cohen_kappa(d$rfair, d$passed), rater_kappa = rater_kappa,
               stringsAsFactors = FALSE)
  })
  out <- do.call(rbind, rows)
  if (is.null(out)) {
    out <- data.frame(test_identifier = character(), n = integer(), rfair_pass = numeric(),
                      rater_pass = numeric(), agreement = numeric(), kappa = numeric(),
                      rater_kappa = numeric(), stringsAsFactors = FALSE)
  }
  out[order(out$test_identifier), , drop = FALSE]
}
