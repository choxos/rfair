# rfuji Strict Audit - Round 4 Post-Metric-Options - 2026-06-16

## Verdict

The merged v2.2.0 metric-version work is broadly sound: all bundled FsF/FRSM
metric files load, legacy metric identifiers score through compatibility
aliases, the webapp builds with the expanded metric selector, and strict package
checks pass with only the expected CRAN incoming "New submission" NOTE.

One correctness issue was found and fixed during this round: a user-supplied
metadata service endpoint could be treated as scoring evidence before any
metadata service was actually harvested or validated.

## Current State Audited

- Package branch audited: `main` at merged PR #8.
- Webapp branch audited: `webapp` at merged PR #9.
- Prior audit artifact reviewed: `audit/rfuji-strict-audit-round3-2026-06-16.md`.
- Scope: current package code, metric compatibility layer, R/Shiny metadata
  service options, browser metadata-service handling, and verification gates.

## Finding Fixed

### High - Metadata service requests were being counted as evidence

The new metadata service option recorded an endpoint requested by the user, but
two scoring paths treated that request as if the service itself had already been
harvested:

- In R, `eval_data_content_metadata()` used `ctx$metadata_service_endpoint` to
  pass legacy `R1-01MD` service-endpoint/data-content criteria.
- In the browser, `harvest()` immediately pushed a `user_supplied_endpoint`
  source and `metadata_service` metadata before any supported fetch succeeded.
  Since the engine uses `sources` and `metadata_service` as evidence, this could
  inflate F2/F4/R1 scores for a dead, mistyped, CORS-blocked, or unsupported
  endpoint.

Fix implemented:

- R now only counts service evidence from harvested metadata
  (`metadata_merged$metadata_service`), not from the request field.
- Browser harvesting now stores unvalidated endpoint settings under
  `metadata_service_request` and does not add a scoring source.
- Browser `metadata_service` and `metadata_service_fetch` sources are only added
  after a supported fetch succeeds for DCAT, schema.org JSON-LD, or CKAN.
- Added R and Vitest regressions for request-only service endpoints.

## Verification

Passing local gates after the fix:

- `Rscript -e 'pkgload::load_all(); testthat::test_file("tests/testthat/test-assess.R")'`:
  23 passed.
- `Rscript -e 'devtools::test()'`: 198 passed, 1 expected Shiny skip.
- `R CMD build .`: built `rfuji_2.2.1.tar.gz`.
- `R CMD check --as-cran --no-manual rfuji_2.2.1.tar.gz`: 0 errors,
  0 warnings, 1 NOTE.
- `npm --prefix webapp test`: 11 passed.
- `npm --prefix webapp run typecheck`: passed.
- `npm --prefix webapp run build`: passed.
- `coderabbit review --agent -t uncommitted`: 0 package findings after the
  scoring fix.
- `coderabbit review --agent -t uncommitted --dir webapp`: initially reported
  two test-mock issues; after hardening the mocks, rerun reported 0 findings.
  A later post-version-bump rerun was rate-limited, and the version bump itself
  only changed package metadata and this audit report.

The only remaining `R CMD check` NOTE is CRAN incoming:

```text
Maintainer: 'Ahmad Sofi-Mahmudi <a.sofimahmudi@gmail.com>'
New submission
```

## Remaining Risks

### Medium - Metadata service harvesting is still partial

The UI exposes OAI-PMH, OGC CSW, SPARQL, DCAT, schema.org JSON-LD, DataCite,
Crossref, Signposting, typed links, RO-Crate, CKAN, and other metadata document
types. The browser can only opportunistically fetch CORS-allowed service
documents, and the R engine still does not implement full OAI-PMH, CSW, or
SPARQL service harvesting. This is now safer because request-only endpoints do
not inflate scores, but feature completeness is still below upstream F-UJI.

### Low - Runtime UI smoke coverage remains limited

The webapp has unit, type, and production-build coverage. The Shiny app has
parse/dependency tests and package-level coverage. Neither app has an automated
browser/runtime smoke test that exercises the full interactive UI.

### Low - Upstream F-UJI conformance remains local-reference dependent

The local parity and package tests pass, and GitHub Actions passed the package
matrix for PR #8. Full upstream F-UJI service conformance still depends on a
running pinned upstream reference server.

## Bottom Line

The round-4 audit found one real scoring-integrity bug and fixed it. After the
fix, request options remain reproducible metadata, but only harvested metadata
services can contribute scoring evidence. The repo is not "100% perfect" because
full metadata-service harvesting and runtime UI smoke tests remain open, but the
new metric-version/options work is materially safer than the merged v2.2.0 state.
