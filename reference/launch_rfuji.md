# Launch the rfuji Shiny app

Opens an interactive app to assess the FAIRness of a research data
object and explore the per-metric results, license reusability,
access/sensitivity, and identifier hygiene.

## Usage

``` r
launch_rfuji(...)
```

## Arguments

- ...:

  Passed to
  [`shiny::runApp()`](https://rdrr.io/pkg/shiny/man/runApp.html).

## Value

Runs the app (called for its side effect); invisibly `NULL`.

## Examples

``` r
if (FALSE) { # \dontrun{
launch_rfuji()
} # }
```
