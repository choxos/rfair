# Check an identifier against best-practice / hygiene heuristics.

Check an identifier against best-practice / hygiene heuristics.

## Usage

``` r
identifier_hygiene(id)
```

## Arguments

- id:

  A persistent identifier or URL.

## Value

A list with `identifier`, `scheme`, `is_persistent`, `hygiene_ok`, and a
character vector of `issues`.

## Examples

``` r
identifier_hygiene("RRID:MGI:5577054")$issues
#> [1] "Compound/layered identifier: an identifier minted on top of another (e.g. RRID:MGI:...) reduces interoperability; prefer the underlying source PID."
#> [2] "Identifier scheme not recognized; may not follow identifier best practices."                                                                        
identifier_hygiene("https://doi.org/10.5281/zenodo.8347772")$hygiene_ok
#> [1] TRUE
```
