# FsF-F2-01M: metadata includes descriptive core elements.
# Ported from fair_evaluator_minimal_metadata.py (FAIREvaluatorCoreMetadata).

# Citation core (partial_elements) and the order matters: descriptive (all 8)
# implies citation (6), so accumulating both scores matches upstream earned.
.CITATION_CORE <- c("creator", "title", "object_identifier",
                    "publication_date", "publisher", "object_type")

#' @noRd
eval_core_metadata <- function(ctx, res) {
  mid <- res$metric_identifier
  found <- intersect(names(ctx$metadata_merged), REFERENCE_ELEMENTS)
  status <- "insufficient metadata"

  # FsF-F2-01M-2: core citation metadata
  t2 <- paste0(mid, "-2")
  if (crit_is_defined(res, t2) && all(.CITATION_CORE %in% found)) {
    crit_pass(res, t2, evidence = paste(.CITATION_CORE, collapse = ", "))
    status <- "partial metadata"
  }

  # FsF-F2-01M-3: full core descriptive metadata
  t3 <- paste0(mid, "-3")
  if (crit_is_defined(res, t3)) {
    required <- crit_required_names(res, t3)
    if (!length(required)) required <- REQUIRED_CORE_METADATA
    if (all(required %in% found)) {
      crit_pass(res, t3, evidence = paste(required, collapse = ", "))
      status <- "all metadata"
    }
  }

  res$output <- list(
    core_metadata_status = status,
    core_metadata_found = ctx$metadata_merged[intersect(found, REQUIRED_CORE_METADATA)]
  )
}
