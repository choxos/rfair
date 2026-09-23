# Landing-page HTML metadata collectors: embedded schema.org JSON-LD, microdata,
# and RDFa, and Dublin Core / OpenGraph / Highwire meta tags. Ported from the
# corresponding metadata_collector_*.py modules. Uses rvest/xml2.

# Dublin Core element -> reference key (reverse of Mapper.DC_MAPPING).
.DC_MAP <- list(
  identifier = "object_identifier", creator = "creator", title = "title",
  contributor = "contributor", publisher = "publisher",
  date = "publication_date", available = "publication_date", issued = "publication_date",
  abstract = "summary", description = "summary", subject = "keywords",
  type = "object_type", license = "license", rights = "access_level",
  accessrights = "access_level", language = "language", format = "object_format",
  relation = "related_resources", source = "related_resources"
)

# OpenGraph property -> reference key (Mapper.OG_MAPPING).
.OG_MAP <- list(
  "og:title" = "title", "og:url" = "object_identifier", "og:description" = "summary",
  "og:type" = "object_type", "og:site_name" = "publisher", "og:locale" = "language"
)

# Highwire/citation meta -> reference key (Mapper.HIGHWIRE_MAPPING, subset).
.HW_MAP <- list(
  citation_title = "title", citation_author = "creator", citation_authors = "creator",
  citation_publisher = "publisher", citation_date = "publication_date",
  citation_publication_date = "publication_date", citation_doi = "object_identifier",
  citation_keywords = "keywords", citation_language = "language"
)

#' Collect all meta tags into a named list: key (lowercased) -> character vector.
#' @noRd
extract_meta_tags <- function(doc) {
  metas <- rvest::html_elements(doc, "meta")
  if (length(metas) == 0L) return(list())
  name <- rvest::html_attr(metas, "name")
  prop <- rvest::html_attr(metas, "property")
  content <- rvest::html_attr(metas, "content")
  key <- ifelse(!is.na(name), name, prop)
  keep <- !is.na(key) & !is.na(content)
  key <- tolower(key[keep]); content <- content[keep]
  out <- list()
  for (i in seq_along(key)) out[[key[i]]] <- c(out[[key[i]]], content[i])
  out
}

#' Map meta tags through a prefix/name mapping into reference-schema keys.
#' @noRd
map_meta <- function(meta, mapping, strip_prefix = NULL) {
  out <- list()
  for (raw_key in names(meta)) {
    k <- raw_key
    if (!is.null(strip_prefix)) {
      if (!startsWith(k, strip_prefix)) next
      k <- sub(strip_prefix, "", k, fixed = TRUE)
    }
    ref <- mapping[[k]]
    if (is.null(ref)) next
    vals <- as_chr(meta[[raw_key]])
    if (!length(vals)) next
    out[[ref]] <- c(out[[ref]], if (length(vals) == 1L) vals else as.list(vals))
  }
  compact(out)
}

#' Map a parsed schema.org JSON-LD object to reference-schema keys.
#' @noRd
map_schemaorg <- function(j) {
  if (!is.list(j)) return(list())
  if (!is.null(j[["@graph"]]) && is.list(j[["@graph"]])) {
    # pick the first graph node that looks like a CreativeWork/Dataset
    nodes <- j[["@graph"]]
    pick <- Filter(function(n) is.list(n) && !is.null(n[["@type"]]), nodes)
    if (length(pick)) j <- pick[[1]]
  }
  name_of <- function(v) {
    if (is.character(v)) return(v)
    if (is.list(v)) return(as_chr(jmap(list(v), "name")) %||% as_chr(v$name))
    NULL
  }
  out <- list()
  out$title <- j$name %||% j$headline
  out$object_type <- j[["@type"]]
  out$publication_date <- j$datePublished %||% j$dateCreated
  out$modified_date <- j$dateModified
  cr <- j$creator %||% j$author
  if (!is.null(cr)) {
    creators <- if (is.list(cr) && is.null(names(cr))) unlist(lapply(cr, name_of)) else name_of(cr)
    if (length(creators)) out$creator <- as.list(as_chr(creators))
  }
  pub <- j$publisher %||% j$provider
  if (!is.null(pub)) out$publisher <- name_of(pub)
  lic <- j$license
  if (is.list(lic)) lic <- lic[["@id"]] %||% lic$url %||% lic$name
  if (!is.null(lic)) out$license <- as_chr(lic)
  out$summary <- j$description %||% j$abstract
  kw <- j$keywords
  if (!is.null(kw)) out$keywords <- if (is.list(kw)) as.list(as_chr(kw)) else kw
  free <- j$isAccessibleForFree
  if (length(free) == 1L) {
    out$access_free <- isTRUE(free) || tolower(as.character(free)) %in% c("true", "free")
  }
  oid <- j$identifier %||% j$url
  if (is.list(oid)) oid <- oid$value %||% oid[["@id"]]
  if (!is.null(oid)) out$object_identifier <- as_chr(oid)[1]

  # data content links: schema.org distribution[].contentUrl or contentUrl
  dist <- j$distribution %||% j$contentUrl
  if (!is.null(dist)) {
    ditems <- if (is.list(dist) && is.null(names(dist))) dist else list(dist)
    links <- list()
    for (d in ditems) {
      u <- if (is.list(d)) (d$contentUrl %||% d$url) else d
      if (is_nonempty_string(u)) {
        links[[length(links) + 1L]] <- list(
          url = u, type = if (is.list(d)) d$encodingFormat %||% d$fileFormat else NULL)
      }
    }
    if (length(links)) out$object_content_identifier <- links
  }
  compact(out)
}

#' Value of a microdata or RDFa property element (HTML microdata algorithm:
#' attribute by tag, else the text).
#' @noRd
html_property_value <- function(n, rdfa = FALSE) {
  tag <- xml2::xml_name(n)
  attrs <- if (rdfa) c("content", "href", "src", "resource") else switch(tag,
    meta = "content", audio = , embed = , iframe = , img = , source = , track = , video = "src",
    a = , area = , link = "href", object = "data", data = , meter = "value", time = "datetime",
    character(0))
  for (a in attrs) {
    v <- xml2::xml_attr(n, a)
    if (!is.na(v) && nzchar(v)) return(v)
  }
  trimws(gsub("\\s+", " ", xml2::xml_text(n)))
}

#' One microdata item (itemscope) or RDFa resource (typeof) as a JSON-LD-like
#' list, recursing into nested items.
#' @noRd
html_item <- function(scope, rdfa = FALSE) {
  scope_attr <- if (rdfa) "typeof" else "itemscope"
  prop_attr <- if (rdfa) "property" else "itemprop"
  type <- xml2::xml_attr(scope, if (rdfa) "typeof" else "itemtype")
  out <- list(`@type` = sub("^.*[/#:]", "", type %||% ""))
  path <- xml2::xml_path(scope)
  for (p in xml2::xml_find_all(scope, sprintf(".//*[@%s]", prop_attr))) {
    owner <- xml2::xml_find_first(p, sprintf("ancestor::*[@%s][1]", scope_attr))
    if (!identical(xml2::xml_path(owner), path)) next
    val <- if (!is.na(xml2::xml_attr(p, scope_attr))) html_item(p, rdfa) else html_property_value(p, rdfa)
    for (name in strsplit(xml2::xml_attr(p, prop_attr), "\\s+")[[1]]) {
      name <- sub("^.*[/#:]", "", name)
      out[[name]] <- c(out[[name]], list(val))
    }
  }
  lapply(out, function(v) if (is.list(v) && is.null(names(v)) && length(v) == 1L) v[[1]] else v)
}

#' schema.org items embedded as microdata or RDFa.
#' @noRd
extract_html_items <- function(doc, rdfa = FALSE) {
  xpath <- if (rdfa) "//*[@typeof and not(@property)]" else "//*[@itemscope and not(@itemprop)]"
  scopes <- xml2::xml_find_all(doc, xpath)
  items <- lapply(scopes, html_item, rdfa = rdfa)
  # keep schema.org items; RDFa schema.org pages declare vocab or a schema: prefix
  Filter(function(it) nzchar(it[["@type"]] %||% "") && length(it) > 1L, items[vapply(scopes, function(s) {
    type <- xml2::xml_attr(s, if (rdfa) "typeof" else "itemtype") %||% ""
    vocab <- xml2::xml_attr(xml2::xml_find_first(s, "ancestor-or-self::*[@vocab][1]"), "vocab")
    grepl("schema\\.org", type) || grepl("^schema:", type) ||
      (!is.na(vocab) && grepl("schema\\.org", vocab))
  }, logical(1))])
}

#' Parse landing HTML and merge schema.org + Dublin Core + OpenGraph + Highwire.
#' @noRd
collect_html_meta <- function(ctx) {
  doc <- tryCatch(xml2::read_html(ctx$landing_html), error = function(e) NULL)
  if (is.null(doc)) return(invisible())
  origin_url <- ctx$landing_url %||% NA_character_

  # embedded JSON-LD (schema.org) -- highest priority
  scripts <- rvest::html_elements(doc, xpath = "//script[@type='application/ld+json']")
  for (s in scripts) {
    txt <- rvest::html_text(s)
    j <- tryCatch(jsonlite::fromJSON(txt, simplifyVector = FALSE), error = function(e) NULL)
    if (is.null(j)) next
    note_linked_uris(ctx, txt)
    docs <- if (!is.null(names(j))) list(j) else j  # array of objects or single
    for (node in docs) {
      md <- map_schemaorg(node)
      if (length(md)) {
        merge_metadata(ctx, md, url = origin_url, method = "schema_org",
                       format = "jsonld", mimetype = "application/ld+json",
                       schema = "http://schema.org")
        ctx$metadata_sources[[length(ctx$metadata_sources) + 1L]] <-
          list(source = "schema.org", method = "embedded")
      }
    }
  }

  # schema.org as microdata and RDFa (F-UJI reads both through extruct)
  for (kind in c("microdata", "rdfa")) {
    for (item in extract_html_items(doc, rdfa = identical(kind, "rdfa"))) {
      md <- map_schemaorg(item)
      if (length(md)) {
        merge_metadata(ctx, md, url = origin_url, method = kind, format = kind,
                       mimetype = "text/html", schema = "http://schema.org")
        ctx$metadata_sources[[length(ctx$metadata_sources) + 1L]] <-
          list(source = kind, method = "embedded")
      }
    }
  }

  meta <- extract_meta_tags(doc)
  if (length(meta)) {
    dc <- map_meta(meta, .DC_MAP, strip_prefix = "dc.")
    dct <- map_meta(meta, .DC_MAP, strip_prefix = "dcterms.")
    og <- map_meta(meta, .OG_MAP)
    hw <- map_meta(meta, .HW_MAP)
    for (rec in list(list(dc, "dublincore"), list(dct, "dublincore"),
                     list(og, "opengraph"), list(hw, "highwire"))) {
      md <- rec[[1]]
      if (length(md)) {
        merge_metadata(ctx, md, url = origin_url, method = rec[[2]],
                       format = "meta_tag", mimetype = "text/html", schema = "")
        ctx$metadata_sources[[length(ctx$metadata_sources) + 1L]] <-
          list(source = rec[[2]], method = "meta_tags")
      }
    }
  }
  invisible()
}
