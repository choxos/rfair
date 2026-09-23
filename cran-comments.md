## Submission

This is an update of rfair from 0.1.0 to 0.2.0. It fixes scoring defects
(Handle detection, unresolved identifiers, data link and RDF graph handling),
adds metadata sources (CSL JSON for all DOI registration agencies, GitLab and
Codeberg repositories, repository file APIs, microdata and RDFa), and adds
`fair_recommendations()`, `fair_compare()`, and `frsm_agreement()`. NEWS.md
lists the changes.

## Test environments

* local macOS (aarch64-apple-darwin), R 4.6.0, with all Suggests installed
* GitHub Actions: macOS (R release), Windows (R release), Ubuntu (R release
  and R devel)
* win-builder: R-devel (2026-09-21 r90579 ucrt)

## R CMD check results

0 errors | 0 warnings | 0 notes

## Notes for CRAN

* Examples that need network access are wrapped in `\donttest{}`. The tests do
  not access the network: HTTP responses come from bundled fixtures through
  `httr2::local_mocked_responses()`, and the one live smoke test is skipped on
  CRAN.
* Optional features (RDF graph parsing and Turtle output via `rdflib` and
  `jsonld`, headless rendering via `chromote`, the Shiny app, the Plumber API)
  live in `Suggests` and degrade gracefully when those packages are missing.
* `assess_fair_batch(workers = n)` uses `parallel::mclapply()`; the examples
  and tests run serially.
* Bundled reference data under `inst/extdata/` and `R/sysdata.rda` is derived
  from the F-UJI sources (MIT, (c) PANGAEA); the `data-raw/` scripts document
  how it is regenerated.
