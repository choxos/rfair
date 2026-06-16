# The `fair_assessment` object

[`assess_fair()`](https://choxos.github.io/rfuji/reference/assess_fair.md)
returns an object of class `fair_assessment`. It has
[`print()`](https://rdrr.io/r/base/print.html),
[`format()`](https://rdrr.io/r/base/format.html),
[summary()](https://choxos.github.io/rfuji/reference/summary.fair_assessment.md),
and
[as.data.frame()](https://choxos.github.io/rfuji/reference/as.data.frame.fair_assessment.md)
methods, and can be exported with
[`as_fuji_json()`](https://choxos.github.io/rfuji/reference/as_fuji_json.md)
and [`as_rdf()`](https://choxos.github.io/rfuji/reference/as_rdf.md).

## Details

Useful list elements: `summary` (F/A/I/R scores), `results`
(per-metric), `metadata` (harvested), `reuse` (license reusability),
`access` (access/sensitivity), and `identifier_hygiene`.

## See also

[`assess_fair()`](https://choxos.github.io/rfuji/reference/assess_fair.md)
