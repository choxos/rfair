# Interoperability metrics: FsF-I1-01M (formal representation) and
# FsF-I3-01M (qualified references to related entities).
# FsF-I2-01M (semantic vocabularies) needs the linked-vocab corpus -> Phase 3.

#' FsF-I1-01M: metadata uses a formal, machine-readable representation.
#' @noRd
eval_formal_metadata <- function(ctx, res) {
  mid <- res$metric_identifier
  # -1 structured metadata embedded in the landing page (JSON-LD / RDFa)
  t1 <- paste0(mid, "-1")
  embedded <- any(vapply(ctx$metadata_sources, function(s)
    grepl("schema|rdfa|microdata", tolower(s$source %||% "")) &&
      identical(s$method, "embedded"), logical(1)))
  if (crit_is_defined(res, t1) && embedded) crit_pass(res, t1, evidence = "embedded JSON-LD/RDFa")
  # -2 structured metadata via content negotiation (RDF / JSON-LD / DataCite JSON)
  t2 <- paste0(mid, "-2")
  negotiated <- has_offering_method(ctx, "content_negotiation")
  if (crit_is_defined(res, t2) && negotiated) crit_pass(res, t2, evidence = "content negotiation")
}

#' FsF-I3-01M: qualified references to related entities.
#' @noRd
eval_related_resources <- function(ctx, res) {
  mid <- res$metric_identifier
  rels <- ctx$related_resources
  if (is.null(rels) || length(rels) == 0L) return(invisible())
  # -1 related resources referenced in metadata (plain text)
  t1 <- paste0(mid, "-1")
  if (crit_is_defined(res, t1)) crit_pass(res, t1, evidence = sprintf("%d related resources", length(rels)))
  # -2 related resources referenced by machine-readable identifiers
  t2 <- paste0(mid, "-2")
  machine <- any(vapply(rels, function(r) is.list(r) && looks_like_pid(r$related_resource), logical(1)))
  if (crit_is_defined(res, t2) && machine) crit_pass(res, t2, evidence = "qualified by identifiers")
  res$output <- rels
}
