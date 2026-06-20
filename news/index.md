# Changelog

## rfair 0.1.0

First release. `rfair` is a native R implementation of the F-UJI /
FAIRsFAIR research data object assessment metrics and the FRSM (FAIR for
Research Software) metrics. It performs the entire assessment in R, with
no external server.

### Assessment

- [`assess_fair()`](https://choxos.github.io/rfair/reference/assess_fair.md)
  resolves a DOI, persistent identifier, URL, or code repository,
  harvests its metadata, and scores it against the FAIR metrics,
  returning a `fair_assessment` object.
- Multiple metric sets, listed by
  [`rfair_metric_versions()`](https://choxos.github.io/rfair/reference/rfair_metric_versions.md):
  the current F-UJI data metrics (v0.8) by default, several legacy and
  domain-specific versions (0.2-0.8, plus social-science and
  environmental variants), and the FRSM research-software metrics (0.7).
- Metadata harvesting from registries (DataCite, Crossref, GitHub),
  landing-page embedded metadata (schema.org JSON-LD, Dublin Core,
  OpenGraph, Highwire), signposting and typed links, content-negotiated
  XML (DataCite XML, MODS, EML, ISO 19139) and RDF / JSON-LD, and
  optional user-supplied metadata-service endpoints (OAI-PMH, OGC CSW,
  SPARQL, DCAT, schema.org, RO-Crate, CKAN).
- Software FAIR: pass a GitHub repository with
  `metric_version = "0.7_software"` to score it against the FRSM metrics
  from its repository signals (license, README, citation/codemeta,
  tests, CI, dependencies, coverage, releases, contributors).
- [`id_parse()`](https://choxos.github.io/rfair/reference/id_parse.md)
  recognizes DOI, Handle, ARK, URN, UUID, identifiers.org / w3id, and
  compact `prefix:accession` identifiers.

### Working with the result

- The `fair_assessment` object has
  [`print()`](https://rdrr.io/r/base/print.html),
  [`summary()`](https://rdrr.io/r/base/summary.html),
  [`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html), and
  [`plot()`](https://rdrr.io/r/graphics/plot.default.html) methods.
  [`plot()`](https://rdrr.io/r/graphics/plot.default.html) draws a
  category scorecard, a per-metric breakdown, or a concentric FAIR
  `"sunburst"`.
- [`as_fuji_json()`](https://choxos.github.io/rfair/reference/as_fuji_json.md)
  exports the assessment in the F-UJI `FAIRResults` JSON schema;
  [`as_rdf()`](https://choxos.github.io/rfair/reference/as_rdf.md)
  exports W3C DQV quality measurements plus a schema.org `Rating`
  (JSON-LD or, with `rdflib`, Turtle).
- A bundled example assessment, `fair_example`, is provided for offline
  use.

### Beyond F-UJI

- [`license_reuse()`](https://choxos.github.io/rfair/reference/license_reuse.md)
  judges whether a license actually permits reuse, using the (Re)usable
  Data Project taxonomy;
  [`reusabledata_rating()`](https://choxos.github.io/rfair/reference/reusabledata_rating.md)
  looks up curated repository ratings.
- [`classify_access()`](https://choxos.github.io/rfair/reference/classify_access.md)
  flags controlled-access and sensitive data (which are not FAIR
  failures).
- [`identifier_hygiene()`](https://choxos.github.io/rfair/reference/identifier_hygiene.md)
  checks identifiers for layered or non-persistent forms.
- [`fair_tlc()`](https://choxos.github.io/rfair/reference/fair_tlc.md)
  reports the FAIR-TLC (Traceable, Licensed, Connected) indicators.
- [`fair_principles()`](https://choxos.github.io/rfair/reference/fair_principles.md)
  and
  [`principle_definition()`](https://choxos.github.io/rfair/reference/principle_definition.md)
  provide the canonical FAIR principle definitions.

### Batch assessment and rtransparent

- [`assess_fair_batch()`](https://choxos.github.io/rfair/reference/assess_fair_batch.md)
  scores a vector of identifiers into one tidy row each.
- [`assess_data_code()`](https://choxos.github.io/rfair/reference/assess_data_code.md)
  ingests the data and code identifiers that the rtransparent package
  extracts from articles (its `open_data_links` and `open_code_links`)
  and scores each (FsF for data, FRSM for code).
- [`split_identifiers()`](https://choxos.github.io/rfair/reference/split_identifiers.md)
  parses the `" ; "`-joined identifier strings.

### Interfaces

- [`launch_rfair()`](https://choxos.github.io/rfair/reference/launch_rfair.md)
  opens a bslib Shiny app for interactive assessment.
- A no-install browser version is published at
  <https://choxos.github.io/rfair/app/>.
- A Plumber API scaffold and an OpenAPI contract are installed under
  `system.file("plumber", package = "rfair")` and
  `system.file("openapi", package = "rfair")`.
