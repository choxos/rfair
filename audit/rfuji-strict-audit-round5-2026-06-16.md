# rfuji Strict Audit - Round 5 Legacy Webapp Options - 2026-06-16

## Verdict

Round 5 found a real user-visible browser bug: the oldest bundled FsF metric
sets, `0.2` and `0.3`, loaded in the webapp but scored every example as zero.
The root cause was not harvesting. The browser harvested DataCite metadata, but
those legacy metric files do not contain per-test `metric_tests`, and the
browser scorer only awarded points through test-level matches.

The same structural issue also existed in the R engine for `0.2` and `0.3`, so
the implementation fixes both package and browser scoring.

## Current State Audited

- Package branch audited: `main` after merged PR #10.
- Webapp branch audited: `webapp` after merged PR #11.
- Prior audit artifact reviewed:
  `audit/rfuji-strict-audit-round4-2026-06-16.md`.
- Scope: webapp metric-version selector behavior, metadata-service option
  coverage, legacy metric scoring, and the matching R scoring path.

## Findings Fixed

### High - FsF v0.2 and v0.3 scored zero in the webapp

Reproduction before the fix:

```text
0.3 Zenodo: FAIR 0/21 = 0%, pass 0/14
0.2 Zenodo: FAIR 0/21 = 0%, pass 0/14
```

The metric definitions for `0.2` and `0.3` are metric-level specifications:
they have `total_score`, but no `metric_tests`. The webapp engine therefore had
no test identifier to pass even when an evaluator condition was true.

Fix implemented:

- Browser scorer now awards the metric total once when a no-test legacy metric
  satisfies an evaluator condition.
- R criterium engine now uses the same metric-level fallback.
- Added regressions in R and Vitest.

After the fix, the webapp example sweep scores the oldest versions:

```text
0.3 Zenodo: FAIR 18/21 = 85.7%, pass 11/14
0.2 Zenodo: FAIR 17/21 = 81%, pass 11/14
```

### High - Webapp metadata-service selector exposed options with no fetch path

The webapp UI exposed OAI-PMH, OGC CSW, SPARQL, DataCite, Crossref,
Signposting, typed links, RO-Crate, CKAN, DCAT, schema.org JSON-LD, and generic
metadata documents, but only DCAT, schema.org HTML JSON-LD, and CKAN had
service-specific handling.

Fix implemented:

- Added browser fetch/validation paths for every exposed metadata service type.
- Kept the round-4 safety rule: request-only endpoints are stored as
  `metadata_service_request` and do not score.
- `metadata_service` and `metadata_service_fetch` evidence are recorded only
  after a successful fetch/validation path.
- Added a Vitest regression that iterates every exposed
  `METADATA_SERVICE_TYPES` option.
- Improved schema.org handling so raw `application/ld+json` documents work, not
  only HTML pages containing a JSON-LD script tag.

## Verification

Passing local gates after the fix:

- `Rscript -e 'pkgload::load_all(); testthat::test_file("tests/testthat/test-metrics-scorer.R")'`:
  58 passed.
- `Rscript -e 'devtools::test()'`: 204 passed, 1 expected Shiny skip.
- `R CMD build .`: built `rfuji_2.2.2.tar.gz`.
- `R CMD check --as-cran --no-manual rfuji_2.2.2.tar.gz`: 0 errors,
  0 warnings, 1 NOTE.
- `npm test` in `webapp`: 13 passed.
- `npm run typecheck` in `webapp`: passed.
- `npm run build` in `webapp`: passed.
- `coderabbit review --agent -t uncommitted`: 0 package findings.
- `coderabbit review --agent -t uncommitted --dir webapp`: initially found
  the CKAN mock did not exercise the CKAN JSON response path; after fixing the
  test mock, rerun reported 0 findings.
- Browser engine legacy sweep:
  - `0.8`: 16/26.
  - `0.6a2a`: 5.5/8.
  - `0.5`: 14/24.
  - `0.5ssv2`: 15/24.
  - `0.5ss`: 6/7.
  - `0.5env`: 14/24.
  - `0.4`: 14/25.
  - `0.3`: 18/21.
  - `0.2`: 17/21.

The only remaining `R CMD check` NOTE is CRAN incoming:

```text
Maintainer: 'Ahmad Sofi-Mahmudi <a.sofimahmudi@gmail.com>'
New submission
```

## Remaining Risks

### Medium - Service-specific harvesting is still lightweight

All webapp service options now do something concrete and validated, but the
browser remains constrained by CORS and by lightweight client-side parsing. The
new handlers should be treated as practical browser support, not full upstream
F-UJI service parity for OAI-PMH, CSW, SPARQL, or repository-specific APIs.

### Low - No browser UI smoke test yet

Vitest covers engine behavior, option coverage, and legacy scoring. The webapp
still lacks a Playwright-style runtime smoke test for clicking every metric
version in the built UI.

## Bottom Line

The legacy metric selector is now real for every exposed FsF version: `0.2` and
`0.3` no longer show all-zero scores for normal examples. The webapp metadata
service selector also no longer exposes dead options. The implementation still
does not claim full upstream F-UJI harvesting parity, but the UI options are no
longer misleading no-ops.
