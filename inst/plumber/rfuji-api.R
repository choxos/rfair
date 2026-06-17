#* @apiTitle rfuji FAIR assessment API
#* @apiDescription HTTP API scaffold for running rfuji FAIR assessments.

parse_bool <- function(x, default = FALSE) {
  if (missing(x) || is.null(x) || !nzchar(as.character(x))) return(default)
  tolower(as.character(x)) %in% c("1", "true", "t", "yes", "y")
}

parse_timeout <- function(x, default = 15) {
  if (missing(x) || is.null(x) || !nzchar(as.character(x))) return(default)
  value <- suppressWarnings(as.numeric(x))
  if (is.na(value)) return(default)
  max(1, min(120, value))
}

#* Health check
#* @serializer unboxedJSON
#* @get /health
function() {
  list(
    status = "ok",
    package = "rfuji",
    version = as.character(utils::packageVersion("rfuji"))
  )
}

#* Available metric versions
#* @serializer unboxedJSON
#* @get /metric-versions
function() {
  list(metric_versions = rfuji::rfuji_metric_versions())
}

#* Assess the FAIRness of an identifier or URL
#* @param id Persistent identifier, DOI, Handle, ARK, URN, or URL to assess.
#* @param metric_version Metric version accepted by rfuji_metric_versions().
#* @param use_datacite Whether to query DataCite metadata.
#* @param metadata_service_endpoint Optional metadata service endpoint or document URL.
#* @param metadata_service_type Metadata service type such as oai_pmh, ogc_csw, sparql, dcat, schema_org, datacite, crossref, signposting, typed_links, ro_crate, ckan, or other.
#* @param resolve Whether to resolve the identifier before harvesting metadata.
#* @param timeout Per-request timeout in seconds, clamped to 1..120.
#* @param use_headless Whether to use a headless browser when available.
#* @serializer unboxedJSON
#* @get /assess
function(id,
         metric_version = "0.8",
         use_datacite = "true",
         metadata_service_endpoint = "",
         metadata_service_type = "oai_pmh",
         resolve = "true",
         timeout = "15",
         use_headless = "false",
         res) {
  if (missing(id) || is.null(id) || !nzchar(trimws(as.character(id)))) {
    res$status <- 400
    return(list(error = "Query parameter `id` is required."))
  }
  endpoint <- if (is.null(metadata_service_endpoint)) "" else metadata_service_endpoint
  endpoint <- trimws(as.character(endpoint))
  if (!nzchar(endpoint)) endpoint <- NULL
  assessment <- rfuji::assess_fair(
    id = id,
    metric_version = metric_version,
    use_datacite = parse_bool(use_datacite, TRUE),
    metadata_service_endpoint = endpoint,
    metadata_service_type = metadata_service_type,
    resolve = parse_bool(resolve, TRUE),
    timeout = parse_timeout(timeout, 15),
    use_headless = parse_bool(use_headless, FALSE)
  )
  jsonlite::fromJSON(rfuji::as_fuji_json(assessment), simplifyVector = FALSE)
}
