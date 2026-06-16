# Package load hooks: register metric evaluators once all functions are defined.

.onAttach <- function(libname, pkgname) {
  version <- utils::packageVersion(pkgname)
  packageStartupMessage(sprintf(
    paste0("rfuji %s: native R FAIR assessment of research data objects ",
           "(F-UJI metrics).\n  Get started with assess_fair() or launch_rfuji().",
           " GitHub: https://github.com/choxos/rfuji"),
    version))
  invisible()
}

.onLoad <- function(libname, pkgname) {
  # Findable
  register_evaluator("FsF-F1-01MD",  eval_unique_identifier_metadata)
  register_evaluator("FsF-F1-02MD",  eval_persistent_identifier)
  register_evaluator("FsF-F2-01M",   eval_core_metadata)
  register_evaluator("FsF-F3-01M",   eval_data_identifier_included)
  register_evaluator("FsF-F4-01M",   eval_searchable)
  # Accessible
  register_evaluator("FsF-A1-01M",   eval_data_access_level)
  register_evaluator("FsF-A1-02MD",  eval_retrievable)
  register_evaluator("FsF-A1.1-01MD", eval_standard_protocol)
  register_evaluator("FsF-A1.2-01MD", eval_protocol_auth)
  # Interoperable
  register_evaluator("FsF-I1-01M",   eval_formal_metadata)
  register_evaluator("FsF-I2-01M",   eval_semantic_vocabulary)
  register_evaluator("FsF-I3-01M",   eval_related_resources)
  # Reusable
  register_evaluator("FsF-R1-01M",   eval_data_content_metadata)
  register_evaluator("FsF-R1.1-01M", eval_license)
  register_evaluator("FsF-R1.2-01M", eval_data_provenance)
  register_evaluator("FsF-R1.3-01M", eval_community_metadata)
  register_evaluator("FsF-R1.3-02D", eval_data_file_format)
  # FRSM software metrics (metrics_v0.7_software)
  register_frsm_evaluators()
  invisible()
}
