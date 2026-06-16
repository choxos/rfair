test_that("metrics load and expose agnostic identifiers", {
  m <- load_metrics("0.8")
  expect_gt(length(m$metrics), 10)
  expect_true("FsF-F1-01MD" %in% names(m$custom))
  expect_identical(m$version, "0.8")
  expect_true("0.8" %in% rfuji_metric_versions())
})

test_that("get_assessment_summary aggregates by category and principle", {
  results <- list(
    list(metric_identifier = "FsF-F1-01MD", score = list(earned = 1, total = 1),
         maturity = 3L, test_status = "pass"),
    list(metric_identifier = "FsF-F2-01M", score = list(earned = 0, total = 2),
         maturity = 0L, test_status = "fail"),
    list(metric_identifier = "FsF-R1.1-01M", score = list(earned = 2, total = 4),
         maturity = 2L, test_status = "pass")
  )
  s <- get_assessment_summary(results)
  expect_equal(s$score_earned[["F"]], 1)
  expect_equal(s$score_total[["F"]], 3)
  expect_equal(s$score_percent[["F"]], round(1 / 3 * 100, 2))
  expect_equal(s$score_earned[["FAIR"]], 3)
  expect_equal(s$score_total[["FAIR"]], 7)
  expect_equal(s$status_passed[["FAIR"]], 2)
  expect_equal(s$status_total[["FAIR"]], 3)
  # maturity F = mean(c(3,0)) = 1.5 -> round = 2
  expect_equal(s$maturity[["F"]], 2)
})

test_that("empty results yield empty summary", {
  expect_identical(get_assessment_summary(list())$score_earned, list())
})
