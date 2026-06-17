# FRSM FAIRness Improvement Audit

Date: 2026-06-16
Repository: <https://github.com/choxos/rfuji>

## Baseline

The repository scored low on the FRSM software metric sets before this change:

- `0.7_software`: FAIR 17/45, with Findability 6/20 and Interoperability 1/7.
- `0.7_software_cessda`: FAIR 16/42, with Findability 6/18 and Interoperability 1/6.

The low scores were caused by missing machine-actionable software metadata rather
than by missing tests or source availability. The detector found a GitHub URL,
README, license, CI, requirements, tests, contributors, and version tags, but no
repository-level citation metadata, no CodeMeta record, and no OpenAPI/API
contract.

## Implemented Improvements

- Added `CITATION.cff` with authors, ORCID, repository URL, license, version,
  abstract, and keywords.
- Added `codemeta.json` with CodeMeta software metadata: repository identifier,
  homepage, issue tracker, license, version, runtime requirements, authors,
  contributor organization, CI link, and upstream F-UJI provenance.
- Added `inst/plumber/rfuji-api.R`, an installable Plumber scaffold exposing
  `/health`, `/metric-versions`, and `/assess`.
- Added `inst/openapi/rfuji-openapi.yaml`, an OpenAPI 3.1 contract for the API.
- Added package tests to ensure the OpenAPI and Plumber artifacts are packaged.
- Bumped the R package version from `2.2.2` to `2.3.0` because this adds a
  documented API surface and new machine-readable metadata.

## Verification

- `jsonlite::validate("codemeta.json")`: pass.
- `yaml::read_yaml("CITATION.cff")`: pass.
- `yaml::read_yaml("inst/openapi/rfuji-openapi.yaml")`: pass.
- `testthat::test_local()`: pass, with one expected Shiny optional-dependency
  skip.
- `R CMD build .`: pass, built `rfuji_2.3.0.tar.gz`.
- `R CMD check --as-cran --no-manual rfuji_2.3.0.tar.gz`: 0 errors,
  0 warnings, 1 NOTE. The NOTE is the CRAN incoming `New submission` note.
- `coderabbit review --agent -t uncommitted`: initially found two issues; both
  were fixed. Re-run completed with 0 findings.

## Expected FRSM Effect

The GitHub FRSM harvester reads the repository default branch, so the final
remote score can only be measured after merge. A local simulation using the same
FRSM evaluator signals predicts:

- `0.7_software`: FAIR 25/45, Findability 11/20, Interoperability 3/7.
- `0.7_software_cessda`: FAIR 22/42, Findability 10/18,
  Interoperability 2/6.

The expected gains come from citation metadata, CodeMeta metadata, metadata
license exposure, and OpenAPI/API discoverability.

## Remaining Honest Limitation

No real archived software DOI for `choxos/rfuji` was present in the local repo or
GitHub release metadata. I did not fabricate a DOI. Full FRSM Findability still
requires minting an actual software DOI, for example via Zenodo-GitHub archival
for the next release, and then adding that DOI to `CITATION.cff` and
`codemeta.json`.
