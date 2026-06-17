# GitHub repository metadata harvester. When the assessed object is a GitHub
# repository, enriches the metadata record from the GitHub REST API (license,
# description, topics, dates). Ported in spirit from github_harvester.py.
# Set GITHUB_TOKEN to raise the API rate limit.

#' Detect an owner/repo pair from candidate URLs.
#' @noRd
github_repo_of <- function(urls) {
  for (u in as_chr(urls)) {
    m <- regmatches(u, regexec("github\\.com/([^/]+)/([^/?#]+)", u))[[1]]
    if (length(m) == 3L) return(list(owner = m[2], name = sub("\\.git$", "", m[3])))
  }
  NULL
}

#' Harvest GitHub repository metadata into the engine state.
#' @noRd
collect_github <- function(ctx, timeout = 15) {
  repo <- github_repo_of(c(ctx$pid_url, ctx$landing_url, ctx$id))
  if (is.null(repo)) return(invisible())

  api <- sprintf("https://api.github.com/repos/%s/%s", repo$owner, repo$name)
  req <- httr2::request(api)
  req <- httr2::req_headers(req, Accept = "application/vnd.github+json",
                            `X-GitHub-Api-Version` = "2022-11-28")
  req <- httr2::req_user_agent(req, "rfuji R package")
  req <- httr2::req_timeout(req, timeout)
  req <- httr2::req_error(req, is_error = function(resp) FALSE)
  token <- Sys.getenv("GITHUB_TOKEN", "")
  if (nzchar(token)) req <- httr2::req_auth_bearer_token(req, token)

  resp <- tryCatch(httr2::req_perform(req), error = function(e) NULL)
  if (is.null(resp) || httr2::resp_status(resp) >= 400) return(invisible())
  j <- tryCatch(httr2::resp_body_json(resp), error = function(e) NULL)
  if (is.null(j)) return(invisible())

  spdx <- jget(j, "license", "spdx_id")
  if (identical(spdx, "NOASSERTION")) spdx <- NULL
  md <- compact(list(
    object_identifier = j$html_url,
    title = j$name,
    summary = j$description,
    object_type = "Software",
    keywords = if (length(j$topics)) as.list(unlist(j$topics)) else NULL,
    license = spdx %||% jget(j, "license", "url"),
    publisher = jget(j, "owner", "login"),
    created_date = j$created_at,
    modified_date = j$updated_at,
    language = j$language
  ))
  if (length(md)) {
    merge_metadata(ctx, md, url = j$html_url, method = "github", format = "json",
                   mimetype = "application/json", schema = "https://docs.github.com/rest")
    ctx$metadata_sources[[length(ctx$metadata_sources) + 1L]] <-
      list(source = "github", method = "content_negotiation")
    ctx$github_data <- j
    ctx_log(ctx, "FsF-R1.1-01M", "info", "Harvested GitHub repository metadata")
  }

  # deeper software metadata: latest release version + codemeta.json + CITATION.cff
  branch <- j$default_branch %||% "main"
  ver <- tryCatch(github_json(paste0(api, "/releases/latest"), token, timeout)$tag_name,
                  error = function(e) NULL)
  cm <- github_software_files(ctx, repo, branch, token, timeout)
  sw <- compact(c(cm, list(version = ver %||% cm$version,
                           programming_language = j$language)))
  if (length(sw)) {
    merge_metadata(ctx, sw, url = j$html_url, method = "github", format = "json",
                   mimetype = "application/json", schema = "https://codemeta.github.io")
  }

  # software FAIR signals (for the FRSM software metrics) from the repo file tree
  ctx$software <- harvest_software_signals(api, repo, branch, j, ver, cm, token, timeout)
  invisible()
}

#' Detect software FAIR signals from the repository file tree + API.
#' @noRd
harvest_software_signals <- function(api, repo, branch, j, ver, cm, token = "", timeout = 15) {
  tree <- tryCatch(
    github_json(sprintf("%s/git/trees/%s?recursive=1", api, branch), token, timeout)$tree,
    error = function(e) NULL)
  paths <- tolower(as_chr(lapply(tree %||% list(), function(t) t$path)))
  any_match <- function(re) any(grepl(re, paths, perl = TRUE))

  contributors <- tryCatch(
    length(github_json(paste0(api, "/contributors?per_page=100"), token, timeout) %||% list()),
    error = function(e) 0L)
  github_license_refs <- software_license_refs(list(
    jget(j, "license", "spdx_id"),
    jget(j, "license", "url")
  ))
  metadata_license_refs <- software_license_refs(cm$license)
  license_ids <- software_spdx_ids(c(github_license_refs, metadata_license_refs))
  metadata_license_ids <- software_spdx_ids(metadata_license_refs)
  spdx_licenses <- tolower(vapply(ref_data("spdx"), function(x) x$licenseId %||% "", character(1)))
  has_spdx_license <- any(tolower(license_ids) %in% spdx_licenses)
  doi_pat <- "10\\.\\d{4,9}/[^\\s\"'<>]+"
  registry_doi <- NULL
  for (v in c(cm$object_identifier, unlist(cm$related_resources))) {
    m <- regmatches(v, regexpr(doi_pat, v %||% "", perl = TRUE))
    if (length(m)) { registry_doi <- m[1]; break }
  }
  has_interface_definition <- any_match("openapi|swagger|\\.proto$|graphql")
  has_open_api <- has_interface_definition && !isTRUE(j$private)
  has_format_schema <- has_interface_definition
  has_format_docs <- has_format_schema || any_match("as_fuji_json|as_rdf|jsonld|rdf|json-schema|schema\\.json")

  list(
    identifier = j$html_url,
    version = ver %||% cm$version,
    registry_doi = registry_doi,
    name = j$name, description = j$description,
    language = j$language, topics = j$topics %||% list(),
    contributors = contributors,
    archived = isTRUE(j$archived),
    has_license = !is.null(j$license) || any_match("^licen[sc]e"),
    has_spdx_license = has_spdx_license,
    has_metadata_spdx_license = any(tolower(metadata_license_ids) %in% spdx_licenses),
    has_readme = any_match("^readme"),
    has_citation = any_match("^citation\\.cff|^codemeta\\.json"),
    has_tests = any_match("(^|/)tests?(/|$)|(^|/)test_|_test\\.|\\.test\\."),
    has_ci = any_match("^\\.github/workflows/|^\\.travis|^\\.circleci|^azure-pipelines|^\\.gitlab-ci"),
    has_requirements = any_match("^(requirements.*\\.txt|setup\\.py|setup\\.cfg|pyproject\\.toml|package\\.json|description|environment\\.ya?ml|renv\\.lock|cargo\\.toml|go\\.mod|pom\\.xml|build\\.gradle)$"),
    has_docs = any_match("^docs?/|readthedocs|mkdocs\\.ya?ml"),
    has_api = has_interface_definition,
    has_open_api = has_open_api,
    has_machine_readable_api = has_interface_definition,
    has_data_format_docs = has_format_docs,
    has_open_data_formats = has_format_schema,
    has_schema_reference = has_format_schema
  )
}

#' Extract license reference strings from scalar or structured software metadata.
#' @noRd
software_license_refs <- function(x) {
  if (is.null(x)) return(character(0))
  if (is.list(x) && !is.data.frame(x)) {
    fields <- c(x[["@id"]], x$url, x$name, x$identifier, x$licenseId)
    if (length(fields)) return(as_chr(fields))
    return(as_chr(unlist(lapply(x, software_license_refs), use.names = FALSE)))
  }
  as_chr(x)
}

#' Normalize SPDX license references to SPDX identifiers.
#' @noRd
software_spdx_ids <- function(x) {
  refs <- unique(software_license_refs(x))
  refs <- refs[refs != "NOASSERTION"]
  unname(vapply(refs, function(ref) {
    if (grepl("^https?://([^/]+\\.)?spdx\\.org/licenses/", ref, ignore.case = TRUE)) {
      sub("\\.(html|json)$", "", sub(".*/", "", ref), ignore.case = TRUE)
    } else {
      ref
    }
  }, character(1)))
}

#' GET + parse a GitHub API JSON resource.
#' @noRd
github_json <- function(url, token = "", timeout = 15) {
  req <- httr2::request(url)
  req <- httr2::req_headers(req, Accept = "application/vnd.github+json")
  req <- httr2::req_user_agent(req, "rfuji R package")
  req <- httr2::req_timeout(req, timeout)
  req <- httr2::req_error(req, is_error = function(resp) FALSE)
  if (nzchar(token)) req <- httr2::req_auth_bearer_token(req, token)
  resp <- httr2::req_perform(req)
  if (httr2::resp_status(resp) >= 400) return(NULL)
  httr2::resp_body_json(resp)
}

#' Harvest codemeta.json / CITATION.cff from a repo's default branch.
#' @noRd
github_software_files <- function(ctx, repo, branch, token = "", timeout = 15) {
  raw <- function(path) sprintf("https://raw.githubusercontent.com/%s/%s/%s/%s",
                                repo$owner, repo$name, branch, path)
  out <- list()
  # codemeta.json
  cm <- tryCatch({
    r <- content_negotiate(raw("codemeta.json"), accept = "json", timeout = timeout)
    if (isTRUE(r$ok)) jsonlite::fromJSON(r$content, simplifyVector = FALSE) else NULL
  }, error = function(e) NULL)
  if (!is.null(cm)) {
    out$title <- cm$name
    out$summary <- cm$description
    out$version <- cm$version %||% cm$softwareVersion
    out$object_identifier <- cm$identifier %||% cm$codeRepository
    lic <- cm$license
    if (is.list(lic)) lic <- lic[["@id"]] %||% lic$url %||% lic$name
    if (!is.null(lic)) out$license <- as_chr(lic)
    if (!is.null(cm$keywords)) out$keywords <- as.list(as_chr(cm$keywords))
    ctx$metadata_sources[[length(ctx$metadata_sources) + 1L]] <-
      list(source = "codemeta", method = "content_negotiation")
  }
  # CITATION.cff (YAML) -- version + doi
  cff <- tryCatch({
    r <- content_negotiate(raw("CITATION.cff"), accept = "default", timeout = timeout)
    if (isTRUE(r$ok)) yaml::yaml.load(r$content) else NULL
  }, error = function(e) NULL)
  if (is.list(cff)) {
    out$version <- out$version %||% cff$version
    if (!is.null(cff$doi)) out$related_resources <- list(list(
      related_resource = paste0("https://doi.org/", cff$doi), relation_type = "isIdenticalTo"))
  }
  compact(out)
}
