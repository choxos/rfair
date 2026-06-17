# Web App FRSM Evidence Scoring Audit

Date: 2026-06-17
Branch: `webapp`
Scope: Browser FRSM software scoring parity with the R engine

## Finding

The web app already harvested real software FAIR evidence from GitHub and
CodeMeta, but its browser-side FRSM evaluator only credited the first subtest
for several metrics:

- `FRSM-10-I1` credited only requirements evidence, not documented open formats
  or schema references.
- `FRSM-11-I1` credited API presence, but not open or machine-readable API
  evidence.
- `FRSM-15-R1.1` credited license presence, but not SPDX-recognized source
  license evidence.
- `FRSM-16-R1.1` credited license metadata presence, but not SPDX-recognized
  license metadata.

This caused the browser score to lag the R engine after the repository gained
CodeMeta and OpenAPI evidence.

## Implementation

- Added browser software signals for SPDX source and metadata licenses, open
  APIs, machine-readable APIs, documented data formats, open data formats, and
  schema references.
- Split open-format and schema-reference detection into explicit path patterns
  for OpenAPI/Swagger, JSON-LD, RDF, XML, CSV/TSV, Parquet, XSD, Proto, and
  GraphQL evidence.
- Normalized SPDX evidence from GitHub license fields and scalar or structured
  CodeMeta license objects.
- Updated `runFrsm()` to score the additional FRSM subtests.
- Added Vitest coverage for structured CodeMeta SPDX metadata and OpenAPI-based
  FRSM scoring.
- Bumped the web app version to `2.2.5`.

## Expected Result

The browser FRSM scores should now align with the R engine for GitHub software
repositories where the evidence is available through CORS-enabled GitHub APIs.
For `https://github.com/choxos/rfuji`, the expected scores are:

- `0.7_software`: 31/45, F 11/20, I 7/7, R 12/16.
- `0.7_software_cessda`: 27/42, F 10/18, I 6/6, R 10/15.

The DOI-gated FRSM-F4 criteria remain uncredited unless the software itself has
a real registry DOI.
