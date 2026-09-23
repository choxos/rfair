# FRSM validation support.

test_that("FRSM results are labeled heuristic and the print says so", {
  local_http(github_routes())
  a <- assess_fair("https://github.com/example/tool", metric_version = "0.7_software",
                   use_datacite = FALSE)
  expect_true(all(vapply(a$results, function(r) identical(r$evidence_type, "heuristic"), logical(1))))
  expect_output(print(a), "FRSM scores are heuristic", fixed = TRUE)
  d <- assess_fair("https://doi.org/10.5281/zenodo.8347772", resolve = FALSE)
  expect_null(d$results[[1]]$evidence_type)
})

test_that("frsm_agreement compares rfair with the raters' majority", {
  local_http(github_routes())
  a <- assess_fair("https://github.com/example/tool", metric_version = "0.7_software",
                   use_datacite = FALSE)
  tests <- c("FRSM-14-R1-1", "FRSM-11-I1-1")   # rfair: pass, fail
  ratings <- data.frame(
    identifier = a$id, test_identifier = rep(tests, each = 3),
    rater = rep(c("A", "B", "C"), 2), passed = c(TRUE, TRUE, FALSE, TRUE, TRUE, TRUE))
  out <- frsm_agreement(list(a), ratings)
  expect_identical(out$test_identifier, sort(tests))
  expect_equal(out$agreement[out$test_identifier == "FRSM-14-R1-1"], 1)   # majority pass
  expect_equal(out$agreement[out$test_identifier == "FRSM-11-I1-1"], 0)   # raters pass, rfair fails
  expect_error(frsm_agreement(list(a), data.frame(x = 1)), "columns")

  tpl <- utils::read.csv(system.file("extdata", "frsm_validation_template.csv", package = "rfair"))
  expect_true(all(c("identifier", "test_identifier", "rater", "passed") %in% names(tpl)))
  expect_equal(nrow(tpl), 45L)
})

test_that("cohen_kappa handles perfect, chance, and degenerate agreement", {
  expect_equal(cohen_kappa(c(TRUE, FALSE, TRUE, FALSE), c(TRUE, FALSE, TRUE, FALSE)), 1)
  expect_equal(cohen_kappa(c(TRUE, TRUE, FALSE, FALSE), c(TRUE, FALSE, TRUE, FALSE)), 0)
  expect_true(is.na(cohen_kappa(c(TRUE, TRUE), c(TRUE, TRUE))))
})
