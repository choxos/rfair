# Contributing to rfair

Thank you for helping improve `rfair`. The package is a native R implementation
of F-UJI / FAIRsFAIR and FRSM metrics, so changes should preserve scientific
traceability, reproducibility, and compatibility with the documented metric
sets.

## Ways to contribute

Useful contributions include:

- Bug reports with a minimal reproducible example.
- Metric or scoring corrections with links to the relevant upstream F-UJI,
  FAIRsFAIR, FRSM, or repository documentation.
- Tests for metadata harvesters, metric scoring, API behavior, and Shiny app
  behavior.
- Documentation improvements for package users, API users, and contributors.
- Small, focused pull requests that are easy to review.

## Before opening an issue

Please search existing issues first. When reporting a bug, include:

- The identifier, DOI, URL, or repository being assessed.
- The metric version used, for example `0.8` or `0.7_software`.
- A short reproducible R example.
- Your `sessionInfo()` output.
- Whether the problem occurs with `resolve = FALSE` or requires live network
  metadata harvesting.

Do not include private data, access tokens, unpublished manuscripts, or
restricted metadata in public issues.

## Development setup

From a local checkout:

```r
install.packages(c("devtools", "testthat"))
devtools::install_deps(dependencies = TRUE)
devtools::load_all()
```

Run the package test suite with:

```r
testthat::test_local()
```

For a CRAN-style local check, build a clean source tarball and run:

```sh
R CMD build .
R CMD check --as-cran rfair_*.tar.gz
```

Optional features use packages in `Suggests`, including `shiny`, `bslib`, `DT`,
`plumber`, `rdflib`, and `wand`. If you change optional behavior, verify both
the installed-dependency path and the graceful-degradation path where practical.

## Code and data expectations

- Keep changes focused. Avoid mixing unrelated refactors with behavioral fixes.
- Add or update tests for scoring, parsing, API, or UI behavior that changes.
- Keep examples CRAN-safe. Network-dependent examples should use `\donttest{}`
  or `\dontrun{}` where appropriate.
- Preserve provenance for bundled metric files and reference data. Update
  `data-raw/` scripts or notes when regenerated data changes.
- Do not commit generated check directories, source tarballs, local logs, or
  credentials.
- Use clear branch names that describe the work.

## Pull requests

Open pull requests against `main`. A good pull request should include:

- A concise summary of the change.
- The reason the change is needed.
- Tests or checks that were run.
- Links to relevant issues, metric definitions, or upstream behavior.

By contributing, you agree that your contribution will be distributed under the
project license.
