test_that("levenshtein_ratio matches python-Levenshtein semantics", {
  expect_equal(levenshtein_ratio("abc", "abc"), 1)
  expect_equal(levenshtein_ratio("", ""), 1)
  expect_equal(levenshtein_ratio("abc", "abd"), 1 - 2 / 6)  # one substitution = 2 indel
})

test_that("token_sort_ratio is order-independent and bounded", {
  expect_equal(token_sort_ratio("hello world", "world hello"), 100)
  expect_true(token_sort_ratio("foo", "completely different") < 50)
})

new_ctx <- function() {
  ctx <- new.env(parent = emptyenv())
  ctx$metadata_merged <- list(); ctx$metadata_unmerged <- list()
  ctx$related_resources <- list(); ctx$pid_collector <- list()
  ctx
}

test_that("merge_metadata splits keyword strings and unions lists", {
  ctx <- new_ctx()
  merge_metadata(ctx, list(keywords = "a, b, c"))
  expect_identical(ctx$metadata_merged$keywords, c("a", "b", "c"))
  merge_metadata(ctx, list(keywords = list("c", "d")))
  expect_identical(ctx$metadata_merged$keywords, list("a", "b", "c", "d"))
})

test_that("merge_metadata coerces publisher to url/name dicts", {
  ctx <- new_ctx()
  merge_metadata(ctx, list(publisher = "Zenodo"))
  expect_identical(ctx$metadata_merged$publisher, list(list(name = "Zenodo")))
  merge_metadata(ctx, list(publisher = "https://zenodo.org"))
  expect_identical(ctx$metadata_merged$publisher,
                   list(list(name = "Zenodo"), list(url = "https://zenodo.org")))
})

test_that("merge_metadata replaces a scalar only if longer and similar", {
  ctx <- new_ctx()
  merge_metadata(ctx, list(title = "data set"))
  merge_metadata(ctx, list(title = "data set v2"))
  expect_identical(ctx$metadata_merged$title, "data set v2")

  ctx2 <- new_ctx()
  merge_metadata(ctx2, list(title = "alpha"))
  merge_metadata(ctx2, list(title = "completely unrelated longer string"))
  expect_identical(ctx2$metadata_merged$title, "alpha")  # not similar -> keep old
})

test_that("merge_metadata records an unmerged provenance entry", {
  ctx <- new_ctx()
  merge_metadata(ctx, list(title = "x"), url = "u", method = "datacite", format = "json")
  expect_length(ctx$metadata_unmerged, 1)
  expect_identical(ctx$metadata_unmerged[[1]]$method, "datacite")
})
