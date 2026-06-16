# Parse a persistent identifier or URL.

Resolves the identifier scheme, normalizes it, and constructs its
resolver URL, mirroring `IdentifierHelper` in F-UJI.

## Usage

``` r
id_parse(idstring)
```

## Arguments

- idstring:

  A DOI, Handle, ARK, URN, UUID, identifiers.org PID, or URL.

## Value

A list with `identifier`, `normalized_id`, `identifier_url`,
`preferred_schema`, `identifier_schemes`, and `is_persistent`.

## Examples

``` r
id_parse("https://doi.org/10.5281/zenodo.8347772")$preferred_schema
#> [1] "doi"
```
