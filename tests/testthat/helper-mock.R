# Offline HTTP fixtures. `local_http()` routes every httr2 request made in the
# calling test to a canned response, so the harvesters run end to end without
# the network. Anything not matched gets a 404 (never a real request).

fixture_text <- function(name) {
  paste(readLines(test_path("fixtures", name), warn = FALSE, encoding = "UTF-8"),
        collapse = "\n")
}

#' One canned response. `accept` (if set) must occur in the request's Accept
#' header, which is how content negotiation on one URL is told apart.
route <- function(url, body = "", status = 200L, type = "text/html; charset=utf-8",
                  method = "GET", accept = NULL, final_url = url, headers = list()) {
  list(url = url, method = method, accept = accept, status = status,
       type = type, final_url = final_url, headers = headers, body = body)
}

json_route <- function(url, body, ...) {
  route(url, body = body, type = "application/json; charset=utf-8", ...)
}

local_http <- function(routes, env = parent.frame()) {
  seen <- new.env(parent = emptyenv())
  seen$urls <- character(0)
  seen$accepts <- character(0)
  httr2::local_mocked_responses(function(req) {
    method <- httr2::req_get_method(req)
    accept <- httr2::req_get_headers(req)$Accept %||% ""
    seen$urls <- c(seen$urls, paste(method, req$url))
    seen$accepts <- c(seen$accepts, accept)
    for (r in routes) {
      if (identical(r$url, req$url) && identical(r$method, method) &&
          (is.null(r$accept) || grepl(r$accept, accept, fixed = TRUE))) {
        return(httr2::response(
          status_code = r$status, url = r$final_url, method = method,
          headers = c(list(`Content-Type` = r$type), r$headers),
          body = charToRaw(enc2utf8(r$body))))
      }
    }
    httr2::response(status_code = 404L, url = req$url, method = method,
                    headers = list(`Content-Type` = "text/plain"),
                    body = charToRaw("not found"))
  }, env = env)
  invisible(seen)
}

# Canned responses for the Zenodo record 10.5281/zenodo.8347772 (F-UJI v2.2.5).
zenodo_routes <- function() {
  doi <- "https://doi.org/10.5281/zenodo.8347772"
  landing <- "https://zenodo.org/records/8347772"
  list(
    route(doi, fixture_text("zenodo-landing.html"), accept = "text/html",
          final_url = landing,
          headers = list(Link = fixture_text("zenodo-link-header.txt"))),
    route(doi, fixture_text("zenodo-datacite.json"),
          accept = "application/vnd.datacite.datacite+json",
          type = "application/vnd.datacite.datacite+json; charset=utf-8",
          final_url = "https://data.crosscite.org/10.5281%2Fzenodo.8347772"),
    route("https://zenodo.org/records/8347772/files/pangaea-data-publisher/fuji-v2.2.5.zip",
          method = "HEAD", type = "application/zip",
          headers = list(`Content-Length` = "2263011"))
  )
}

# Canned GitHub API responses for a small example repository.
github_routes <- function(owner = "example", name = "tool") {
  api <- sprintf("https://api.github.com/repos/%s/%s", owner, name)
  raw <- sprintf("https://raw.githubusercontent.com/%s/%s/main/", owner, name)
  html <- sprintf("https://github.com/%s/%s", owner, name)
  repo <- jsonlite::toJSON(list(
    html_url = html, name = name, description = "An example research tool",
    topics = list("fair"), license = list(spdx_id = "MIT", url = "https://api.github.com/licenses/mit"),
    owner = list(login = owner), created_at = "2024-01-01T00:00:00Z",
    updated_at = "2026-01-01T00:00:00Z", language = "R", default_branch = "main",
    private = FALSE, archived = FALSE, has_issues = TRUE), auto_unbox = TRUE)
  tree <- jsonlite::toJSON(list(tree = lapply(
    c("DESCRIPTION", "LICENSE", "README.md", "CITATION.cff", "codemeta.json",
      "tests/testthat/test-a.R", ".github/workflows/check.yaml"),
    function(p) list(path = p))), auto_unbox = TRUE)
  list(
    route(html, "<html><head><title>repo</title></head></html>"),
    json_route(api, repo),
    json_route(paste0(api, "/releases/latest"), '{"tag_name": "v1.2.0"}'),
    json_route(paste0(api, "/git/trees/main?recursive=1"), tree),
    json_route(paste0(api, "/contributors?per_page=100"), '[{"login": "a"}, {"login": "b"}]'),
    json_route(paste0(raw, "codemeta.json"),
               '{"name": "tool", "version": "1.2.0", "license": "https://spdx.org/licenses/MIT",
                 "identifier": "https://doi.org/10.5281/zenodo.1234567"}'),
    route(paste0(raw, "CITATION.cff"), "cff-version: 1.2.0\nversion: 1.2.0\ndoi: 10.5281/zenodo.1234567\n",
          type = "text/plain"),
    route(paste0(raw, "README.md"), "# tool\n", type = "text/plain")
  )
}

# Canned responses for the Crossref DOI 10.1038/sdata.2016.18.
crossref_routes <- function() {
  doi <- "https://doi.org/10.1038/sdata.2016.18"
  list(
    route(doi, "<html><head><title>FAIR principles</title></head></html>",
          accept = "text/html", final_url = "https://www.nature.com/articles/sdata201618"),
    route(doi, fixture_text("crossref-csl.json"), accept = "application/vnd.citationstyles.csl+json",
          type = "application/vnd.citationstyles.csl+json"),
    json_route("https://doi.org/ra/10.1038", '[{"DOI": "10.1038", "RA": "Crossref"}]')
  )
}

# Canned GitLab API v4 responses for gitlab.com/group/sub/tool.
gitlab_routes <- function() {
  api <- "https://gitlab.com/api/v4/projects/group%2Fsub%2Ftool"
  web <- "https://gitlab.com/group/sub/tool"
  project <- jsonlite::toJSON(list(
    id = 1, web_url = web, name = "tool", description = "A GitLab tool", topics = list("fair"),
    license = list(key = "apache-2.0", html_url = "https://www.apache.org/licenses/LICENSE-2.0"),
    namespace = list(path = "group"), created_at = "2024-01-01", last_activity_at = "2026-01-01",
    default_branch = "main", visibility = "public", `_links` = list(issues = paste0(web, "/issues"))),
    auto_unbox = TRUE)
  tree <- jsonlite::toJSON(lapply(c("pyproject.toml", "README.md", "LICENSE", "tests/test_a.py",
                                    ".gitlab-ci.yml"), function(p) list(path = p)), auto_unbox = TRUE)
  list(
    route(web, "<html><head><title>tool</title></head></html>"),
    json_route(paste0(api, "?license=true"), project),
    json_route(paste0(api, "/repository/tree?recursive=true&per_page=100&page=1"), tree),
    json_route(paste0(api, "/languages"), '{"Python": 98.5, "Shell": 1.5}'),
    json_route(paste0(api, "/releases?per_page=1"), '[{"tag_name": "v2.0.0"}]'),
    json_route(paste0(api, "/repository/contributors?per_page=100"), '[{"name": "a"}]'),
    route(paste0(web, "/-/raw/main/pyproject.toml"), '[project]\nname = "gltool"\n', type = "text/plain"),
    json_route("https://pypi.org/pypi/gltool/json", "{}", method = "HEAD")
  )
}

# Canned Forgejo/Gitea API v1 responses for codeberg.org/owner/tool.
codeberg_routes <- function() {
  api <- "https://codeberg.org/api/v1/repos/owner/tool"
  html <- "https://codeberg.org/owner/tool"
  repo <- jsonlite::toJSON(list(
    html_url = html, name = "tool", description = "A Codeberg tool", topics = list("fair"),
    licenses = list("MIT"), owner = list(login = "owner"), created_at = "2024-01-01",
    updated_at = "2026-01-01", language = "Rust", default_branch = "main", private = FALSE,
    has_issues = TRUE), auto_unbox = TRUE)
  tree <- jsonlite::toJSON(list(tree = lapply(c("Cargo.toml", "README.md", "LICENSE",
                                                  ".forgejo/workflows/ci.yml", "tests/it.rs"),
                                                function(p) list(path = p))), auto_unbox = TRUE)
  list(
    route(html, "<html><head><title>tool</title></head></html>"),
    json_route(api, repo),
    json_route(paste0(api, "/git/trees/main?recursive=true&per_page=10000"), tree),
    json_route(paste0(api, "/commits?limit=50&stat=false&verification=false&files=false"),
               '[{"commit": {"author": {"email": "a@x"}}}, {"commit": {"author": {"email": "b@x"}}}]'),
    json_route(paste0(api, "/releases/latest"), '{"tag_name": "0.3.1"}')
  )
}
