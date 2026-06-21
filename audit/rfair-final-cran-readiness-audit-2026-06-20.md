# rfair final CRAN-readiness audit

Date: 2026-06-20 EDT

Audited checkout: `/Users/choxos/Documents/GitHub/rfuji`

Final audited state:

- Branch: `main`
- Commit: `f541662c69ef769093446c1498b4ab265068c4bb`
- Commit subject: `Surface the interactive app right after installation (#39)`
- Package: `rfair`
- Version in `DESCRIPTION`: `0.1.0`
- Latest GitHub release observed: `rfair 0.1.0`, tag `v0.1.0`, published `2026-06-20T14:36:01Z`
- Local worktree before this audit file was added: clean against `origin/main`

## Verdict

Not ready to submit to CRAN exactly as-is.

The R package itself is very close: a clean source tarball built from current `main` passes full `R CMD check --as-cran`, including PDF and HTML manual checks, with only the expected new-submission NOTE. That is the strongest package-level signal and it is good.

However, three submission/release hygiene issues still need to be corrected before pressing submit:

1. The checked source state is ahead of the public `v0.1.0` tag while the package version is still `0.1.0`.
2. `urlchecker::url_check()` reports a 404 for the README's pre-CRAN package link.
3. `cran-comments.md` is stale: it says `0 notes` even though the actual check has the expected new-submission NOTE, and it describes the rewrite as package version `2.0.0` while the package is `0.1.0`.

Strict release judgment: the code/build/test state is CRAN-ready, but the repository should not be submitted as-is until those submission-material issues are fixed or explicitly justified.

## CRAN standard used

This audit checked against the current official CRAN guidance:

- CRAN Repository Policy: <https://cran.r-project.org/web/packages/policies.html>
- CRAN submission checklist: <https://cran.r-project.org/web/packages/submission_checklist.html>
- CRAN URL checks note: <https://cran.r-project.org/web/packages/URL_checks.html>

The key operational standard is that a package should be built with `R CMD build` and checked with `R CMD check --as-cran` before submission, and should pass without warnings or significant notes. URL checks include README URLs.

## Verification performed

| Check | Result |
| --- | --- |
| `git status --porcelain=v1 --branch` | Clean `main...origin/main` before this audit file was added. |
| `git log -1` | `f541662c69ef769093446c1498b4ab265068c4bb`, `Surface the interactive app right after installation (#39)`. |
| `DESCRIPTION` | `Package: rfair`, `Version: 0.1.0`. |
| Optional `Suggests` availability | All listed optional packages checked were installed: `bslib`, `chromote`, `covr`, `DT`, `httptest2`, `jqr`, `knitr`, `plumber`, `rdflib`, `rmarkdown`, `shiny`, `testthat`, `wand`. |
| `testthat::test_local()` | Passed: `FAIL 0`, `WARN 0`, `SKIP 1`, `PASS 297`. |
| Documentation regeneration smoke | `devtools::document(roclets = c("rd"), quiet = TRUE)` completed and left the worktree clean. |
| `R CMD build /Users/choxos/Documents/GitHub/rfuji` | Built `rfair_0.1.0.tar.gz` successfully. |
| Tarball payload probe | No old tarballs, audit files, comments, `.github`, `.gstack`, docs, pkgdown, data-raw, node_modules, or check directories detected in the built tarball. |
| Tarball size | `456K`, well below CRAN's usual source tarball size concern threshold. |
| `R CMD check --as-cran --no-manual` | `Status: 1 NOTE`, only `New submission`. |
| `R CMD check --as-cran` | `Status: 1 NOTE`, only `New submission`; PDF and HTML manual checks passed. |
| `urlchecker::url_check()` | Failed on the README CRAN package link with `404: Not Found`. |
| `git diff --check` | Passed. |
| CodeRabbit uncommitted review | Skipped with `No changes detected`; no findings because the tree was clean. |
| Branch hygiene | No local or remote refs containing `fix` or `codex` were found. |
| Worktree count | One local worktree: `~/Documents/GitHub/rfuji` on `main`. |

## Full CRAN check result

The primary CRAN-readiness check was:

```text
R CMD check --as-cran rfair_0.1.0.tar.gz
```

It completed successfully with:

```text
Status: 1 NOTE
```

The only NOTE was:

```text
New submission
```

Important successful subchecks included:

```text
* checking top-level files ... OK
* checking examples ... OK
* checking examples with --run-donttest ... OK
* checking tests ... OK
* checking package vignettes ... OK
* checking re-building of vignette outputs ... OK
* checking PDF version of manual ... OK
* checking HTML version of manual ... OK
```

There were no errors and no warnings.

## Findings

### 1. The current source state is ahead of the `v0.1.0` release tag

Severity: high for release provenance

The audited commit is:

```text
f541662c69ef769093446c1498b4ab265068c4bb
```

The local `v0.1.0` tag resolves to:

```text
93ad01bf775e2a89441cf3fa468b860c95215620
```

Current `main` has three commits after the `v0.1.0` tag:

```text
f541662 Surface the interactive app right after installation (#39)
85030ee Score additional FRSM software metrics from provenance signals (#38)
2728986 Record the Zenodo archive DOI in citation metadata (#37)
```

This matters because the tarball that passed CRAN checks was built from current `main`, not from the public `v0.1.0` tag. Since `DESCRIPTION` still says `0.1.0`, the public release artifact and the audited source state are not aligned.

Required before submission:

- Either move/recreate the `v0.1.0` release/tag so it points at the exact source intended for CRAN, if policy for the project allows replacing that release, or
- Bump to a new version and submit that new version from a new tag/release.

Do not submit a CRAN tarball whose version and release tag imply a different source state.

### 2. README contains a currently broken pre-CRAN package URL

Severity: medium-high for submission hygiene

`urlchecker::url_check()` reports:

```text
README.md:4:62 404: Not Found
[![CRAN status](https://www.r-pkg.org/badges/version/rfair)](https://CRAN.R-project.org/package=rfair)
                                                             ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
```

This is understandable for a package that is not yet on CRAN, but it is still a failed URL check today. The official CRAN URL-check notes say README URLs are part of the URL-check surface.

Required before submission:

- Remove the CRAN package-page badge/link until after acceptance, or
- Replace it with a link that is live before submission, or
- Be ready to explain in the CRAN submission comment why this transient 404 is expected and will resolve after publication.

The safest strict recommendation is to remove the badge/link before initial submission and add it back after CRAN publication.

### 3. `cran-comments.md` is stale and internally inconsistent

Severity: medium

The file currently says:

```text
0 errors | 0 warnings | 0 notes, when all `Suggests` are installed.
```

The actual full check result is:

```text
Status: 1 NOTE
New submission
```

It also says:

```text
This is a major rewrite of the package (2.0.0).
```

But the package version is:

```text
Version: 0.1.0
```

This is not a package-code defect, but it is a CRAN submission defect. The comments should be corrected before submission so they match the exact check result and version being uploaded.

Recommended wording:

```text
## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new submission.

## Notes for CRAN

* This is the first CRAN submission of rfair 0.1.0. The package grew from the
  earlier rfuji F-UJI API client but now reimplements the FAIR assessment engine
  natively in R.
```

### 4. Cross-platform CRAN checks were not run here

Severity: medium-low

The full local check was strong and used R 4.6.0 on macOS arm64:

```text
R version 4.6.0 (2026-04-24)
platform: aarch64-apple-darwin23
```

The audit did not submit to win-builder, macbuilder, or R-hub. The CRAN submission checklist recommends supplementing local checks with these services, especially Windows checks for maintainers without local Windows access.

This is not a blocker to saying the package is locally CRAN-clean. It is a remaining submission-risk reduction step.

## Prior blockers now resolved

The previous audit's main blockers are fixed in the current checkout:

- Root-level legacy `rfuji_*.tar.gz` archives are no longer present in the source tarball.
- `.Rbuildignore` now excludes `*.tar.gz` broadly.
- `R CMD check` top-level files check is clean.
- The README `rtransparent` URL no longer redirects to a moved repository.
- OpenAPI metadata now reports `0.1.0`, not `2.3.5`.
- No `fix` or `codex` branch refs were found.
- The bundled Shiny app exists under `inst/shiny-apps/rfair/app.R`.
- `launch_rfair()` is exported, parses through the test suite, and checks its optional UI dependencies clearly.

## Package-level assessment

The package source is in strong shape:

- Tests pass.
- Examples pass, including `--run-donttest`.
- Vignettes rebuild.
- Manuals build in PDF and HTML.
- The source tarball is clean and compact.
- Optional heavy features are in `Suggests`.
- The shipped app is bundled in `inst/`, not as an unrelated top-level webapp directory.
- Current metric-version coverage includes the expected data, software, and legacy metric sets:

```text
0.8, 0.5, 0.5ssv2, 0.5ss, 0.5env, 0.7_software,
0.7_software_cessda, 0.6a2a, 0.4, 0.3, 0.2
```

## Final decision

Submit to CRAN today exactly as-is: no.

Submit after small release-hygiene fixes: yes, likely.

Minimum pre-submission checklist:

1. Align the CRAN source version with the public release tag, either by retagging/re-releasing `v0.1.0` at `f541662` or by bumping to a new version.
2. Fix or remove the README CRAN package link that currently returns 404.
3. Correct `cran-comments.md` to say `0 errors | 0 warnings | 1 note`, explain the new-submission NOTE, and remove the stale `2.0.0` wording.
4. Rebuild from the final intended commit.
5. Re-run `R CMD check --as-cran` on that rebuilt tarball.
6. Optionally run win-builder or R-hub before upload.

After those small non-code issues are handled, the package should be ready for CRAN submission based on the evidence from this audit.
