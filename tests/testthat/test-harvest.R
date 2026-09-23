# Full-pipeline tests over canned HTTP responses (see helper-mock.R).

metric_row <- function(a, id) {
  df <- as.data.frame(a)
  df[df$metric_identifier == id, , drop = FALSE]
}

test_that("a resolvable DOI harvests landing, signposting, and DataCite metadata", {
  local_http(zenodo_routes())
  a <- assess_fair("https://doi.org/10.5281/zenodo.8347772")

  expect_true(a$resolution$ok)
  expect_identical(a$resolved_url, "https://zenodo.org/records/8347772")
  expect_true(all(c("title", "creator", "publisher", "license", "object_identifier") %in%
                    names(a$metadata)))
  urls <- vapply(a$metadata$object_content_identifier, function(x) x$url, "")
  expect_true(any(grepl("fuji-v2.2.5.zip", urls, fixed = TRUE)))

  expect_equal(metric_row(a, "FsF-A1-02MD")$status, "pass")
  expect_equal(metric_row(a, "FsF-F1-02MD")$earned, 1)
  expect_equal(metric_row(a, "FsF-R1.1-01M")$status, "pass")
  expect_gt(summary(a)$percent[summary(a)$category == "FAIR"], 40)
})

test_that("an identifier that does not resolve is not scored as resolved or retrievable", {
  local_http(list())  # everything 404s
  a <- assess_fair("10.5281/zenodo.99999999999")

  expect_false(a$resolution$ok)
  expect_identical(a$resolution$status, 404L)
  expect_true(is.na(a$resolved_url))
  expect_output(print(a), "unresolved: https://doi.org/10.5281/zenodo.99999999999 (HTTP 404)",
                fixed = TRUE)

  expect_equal(metric_row(a, "FsF-A1-02MD")$earned, 0)
  # registered-and-resolves test fails; the scheme test still passes (as in F-UJI)
  expect_equal(metric_row(a, "FsF-F1-02MD")$earned, 0.5)

  row <- assess_fair_batch("10.5281/zenodo.99999999999", quiet = TRUE)
  expect_false(row$resolved)
  expect_identical(row$http_status, 404L)
})

test_that("a plain URL with a numeric path is fetched as-is, not via the Handle resolver", {
  seen <- local_http(list(route("https://figshare.com/articles/dataset/foo/12345/1",
                                "<html><head><title>x</title></head></html>")))
  a <- assess_fair("https://figshare.com/articles/dataset/foo/12345/1", use_datacite = FALSE)
  expect_true(a$resolution$ok)
  expect_false(any(grepl("hdl.handle.net", seen$urls, fixed = TRUE)))
  expect_equal(metric_row(a, "FsF-F1-02MD")$earned, 0)
})

test_that("a GitHub repository is scored from its API and file tree", {
  local_http(github_routes())
  a <- assess_fair("https://github.com/example/tool", metric_version = "0.7_software",
                   use_datacite = FALSE)
  expect_length(a$harvest_errors, 0L)
  expect_equal(metric_row(a, "FRSM-14-R1")$status, "pass")   # tests + CI
  expect_equal(metric_row(a, "FRSM-15-R1.1")$status, "pass")  # license
  expect_equal(metric_row(a, "FRSM-03-F1.2")$status, "pass")  # version v1.2.0
})

test_that("a GitHub rate limit is reported instead of silently lowering scores", {
  withr::local_envvar(GITHUB_PAT = "", GITHUB_TOKEN = "")
  limited <- route("https://api.github.com/repos/example/tool", '{"message": "API rate limit exceeded"}',
                   status = 403L, type = "application/json",
                   headers = list(`x-ratelimit-remaining` = "0", `x-ratelimit-reset` = "1790000000"))
  routes <- github_routes()
  routes[[2]] <- limited
  seen <- local_http(routes)
  expect_warning(
    a <- assess_fair("https://github.com/example/tool", metric_version = "0.7_software",
                     use_datacite = FALSE),
    class = "rfair_rate_limit")
  expect_length(a$harvest_errors, 1L)
  expect_identical(a$harvest_errors[[1]]$status, 403L)
  expect_output(print(a), "harvest:  1 source(s) failed", fixed = TRUE)
  # no further GitHub API calls after the limit was hit
  expect_equal(sum(grepl("api.github.com", seen$urls, fixed = TRUE)), 1L)
})

test_that("github_token prefers GITHUB_PAT over GITHUB_TOKEN", {
  withr::local_envvar(GITHUB_PAT = "pat", GITHUB_TOKEN = "tok")
  expect_identical(github_token(), "pat")
  withr::local_envvar(GITHUB_PAT = "")
  expect_identical(github_token(), "tok")
})
