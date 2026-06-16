# Signposting and typed-link harvesting, ported from
# fuji_server/helper/signposting_helper.py. Reads typed links from the landing
# page's HTTP `Link` header and `<head><link>` elements, and uses them to find
# data content, citation PIDs, licenses, and further metadata documents.

SIGNPOSTING_RELS <- c("describedby", "item", "license", "type", "collection",
                      "author", "linkset", "cite-as", "api-catalog",
                      "service-doc", "service-desc", "service-meta")

# rels accepted as typed content links (signposting_helper.set_typed_content_links)
.TYPED_LINK_RELS <- c("meta", "alternate meta", "metadata", "collection", "author",
                      "describes", "item", "type", "search", "alternate",
                      "describedby", "cite-as", "linkset", "license", "api-catalog")

#' Parse an HTTP `Link` header into typed-link records.
#' @noRd
parse_link_header <- function(link_str) {
  if (!is_nonempty_string(link_str)) return(list())
  out <- list()
  for (part in strsplit(link_str, ",", fixed = TRUE)[[1]]) {
    seg <- trimws(strsplit(part, ";", fixed = TRUE)[[1]])
    url <- sub("^<(.*)>$", "\\1", seg[1])
    if (!nzchar(url)) next
    getp <- function(name) {
      m <- regmatches(seg, regexpr(sprintf('%s\\s*=\\s*"?([^,;"]+)"?', name), seg, perl = TRUE))
      if (length(m)) sub(sprintf('.*%s\\s*=\\s*"?([^,;"]+)"?.*', name), "\\1", m[1], perl = TRUE) else NA_character_
    }
    rel <- getp("rel")
    if (is.na(rel) || !(rel %in% SIGNPOSTING_RELS)) next
    out[[length(out) + 1L]] <- list(url = url, rel = rel, type = getp("type"),
                                    profile = getp("profile"), origin = "header")
  }
  out
}

#' Extract typed `<link>` elements from landing-page HTML.
#' @noRd
extract_typed_links <- function(html, base_url) {
  doc <- tryCatch(xml2::read_html(html), error = function(e) NULL)
  if (is.null(doc)) return(list())
  links <- xml2::xml_find_all(doc, "/*/head/link")
  out <- list()
  for (lk in links) {
    rel <- xml2::xml_attr(lk, "rel"); href <- xml2::xml_attr(lk, "href")
    if (is.na(rel) || is.na(href) || !(rel %in% .TYPED_LINK_RELS)) next
    href <- tryCatch(xml2::url_absolute(href, base_url), error = function(e) href)
    out[[length(out) + 1L]] <- list(url = href, rel = rel,
                                    type = xml2::xml_attr(lk, "type"),
                                    profile = xml2::xml_attr(lk, "profile"),
                                    origin = "content")
  }
  out
}

#' Harvest signposting / typed links and feed them into the metadata record.
#' @noRd
collect_signposting <- function(ctx) {
  link_hdr <- if (!is.null(ctx$landing_headers)) ctx$landing_headers[["Link"]] %||%
    ctx$landing_headers[["link"]] else NULL
  links <- c(parse_link_header(link_hdr),
             if (is_nonempty_string(ctx$landing_html))
               extract_typed_links(ctx$landing_html, ctx$landing_url %||% ctx$pid_url) else list())
  if (!length(links)) return(invisible())
  ctx$typed_links <- c(ctx$typed_links, links)

  md <- list()
  data_links <- list()
  for (lk in links) {
    if (!is_nonempty_string(lk$url)) next
    if (lk$rel %in% c("item")) {
      data_links[[length(data_links) + 1L]] <- list(url = lk$url, type = lk$type)
    } else if (lk$rel == "cite-as") {
      md$object_identifier <- md$object_identifier %||% lk$url
    } else if (lk$rel == "license") {
      md$license <- c(md$license, lk$url)
    }
  }
  if (length(data_links)) md$object_content_identifier <- data_links
  if (length(md)) {
    merge_metadata(ctx, md, url = ctx$landing_url, method = "signposting",
                   format = "typed_links", mimetype = "text/html", schema = "")
    ctx$metadata_sources[[length(ctx$metadata_sources) + 1L]] <-
      list(source = "signposting", method = "typed_links")
  }

  # follow describedby links that point to XML/RDF metadata documents
  described <- Filter(function(l) l$rel %in% c("describedby", "metadata", "meta", "alternate meta"), links)
  for (lk in described) {
    ct <- tolower(lk$type %||% "")
    if (grepl("xml", ct)) collect_xml_from_url(ctx, lk$url)
    else if (grepl("ld\\+json|json", ct)) collect_rdf_from_url(ctx, lk$url, jsonld = TRUE)
    else if (grepl("turtle|rdf|n-triples|n3", ct)) collect_rdf_from_url(ctx, lk$url, jsonld = FALSE)
  }
  invisible()
}
