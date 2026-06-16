# rfuji Strict Audit - Round 3 Post-Fix - 2026-06-16

## Verdict

After the follow-up fixes, the repo is materially cleaner. The two concrete package-check regressions from the round-3 redo are fixed:

- `LICENSE` is back to a valid CRAN-style MIT stub for `License: MIT + file LICENSE`.
- `.gstack/` is now excluded from `R CMD build`.

The fallback package check is now clean: **0 errors | 0 warnings | 0 notes**.

The repo is still not a perfect release state because strict `R CMD check` still cannot pass in this audit environment without the full Suggests stack, and upstream F-UJI conformance still was not reproduced because no reference server was running. Those are now the main remaining evidence gaps.

## Current State Audited

- Current branch: `main`
- Current HEAD before local fixes: `5c819f4` (`Merge pull request #7 from choxos/fix/web-software-metrics`)
- Local main-branch source fixes made during this follow-up:
  - Restored CRAN MIT license stub in `LICENSE`.
  - Added `.gstack/` and `webapp/` handling to local ignores/build ignores.
  - Corrected methodology wording around historical/manual F-UJI validation.
  - Removed the stray closing fence from `vignettes/rfuji.Rmd`.
  - Corrected the roadmap workflow filename wording for the `webapp` branch.
- Local `webapp` branch fixes made in the temporary `webapp/` worktree:
  - Made `scripts/sync-data.mjs` auto-detect the parent package worktree.
  - Added a Vitest case that exercises the FRSM/software assessment path.

## Verification

Passing gates:

- `rtk Rscript -e 'devtools::test()'`: 155 passed, 1 skipped, 0 failed, 0 warnings.
- Fallback `R CMD check` with `_R_CHECK_FORCE_SUGGESTS_=false`: 0 errors, 0 warnings, 0 notes.
- CI-shaped pkgdown build with the current source installed first: passed.
- `rtk Rscript tests/conformance/parity.R`: 30/30 registry-core R-to-TS parity.
- Webapp branch `npm ci`: passed, 0 vulnerabilities.
- Webapp branch `npm test`: 9 tests passed.
- Webapp branch `npm run typecheck`: passed.
- Webapp branch `npm audit --audit-level=low`: passed.
- Webapp branch `npm run build`: passed.
- Webapp branch `npm run sync-data`: now finds the parent package worktree and syncs all six JSON files.

Remaining incomplete gates:

- Strict `R CMD check` still fails at dependency checking because `jqr`, `plumber`, `rdflib`, and `wand` are unavailable in this local environment.
- `tests/conformance/run.R` still cannot compare against upstream F-UJI because `http://localhost:1071/fuji/api/v1/evaluate` is not running.
- Browser e2e and Shiny runtime smoke coverage are still not implemented.

## Remaining Findings

### High - Strict `R CMD check` still needs full-Suggests evidence

`DESCRIPTION` still lists optional packages that are unavailable locally: `jqr`, `plumber`, `rdflib`, and `wand`. The package now checks cleanly when Suggests are not forced, but release evidence still needs a full strict check in an environment with those packages and their system libraries installed.

### Medium - Upstream F-UJI conformance is still historical/manual

The conformance harness is present, but the local reference server was not running. Current docs are now more careful about this, but a fully reproducible release story still needs either an automated pinned reference server or an archived version-pinned conformance artifact.

### Low - Runtime/UI coverage is still limited

The webapp branch now has a unit test for the FRSM software path, plus build/typecheck/audit. It still lacks browser e2e coverage. The Shiny app still has parse/dependency tests rather than a runtime UI smoke test.

## Bottom Line

The immediate round-3 regressions are fixed and verified. The repo is now much closer to release-clean from a local package standpoint. The remaining blockers are mostly environment/evidence items: full-Suggests strict check, upstream F-UJI reproducibility, and runtime UI smoke coverage.
