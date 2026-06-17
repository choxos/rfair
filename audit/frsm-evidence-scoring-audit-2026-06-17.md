# FRSM Evidence Scoring Audit

Date: 2026-06-17
Branch: `main`
Scope: FRSM software scoring, GitHub software evidence, package FAIR metadata

## Finding

After the prior metadata pass, rfuji had real machine-readable evidence that the
R FRSM scorer was still treating as only partial evidence:

- `inst/openapi/rfuji-openapi.yaml` documents the assessment API and provides a
  machine-readable interface definition.
- `codemeta.json` exposes a SPDX license URL.
- The GitHub repository and OpenAPI file are public, so the API contract is open
  and machine-readable.

Baseline on `main`:

- `0.7_software`: 25/45, I 3/7, R 10/16.
- `0.7_software_cessda`: 22/42, I 2/6, R 9/15.

## Implementation

- Added GitHub software signals for SPDX license evidence, metadata SPDX
  license evidence, documented open data formats, schema references, open APIs,
  and machine-readable API definitions.
- Normalized SPDX evidence from GitHub API license objects, scalar CodeMeta
  license values, and structured CodeMeta license objects.
- Updated FRSM evaluators to credit those sub-tests when the evidence exists.
- Added regression coverage for full OpenAPI and SPDX metadata scoring.
- Bumped the R package version to `2.3.1` across DESCRIPTION, CFF, CodeMeta,
  R citation metadata, and OpenAPI metadata.

## Result

Post-change live score smoke against `https://github.com/choxos/rfuji`:

- `0.7_software`: 31/45, F 11/20, I 7/7, R 12/16.
- `0.7_software_cessda`: 27/42, F 10/18, I 6/6, R 10/15.

Verification:

- `testthat::test_file("tests/testthat/test-frsm.R")`: pass.
- `testthat::test_local()`: pass, with one expected Shiny missing-deps path
  skipped because the UI dependencies are installed.
- JSON/YAML syntax: `codemeta.json`, `CITATION.cff`, and
  `inst/openapi/rfuji-openapi.yaml` passed parser checks.
- `R CMD check --as-cran --no-manual rfuji_2.3.1.tar.gz`: 0 errors,
  0 warnings, 1 NOTE (`New submission`).

## Limitation

The DOI-gated FRSM-F4 criteria remain uncredited. This audit did not fabricate
a DOI or count upstream F-UJI DOIs as rfuji identifiers.
