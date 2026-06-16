# Reusability metrics: FsF-R1-01M (data content metadata),
# FsF-R1.2-01M (provenance), FsF-R1.3-02D (data file format).
# FsF-R1.3-01M (community metadata standard) needs the standards corpus -> Phase 3.

# Metadata elements that carry provenance information (Mapper.PROVENANCE_MAPPING).
.PROVENANCE_ELEMENTS <- c("contributor", "creator", "publisher", "right_holder",
                          "created_date", "modified_date", "publication_date",
                          "related_resources", "object_type")

#' FsF-R1-01M: metadata describes the data content.
#' @noRd
eval_data_content_metadata <- function(ctx, res) {
  mid <- res$metric_identifier
  mm <- ctx$metadata_merged
  # -1 resource type specified
  t1 <- paste0(mid, "-1")
  if (crit_is_defined(res, t1) && !is.null(mm$object_type)) crit_pass(res, t1, evidence = as_chr(mm$object_type))
  # -2 form/manner: file size and type, or service endpoint
  t2 <- paste0(mid, "-2")
  has_form <- !is.null(mm$object_format) || !is.null(mm$object_size) ||
    length(content_urls_of(ctx)) > 0L
  if (crit_is_defined(res, t2) && has_form) crit_pass(res, t2, evidence = "file type/size or data links")
  # -3 measured variables / observation types
  t3 <- paste0(mid, "-3")
  if (crit_is_defined(res, t3) && !is.null(mm$measured_variable)) crit_pass(res, t3)
}

#' FsF-R1.2-01M: provenance information is provided.
#' @noRd
eval_data_provenance <- function(ctx, res) {
  mid <- res$metric_identifier
  found <- intersect(.PROVENANCE_ELEMENTS, names(ctx$metadata_merged))
  # -1 provenance via dedicated/standard metadata elements (mappable to PROV/DC)
  t1 <- paste0(mid, "-1")
  if (crit_is_defined(res, t1) && length(found) > 0L) crit_pass(res, t1, evidence = found)
  # -2 provenance via a formal provenance ontology -> Phase 2/3 (RDF)
  res$output <- list(provenance_elements = found)
}

#' FsF-R1.3-02D: data is in a community-recommended file format.
#' @noRd
eval_data_file_format <- function(ctx, res) {
  t1 <- paste0(res$metric_identifier, "-1")
  recommended <- c(names(ref_data("science_file_formats")),
                   names(ref_data("long_term_file_formats")),
                   names(ref_data("open_file_formats")))
  candidates <- tolower(as_chr(c(ctx$metadata_merged$object_format,
                                 ctx$metadata_merged$object_content_identifier)))
  hit <- candidates[candidates %in% recommended]
  if (crit_is_defined(res, t1) && length(hit) > 0L) {
    crit_pass(res, t1, evidence = hit)
    res$output <- list(recommended_formats = hit)
  }
}
