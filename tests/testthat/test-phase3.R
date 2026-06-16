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
