# rfair 0.2.0

Scores can differ from rfair 0.1.0: several fixes below change what counts as
evidence, and new metadata sources find evidence that was missed before. Rerun
assessments before comparing them with 0.1.0 results. Agreement with the
reference F-UJI 4.0.0 service (metrics v0.8, five fixture DOIs, 85 metric
comparisons) rose from 91.8% to 97.6%; see `tests/conformance/README.md`.

## Scoring fixes

* `id_parse()` no longer treats a plain URL with a numeric path segment (for
  example `https://figshare.com/articles/dataset/foo/12345/1`) as a Handle. Such
  URLs were marked persistent and resolved through `hdl.handle.net` instead of
  their own page. The Handle pattern is now anchored at the start, as in
  F-UJI's `verify_handle()`.
* An identifier that does not resolve is no longer reported or scored as
  resolved. `resolved_url` is `NA`, the new `resolution` element records the
  attempt (URL, HTTP status, error), and `print()` shows it as unresolved.
  FsF-A1-02MD-1 (metadata retrievable) now requires a harvested metadata
  record, as F-UJI's `testMetadataRetrievable` does; a page that resolves but
  offers no extractable metadata no longer earns it. A nonexistent DOI dropped
  from 17.3% to 13.5%; the remaining points (identifier scheme, HTTP protocol)
  are the ones F-UJI also awards.
* FsF-A1-02MD-2 (data retrievable) now requires a data link that answers with
  a 2xx status, as in F-UJI. Up to five links are probed with a GET that is
  closed once the headers arrive; HEAD hung on repositories that build files
  on request.
* schema.org `isAccessibleForFree` is read as an access statement, as F-UJI
  does (FsF-A1-01M, `classify_access()`).
* RDF graph metadata (Turtle, RDF/XML) was never harvested: the query used
  SPARQL 1.1 property paths, which librdf rejects. Triples are now mapped in R,
  creator nodes resolve to names, and predicate namespaces feed the semantic
  vocabulary and community standard metrics. Scores can rise for repositories
  that serve RDF.
* Metadata sources that fail are recorded in the new `harvest_errors` element.
  API rate limits (GitHub, GitLab, Codeberg, repository APIs) are also raised
  as an `rfair_rate_limit` warning and stop further calls to that API for the
  assessment, instead of silently lowering software scores.
* `license_reuse()` recognizes the OGL, Etalab, CDLA, DL-DE, and NLOD open data
  licenses, and classes MPL as copyleft.
* Link headers split only between links, so URLs containing commas survive.
* FsF-I2-01M (semantic vocabularies) checks namespaces against F-UJI's full
  linked-vocabulary index (5,160 registered namespaces from LOV, BioPortal,
  Bioregistry, SeaDataNet, and others) instead of a curated list of 20, and
  also counts vocabulary terms used as metadata values (for example an SPDX
  license URL), as F-UJI does. XML metadata keeps its declared namespaces.
* Assessments record the version of the bundled reference data in
  `reference_data`.

## New metadata sources

* DOIs registered outside DataCite (Crossref, mEDRA, JaLC, KISTI) are harvested
  through CSL JSON content negotiation: title, authors, publisher, dates,
  abstract, subjects, licenses, Crossref text-mining links, and relations. The
  registration agency is looked up (bundled prefix table, then
  `https://doi.org/ra/`), and the DataCite requests are skipped for DOIs
  registered elsewhere. CSL metadata does not satisfy FsF-F4-01M-2, which is
  specific to DataCite.
* When no data links were found, the file list is read from the repository
  API: Zenodo, figshare, Dataverse, and Dryad.
* schema.org metadata embedded as microdata or RDFa is harvested, next to
  JSON-LD, and counts as embedded metadata for FsF-F4-01M and FsF-I1-01M. As
  in F-UJI, only CreativeWork types count (not Organization or
  BreadcrumbList).

## Software assessment

* Code repositories on GitLab (API v4, nested groups) and Codeberg or any
  Forgejo/Gitea instance (API v1) are harvested, next to GitHub. Tokens are
  read from `GITHUB_PAT` (then `GITHUB_TOKEN`), `GITLAB_PAT`, and
  `CODEBERG_TOKEN`.
* Under the software metrics, a DOI whose metadata links a repository (for
  example Zenodo's `IsSupplementTo` link to GitHub) is bridged to it: the
  repository supplies the software signals and the DOI counts as the registry
  DOI. rfair's own Zenodo concept DOI rose from 2.2% to 100%.
* Archiving is checked against Software Heritage and the language package
  registry (CRAN from `DESCRIPTION`, PyPI from `pyproject.toml` or
  `setup.cfg`), not only against text mentions.
* The harvested repository signals are returned as `a$software`.
* FRSM results are labeled `evidence_type = "heuristic"`, and `print()` says
  so: the scores come from repository signals that have not been validated
  against expert judgement. `frsm_agreement()` compares them with expert
  ratings (percent agreement and Cohen's kappa per test, plus agreement
  between raters), and `inst/extdata/frsm_validation_template.csv` is a
  rating sheet for all 45 FRSM tests. The validation study itself is still to
  be done.

## Guidance

* `fair_recommendations()` lists every failed test with one concrete action,
  largest score gain first (the gain allows for each metric's cap). The Shiny
  app shows it in a "How to improve" tab.
* `fair_compare()` reports per-metric or per-test changes between two
  assessments.

## Machine-readable results

* `as_rdf()` adds one DQV quality measurement per metric and one FAIR Test
  Result per metric test in the OSTrails FAIR Testing Resource vocabulary
  (<https://w3id.org/ftr/>, version 1.3.0): pass or fail, completion, the
  evidence as a log, and for failed tests the `fair_recommendations()` action
  as a suggestion. Turtle output now checks for the `jsonld` package it needs.

## Batch runs and HTTP

* `assess_fair()` gains `max_time`, a time budget for the whole assessment.
* `assess_fair_batch()` and `assess_data_code()` gain `workers` (parallel
  assessment by forking; serial on Windows), `keep` (the full assessments in
  the `"assessments"` attribute), and `previous` (resume an interrupted run),
  plus `resolved` and `http_status` columns.
* All requests share one policy: retry on 429 and 503 with capped waits, a
  per-host rate limit (`options(rfair.rate_per_host)`), and an optional HTTP
  cache (`options(rfair.cache_dir)`). Bodies are decoded from their declared
  charset to UTF-8.

## Security

* `options(rfair.block_private_hosts = TRUE)` refuses non-http(s) URLs and
  hosts that resolve to loopback, private, link-local, or cloud metadata
  addresses. The request connects to the address that was checked (libcurl's
  CURLOPT_RESOLVE), so DNS rebinding cannot swap it, and every redirect hop is
  checked, with credentials dropped when a redirect changes scheme, host, or
  port. The bundled Plumber API and Shiny app turn it on, since both fetch
  visitor-supplied URLs. Headless rendering (`use_headless`) runs in a browser
  outside this guard.
* The Plumber API refuses headless rendering unless the server sets
  `RFAIR_API_ALLOW_HEADLESS=true`.

## Package metadata and tests

* `CITATION.cff`, `codemeta.json`, `.zenodo.json`, and
  `ro-crate-metadata.json` are generated from `DESCRIPTION` by
  `data-raw/07-build-metadata.R`, so title, authors, contributors, and
  dependencies agree. `citation("rfair")` reads the title and version from the
  package metadata. The CRAN DOI is recorded.
* The FAIR principles links point to the GO FAIR Foundation's new address.
* Removed the unused suggested packages `httptest2`, `jqr`, `wand`, and
  `covr`. The documentation no longer mentions libmagic file sniffing, which
  was never implemented.
* The harvesters are tested end to end offline, with canned responses served
  through `httr2::local_mocked_responses()`.
* A scheduled workflow compares rfair with the F-UJI Docker image monthly.

# rfair 0.1.0

First release. `rfair` is a native R implementation of the F-UJI / FAIRsFAIR
research data object assessment metrics and the FRSM (FAIR for Research Software)
metrics. It performs the entire assessment in R, with no external server.

## Assessment

* `assess_fair()` resolves a DOI, persistent identifier, URL, or code
  repository, harvests its metadata, and scores it against the FAIR metrics,
  returning a `fair_assessment` object.
* Multiple metric sets, listed by `rfair_metric_versions()`: the current F-UJI
  data metrics (v0.8) by default, several legacy and domain-specific versions
  (0.2-0.8, plus social-science and environmental variants), and the FRSM
  research-software metrics (0.7).
* Metadata harvesting from registries (DataCite, Crossref, GitHub), landing-page
  embedded metadata (schema.org JSON-LD, Dublin Core, OpenGraph, Highwire),
  signposting and typed links, content-negotiated XML (DataCite XML, MODS, EML,
  ISO 19139) and RDF / JSON-LD, and optional user-supplied metadata-service
  endpoints (OAI-PMH, OGC CSW, SPARQL, DCAT, schema.org, RO-Crate, CKAN).
* Software FAIR: pass a GitHub repository with `metric_version = "0.7_software"`
  to score it against the FRSM metrics from its repository signals (license,
  README, citation/codemeta, tests, CI, dependencies, coverage, releases,
  contributors). The FRSM metrics operationalize the FAIR Principles for
  Research Software (FAIR4RS; Chue Hong et al. 2022, <doi:10.15497/RDA00068>).
* `id_parse()` recognizes DOI, Handle, ARK, URN, UUID, identifiers.org / w3id,
  and compact `prefix:accession` identifiers.

## Working with the result

* The `fair_assessment` object has `print()`, `summary()`, `as.data.frame()`,
  and `plot()` methods. `plot()` draws a category scorecard, a per-metric
  breakdown, or a concentric FAIR `"sunburst"`.
* `as_fuji_json()` exports the assessment in the F-UJI `FAIRResults` JSON schema;
  `as_rdf()` exports W3C DQV quality measurements plus a schema.org `Rating`
  (JSON-LD or, with `rdflib`, Turtle).
* A bundled example assessment, `fair_example`, is provided for offline use.

## Beyond F-UJI

* `license_reuse()` judges whether a license actually permits reuse, using the
  (Re)usable Data Project taxonomy; `reusabledata_rating()` looks up curated
  repository ratings.
* `classify_access()` flags controlled-access and sensitive data (which are not
  FAIR failures).
* `identifier_hygiene()` checks identifiers for layered or non-persistent forms.
* `fair_tlc()` reports the FAIR-TLC (Traceable, Licensed, Connected) indicators.
* `fair_principles()` and `principle_definition()` provide the canonical FAIR
  principle definitions; `fair4rs_principles()` provides the FAIR4RS principles
  for research software, and `principle_definition()` resolves FRSM software
  metrics to their FAIR4RS statement.

## Batch assessment and rtransparent

* `assess_fair_batch()` scores a vector of identifiers into one tidy row each.
* `assess_data_code()` ingests the data and code identifiers that the
  rtransparent package extracts from articles (its `open_data_links` and
  `open_code_links`) and scores each (FsF for data, FRSM for code).
* `split_identifiers()` parses the `" ; "`-joined identifier strings.

## Interfaces

* `launch_rfair()` opens a bslib Shiny app for interactive assessment.
* A no-install browser version is published at
  <https://choxos.github.io/rfair/app/>.
* A Plumber API scaffold and an OpenAPI contract are installed under
  `system.file("plumber", package = "rfair")` and
  `system.file("openapi", package = "rfair")`.
