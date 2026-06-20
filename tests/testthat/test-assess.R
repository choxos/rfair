# Offline assessment skeleton (resolve = FALSE => no network).

test_that("assess_fair returns a valid baseline assessment offline", {
  a <- assess_fair("https://doi.org/10.5281/zenodo.8347772", resolve = FALSE)
  expect_s3_class(a, "fair_assessment")
  expect_gt(a$total_metrics, 10)

  df <- as.data.frame(a)
  expect_equal(nrow(df), a$total_metrics)
  expect_true(all(c("metric_identifier", "principle", "category", "earned",
                    "total", "percent", "maturity", "status") %in% names(df)))
  # offline: identifier metrics pass from id_parse alone; metadata metrics fail
  expect_equal(df$earned[df$metric_identifier == "FsF-F1-01MD"], 1)
  expect_equal(df$earned[df$metric_identifier == "FsF-F2-01M"], 0)
  expect_equal(df$status[df$metric_identifier == "FsF-F2-01M"], "fail")

  s <- summary(a)
  expect_true(all(c("F", "A", "I", "R", "FAIR") %in% s$category))
  expect_gt(s$total[s$category == "FAIR"], 0)
})

test_that("as_fuji_json emits valid, schema-shaped JSON", {
  a <- assess_fair("https://doi.org/10.5281/zenodo.8347772", resolve = FALSE)
  js <- as_fuji_json(a, pretty = FALSE)
  expect_true(jsonlite::validate(js))
  obj <- jsonlite::fromJSON(js, simplifyVector = FALSE)
  expect_true(all(c("test_id", "request", "software_version", "metric_version",
                    "total_metrics", "summary", "results") %in% names(obj)))
  expect_equal(length(obj$results), a$total_metrics)
})

test_that("assess_fair records metadata service request options", {
  a <- assess_fair(
    "https://doi.org/10.5281/zenodo.8347772",
    resolve = FALSE,
    metadata_service_endpoint = "https://example.org/oai",
    metadata_service_type = "oai_pmh",
    use_datacite = FALSE
  )
  expect_false(a$request$use_datacite)
  expect_equal(a$request$metadata_service_endpoint, "https://example.org/oai")
  expect_equal(a$request$metadata_service_type, "oai_pmh")
})

test_that("metadata service request alone is not scoring evidence", {
  a <- assess_fair(
    "https://doi.org/10.5281/zenodo.8347772",
    metric_version = "0.5",
    resolve = FALSE,
    metadata_service_endpoint = "https://example.org/oai",
    metadata_service_type = "oai_pmh"
  )
  df <- as.data.frame(a)
  expect_equal(df$earned[df$metric_identifier == "FsF-R1-01MD"], 0)
})

test_that("print.fair_assessment is stable", {
  a <- assess_fair("https://doi.org/10.5281/zenodo.8347772", resolve = FALSE)
  expect_output(print(a), "fair_assessment")
})

test_that("as_fuji_json includes agnostic test identifiers (not null)", {
  a <- assess_fair("https://doi.org/10.5281/zenodo.8347772", resolve = FALSE)
  js <- as_fuji_json(a, pretty = FALSE)
  expect_false(grepl('"agnostic_test_identifier":null', js, fixed = TRUE))
  obj <- jsonlite::fromJSON(js, simplifyVector = FALSE)
  r <- Find(function(x) identical(x$metric_identifier, "FsF-F1-01MD"), obj$results)
  expect_true(all(vapply(r$metric_tests,
                         function(t) is_nonempty_string(t$agnostic_test_identifier), logical(1))))
})

test_that("as_rdf emits valid DQV / schema.org Rating JSON-LD", {
  a <- assess_fair("https://doi.org/10.5281/zenodo.8347772", resolve = FALSE)
  js <- as_rdf(a)
  expect_true(jsonlite::validate(js))
  o <- jsonlite::fromJSON(js, simplifyVector = FALSE)
  expect_true("schema:Rating" %in% o[["@type"]])
  expect_length(o[["dqv:hasQualityMeasurement"]], 5)
  expect_error(as_rdf(list()), "fair_assessment")
})
