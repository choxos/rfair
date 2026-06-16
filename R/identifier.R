# Persistent-identifier parsing and resolution, ported from
# fuji_server/helper/identifier_helper.py.

# PIDs treated as persistent (identifier_helper.py VALID_PIDS, :19-39).
.VALID_PIDS <- c(
  "ark", "arxiv", "bioproject", "biosample", "doi", "ensembl", "genome", "gnd",
  "handle", "lsid", "pmid", "pmcid", "purl", "refseq", "sra", "uniprot", "urn",
  "identifiers.org", "w3id"
)

# URN resolver hosts (identifier_helper.py URN_RESOLVER, :54-65).
.URN_RESOLVER <- c(
  "urn:doi:"  = "dx.doi.org/",        "urn:lex:br" = "www.lexml.gov.br/",
  "urn:nbn:de" = "nbn-resolving.org/", "urn:nbn:se" = "urn.kb.se/resolve?urn=",
  "urn:nbn:at" = "resolver.obvsg.at/", "urn:nbn:hr" = "urn.nsk.hr/",
  "urn:nbn:no" = "urn.nb.no/",         "urn:nbn:fi" = "urn.fi/",
  "urn:nbn:it" = "nbn.depositolegale.it/", "urn:nbn:nl" = "www.persistent-identifier.nl/"
)

#' Extract the bare DOI (10.x/...) from a string, or NA.
#' @noRd
extract_doi <- function(x) {
  m <- regmatches(x, regexpr("(?i)(?:doi:\\s*|(?:https?://)?(?:dx\\.)?doi\\.org/)?(10\\.\\d+(?:\\.\\d+)*/\\S+)$",
                             x, perl = TRUE))
  if (length(m) == 0L) return(NA_character_)
  sub("(?i)^(?:doi:\\s*|(?:https?://)?(?:dx\\.)?doi\\.org/)?", "", m, perl = TRUE)
}

#' Extract a Handle (prefix/suffix) from a string, or NA.
#' @noRd
extract_handle <- function(x) {
  m <- regmatches(x, regexpr("(?i)(?:hdl:\\s*|(?:https?://)?hdl\\.handle\\.net/)?([0-9]+(?:\\.[0-9]+)*/.+)$",
                             x, perl = TRUE))
  if (length(m) == 0L) return(NA_character_)
  sub("(?i)^(?:hdl:\\s*|(?:https?://)?hdl\\.handle\\.net/)?", "", m, perl = TRUE)
}

#' @noRd
is_uuid_string <- function(x) {
  grepl("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", x, ignore.case = TRUE)
}

#' @noRd
is_hash_string <- function(x) {
  grepl("^[0-9a-f]{32}$|^[0-9a-f]{40}$|^[0-9a-f]{64}$|^[0-9a-f]{128}$", x, ignore.case = TRUE)
}

#' @noRd
is_url_string <- function(x) grepl("^https?://[^\\s/$.?#].[^\\s]*$", x, perl = TRUE)

#' Detect identifier schemes for a string (idutils.detect_identifier_schemes).
#' @return Character vector of schemes (most specific first), possibly empty.
#' @noRd
detect_schemes <- function(x) {
  schemes <- character(0)
  if (!is.na(extract_doi(x)))           schemes <- c(schemes, "doi")
  if (grepl("ark:/", x, fixed = TRUE))  schemes <- c(schemes, "ark")
  if (grepl("^urn:[a-z0-9][a-z0-9-]{0,31}:", x, ignore.case = TRUE)) schemes <- c(schemes, "urn")
  if (grepl("(?i)arxiv", x, perl = TRUE) && grepl("\\d{4}\\.\\d{4,5}", x)) schemes <- c(schemes, "arxiv")
  if (!("doi" %in% schemes) && !is.na(extract_handle(x))) schemes <- c(schemes, "handle")
  if (is_url_string(x)) schemes <- c(schemes, "url")
  unique(schemes)
}

#' Build a resolver URL for an identifier given its scheme (IdentifierHelper.to_url).
#' @noRd
to_url <- function(id, schema, normalized = id) {
  url <- switch(schema,
    doi    = paste0("https://doi.org/", normalized),
    handle = paste0("https://hdl.handle.net/", normalized),
    arxiv  = paste0("https://arxiv.org/abs/", sub("(?i)^arxiv:", "", normalized, perl = TRUE)),
    ark    = if (is_url_string(id)) id else paste0("https://n2t.net/", normalized),
    w3id   = id,
    url    = id,
    NA_character_
  )
  url
}

#' Parse a persistent identifier or URL.
#'
#' Resolves the identifier scheme, normalizes it, and constructs its resolver
#' URL, mirroring `IdentifierHelper` in F-UJI.
#'
#' @param idstring A DOI, Handle, ARK, URN, UUID, identifiers.org PID, or URL.
#' @return A list with `identifier`, `normalized_id`, `identifier_url`,
#'   `preferred_schema`, `identifier_schemes`, and `is_persistent`.
#' @export
#' @examples
#' id_parse("https://doi.org/10.5281/zenodo.8347772")$preferred_schema
id_parse <- function(idstring) {
  empty <- list(identifier = idstring, normalized_id = idstring,
                identifier_url = NA_character_, preferred_schema = NA_character_,
                identifier_schemes = character(0), is_persistent = FALSE)
  if (!is_nonempty_string(idstring)) return(empty)
  id <- trimws(idstring)
  if (nchar(id) <= 4L || grepl("^[0-9]+$", id)) return(empty)

  # workarounds (identifier_helper.py:100-106)
  id <- sub("/purl.archive.org/", "/purl.org/", id, fixed = TRUE)
  if (grepl("https://purl.", id, fixed = TRUE) || grepl("/ark:", id, fixed = TRUE)) {
    id <- sub("https:", "http:", id, fixed = TRUE)
  }
  id <- sub("/ark:", "/ark:/", id, fixed = TRUE)
  id <- sub("/ark://", "/ark:/", id, fixed = TRUE)

  schemes <- character(0); preferred <- NA_character_
  normalized <- NA_character_; id_url <- NA_character_; persistent <- FALSE

  if (is_uuid_string(id)) { schemes <- "uuid"; preferred <- "uuid" }
  else if (is_hash_string(id)) { schemes <- "hash"; preferred <- "hash" }

  if (length(schemes) == 0L || identical(schemes, "url")) {
    parts <- tryCatch(httr2::url_parse(id), error = function(e) NULL)
    netloc <- if (!is.null(parts)) parts$hostname %||% "" else ""
    # w3id
    if (!is.null(parts) && identical(parts$scheme, "https") &&
        netloc %in% c("w3id.org", "www.w3id.org") && nzchar(parts$path %||% "")) {
      schemes <- c("w3id", "url"); preferred <- "w3id"
      id_url <- id; normalized <- id
    } else {
      # identifiers.org -> reformat to prefix:accession
      if (identical(netloc, "identifiers.org")) {
        seg <- strsplit(sub("^/", "", parts$path %||% ""), "/", fixed = TRUE)[[1]]
        if (length(seg) == 2L) id <- paste0(seg[1], ":", seg[2])
      }
      m <- regmatches(id, regexpr("^([a-z0-9._]+):(.+)", id, perl = TRUE))
      if (length(m) == 1L) {
        prefix <- sub("^([a-z0-9._]+):(.+)", "\\1", m, perl = TRUE)
        suffix <- sub("^([a-z0-9._]+):(.+)", "\\2", m, perl = TRUE)
        idorg <- ref_data("identifiers_org")
        if (prefix != "doi" && !is.null(idorg[[prefix]])) {
          patt <- idorg[[prefix]]$pattern
          if (is_nonempty_string(patt) && grepl(patt, suffix, perl = TRUE)) {
            schemes <- c("identifiers.org", prefix); preferred <- prefix
            id_url <- paste0("https://identifiers.org/", id)
            normalized <- paste0(tolower(prefix), ":", suffix)
          }
        }
      }
    }
  }

  if (length(schemes) == 0L) {
    schemes <- detect_schemes(id)
  }

  if (length(schemes) > 0L) {
    # move "url" to the end so a more specific scheme is preferred
    if (length(schemes) > 1L && "url" %in% schemes) {
      schemes <- c(setdiff(schemes, "url"), "url")
    }
    if (is.na(preferred)) preferred <- schemes[1]
    if (is.na(normalized)) {
      normalized <- switch(preferred,
        doi    = extract_doi(id) %||% id,
        handle = extract_handle(id) %||% id,
        id)
      if (is.na(normalized)) normalized <- id
    }
    if (is.na(id_url)) id_url <- to_url(id, preferred, normalized)
  }

  if (!is.na(preferred) &&
      (preferred %in% .VALID_PIDS || !is.null(ref_data("identifiers_org")[[preferred]]))) {
    persistent <- TRUE
  }
  if (is.na(normalized)) normalized <- id

  list(
    identifier = id,
    normalized_id = normalized,
    identifier_url = id_url %||% NA_character_,
    preferred_schema = preferred,
    identifier_schemes = schemes,
    is_persistent = persistent
  )
}
