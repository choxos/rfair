# The `fair_assessment` object

[`assess_fair()`](https://choxos.github.io/rfair/reference/assess_fair.md)
returns an object of class `fair_assessment`. It has
[`print()`](https://rdrr.io/r/base/print.html),
[`format()`](https://rdrr.io/r/base/format.html),
[summary()](https://choxos.github.io/rfair/reference/summary.fair_assessment.md),
and
[as.data.frame()](https://choxos.github.io/rfair/reference/as.data.frame.fair_assessment.md)
methods, and can be exported with
[`as_fuji_json()`](https://choxos.github.io/rfair/reference/as_fuji_json.md)
and [`as_rdf()`](https://choxos.github.io/rfair/reference/as_rdf.md).

## Details

Useful list elements: `summary` (F/A/I/R scores), `results`
(per-metric), `metadata` (harvested), `reuse` (license reusability),
`access` (access/sensitivity), `identifier_hygiene`, `resolution` (the
identifier's resolution attempt: `url`, `final_url`, HTTP `status`,
`ok`, `error`), and `harvest_errors` (metadata sources that failed, for
example a GitHub rate limit), and `software` (the repository signals the
FRSM software metrics score, when a code repository was harvested), and
`reference_data` (when and from which F-UJI release the bundled
reference tables were built). `resolved_url` is `NA` when the identifier
did not resolve.

## See also

[`assess_fair()`](https://choxos.github.io/rfair/reference/assess_fair.md)
