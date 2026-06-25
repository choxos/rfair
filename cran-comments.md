## Resubmission

This is a resubmission. In response to the CRAN review I have:

* Written the references in the DESCRIPTION in the `authors (year) <doi:...>`
  form (Chue Hong et al. (2022) <doi:10.15497/RDA00068>; Devaraju and Huber
  (2020) <doi:10.5281/zenodo.3775793>).
* Removed the commented-out example code (which referenced the unexported
  function `rtransparent::rt_data_code_pmc()`) from the `assess_data_code()`
  example; the example now calls only exported functions.
* Replaced `\dontrun{}` with `if (interactive()) {}` in the interactive-only
  `launch_rfair()` example.

## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new submission.

When optional `Suggests` such as `rdflib` and `wand` (which need the system
libraries `librdf` and `libmagic`) are not installed, the dependency step may
warn; these packages gate optional features only (RDF Turtle serialization,
libmagic content sniffing) and the package degrades gracefully without them.

## Notes for CRAN

* This is the first CRAN submission of rfair 0.1.0. The package grew from the
  earlier rfuji F-UJI API client but now reimplements the FAIR assessment engine
  natively in R, with no external server.
* The README carries the standard CRAN status badge; its package-page link
  (https://CRAN.R-project.org/package=rfair) is not live yet and resolves once
  the package is accepted.
* All examples that require network access are wrapped in `\donttest{}` or
  `\dontrun{}`. The test suite does not access the network (assessments in tests
  use `resolve = FALSE`).
* Optional, heavier capabilities (RDF graph parsing, headless rendering, the
  Shiny app, the Plumber API) live in `Suggests` and degrade gracefully when the
  corresponding package is not installed.
* Bundled reference data under `inst/extdata/` and `R/sysdata.rda` is derived
  from the F-UJI sources (MIT, © PANGAEA); the `data-raw/` scripts document how
  it is regenerated.
