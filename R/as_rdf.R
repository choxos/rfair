# Serialize a FAIR assessment to RDF as W3C Data Quality Vocabulary (DQV) +
# schema.org Rating, mirroring the machine-readable result F-UJI emits.

#' @noRd
build_dqv <- function(x) {
  s <- summary(x)
  fair <- s[s$category == "FAIR", ]
  principle_uri <- "https://w3id.org/fair/principles/terms/"
  measurements <- lapply(seq_len(nrow(s)), function(i) {
    list(
      "@type" = "dqv:QualityMeasurement",
      "dqv:value" = s$percent[i],
      "dqv:isMeasurementOf" = paste0(principle_uri, s$category[i])
    )
  })
  list(
    "@context" = list(
      dcat = "http://www.w3.org/ns/dcat#", dc = "http://purl.org/dc/terms/",
      schema = "http://schema.org/", dqv = "http://www.w3.org/ns/dqv#",
      prov = "http://www.w3.org/ns/prov#",
      rfuji = "https://github.com/choxos/rfuji#"
    ),
    "@type" = c("schema:Dataset", "dqv:QualityMetadata", "schema:Rating"),
    "dc:creator" = "rfuji",
    "dc:title" = paste("FAIR assessment results for", x$id),
    "dc:source" = x$id,
    "schema:ratingValue" = fair$percent %||% 0,
    "schema:bestRating" = 100,
    "schema:worstRating" = 0,
    "schema:reviewAspect" = "FAIRness",
    "prov:wasGeneratedBy" = list("@type" = "prov:Activity", "prov:used" = x$id),
    "rfuji:metricVersion" = x$metric_version,
    "rfuji:softwareVersion" = x$software_version,
    "dqv:hasQualityMeasurement" = measurements
  )
}

#' Serialize a FAIR assessment to RDF (DQV + schema.org Rating).
#'
#' Emits the assessment as W3C Data Quality Vocabulary quality measurements plus
#' a schema.org Rating, the machine-readable form the F-UJI service publishes.
#'
#' @param x A [fair_assessment] object.
#' @param format `"jsonld"` (default) or `"turtle"` (needs the optional `rdflib`
#'   package).
#' @return A character scalar of serialized RDF.
#' @export
#' @examples
#' \donttest{
#' a <- assess_fair("https://doi.org/10.5281/zenodo.8347772")
#' cat(as_rdf(a))
#' }
as_rdf <- function(x, format = c("jsonld", "turtle")) {
  format <- match.arg(format)
  if (!inherits(x, "fair_assessment")) {
    stop("`x` must be a <fair_assessment> (from assess_fair()).", call. = FALSE)
  }
  doc <- build_dqv(x)
  jsonld <- jsonlite::toJSON(doc, auto_unbox = TRUE, pretty = TRUE)
  if (format == "jsonld") return(as.character(jsonld))

  if (!requireNamespace("rdflib", quietly = TRUE)) {
    stop("Turtle output requires the 'rdflib' package. Install it, or use format = \"jsonld\".",
         call. = FALSE)
  }
  rdf <- rdflib::rdf_parse(jsonld, format = "jsonld", rdf = rdflib::rdf())
  tmp <- tempfile(fileext = ".ttl")
  on.exit(unlink(tmp))
  rdflib::rdf_serialize(rdf, tmp, format = "turtle")
  paste(readLines(tmp, warn = FALSE), collapse = "\n")
}
