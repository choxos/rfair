# Package index

## Assessment

- [`assess_fair()`](https://choxos.github.io/rfair/reference/assess_fair.md)
  : Assess the FAIRness of a research data object.
- [`as_fair_json()`](https://choxos.github.io/rfair/reference/as_fair_json.md)
  : Convert a FAIR assessment to F-UJI-compatible JSON.
- [`id_parse()`](https://choxos.github.io/rfair/reference/id_parse.md) :
  Parse a persistent identifier or URL.
- [`rfair_metric_versions()`](https://choxos.github.io/rfair/reference/rfair_metric_versions.md)
  : List the metric versions bundled with rfair.

## Batch assessment and rtransparent

- [`assess_data_code()`](https://choxos.github.io/rfair/reference/assess_data_code.md)
  : Assess the FAIRness of the data and code shared in articles
  (rtransparent)
- [`assess_fair_batch()`](https://choxos.github.io/rfair/reference/assess_fair_batch.md)
  : Assess the FAIRness of a batch of identifiers
- [`split_identifiers()`](https://choxos.github.io/rfair/reference/split_identifiers.md)
  : Split a joined identifier string into individual identifiers.

## Assessment object

- [`fair_assessment`](https://choxos.github.io/rfair/reference/fair_assessment.md)
  :

  The `fair_assessment` object

- [`as.data.frame(`*`<fair_assessment>`*`)`](https://choxos.github.io/rfair/reference/as.data.frame.fair_assessment.md)
  : Convert a FAIR assessment to a per-metric data frame.

- [`summary(`*`<fair_assessment>`*`)`](https://choxos.github.io/rfair/reference/summary.fair_assessment.md)
  : Summarize a FAIR assessment as an F/A/I/R score table.

- [`plot(`*`<fair_assessment>`*`)`](https://choxos.github.io/rfair/reference/plot.fair_assessment.md)
  : Plot a FAIR assessment as a scorecard

## Example data

- [`fair_example`](https://choxos.github.io/rfair/reference/fair_example.md)
  : An example FAIR assessment

## Beyond F-UJI (reuse, sensitivity, hygiene, FAIR-TLC)

- [`license_reuse()`](https://choxos.github.io/rfair/reference/license_reuse.md)
  : Assess the reuse permissions granted by a license.
- [`classify_access()`](https://choxos.github.io/rfair/reference/classify_access.md)
  : Classify the access level and sensitivity of a data object.
- [`reusabledata_rating()`](https://choxos.github.io/rfair/reference/reusabledata_rating.md)
  : Look up a (Re)usable Data Project curation for a source.
- [`identifier_hygiene()`](https://choxos.github.io/rfair/reference/identifier_hygiene.md)
  : Check an identifier against best-practice / hygiene heuristics.
- [`fair_principles()`](https://choxos.github.io/rfair/reference/fair_principles.md)
  : The canonical FAIR (sub)principles.
- [`principle_definition()`](https://choxos.github.io/rfair/reference/principle_definition.md)
  : Canonical definition of the FAIR principle a metric maps to.
- [`fair_tlc()`](https://choxos.github.io/rfair/reference/fair_tlc.md) :
  FAIR-TLC indicators (Traceable, Licensed, Connected)
- [`as_rdf()`](https://choxos.github.io/rfair/reference/as_rdf.md) :
  Serialize a FAIR assessment to RDF (DQV + schema.org Rating).

## App

- [`launch_rfair()`](https://choxos.github.io/rfair/reference/launch_rfair.md)
  : Launch the rfair Shiny app
