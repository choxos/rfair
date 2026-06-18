# Assess the FAIRness of a research data object.

Resolves a persistent identifier or URL, harvests its metadata, and
scores it against the FAIRsFAIR metrics, entirely in R.

## Usage

``` r
assess_fair(
  id,
  metric_version = "0.8",
  use_datacite = TRUE,
  metadata_service_endpoint = NULL,
  metadata_service_type = metadata_service_types(),
  test_debug = FALSE,
  resolve = TRUE,
  timeout = 15,
  use_headless = FALSE
)
```

## Arguments

- id:

  A persistent identifier or URL (DOI, Handle, ARK, URN, ...).

- metric_version:

  Metric version to use (see
  [`rfuji_metric_versions()`](https://choxos.github.io/rfuji/reference/rfuji_metric_versions.md)).

- use_datacite:

  Whether to query DataCite for registry metadata.

- metadata_service_endpoint:

  Optional URL of an additional metadata document to harvest, or a ready
  protocol query URL (for example an OAI-PMH `GetRecord` URL, an OGC CSW
  `GetRecordById` URL, a SPARQL query URL, or a DCAT / schema.org
  JSON-LD / RO-Crate / DataCite / Crossref / CKAN document). The
  response is parsed with the same format-gated collectors used for
  content negotiation, so only a recognized metadata document
  contributes.

- metadata_service_type:

  Type hint for `metadata_service_endpoint`. `"schema_org"` is harvested
  as JSON-LD; the others are tried as an XML metadata document, then
  RDF.

- test_debug:

  If `TRUE`, collect debug log messages in the result.

- resolve:

  If `TRUE`, resolve the identifier to its landing page.

- timeout:

  Per-request timeout in seconds.

- use_headless:

  If `TRUE` and the optional `chromote` package is installed, render
  JavaScript-heavy landing pages with a headless browser before
  harvesting embedded metadata.

## Value

A
[fair_assessment](https://choxos.github.io/rfuji/reference/fair_assessment.md)
object.

## Examples

``` r
# \donttest{
a <- assess_fair("https://doi.org/10.5281/zenodo.8347772")
summary(a)
#>   category earned total percent maturity
#> 1        F    6.5     7   92.86      3.0
#> 2        A    7.0     7  100.00      3.0
#> 3        I    4.0     6   66.67      2.0
#> 4        R    5.0     6   83.33      2.0
#> 5     FAIR   22.5    26   86.54      2.5
# }
```
