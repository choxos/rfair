# fair_recommendations() and fair_compare().

test_that("every FsF v0.8 and FRSM test has a recommendation", {
  tbl <- recommendation_table()
  for (v in c("0.8", "0.7_software")) {
    ids <- unlist(lapply(load_metrics(v)$metrics, function(m)
      vapply(m$metric_tests, function(t) t$metric_test_identifier, "")))
    expect_true(all(ids %in% names(tbl)), info = paste(setdiff(ids, names(tbl)), collapse = ", "))
  }
  expect_false(any(grepl(" — | – | - |--", unlist(tbl))))
})

test_that("fair_recommendations lists failed tests, biggest gains first", {
  data(fair_example, package = "rfair")
  rec <- fair_recommendations(fair_example)
  expect_named(rec, c("metric_identifier", "test_identifier", "test_name", "points", "recommendation"))
  expect_false(anyNA(rec$recommendation))
  expect_false(is.unsorted(-rec$points))
  failed <- unlist(lapply(fair_example$results, function(r)
    Filter(function(t) !identical(t$metric_test_status, "pass"), r$metric_tests)), recursive = FALSE)
  expect_equal(nrow(rec), length(failed))

  legacy <- assess_fair("https://doi.org/10.5281/zenodo.8347772", metric_version = "0.3",
                        resolve = FALSE)
  expect_false(anyNA(fair_recommendations(legacy)$recommendation))
  expect_error(fair_recommendations(list()), "fair_assessment")
})

test_that("fair_compare reports improvements per metric and per test", {
  data(fair_example, package = "rfair")
  a <- assess_fair("https://doi.org/10.5281/zenodo.8347772", resolve = FALSE)
  cmp <- fair_compare(a, fair_example)
  expect_identical(cmp$metric_identifier, as.data.frame(a)$metric_identifier)
  expect_true(any(cmp$change == "improved"))
  expect_false(any(cmp$change == "worse"))
  expect_equal(sum(cmp$delta), sum(as.data.frame(fair_example)$earned) - sum(as.data.frame(a)$earned))

  tests <- fair_compare(a, fair_example, level = "test")
  expect_true(all(c("test_identifier", "status_a", "status_b") %in% names(tests)))
  expect_setequal(unique(fair_compare(a, a)$change), "same")
})
