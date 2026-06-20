# Assess the FAIRness of the data and code shared in articles (rtransparent)

Bridges rtransparent and rfair: takes the data/code identifiers
rtransparent extracts from articles (its `open_data_links` and
`open_code_links` columns) and scores each against the FAIR metrics.
Data identifiers are scored with the FsF data metrics and code
repositories with the FRSM software metrics.

## Usage

``` r
assess_data_code(
  x,
  id_col = NULL,
  data_metric_version = "0.8",
  code_metric_version = "0.7_software",
  data_col = "open_data_links",
  code_col = "open_code_links",
  sep = " ; ",
  quiet = FALSE,
  ...
)
```

## Arguments

- x:

  One of: a data frame from `rtransparent::rt_data_code_pmc()` /
  `rt_all_pmc()` (with `open_data_links` / `open_code_links` columns); a
  named list with those elements; or a character vector of
  `" ; "`-joined data-link strings.

- id_col:

  Optional name of a column in `x` identifying the source article (e.g.
  `"pmid"` or `"doi"`); used to label each result.

- data_metric_version:

  Metric version for data identifiers (default `"0.8"`).

- code_metric_version:

  Metric version for code repositories (default `"0.7_software"`).

- data_col, code_col:

  Column/element names holding the joined links (defaults match
  rtransparent: `"open_data_links"`, `"open_code_links"`).

- sep:

  Separator rtransparent uses to join identifiers (default `" ; "`).

- quiet:

  If `FALSE` (default), print per-identifier progress.

- ...:

  Passed to
  [`assess_fair()`](https://choxos.github.io/rfair/reference/assess_fair.md).

## Value

A data frame with one row per (article, kind, identifier): `source`
(article id), `kind` (`"data"` or `"code"`), and the columns of
[`assess_fair_batch()`](https://choxos.github.io/rfair/reference/assess_fair_batch.md).
Each unique identifier is assessed once.

## See also

[`assess_fair_batch()`](https://choxos.github.io/rfair/reference/assess_fair_batch.md),
[`split_identifiers()`](https://choxos.github.io/rfair/reference/split_identifiers.md),
[`assess_fair()`](https://choxos.github.io/rfair/reference/assess_fair.md)

## Examples

``` r
# \donttest{
# rt <- rtransparent::rt_data_code_pmc(xml)
# assess_data_code(rt, id_col = "pmid")
assess_data_code(list(open_data_links = "https://doi.org/10.5281/zenodo.8347772",
                      open_code_links = "https://github.com/pangaea-data-publisher/fuji"))
#> [1/2] assessing https://doi.org/10.5281/zenodo.8347772 (v0.8)
#> [2/2] assessing https://github.com/pangaea-data-publisher/fuji (v0.7_software)
#>   source kind                                     identifier metric_version
#> 1   <NA> data         https://doi.org/10.5281/zenodo.8347772            0.8
#> 2   <NA> code https://github.com/pangaea-data-publisher/fuji   0.7_software
#>   scheme is_persistent                                   resolved_url
#> 1    doi          TRUE             https://zenodo.org/records/8347772
#> 2    url         FALSE https://github.com/pangaea-data-publisher/fuji
#>   fair_percent   F   A      I     R maturity n_pass n_metrics error
#> 1        88.46 100 100  66.67 83.33     2.50     15        17  <NA>
#> 2        73.33  55 100 100.00 81.25     2.25     16        17  <NA>
# }
```
