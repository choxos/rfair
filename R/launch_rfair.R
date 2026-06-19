#' Launch the rfair Shiny app
#'
#' Opens an interactive app to assess the FAIRness of a research data object and
#' explore the per-metric results, license reusability, access/sensitivity, and
#' identifier hygiene.
#'
#' @param ... Passed to [shiny::runApp()].
#' @return Runs the app (called for its side effect); invisibly `NULL`.
#' @export
#' @examples
#' \dontrun{
#' launch_rfair()
#' }
launch_rfair <- function(...) {
  for (pkg in c("shiny", "bslib", "DT")) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      stop("Package '", pkg, "' is required to run the rfair app. ",
           "Install it with install.packages(\"", pkg, "\").", call. = FALSE)
    }
  }
  app_dir <- system.file("shiny-apps", "rfair", package = "rfair")
  if (!nzchar(app_dir)) {
    stop("Could not find the bundled Shiny app. Try reinstalling rfair.", call. = FALSE)
  }
  shiny::runApp(app_dir, ...)
}
