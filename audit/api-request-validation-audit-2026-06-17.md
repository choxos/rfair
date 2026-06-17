# API Request Validation Audit - 2026-06-17

## Scope

Fresh audit of the merged `main` and `webapp` worktrees after the 2.3.3
release. This round focused on user-facing API correctness, option parity, and
release hygiene after confirming the core R and webapp test suites were green.

## Finding

The OpenAPI contract documented a `400` response for invalid `/assess` request
parameters, but the Plumber scaffold only handled a missing `id`. Invalid
`metric_version` and `metadata_service_type` values could continue into the
assessment call and become unstructured server errors.

That is externally visible API behavior: clients should get a deterministic
client-error response with the invalid parameter and allowed values.

## Implementation

- Added Plumber-side validation for `metric_version` against
  `rfuji_metric_versions()`.
- Added Plumber-side validation for every supported metadata service type:
  OAI-PMH, OGC CSW, SPARQL, DCAT, schema.org JSON-LD, DataCite, Crossref,
  Signposting, typed links, RO-Crate, CKAN, and other metadata documents.
- Added structured `400` responses with `error`, `parameter`, and `allowed`
  fields where appropriate.
- Added OpenAPI enum documentation for `metric_version`.
- Added tests that parse the packaged Plumber scaffold and assert invalid enum
  parameters return `400`.
- Bumped the R package patch version from `2.3.3` to `2.3.4`.

## Verification

Executed checks:

- `Rscript -e "testthat::test_file('tests/testthat/test-api-artifacts.R')"`:
  15 passed.
- `Rscript -e "testthat::test_local()"`: 233 passed, 1 expected skip.
- `npm test` in `webapp`: 16 passed.
- `npm run build` in `webapp`: production build completed.
- `R CMD build --no-build-vignettes .`: built `rfuji_2.3.4.tar.gz`.
- Tarball content probe: no bundled `webapp`, `comments`, `audit`, `.git`,
  `node_modules`, or `.DS_Store` paths.
- `R CMD check --no-manual --ignore-vignettes rfuji_2.3.4.tar.gz`: OK.
- `git diff --check`: OK.
- CodeRabbit review against `main`: 0 findings.

## Branch Hygiene

The implementation branch is `api-request-validation`. No `codex` or `fix`
branch names were created.
