# Identifier best-practice / hygiene checks.
#
# Addresses a peer-review critique: automated FAIR tools reward the mere
# presence of a PID or ontology term, but layered identifiers (e.g.
# "RRID:MGI:5577054", an identifier minted on top of another) and non-resolvable
# or non-standard identifiers reduce interoperability. identifier_hygiene()
# flags such anti-patterns.

#' Check an identifier against best-practice / hygiene heuristics.
#'
#' @param id A persistent identifier or URL.
#' @return A list with `identifier`, `scheme`, `is_persistent`, `hygiene_ok`,
#'   and a character vector of `issues`.
#' @export
#' @examples
#' identifier_hygiene("RRID:MGI:5577054")$issues
#' identifier_hygiene("https://doi.org/10.5281/zenodo.8347772")$hygiene_ok
identifier_hygiene <- function(id) {
  p <- id_parse(id)
  issues <- character(0)

  layered <- grepl("(?i)^rrid:", id, perl = TRUE) ||
    (grepl("^[A-Za-z]+:[A-Za-z]+:[^:/]+$", id) && !grepl("(?i)^(urn|info):", id, perl = TRUE))
  if (layered) {
    issues <- c(issues, paste(
      "Compound/layered identifier: an identifier minted on top of another",
      "(e.g. RRID:MGI:...) reduces interoperability; prefer the underlying source PID."))
  }
  if (is.na(p$preferred_schema)) {
    issues <- c(issues, "Identifier scheme not recognized; may not follow identifier best practices.")
  } else if (!isTRUE(p$is_persistent)) {
    issues <- c(issues, paste(
      "Not a persistent identifier; prefer a DOI, Handle, or ARK for long-term resolvability."))
  }

  list(identifier = id, scheme = p$preferred_schema,
       is_persistent = isTRUE(p$is_persistent),
       hygiene_ok = length(issues) == 0L, issues = issues)
}
