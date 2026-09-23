test_that("lookup_standard classifies generic vs disciplinary", {
  expect_identical(lookup_standard("http://datacite.org/schema/kernel-4")$type, "generic")
  expect_identical(lookup_standard("http://schema.org")$type, "generic")
  expect_null(lookup_standard("http://example.org/nonexistent-ns"))
})

mk_ctx <- function(unmerged) {
  ctx <- new.env(parent = emptyenv())
  ctx$metadata_unmerged <- unmerged
  ctx$metadata_merged <- list(); ctx$test_debug <- FALSE
  ctx
}
mk_res <- function(agnostic) new_metric_evaluation(load_metrics("0.8")$custom[[agnostic]])

test_that("R1.3-01M passes via generic standard namespace", {
  ctx <- mk_ctx(list(list(schema = "http://datacite.org/schema/kernel-4", namespaces = list())))
  res <- mk_res("FsF-R1.3-01M")
  eval_community_metadata(ctx, res)
  out <- finalize_result(res)
  expect_equal(out$score$earned, 1)           # -3 multidisciplinary
  expect_identical(out$test_status, "pass")
})

test_that("I2-01M excludes default namespaces (0 for plain DataCite)", {
  ctx <- mk_ctx(list(list(schema = "http://schema.org", namespaces = list("http://datacite.org/schema"))))
  res <- mk_res("FsF-I2-01M")
  eval_semantic_vocabulary(ctx, res)
  expect_equal(finalize_result(res)$score$earned, 0)

  # prov is a registered vocab and not a default namespace -> counts
  ctx2 <- mk_ctx(list(list(schema = "", namespaces = list("http://www.w3.org/ns/prov#"))))
  res2 <- mk_res("FsF-I2-01M")
  eval_semantic_vocabulary(ctx2, res2)
  expect_equal(finalize_result(res2)$score$earned, 2)  # known vocab present
})

test_that("github_repo_of extracts owner/repo", {
  r <- github_repo_of("https://github.com/pangaea-data-publisher/fuji")
  expect_identical(r$owner, "pangaea-data-publisher")
  expect_identical(r$name, "fuji")
  expect_null(github_repo_of("https://doi.org/10.5281/zenodo.1"))
})

test_that("F4 requires an embedded offering method (not content negotiation)", {
  res <- mk_res("FsF-F4-01M")
  ctx <- new.env(parent = emptyenv())
  ctx$metadata_sources <- list(list(source = "DataCite", method = "content_negotiation"))
  ctx$test_debug <- FALSE
  eval_searchable(ctx, res)
  expect_equal(finalize_result(res)$score$earned, 0)   # negotiation does not count

  res2 <- mk_res("FsF-F4-01M")
  ctx$metadata_sources <- list(list(source = "schema.org", method = "embedded"))
  eval_searchable(ctx, res2)
  expect_equal(finalize_result(res2)$score$earned, 2)
})

test_that("I2-01M matches declared namespaces and term URIs against the vocabulary index", {
  expect_identical(lod_namespace_of("http://www.isotc211.org/2005/gmd"), "isotc211.org/2005/gmd")
  expect_identical(lod_namespace_of("http://www.w3.org/2004/02/skos/core#"), "w3.org/2004/02/skos/core")
  # a URI used as a value must name a term inside the namespace
  expect_identical(lod_namespace_of("https://spdx.org/licenses/CC0-1.0.html", term = TRUE), "spdx.org/licenses")
  expect_true(is.na(lod_namespace_of("https://spdx.org/licenses/", term = TRUE)))
  expect_true(is.na(lod_namespace_of("https://orcid.org/0000-0001-6829-0823", term = TRUE)))

  ctx <- new_engine_ctx("x", load_metrics("0.8"))
  note_linked_uris(ctx, '{"license": "https://spdx.org/licenses/CC0-1.0.html"}')
  res <- new_metric_evaluation(Find(function(m) m$metric_identifier == "FsF-I2-01M",
                                    load_metrics("0.8")$metrics))
  eval_semantic_vocabulary(ctx, res)
  expect_equal(finalize_result(res)$score$earned, 2)
})

test_that("assessments record the reference data version", {
  data(fair_example, package = "rfair")
  a <- assess_fair("https://doi.org/10.5281/zenodo.8347772", resolve = FALSE)
  expect_true(all(c("core_tables_built", "linked_vocabs_built") %in% names(a$reference_data)))
})
