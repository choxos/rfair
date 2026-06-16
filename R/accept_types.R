# HTTP Accept header profiles, ported from the AcceptTypes enum in
# fuji_server/helper/request_helper.py (:39-57).

ACCEPT_TYPES <- list(
  datacite_json = "application/vnd.datacite.datacite+json",
  datacite_xml  = "application/vnd.datacite.datacite+xml",
  schemaorg     = "application/vnd.schemaorg.ld+json, application/ld+json",
  html          = "text/html, application/xhtml+xml",
  html_xml      = "text/html, application/xhtml+xml, application/xml;q=0.5, text/xml;q=0.5, application/rdf+xml;q=0.5",
  xml           = "application/xml, text/xml;q=0.5",
  linkset       = "application/linkset, application/linkset+json",
  json          = "application/json, text/json;q=0.5",
  jsonld        = "application/ld+json",
  atom          = "application/atom+xml",
  rdfjson       = "application/rdf+json",
  nt            = "text/n3, application/n-triples",
  rdfxml        = "application/rdf+xml, text/rdf;q=0.5, application/xml;q=0.1, text/xml;q=0.1",
  turtle        = "text/ttl, text/turtle, application/turtle, application/x-turtle;q=0.6, text/n3;q=0.3, text/rdf+n3;q=0.3, application/rdf+n3;q=0.3",
  rdf           = "text/turtle, application/turtle, application/x-turtle;q=0.8, application/rdf+xml, text/n3;q=0.9, text/rdf+n3;q=0.9,application/ld+json",
  default       = "text/html, */*"
)

#' Guess a metadata format label from a content (MIME) type.
#' @noRd
guess_format <- function(content_type) {
  if (!is_nonempty_string(content_type)) return(NA_character_)
  ct <- tolower(sub(";.*$", "", content_type))
  if (grepl("datacite", ct)) return(if (grepl("xml", ct)) "datacite_xml" else "datacite_json")
  if (grepl("ld\\+json", ct)) return("jsonld")
  if (grepl("rdf\\+xml", ct)) return("rdfxml")
  if (grepl("turtle|x-turtle|n3|n-triples|ttl", ct)) return("turtle")
  if (grepl("json", ct)) return("json")
  if (grepl("xhtml|text/html", ct)) return("html")
  if (grepl("xml", ct)) return("xml")
  NA_character_
}
