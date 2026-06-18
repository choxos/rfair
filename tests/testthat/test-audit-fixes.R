# Regression tests for defects found in the engine/collector/plot audit.

test_that("map_access_right matches eu-repo access levels case-insensitively", {
  expect_equal(map_access_right("info:eu-repo/semantics/openAccess"), "public")
  expect_equal(map_access_right("info:eu-repo/semantics/closedAccess"), "closed")
  expect_equal(map_access_right("info:eu-repo/semantics/restrictedAccess"), "restricted")
  expect_equal(map_access_right("info:eu-repo/semantics/embargoedAccess"), "embargoed")
  expect_equal(map_access_right("c_abf2"), "public")          # COAR code still works
  expect_true(is.na(map_access_right("not-an-access-code")))
})

test_that("compact drops scalar NA fields so absent metadata is not counted present", {
  out <- compact(list(title = NA, creator = "x", empty = character(0), nul = NULL))
  expect_false("title" %in% names(out))
  expect_false("empty" %in% names(out))
  expect_false("nul" %in% names(out))
  expect_true("creator" %in% names(out))
})

test_that("parse_link_header handles space-separated rel and ignores URL query params", {
  h <- '<https://ex.org/data?type=zip>; rel="describedby alternate"; type="application/ld+json"'
  links <- parse_link_header(h)
  expect_length(links, 1L)
  expect_equal(links[[1]]$rel, "describedby")           # multi-rel matched
  expect_equal(links[[1]]$type, "application/ld+json")  # not "zip" from the URL query
})

test_that("plot and as.data.frame survive metric sets missing a category / empty results", {
  data(fair_example, package = "rfuji")
  x2 <- fair_example
  x2$results <- Filter(function(r) !grepl("FsF-A", r$metric_identifier %||% ""),
                       fair_example$results)
  tmp <- tempfile(fileext = ".png")
  grDevices::png(tmp); expect_s3_class(plot(x2, type = "category"), "fair_assessment"); grDevices::dev.off()
  grDevices::png(tmp); expect_s3_class(plot(x2, type = "sunburst"), "fair_assessment"); grDevices::dev.off()

  empty <- structure(list(results = list(), summary = list()), class = "fair_assessment")
  d <- as.data.frame(empty)
  expect_s3_class(d, "data.frame")
  expect_equal(nrow(d), 0L)
})

test_that("collect_metadata_service is a no-op without an endpoint", {
  ctx <- new.env()
  ctx$metadata_service_endpoint <- ""
  ctx$metadata_sources <- list()
  ctx$metadata_merged <- list()
  ctx$log <- list()
  expect_silent(collect_metadata_service(ctx))
  expect_length(ctx$metadata_sources, 0L)
})
