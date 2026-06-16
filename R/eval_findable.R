# Findability metrics beyond identifiers: FsF-F3-01M and FsF-F4-01M.

#' FsF-F3-01M: metadata includes the identifier of the data it describes.
#' @noRd
eval_data_identifier_included <- function(ctx, res) {
  t <- paste0(res$metric_identifier, "-2")
  urls <- content_urls_of(ctx)
  if (crit_is_defined(res, t) && length(urls) > 0L) {
    crit_pass(res, t, evidence = urls)
  }
  res$output <- list(object_content_identifier = content_urls_of(ctx))
}

#' FsF-F4-01M: metadata is offered so search engines can index it.
#'
#' F-UJI counts only EMBEDDED offering methods (meta tags, embedded JSON-LD,
#' microdata, RDFa) for search-engine ingestion; content-negotiated metadata
#' does not qualify.
#' @noRd
eval_searchable <- function(ctx, res) {
  t <- paste0(res$metric_identifier, "-1")
  embedded <- Filter(function(s) s$method %in% c("embedded", "meta_tags", "microdata", "rdfa"),
                     ctx$metadata_sources)
  mechs <- unique(vapply(embedded, function(s) tolower(s$source %||% ""), character(1)))
  if (crit_is_defined(res, t) && length(embedded) > 0L) {
    crit_pass(res, t, evidence = mechs)
  }
  res$output <- list(search_mechanisms = mechs)
}
