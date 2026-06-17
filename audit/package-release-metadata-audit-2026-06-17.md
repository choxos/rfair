# Package Release Metadata Audit - 2026-06-17

## Scope

Fresh post-merge audit of the current `main` and `webapp` worktrees, with
emphasis on release readiness, FAIR-facing metadata, option parity, and branch
hygiene.

## Finding

`R CMD check --no-manual --no-build-vignettes .` failed before test execution:

```text
Required fields missing or empty:
  'Author' 'Maintainer'
```

Although `Authors@R` was present, the active R 4.6 check environment did not
derive the legacy `Author` and `Maintainer` fields. That makes the package
release-blocked and also weakens machine-readable package metadata for users
and archive tooling that still read those DCF fields directly.

## Implementation

- Added explicit `Author` and `Maintainer` fields while preserving `Authors@R`.
- Bumped the R package patch version from `2.3.2` to `2.3.3`.
- Updated release-facing metadata in `CITATION.cff`, `codemeta.json`,
  `inst/CITATION`, and the OpenAPI contract.

## Verification

Executed checks:

- `Rscript -e "testthat::test_local()"`: 223 passed, 1 expected skip.
- `R CMD build --no-build-vignettes .`: built `rfuji_2.3.3.tar.gz`.
- Tarball content probe: no bundled `webapp`, `comments`, `audit`, `.git`,
  `node_modules`, or `.DS_Store` paths.
- `R CMD check --no-manual --ignore-vignettes rfuji_2.3.3.tar.gz`: OK.
- `git diff --check`: OK.

The raw-check command `R CMD check --no-manual --no-build-vignettes .` was used
as the initial probe and exposed the missing `Author`/`Maintainer` fields. It
was not used as the final release verdict because checking the raw checkout does
not apply `.Rbuildignore`, so local worktrees and reference folders are visible
to the checker. The built tarball path above is the source-package verification
used for this round.

## Branch Hygiene

The implementation branch is `package-release-metadata`. No `codex` or `fix`
branch names were created.
