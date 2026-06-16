# FAIR-TLC extension: Traceable, Licensed, Connected.

#' FAIR-TLC indicators (Traceable, Licensed, Connected)
#'
#' Computes the three "FAIR+" indicators proposed by Haendel and colleagues in
#' the Monarch Initiative / NCATS TransMed response to the NIH RFI on biomedical
#' repository value metrics (\doi{10.5281/zenodo.203295}), building on the
#' (Re)usable Data Project (\doi{10.1371/journal.pone.0213090}). They extend FAIR
#' with the provenance and legal dimensions that automated FAIR tools usually
#' miss: whether data is **Traceable** (provenance, attribution), **Licensed**
#' (clearly documented and actually reusable), and **Connected** (qualified links
#' to related entities).
#'
#' @param x A [fair_assessment] from [assess_fair()].
#' @return A data frame with columns `dimension`, `indicator`, `met` (logical),
#'   and `detail`, plus a `"source"` attribute citing the framework.
#' @export
#' @examples
#' \donttest{
#' a <- assess_fair("https://doi.org/10.5281/zenodo.8347772")
#' fair_tlc(a)
#' }
fair_tlc <- function(x) {
  if (!inherits(x, "fair_assessment")) {
    stop("`x` must be a <fair_assessment> (from assess_fair()).", call. = FALSE)
  }
  md <- x$metadata
  has <- function(k) !is.null(md[[k]]) && length(md[[k]]) > 0L
  metric_pass <- function(id) {
    r <- Find(function(r) identical(r$metric_identifier, id), x$results)
    !is.null(r) && identical(r$test_status, "pass")
  }

  reuse <- x$reuse$licenses %||% list()
  documented <- length(reuse) > 0L
  standard <- any(vapply(reuse, function(l) !is.na(l$spdx_id), logical(1)))
  minimally_restrictive <- isTRUE(x$reuse$any_open)
  flowthrough_known <- documented &&
    all(vapply(reuse, function(l) !identical(l$category, "custom/unknown"), logical(1)))

  mk <- function(dimension, indicator, met, detail) {
    data.frame(dimension = dimension, indicator = indicator, met = isTRUE(met),
               detail = detail, stringsAsFactors = FALSE)
  }
  df <- rbind(
    mk("Traceable", "T1 Provenance",
       metric_pass("FsF-R1.2-01M") || has("created_date") || has("modified_date"),
       "data creation/generation provenance is recorded"),
    mk("Traceable", "T2 Attribution",
       has("creator") && (has("publisher") || has("contributor")),
       "creators and publisher are recorded for citation"),
    mk("Licensed", "L1 Documented & minimally restrictive",
       documented && standard && minimally_restrictive,
       "a standard license is present that actually permits reuse"),
    mk("Licensed", "L2 Flowthrough transparency",
       flowthrough_known,
       "downstream reuse/redistribution implications are determinable"),
    mk("Connected", "C1 Connectedness",
       metric_pass("FsF-I3-01M") || has("related_resources"),
       "qualified links to related entities are present")
  )
  rownames(df) <- NULL
  attr(df, "source") <- paste(
    "FAIR-TLC (Traceable, Licensed, Connected): Haendel et al., Monarch/NCATS",
    "TransMed response to the NIH RFI on biomedical repository value metrics",
    "(doi:10.5281/zenodo.203295); (Re)usable Data Project",
    "(doi:10.1371/journal.pone.0213090).")
  df
}
