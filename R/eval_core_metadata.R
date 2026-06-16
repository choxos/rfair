# FsF-F2-01M: metadata includes descriptive core elements.
# Ported from fair_evaluator_minimal_metadata.py (FAIREvaluatorCoreMetadata).

# Citation core (partial_elements) and the order matters: descriptive (all 8)
# implies citation (6), so accumulating both scores matches upstream earned.
.CITATION_CORE <- c("creator", "title", "object_identifier",
                    "publication_date", "publisher", "object_type")

#' @noRd
eval_core_metadata <- function(ctx, res) {
  found <- intersect(names(ctx$metadata_merged), REFERENCE_ELEMENTS)
  status <- "insufficient metadata"

  # Legacy FsF <=0.6 also gave credit for metadata being offered through a
  # common web mechanism (embedded metadata, content negotiation, signposting).
  if (crit_is_defined_suffix(res, "-1") && length(ctx$metadata_sources) > 0L) {
    crit_pass_suffix(res, "-1",
                     evidence = unique(vapply(ctx$metadata_sources, function(s)
                       paste(s$source %||% "", s$method %||% "", sep = ":"),
                       character(1))))
  }

  # FsF-F2-01M-2: core citation metadata
  if (crit_is_defined_suffix(res, "-2") && all(.CITATION_CORE %in% found)) {
    crit_pass_suffix(res, "-2", evidence = paste(.CITATION_CORE, collapse = ", "))
    status <- "partial metadata"
  }

  # FsF-F2-01M-3: full core descriptive metadata
  if (crit_is_defined_suffix(res, "-3")) {
    required <- crit_required_names_suffix(res, "-3")
    if (!length(required)) required <- REQUIRED_CORE_METADATA
    if (all(required %in% found)) {
      crit_pass_suffix(res, "-3", evidence = paste(required, collapse = ", "))
      status <- "all metadata"
    }
  }

  res$output <- list(
    core_metadata_status = status,
    core_metadata_found = ctx$metadata_merged[intersect(found, REQUIRED_CORE_METADATA)]
  )
}
