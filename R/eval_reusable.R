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
  mm <- ctx$metadata_merged
  urls <- content_urls_of(ctx)
  has_type <- !is.null(mm$object_type)
  has_link <- length(urls) > 0L
  has_file_descriptor <- !is.null(mm$object_format) || !is.null(mm$object_size)
  has_variable <- !is.null(mm$measured_variable)
  has_service <- is_nonempty_string(ctx$metadata_service_endpoint)

  # -1 resource type specified
  if (crit_is_defined_suffix(res, "-1") && (has_type || has_link)) {
    crit_pass_suffix(res, "-1",
                     evidence = c(as_chr(mm$object_type), urls))
  }
  if (crit_is_defined_suffix(res, "-1a") && has_type) {
    crit_pass_suffix(res, "-1a", evidence = as_chr(mm$object_type))
  }
  if (crit_is_defined_suffix(res, "-1b") && has_link) {
    crit_pass_suffix(res, "-1b", evidence = urls)
  }

  # -2 form/manner: file size and type, or service endpoint
  has_form <- has_file_descriptor || has_link || has_service
  if (crit_is_defined_suffix(res, "-2") && has_form) {
    crit_pass_suffix(res, "-2", evidence = "file type/size, data links, or service endpoint")
  }
  if (crit_is_defined_suffix(res, "-2a") && has_file_descriptor) {
    crit_pass_suffix(res, "-2a", evidence = c(as_chr(mm$object_format), as_chr(mm$object_size)))
  }
  if (crit_is_defined_suffix(res, "-2b") && has_variable) {
    crit_pass_suffix(res, "-2b", evidence = as_chr(mm$measured_variable))
  }
  if (crit_is_defined_suffix(res, "-2c") && has_service) {
    crit_pass_suffix(res, "-2c", evidence = ctx$metadata_service_endpoint)
  }

  # -3 measured variables / observation types
  if (crit_is_defined_suffix(res, "-3") && (has_file_descriptor || has_service)) {
    crit_pass_suffix(res, "-3", evidence = "declared content descriptor")
  }
  if (crit_is_defined_suffix(res, "-4") && has_variable) {
    crit_pass_suffix(res, "-4", evidence = as_chr(mm$measured_variable))
  }
}

#' FsF-R1.2-01M: provenance information is provided.
#' @noRd
eval_data_provenance <- function(ctx, res) {
  found <- intersect(.PROVENANCE_ELEMENTS, names(ctx$metadata_merged))
  # -1 provenance via dedicated/standard metadata elements (mappable to PROV/DC)
  if (crit_is_defined_suffix(res, "-1") && length(found) > 0L) {
    crit_pass_suffix(res, "-1", evidence = found)
  }
  # -2 provenance via a formal provenance ontology -> Phase 2/3 (RDF)
  res$output <- list(provenance_elements = found)
}

#' FsF-R1.3-02D: data is in a community-recommended file format.
#' @noRd
eval_data_file_format <- function(ctx, res) {
  recommended <- c(names(ref_data("science_file_formats")),
                   names(ref_data("long_term_file_formats")),
                   names(ref_data("open_file_formats")))
  candidates <- tolower(as_chr(c(ctx$metadata_merged$object_format,
                                 ctx$metadata_merged$object_content_identifier)))
  hit <- candidates[candidates %in% recommended]
  if (crit_is_defined_suffix(res, "-1") && length(hit) > 0L) {
    crit_pass_suffix(res, "-1", evidence = hit)
    res$output <- list(recommended_formats = hit)
  }
}
