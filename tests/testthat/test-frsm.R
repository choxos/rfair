test_that("FRSM software metrics load and evaluators score from signals", {
  m <- load_metrics("0.7_software")
  expect_equal(length(m$metrics), 17)
  expect_true("FRSM-15-R1.1" %in% names(m$custom))

  ctx <- new.env(parent = emptyenv())
  ctx$software <- list(
    identifier = "https://github.com/o/r", version = "v1.2.0",
    registry_doi = "10.5281/zenodo.123", name = "r", description = "a tool",
    contributors = 5, has_license = TRUE, has_readme = TRUE, has_citation = TRUE,
    has_tests = TRUE, has_ci = TRUE, has_requirements = TRUE, has_api = FALSE)
  ctx$metadata_merged <- list(license = "MIT")
  ctx$test_debug <- FALSE
  mk <- function(id) new_metric_evaluation(m$custom[[id]])

  r <- mk("FRSM-15-R1.1"); eval_frsm_source_license(ctx, r)
  expect_gt(finalize_result(r)$score$earned, 0)            # LICENSE file present

  v <- mk("FRSM-03-F1.2"); eval_frsm_version_identifier(ctx, v)
  expect_identical(finalize_result(v)$test_status, "pass") # semantic version present

  t <- mk("FRSM-14-R1"); eval_frsm_test_cases(ctx, t)
  expect_gt(finalize_result(t)$score$earned, 0)            # tests + CI present
})
