# rfuji Strict Audit - 2026-06-16

## Verdict

This repository is **not 100% perfect** and is **not ready to commit, publish, submit to CRAN, or call release-ready** in its current state.

The working tree can run many important checks, and the replacement implementation is not a toy. The R test suite passes, the webapp builds, the R-to-TypeScript parity harness passes on its narrow registry-core metric set, and live smoke assessments return plausible results. However, several hard blockers remain:

- The git index is catastrophically unsafe: a commit from the current index would delete nearly the entire original package and omit the untracked replacement implementation.
- The webapp dependency tree has current `npm audit` vulnerabilities, including a critical finding.
- Strict `R CMD check` fails locally before tests because required `Suggests` are unavailable.
- The fallback package check still has a portability NOTE from an overlong test fixture path.
- The claimed upstream F-UJI conformance result is not reproducible from the current checkout because the required local reference server is not running.
- The F-UJI-compatible JSON export has a concrete schema/compatibility defect: agnostic test identifiers are emitted as `null`.
- Documentation, roadmap, CRAN comments, and live results disagree.

This is a strong prototype with real test coverage. It is not a clean, auditable release.

## Audit Scope

Audited the whole current working tree, including staged deletions, untracked replacement files, R package code, Shiny app, Vite webapp, workflows, vignettes, tests, conformance scripts, comments/reference material, package metadata, and generated/ignored artifacts.

No source fixes were made. No CodeRabbit or external diff-upload review was run. Live network probes were run for selected DOI/GitHub paths because that scope was requested.

## Command Evidence

Passing gates:

- `rtk Rscript -e 'devtools::test()'`: 145 passed, 1 skipped, 0 failures.
- `rtk npm --prefix webapp run sync-data && rtk npm --prefix webapp test && rtk npm --prefix webapp run typecheck && rtk npm --prefix webapp run build`: sync, Vitest, TypeScript, and production build all passed.
- `rtk Rscript tests/conformance/parity.R`: R-to-TypeScript registry-core parity passed, 30/30.
- Live `assess_fair("https://doi.org/10.5281/zenodo.8347772")`: resolved to Zenodo, FAIR 23/26 = 88.46%.
- Live `assess_fair("https://github.com/pangaea-data-publisher/fuji")`: resolved to GitHub, v0.8 FAIR 11/26 = 42.31%.
- Live `assess_fair(..., metric_version = "0.7_software")` on the same GitHub repo: FRSM FAIR 25/45 = 55.56%.
- `rtk diff -qr inst/extdata/web webapp/public/data`: no differences after `npm run sync-data`.
- Secret-pattern scan over the non-`.git` tree found no obvious private keys or common token formats.

Failing or incomplete gates:

- Strict `rtk Rscript -e 'rcmdcheck::rcmdcheck(...)'`: 1 ERROR because `jqr`, `plumber`, `rdflib`, and `wand` were unavailable.
- Fallback `_R_CHECK_FORCE_SUGGESTS_=false` check: 0 errors, 0 warnings, 1 NOTE for a non-portable test fixture path.
- `rtk npm --prefix webapp audit --audit-level=low`: failed with 5 vulnerabilities, including high and critical findings through Vite/esbuild/vitest.
- `rtk curl ... http://localhost:1071/fuji/api/v1/evaluate`: failed to connect, so upstream F-UJI conformance could not be reproduced in this audit.
- `rtk npm --prefix webapp outdated`: React, Vite, Vitest, TypeScript, Tailwind, and related tooling have newer major versions.

## Findings

### Critical - The git index would delete the product if committed now

Evidence:

- `git ls-files` currently lists only 5 tracked files: `.Rbuildignore`, `.gitignore`, `DESCRIPTION`, `README.md`, and `tests/testthat.R`.
- `git diff --cached --name-status` contains 198 staged deletions.
- `git status --short --untracked-files=all` reports 627 untracked files, including the replacement `R/`, `NAMESPACE`, `man/`, `inst/`, `tests/testthat/`, `.github/`, `webapp/`, and `vignettes/` trees.
- Only three tracked files have unstaged modifications: `.Rbuildignore`, `DESCRIPTION`, and `README.md`.

Impact:

A normal commit from the current index would preserve only five tracked files and delete the package implementation. The local working tree still runs because R loads untracked files from disk, but the repository state is not publishable or reviewable as a commit.

Fix direction:

Reset the staging state intentionally, then stage the replacement implementation and intentional deletions together. Do not commit until `git status --short` shows the intended tracked set and no accidental untracked product files remain.

### Critical - Webapp dependency audit fails with vulnerable Vite/esbuild/vitest chain

Evidence:

- `webapp/package.json:27-28` allows `vite` and `vitest` major-2/5-era versions.
- `webapp/package-lock.json:2916-2924` pins Vite 5.4.21, depending on esbuild.
- `webapp/package-lock.json:3000-3025` pins Vitest 2.1.9 and `vite-node`.
- `npm audit` reports 5 vulnerabilities: 2 moderate, 2 high, and 1 critical. It specifically flags esbuild advisories and the vulnerable Vite/Vitest dependency path.

Impact:

The production build passes, but dependency security does not. This blocks any claim that the browser app is release-safe. The Vite dev-server advisory is not only cosmetic if maintainers run the dev server on a networked machine, and the lockfile is the deployed dependency source of truth.

Fix direction:

Upgrade Vite/Vitest and their plugin/tooling chain in a controlled branch, rerun `npm audit`, Vitest, typecheck, production build, and any browser smoke tests. The audit output says `npm audit fix --force` would jump to Vite 8, so this needs a deliberate compatibility update, not a blind force fix.

### High - Strict `R CMD check` does not pass

Evidence:

- `DESCRIPTION:34-46` lists `jqr`, `plumber`, `rdflib`, and `wand` under `Suggests`.
- Local dependency probe found `jqr`, `plumber`, `rdflib`, and `wand` unavailable.
- Strict `R CMD check` stopped at `checking package dependencies ... ERROR`.
- `cran-comments.md:1-4` claims `0 errors | 0 warnings | 0 notes`, which is false for this audit environment.

Impact:

This cannot be called CRAN-ready or package-release-ready from current evidence. The fallback check with `_R_CHECK_FORCE_SUGGESTS_=false` is useful diagnostic evidence, but it is not a strict clean check.

Fix direction:

Decide whether these packages are truly optional. If they are optional, keep all examples/tests/docs robust when absent and document the degraded paths. For release evidence, run a complete check in an environment where the full Suggests stack, including system dependencies for `rdflib` and `wand`, is installed.

### High - Fallback package check still has a portability NOTE

Evidence:

- Fallback `R CMD check` completed with 1 NOTE:
  `rfuji/tests/testthat/_fuji_zenodo/zenodo.org/records/8347772/files/pangaea-data-publisher/fuji-v2.2.5.zip-HEAD.R`
  is a non-portable file path.
- `tests/testthat/test-integration.R:8-15` depends on the `_fuji_zenodo` cassette directory.

Impact:

The package is not clean even after bypassing missing Suggests. CRAN and cross-platform packaging can object to the path length. It also weakens reproducibility if tar implementations or filesystems truncate or reject paths.

Fix direction:

Shorten the cassette fixture path or move the fixture behind a shorter stable alias. Then rerun fallback and strict checks.

### High - `as_fuji_json()` emits null agnostic test identifiers

Evidence:

- `R/metrics.R:64-79` adds `agnostic_test_identifier` only while building `custom`.
- `R/assess.R:45-50` runs evaluators over `metrics_meta$metrics`, the raw metric list, not the enriched `custom` map.
- `R/criterium_engine.R:16-19` copies `t$agnostic_test_identifier` into each emitted test.
- `R/as_fuji_json.R:21-24` claims the output matches the upstream F-UJI `FAIRResults` schema.
- Live probe of `as_fuji_json()` found 31 occurrences of `"agnostic_test_identifier":null`.
- `tests/testthat/test-assess.R:22-30` only checks JSON validity and top-level shape, so this bug is not caught.

Impact:

The exported JSON is syntactically valid but not fully compatible with the schema it claims to target. Downstream consumers that rely on agnostic metric-test identifiers will lose mapping information.

Fix direction:

Either enrich `metrics_meta$metrics` before evaluator execution or make `run_evaluators()` use the enriched metric definitions. Add an assertion that exported metric tests include non-null agnostic identifiers.

### High - Upstream F-UJI conformance is claimed but not reproducible in this audit

Evidence:

- `tests/conformance/README.md:34-45` claims validated agreement against locally-run F-UJI 4.0.0.
- `ROADMAP.md:98` repeats the 94.1% and 85.3% conformance claim.
- `tests/conformance/run.R:19-20` defaults to `http://localhost:1071/fuji/api/v1/evaluate`.
- The local probe to `localhost:1071` failed to connect.

Impact:

The current repo can claim "a previous run said this," but it cannot currently demonstrate upstream fidelity. For a native reimplementation of a scoring engine, this is a major verification gap.

Fix direction:

Make the reference-server setup reproducible in CI or a local script, capture the exact F-UJI version and metric files, and store fresh conformance output. Until then, keep fidelity claims conservative.

### Medium - README and ROADMAP are materially stale or contradictory

Evidence:

- `README.md:38-43` shows the Zenodo quick-start score as `20/26` and `76.9%`.
- Live audit of the same DOI returned `23/26` and `88.46%`.
- `ROADMAP.md:20-22` says signposting and data harvesting are still TODO, while `ROADMAP.md:39-43` and `ROADMAP.md:62` say they are implemented.
- `ROADMAP.md:55` says FRSM evaluators are not written, but `R/eval_frsm.R:110-127` registers all 17 FRSM evaluators.
- `ROADMAP.md:97` says the parity harness is `12/12`; the current run reports `30/30`.
- `ROADMAP.md:118` says I2-01M and R1.3-01M are deferred and always 0, while `ROADMAP.md:49-53` says both are implemented.

Impact:

Users and reviewers cannot tell what is actually done. This is especially damaging for a package whose main value proposition is scoring fidelity and methodological transparency.

Fix direction:

Regenerate README examples or make them explicitly illustrative. Rewrite the roadmap as current state plus verified evidence, not a historical scratchpad.

### Medium - Live assessments include duplicate content identifiers

Evidence:

- Live Zenodo assessment returned two identical `object_content_identifier` URLs and only one unique URL.
- `R/merge.R:104-107` deduplicates list-like metadata at merge time.
- `R/harvest_data.R:12-40` later enriches content identifiers but does not deduplicate after enrichment.

Impact:

This causes duplicate evidence in `as_fuji_json()`, duplicate retrievability evidence, and noisy output. It can also mask real multi-file behavior because repeated copies of the same file look like multiple data links.

Fix direction:

Normalize content identifiers by canonical URL after all enrichment, not just by structural digest before enrichment. Add a regression test using the Zenodo fixture.

### Medium - Test coverage is too weak for several public claims

Evidence:

- `tests/testthat/test-integration.R:7-15` asserts only that a full assessment returns an object, has positive FAIR score, has more than five passing metrics, and has metadata. It does not lock expected metric-level behavior.
- `tests/testthat/test-frsm.R:1-24` exercises synthetic boolean FRSM signals, not a real repository fixture or upstream software FAIR expected output.
- `tests/testthat/test-shiny.R:1-15` parses the Shiny app and checks missing-dependency behavior only. It does not run the app interactively.
- `webapp/src/lib/engine.test.ts:9-47` covers license/reuse helpers and parsers, not the full browser `assess()` path.
- `tests/conformance/run.R:64-65` exits only after finding no reference comparisons, but the reference service is not part of automated local verification.

Impact:

Passing tests do not prove the core scoring engine, FRSM engine, Shiny UI, or browser app are correct at the behavioral level users care about.

Fix direction:

Add exact metric-level fixture tests for representative DOI, repository, RDF/XML/signposting, and FRSM cases. Add browser-level smoke tests for the Vite app and a Shiny smoke test if the package intends to ship the app as a supported interface.

### Medium - CI does not gate the webapp on dependency audit or browser behavior

Evidence:

- `.github/workflows/deploy-app.yaml:35-41` runs sync-data, typecheck, test, and build.
- It does not run `npm audit`.
- It does not run browser smoke or Playwright checks.

Impact:

The webapp workflow would deploy a passing build even while `npm audit` fails. It also cannot catch runtime rendering/data-loading regressions that unit tests miss.

Fix direction:

Add a security audit gate with a documented severity threshold, and add a headless browser smoke test that loads the built app, verifies data JSON loads, runs a sample assessment, and checks the visible score.

### Medium - Whole-tree hygiene is not safe for a public fork

Evidence:

- The repo is 116 MB locally; `comments/` alone is 30 MB and 484 files.
- Untracked files include `.DS_Store`, `comments/.DS_Store`, nested `.DS_Store` files, `comments/FAIR-nanopubs-master/.project`, and `comments/reusabledata-master/.claude/skills/*.md`.
- `.gitignore:1-35` lacks global `.DS_Store` and `*.tsbuildinfo` ignores.
- `webapp/.gitignore:1-5` ignores `.DS_Store` only inside `webapp/`, not globally, and does not ignore `tsconfig.tsbuildinfo`.
- `.Rbuildignore:9-10` excludes `data-raw` and `comments` from package builds, but that does not prevent accidental inclusion in the GitHub repository.

Impact:

The package tarball may avoid some of this, but a public repo commit can still leak local/editor artifacts, unrelated source material, Claude/agent skill files, and bulky reference copies. This harms reviewability and provenance.

Fix direction:

Decide whether `comments/` and nested third-party source trees belong in the public repo. If retained, curate them, remove local artifacts, document licenses/provenance, and add global ignores for local build/editor files.

### Medium - Optional RDF/headless/content-sniffing paths are not fully verified

Evidence:

- `DESCRIPTION:34-46` lists optional packages including `chromote`, `rdflib`, and `wand`.
- Local dependency probe found `chromote` installed but `rdflib` and `wand` absent.
- `R/collect_rdf.R:57-87` skips Turtle/RDF graph parsing when `rdflib` is missing.
- `R/as_rdf.R:61-69` requires `rdflib` for Turtle serialization.
- `R/harvest_data.R:1-3` states that `wand` adds libmagic content sniffing, but local verification did not cover that path.
- `ROADMAP.md:44` explicitly calls the `rdflib`/librdf Turtle path untested.

Impact:

The graceful-degradation story appears plausible, but the full feature story is unverified. A release should distinguish "implemented" from "implemented only when optional system dependencies are present and tested."

Fix direction:

Run a second package check in an environment with all Suggests and system dependencies installed. Add small fixtures for Turtle/RDF-XML and libmagic behavior.

### Medium - CRAN comments are currently false

Evidence:

- `cran-comments.md:1-4` says `0 errors | 0 warnings | 0 notes`.
- This audit saw strict `R CMD check` fail with 1 ERROR, and fallback check finish with 1 NOTE.

Impact:

This would be misleading in a CRAN submission or release checklist.

Fix direction:

Regenerate `cran-comments.md` only after a clean check in the intended release environment.

### Low - JSON-LD namespace quality is thin

Evidence:

- `R/as_rdf.R:17-21` defines JSON-LD context entries for `dcat`, `dc`, `schema`, `dqv`, and `prov`.
- `R/as_rdf.R:31-32` emits `rfuji:metricVersion` and `rfuji:softwareVersion`, but no `rfuji` prefix is defined in the context.
- `tests/testthat/test-assess.R:37-44` validates JSON syntax and checks for `schema:Rating`, but does not expand or validate JSON-LD semantics.

Impact:

The JSON-LD is syntactically valid JSON, but machine-readable RDF quality is not strongly verified. Consumers may treat the custom `rfuji:` fields inconsistently.

Fix direction:

Define an `rfuji` namespace in the context or use full IRIs. Add a JSON-LD expansion/round-trip check where feasible.

## Positive Findings

The audit was not all negative:

- The R package loads and the primary offline/unit suite passes.
- The fallback package check gets through examples, tests, vignettes, and installed-size checks once missing Suggests are bypassed.
- The webapp builds cleanly and its data sync matches the package extdata source.
- The R-to-TypeScript parity harness passed on the six registry-core metrics across five identifiers.
- Live DOI and GitHub assessments completed without crashing.
- The package exports are coherent with `NAMESPACE`.
- No obvious private keys or common token strings were found by the regex scan.

These are good signals. They are not enough for "100% perfect."

## Recommended Fix Order

1. Repair git state first. Do not do any release or review commit until tracked/untracked/staged state is coherent.
2. Fix dependency security in `webapp/` and add an audit gate.
3. Make strict `R CMD check` clean in a full-Suggests environment and remove the long fixture path NOTE.
4. Fix `as_fuji_json()` agnostic identifier emission and add a regression test.
5. Reproduce upstream F-UJI conformance from a scripted reference server, then update or soften the fidelity claims.
6. Clean README, ROADMAP, and CRAN comments to match current behavior.
7. Add exact metric-level fixture tests, webapp browser smoke tests, and optional-dependency tests.
8. Curate or remove `comments/` and local artifacts before staging the public repo.

## Bottom Line

Claude produced a substantial rewrite that can run and pass meaningful tests. But the repository as prepared is not clean, not safely staged, not dependency-secure, not strict-check-clean, not fully fidelity-verified, and not documentation-consistent. It should be treated as an advanced draft requiring hardening, not a finished package.
