# Accessibility metrics: FsF-A1-01M, FsF-A1-02MD, FsF-A1.1-01MD, FsF-A1.2-01MD.

#' FsF-A1-01M: access restrictions/rights can be identified in metadata.
#' @noRd
eval_data_access_level <- function(ctx, res) {
  # license URLs are often mixed into the rights field; they are NOT access info
  access <- Filter(function(a) {
    if (grepl("creativecommons|spdx.org/licenses|/legalcode|opensource.org/licenses", a)) return(FALSE)
    !is.na(map_access_right(a)) ||
      grepl("eu-repo/semantics/(open|closed|restricted|embargoed)", a)
  }, access_statements(ctx$metadata_merged))
  if (length(access) > 0L) {
    cond <- vapply(access, map_access_right, character(1))
    if (crit_is_defined_suffix(res, "-1")) crit_pass_suffix(res, "-1", evidence = access)
    if (crit_is_defined_suffix(res, "-2") && any(!is.na(cond))) {
      crit_pass_suffix(res, "-2", evidence = access)
    }
    if (crit_is_defined_suffix(res, "-3")) crit_pass_suffix(res, "-3", evidence = access)
    res$output <- list(access_level = access,
                       access_condition = unique(stats::na.omit(cond)))
  }
}

#' FsF-A1-02MD: metadata and data are retrievable via their identifiers.
#' @noRd
eval_retrievable <- function(ctx, res) {
  # metadata retrievable: some metadata record was actually harvested from a URL
  # (F-UJI testMetadataRetrievable walks metadata_unmerged the same way), so an
  # identifier that does not resolve earns nothing here.
  retrieved <- unique(as_chr(lapply(ctx$metadata_unmerged, function(r)
    if (is_nonempty_string(r$url) && is.list(r$metadata)) r$url)))
  if (crit_is_defined_suffix(res, "-1") && length(retrieved)) {
    crit_pass_suffix(res, "-1", evidence = retrieved)
  }
  # data retrievable: a probed content link answered with a 2xx status (F-UJI
  # testDataRetrievable checks the status code the same way)
  urls <- retrievable_content_urls(ctx)
  if (crit_is_defined_suffix(res, "-2") && length(urls)) crit_pass_suffix(res, "-2", evidence = urls)
}

#' FsF-A1.1-01MD: identifiers resolve over a standardized web protocol.
#' @noRd
eval_standard_protocol <- function(ctx, res) {
  meta_scheme <- Filter(is_standard_protocol, metadata_url_schemes(ctx))
  if (crit_is_defined_suffix(res, "-1") && length(meta_scheme)) {
    crit_pass_suffix(res, "-1", evidence = meta_scheme)
  }
  urls <- content_urls_of(ctx)
  data_ok <- any(vapply(urls, function(u) is_standard_protocol(url_scheme(u)), logical(1)))
  if (crit_is_defined_suffix(res, "-2") && data_ok) {
    crit_pass_suffix(res, "-2", evidence = urls)
  }
}

#' FsF-A1.2-01MD: the access protocol supports authentication where needed.
#' @noRd
eval_protocol_auth <- function(ctx, res) {
  meta_scheme <- Filter(protocol_supports_auth, metadata_url_schemes(ctx))
  if (crit_is_defined_suffix(res, "-1") && length(meta_scheme)) {
    crit_pass_suffix(res, "-1", evidence = meta_scheme)
  }
  urls <- content_urls_of(ctx)
  data_ok <- any(vapply(urls, function(u) protocol_supports_auth(url_scheme(u)), logical(1)))
  if (crit_is_defined_suffix(res, "-2") && data_ok) crit_pass_suffix(res, "-2", evidence = urls)
}

#' FsF-A1-03D (legacy): data is accessible through a standard protocol.
#' @noRd
eval_data_standard_protocol_legacy <- function(ctx, res) {
  urls <- content_urls_of(ctx)
  data_ok <- any(vapply(urls, function(u) is_standard_protocol(url_scheme(u)), logical(1)))
  if (crit_is_defined_suffix(res, "-1") && data_ok) {
    crit_pass_suffix(res, "-1", evidence = urls)
  }
}

#' FsF-A1-02M (legacy): metadata is accessible through a standard protocol.
#' @noRd
eval_metadata_standard_protocol_legacy <- function(ctx, res) {
  meta_scheme <- Filter(is_standard_protocol, metadata_url_schemes(ctx))
  if (crit_is_defined_suffix(res, "-1") && length(meta_scheme)) {
    crit_pass_suffix(res, "-1", evidence = meta_scheme)
  }
}

#' FsF-A2-01M (legacy): metadata remains available via a PID/landing page.
#' @noRd
eval_metadata_persistence_legacy <- function(ctx, res) {
  if (crit_is_defined_suffix(res, "-1") &&
      isTRUE(ctx$is_persistent) &&
      is_nonempty_string(ctx$landing_url)) {
    crit_pass_suffix(res, "-1", evidence = ctx$landing_url)
  }
}
