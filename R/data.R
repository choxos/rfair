#' An example FAIR assessment
#'
#' A stored [fair_assessment][fair_assessment] object, produced by running
#' [assess_fair()] on a stable Zenodo deposit
#' (\doi{10.5281/zenodo.8347772}). It is bundled so the plotting examples and
#' the `vignette("illustrating-fairness")` can run offline and reproducibly,
#' without contacting any network service.
#'
#' The verbose per-test debug log has been stripped to keep the installed size
#' small; all elements used by the `print`, `summary`, `as.data.frame`,
#' [plot][plot.fair_assessment], [as_fair_json()], and [as_rdf()] methods are
#' retained.
#'
#' @format A `fair_assessment` object (a list with S3 class `fair_assessment`);
#'   see [fair_assessment] for its structure.
#' @source [assess_fair()] on \doi{10.5281/zenodo.8347772},
#'   rebuilt by `data-raw/06-build-example-assessment.R`.
#' @seealso [assess_fair()], [plot.fair_assessment()]
#' @examples
#' data(fair_example)
#' summary(fair_example)
#' plot(fair_example)
"fair_example"
