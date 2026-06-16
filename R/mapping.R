# Native-R metadata mapping helpers, replacing the JMESPath expressions in
# fuji_server/helper/metadata_mapper.py. Each `map_*` function turns a parsed
# source document into reference-schema keys.

#' Walk nested list keys; return NULL if any level is missing.
#' @noRd
jget <- function(x, ...) {
  for (k in c(...)) {
    if (is.list(x) && !is.null(x[[k]])) x <- x[[k]] else return(NULL)
  }
  x
}

#' Extract `key` from each element of a list-of-lists (drop NULLs).
#' @noRd
jmap <- function(lst, key) {
  if (is.null(lst) || !is.list(lst)) return(NULL)
  vals <- lapply(lst, function(e) if (is.list(e)) e[[key]] else NULL)
  vals <- vals[!vapply(vals, is.null, logical(1))]
  if (length(vals) == 0L) NULL else vals
}

#' Keep list elements where `e[[key]] == value`.
#' @noRd
jfilter <- function(lst, key, value) {
  if (is.null(lst) || !is.list(lst)) return(NULL)
  Filter(function(e) is.list(e) && identical(e[[key]], value), lst)
}

#' Drop NULL/empty entries from a mapped list.
#' @noRd
compact <- function(x) x[!vapply(x, function(v) is.null(v) || length(v) == 0L, logical(1))]

#' Map a content-negotiated DataCite JSON document to reference-schema keys.
#'
#' Replicates `Mapper.DATACITE_JSON_MAPPING` (metadata_mapper.py:253-275).
#' @noRd
map_datacite <- function(j) {
  if (!is.list(j)) return(list())
  out <- list()

  out$object_identifier <- j$id %||% j$doi
  out$object_type <- jget(j, "types", "resourceTypeGeneral")

  cr <- as_chr(jmap(j$creators, "name"))
  if (length(cr)) out$creator <- as.list(cr)

  titles <- j$titles
  if (!is.null(titles) && length(titles)) out$title <- titles[[1]]$title

  pub <- j$publisher
  if (is.list(pub)) out$publisher <- pub$name %||% pub$publisherIdentifier
  else if (is.character(pub)) out$publisher <- pub

  kw <- as_chr(jmap(j$subjects, "subject"))
  if (length(kw)) out$keywords <- as.list(kw)

  avail <- as_chr(jmap(jfilter(j$dates, "dateType", "Available"), "date"))
  out$publication_date <- if (length(avail)) avail[1] else
    if (!is.null(j$publicationYear)) as.character(j$publicationYear) else NULL

  lic <- as_chr(jmap(j$rightsList, "rightsUri"))
  if (!length(lic)) lic <- as_chr(jmap(j$rightsList, "rights"))
  if (length(lic)) { out$license <- as.list(lic); out$access_level <- as.list(lic) }

  ab <- as_chr(jmap(jfilter(j$descriptions, "descriptionType", "Abstract"), "description"))
  if (!length(ab) && !is.null(j$descriptions) && length(j$descriptions)) {
    ab <- as_chr(j$descriptions[[1]]$description)
  }
  if (length(ab)) out$summary <- ab[1]

  rel <- lapply(j$relatedIdentifiers %||% list(), function(r) {
    list(related_resource = r$relatedIdentifier, relation_type = r$relationType,
         scheme_uri = r$schemeUri)
  })
  rel <- Filter(function(r) is_nonempty_string(r$related_resource), rel)
  if (length(rel)) out$related_resources <- rel

  out$datacite_client <- j$clientId
  md <- as_chr(jmap(jfilter(j$dates, "dateType", "Updated"), "date"))
  if (length(md)) out$modified_date <- md[1]
  cd <- as_chr(jmap(jfilter(j$dates, "dateType", "Created"), "date"))
  if (length(cd)) out$created_date <- cd[1]

  if (!is.null(j$sizes) && length(j$sizes)) out$object_size <- j$sizes[[1]]
  if (!is.null(j$formats) && length(j$formats)) out$object_format <- j$formats[[1]]
  out$language <- j$language

  compact(out)
}
