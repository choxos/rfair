# Accessibility metrics: FsF-A1-01M, FsF-A1-02MD, FsF-A1.1-01MD, FsF-A1.2-01MD.

#' FsF-A1-01M: access restrictions/rights can be identified in metadata.
#' @noRd
eval_data_access_level <- function(ctx, res) {
  t <- paste0(res$metric_identifier, "-1")
  # license URLs are often mixed into the rights field; they are NOT access info
  access <- Filter(function(a) {
    if (grepl("creativecommons|spdx.org/licenses|/legalcode|opensource.org/licenses", a)) return(FALSE)
    !is.na(map_access_right(a)) ||
      grepl("eu-repo/semantics/(open|closed|restricted|embargoed)", a)
  }, as_chr(ctx$metadata_merged$access_level))
  if (crit_is_defined(res, t) && length(access) > 0L) {
    cond <- vapply(access, map_access_right, character(1))
    crit_pass(res, t, evidence = access)
    res$output <- list(access_level = access,
                       access_condition = unique(stats::na.omit(cond)))
  }
}

#' FsF-A1-02MD: metadata and data are retrievable via their identifiers.
#' @noRd
eval_retrievable <- function(ctx, res) {
  mid <- res$metric_identifier
  # metadata retrievable: landing page resolved successfully
  t1 <- paste0(mid, "-1")
  if (crit_is_defined(res, t1) && is_nonempty_string(ctx$landing_url)) {
    crit_pass(res, t1, evidence = ctx$landing_url)
  }
  # data retrievable: content links present using a standard protocol
  t2 <- paste0(mid, "-2")
  urls <- content_urls_of(ctx)
  data_ok <- length(urls) > 0L && any(vapply(urls, function(u) is_standard_protocol(url_scheme(u)), logical(1)))
  if (crit_is_defined(res, t2) && data_ok) crit_pass(res, t2, evidence = urls)
}

#' FsF-A1.1-01MD: identifiers resolve over a standardized web protocol.
#' @noRd
eval_standard_protocol <- function(ctx, res) {
  mid <- res$metric_identifier
  t1 <- paste0(mid, "-1")
  meta_scheme <- url_scheme(ctx$landing_url %||% ctx$pid_url)
  if (crit_is_defined(res, t1) && is_standard_protocol(meta_scheme)) {
    crit_pass(res, t1, evidence = meta_scheme)
  }
  t2 <- paste0(mid, "-2")
  urls <- content_urls_of(ctx)
  data_ok <- any(vapply(urls, function(u) is_standard_protocol(url_scheme(u)), logical(1)))
  if (crit_is_defined(res, t2) && data_ok) {
    crit_pass(res, t2, evidence = urls)
  }
}

#' FsF-A1.2-01MD: the access protocol supports authentication where needed.
#' @noRd
eval_protocol_auth <- function(ctx, res) {
  mid <- res$metric_identifier
  t1 <- paste0(mid, "-1")
  meta_scheme <- url_scheme(ctx$landing_url %||% ctx$pid_url)
  if (crit_is_defined(res, t1) && protocol_supports_auth(meta_scheme)) {
    crit_pass(res, t1, evidence = meta_scheme)
  }
  t2 <- paste0(mid, "-2")
  urls <- content_urls_of(ctx)
  data_ok <- any(vapply(urls, function(u) protocol_supports_auth(url_scheme(u)), logical(1)))
  if (crit_is_defined(res, t2) && data_ok) crit_pass(res, t2, evidence = urls)
}
