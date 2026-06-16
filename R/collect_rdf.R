# RDF metadata collectors.
#
# Content-negotiated JSON-LD is parsed natively (no system dependencies) and run
# through the schema.org mapper. Turtle / RDF-XML need an RDF graph parser; that
# path is gated behind the optional `rdflib` package (which needs the system
# `librdf`) and degrades gracefully when it is unavailable.

# SPARQL that pulls reference fields from an arbitrary RDF graph
# (Mapper.GENERIC_SPARQL, metadata_mapper.py:302).
.GENERIC_SPARQL <- "
PREFIX dct: <http://purl.org/dc/terms/>
PREFIX dc: <http://purl.org/dc/elements/1.1/>
PREFIX sdo: <http://schema.org/>
SELECT ?object_identifier ?title ?summary ?publisher ?publication_date ?creator ?object_type ?license ?access_level ?keywords WHERE {
  OPTIONAL {?s dct:title|dc:title|sdo:name ?title}
  OPTIONAL {?s dct:identifier|dc:identifier|sdo:identifier ?object_identifier}
  OPTIONAL {?s dct:description|dc:description|sdo:abstract ?summary}
  OPTIONAL {?s dct:publisher|dc:publisher|sdo:publisher ?publisher}
  OPTIONAL {?s dct:created|dct:issued|dct:date|sdo:datePublished ?publication_date}
  OPTIONAL {?s dct:creator|dc:creator|sdo:author ?creator}
  OPTIONAL {?s dct:type|dc:type ?object_type}
  OPTIONAL {?s dct:license|dc:license|sdo:license ?license}
  OPTIONAL {?s dct:accessRights|dct:rights|dc:rights ?access_level}
  OPTIONAL {?s dct:subject|dc:subject|sdo:keywords ?keywords}
} LIMIT 5"

#' Harvest content-negotiated JSON-LD (native) into the metadata record.
#' @noRd
collect_rdf_from_url <- function(ctx, url, jsonld = TRUE, timeout = 15) {
  accept <- if (jsonld) "jsonld" else "rdf"
  resp <- tryCatch(content_negotiate(url, accept = accept, timeout = timeout), error = function(e) NULL)
  if (is.null(resp) || !isTRUE(resp$ok) || is.null(resp$content)) return(invisible())
  ct <- tolower(resp$content_type %||% "")

  if (grepl("json", ct)) {
    j <- tryCatch(jsonlite::fromJSON(resp$content, simplifyVector = FALSE), error = function(e) NULL)
    if (is.null(j)) return(invisible())
    nodes <- if (!is.null(names(j))) list(j) else j
    for (node in nodes) {
      md <- map_schemaorg(node)
      if (length(md)) {
        merge_metadata(ctx, md, url = resp$redirect_url, method = "schema_org",
                       format = "jsonld", mimetype = resp$content_type, schema = "http://schema.org")
        ctx$metadata_sources[[length(ctx$metadata_sources) + 1L]] <-
          list(source = "schema.org", method = "content_negotiation")
      }
    }
  } else if (grepl("turtle|rdf|n-triples|n3", ct)) {
    collect_rdf_graph(ctx, resp$content, ct, resp$redirect_url)
  }
  invisible()
}

#' Parse an RDF graph (Turtle/RDF-XML) via rdflib and map it (optional).
#' @noRd
collect_rdf_graph <- function(ctx, content, content_type, url) {
  if (!requireNamespace("rdflib", quietly = TRUE)) {
    ctx_log(ctx, "FsF-I1-01M", "info",
            "RDF graph metadata found but the optional 'rdflib' package is not installed; skipping.")
    return(invisible(FALSE))
  }
  fmt <- if (grepl("turtle|n3", content_type)) "turtle"
         else if (grepl("n-triples", content_type)) "ntriples"
         else "rdfxml"
  res <- tryCatch({
    rdf <- rdflib::rdf_parse(content, format = fmt, rdf = rdflib::rdf())
    rdflib::rdf_query(rdf, .GENERIC_SPARQL)
  }, error = function(e) NULL)
  if (is.null(res) || !nrow(res)) return(invisible(FALSE))
  row <- as.list(res[1, , drop = FALSE])
  md <- compact(lapply(row, function(v) if (length(v) && !is.na(v)) as.character(v) else NULL))
  if (length(md)) {
    merge_metadata(ctx, md, url = url, method = "rdf", format = "rdf",
                   mimetype = content_type, schema = "")
    ctx$metadata_sources[[length(ctx$metadata_sources) + 1L]] <-
      list(source = "rdf", method = "content_negotiation")
  }
  invisible(TRUE)
}

#' Harvest RDF (JSON-LD now, Turtle/RDF-XML if rdflib is available).
#' @noRd
collect_rdf <- function(ctx, timeout = 15) {
  collect_rdf_from_url(ctx, ctx$pid_url, jsonld = TRUE, timeout = timeout)
  if (requireNamespace("rdflib", quietly = TRUE)) {
    collect_rdf_from_url(ctx, ctx$pid_url, jsonld = FALSE, timeout = timeout)
  }
  invisible()
}
