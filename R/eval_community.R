# FsF-R1.3-01M: metadata follows a community-recommended standard.
# Ported from fair_evaluator_community_metadata.py. Detects standards from the
# namespace/schema URIs of harvested metadata and classifies them as generic
# (multidisciplinary, RDA/FAIRsharing-endorsed) or disciplinary.

#' @noRd
eval_community_metadata <- function(ctx, res) {
  nss <- ctx_namespace_uris(ctx)
  found <- Filter(Negate(is.null), lapply(nss, lookup_standard))
  # dedupe by standard name
  seen <- character(0); uniq <- list()
  for (s in found) if (!(s$name %in% seen)) { seen <- c(seen, s$name); uniq[[length(uniq) + 1L]] <- s }
  generic <- Filter(function(s) identical(s$type, "generic"), uniq)
  disc <- Filter(function(s) identical(s$type, "disciplinary"), uniq)

  # -3 multidisciplinary but community endorsed (maturity 1)
  if (crit_is_defined_suffix(res, "-3") && length(generic)) {
    crit_pass_suffix(res, "-3", evidence = vapply(generic, function(s) s$name, character(1)))
  }
  # -1 community-specific (disciplinary) standard (maturity 3)
  if (crit_is_defined_suffix(res, "-1") && length(disc)) {
    crit_pass_suffix(res, "-1", evidence = vapply(disc, function(s) s$name, character(1)))
  }
  res$output <- lapply(uniq, function(s) list(
    metadata_standard = s$name, type = s$type, url = s$uri, subject_areas = s$subject))
}
