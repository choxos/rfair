#' rfuji: Assess the FAIRness of Research Data Objects
#'
#' rfuji is a native R implementation of the F-UJI (FAIRsFAIR Research Data
#' Object Assessment) metrics. Given a persistent identifier or URL, it resolves
#' the object, harvests metadata from its landing page and from registries such
#' as DataCite, and scores the result against the FAIRsFAIR metrics. Unlike the
#' original rfuji client, this version performs the assessment entirely in R and
#' does not require a running F-UJI server.
#'
#' The main entry point is [assess_fair()]. See the package vignettes and
#' <https://choxos.github.io/rfuji/> for details.
#'
#' @keywords internal
"_PACKAGE"
