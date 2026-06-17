# API Boolean Validation Audit - 2026-06-17

## Scope

Fresh audit of the merged `main` and `webapp` worktrees after the 2.3.4 API
validation release. This round focused on the remaining `/assess` request
parsing behavior in the Plumber scaffold.

## Finding

The API now validated enum-like parameters, but boolean query parameters still
accepted arbitrary non-empty strings. For example, `use_datacite=not-bool`,
`resolve=not-bool`, or `use_headless=not-bool` were parsed as `FALSE` instead
of returning the documented client-error response.

That is a user-visible API bug: a typo can silently disable DataCite lookup,
identifier resolution, or headless rendering.

## Implementation

- Hardened the Plumber boolean parser to accept only explicit true/false forms:
  `true`, `false`, `1`, `0`, `yes`, `no`, `y`, `n`, `t`, and `f`.
- Added structured `400` responses for invalid `use_datacite`, `resolve`, and
  `use_headless` values.
- Added direct Plumber route tests for invalid boolean values and accepted
  false-like aliases.
- Bumped the R package patch version from `2.3.4` to `2.3.5`.

## Verification

Executed checks:

- `Rscript -e "testthat::test_file('tests/testthat/test-api-artifacts.R')"`:
  33 passed.
- `Rscript -e "testthat::test_local()"`: 251 passed, 1 expected skip.
- `npm test` in `webapp`: 16 passed.
- `npm run build` in `webapp`: production build completed.
- `R CMD build --no-build-vignettes .`: built `rfuji_2.3.5.tar.gz`.
- Tarball content probe: no bundled `webapp`, `comments`, `audit`, `.git`,
  `node_modules`, or `.DS_Store` paths.
- `R CMD check --no-manual --ignore-vignettes rfuji_2.3.5.tar.gz`: OK.
- `git diff --check`: OK.
- CodeRabbit review against `main`: 0 findings.

## Branch Hygiene

The implementation branch is `api-boolean-validation`. No `codex` or `fix`
branch names were created.
