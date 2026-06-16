# rfuji roadmap

Native, pure-R reimplementation of the F-UJI FAIR assessment engine, plus a
Shiny app and a static JS/TS web app. This file tracks everything still to do so
nothing is forgotten. See `~/.claude/plans/i-forked-rfuji-r-deep-backus.md` for
the approved plan and design rationale.

Legend: `[x]` done · `[~]` partial · `[ ]` todo

## Phase 0 — Foundations  `[x]`
- [x] Package scaffolding (DESCRIPTION v2, roxygen NAMESPACE, `.onLoad`, MIT LICENSE, `.Rbuildignore`); generated OpenAPI client removed
- [x] Reference-data pipeline `data-raw/01..04` → `R/sysdata.rda` (SPDX, file formats, access rights, protocols, identifiers.org, DOI prefixes) + `inst/extdata/metrics` + `inst/extdata/web/*.json`
- [x] Engine primitives: `id_parse`, `content_negotiate`/`resolve_landing_page` (httr2), `reference_schema`, `merge_metadata` (+ `levenshtein_ratio`/`token_sort_ratio`), metrics loader, criterium engine, scorer, `fair_assessment` S3 (print/format/as.data.frame/summary), `as_fuji_json`

## Phase 1 — MVP engine (common case)  `[~]`
Harvesters
- [x] DataCite JSON via content negotiation (`collect_datacite` + `map_datacite`)
- [x] Landing-page HTML: schema.org JSON-LD, Dublin Core, OpenGraph, Highwire (`collect_html`)
- [x] schema.org `distribution`/`contentUrl` → `object_content_identifier`
- [x] Signposting (HTTP `Link` headers + typed `<link rel>`) harvester — implemented in Phase 2 (`signposting.R`)
- [x] Data harvester: HEAD content links for size/type (`mime`) — implemented in Phase 4 (`harvest_data.R`)
- [ ] Improve data-link discovery for repos that expose files via API (e.g. Zenodo files endpoint) — currently some records yield no `object_content_identifier`

Evaluators (15 / 17 implemented)
- [x] F1-01MD unique id · F1-02MD persistent id · F2-01M core metadata · F3-01M data-id-included · F4-01M searchable
- [x] A1-01M access info · A1-02MD retrievable · A1.1-01MD standard protocol · A1.2-01MD protocol auth
- [x] I1-01M formal metadata · I3-01M related resources
- [x] R1-01M data content · R1.1-01M license · R1.2-01M provenance · R1.3-02D file format
- [ ] I2-01M semantic vocabularies — needs linked-vocab corpus → Phase 3
- [ ] R1.3-01M community metadata standard — needs standards corpus → Phase 3

Fidelity gate (blocks "Phase 1 done")
- [ ] Stand up a local pinned F-UJI (metrics_v0.8) as reference
- [ ] Conformance harness over ~15 DataCite DOIs; per-metric diff; target ≥85% agreement
- [ ] `httptest2` cassettes so unit + replay tests run offline / CRAN-safe
- [ ] Reconcile divergences (mapping/merge subtleties, protocol/auth edge cases)

## Phase 2 — RDF + XML harvesting  `[~]`
- [x] Signposting / typed links: HTTP `Link` header + `<head><link>`; item→data links, cite-as→PID, license, describedby→fetch (`signposting.R`)
- [x] `collect_xml`: DataCite XML + Dublin Core via `xml2` (namespace-stripped); schema detection; merge (`collect_xml.R`)
- [x] `collect_rdf`: content-negotiated JSON-LD parsed natively + mapped; Turtle/RDF-XML via `rdflib` gated on `requireNamespace` with graceful degrade (`collect_rdf.R`)
- [x] Harvest order rewired: embedded → signposting → DataCite JSON → XML → RDF
- [x] Result: data-content links now harvested → Zenodo/PANGAEA reach ~85% (was 65–69%)
- [ ] `rdflib`/librdf Turtle path is implemented but UNTESTED (install librdf + add a fixture)
- [ ] More XML schemas: ISO19139, MODS, EML, METS (mappings exist in fuji); explicit OAI-PMH endpoint input
- [ ] Microdata + RDFa extraction from landing HTML

## Phase 3 — Community / semantic / software  `[~]`
- [x] Bundle `metadata_standards` (360 namespace URIs, generic vs disciplinary) into sysdata (`data-raw/05`)
- [x] R1.3-01M community metadata standard: detect generic (DataCite/schema.org/DC, RDA-endorsed → test-3) vs disciplinary (→ test-1) from harvested namespaces (`eval_community.R`)
- [x] I2-01M semantic vocabulary: namespace match minus default namespaces vs a registered-vocab set (faithful 0 for plain DataCite, matching F-UJI) (`eval_semantic.R`)
- [x] GitHub harvester: enrich GitHub repos from the REST API (license, description, topics, dates) (`collect_github.R`)
- [x] **All 17 v0.8 metrics now score.** Fidelity vs real F-UJI on figshare DOI: rfuji 14/26 vs F-UJI 12.5/26 (gap = environment-dependent PID resolution)
- [x] FRSM software metric version bundled + selectable (`assess_fair(metric_version = "0.7_software")`); deeper GitHub harvest (codemeta.json, CITATION.cff, latest release version, language)
- [x] FRSM-* evaluators (all 17 software metrics) implemented in `eval_frsm.R`, scoring from GitHub file-tree signals (license/tests/CI/requirements/registry-DOI/version); heuristic — not yet validated against an upstream FRSM reference
- [ ] re3data/OAI-PMH/SPARQL/CSW metadata-service endpoints for richer R1.3-01M (disciplinary standards via repository services)
- [ ] linked-vocab (LOD) corpus for fuller I2-01M (currently a curated vocab subset)

## Phase 4 — Optional fidelity tail  `[~]`
- [x] `as_rdf()` result serialization: DQV quality measurements + schema.org Rating JSON-LD (Turtle via optional `rdflib`)
- [x] Headless rendering via `chromote` (`use_headless = FALSE` default; gated, no-op if absent) wired into `assess_fair()`
- [x] Data-file harvester (`harvest_data`): HTTP HEAD content links for MIME type + size (improves R1-01M-2, R1.3-02D); `mime` fallback
- [ ] Deeper libmagic content sniffing via `wand` (currently HEAD content-type + extension only)

## Phase 5 — Shiny app  `[~]`
- [x] `inst/shiny-apps/rfuji/app.R` (bslib `page_sidebar`, value boxes, cards, tabs) + `launch_rfuji()`
- [x] Input DOI/PID/URL + metric version; FAIR doughnut; per-principle table; per-metric DT (pass/fail row colors); debug log
- [x] Reviewer-driven panels: license reusability, access/sensitivity, identifier hygiene
- [x] Download results as F-UJI JSON; boots headless without errors; CRAN-safe parse test
- [ ] shinytest2 smoke test (non-CRAN) once shinytest2 is installed
- [ ] Richer report export (docx/xlsx/csv) and the concentric two-ring donut (see Phase 6 design)

## Phase 6 — JS/TS web app + gh-pages  `[~]`
- [x] `webapp/` (subdir on main, excluded from R build): React + TS + Vite + Tailwind
- [x] Separate TS scoring engine (criterium engine + evaluators + scorer) reading `inst/extdata/web/*.json` (synced by `npm run sync-data`)
- [x] Client-side harvest from DataCite + Crossref (CORS-enabled); CORS landing-page limitation documented in UI + README
- [x] UI: FAIR donut, category cards + maturity badges, per-metric accordion report, reuse/sensitivity/hygiene panels, harvested-metadata view, JSON download
- [x] Build passes (164 KB JS / 53 KB gzip); engine validated live (Zenodo 61.5%, figshare 53.8% — registry-only, matches R for registry-derivable metrics)
- [x] `deploy-app.yaml` → gh-pages `/app` (`keep_files: true` preserves pkgdown root)
- [x] Concentric two-ring donut (inner F/A/I/R + outer individual metrics, opacity ∝ score)
- [x] FAIR-TLC + RDP license category surfaced in the Reuse & access tab
- [ ] Client-side GitHub API harvest (api.github.com is CORS-enabled) for software objects
- [ ] Vitest unit tests + Playwright e2e in CI (R↔TS parity script exists in `tests/conformance/parity.R`)
- [ ] Deviation from plan: built as a `webapp/` subdir (not a separate branch) to avoid mid-session branch switching; functionally identical for gh-pages

### Visual design (model on https://www.f-uji.net result page; improve on it)
- [ ] **Concentric donut** (Chart.js doughnut, two rings): inner ring = F/A/I/R categories, outer ring = the individual metrics with opacity proportional to score%; total score % in the center. Category colors F `#118AB2`, A `#06D6A0`, I `#FFD166`, R `#EF476F`.
- [ ] **Per-category cards**: small score donut + "earned of total" + a FAIR-level (maturity) badge. Maturity colors: incomplete `#fe7d37`, initial `#dfb317`, moderate `#97ca00`, advanced `#4c1` (0/1/2/3).
- [ ] **Accordion report**, one collapsible per metric: FAIR level (X of 3) + badge, score (earned/total), Output JSON, a metric-tests table (test id, name, score, maturity, pass/fail icon), and Debug messages (when test_debug).
- [ ] **Harvested-metadata** collapsible showing the unmerged source records (method, format, schema, namespaces, mapped fields) — rfuji already produces these in `metadata_unmerged`.
- [ ] Header summary card: resolved PID/URL, metric version + spec link, software version, JSON export button.
- [ ] rfuji additions beyond F-UJI's page: reuse (open vs restrictive), controlled-access/sensitivity, identifier-hygiene panels; embeddable result JSON-LD (schema:Rating) like F-UJI emits.
- Note: the same donut + card components should back the Shiny app (Phase 5) so the two UIs share a visual language.

## Cross-cutting  `[~]`
- [x] testthat suite (identifier, merge, scorer, assess, reuse, phase3, xml-signposting, shiny)
- [x] **R↔TS cross-engine parity harness** (`tests/conformance/parity.R`): 100% agreement on registry-core metrics (e.g. 30/30 over the 5-identifier fixture set) — no drift between the two engines
- [x] **Conformance vs upstream F-UJI 4.0.0 (metrics v0.8) — validated: 94.1% on Zenodo (16/17 metrics exact), 85.3% over PANGAEA+Dryad.** Only FsF-R1.3-02D (data file format) diverges (Tika vs HEAD). Meets the ≥85% gate.
- [ ] `httptest2` cassettes for full-pipeline replay (unit tests already offline via `resolve = FALSE`)
- [x] GitHub Actions: `R-CMD-check.yaml` (mac/win/linux + devel), `pkgdown.yaml` (gh-pages root, `clean:false`), `deploy-app.yaml`; `_pkgdown.yml` (untested in CI until first push)
- [x] roxygen links resolve clean; README rewritten; getting-started vignette (`vignettes/rfuji.Rmd`); `fair_assessment` class doc; `R CMD build` succeeds
- [ ] More vignettes (interpreting scores, reuse/sensitivity deep-dive)
- [ ] CRAN readiness: full `R CMD check` clean across platforms (network examples already `\donttest`/`\dontrun`); installed size check; `cran-comments.md`

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
