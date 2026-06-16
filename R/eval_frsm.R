# Evaluators for the FRSM (FAIR for Research Software) metrics
# (metrics_v0.7_software), scoring from the software signals harvested by
# collect_github() into ctx$software. Scoring is heuristic: a test passes when a
# corresponding signal is detected in the repository (license file, tests, CI,
# requirements, registry DOI, version, contributors, ...).

.sw <- function(ctx) ctx$software %||% list()
.p <- function(res, n, ev = NULL) crit_pass(res, paste0(res$metric_identifier, "-", n), evidence = ev)
.def <- function(res, n) crit_is_defined(res, paste0(res$metric_identifier, "-", n))
.semver <- function(v) is_nonempty_string(v) && grepl("^v?\\d+\\.\\d+", v)

#' @noRd
eval_frsm_software_identifier <- function(ctx, res) {       # FRSM-01-F1
  sw <- .sw(ctx)
  if (is_nonempty_string(sw$identifier) && .def(res, 1)) .p(res, 1, sw$identifier)
  if (is_nonempty_string(sw$registry_doi)) { if (.def(res, 2)) .p(res, 2); if (.def(res, 3)) .p(res, 3) }
}
#' @noRd
eval_frsm_component_identifiers <- function(ctx, res) {     # FRSM-02-F1.1
  sw <- .sw(ctx)
  if (isTRUE(sw$has_citation) && .def(res, 1)) .p(res, 1)   # components described in codemeta/CFF
}
#' @noRd
eval_frsm_version_identifier <- function(ctx, res) {        # FRSM-03-F1.2
  sw <- .sw(ctx)
  if (is_nonempty_string(sw$version) && .def(res, 1)) .p(res, 1, sw$version)
  if (.semver(sw$version) && .def(res, 2)) .p(res, 2)
  if (isTRUE(sw$has_citation) && .def(res, 3)) .p(res, 3)
}
#' @noRd
eval_frsm_descriptive_metadata <- function(ctx, res) {      # FRSM-04-F2
  sw <- .sw(ctx)
  if (is_nonempty_string(sw$name) && is_nonempty_string(sw$description) && .def(res, 1)) .p(res, 1)
  if (isTRUE(sw$has_readme) && .def(res, 2)) .p(res, 2)
  if (isTRUE(sw$has_citation) && .def(res, 3)) .p(res, 3)
}
#' @noRd
eval_frsm_development_metadata <- function(ctx, res) {      # FRSM-05-R1
  sw <- .sw(ctx)
  if (isTRUE(sw$has_readme) && .def(res, 1)) .p(res, 1)
  if (isTRUE(sw$has_ci) && .def(res, 2)) .p(res, 2)
  if (isTRUE(sw$has_requirements) && .def(res, 3)) .p(res, 3)
}
#' @noRd
eval_frsm_contributor_metadata <- function(ctx, res) {      # FRSM-06-F2
  sw <- .sw(ctx)
  if (isTRUE(sw$contributors > 0) && .def(res, 1)) .p(res, 1)
  if (isTRUE(sw$has_citation) && .def(res, 2)) .p(res, 2)
}
#' @noRd
eval_frsm_identifier_in_metadata <- function(ctx, res) {    # FRSM-07-F3
  sw <- .sw(ctx)
  if (isTRUE(sw$has_citation) && .def(res, 1)) .p(res, 1)
  if (is_nonempty_string(sw$registry_doi) && .def(res, 2)) .p(res, 2)
}
#' @noRd
eval_frsm_persistent_metadata <- function(ctx, res) {       # FRSM-08-F4
  sw <- .sw(ctx)
  if (is_nonempty_string(sw$registry_doi)) { if (.def(res, 1)) .p(res, 1); if (.def(res, 2)) .p(res, 2) }
}
#' @noRd
eval_frsm_standard_protocol_repo <- function(ctx, res) {    # FRSM-09-A1
  sw <- .sw(ctx)
  if (is_nonempty_string(sw$identifier) && grepl("^https", sw$identifier) && .def(res, 1)) .p(res, 1)
}
#' @noRd
eval_frsm_open_formats <- function(ctx, res) {              # FRSM-10-I1
  sw <- .sw(ctx)
  if (isTRUE(sw$has_requirements) && .def(res, 1)) .p(res, 1)  # declared deps use open formats
}
#' @noRd
eval_frsm_open_api <- function(ctx, res) {                  # FRSM-11-I1
  sw <- .sw(ctx)
  if (isTRUE(sw$has_api) && .def(res, 1)) .p(res, 1)
}
#' @noRd
eval_frsm_references <- function(ctx, res) {                # FRSM-12-I2
  sw <- .sw(ctx)
  if (isTRUE(sw$has_citation) && .def(res, 1)) .p(res, 1)
}
#' @noRd
eval_frsm_requirements <- function(ctx, res) {              # FRSM-13-R1
  sw <- .sw(ctx)
  if (isTRUE(sw$has_requirements)) { if (.def(res, 1)) .p(res, 1); if (.def(res, 2)) .p(res, 2) }
}
#' @noRd
eval_frsm_test_cases <- function(ctx, res) {                # FRSM-14-R1
  sw <- .sw(ctx)
  if (isTRUE(sw$has_tests) && .def(res, 1)) .p(res, 1)
  if (isTRUE(sw$has_ci) && .def(res, 2)) .p(res, 2)
}
#' @noRd
eval_frsm_source_license <- function(ctx, res) {            # FRSM-15-R1.1
  sw <- .sw(ctx)
  if (isTRUE(sw$has_license) && .def(res, 1)) .p(res, 1)
}
#' @noRd
eval_frsm_metadata_license <- function(ctx, res) {          # FRSM-16-R1.1
  # reuse the data-license evaluator's logic via the merged license field
  if (!is.null(ctx$metadata_merged$license) && .def(res, 1)) .p(res, 1)
}
#' @noRd
eval_frsm_provenance <- function(ctx, res) {                # FRSM-17-R1.2
  sw <- .sw(ctx)
  if ((isTRUE(sw$contributors > 0) || is_nonempty_string(sw$version)) && .def(res, 1)) .p(res, 1)
}

#' Register all FRSM software evaluators.
#' @noRd
register_frsm_evaluators <- function() {
  register_evaluator("FRSM-01-F1",   eval_frsm_software_identifier)
  register_evaluator("FRSM-02-F1.1", eval_frsm_component_identifiers)
  register_evaluator("FRSM-03-F1.2", eval_frsm_version_identifier)
  register_evaluator("FRSM-04-F2",   eval_frsm_descriptive_metadata)
  register_evaluator("FRSM-05-R1",   eval_frsm_development_metadata)
  register_evaluator("FRSM-06-F2",   eval_frsm_contributor_metadata)
  register_evaluator("FRSM-07-F3",   eval_frsm_identifier_in_metadata)
  register_evaluator("FRSM-08-F4",   eval_frsm_persistent_metadata)
  register_evaluator("FRSM-09-A1",   eval_frsm_standard_protocol_repo)
  register_evaluator("FRSM-10-I1",   eval_frsm_open_formats)
  register_evaluator("FRSM-11-I1",   eval_frsm_open_api)
  register_evaluator("FRSM-12-I2",   eval_frsm_references)
  register_evaluator("FRSM-13-R1",   eval_frsm_requirements)
  register_evaluator("FRSM-14-R1",   eval_frsm_test_cases)
  register_evaluator("FRSM-15-R1.1", eval_frsm_source_license)
  register_evaluator("FRSM-16-R1.1", eval_frsm_metadata_license)
  register_evaluator("FRSM-17-R1.2", eval_frsm_provenance)
}
