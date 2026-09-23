# Code forge harvester for GitHub, GitLab, and Codeberg (Forgejo/Gitea). When
# the assessed object is a repository, or (under the software metrics) software
# whose metadata points at one, it harvests repository metadata and the
# software FAIR signals that the FRSM metrics score. Ported in spirit from
# F-UJI's github_harvester.py.
#
# Tokens raise the API rate limits: GITHUB_PAT (or GITHUB_TOKEN), GITLAB_PAT,
# and CODEBERG_TOKEN.

.FORGE_HOSTS <- c("github.com" = "github", "gitlab.com" = "gitlab", "codeberg.org" = "gitea")

#' Detect a forge repository from candidate URLs.
#' @return A list with `forge`, `host`, `owner`, `name`, and `path`, or NULL.
#' @noRd
forge_of <- function(urls) {
  for (u in as_chr(urls)) {
    parts <- tryCatch(httr2::url_parse(u), error = function(e) NULL)
    if (is.null(parts)) next
    host <- sub("^www\\.", "", tolower(parts$hostname %||% ""))
    forge <- unname(.FORGE_HOSTS[host])
    if (is.na(forge)) next
    seg <- strsplit(parts$path %||% "", "/", fixed = TRUE)[[1]]
    seg <- seg[nzchar(seg)]
    if (identical(forge, "gitlab")) {
      # GitLab groups nest; the project path ends where "/-/" begins
      cut <- match("-", seg)
      if (!is.na(cut)) seg <- seg[seq_len(cut - 1L)]
    } else {
      seg <- utils::head(seg, 2L)
    }
    if (length(seg) < 2L) next
    seg[length(seg)] <- sub("\\.git$", "", seg[length(seg)])
    return(list(forge = forge, host = host, owner = seg[1], name = seg[length(seg)],
                path = paste(seg, collapse = "/")))
  }
  NULL
}

#' Detect an owner/repo pair on GitHub from candidate URLs.
#' @noRd
github_repo_of <- function(urls) {
  r <- forge_of(urls)
  if (is.null(r) || !identical(r$forge, "github")) return(NULL)
  list(owner = r$owner, name = r$name)
}

#' API token for a forge, from its environment variables.
#' @noRd
forge_token <- function(forge) {
  vars <- switch(forge, github = c("GITHUB_PAT", "GITHUB_TOKEN"),
                 gitlab = c("GITLAB_PAT", "GITLAB_TOKEN"), gitea = "CODEBERG_TOKEN",
                 character(0))
  for (v in vars) {
    tok <- Sys.getenv(v, "")
    if (nzchar(tok)) return(tok)
  }
  ""
}

#' GitHub token from GITHUB_PAT (the gh/gitcreds convention) or GITHUB_TOKEN.
#' @noRd
github_token <- function() forge_token("github")

#' Record a failed metadata source on the engine state.
#' @noRd
add_harvest_error <- function(ctx, source, url, message, status = NA_integer_) {
  if (is.null(ctx)) return(invisible())
  ctx$harvest_errors[[length(ctx$harvest_errors) + 1L]] <-
    list(source = source, url = url, status = as.integer(status), message = message)
  invisible()
}

#' GET + parse a JSON API resource (code forges, registries, repositories).
#'
#' A rate-limited response (429, or 403 with a zero remaining quota) is recorded
#' in `ctx$harvest_errors` and raised as an `rfair_rate_limit` warning, once per
#' API and assessment; later calls to that API are skipped, so a rate limit
#' cannot lower the scores without a trace. GitLab's next-page number is kept
#' in the `next_page` attribute.
#' @noRd
api_json <- function(url, forge, ctx = NULL, timeout = 15) {
  if (isTRUE(ctx$forge_rate_limited[[forge]])) return(NULL)
  accept <- if (identical(forge, "github")) "application/vnd.github+json" else "application/json"
  req <- rfair_request(url, timeout = timeout, accept = accept,
                       user_agent = "rfair R package", retry = FALSE)
  if (identical(forge, "github")) req <- httr2::req_headers(req, `X-GitHub-Api-Version` = "2022-11-28")
  token <- forge_token(forge)
  # every forge accepts a Bearer token; libcurl keeps Authorization from
  # following a redirect to another host, which it does not do for GitLab's
  # custom PRIVATE-TOKEN header
  if (nzchar(token)) req <- httr2::req_auth_bearer_token(req, token)
  resp <- rfair_perform(req, ctx = ctx, source = forge)
  if (!is_response(resp)) return(NULL)
  status <- httr2::resp_status(resp)
  remaining <- httr2::resp_header(resp, "x-ratelimit-remaining") %||%
    httr2::resp_header(resp, "ratelimit-remaining")
  if (status == 429L || (status == 403L && identical(remaining, "0"))) {
    reset <- suppressWarnings(as.numeric(httr2::resp_header(resp, "x-ratelimit-reset") %||%
                                           httr2::resp_header(resp, "ratelimit-reset")))
    when <- if (is.na(reset)) "later" else
      format(as.POSIXct(reset, origin = "1970-01-01"), "%Y-%m-%d %H:%M:%S %Z")
    msg <- sprintf(paste0("%s API rate limit reached; this assessment is incomplete. ",
                          "It resets at %s.%s"),
                   forge, when, if (identical(forge, "github"))
                     " Set GITHUB_PAT to raise the limit." else "")
    add_harvest_error(ctx, forge, url, msg, status)
    if (!is.null(ctx)) ctx$forge_rate_limited[[forge]] <- TRUE
    warning(warningCondition(msg, class = "rfair_rate_limit"))
    return(NULL)
  }
  if (status >= 400) return(NULL)
  body <- tryCatch(httr2::resp_body_json(resp, check_type = FALSE), error = function(e) NULL)
  if (!is.null(body)) attr(body, "next_page") <- httr2::resp_header(resp, "x-next-page")
  body
}

#' Repository facts from GitHub, normalized across forges.
#' @noRd
forge_info_github <- function(r, ctx, timeout) {
  api <- sprintf("https://api.github.com/repos/%s/%s", r$owner, r$name)
  j <- api_json(api, "github", ctx, timeout)
  if (is.null(j)) return(NULL)
  branch <- j$default_branch %||% "main"
  tree <- api_json(sprintf("%s/git/trees/%s?recursive=1", api, branch), "github", ctx, timeout)
  list(
    forge = "github", html_url = j$html_url, name = j$name, description = j$description,
    topics = as_chr(j$topics),
    license_refs = as_chr(c(jget(j, "license", "spdx_id"), jget(j, "license", "url"))),
    owner = jget(j, "owner", "login"), created = j$created_at, updated = j$updated_at,
    language = j$language, private = isTRUE(j$private), archived = isTRUE(j$archived),
    has_issues = isTRUE(j$has_issues),
    release = api_json(paste0(api, "/releases/latest"), "github", ctx, timeout)$tag_name,
    paths = as_chr(lapply(tree$tree %||% list(), function(t) t$path)),
    contributors = length(api_json(paste0(api, "/contributors?per_page=100"),
                                     "github", ctx, timeout) %||% list()),
    raw = function(p) sprintf("https://raw.githubusercontent.com/%s/%s/%s/%s",
                              r$owner, r$name, branch, p))
}

#' Repository facts from a GitLab instance (API v4).
#' @noRd
forge_info_gitlab <- function(r, ctx, timeout) {
  api <- sprintf("https://%s/api/v4/projects/%s", r$host, utils::URLencode(r$path, reserved = TRUE))
  j <- api_json(paste0(api, "?license=true"), "gitlab", ctx, timeout)
  if (is.null(j)) return(NULL)
  branch <- j$default_branch %||% "main"
  paths <- character(0)
  page <- "1"
  for (i in seq_len(20)) {   # ponytail: 2000 paths; enough for signal detection
    t <- api_json(sprintf("%s/repository/tree?recursive=true&per_page=100&page=%s", api, page),
                    "gitlab", ctx, timeout)
    paths <- c(paths, as_chr(lapply(t %||% list(), function(x) x$path)))
    page <- attr(t, "next_page")
    if (!is_nonempty_string(page)) break
  }
  langs <- unlist(api_json(paste0(api, "/languages"), "gitlab", ctx, timeout))
  releases <- api_json(paste0(api, "/releases?per_page=1"), "gitlab", ctx, timeout)
  list(
    forge = "gitlab", html_url = j$web_url, name = j$name, description = j$description,
    topics = as_chr(j$topics %||% j$tag_list),
    license_refs = as_chr(c(jget(j, "license", "key"), jget(j, "license", "html_url"))),
    owner = jget(j, "namespace", "path"), created = j$created_at, updated = j$last_activity_at,
    language = if (length(langs)) names(langs)[which.max(langs)],
    private = !identical(j$visibility, "public"), archived = isTRUE(j$archived),
    has_issues = isTRUE(j$issues_enabled) || !is.null(jget(j, "_links", "issues")),
    release = if (length(releases)) releases[[1]]$tag_name,
    paths = paths,
    contributors = length(api_json(paste0(api, "/repository/contributors?per_page=100"),
                                     "gitlab", ctx, timeout) %||% list()),
    raw = function(p) sprintf("%s/-/raw/%s/%s", j$web_url, branch, p))
}

#' Repository facts from a Forgejo/Gitea instance such as Codeberg (API v1).
#' @noRd
forge_info_gitea <- function(r, ctx, timeout) {
  api <- sprintf("https://%s/api/v1/repos/%s/%s", r$host, r$owner, r$name)
  j <- api_json(api, "gitea", ctx, timeout)
  if (is.null(j)) return(NULL)
  branch <- j$default_branch %||% "main"
  tree <- api_json(sprintf("%s/git/trees/%s?recursive=true&per_page=10000", api, branch),
                     "gitea", ctx, timeout)
  # Gitea has no public contributors endpoint; count recent commit authors
  commits <- api_json(sprintf("%s/commits?limit=50&stat=false&verification=false&files=false", api),
                        "gitea", ctx, timeout)
  authors <- unique(as_chr(lapply(commits %||% list(), function(c) jget(c, "commit", "author", "email"))))
  list(
    forge = "gitea", html_url = j$html_url, name = j$name, description = j$description,
    topics = as_chr(j$topics), license_refs = as_chr(j$licenses),
    owner = jget(j, "owner", "login"), created = j$created_at, updated = j$updated_at,
    language = j$language, private = isTRUE(j$private), archived = isTRUE(j$archived),
    has_issues = isTRUE(j$has_issues),
    release = api_json(paste0(api, "/releases/latest"), "gitea", ctx, timeout)$tag_name,
    paths = as_chr(lapply(tree$tree %||% list(), function(t) t$path)),
    contributors = length(authors),
    raw = function(p) sprintf("https://%s/%s/%s/raw/branch/%s/%s", r$host, r$owner, r$name, branch, p))
}

#' Is the assessment scoring software (FRSM metrics)?
#' @noRd
is_software_assessment <- function(ctx) grepl("software", ctx$metrics$version %||% "")

#' Harvest forge repository metadata and software signals into the engine state.
#'
#' A repository URL is harvested directly. Under the software metrics, a DOI or
#' other identifier whose metadata links a repository (for example Zenodo's
#' `IsSupplementTo` link to GitHub) is bridged to it: the repository supplies
#' the software signals, while the registry record stays the metadata of record.
#' @noRd
collect_forge <- function(ctx, timeout = 15) {
  repo <- forge_of(c(ctx$pid_url, ctx$landing_url, ctx$id))
  bridged <- FALSE
  if (is.null(repo) && is_software_assessment(ctx)) {
    linked <- c(as_chr(lapply(ctx$related_resources, function(r) r$related_resource)),
                as_chr(ctx$metadata_merged$object_identifier))
    repo <- forge_of(linked)
    bridged <- !is.null(repo)
  }
  if (is.null(repo)) return(invisible())

  info <- switch(repo$forge,
                 github = forge_info_github(repo, ctx, timeout),
                 gitlab = forge_info_gitlab(repo, ctx, timeout),
                 gitea = forge_info_gitea(repo, ctx, timeout))
  if (is.null(info)) return(invisible())

  cm <- forge_software_files(ctx, info, timeout, record = !bridged)
  if (!bridged) {
    spdx <- setdiff(info$license_refs, "NOASSERTION")
    md <- compact(list(
      object_identifier = info$html_url, title = info$name, summary = info$description,
      object_type = "Software",
      keywords = if (length(info$topics)) as.list(info$topics),
      license = spdx[1] %||% NULL, publisher = info$owner,
      created_date = info$created, modified_date = info$updated, language = info$language))
    if (length(md)) {
      merge_metadata(ctx, md, url = info$html_url, method = info$forge, format = "json",
                     mimetype = "application/json", schema = forge_schema(info$forge))
      ctx$metadata_sources[[length(ctx$metadata_sources) + 1L]] <-
        list(source = info$forge, method = "content_negotiation")
      ctx$github_data <- info
      ctx_log(ctx, "FsF-R1.1-01M", "info", paste("Harvested", info$forge, "repository metadata"))
    }
    sw_md <- compact(c(cm, list(version = info$release %||% cm$version,
                                programming_language = info$language)))
    if (length(sw_md)) {
      merge_metadata(ctx, sw_md, url = info$html_url, method = info$forge, format = "json",
                     mimetype = "application/json", schema = "https://codemeta.github.io")
    }
  }

  sw <- software_signals(info, cm, ctx, timeout)
  if (bridged) {
    sw$identifier <- ctx$pid_url
    sw$repository <- info$html_url
    if (identical(ctx$pid$preferred_schema, "doi")) sw$registry_doi <- ctx$pid$normalized_id
  }
  ctx$software <- sw
  invisible()
}

#' @noRd
forge_schema <- function(forge) {
  switch(forge, github = "https://docs.github.com/rest",
         gitlab = "https://docs.gitlab.com/api/", gitea = "https://gitea.com/api/swagger")
}

#' Detect software FAIR signals from normalized repository facts.
#' @noRd
software_signals <- function(info, cm, ctx = NULL, timeout = 15) {
  paths <- tolower(info$paths)
  any_match <- function(re) any(grepl(re, paths, perl = TRUE))

  metadata_license_refs <- software_license_refs(cm$license)
  license_ids <- software_spdx_ids(c(info$license_refs, metadata_license_refs))
  metadata_license_ids <- software_spdx_ids(metadata_license_refs)
  spdx_licenses <- tolower(vapply(ref_data("spdx"), function(x) x$licenseId %||% "", character(1)))
  has_spdx_license <- any(tolower(license_ids) %in% spdx_licenses)
  doi_pat <- "10\\.\\d{4,9}/[^\\s\"'<>]+"
  registry_doi <- NULL
  for (v in c(cm$object_identifier, unlist(cm$related_resources))) {
    m <- regmatches(v, regexpr(doi_pat, v %||% "", perl = TRUE))
    if (length(m)) { registry_doi <- m[1]; break }
  }
  path_signals <- software_path_signals(paths, private = info$private)

  read_raw <- function(path) {
    r <- content_negotiate(info$raw(path), accept = "default", timeout = timeout, ctx = ctx)
    if (isTRUE(r$ok)) as_chr(r$content) else ""
  }
  meta_text <- paste(read_raw("codemeta.json"), read_raw("CITATION.cff"),
                     read_raw("README.md"), collapse = " ")
  has_credit_roles <- grepl("rolename|credit\\.niso\\.org", meta_text, ignore.case = TRUE)

  # archiving infrastructures beyond the DOI registry: Software Heritage and a
  # language package registry (CRAN, PyPI)
  in_swh <- !info$private && !is.null(api_json(
    sprintf("https://archive.softwareheritage.org/api/1/origin/%s/get/", info$html_url),
    "swh", ctx, timeout))
  registry <- package_registry(info, read_raw, ctx, timeout)
  has_multiple_archives <- is_nonempty_string(registry_doi) &&
    (in_swh || !is.na(registry) ||
       grepl("softwareheritage\\.org|swh:1:|cran\\.r-project\\.org/package", meta_text, ignore.case = TRUE))

  list(
    identifier = info$html_url,
    forge = info$forge,
    version = info$release %||% cm$version,
    registry_doi = registry_doi,
    name = info$name, description = info$description,
    language = info$language, topics = as.list(info$topics),
    contributors = info$contributors,
    archived = isTRUE(info$archived),
    has_license = length(setdiff(info$license_refs, "NOASSERTION")) > 0L || any_match("^licen[sc]e"),
    has_spdx_license = has_spdx_license,
    has_metadata_spdx_license = any(tolower(metadata_license_ids) %in% spdx_licenses),
    has_readme = any_match("^readme"),
    has_citation = any_match("^citation\\.cff|^codemeta\\.json"),
    has_tests = any_match("(^|/)tests?(/|$)|(^|/)test_|_test\\.|\\.test\\."),
    has_ci = any_match("^\\.github/workflows/|^\\.travis|^\\.circleci|^azure-pipelines|^\\.gitlab-ci|^\\.forgejo/workflows/|^\\.gitea/workflows/|^\\.woodpecker"),
    has_requirements = any_match("^(requirements.*\\.txt|setup\\.py|setup\\.cfg|pyproject\\.toml|package\\.json|description|environment\\.ya?ml|renv\\.lock|cargo\\.toml|go\\.mod|pom\\.xml|build\\.gradle)$"),
    has_docs = any_match("^docs?/|readthedocs|mkdocs\\.ya?ml"),
    has_coverage = any_match("codecov|coveralls|(^|/)test-coverage|\\.codecov|(^|/)covr(\\.|/)"),
    is_public = !isTRUE(info$private),
    has_issue_tracker = isTRUE(info$has_issues),
    has_api = path_signals$has_api,
    has_open_api = path_signals$has_open_api,
    has_machine_readable_api = path_signals$has_machine_readable_api,
    has_data_format_docs = path_signals$has_data_format_docs,
    has_open_data_formats = path_signals$has_open_data_formats,
    has_schema_reference = path_signals$has_schema_reference,
    has_bundled_license_info = any_match("(^|/)(notice|copyrights?|authors)(\\.[a-z0-9]+)?$|licen[sc]e\\.note$|(^|/)licen[sc]es?/|third[-_]?party"),
    has_credit_roles = has_credit_roles,
    in_software_heritage = in_swh,
    package_registry = registry,
    has_multiple_archives = has_multiple_archives,
    has_provenance_metadata = any_match("ro-crate-metadata\\.json$|(^|/)ro-crate|\\.prov(\\.|$)|(^|/)provenance|(^|/)attestations?/|(^|/)slsa")
  )
}

#' Language package registry the repository is published in ("CRAN", "PyPI"), or NA.
#'
#' Reads the package name from DESCRIPTION (R) or pyproject.toml / setup.cfg
#' (Python) and checks that the registry has it.
#' @noRd
package_registry <- function(info, read_raw, ctx = NULL, timeout = 15) {
  paths <- tolower(info$paths)
  exists_at <- function(url) {
    resp <- rfair_perform(rfair_request(url, timeout = timeout, method = "HEAD"),
                          ctx = NULL, source = "registry")
    is_response(resp) && httr2::resp_status(resp) < 400L
  }
  if ("description" %in% paths) {
    desc <- read_raw("DESCRIPTION")
    pkg <- sub("^Package:\\s*", "", regmatches(desc, regexpr("(?m)^Package:\\s*\\S+", desc, perl = TRUE)))
    if (is_nonempty_string(pkg) && exists_at(sprintf("https://cran.r-project.org/package=%s", pkg))) {
      return("CRAN")
    }
  }
  py <- if ("pyproject.toml" %in% paths) read_raw("pyproject.toml")
        else if ("setup.cfg" %in% paths) read_raw("setup.cfg") else ""
  name <- regmatches(py, regexpr("(?m)^\\s*name\\s*=\\s*[\"']?[A-Za-z0-9._-]+", py, perl = TRUE))
  if (length(name)) {
    name <- sub("^\\s*name\\s*=\\s*[\"']?", "", name, perl = TRUE)
    if (exists_at(sprintf("https://pypi.org/pypi/%s/json", name))) return("PyPI")
  }
  NA_character_
}

#' Detect software API, data-format, and schema signals from repository paths.
#' @noRd
software_path_signals <- function(paths, private = FALSE) {
  paths <- tolower(as_chr(paths))
  any_match <- function(re) any(grepl(re, paths, perl = TRUE))
  has_interface_definition <- any_match("openapi|swagger|\\.proto$|graphql")
  has_open_data_format <- any_match("(^|/)(openapi|swagger).*\\.(ya?ml|json)$|jsonld|json-ld|rdf|rdfs|\\.ttl$|\\.turtle$|\\.csv$|\\.tsv$|\\.parquet$|\\.feather$|\\.hdf5?$|\\.nc$|\\.netcdf$|\\.xml$")
  has_schema_reference <- any_match("(^|/)(openapi|swagger).*\\.(ya?ml|json)$|json-schema|schema\\.json|\\.schema\\.json$|\\.xsd$|rdfs|\\.proto$|graphql")
  has_format_docs <- has_open_data_format || has_schema_reference ||
    any_match("as_fuji_json|as_rdf|jsonld|rdf|json-schema|schema\\.json")
  list(
    has_api = has_interface_definition,
    has_open_api = has_interface_definition && !isTRUE(private),
    has_machine_readable_api = has_interface_definition,
    has_data_format_docs = has_format_docs,
    has_open_data_formats = has_open_data_format,
    has_schema_reference = has_schema_reference
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

#' Harvest codemeta.json / CITATION.cff from a repository's default branch.
#'
#' `record = FALSE` reads them without registering them as metadata sources
#' (used when a registry record is the metadata of record).
#' @noRd
forge_software_files <- function(ctx, info, timeout = 15, record = TRUE) {
  out <- list()
  cm <- tryCatch({
    r <- content_negotiate(info$raw("codemeta.json"), accept = "json", timeout = timeout, ctx = ctx)
    if (isTRUE(r$ok)) jsonlite::fromJSON(r$content, simplifyVector = FALSE) else NULL
  }, error = function(e) NULL)
  if (is.list(cm)) {
    out$title <- cm$name
    out$summary <- cm$description
    out$version <- cm$version %||% cm$softwareVersion
    out$object_identifier <- cm$identifier %||% cm$codeRepository
    lic <- cm$license
    if (is.list(lic)) lic <- lic[["@id"]] %||% lic$url %||% lic$name
    if (!is.null(lic)) out$license <- as_chr(lic)
    if (!is.null(cm$keywords)) out$keywords <- as.list(as_chr(cm$keywords))
    if (record) {
      ctx$metadata_sources[[length(ctx$metadata_sources) + 1L]] <-
        list(source = "codemeta", method = "content_negotiation")
    }
  }
  cff <- tryCatch({
    r <- content_negotiate(info$raw("CITATION.cff"), accept = "default", timeout = timeout, ctx = ctx)
    if (isTRUE(r$ok)) yaml::yaml.load(r$content) else NULL
  }, error = function(e) NULL)
  if (is.list(cff)) {
    out$version <- out$version %||% cff$version
    doi <- cff$doi %||% as_chr(jmap(jfilter(cff$identifiers, "type", "doi"), "value"))[1]
    if (is_nonempty_string(doi)) out$related_resources <- list(list(
      related_resource = paste0("https://doi.org/", doi), relation_type = "isIdenticalTo"))
  }
  compact(out)
}
