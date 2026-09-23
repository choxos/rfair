# Data-file lists from repository APIs. Many repositories publish no
# schema.org `distribution` or signposting `item` links, so FsF-F3-01M,
# FsF-A1-02MD-2, and FsF-R1.3-02D under-scored. When no data links were
# harvested, ask the repository's own API for its file list: Zenodo, figshare,
# Dataverse, and Dryad.

#' File entries (url, type, size, name) from the landing page's repository API.
#' @return A list of file entries, or NULL when the host is not supported.
#' @noRd
repository_files <- function(url, ctx = NULL, timeout = 15) {
  parts <- tryCatch(httr2::url_parse(url), error = function(e) NULL)
  if (is.null(parts)) return(NULL)
  host <- tolower(parts$hostname %||% "")
  path <- parts$path %||% ""
  seg <- Filter(nzchar, strsplit(path, "/", fixed = TRUE)[[1]])
  entry <- function(url, name = NULL, type = NULL, size = NULL) {
    guessed <- mime::guess_type(name %||% url, unknown = NA_character_, empty = NA_character_)
    compact(list(url = url, name = name,
                 type = type %||% (if (!is.na(guessed)) guessed),
                 size = if (!is.null(size)) as.character(size)))
  }

  if (host %in% c("zenodo.org", "sandbox.zenodo.org") && grepl("^/records?/[0-9]+", path)) {
    id <- sub("^/records?/([0-9]+).*$", "\\1", path)
    j <- api_json(sprintf("https://%s/api/records/%s", host, id), "zenodo", ctx, timeout)
    return(lapply(j$files %||% list(), function(f)
      entry(jget(f, "links", "self"), f$key, size = f$size)))
  }

  if (grepl("(^|\\.)figshare\\.com$", host) && "articles" %in% seg) {
    nums <- seg[grepl("^[0-9]+$", seg)]
    if (!length(nums)) return(NULL)
    # /articles/<type>/<title>/<id>/<version>: a short trailing number is the version
    id <- if (length(nums) >= 2L && nchar(nums[length(nums)]) <= 3L) nums[length(nums) - 1L]
          else nums[length(nums)]
    j <- api_json(sprintf("https://api.figshare.com/v2/articles/%s", id), "figshare", ctx, timeout)
    return(lapply(j$files %||% list(), function(f)
      entry(f$download_url, f$name, f$mimetype, f$size)))
  }

  pid <- httr2::url_parse(url)$query$persistentId
  if (grepl("dataset\\.xhtml$", path) && is_nonempty_string(pid)) {
    j <- api_json(sprintf("https://%s/api/datasets/:persistentId/?persistentId=%s", host,
                          utils::URLencode(pid, reserved = TRUE)), "dataverse", ctx, timeout)
    files <- jget(j, "data", "latestVersion", "files") %||% list()
    return(lapply(files, function(f) {
      d <- f$dataFile %||% list()
      entry(sprintf("https://%s/api/access/datafile/%s", host, d$id), d$filename,
            d$contentType, d$filesize)
    }))
  }

  if (identical(host, "datadryad.org") && any(grepl("^doi:", seg))) {
    doi <- paste(seg[which(grepl("^doi:", seg))[1]:length(seg)], collapse = "/")
    api <- "https://datadryad.org/api/v2"
    ds <- api_json(sprintf("%s/datasets/%s", api, utils::URLencode(doi, reserved = TRUE)),
                   "dryad", ctx, timeout)
    version <- jget(ds, "_links", "stash:version", "href")
    if (!is_nonempty_string(version)) return(list())
    # ponytail: first page of files only (Dryad pages them); enough for format signals
    fl <- api_json(paste0("https://datadryad.org", version, "/files"), "dryad", ctx, timeout)
    return(lapply(jget(fl, "_embedded", "stash:files") %||% list(), function(f)
      entry(xml2::url_absolute(jget(f, "_links", "stash:download", "href") %||% "", "https://datadryad.org"),
            f$path, f$mimeType, f$size)))
  }
  NULL
}

#' Fill object_content_identifier from the repository API when nothing else did.
#' @noRd
collect_repository_files <- function(ctx, timeout = 15) {
  if (length(ctx$metadata_merged$object_content_identifier)) return(invisible())
  url <- if (is_nonempty_string(ctx$landing_url)) ctx$landing_url else ctx$pid_url
  files <- Filter(function(f) is_nonempty_string(f$url), repository_files(url, ctx, timeout) %||% list())
  if (!length(files)) return(invisible())
  md <- list(object_content_identifier = files)
  sizes <- as_chr(lapply(files, function(f) f$size))
  if (length(sizes)) md$object_size <- sizes[1]
  merge_metadata(ctx, md, url = url, method = "repository_api", format = "json",
                 mimetype = "application/json", schema = "")
  ctx$metadata_sources[[length(ctx$metadata_sources) + 1L]] <-
    list(source = "repository_api", method = "api")
  ctx_log(ctx, "FsF-F3-01M", "info", sprintf("Found %d data files through the repository API", length(files)))
  invisible()
}
