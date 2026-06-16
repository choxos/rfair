# Canonical definition of the FAIR principle a metric maps to.

Canonical definition of the FAIR principle a metric maps to.

## Usage

``` r
principle_definition(metric_identifier)
```

## Arguments

- metric_identifier:

  A metric identifier (e.g. "FsF-F1-01MD").

## Value

The principle's definition string, or `NA`.

## Examples

``` r
principle_definition("FsF-R1.1-01M")
#> [1] "(meta)data are released with a clear and accessible data usage license"
```
