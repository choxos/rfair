# Assess the reuse permissions granted by a license.

Goes beyond detecting that a license exists: classifies whether it
actually permits redistribution, commercial use, and derivative works,
and whether it meets the Open Definition. Useful for judging real
reusability of data.

## Usage

``` r
license_reuse(license)
```

## Arguments

- license:

  A license name, SPDX id, or URL (e.g. from an assessment).

## Value

A list describing the license's reuse terms, including `is_open`,
`permits_redistribution`, `permits_commercial`, `permits_derivatives`,
`requires_attribution`, `requires_share_alike`, `category`, and `note`.

## Examples

``` r
license_reuse("https://creativecommons.org/licenses/by-nc-nd/4.0/")$is_open
#> [1] FALSE
license_reuse("CC-BY-4.0")$is_open
#> [1] TRUE
```
