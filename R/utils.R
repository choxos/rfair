# Internal utilities shared across the engine.

# `rfuji_data` is the internal reference-data list baked into R/sysdata.rda by
# data-raw/01-build-sysdata.R. R loads it into the package namespace at install.
utils::globalVariables("rfuji_data")

#' Null/empty coalescing operator
#' @noRd
`%||%` <- function(x, y) if (is.null(x) || length(x) == 0L) y else x

#' Access a baked-in reference table from R/sysdata.rda
#' @param key Name of the table (e.g. "spdx", "science_file_formats").
#' @noRd
ref_data <- function(key) {
  d <- rfuji_data[[key]]
  if (is.null(d)) stop(sprintf("rfuji reference data '%s' not found; reinstall the package.", key))
  d
}

#' Is `x` a non-empty, non-NA scalar string?
#' @noRd
is_nonempty_string <- function(x) {
  is.character(x) && length(x) == 1L && !is.na(x) && nzchar(x)
}

#' Coerce a value to a character vector, dropping NULLs/NAs/empties.
#' @noRd
as_chr <- function(x) {
  if (is.null(x)) return(character(0))
  x <- unlist(x, use.names = FALSE)
  x <- as.character(x)
  x[!is.na(x) & nzchar(x)]
}
