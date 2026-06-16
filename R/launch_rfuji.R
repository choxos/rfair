#' Launch the rfuji Shiny app
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
#' launch_rfuji()
#' }
launch_rfuji <- function(...) {
  for (pkg in c("shiny", "bslib", "DT")) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      stop("Package '", pkg, "' is required to run the rfuji app. ",
           "Install it with install.packages(\"", pkg, "\").", call. = FALSE)
    }
  }
  app_dir <- system.file("shiny-apps", "rfuji", package = "rfuji")
  if (!nzchar(app_dir)) {
    stop("Could not find the bundled Shiny app. Try reinstalling rfuji.", call. = FALSE)
  }
  shiny::runApp(app_dir, ...)
}
