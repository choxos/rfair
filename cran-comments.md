## R CMD check results

0 errors | 0 warnings | 0 notes, when all `Suggests` are installed.

Note: a strict check fails at the dependency step if optional `Suggests` such as
`rdflib` and `wand` (which need the system libraries `librdf` and `libmagic`)
are not installed. With the full `Suggests` stack present, the check is clean.
These packages gate optional features only (RDF Turtle serialization, libmagic
content sniffing) and the package degrades gracefully without them.

## Notes for CRAN

* This is a major rewrite of the package (2.0.0). The previous versions were an
  auto-generated HTTP client for an external F-UJI server; this version
  re-implements the FAIR assessment natively in R.
* All examples that require network access are wrapped in `\donttest{}` or
  `\dontrun{}`. The test suite does not access the network (assessments in tests
  use `resolve = FALSE`).
* Optional, heavier capabilities (RDF graph parsing, headless rendering, the
  Shiny app, the Plumber API) live in `Suggests` and degrade gracefully when the
  corresponding package is not installed.
* Bundled reference data under `inst/extdata/` and `R/sysdata.rda` is derived
  from the F-UJI sources (MIT, © PANGAEA); the `data-raw/` scripts document how
  it is regenerated.
