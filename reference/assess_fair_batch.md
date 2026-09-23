# Assess the FAIRness of a batch of identifiers

Runs
[`assess_fair()`](https://choxos.github.io/rfair/reference/assess_fair.md)
over a vector of identifiers and returns one tidy row per identifier
(deduplicated). Failures are captured in an `error` column rather than
aborting the batch.

## Usage

``` r
assess_fair_batch(
  ids,
  metric_version = "0.8",
  quiet = FALSE,
  workers = 1L,
  keep = FALSE,
  previous = NULL,
  ...
)
```

## Arguments

- ids:

  Character vector of DOIs, PIDs, URLs, or identifiers.org codes.

- metric_version:

  Metric version (see
  [`rfair_metric_versions()`](https://choxos.github.io/rfair/reference/rfair_metric_versions.md)).

- quiet:

  If `FALSE` (default), print per-identifier progress.

- workers:

  Number of identifiers to assess at once. Values above 1 fork worker
  processes with
  [`parallel::mclapply()`](https://rdrr.io/r/parallel/mclapply.html),
  which is not available on Windows (there the batch runs serially with
  a warning). HTTP requests to one host stay rate limited per process
  (see `options(rfair.rate_per_host)`).

- keep:

  If `TRUE`, keep the full
  [fair_assessment](https://choxos.github.io/rfair/reference/fair_assessment.md)
  objects, named by identifier, in the `"assessments"` attribute of the
  result.

- previous:

  Optional result of an earlier `assess_fair_batch()` call. Identifiers
  it already scored without an error (for the same metric version) are
  reused instead of assessed again, so an interrupted batch can be
  resumed.

- ...:

  Passed to
  [`assess_fair()`](https://choxos.github.io/rfair/reference/assess_fair.md).

## Value

A data frame with one row per unique identifier: `identifier`,
`metric_version`, `scheme`, `is_persistent`, `resolved` (did the
identifier resolve; `NA` when `resolve = FALSE`), `http_status`,
`resolved_url`, `fair_percent`, `F`, `A`, `I`, `R`, `maturity`,
`n_pass`, `n_metrics`, `error`.

## See also

[`assess_data_code()`](https://choxos.github.io/rfair/reference/assess_data_code.md),
[`assess_fair()`](https://choxos.github.io/rfair/reference/assess_fair.md)

## Examples

``` r
# \donttest{
res <- assess_fair_batch(c("https://doi.org/10.5281/zenodo.8347772", "geo:GSE12345"),
                         keep = TRUE)
#> [1/2] assessing https://doi.org/10.5281/zenodo.8347772
#> [2/2] assessing geo:GSE12345
attr(res, "assessments")[[1]]
#> <fair_assessment> https://doi.org/10.5281/zenodo.8347772
#>   resolved: https://zenodo.org/records/8347772
#>   metrics: v0.8 (17 metrics)
#> 
#>   FAIR     earned  percent  maturity
#>   F           7/7   100.0%         3
#>   A           7/7   100.0%         3
#>   I           4/6    66.7%         2
#>   R           5/6    83.3%         2
#>   FAIR      23/26    88.5%       2.5
#> 
#>   reuse:    custom/unknown; open (software, permissive)
# }
```
