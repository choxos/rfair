# rfuji Strict Audit - Round 2 - 2026-06-16

## Verdict

The repository is **substantially improved since the first audit**, but it is still **not 100% perfect** and I would not call it fully release-proof, CRAN-proof, or methodologically closed.

Claude appears to have fixed several of the first-round hard failures: the git staging disaster is gone, the npm audit is clean, the webapp builds on the updated Vite/Vitest stack, the fallback R package check is clean, the prior `as_fuji_json()` null `agnostic_test_identifier` defect is fixed, and duplicate live Zenodo content URLs are fixed.

The current blockers are narrower but still real:

- The R-to-TypeScript parity harness is currently broken because it hard-codes an `esbuild` binary that the current Vite 8 dependency tree does not install.
- The repo still claims validated R/TS parity and upstream F-UJI agreement, but the current checkout cannot reproduce either claim from the audited commands.
- Strict `R CMD check` still fails in this local audit before tests because optional `Suggests` are absent, so the full-stack clean-check claim remains unverified here.
- The deploy workflow uses `npm install` rather than `npm ci`, which trades reproducibility for platform repair.
- pkgdown builds, but reports a README accessibility defect.
- Some roadmap/test-coverage claims remain too broad for the evidence.

This is no longer the catastrophic pre-commit state from round 1. It is a plausible release candidate after targeted fixes. It is not perfect.

## Current State Audited

- Current branch: `main`
- Current HEAD: `007d7ee` (`Merge pull request #4 from choxos/fix/pkgdown-reference-index`)
- Worktree before writing this report: clean, with no untracked files.
- Prior audit preserved at `audit/rfuji-strict-audit-2026-06-16.md`.
- Scope: full current checkout, including R package code, tests, conformance harnesses, workflows, pkgdown config, README/roadmap, webapp package, and live smoke probes.
- No source fixes were made in this round. The only file added by this audit is this report.

## Command Evidence

Passing or improved gates:

- `rtk git status --short --branch`: clean `main...origin/main`.
- `rtk git ls-files --others --exclude-standard | wc -l`: `0`.
- `rtk npm --prefix webapp ci`: passed; installed 132 packages; `0 vulnerabilities`.
- `rtk npm --prefix webapp audit --audit-level=low`: passed; `0 vulnerabilities`.
- `rtk npm --prefix webapp run sync-data && rtk npm --prefix webapp test && rtk npm --prefix webapp run typecheck && rtk npm --prefix webapp run build`: passed.
- Vitest: 1 test file, 8 tests passed.
- Vite production build: passed.
- `rtk Rscript -e 'devtools::test()'`: 148 passed, 1 skipped, 0 failed, 0 warnings.
- Fallback package check with `_R_CHECK_FORCE_SUGGESTS_=false`: `0 errors | 0 warnings | 0 notes`.
- `rtk Rscript -e 'pkgdown::build_site(new_process = FALSE, install = FALSE)'`: completed successfully.
- Live `assess_fair("https://doi.org/10.5281/zenodo.8347772")`: resolved to Zenodo, FAIR 23/26 = 88.46%.
- Live `assess_fair("https://github.com/pangaea-data-publisher/fuji")`: resolved to GitHub, FAIR 11/26 = 42.31%.
- Live JSON export probe found `0` null `agnostic_test_identifier` values and F1 tests with non-empty agnostic identifiers.
- Live Zenodo content URL probe found 1 content URL and 1 unique content URL.

Failing, incomplete, or non-perfect gates:

- Strict `rtk Rscript -e 'rcmdcheck::rcmdcheck(...)'`: check result has 1 ERROR because `jqr`, `plumber`, `rdflib`, and `wand` are unavailable.
- `rtk Rscript tests/conformance/parity.R`: fails immediately with `Run npm install in webapp/ first.`
- `rtk npm --prefix webapp ls esbuild --depth=0`: `(empty)`, confirming the parity failure is not a missing install step after `npm ci`.
- `rtk curl http://localhost:1071/fuji/api/v1/evaluate`: failed to connect, so upstream F-UJI conformance was not reproduced.
- `pkgdown::build_site(...)`: reports missing alt text for the shield image in `README.md`.
- `rtk npm --prefix webapp outdated`: React 19, Tailwind 4, and matching type packages are available; not a current blocker, but not fully up to date.

## Resolved Since Round 1

### Resolved - The git/index state is now safe

Round 1 found that a commit would delete almost the entire product. Current evidence is clean:

- `git status --short --branch` shows no staged, unstaged, or untracked product files.
- `git ls-files --others --exclude-standard` returns zero.
- The package, webapp, workflows, tests, vignettes, audit file, and docs sources are now tracked normally.

### Resolved - Webapp dependency vulnerabilities are fixed

Round 1 found a vulnerable Vite/esbuild/vitest chain with a critical audit finding. Current evidence:

- `webapp/package.json:22-28` now uses `@vitejs/plugin-react` 6, TypeScript 6, Vite 8, and Vitest 4.
- `npm ci` and `npm audit --audit-level=low` both pass with zero vulnerabilities.
- Vitest, typecheck, and production build pass on the updated stack.

### Resolved - Fallback R package check is clean

Round 1 fallback check had a portability NOTE from an overlong fixture path. Current fallback check with forced Suggests disabled is clean:

- `0 errors | 0 warnings | 0 notes`.

### Resolved - `as_fuji_json()` no longer emits null agnostic identifiers

Evidence:

- `R/criterium_engine.R:15-19` now derives `agnostic_test_identifier` directly while constructing metric-test records.
- `tests/testthat/test-assess.R:37-45` asserts the JSON export does not contain `"agnostic_test_identifier":null` and that F1 tests have non-empty values.
- Live export probe found zero null agnostic identifiers.

### Resolved - Duplicate live Zenodo content URLs are fixed

Evidence:

- `R/harvest_data.R:40-50` deduplicates enriched content identifiers by URL after probing.
- `tests/testthat/test-integration.R:14-21` checks that live content URLs are unique when present.
- Live Zenodo probe returned 1 content URL and 1 unique URL.

### Improved - README quick-start score now matches the current live probe

Round 1 found README score drift. Current `README.md:33-44` shows Zenodo resolving to `23/26` and `88.5%`, matching the audited live result within rounding.

## Findings

### Critical - Current R-to-TypeScript parity proof is broken

Evidence:

- `tests/conformance/parity.R:17-21` hard-codes `webapp/node_modules/.bin/esbuild` as the bundler.
- `webapp/package.json:22-28` has no direct `esbuild` dependency.
- `npm ci` completed successfully, but `npm ls esbuild --depth=0` reports `(empty)`.
- `Rscript tests/conformance/parity.R` fails before running comparisons with `Run npm install in webapp/ first.`
- `ROADMAP.md:97` still marks the R/TS parity harness as complete and says it has 100% agreement.
- `tests/conformance/README.md:46-47` says the parity harness separately confirms 100% R/TS agreement.

Impact:

The repo currently cannot prove that the browser scoring engine agrees with the R engine. This matters because the webapp duplicates scoring logic in TypeScript and publicly claims agreement for registry-core metrics. Passing Vitest tests do not replace this because `webapp/src/lib/engine.test.ts:9-47` only covers reuse helpers and simple parsers, not full browser assessment parity.

Fix direction:

Make the parity runner use a dependency that is actually declared and installed. The clean options are: add `esbuild` as an explicit devDependency, invoke Vite/Rolldown through a supported script, or rewrite `parity-entry.mts` so it can run under a maintained TypeScript/Node runner. Then make the parity command part of CI or downgrade the 100% parity claim.

### High - Upstream F-UJI conformance is still claimed but not reproducible here

Evidence:

- `tests/conformance/run.R:19-20` defaults to `http://localhost:1071/fuji/api/v1/evaluate`.
- The local probe to that endpoint failed to connect.
- `tests/conformance/README.md:34-47` still says F-UJI 4.0.0 validation produced 94.1% Zenodo agreement, 85.3% PANGAEA/Dryad agreement, and that the R/TS harness confirms 100% agreement.
- `ROADMAP.md:98` repeats the 94.1% and 85.3% conformance claim and says it meets the 85% gate.
- The CI workflows do not start a reference F-UJI server or run `tests/conformance/run.R`.

Impact:

The current repo can describe a prior manual run, but it cannot demonstrate that upstream-fidelity claim from the current checkout. For a native reimplementation of a scoring engine, this is a major evidence gap.

Fix direction:

Either automate the reference service in CI or store a version-pinned, reproducible conformance artifact with exact F-UJI commit/version, metrics file hash, fixture identifiers, command, date, and output. Until then, mark the result as historical/manual, not current validated status.

### High - Strict `R CMD check` still does not pass in this audit environment

Evidence:

- `DESCRIPTION:34-46` lists `jqr`, `plumber`, `rdflib`, and `wand` in `Suggests`.
- Strict `rcmdcheck` reports 1 ERROR at dependency checking because those packages are unavailable.
- `cran-comments.md:3-9` now correctly qualifies the clean result as applying when all `Suggests` are installed and says the package degrades gracefully without them.

Impact:

This is less severe than round 1 because the CRAN comments are now conditional and the fallback check is clean. But the full clean-check claim is still not reproduced locally in this audit. A release decision needs evidence from an environment with the full Suggests stack and system libraries for `rdflib` and `wand`.

Fix direction:

Run and archive a full strict check in an environment with `jqr`, `plumber`, `rdflib`, `wand`, `librdf`, and `libmagic` installed. If those dependencies are meant to be optional, keep the fallback check, but do not treat it as equivalent to strict check evidence.

### Medium - Deploy workflow is less reproducible than the lockfile suggests

Evidence:

- `.github/workflows/deploy-app.yaml:31-37` intentionally uses `npm install --no-audit --no-fund`, not `npm ci`.
- The comment says this lets the Linux runner reconcile platform-specific optional native deps not enumerated by a macOS-generated lockfile.
- The same workflow audits only at `--audit-level=high` in `.github/workflows/deploy-app.yaml:39-41`.

Impact:

The workflow may be pragmatic for platform-specific optional dependency repair, but it weakens reproducibility. `npm install` can update the lockfile contents during CI, while `npm ci` is the standard lockfile-exact install. Also, a future moderate advisory would not block deployment under the current high-only threshold.

Fix direction:

Prefer a lockfile that works with `npm ci` on Linux, or add an explicit CI guard that fails if `npm install` mutates `package-lock.json`. Consider using the same audit threshold in CI as the local audit gate, or document why deployment intentionally tolerates lower-severity advisories.

### Medium - pkgdown builds, but the README has an accessibility defect

Evidence:

- `pkgdown::build_site(new_process = FALSE, install = FALSE)` completed.
- pkgdown reported: `Missing alt-text in 'README.md'` for the shield image.
- `README.md:1` uses raw HTML: `<img src="https://img.shields.io/badge/FAIR-assessment-118AB2" align="right" />` with no `alt` attribute.

Impact:

This does not block site generation, but it is a real accessibility defect and prevents calling the documentation perfect. It is especially easy to fix.

Fix direction:

Add an `alt` attribute to the badge image or remove the decorative badge from the H1.

### Medium - Roadmap still overstates completed validation

Evidence:

- `ROADMAP.md:97` marks R/TS parity as complete with 100% agreement, but the current parity command fails before comparison.
- `ROADMAP.md:98` marks upstream F-UJI conformance as validated, but the reference server was not available and the harness is not automated.
- `ROADMAP.md:83` still lists Vitest unit tests plus Playwright e2e in CI as TODO; current web CI has Vitest but no browser e2e.
- `ROADMAP.md:103` still leaves CRAN readiness unchecked, which is consistent with the strict-check evidence gap.

Impact:

The roadmap mixes current implementation status, historical manual validation, and not-yet-automated gates. Reviewers cannot infer what is currently guaranteed by CI or local reproducible checks.

Fix direction:

Split the roadmap into "implemented", "currently verified by CI/local command", and "historical/manual evidence". Claims about parity and conformance should point to fresh artifacts or commands that pass in the current checkout.

### Medium - Public behavior coverage is still thinner than the claims

Evidence:

- `tests/testthat/test-integration.R:4-22` is a useful live smoke test, but it only asserts broad positivity and content URL deduplication.
- `tests/testthat/test-shiny.R:1-16` parses the Shiny app and checks missing-dependency behavior; it does not launch or exercise the UI.
- `webapp/src/lib/engine.test.ts:9-47` tests license/reuse helpers and parsers, not full browser scoring behavior.
- There is no Playwright/browser smoke test in CI.
- There is no automated F-UJI reference comparison in CI.

Impact:

The passing test suite is meaningful but not sufficient to prove the core public promises: metric-level fidelity, browser app correctness, Shiny app behavior, and upstream agreement.

Fix direction:

Add exact expected metric-level fixtures for representative DOI, repository, RDF/XML/signposting, and FRSM cases. Add browser smoke coverage for the built Vite app. Add a minimal Shiny smoke test if `launch_rfuji()` is a supported interface. Gate parity and conformance claims with runnable checks.

### Low - Web dependencies are clean but not latest-major

Evidence:

- `npm outdated` reports newer major lines for React, React DOM, React type packages, and Tailwind.
- `npm audit --audit-level=low` is currently clean.

Impact:

This is not a release blocker. Staying on React 18 and Tailwind 3 is reasonable if deliberate. It only prevents saying the web stack is fully current.

Fix direction:

Document that React 18/Tailwind 3 are intentionally pinned for stability, or schedule a separate major-upgrade pass.

## Bottom Line

Round 2 fixed the worst release blockers from round 1. The repo is now cleanly tracked, the web security audit is clean, the webapp builds, the R tests pass, the fallback package check is clean, and the concrete JSON/content-URL bugs are fixed.

The remaining non-negotiable issue is evidence integrity: the repository still says parity and F-UJI conformance are validated, while the current audited checkout cannot reproduce those validations. Fix the broken parity runner, either automate or clearly archive F-UJI conformance, and produce a full-Suggests strict R CMD check. After that, this can be re-audited as a much closer release candidate.
