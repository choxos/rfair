# Assess the FAIRness of a research data object.

Resolves a persistent identifier or URL, harvests its metadata, and
scores it against the FAIRsFAIR metrics, entirely in R.

## Usage

``` r
assess_fair(
  id,
  metric_version = "0.8",
  use_datacite = TRUE,
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
#> 1        F      7     7  100.00      3.0
#> 2        A      7     7  100.00      3.0
#> 3        I      4     6   66.67      2.0
#> 4        R      5     6   83.33      2.0
#> 5     FAIR     23    26   88.46      2.5
# }
```
