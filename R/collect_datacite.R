# DataCite metadata collector and the harvesting orchestrator.

#' Harvest DataCite metadata via content negotiation and merge it.
#' @noRd
collect_datacite <- function(ctx, timeout = 15) {
  if (!isTRUE(ctx$use_datacite)) return(invisible())
  pid_url <- ctx$pid_url
  if (!is_nonempty_string(pid_url)) return(invisible())

  resp <- tryCatch(content_negotiate(pid_url, accept = "datacite_json", timeout = timeout),
                   error = function(e) NULL)
  if (is.null(resp) || !isTRUE(resp$ok) || is.null(resp$content)) return(invisible())
  # content negotiation can fall back to HTML; only accept DataCite JSON
  if (!grepl("datacite|json", resp$content_type %||% "", ignore.case = TRUE)) return(invisible())

  j <- tryCatch(jsonlite::fromJSON(resp$content, simplifyVector = FALSE),
                error = function(e) NULL)
  if (is.null(j)) return(invisible())

  md <- map_datacite(j)
  if (length(md)) {
    merge_metadata(ctx, md, url = resp$redirect_url, method = "datacite",
                   format = "datacite_json", mimetype = resp$content_type,
                   schema = "http://datacite.org/schema/kernel-4")
    ctx$metadata_sources[[length(ctx$metadata_sources) + 1L]] <-
      list(source = "DataCite", method = "content_negotiation")
    ctx_log(ctx, "FsF-F2-01M", "info",
            paste("Found DataCite metadata via content negotiation:",
                  paste(names(md), collapse = ", ")))
  }
  invisible()
}

#' Run all metadata collectors over the engine state.
#'
#' Collectors run in F-UJI's priority order; later collectors only fill gaps via
#' `merge_metadata()`. Wires DataCite, landing-page HTML, signposting, XML, RDF,
#' GitHub, and the data-file probe.
#' @noRd
harvest_all_metadata <- function(ctx, timeout = 15) {
  # embedded (landing page) first, then typed links / signposting, then
  # content-negotiated structured formats (DataCite JSON/XML, RDF/JSON-LD).
  if (is_nonempty_string(ctx$landing_html)) {
    collect_html_meta(ctx)
    collect_signposting(ctx)
  }
  collect_datacite(ctx, timeout = timeout)
  collect_xml(ctx, timeout = timeout)
  collect_rdf(ctx, timeout = timeout)
  collect_github(ctx, timeout = timeout)
  harvest_data(ctx, timeout = timeout)
  invisible()
}
