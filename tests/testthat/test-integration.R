# Live full-pipeline smoke test. Skipped on CRAN and when offline, so it never
# runs network requests during `R CMD check` and ships no fixtures.

test_that("assess_fair runs a full assessment end to end (live)", {
  skip_on_cran()
  testthat::skip_if_offline("doi.org")
  a <- assess_fair("https://doi.org/10.5281/zenodo.8347772", timeout = 30)
  expect_s3_class(a, "fair_assessment")
  s <- summary(a)
  expect_gt(s$earned[s$category == "FAIR"], 0)
  expect_gt(sum(as.data.frame(a)$status == "pass"), 5L)
  expect_true(length(a$metadata) > 5L)

  # content identifiers are deduplicated after data-file enrichment
  oci <- a$metadata$object_content_identifier
  if (!is.null(oci)) {
    urls <- vapply(if (is.null(names(oci))) oci else list(oci),
                   function(x) if (is.list(x)) x$url %||% "" else as.character(x), character(1))
    urls <- urls[nzchar(urls)]
    expect_equal(length(urls), length(unique(urls)))
  }
})
