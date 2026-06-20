#* @apiTitle rfair FAIR assessment API
#* @apiDescription HTTP API scaffold for running rfair FAIR assessments.

parse_bool <- function(x, default = FALSE) {
  value <- parse_string(x, "")
  if (!nzchar(value)) return(default)
  value <- tolower(value)
  if (value %in% c("1", "true", "t", "yes", "y")) return(TRUE)
  if (value %in% c("0", "false", "f", "no", "n")) return(FALSE)
  NA
}

parse_string <- function(x, default = "") {
  if (missing(x) || is.null(x) || !length(x)) return(default)
  value <- trimws(as.character(x[[1]]))
  if (nzchar(value)) value else default
}

parse_timeout <- function(x, default = 15) {
  if (missing(x) || is.null(x) || !nzchar(as.character(x))) return(default)
  value <- suppressWarnings(as.numeric(x))
  if (is.na(value)) return(default)
  max(1, min(120, value))
}

metadata_service_types <- function() {
  c("oai_pmh", "ogc_csw", "sparql", "dcat", "schema_org", "datacite",
    "crossref", "signposting", "typed_links", "ro_crate", "ckan", "other")
}

bad_request <- function(res, message, parameter, allowed = NULL) {
  res$status <- 400
  out <- list(error = message, parameter = parameter)
  if (!is.null(allowed)) out$allowed <- allowed
  out
}

#* Health check
#* @serializer unboxedJSON
#* @get /health
function() {
  list(
    status = "ok",
    package = "rfair",
    version = as.character(utils::packageVersion("rfair"))
  )
}

#* Available metric versions
#* @serializer unboxedJSON
#* @get /metric-versions
function() {
  list(metric_versions = rfair::rfair_metric_versions())
}

#* Assess the FAIRness of an identifier or URL
#* @param id Persistent identifier, DOI, Handle, ARK, URN, or URL to assess.
#* @param metric_version Metric version accepted by rfair_metric_versions().
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
    return(bad_request(res, "Query parameter `id` is required.", "id"))
  }
  metric_version <- parse_string(metric_version, "0.8")
  metadata_service_type <- parse_string(metadata_service_type, "oai_pmh")

  metric_versions <- rfair::rfair_metric_versions()
  if (!metric_version %in% metric_versions) {
    return(bad_request(
      res,
      sprintf("Unsupported `metric_version`: %s.", metric_version),
      "metric_version",
      metric_versions
    ))
  }

  service_types <- metadata_service_types()
  if (!metadata_service_type %in% service_types) {
    return(bad_request(
      res,
      sprintf("Unsupported `metadata_service_type`: %s.", metadata_service_type),
      "metadata_service_type",
      service_types
    ))
  }

  endpoint <- parse_string(metadata_service_endpoint, "")
  if (!nzchar(endpoint)) endpoint <- NULL

  use_datacite <- parse_bool(use_datacite, TRUE)
  if (is.na(use_datacite)) {
    return(bad_request(
      res,
      "Query parameter `use_datacite` must be boolean.",
      "use_datacite",
      c("true", "false", "1", "0", "yes", "no", "y", "n", "t", "f")
    ))
  }
  resolve <- parse_bool(resolve, TRUE)
  if (is.na(resolve)) {
    return(bad_request(
      res,
      "Query parameter `resolve` must be boolean.",
      "resolve",
      c("true", "false", "1", "0", "yes", "no", "y", "n", "t", "f")
    ))
  }
  use_headless <- parse_bool(use_headless, FALSE)
  if (is.na(use_headless)) {
    return(bad_request(
      res,
      "Query parameter `use_headless` must be boolean.",
      "use_headless",
      c("true", "false", "1", "0", "yes", "no", "y", "n", "t", "f")
    ))
  }

  assessment <- rfair::assess_fair(
    id = id,
    metric_version = metric_version,
    use_datacite = use_datacite,
    metadata_service_endpoint = endpoint,
    metadata_service_type = metadata_service_type,
    resolve = resolve,
    timeout = parse_timeout(timeout, 15),
    use_headless = use_headless
  )
  jsonlite::fromJSON(rfair::as_fuji_json(assessment), simplifyVector = FALSE)
}
