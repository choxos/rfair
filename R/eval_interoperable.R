# Interoperability metrics: FsF-I1-01M (formal representation) and
# FsF-I3-01M (qualified references to related entities).
# FsF-I2-01M (semantic vocabularies) needs the linked-vocab corpus -> Phase 3.

#' FsF-I1-01M: metadata uses a formal, machine-readable representation.
#' @noRd
eval_formal_metadata <- function(ctx, res) {
  # -1 structured metadata embedded in the landing page (JSON-LD / RDFa)
  embedded <- any(vapply(ctx$metadata_sources, function(s)
    grepl("schema|rdfa|microdata", tolower(s$source %||% "")) &&
      identical(s$method, "embedded"), logical(1)))
  if (crit_is_defined_suffix(res, "-1") && embedded) {
    crit_pass_suffix(res, "-1", evidence = "embedded JSON-LD/RDFa")
  }
  # -2 structured metadata via content negotiation (RDF / JSON-LD / DataCite JSON)
  negotiated <- has_offering_method(ctx, "content_negotiation")
  if (crit_is_defined_suffix(res, "-2") && negotiated) {
    crit_pass_suffix(res, "-2", evidence = "content negotiation")
  }
}

#' FsF-I3-01M: qualified references to related entities.
#' @noRd
eval_related_resources <- function(ctx, res) {
  rels <- ctx$related_resources
  if (is.null(rels) || length(rels) == 0L) return(invisible())
  # -1 related resources referenced in metadata (plain text)
  if (crit_is_defined_suffix(res, "-1")) {
    crit_pass_suffix(res, "-1", evidence = sprintf("%d related resources", length(rels)))
  }
  # -2 related resources referenced by machine-readable identifiers
  machine <- any(vapply(rels, function(r) is.list(r) && looks_like_pid(r$related_resource), logical(1)))
  if (crit_is_defined_suffix(res, "-2") && machine) {
    crit_pass_suffix(res, "-2", evidence = "qualified by identifiers")
  }
  res$output <- rels
}
