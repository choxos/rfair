# Export a `fair_assessment` to the upstream F-UJI `FAIRResults` JSON schema,
# for interoperability with existing F-UJI clients and the conformance harness.

#' @noRd
as_fair_list <- function(x) {
  list(
    test_id = digest::digest(x$id, algo = "sha1", serialize = FALSE),
    request = x$request,
    start_timestamp = x$start_timestamp,
    end_timestamp = x$end_timestamp,
    software_version = x$software_version,
    metric_version = x$metric_version,
    metric_specification = x$metric_specification,
    total_metrics = x$total_metrics,
    summary = x$summary,
    results = x$results,
    resolved_url = x$resolved_url
  )
}

#' Convert a FAIR assessment to F-UJI-compatible JSON.
#'
#' Produces a payload matching the upstream F-UJI `FAIRResults` schema, so the
#' output can be consumed by tools built for the F-UJI service.
#'
#' @param x A [fair_assessment] object.
#' @param pretty Whether to pretty-print the JSON.
#' @return A JSON string (class `json`).
#' @export
#' @examples
#' \donttest{
#' a <- assess_fair("https://doi.org/10.5281/zenodo.8347772")
#' cat(as_fair_json(a))
#' }
as_fair_json <- function(x, pretty = TRUE) {
  if (!inherits(x, "fair_assessment")) {
    stop("`x` must be a <fair_assessment> (from assess_fair()).", call. = FALSE)
  }
  jsonlite::toJSON(as_fair_list(x), auto_unbox = TRUE, null = "null",
                   na = "null", pretty = pretty)
}
