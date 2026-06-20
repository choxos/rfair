# rfair current package audit

Date: 2026-06-19 EDT

Audited checkout: `/Users/choxos/Documents/GitHub/rfuji`

Final audited state:

- Branch: `main`
- Worktree: clean against `origin/main` before this audit file was added
- Commit: `9a19469e22c5f3713cd1af36ced05d920e18ff69`
- Commit subject: `Keep the version at 0.1.0`
- Package name: `rfair`
- Package version: `0.1.0`
- Current GitHub release observed: `rfair 0.1.0`, tag `v0.1.0`, published `2026-06-20T01:16:16Z`

## Verdict

The package is not 100% perfect and is not yet CRAN-quality clean.

The core R package test suite is in good shape: the full testthat harness passes, the package builds, vignettes rebuild successfully, and `R CMD check --as-cran --no-manual` reaches completion without errors or warnings. However, the check still reports two NOTEs, and one of those NOTEs exposes a serious release hygiene problem: the source package currently bundles nine old `rfuji_2.x.tar.gz` archives at the package root.

The strongest current blockers are:

1. The source tarball includes stale old package archives.
2. `R CMD check --as-cran --no-manual` has two NOTEs.
3. The OpenAPI contract still advertises version `2.3.5` while the package and release are `0.1.0`.
4. Local and remote branches named `fix/*` still exist despite the repository preference to avoid `fix` branch names.

No implementation was performed as part of this audit.

## Verification performed

| Check | Result |
| --- | --- |
| `git status --porcelain=v1 --branch` | Final clean state was `## main...origin/main` before this audit file was added. |
| `DESCRIPTION` version check | `Version: 0.1.0`. |
| GitHub release check | Latest release was `rfair 0.1.0`, tag `v0.1.0`. |
| `testthat::test_local()` | Passed: `FAIL 0`, `WARN 0`, `SKIP 1`, `PASS 292`. |
| Direct `tests/testthat/test-api-artifacts.R` run | Passed 9 tests, skipped 2 standalone checks because `{rfair}` was not installed in that invocation mode. |
| `R CMD build` | Built `rfair_0.1.0.tar.gz`. |
| Built tarball content probe | Found nine old `rfuji_2.x.tar.gz` files inside the built source package. |
| `R CMD check --as-cran --no-manual rfair_0.1.0.tar.gz` | Completed with `Status: 2 NOTEs`. |
| `git diff --check` | Passed. |
| CodeRabbit uncommitted review | Skipped with `No changes detected`, which is expected for a clean tree and is not an independent clean-code verdict. |

## Findings

### 1. Release-blocking source package contamination

Severity: high

The built source package includes nine old package archives:

```text
rfair/rfuji_2.2.0.tar.gz
rfair/rfuji_2.2.1.tar.gz
rfair/rfuji_2.2.2.tar.gz
rfair/rfuji_2.3.0.tar.gz
rfair/rfuji_2.3.1.tar.gz
rfair/rfuji_2.3.2.tar.gz
rfair/rfuji_2.3.3.tar.gz
rfair/rfuji_2.3.4.tar.gz
rfair/rfuji_2.3.5.tar.gz
```

This is not just cosmetic. These archives are bundled into `rfair_0.1.0.tar.gz` and trigger the `R CMD check` top-level file NOTE. They also bloat the distributed source package and ship stale historical artifacts from the old package name.

The likely direct cause is that `.Rbuildignore` excludes current `rfair_[0-9].*.tar.gz` build artifacts but does not exclude legacy `rfuji_[0-9].*.tar.gz` archives.

### 2. `R CMD check --as-cran` is not clean

Severity: high

The final source check status is:

```text
Status: 2 NOTEs
```

The two NOTEs are:

1. A moved README URL:

```text
https://github.com/choxos/rtransparent
Moved to https://github.com/choxos/rtransparency
Status: 301
```

2. Non-standard top-level files:

```text
rfuji_2.2.0.tar.gz
rfuji_2.2.1.tar.gz
rfuji_2.2.2.tar.gz
rfuji_2.3.0.tar.gz
rfuji_2.3.1.tar.gz
rfuji_2.3.2.tar.gz
rfuji_2.3.3.tar.gz
rfuji_2.3.4.tar.gz
rfuji_2.3.5.tar.gz
```

A package can sometimes be acceptable with unavoidable NOTEs, but these are avoidable. Under a strict audit standard, this is not release clean.

### 3. OpenAPI metadata is stale after the package rename and version reset

Severity: medium-high

`inst/openapi/rfair-openapi.yaml` still uses the old API/package version in the public contract:

```yaml
info:
  version: 2.3.5
```

The health endpoint example also still returns:

```yaml
version:
  example: "2.3.5"
```

That conflicts with the final audited package version `0.1.0` and the latest release tag `v0.1.0`. This can mislead API clients, generated clients, documentation readers, and anyone using the OpenAPI document as authoritative machine-readable metadata.

### 4. Branch hygiene still violates the repository preference

Severity: medium

Local and remote branch refs containing `fix` still exist:

```text
fix/pkgdown-articles-navbar
fix/repo-rename-urls
fix/stay-on-0.1.0
origin/fix/pkgdown-articles-navbar
origin/fix/repo-rename-urls
origin/fix/stay-on-0.1.0
```

This audit did not remove them because the requested scope was audit-only. Still, this is a current repository hygiene issue given the explicit preference to avoid branch names containing `fix` or `codex` in this repository.

### 5. The companion web app was not present in the local checkout

Severity: medium-low

The current package README and pkgdown configuration reference a web app at:

```text
https://choxos.github.io/rfair/app/
```

The current local checkout does not contain a `webapp/` directory or a separate local webapp worktree. There is an `origin/webapp` branch, but it was not present as a local worktree in the audited checkout.

Because this audit was requested for the package, this is not counted as a package test failure. It is still a verification gap for the full project, since the package advertises the app and prior work has treated web-app behavior as part of the project surface.

### 6. Some standalone test-file invocations are brittle

Severity: low

The full package test suite passes under `testthat::test_local()`, which is the relevant package-harness result. However, direct standalone `test_file()` invocation is less robust:

- `tests/testthat/test-api-artifacts.R` skips two package-dependent tests when `{rfair}` is not installed.
- Other test files may require package functions to be loaded through the normal package harness.

This is not a release blocker, but it makes ad hoc forensic testing less reliable.

## Positive findings

The current package has several important strengths:

- Full package tests pass with no failures.
- `R CMD check` completes with no errors and no warnings.
- Vignettes rebuild during source check.
- The package rename to `rfair` is mostly reflected in `DESCRIPTION`, `CITATION.cff`, `codemeta.json`, `inst/CITATION`, README, pkgdown metadata, API file naming, and generated documentation.
- `git diff --check` reports no whitespace errors.
- The final audited worktree was clean before this audit artifact was added.
- The package contains a substantial test surface for API artifacts, fairness scoring, metric behavior, data validation, and compatibility behavior.

## Recommended next actions

No changes were made during this audit, but the next implementation pass should prioritize:

1. Exclude or remove legacy root-level `rfuji_*.tar.gz` archives so future `R CMD build` outputs are not contaminated.
2. Fix the moved README URL from `choxos/rtransparent` to `choxos/rtransparency`.
3. Update `inst/openapi/rfair-openapi.yaml` to report `0.1.0` consistently, or generate it from package metadata so this cannot drift again.
4. Remove or rename local and remote `fix/*` branches in accordance with the repository branch-name preference.
5. Re-run `R CMD build`, inspect the built tarball contents, and re-run `R CMD check --as-cran --no-manual` until the package is clean or only unavoidable NOTEs remain.
6. If the advertised web app is in scope for release quality, check out the webapp surface locally and run a separate app audit.

## Final strict assessment

Current status: not perfect.

Release readiness: close, but blocked by avoidable source-package and metadata issues.

CRAN-quality readiness: not yet, because `R CMD check --as-cran` has avoidable NOTEs.

Project-surface readiness: incomplete, because the advertised web app was not present in the local package checkout and therefore was not audited in this round.
