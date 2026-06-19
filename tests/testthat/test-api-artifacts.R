api_artifact <- function(...) {
  installed <- system.file(..., package = "rfair")
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
  openapi <- api_artifact("openapi", "rfair-openapi.yaml")
  plumber <- api_artifact("plumber", "rfair-api.R")

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
  plumber_file <- api_artifact("plumber", "rfair-api.R")
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

test_that("Plumber scaffold validates boolean query parameters as 400s", {
  testthat::skip_if_not_installed("plumber")
  plumber_file <- api_artifact("plumber", "rfair-api.R")
  route <- plumber::plumb(plumber_file)$routes[["assess"]]
  assess <- route$getFunc()

  for (parameter in c("use_datacite", "resolve", "use_headless")) {
    res <- new.env(parent = emptyenv())
    args <- list(
      id = "https://doi.org/10.5281/zenodo.8347772",
      resolve = "false",
      res = res
    )
    args[[parameter]] <- "not-bool"

    bad_boolean <- do.call(assess, args)
    expect_equal(res$status, 400)
    expect_equal(bad_boolean$parameter, parameter)
    expect_true("true" %in% bad_boolean$allowed)
    expect_true("false" %in% bad_boolean$allowed)
  }

  parse_bool <- get("parse_bool", envir = environment(assess))
  expect_false(parse_bool("0", TRUE))
  expect_false(parse_bool("false", TRUE))
  expect_false(parse_bool("no", TRUE))
  expect_true(parse_bool("1", FALSE))
  expect_true(parse_bool("true", FALSE))
  expect_true(parse_bool("yes", FALSE))
})
