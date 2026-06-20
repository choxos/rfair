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
  contributors).
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
  principle definitions.

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
