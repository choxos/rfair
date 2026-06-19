#' rfair: Assess the FAIRness of Research Data Objects
#'
#' rfair is a native R implementation of the F-UJI (FAIRsFAIR Research Data
#' Object Assessment) metrics. Given a persistent identifier or URL, it resolves
#' the object, harvests metadata from its landing page and from registries such
#' as DataCite, and scores the result against the FAIRsFAIR metrics. rfair began
#' as a fork of the rfuji F-UJI API client; unlike that client, it performs the
#' assessment entirely in R and does not require a running F-UJI server.
#'
#' The main entry point is [assess_fair()]. See the package vignettes and
#' <https://choxos.github.io/rfuji/> for details.
#'
#' @keywords internal
"_PACKAGE"
