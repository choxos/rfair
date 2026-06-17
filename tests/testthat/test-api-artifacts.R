api_artifact <- function(...) {
  installed <- system.file(..., package = "rfuji")
  if (nzchar(installed)) return(installed)
  candidates <- c(
    file.path("inst", ...),
    file.path("..", "inst", ...),
    file.path("..", "..", "inst", ...)
  )
  found <- candidates[file.exists(candidates)]
  if (length(found)) found[[1]] else ""
}

expected_metric_versions <- c("0.8", "0.5", "0.5ssv2", "0.5ss", "0.5env",
                              "0.7_software", "0.7_software_cessda",
                              "0.6a2a", "0.4", "0.3", "0.2")

test_that("machine-readable API artifacts are packaged", {
  openapi <- api_artifact("openapi", "rfuji-openapi.yaml")
  plumber <- api_artifact("plumber", "rfuji-api.R")

  expect_true(file.exists(openapi))
  expect_true(file.exists(plumber))

  spec <- yaml::read_yaml(openapi)
  expect_equal(spec$openapi, "3.1.0")
  expect_true("/assess" %in% names(spec$paths))
  expect_true("/metric-versions" %in% names(spec$paths))

  params <- spec$paths[["/assess"]]$get$parameters
  by_name <- stats::setNames(params, vapply(params, `[[`, character(1), "name"))
  expect_setequal(by_name$metric_version$schema$enum, expected_metric_versions)
  expect_setequal(
    by_name$metadata_service_type$schema$enum,
    c("oai_pmh", "ogc_csw", "sparql", "dcat", "schema_org", "datacite",
      "crossref", "signposting", "typed_links", "ro_crate", "ckan", "other")
  )
})

test_that("Plumber scaffold validates request enum parameters as 400s", {
  testthat::skip_if_not_installed("plumber")
  plumber_file <- api_artifact("plumber", "rfuji-api.R")
  route <- plumber::plumb(plumber_file)$routes[["assess"]]
  assess <- route$getFunc()

  res <- new.env(parent = emptyenv())
  missing_id <- assess(id = "", res = res)
  expect_equal(res$status, 400)
  expect_equal(missing_id$parameter, "id")

  res <- new.env(parent = emptyenv())
  bad_metric <- assess(
    id = "https://doi.org/10.5281/zenodo.8347772",
    metric_version = "not-a-version",
    resolve = "false",
    res = res
  )
  expect_equal(res$status, 400)
  expect_equal(bad_metric$parameter, "metric_version")
  expect_true("0.8" %in% bad_metric$allowed)

  res <- new.env(parent = emptyenv())
  bad_service <- assess(
    id = "https://doi.org/10.5281/zenodo.8347772",
    metadata_service_endpoint = "https://example.org/oai",
    metadata_service_type = "bad-service",
    resolve = "false",
    res = res
  )
  expect_equal(res$status, 400)
  expect_equal(bad_service$parameter, "metadata_service_type")
  expect_true("oai_pmh" %in% bad_service$allowed)
})
