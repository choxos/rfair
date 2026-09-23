# Serialize a FAIR assessment to RDF as W3C Data Quality Vocabulary (DQV) +
# schema.org Rating, mirroring the machine-readable result F-UJI emits.

#' @noRd
build_dqv <- function(x) {
  s <- summary(x)
  fair <- s[s$category == "FAIR", ]
  principle_uri <- "https://w3id.org/fair/principles/terms/"
  spec <- x$metric_specification %||% "https://doi.org/10.5281/zenodo.6461229"
  target <- list("@id" = if (is_nonempty_string(x$resolved_url)) x$resolved_url else x$id)
  measurements <- lapply(seq_len(nrow(s)), function(i) {
    list(
      "@type" = "dqv:QualityMeasurement",
      "dqv:value" = s$percent[i],
      "dqv:isMeasurementOf" = paste0(principle_uri, s$category[i])
    )
  })
  # one measurement per metric, identified within the metric specification
  metric_measurements <- lapply(x$results, function(r) list(
    "@type" = "dqv:QualityMeasurement",
    "dqv:value" = r$score$percent %||% 0,
    "dqv:computedOn" = target,
    "dqv:isMeasurementOf" = list("@id" = paste0(spec, "#", r$metric_identifier),
                                 "@type" = "dqv:Metric",
                                 "dc:title" = r$metric_name %||% r$metric_identifier)))

  # one FAIR Test Result (OSTrails FTR vocabulary 1.3.0) per metric test
  advice <- recommendation_table()
  test_results <- unname(unlist(lapply(x$results, function(r) {
    lapply(r$metric_tests %||% list(), function(t) {
      passed <- identical(t$metric_test_status, "pass")
      out <- list(
        "@type" = "ftr:TestResult",
        "dc:identifier" = t$metric_test_identifier,
        "dc:title" = t$metric_test_name %||% t$metric_test_identifier,
        "prov:value" = if (passed) "pass" else "fail",
        "ftr:completion" = if (passed) 1 else 0,
        "ftr:outputFromTest" = list("@id" = paste0(spec, "#", t$metric_test_identifier)),
        "ftr:assessmentTarget" = target)
      if (length(t$evidence)) out[["ftr:log"]] <- paste(as_chr(t$evidence), collapse = "; ")
      tip <- advice[[t$metric_test_identifier]]
      if (!passed && is_nonempty_string(tip)) {
        out[["ftr:suggestion"]] <- list("@type" = "ftr:GuidanceContext", "dc:description" = tip)
      }
      out
    })
  }), recursive = FALSE))

  list(
    "@context" = list(
      dcat = "http://www.w3.org/ns/dcat#", dc = "http://purl.org/dc/terms/",
      schema = "http://schema.org/", dqv = "http://www.w3.org/ns/dqv#",
      prov = "http://www.w3.org/ns/prov#", ftr = "https://w3id.org/ftr#",
      rfair = "https://github.com/choxos/rfair#"
    ),
    "@type" = c("schema:Dataset", "dqv:QualityMetadata", "schema:Rating"),
    "dc:creator" = "rfair",
    "dc:title" = paste("FAIR assessment results for", x$id),
    "dc:source" = x$id,
    "schema:ratingValue" = fair$percent %||% 0,
    "schema:bestRating" = 100,
    "schema:worstRating" = 0,
    "schema:reviewAspect" = "FAIRness",
    "prov:wasGeneratedBy" = list("@type" = "prov:Activity", "prov:used" = x$id),
    "prov:wasDerivedFrom" = list("@type" = "ftr:TestResultSet", "prov:hadMember" = test_results),
    "rfair:metricVersion" = x$metric_version,
    "rfair:softwareVersion" = x$software_version,
    "dqv:hasQualityMeasurement" = c(measurements, metric_measurements)
  )
}

#' Serialize a FAIR assessment to RDF (DQV + schema.org Rating + FTR).
#'
#' Emits the assessment as W3C Data Quality Vocabulary quality measurements (one
#' per FAIR category and one per metric) plus a schema.org Rating, the
#' machine-readable form the F-UJI service publishes, and one FAIR Test Result
#' per metric test using the OSTrails FAIR Testing Resource vocabulary
#' (<https://w3id.org/ftr/>, version 1.3.0): `prov:value` pass or fail,
#' `ftr:completion`, the evidence as `ftr:log`, and for failed tests the
#' [fair_recommendations()] action as an `ftr:suggestion`. Metrics and tests are
#' identified within the metric specification (for example
#' `https://doi.org/10.5281/zenodo.6461229#FsF-F1-01MD-1`).
#'
#' @param x A [fair_assessment] object.
#' @param format `"jsonld"` (default) or `"turtle"` (needs the optional `rdflib`
#'   and `jsonld` packages).
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

  for (pkg in c("rdflib", "jsonld")) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      stop("Turtle output requires the 'rdflib' and 'jsonld' packages. Install ",
           "them, or use format = \"jsonld\".", call. = FALSE)
    }
  }
  rdf <- rdflib::rdf_parse(jsonld, format = "jsonld", rdf = rdflib::rdf())
  tmp <- tempfile(fileext = ".ttl")
  on.exit(unlink(tmp))
  rdflib::rdf_serialize(rdf, tmp, format = "turtle")
  paste(readLines(tmp, warn = FALSE), collapse = "\n")
}
