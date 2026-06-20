test_that("FRSM software metrics load and evaluators score from signals", {
  m <- load_metrics("0.7_software")
  expect_equal(length(m$metrics), 17)
  expect_true("FRSM-15-R1.1" %in% names(m$custom))

  ctx <- new.env(parent = emptyenv())
  ctx$software <- list(
    identifier = "https://github.com/o/r", version = "v1.2.0",
    registry_doi = "10.5281/zenodo.123", name = "r", description = "a tool",
    contributors = 5, has_license = TRUE, has_readme = TRUE, has_citation = TRUE,
    has_tests = TRUE, has_ci = TRUE, has_requirements = TRUE, has_api = TRUE,
    has_open_api = TRUE, has_machine_readable_api = TRUE,
    has_data_format_docs = TRUE, has_open_data_formats = TRUE,
    has_schema_reference = TRUE, has_spdx_license = TRUE,
    has_metadata_spdx_license = TRUE, has_issue_tracker = TRUE,
    has_coverage = TRUE, has_bundled_license_info = TRUE,
    has_credit_roles = TRUE, has_multiple_archives = TRUE,
    has_provenance_metadata = TRUE)
  ctx$metadata_merged <- list(license = "https://spdx.org/licenses/MIT.html")
  ctx$test_debug <- FALSE
  mk <- function(id) new_metric_evaluation(m$custom[[id]])

  r <- mk("FRSM-15-R1.1"); eval_frsm_source_license(ctx, r)
  expect_gt(finalize_result(r)$score$earned, 0)            # LICENSE file present

  v <- mk("FRSM-03-F1.2"); eval_frsm_version_identifier(ctx, v)
  expect_identical(finalize_result(v)$test_status, "pass") # semantic version present

  t <- mk("FRSM-14-R1"); eval_frsm_test_cases(ctx, t)
  expect_gt(finalize_result(t)$score$earned, 0)            # tests + CI present

  api <- mk("FRSM-11-I1"); eval_frsm_open_api(ctx, api)
  expect_identical(finalize_result(api)$test_status, "pass") # OpenAPI contract present

  lic <- mk("FRSM-16-R1.1"); eval_frsm_metadata_license(ctx, lic)
  expect_identical(finalize_result(lic)$test_status, "pass") # SPDX license metadata

  # metrics that reach full marks from the complete signal set above
  full <- function(id, fn) {
    r <- mk(id); fn(ctx, r); s <- finalize_result(r)$score
    expect_equal(s$earned, s$total)
  }
  full("FRSM-02-F1.1", eval_frsm_component_identifiers) # single fully-identified component
  full("FRSM-06-F2",   eval_frsm_contributor_metadata)  # contributors + CRediT roles
  full("FRSM-08-F4",   eval_frsm_persistent_metadata)   # DOI + second archive
  full("FRSM-15-R1.1", eval_frsm_source_license)        # license + bundled-component licenses + SPDX
  full("FRSM-17-R1.2", eval_frsm_provenance)            # provenance + issue tracker + RO-Crate
})

test_that("FRSM software license signals handle structured metadata", {
  expect_equal(software_spdx_ids("https://spdx.org/licenses/MIT.html"), "MIT")
  expect_equal(
    software_spdx_ids(list(list(`@id` = "https://spdx.org/licenses/Apache-2.0.json"))),
    "Apache-2.0"
  )
  expect_equal(software_license_refs(list(list(url = "https://spdx.org/licenses/BSD-3-Clause.html"))),
               "https://spdx.org/licenses/BSD-3-Clause.html")
})

test_that("FRSM software path signals distinguish API, format, and schema evidence", {
  openapi <- software_path_signals("inst/openapi/rfair-openapi.yaml")
  expect_true(openapi$has_api)
  expect_true(openapi$has_open_data_formats)
  expect_true(openapi$has_schema_reference)

  graphql <- software_path_signals("schema/query.graphql")
  expect_true(graphql$has_api)
  expect_false(graphql$has_open_data_formats)
  expect_true(graphql$has_schema_reference)

  formats <- software_path_signals(c("examples/result.jsonld", "schemas/result.xsd"))
  expect_false(formats$has_api)
  expect_true(formats$has_open_data_formats)
  expect_true(formats$has_schema_reference)
})
