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

#' Harvest a user-supplied metadata service endpoint or metadata document.
#'
#' The user passes `metadata_service_endpoint` (a URL that returns a metadata
#' document, or a ready protocol query URL such as an OAI-PMH `GetRecord` URL)
#' and a `metadata_service_type` hint. The response is harvested with the same
#' format-gated collectors used for content negotiation: schema.org JSON-LD via
#' the RDF/JSON-LD path, everything else as an XML/metadata document first, then
#' RDF as a fallback. Format detection (recognized schema/root in `collect_xml`,
#' valid RDF in `collect_rdf`) prevents arbitrary 200 responses from scoring.
#' @noRd
collect_metadata_service <- function(ctx, timeout = 15) {
  url <- ctx$metadata_service_endpoint
  if (!is_nonempty_string(url)) return(invisible())
  type <- ctx$metadata_service_type %||% "other"
  before <- length(ctx$metadata_sources)

  if (identical(type, "schema_org")) {
    collect_rdf_from_url(ctx, url, jsonld = TRUE, timeout = timeout)
  } else {
    collect_xml_from_url(ctx, url, timeout = timeout)
    if (length(ctx$metadata_sources) == before) {
      collect_rdf_from_url(ctx, url, jsonld = TRUE, timeout = timeout)
    }
  }

  if (length(ctx$metadata_sources) > before) {
    ctx$metadata_merged$metadata_service <- url
    ctx_log(ctx, "FsF-F2-01M", "info",
            sprintf("Harvested metadata service (%s): %s", type, url))
  } else {
    ctx_log(ctx, "FsF-F2-01M", "warning",
            sprintf("Metadata service endpoint returned no usable metadata (%s): %s", type, url))
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
  # isolate each collector: a malformed response from one source must not abort
  # the whole harvest (later collectors only fill gaps, so a skipped source just
  # means fewer signals, not a failed assessment).
  run <- function(label, expr) {
    tryCatch(expr, error = function(e)
      ctx_log(ctx, "FsF-F2-01M", "warning",
              sprintf("collector '%s' failed: %s", label, conditionMessage(e))))
  }
  # embedded (landing page) first, then typed links / signposting, then
  # content-negotiated structured formats (DataCite JSON/XML, RDF/JSON-LD).
  if (is_nonempty_string(ctx$landing_html)) {
    run("html", collect_html_meta(ctx))
    run("signposting", collect_signposting(ctx))
  }
  run("metadata_service", collect_metadata_service(ctx, timeout = timeout))
  run("datacite", collect_datacite(ctx, timeout = timeout))
  run("xml", collect_xml(ctx, timeout = timeout))
  run("rdf", collect_rdf(ctx, timeout = timeout))
  run("github", collect_github(ctx, timeout = timeout))
  run("data", harvest_data(ctx, timeout = timeout))
  invisible()
}
