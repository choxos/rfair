# FsF-I2-01M: metadata uses registered semantic resources (vocabularies).
# Ported from fair_evaluator_semantic_vocabulary.py. In metrics v0.8 only test
# -2 applies: vocabulary namespaces used in the metadata (after excluding common
# default namespaces like RDF/XSD/DC/schema.org) must be listed in a registry.
# The registry is F-UJI's linked-vocabulary index (data-raw/08), matched against
# both declared namespaces and URIs that appear as metadata values (for example
# an SPDX license URL), as F-UJI's setLinkedNamespaces() does.
#
# Because rfair maps metadata into its reference schema, the property-level
# vocabulary namespaces of plain DataCite/Dublin Core records reduce to default
# namespaces and this metric correctly scores 0 (matching F-UJI). It passes when
# genuine domain vocabularies are present (e.g. via RDF harvesting).

#' Normalize a namespace or URI: no scheme, no "www.", lowercase, no trailing
#' separators.
#' @noRd
strip_ns <- function(x) sub("^www\\.", "", sub("[/#]+$", "", sub("^[a-z]+://", "", tolower(x))))

# Hosts whose URIs are identifiers, not vocabularies (LinkedVocabHelper.ignore_domain).
.NOT_VOCAB_HOSTS <- c("orcid.org", "doi.org", "dx.doi.org", "ror.org", "zenodo.org", "isni.org",
                      "github.com", "arxiv.org", "fairsharing.org", "nbn-resolving.org")

#' Registered vocabulary namespace (from F-UJI's linked-vocabulary index) that
#' each URI belongs to, or NA.
#'
#' A declared namespace matches its registry entry exactly or by prefix. A URI
#' used as a metadata value (`term = TRUE`) must name a term inside the
#' namespace: a bare `https://spdx.org/licenses/` does not count, while
#' `https://spdx.org/licenses/CC0-1.0.html` does, as in F-UJI.
#' @noRd
lod_namespace_of <- function(uris, term = FALSE) {
  index <- ref_data("linked_vocab_namespaces")
  index_stripped <- sub("[/#]+$", "", index)
  x <- strip_ns(uris)
  vapply(x, function(u) {
    if (sub("/.*$", "", u) %in% .NOT_VOCAB_HOSTS) return(NA_character_)
    hit <- if (term) which(startsWith(u, index) & nchar(u) > nchar(index))
           else which(u == index_stripped | startsWith(u, index))
    if (length(hit)) index_stripped[hit[which.max(nchar(index[hit]))]] else NA_character_
  }, character(1), USE.NAMES = FALSE)
}

#' @noRd
eval_semantic_vocabulary <- function(ctx, res) {
  defnorm <- strip_ns(ref_data("default_namespaces"))
  not_default <- function(n) n[!vapply(n, function(x) any(startsWith(x, defnorm)), logical(1))]
  # namespaces declared by the harvested metadata, and URIs used as values in it
  nondefault <- not_default(unique(strip_ns(ctx_namespace_uris(ctx))))
  linked <- not_default(unique(strip_ns(ctx$linked_uris)))
  known <- unique(stats::na.omit(c(lod_namespace_of(nondefault), lod_namespace_of(linked, term = TRUE))))

  if (crit_is_defined_suffix(res, "-1") && (length(nondefault) || length(known))) {
    crit_pass_suffix(res, "-1", evidence = unique(c(nondefault, known)))
  }
  if (crit_is_defined_suffix(res, "-2") && length(known)) {
    crit_pass_suffix(res, "-2", evidence = known)
    res$output <- lapply(known, function(n) list(namespace = n, is_namespace_active = TRUE))
  }
}
