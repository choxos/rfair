# Agreement between rfair's FRSM scores and expert ratings

rfair scores the FRSM software metrics from repository signals (file
names, API fields, metadata files). These heuristics have not yet been
validated against expert judgement, so every FRSM result carries
`evidence_type = "heuristic"`. `frsm_agreement()` supports that
validation: raters judge each FRSM test for a sample of repositories
(start from the template in
`system.file("extdata", "frsm_validation_template.csv", package = "rfair")`),
and the function compares rfair's pass/fail result with the raters'
majority judgement, test by test.

## Usage

``` r
frsm_agreement(assessments, ratings)
```

## Arguments

- assessments:

  A list of
  [fair_assessment](https://choxos.github.io/rfair/reference/fair_assessment.md)
  objects scored with an FRSM metric version (for example the
  `"assessments"` attribute of
  `assess_fair_batch(..., metric_version = "0.7_software", keep = TRUE)`),
  or a single assessment.

- ratings:

  A data frame with columns `identifier` (as passed to
  [`assess_fair()`](https://choxos.github.io/rfair/reference/assess_fair.md)),
  `test_identifier` (for example `"FRSM-14-R1-2"`), `rater`, and
  `passed` (logical; did the software satisfy the test?).

## Value

A data frame with one row per test: `test_identifier`, `n` (rated
items), `rfair_pass` and `rater_pass` (pass rates), `agreement` (share
of items where rfair matches the raters' majority), `kappa` (Cohen's
kappa of rfair against the majority), and `rater_kappa` (kappa between
the first two raters, when two or more rated the test). Ties between
raters are dropped.

## Examples

``` r
data(fair_example)
ratings <- data.frame(identifier = fair_example$id,
                      test_identifier = "FsF-F1-01MD-1", rater = "A", passed = TRUE)
# fair_example is a data assessment, so this only shows the shape of the output
frsm_agreement(fair_example, ratings)
#>   test_identifier n rfair_pass rater_pass agreement kappa rater_kappa
#> 1   FsF-F1-01MD-1 1          1          1         1    NA          NA
```
