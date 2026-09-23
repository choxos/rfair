# RDF metadata collectors.
#
# Content-negotiated JSON-LD is parsed natively (no system dependencies) and run
# through the schema.org mapper. Turtle / RDF-XML need an RDF graph parser; that
# path is gated behind the optional `rdflib` package (which needs the system
# `librdf`) and degrades gracefully when it is unavailable.

# RDF predicates mapped to reference fields (Mapper.GENERIC_SPARQL,
# metadata_mapper.py:302). Mapped in R from a plain triple dump rather than with
# SPARQL 1.1 property paths, which librdf's query engine rejects.
.RDF_FIELDS <- local({
  dct <- c(title = "title", identifier = "object_identifier", description = "summary",
           abstract = "summary", publisher = "publisher", created = "publication_date",
           issued = "publication_date", date = "publication_date", creator = "creator",
           type = "object_type", license = "license", accessRights = "access_level",
           rights = "access_level", subject = "keywords")
  dc <- dct[c("title", "identifier", "description", "publisher", "date", "creator",
              "type", "rights", "subject")]
  sdo <- c(name = "title", identifier = "object_identifier", abstract = "summary",
           description = "summary", publisher = "publisher", datePublished = "publication_date",
           author = "creator", creator = "creator", license = "license", keywords = "keywords")
  c(stats::setNames(dct, paste0("http://purl.org/dc/terms/", names(dct))),
    stats::setNames(dc, paste0("http://purl.org/dc/elements/1.1/", names(dc))),
    stats::setNames(sdo, paste0("http://schema.org/", names(sdo))),
    stats::setNames(sdo, paste0("https://schema.org/", names(sdo))))
})

# Predicates giving a human-readable name for a node (e.g. a creator).
.RDF_NAME_PREDICATES <- c("http://xmlns.com/foaf/0.1/name", "http://schema.org/name",
                          "https://schema.org/name", "http://www.w3.org/2006/vcard/ns#fn",
                          "http://www.w3.org/2000/01/rdf-schema#label")

#' Map a triple table (s, p, o) to reference-schema keys.
#'
#' The main subject is the one carrying the most mapped predicates; node
#' objects (for example creator URIs) are replaced by their name when the graph
#' gives one.
#' @noRd
map_rdf_triples <- function(triples) {
  field <- unname(.RDF_FIELDS[triples$p])
  mapped <- triples[!is.na(field), , drop = FALSE]
  if (!nrow(mapped)) return(list())
  mapped$field <- field[!is.na(field)]
  main <- names(sort(table(mapped$s), decreasing = TRUE))[1]
  mapped <- mapped[mapped$s == main, , drop = FALSE]
  names_tbl <- triples[triples$p %in% .RDF_NAME_PREDICATES, , drop = FALSE]
  md <- list()
  for (f in unique(mapped$field)) {
    vals <- unique(mapped$o[mapped$field == f])
    named <- names_tbl$o[match(vals, names_tbl$s)]
    vals <- ifelse(is.na(named), vals, named)
    md[[f]] <- if (f %in% c("creator", "keywords", "license", "access_level")) as.list(vals) else vals[1]
  }
  compact(md)
}

#' Namespaces of the predicates used in a triple table.
#' @noRd
rdf_namespaces <- function(triples) {
  unique(sub("[^/#]*$", "", triples$p))
}

#' Harvest content-negotiated JSON-LD (native) into the metadata record.
#' @noRd
collect_rdf_from_url <- function(ctx, url, jsonld = TRUE, timeout = 15) {
  accept <- if (jsonld) "jsonld" else "rdf"
  resp <- tryCatch(content_negotiate(url, accept = accept, timeout = timeout, ctx = ctx), error = function(e) NULL)
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
  triples <- tryCatch({
    rdf <- rdflib::rdf_parse(content, format = fmt, rdf = rdflib::rdf())
    rdflib::rdf_query(rdf, "SELECT ?s ?p ?o WHERE { ?s ?p ?o }")
  }, error = function(e) NULL)
  if (is.null(triples) || !nrow(triples)) return(invisible(FALSE))
  triples <- as.data.frame(lapply(triples, as.character), stringsAsFactors = FALSE)
  md <- map_rdf_triples(triples)
  if (!length(md)) return(invisible(FALSE))
  merge_metadata(ctx, md, url = url, method = "rdf", format = "rdf",
                 mimetype = content_type, schema = "", namespaces = rdf_namespaces(triples))
  ctx$metadata_sources[[length(ctx$metadata_sources) + 1L]] <-
    list(source = "rdf", method = "content_negotiation")
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
