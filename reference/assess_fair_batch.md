# Assess the FAIRness of a batch of identifiers

Runs
[`assess_fair()`](https://choxos.github.io/rfair/reference/assess_fair.md)
over a vector of identifiers and returns one tidy row per identifier
(deduplicated). Failures are captured in an `error` column rather than
aborting the batch.

## Usage

``` r
assess_fair_batch(ids, metric_version = "0.8", quiet = FALSE, ...)
```

## Arguments

- ids:

  Character vector of DOIs, PIDs, URLs, or identifiers.org codes.

- metric_version:

  Metric version (see
  [`rfair_metric_versions()`](https://choxos.github.io/rfair/reference/rfair_metric_versions.md)).

- quiet:

  If `FALSE` (default), print per-identifier progress.

- ...:

  Passed to
  [`assess_fair()`](https://choxos.github.io/rfair/reference/assess_fair.md).

## Value

A data frame with one row per unique identifier: `identifier`,
`metric_version`, `scheme`, `is_persistent`, `resolved_url`,
`fair_percent`, `F`, `A`, `I`, `R`, `maturity`, `n_pass`, `n_metrics`,
`error`.

## See also

[`assess_data_code()`](https://choxos.github.io/rfair/reference/assess_data_code.md),
[`assess_fair()`](https://choxos.github.io/rfair/reference/assess_fair.md)

## Examples

``` r
# \donttest{
assess_fair_batch(c("https://doi.org/10.5281/zenodo.8347772", "geo:GSE12345"))
#> [1/2] assessing https://doi.org/10.5281/zenodo.8347772
#> [2/2] assessing geo:GSE12345
#>                               identifier metric_version scheme is_persistent
#> 1 https://doi.org/10.5281/zenodo.8347772            0.8    doi          TRUE
#> 2                           geo:GSE12345            0.8    geo          TRUE
#>                                                  resolved_url fair_percent
#> 1                          https://zenodo.org/records/8347772        88.46
#> 2 https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE12345        19.23
#>        F      A     I     R maturity n_pass n_metrics error
#> 1 100.00 100.00 66.67 83.33      2.5     15        17  <NA>
#> 2  28.57  42.86  0.00  0.00      1.0      5        17  <NA>
# }
```
