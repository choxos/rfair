# Findability metrics beyond identifiers: FsF-F3-01M and FsF-F4-01M.

#' FsF-F3-01M: metadata includes the identifier of the data it describes.
#' @noRd
eval_data_identifier_included <- function(ctx, res) {
  urls <- content_urls_of(ctx)
  content_info <- !is.null(ctx$metadata_merged$object_format) ||
    !is.null(ctx$metadata_merged$object_size) ||
    length(urls) > 0L
  if (crit_is_defined_suffix(res, "-1") && content_info) {
    crit_pass_suffix(res, "-1", evidence = "data content metadata")
  }
  if (crit_is_defined_suffix(res, "-2") && length(urls) > 0L) {
    crit_pass_suffix(res, "-2", evidence = urls)
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
  embedded <- Filter(function(s) s$method %in% c("embedded", "meta_tags", "microdata", "rdfa"),
                     ctx$metadata_sources)
  mechs <- unique(vapply(embedded, function(s) tolower(s$source %||% ""), character(1)))
  if (crit_is_defined_suffix(res, "-1") && length(embedded) > 0L) {
    crit_pass_suffix(res, "-1", evidence = mechs)
  }

  sources <- source_names(ctx)
  if (crit_is_defined_suffix(res, "-2") && any(grepl("datacite", sources))) {
    crit_pass_suffix(res, "-2", evidence = "DataCite")
  }

  # Some social-science prototype metrics use -3 for the generic
  # "programmatically retrievable metadata" criterion.
  if (crit_is_defined_suffix(res, "-3") && length(ctx$metadata_sources) > 0L) {
    crit_pass_suffix(res, "-3",
                     evidence = unique(vapply(ctx$metadata_sources, function(s)
                       s$method %||% "", character(1))))
  }
  res$output <- list(search_mechanisms = mechs)
}
