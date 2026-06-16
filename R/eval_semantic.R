# FsF-I2-01M: metadata uses registered semantic resources (vocabularies).
# Ported from fair_evaluator_semantic_vocabulary.py. In metrics v0.8 only test
# -2 applies: vocabulary namespaces used in the metadata (after excluding common
# default namespaces like RDF/XSD/DC/schema.org) must be listed in a registry.
#
# Because rfuji maps metadata into its reference schema, the property-level
# vocabulary namespaces of plain DataCite/Dublin Core records reduce to default
# namespaces and this metric correctly scores 0 (matching F-UJI). It passes when
# genuine domain vocabularies are present (e.g. via RDF harvesting).

# A curated subset of registered semantic-vocabulary namespaces (LOD registry).
.KNOWN_VOCABS <- c(
  "w3.org/2004/02/skos/core", "xmlns.com/foaf", "w3.org/ns/prov", "w3.org/ns/dcat",
  "purl.org/pav", "w3.org/ns/sosa", "w3.org/ns/ssn", "w3.org/2006/time",
  "purl.org/spar", "purl.obolibrary.org/obo", "w3.org/ns/org", "w3.org/2006/vcard",
  "rdfs.org/ns/void", "qudt.org", "geonames.org", "purl.org/linked-data/cube",
  "w3.org/2003/01/geo", "purl.org/vocab", "vocab.nerc.ac.uk", "schema.geolink.org"
)

#' @noRd
eval_semantic_vocabulary <- function(ctx, res) {
  t2 <- paste0(res$metric_identifier, "-2")
  if (!crit_is_defined(res, t2)) return(invisible())
  strip_ns <- function(x) sub("^www\\.", "", sub("[/#]+$", "", sub("^https?://", "", tolower(x))))
  norm <- strip_ns(ctx_namespace_uris(ctx))
  defnorm <- strip_ns(ref_data("default_namespaces"))
  nondefault <- norm[!vapply(norm, function(n) any(startsWith(n, defnorm)), logical(1))]
  known <- nondefault[vapply(nondefault, function(n) any(startsWith(n, .KNOWN_VOCABS)), logical(1))]
  if (length(known)) {
    crit_pass(res, t2, evidence = known)
    res$output <- lapply(known, function(n) list(namespace = n, is_namespace_active = TRUE))
  }
}
