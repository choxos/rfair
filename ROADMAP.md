# rfair roadmap

Native, pure-R reimplementation of the F-UJI FAIR assessment engine, plus a
Shiny app and a static JS/TS web app. This file tracks everything still to do so
nothing is forgotten.

Legend: `[x]` done · `[~]` partial · `[ ]` todo

## Phase 0 — Foundations  `[x]`
- [x] Package scaffolding (DESCRIPTION v2, roxygen NAMESPACE, `.onLoad`, LICENSE (MIT at first; GPL-3 since 0.1.0), `.Rbuildignore`); generated OpenAPI client removed
- [x] Reference-data pipeline `data-raw/01..04` → `R/sysdata.rda` (SPDX, file formats, access rights, protocols, identifiers.org, DOI prefixes) + `inst/extdata/metrics` + `inst/extdata/web/*.json`
- [x] Engine primitives: `id_parse`, `content_negotiate`/`resolve_landing_page` (httr2), `reference_schema`, `merge_metadata` (+ `levenshtein_ratio`/`token_sort_ratio`), metrics loader, criterium engine, scorer, `fair_assessment` S3 (print/format/as.data.frame/summary), `as_fuji_json`

## Phase 1 — MVP engine (common case)  `[~]`
Harvesters
- [x] DataCite JSON via content negotiation (`collect_datacite` + `map_datacite`)
- [x] Landing-page HTML: schema.org JSON-LD, Dublin Core, OpenGraph, Highwire (`collect_html`)
- [x] schema.org `distribution`/`contentUrl` → `object_content_identifier`
- [x] Signposting (HTTP `Link` headers + typed `<link rel>`) harvester — implemented in Phase 2 (`signposting.R`)
- [x] Data harvester: HEAD content links for size/type (`mime`) — implemented in Phase 4 (`harvest_data.R`)
- [x] Data-link discovery through repository APIs (Zenodo, figshare, Dataverse, Dryad) when no links were harvested (0.2.0, `collect_files.R`)

Evaluators (15 / 17 implemented)
- [x] F1-01MD unique id · F1-02MD persistent id · F2-01M core metadata · F3-01M data-id-included · F4-01M searchable
- [x] A1-01M access info · A1-02MD retrievable · A1.1-01MD standard protocol · A1.2-01MD protocol auth
- [x] I1-01M formal metadata · I3-01M related resources
- [x] R1-01M data content · R1.1-01M license · R1.2-01M provenance · R1.3-02D file format
- [x] I2-01M semantic vocabularies (Phase 3; full linked-vocab index in 0.2.0)
- [x] R1.3-01M community metadata standard (Phase 3)

Fidelity gate (blocks "Phase 1 done")
- [x] Stand up a local pinned F-UJI (metrics_v0.8) as reference
- [x] Conformance harness with per-metric diff; 97.6% agreement over five fixture DOIs (2026-09-22)
- [x] Offline replay tests: canned responses through `httr2::local_mocked_responses()` (0.2.0, `helper-mock.R`)
- [~] Reconcile divergences: only FsF-R1.3-02D on zip archives remains (F-UJI inspects archive contents with Tika)

## Phase 2 — RDF + XML harvesting  `[~]`
- [x] Signposting / typed links: HTTP `Link` header + `<head><link>`; item→data links, cite-as→PID, license, describedby→fetch (`signposting.R`)
- [x] `collect_xml`: DataCite XML + Dublin Core via `xml2` (namespace-stripped); schema detection; merge (`collect_xml.R`)
- [x] `collect_rdf`: content-negotiated JSON-LD parsed natively + mapped; Turtle/RDF-XML via `rdflib` gated on `requireNamespace` with graceful degrade (`collect_rdf.R`)
- [x] Harvest order rewired: embedded → signposting → DataCite JSON → XML → RDF
- [x] Result: data-content links now harvested → Zenodo/PANGAEA reach ~85% (was 65–69%)
- [x] `rdflib`/librdf Turtle path fixed (the SPARQL query used property paths librdf rejects) and tested with a fixture (0.2.0)
- [ ] More XML schemas: ISO19139, MODS, EML, METS (mappings exist in fuji); explicit OAI-PMH endpoint input
- [x] Microdata + RDFa extraction from landing HTML (0.2.0)

## Phase 3 — Community / semantic / software  `[~]`
- [x] Bundle `metadata_standards` (360 namespace URIs, generic vs disciplinary) into sysdata (`data-raw/05`)
- [x] R1.3-01M community metadata standard: detect generic (DataCite/schema.org/DC, RDA-endorsed → test-3) vs disciplinary (→ test-1) from harvested namespaces (`eval_community.R`)
- [x] I2-01M semantic vocabulary: namespace match minus default namespaces vs a registered-vocab set (faithful 0 for plain DataCite, matching F-UJI) (`eval_semantic.R`)
- [x] GitHub harvester: enrich GitHub repos from the REST API (license, description, topics, dates) (`collect_github.R`)
- [x] **All 17 v0.8 metrics now score.** Fidelity vs real F-UJI on figshare DOI: rfair 14/26 vs F-UJI 12.5/26 (gap = environment-dependent PID resolution)
- [x] FRSM software metric version bundled + selectable (`assess_fair(metric_version = "0.7_software")`); deeper GitHub harvest (codemeta.json, CITATION.cff, latest release version, language)
- [x] FRSM-* evaluators (all 17 software metrics) implemented in `eval_frsm.R`, scoring from GitHub file-tree signals (license/tests/CI/requirements/registry-DOI/version); heuristic — not yet validated against an upstream FRSM reference
- [ ] re3data/OAI-PMH/SPARQL/CSW metadata-service endpoints for richer R1.3-01M (disciplinary standards via repository services)
- [x] Linked-vocab (LOD) index for I2-01M: 5,160 namespaces from F-UJI (0.2.0, `data-raw/08`)

## Phase 4 — Optional fidelity tail  `[~]`
- [x] `as_rdf()` result serialization: DQV quality measurements + schema.org Rating JSON-LD (Turtle via optional `rdflib`)
- [x] Headless rendering via `chromote` (`use_headless = FALSE` default; gated, no-op if absent) wired into `assess_fair()`
- [x] Data-file harvester (`harvest_data`): HTTP HEAD content links for MIME type + size (improves R1-01M-2, R1.3-02D); `mime` fallback
- [ ] File format detection inside archives (F-UJI uses Tika); rfair reads declared and served content types from a header-only GET

## Phase 5 — Shiny app  `[~]`
- [x] `inst/shiny-apps/rfair/app.R` (bslib `page_sidebar`, value boxes, cards, tabs) + `launch_rfair()`
- [x] Input DOI/PID/URL + metric version; FAIR doughnut; per-principle table; per-metric DT (pass/fail row colors); debug log
- [x] Reviewer-driven panels: license reusability, access/sensitivity, identifier hygiene
- [x] Download results as F-UJI JSON; boots headless without errors; CRAN-safe parse test
- [ ] shinytest2 smoke test (non-CRAN) once shinytest2 is installed
- [ ] Richer report export (docx/xlsx/csv) and the concentric two-ring donut (see Phase 6 design)

## Phase 6 — JS/TS web app + gh-pages  `[x]`

The web app lives on its own **`webapp` branch** (app at the repo root), so the
`main` branch is the R package only. It deploys to gh-pages `/app` from that
branch; `main` carries only the R package + pkgdown docs (gh-pages root).

- [x] Standalone `webapp` branch: React 19 + TypeScript + Vite 8 + Tailwind 4
- [x] Separate TS scoring engine (criterium engine + evaluators + scorer); reference JSON committed to the branch under `public/data` (regenerated from the package's `inst/extdata/web` via `npm run sync-data` when the package is checked out alongside)
- [x] Client-side harvest from DataCite + Crossref + GitHub (CORS-enabled); CORS landing-page limitation documented in UI + README
- [x] Modern, minimal UI (not an f-uji.net replica): sticky header with light/dark toggle, hero search with example chips, "what is FAIR" empty state, loading skeleton, URL state (`?doi=`), share/copy/download
- [x] **Concentric sunburst summary** (inner F/A/I/R ring + outer per-metric ring, opacity ∝ score, FAIR % in center) as the score hero
- [x] Per-category ring cards + maturity badges, per-metric accordion, reuse/access/hygiene + FAIR-TLC panels, harvested-metadata view
- [x] Vitest unit tests + typecheck + `npm audit` gate in the branch's `deploy.yaml`; build clean (0 vulnerabilities)
- [ ] Playwright browser e2e in CI (manual browse smoke done)
- R↔TS parity: run `tests/conformance/parity.R` after materializing the app with `git worktree add webapp webapp` (esbuild is an explicit devDependency on the branch)

## Cross-cutting  `[~]`

Status is split into what CI / a local command verifies *now*, versus
historical manual runs that need a reference service to reproduce.

**Verified by CI or a runnable local command (current checkout):**
- [x] testthat suite (identifier, merge, scorer, assess, reuse, phase3, xml-signposting, shiny, frsm, integration, plot)
- [x] R↔TS cross-engine parity harness (`tests/conformance/parity.R`) runs from a clean install: `esbuild` is an explicit `webapp` devDependency, the harness bundles `parity-entry.mts` and diffs registry-core metrics R vs TS
- [x] GitHub Actions: `R-CMD-check.yaml` (mac/win/linux + devel), `pkgdown.yaml` (gh-pages root, `clean:false`), and the `webapp` branch `.github/workflows/deploy.yaml` workflow (`deploy-app`); live site at `choxos.github.io/rfair` + `/app`
- [x] roxygen links resolve clean; README; vignettes (`rfair`, `methodology`, `beyond-fuji`, `illustrating-fairness`); `fair_assessment` class + `plot` method docs; `R CMD build` succeeds

**Historical / manual evidence (not reproduced by CI; needs a reference server):**
- [x] **Conformance vs upstream F-UJI 4.0.0 (metrics v0.8)**: 97.6% of 85 metric comparisons over five fixture DOIs on 2026-09-22 (0.1.0: 91.8%). `.github/workflows/conformance.yaml` reruns it monthly against the F-UJI Docker image.
- [~] R↔TS parity previously measured 100% on the registry-core fixture set; the harness is runnable (above) but is not yet a CI gate.

**Still open:**
- [x] Full-pipeline replay tests with httr2 mocked responses (0.2.0)
- [x] Automate F-UJI conformance: scheduled workflow with the F-UJI Docker image, comparison CSV and image digest as an artifact
- [ ] CRAN readiness: full strict `R CMD check` clean in an environment with all `Suggests` + system libs (`librdf`) installed (the fallback check with `_R_CHECK_FORCE_SUGGESTS_=false` is clean); installed-size check. `wand`/`libmagic` were dropped in 0.2.0.

## Reviewer-driven extensions (Haendel review + comments/ folder)  `[x]`
- [x] `license_reuse()` — license presence ≠ open for reuse (CC-BY-NC-ND etc.) + the **(Re)usable Data Project six-category taxonomy** (permissive/copyleft/restrictive/private-pool/copyright/unknown; Carbon et al. 2019, the paper in comments/) via `rdp_category` + `facilitates_reuse`
- [x] `classify_access()` + `reusabledata_rating()` — controlled-access / sensitive data not scored as FAIR failure
- [x] `identifier_hygiene()` — layered/non-persistent PID anti-patterns (e.g. RRID:MGI:…)
- [x] `fair_principles()` / `principle_definition()` — canonical FAIR principles (FAIR-nanopubs / go-fair, w3id.org/fair)
- [x] **`fair_tlc()` — FAIR-TLC (Traceable, Licensed, Connected)**, Haendel et al.'s "FAIR+" framework (doi:10.5281/zenodo.203295, the Monarch/TransMed RFI response + FORCE11 blog in comments/)
- [x] Wired into `assess_fair()` output + print, the **Shiny app** (Reuse tab), and the **web app** (Reuse & access tab)
- [x] Vignette `beyond-fuji.Rmd` framing the review responses (reuse, sensitivity, hygiene, FAIR-TLC)
- Note: the comments/ PDFs were the source papers (reusabledata, FAIR-nanopubs, FAIR-TLC RFI) — all actionable items implemented; the remaining comments content is manuscript-discussion prose, not code.

## Known limitations / fidelity gaps (track for conformance)
- Data-content links absent for some records (no schema.org `distribution`) → F3/A1-02MD-2/R1.3-02D under-score
- `token_sort_ratio` preprocessing is approximate vs thefuzz/rapidfuzz (affects only scalar-replacement ties; low score impact)
- I2-01M (semantic vocab) implemented but scores 0 for plain DataCite metadata (only registry/default namespaces present) — matches F-UJI; R1.3-01M (community standard) implemented (Phase 3)
- RDF-only repositories under-score until Phase 2
- JS-rendered landing pages under-score until Phase 4 (headless)

## Next (after 0.2.0)
- [ ] FRSM validation study: expert ratings of a repository sample with `inst/extdata/frsm_validation_template.csv`, agreement with `frsm_agreement()`; tighten or drop heuristics that disagree (FRSM-09-A1-2 and FRSM-06-F2-3 are the weakest proxies)
- [ ] `webapp` TS engine: port the 0.2.0 scoring changes (CSL JSON, unresolved identifiers, data-link status) or document the divergence in `parity.R`
- [ ] Bitbucket support in the forge harvester (its API has no recursive tree or releases, so it needs its own adapter)
