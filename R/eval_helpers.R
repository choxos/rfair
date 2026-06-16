# Shared helpers used by the metric evaluators.

#' Lowercased URL scheme, or NA.
#' @noRd
url_scheme <- function(u) {
  if (!is_nonempty_string(u)) return(NA_character_)
  tolower(tryCatch(httr2::url_parse(u)$scheme, error = function(e) NA_character_) %||% NA_character_)
}

#' Content (data) URLs harvested into object_content_identifier.
#' @noRd
content_urls_of <- function(ctx) {
  oci <- ctx$metadata_merged$object_content_identifier
  if (is.null(oci)) return(character(0))
  items <- if (is.list(oci) && is.null(names(oci))) oci else list(oci)
  as_chr(lapply(items, function(x) if (is.list(x)) x$url else x))
}

#' Is a URL scheme a standardized communication protocol?
#' @noRd
is_standard_protocol <- function(scheme) {
  is_nonempty_string(scheme) && scheme %in% names(ref_data("standard_protocols"))
}

#' Does a standard protocol support authentication?
#' @noRd
protocol_supports_auth <- function(scheme) {
  if (!is_standard_protocol(scheme)) return(FALSE)
  is_nonempty_string(ref_data("standard_protocols")[[scheme]]$auth)
}

#' Names of the metadata sources harvested so far (lowercased).
#' @noRd
source_names <- function(ctx) {
  vapply(ctx$metadata_sources, function(s) tolower(s$source %||% ""), character(1))
}

#' Did a metadata source arrive by a given offering method?
#' @noRd
has_offering_method <- function(ctx, method) {
  any(vapply(ctx$metadata_sources, function(s) identical(s$method, method), logical(1)))
}

#' Does a value look like a resolvable PID/URL?
#' @noRd
looks_like_pid <- function(x) is_nonempty_string(x) && !is.na(id_parse(x)$preferred_schema)

#' Vocabulary / schema namespace URIs encountered while harvesting.
#' @noRd
ctx_namespace_uris <- function(ctx) {
  uris <- character(0)
  for (rec in ctx$metadata_unmerged) {
    if (is_nonempty_string(rec$schema)) uris <- c(uris, rec$schema)
    uris <- c(uris, as_chr(rec$namespaces))
  }
  unique(uris[nzchar(uris)])
}

#' Look up a metadata standard for a namespace URI (with path-prefix fallback).
#' @noRd
lookup_standard <- function(ns) {
  ms <- ref_data("metadata_standards")
  n <- sub("[/#]+$", "", sub("^https?://", "", tolower(ns)))
  repeat {
    if (!is.null(ms[[n]])) return(ms[[n]])
    if (!grepl("/", n)) return(NULL)
    n <- sub("/[^/]*$", "", n)   # trim trailing path segment and retry
  }
}
