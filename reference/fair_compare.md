# Compare two FAIR assessments

Joins two assessments, for example of the same record before and after a
metadata fix, or under two metric versions, and reports what changed.

## Usage

``` r
fair_compare(a, b, level = c("metric", "test"))
```

## Arguments

- a, b:

  [fair_assessment](https://choxos.github.io/rfair/reference/fair_assessment.md)
  objects; `a` is the baseline.

- level:

  `"metric"` (default) for one row per metric, or `"test"` for one row
  per metric test.

## Value

A data frame with the identifiers, `earned_a`, `earned_b`, `status_a`,
`status_b`, `delta` (`earned_b - earned_a`), and `change` (`"improved"`,
`"worse"`, `"same"`, or `"only in a"`/`"only in b"`), in the metric
order of `a`.

## See also

[`fair_recommendations()`](https://choxos.github.io/rfair/reference/fair_recommendations.md)

## Examples

``` r
data(fair_example)
fixed <- fair_example
fixed$results[[1]]$score$earned <- fixed$results[[1]]$score$total
fair_compare(fair_example, fixed)[1:3, ]
#>   metric_identifier
#> 1       FsF-F1-01MD
#> 2       FsF-F1-02MD
#> 3        FsF-F2-01M
#>                                                                                                                                                     metric_name
#> 1                                                                                                  Metadata and data are assigned a globally unique identifier.
#> 2                                                                                                       Metadata and data are assigned a persistent identifier.
#> 3 Metadata includes descriptive core elements (creator, title, data identifier, publisher, publication date, summary and keywords) to support data findability.
#>   earned_a status_a earned_b status_b delta change
#> 1        1     pass        1     pass     0   same
#> 2        1     pass        1     pass     0   same
#> 3        2     pass        2     pass     0   same
```
