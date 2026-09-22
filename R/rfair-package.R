#' rfair: Assess the FAIRness of Research Data Objects and Software
#'
#' rfair is a native R implementation of the F-UJI (FAIRsFAIR Research Data
#' Object Assessment) metrics and the FRSM (FAIR for Research Software) metrics.
#' Given a persistent identifier, URL, or code repository, it resolves the
#' object, harvests metadata from its landing page, registries such as DataCite,
#' and code forges, and scores the result against the chosen metrics. rfair began
#' as a fork of the rfuji F-UJI API client; unlike that client, it performs the
#' assessment entirely in R and does not require a running F-UJI server.
#'
#' The main entry point is [assess_fair()]. See the package vignettes and
#' <https://choxos.github.io/rfair/> for details.
#'
#' @keywords internal
"_PACKAGE"
