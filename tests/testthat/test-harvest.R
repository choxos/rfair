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

test_that("a Crossref DOI is harvested through CSL JSON, without DataCite requests", {
  seen <- local_http(crossref_routes())
  a <- assess_fair("https://doi.org/10.1038/sdata.2016.18")

  expect_identical(a$metadata$title,
                   "The FAIR Guiding Principles for scientific data management and stewardship")
  expect_true(length(a$metadata$creator) >= 3L)
  expect_identical(as_chr(a$metadata$license)[1], "https://creativecommons.org/licenses/by/4.0")
  urls <- vapply(a$metadata$object_content_identifier, function(x) x$url, "")
  expect_true("https://www.nature.com/articles/sdata201618.pdf" %in% urls)
  expect_false(any(grepl("datacite", seen$accepts, fixed = TRUE)))

  expect_equal(metric_row(a, "FsF-R1.1-01M")$status, "pass")
  # FsF-F4-01M-2 is specific to DataCite registration; CSL does not satisfy it
  f4 <- a$results[[which(vapply(a$results, `[[`, "", "metric_identifier") == "FsF-F4-01M")]]
  expect_false(any(vapply(f4$metric_tests, function(t)
    grepl("-2$", t$metric_test_identifier) && identical(t$metric_test_status, "pass"), logical(1))))
})

test_that("map_csl maps dates, authors, relations, and skips similarity-check links", {
  md <- map_csl(list(
    DOI = "10.1/x", title = "T", type = "dataset",
    author = list(list(given = "Ada", family = "Lovelace"), list(literal = "Consortium")),
    issued = list(`date-parts` = list(list(2020, 1))),
    link = list(list(URL = "https://x/sc.pdf", `intended-application` = "similarity-checking")),
    relation = list(`is-supplement-to` = list(list(`id-type` = "doi", id = "10.2/y")))))
  expect_identical(md$publication_date, "2020-01")
  expect_identical(unlist(md$creator), c("Ada Lovelace", "Consortium"))
  expect_null(md$object_content_identifier)
  expect_identical(md$related_resources[[1]]$related_resource, "https://doi.org/10.2/y")
})

test_that("Turtle metadata is mapped from the RDF graph, with creator names", {
  skip_if_not_installed("rdflib")
  local_http(list())
  ctx <- new_engine_ctx("x", load_metrics("0.8"))
  ok <- collect_rdf_graph(ctx, fixture_text("crossref.ttl"), "text/turtle", "https://doi.org/10.1038/sdata.2016.18")
  expect_true(ok)
  md <- ctx$metadata_merged
  expect_identical(md$title, "The FAIR Guiding Principles for scientific data management and stewardship")
  expect_setequal(unlist(md$creator), c("Mark D. Wilkinson", "Michel Dumontier"))
  expect_true("http://purl.org/ontology/bibo/" %in% unlist(ctx$metadata_unmerged[[1]]$namespaces))
})

test_that("GitLab projects (nested groups) are harvested through API v4", {
  local_http(gitlab_routes())
  a <- assess_fair("https://gitlab.com/group/sub/tool", metric_version = "0.7_software",
                   use_datacite = FALSE)
  sw <- a$software
  expect_identical(sw$forge, "gitlab")
  expect_identical(sw$version, "v2.0.0")
  expect_identical(sw$language, "Python")
  expect_true(sw$has_tests && sw$has_ci && sw$has_spdx_license && sw$has_issue_tracker)
  expect_identical(sw$package_registry, "PyPI")
  expect_equal(metric_row(a, "FRSM-14-R1")$status, "pass")
})

test_that("Codeberg repositories are harvested through the Forgejo/Gitea API", {
  local_http(codeberg_routes())
  a <- assess_fair("https://codeberg.org/owner/tool", metric_version = "0.7_software",
                   use_datacite = FALSE)
  sw <- a$software
  expect_identical(sw$forge, "gitea")
  expect_identical(sw$contributors, 2L)
  expect_true(sw$has_ci && sw$has_license && sw$has_spdx_license)
  expect_identical(sw$version, "0.3.1")
})

test_that("a software DOI is bridged to its linked repository under the FRSM metrics", {
  doi <- "https://doi.org/10.5281/zenodo.1234567"
  datacite <- jsonlite::toJSON(list(
    id = doi, doi = "10.5281/zenodo.1234567",
    types = list(resourceTypeGeneral = "Software"),
    titles = list(list(title = "tool")), creators = list(list(name = "A")),
    publisher = "Zenodo", publicationYear = 2026,
    relatedIdentifiers = list(list(relatedIdentifier = "https://github.com/example/tool/tree/v1.2.0",
                                   relationType = "IsSupplementTo"))), auto_unbox = TRUE)
  routes <- c(github_routes(), list(
    route(doi, "<html><head><title>tool</title></head></html>", accept = "text/html",
          final_url = "https://zenodo.org/records/1234567"),
    route(doi, datacite, accept = "application/vnd.datacite.datacite+json",
          type = "application/vnd.datacite.datacite+json")))
  local_http(routes)
  a <- assess_fair(doi, metric_version = "0.7_software")
  expect_identical(a$software$repository, "https://github.com/example/tool")
  expect_identical(a$software$registry_doi, "10.5281/zenodo.1234567")
  expect_equal(metric_row(a, "FRSM-01-F1")$status, "pass")
  expect_equal(metric_row(a, "FRSM-14-R1")$status, "pass")
  # the registry record stays the metadata of record
  expect_identical(a$metadata$title, "tool")
  expect_null(a$metadata$summary)   # the repository description was not merged in
})

test_that("forge_of recognizes GitHub, nested GitLab groups, and Codeberg", {
  expect_identical(forge_of("https://gitlab.com/g/s/p/-/blob/main/x.R")$path, "g/s/p")
  expect_identical(forge_of("https://codeberg.org/o/r.git")$name, "r")
  expect_identical(forge_of("https://github.com/o/r/tree/v1")$forge, "github")
  expect_null(forge_of("https://example.org/o/r"))
})

test_that("data links count as retrievable only when they answer 2xx", {
  test_status <- function(status) {
    routes <- zenodo_routes()
    routes[[3]]$status <- status
    local_http(routes)
    a <- assess_fair("https://doi.org/10.5281/zenodo.8347772")
    r <- a$results[[which(vapply(a$results, `[[`, "", "metric_identifier") == "FsF-A1-02MD")]]
    r$metric_tests[["FsF-A1-02MD-2"]]$metric_test_status
  }
  expect_identical(test_status(200L), "pass")
  expect_identical(test_status(401L), "fail")
})

test_that("schema.org isAccessibleForFree is read as an access statement", {
  md <- map_schemaorg(list(`@type` = "Dataset", name = "x", isAccessibleForFree = TRUE))
  expect_true(md$access_free)
  expect_identical(access_statements(md), "https://schema.org/isAccessibleForFree#public")
  expect_identical(map_access_right(access_statements(md)), "public")
})
