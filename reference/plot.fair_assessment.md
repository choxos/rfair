# Plot a FAIR assessment as a scorecard

Draws a compact, readable scorecard of a
[fair_assessment](https://choxos.github.io/rfuji/reference/fair_assessment.md)
using base graphics (no extra package dependencies). It is the quickest
way to *see* an assessment: a horizontal progress bar per FAIR category
(or per metric), each annotated with its score and CMMI maturity level.
See
[`vignette("illustrating-fairness")`](https://choxos.github.io/rfuji/articles/illustrating-fairness.md)
for worked examples.

## Usage

``` r
# S3 method for class 'fair_assessment'
plot(
  x,
  type = c("category", "metric", "sunburst"),
  colors = .fair_cat_colors,
  show_maturity = (match.arg(type) == "category"),
  main = NULL,
  ...
)
```

## Arguments

- x:

  A `fair_assessment` object returned by
  [`assess_fair()`](https://choxos.github.io/rfuji/reference/assess_fair.md).

- type:

  What to draw. `"category"` (default) draws one bar per FAIR category
  (Findable, Accessible, Interoperable, Reusable) plus the overall
  score; `"metric"` draws one bar per individual metric, grouped and
  colored by category; `"sunburst"` draws a concentric sunburst (an
  inner ring of the F/A/I/R categories and an outer ring of the
  individual metrics, each filled in proportion to its score) with the
  overall FAIR percentage in the center.

- colors:

  Named character vector of category fill colors, with names `"F"`,
  `"A"`, `"I"`, `"R"`.

- show_maturity:

  Logical; annotate each bar with its maturity level. Defaults to `TRUE`
  for `type = "category"`.

- main:

  Title. Defaults to the resolved identifier (or the input id).

- ...:

  Ignored (for S3 method compatibility).

## Value

`x`, invisibly. Called for the side effect of drawing a plot.

## See also

[`assess_fair()`](https://choxos.github.io/rfuji/reference/assess_fair.md),
[`summary.fair_assessment()`](https://choxos.github.io/rfuji/reference/summary.fair_assessment.md),
[fair_example](https://choxos.github.io/rfuji/reference/fair_example.md)

## Examples

``` r
# A stored example assessment (no network needed):
data(fair_example)
plot(fair_example)

plot(fair_example, type = "metric")

plot(fair_example, type = "sunburst")
```
