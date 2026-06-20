# Split a joined identifier string into individual identifiers.

rtransparent joins the data/code identifiers it extracts with `" ; "`.
This splits such a string (or a vector of them) into a trimmed character
vector, dropping empties. rfair's
[`id_parse()`](https://choxos.github.io/rfair/reference/id_parse.md)
already understands the forms it emits (doi.org URLs, repository URLs,
and identifiers.org `prefix:accession` codes such as `geo:GSE123` or
`bioproject:PRJEB123`).

## Usage

``` r
split_identifiers(x, sep = " ; ")
```

## Arguments

- x:

  A character vector of identifier strings (each possibly joined).

- sep:

  Separator used to join identifiers (default `" ; "`).

## Value

A character vector of individual identifiers.

## Examples

``` r
split_identifiers("https://doi.org/10.5061/dryad.x ; geo:GSE12345")
#> [1] "https://doi.org/10.5061/dryad.x" "geo:GSE12345"                   
```
