# Canonical FAIR principle definitions.
#
# Sourced from the FAIR-nanopubs vocabulary (https://w3id.org/fair/principles),
# the machine-readable encoding of the FAIR Guiding Principles (Wilkinson et al.
# 2016) referenced by the canonical FAIR website, https://www.go-fair.org. This
# grounds rfair's metrics in the authoritative principle definitions.

#' The canonical FAIR (sub)principles.
#'
#' @param category Optional filter: one or more of "F", "A", "I", "R".
#' @return A data frame with `id`, `label`, `category`, `definition`, and `uri`
#'   (the w3id.org/fair/principles term URI).
#' @export
#' @examples
#' fair_principles()
#' fair_principles("R")
fair_principles <- function(category = NULL) {
  fp <- ref_data("fair_principles")
  df <- do.call(rbind, lapply(fp, function(p) data.frame(
    id = p$id, label = p$label, category = p$category,
    definition = p$definition, uri = p$uri, stringsAsFactors = FALSE)))
  rownames(df) <- NULL
  # order F, A, I, R
  df <- df[order(match(df$category, c("F", "A", "I", "R")), df$id), ]
  if (!is.null(category)) df <- df[df$category %in% category, , drop = FALSE]
  rownames(df) <- NULL
  attr(df, "source") <- paste(
    "FAIR Guiding Principles (Wilkinson et al. 2016, doi:10.1038/sdata.2016.18);",
    "machine-readable via FAIR-nanopubs (https://w3id.org/fair/principles),",
    "as referenced by https://www.go-fair.org/fair-principles/.")
  df
}

#' Canonical definition of the FAIR principle a metric maps to.
#'
#' For data metrics (`FsF-*`) this returns the FAIR Guiding Principle definition;
#' for software metrics (`FRSM-*`) it returns the corresponding FAIR4RS Principle
#' statement (see [fair4rs_principles()]).
#'
#' @param metric_identifier A metric identifier (e.g. "FsF-F1-01MD" or
#'   "FRSM-17-R1.2").
#' @return The principle's definition string, or `NA`.
#' @export
#' @examples
#' principle_definition("FsF-R1.1-01M")
#' principle_definition("FRSM-17-R1.2")
principle_definition <- function(metric_identifier) {
  pid <- unname(principle_of(metric_identifier)["principle"])
  if (is.na(pid)) return(NA_character_)
  if (grepl("^FRSM-", metric_identifier)) {
    d <- .fair4rs()
    hit <- d$statement[d$id == pid]
    return(if (length(hit)) hit[1] else NA_character_)
  }
  p <- ref_data("fair_principles")[[pid]]
  if (is.null(p)) NA_character_ else p$definition
}
