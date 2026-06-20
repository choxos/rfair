# An example FAIR assessment

A stored
[fair_assessment](https://choxos.github.io/rfair/reference/fair_assessment.md)
object, produced by running
[`assess_fair()`](https://choxos.github.io/rfair/reference/assess_fair.md)
on a stable Zenodo deposit
([doi:10.5281/zenodo.8347772](https://doi.org/10.5281/zenodo.8347772) ).
It is bundled so the plotting examples and the
[`vignette("illustrating-fairness")`](https://choxos.github.io/rfair/articles/illustrating-fairness.md)
can run offline and reproducibly, without contacting any network
service.

## Usage

``` r
data(fair_example)
```

## Format

A `fair_assessment` object (a list with S3 class `fair_assessment`); see
[fair_assessment](https://choxos.github.io/rfair/reference/fair_assessment.md)
for its structure.

## Source

[`assess_fair()`](https://choxos.github.io/rfair/reference/assess_fair.md)
on [doi:10.5281/zenodo.8347772](https://doi.org/10.5281/zenodo.8347772)
, rebuilt by `data-raw/06-build-example-assessment.R`.

## Details

The verbose per-test debug log has been stripped to keep the installed
size small; all elements used by the `print`, `summary`,
`as.data.frame`,
[plot](https://choxos.github.io/rfair/reference/plot.fair_assessment.md),
[`as_fair_json()`](https://choxos.github.io/rfair/reference/as_fair_json.md),
and [`as_rdf()`](https://choxos.github.io/rfair/reference/as_rdf.md)
methods are retained.

## See also

[`assess_fair()`](https://choxos.github.io/rfair/reference/assess_fair.md),
[`plot.fair_assessment()`](https://choxos.github.io/rfair/reference/plot.fair_assessment.md)

## Examples

``` r
data(fair_example)
summary(fair_example)
#>   category earned total percent maturity
#> 1        F      7     7  100.00      3.0
#> 2        A      7     7  100.00      3.0
#> 3        I      4     6   66.67      2.0
#> 4        R      5     6   83.33      2.0
#> 5     FAIR     23    26   88.46      2.5
plot(fair_example)
```
