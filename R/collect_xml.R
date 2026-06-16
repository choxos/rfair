# XML metadata collectors (DataCite XML, Dublin Core), ported from the
# XML_MAPPING_* tables in metadata_mapper.py and metadata_collector_xml.py.
# Uses xml2 with namespaces stripped, so the fuji "{*}local-name" paths become
# plain XPath.

#' Translate a fuji XML mapping path to namespace-stripped XPath.
#' @noRd
xml_translate <- function(p) {
  p <- gsub("\\{\\*\\}", "", p)   # namespace wildcard -> none (ns stripped)
  p <- gsub("@@", "/@", p)         # attribute marker
  gsub("xlink:", "", p)            # attribute namespace prefix
}

#' Get trimmed text for one or more XPath paths under a node.
#' @noRd
xml_get <- function(node, paths) {
  vals <- character(0)
  for (p in paths) {
    found <- tryCatch(xml2::xml_find_all(node, xml_translate(p)), error = function(e) NULL)
    if (!is.null(found) && length(found)) vals <- c(vals, trimws(xml2::xml_text(found)))
  }
  vals[nzchar(vals)]
}

#' Map a DataCite XML <resource> node to reference-schema keys.
#' @noRd
map_datacite_xml <- function(node) {
  out <- list()
  out$title <- xml_get(node, "./{*}titles/{*}title")[1]
  cr <- xml_get(node, "./{*}creators/{*}creator/{*}creatorName"); if (length(cr)) out$creator <- as.list(cr)
  ct <- xml_get(node, "./{*}contributors/{*}contributor/{*}contributorName"); if (length(ct)) out$contributor <- as.list(ct)
  out$publication_date <- xml_get(node, "./{*}publicationYear")[1]
  kw <- xml_get(node, "./{*}subjects/{*}subject"); if (length(kw)) out$keywords <- as.list(kw)
  out$object_identifier <- xml_get(node, "./{*}identifier")[1]
  pubn <- xml_get(node, "./{*}publisher")[1]; if (!is.na(pubn) && nzchar(pubn %||% "")) out$publisher <- pubn
  out$summary <- xml_get(node, "./{*}descriptions/{*}description")[1]
  out$object_type <- xml_get(node, "./{*}resourceType@@resourceTypeGeneral")[1]
  sz <- xml_get(node, "./{*}sizes/{*}size"); if (length(sz)) out$object_size <- sz[1]
  fmt <- xml_get(node, "./{*}formats/{*}format"); if (length(fmt)) out$object_format <- fmt[1]
  lic <- c(xml_get(node, "./{*}rightsList/{*}rights@@rightsURI"),
           xml_get(node, "./{*}rightsList/{*}rights"))
  if (length(lic)) { out$license <- as.list(unique(lic)); out$access_level <- as.list(unique(lic)) }
  out$language <- xml_get(node, "./{*}language")[1]
  # related identifiers (+ relation type), zipped
  rid <- xml_get(node, "./{*}relatedIdentifiers/{*}relatedIdentifier")
  rtype <- xml_get(node, "./{*}relatedIdentifiers/{*}relatedIdentifier@@relationType")
  if (length(rid)) {
    out$related_resources <- lapply(seq_along(rid), function(i) list(
      related_resource = rid[i], relation_type = if (i <= length(rtype)) rtype[i] else NA_character_))
  }
  compact(out)
}

#' Map a Dublin Core document (any wrapper) to reference-schema keys.
#' @noRd
map_dc_xml <- function(root) {
  g <- function(name) xml_get(root, sprintf(".//{*}%s", name))
  out <- list()
  out$title <- g("title")[1]
  cr <- g("creator"); if (length(cr)) out$creator <- as.list(cr)
  ct <- g("contributor"); if (length(ct)) out$contributor <- as.list(ct)
  kw <- g("subject"); if (length(kw)) out$keywords <- as.list(kw)
  out$summary <- (c(g("description"), g("abstract")))[1]
  out$publisher <- g("publisher")[1]
  out$publication_date <- (c(g("date"), g("issued"), g("available")))[1]
  out$object_identifier <- g("identifier")[1]
  out$object_type <- g("type")[1]
  out$object_format <- g("format")[1]
  out$language <- g("language")[1]
  lic <- g("license"); if (length(lic)) out$license <- as.list(lic)
  acc <- c(g("rights"), g("accessRights")); if (length(acc)) out$access_level <- as.list(acc)
  rel <- c(g("relation"), g("references"), g("source"), g("isPartOf"), g("hasVersion"),
           g("isVersionOf"), g("isReferencedBy"))
  if (length(rel)) out$related_resources <- lapply(rel, function(r) list(related_resource = r))
  compact(out)
}

#' Map a MODS document to reference-schema keys.
#' @noRd
map_mods_xml <- function(root) {
  g <- function(p) xml_get(root, p)
  compact(list(
    title = g(".//{*}titleInfo/{*}title")[1],
    creator = { x <- g(".//{*}name/{*}namePart"); if (length(x)) as.list(x) else NULL },
    publisher = g(".//{*}originInfo/{*}publisher")[1],
    object_identifier = g(".//{*}identifier")[1],
    publication_date = g(".//{*}originInfo/{*}dateCreated")[1],
    keywords = { x <- g(".//{*}subject/{*}topic"); if (length(x)) as.list(x) else NULL },
    summary = g(".//{*}abstract")[1],
    object_type = g(".//{*}typeOfResource")[1],
    language = g(".//{*}language/{*}languageTerm")[1]))
}

#' Map an EML (Ecological Metadata Language) document.
#' @noRd
map_eml_xml <- function(root) {
  g <- function(p) xml_get(root, p)
  compact(list(
    title = g(".//{*}dataset/{*}title")[1],
    object_identifier = (c(g(".//{*}dataset/{*}alternateIdentifier"), xml_get(root, "./@packageId")))[1],
    creator = { x <- g(".//{*}dataset/{*}creator/{*}individualName/{*}surName"); if (length(x)) as.list(x) else NULL },
    publication_date = g(".//{*}dataset/{*}pubDate")[1],
    keywords = { x <- g(".//{*}dataset/{*}keywordSet/{*}keyword"); if (length(x)) as.list(x) else NULL },
    summary = (c(g(".//{*}dataset/{*}abstract/{*}para"), g(".//{*}dataset/{*}abstract")))[1],
    publisher = g(".//{*}dataset/{*}publisher/{*}organizationName")[1],
    measured_variable = { x <- g(".//{*}attributeName"); if (length(x)) as.list(x) else NULL }))
}

#' Map an ISO 19139 (geographic) document (core fields only).
#' @noRd
map_iso_xml <- function(root) {
  g <- function(name) xml_get(root, sprintf(".//{*}%s", name))
  compact(list(
    title = g("title")[1],
    summary = g("abstract")[1],
    keywords = { x <- g("keyword"); if (length(x)) as.list(x) else NULL },
    object_identifier = (c(g("code"), g("fileIdentifier")))[1],
    publication_date = g("date")[1],
    language = g("language")[1]))
}

#' Parse an XML string, detect its schema, map it, and merge.
#' @noRd
collect_xml_doc <- function(ctx, content, url, mimetype = "application/xml") {
  doc <- tryCatch(xml2::read_xml(content), error = function(e) NULL)
  if (is.null(doc)) return(invisible(FALSE))
  xml2::xml_ns_strip(doc)
  resource <- xml2::xml_find_first(doc, "//resource")
  found_node <- function(name) xml2::xml_find_first(doc, sprintf("//*[local-name()='%s']", name))
  has <- function(node) !inherits(node, "xml_missing")
  if (has(resource) && length(xml2::xml_find_all(resource, "./titles"))) {
    md <- map_datacite_xml(resource); src <- "datacite_xml"; schema <- "http://datacite.org/schema/kernel-4"
  } else if (has(found_node("mods"))) {
    md <- map_mods_xml(found_node("mods")); src <- "mods_xml"; schema <- "http://www.loc.gov/mods/v3"
  } else if (has(found_node("eml"))) {
    md <- map_eml_xml(found_node("eml")); src <- "eml_xml"; schema <- "https://eml.ecoinformatics.org"
  } else if (has(found_node("MD_Metadata"))) {
    md <- map_iso_xml(found_node("MD_Metadata")); src <- "iso19139_xml"; schema <- "http://www.isotc211.org/2005/gmd"
  } else if (length(xml2::xml_find_all(doc, ".//*[local-name()='title']")) ||
             length(xml2::xml_find_all(doc, ".//*[local-name()='identifier']"))) {
    md <- map_dc_xml(xml2::xml_root(doc)); src <- "dublincore_xml"; schema <- "http://purl.org/dc/elements/1.1/"
  } else {
    return(invisible(FALSE))
  }
  if (!length(md)) return(invisible(FALSE))
  merge_metadata(ctx, md, url = url, method = src, format = "xml",
                 mimetype = mimetype, schema = schema)
  ctx$metadata_sources[[length(ctx$metadata_sources) + 1L]] <- list(source = src, method = "content_negotiation")
  ctx_log(ctx, "FsF-I1-01M", "info", paste("Harvested", src, "metadata"))
  invisible(TRUE)
}

#' Fetch a URL expected to hold XML metadata and harvest it.
#' @noRd
collect_xml_from_url <- function(ctx, url, timeout = 15) {
  resp <- tryCatch(content_negotiate(url, accept = "xml", timeout = timeout), error = function(e) NULL)
  if (is.null(resp) || !isTRUE(resp$ok) || is.null(resp$content)) return(invisible())
  collect_xml_doc(ctx, resp$content, url = resp$redirect_url, mimetype = resp$content_type)
}

#' Harvest XML metadata via content negotiation (DataCite XML, generic XML).
#' @noRd
collect_xml <- function(ctx, timeout = 15) {
  resp <- tryCatch(content_negotiate(ctx$pid_url, accept = "datacite_xml", timeout = timeout),
                   error = function(e) NULL)
  if (!is.null(resp) && isTRUE(resp$ok) && !is.null(resp$content) &&
      grepl("xml", resp$content_type %||% "", ignore.case = TRUE)) {
    collect_xml_doc(ctx, resp$content, url = resp$redirect_url, mimetype = resp$content_type)
  }
  invisible()
}
