# FAIR-TLC indicators (Traceable, Licensed, Connected)

Computes the three "FAIR+" indicators proposed by Haendel and colleagues
in the Monarch Initiative / NCATS TransMed response to the NIH RFI on
biomedical repository value metrics
([doi:10.5281/zenodo.203295](https://doi.org/10.5281/zenodo.203295) ),
building on the (Re)usable Data Project
([doi:10.1371/journal.pone.0213090](https://doi.org/10.1371/journal.pone.0213090)
). They extend FAIR with the provenance and legal dimensions that
automated FAIR tools usually miss: whether data is **Traceable**
(provenance, attribution), **Licensed** (clearly documented and actually
reusable), and **Connected** (qualified links to related entities).

## Usage

``` r
fair_tlc(x)
```

## Arguments

- x:

  A
  [fair_assessment](https://choxos.github.io/rfair/reference/fair_assessment.md)
  from
  [`assess_fair()`](https://choxos.github.io/rfair/reference/assess_fair.md).

## Value

A data frame with columns `dimension`, `indicator`, `met` (logical), and
`detail`, plus a `"source"` attribute citing the framework.

## Examples

``` r
# \donttest{
a <- assess_fair("https://doi.org/10.5281/zenodo.8347772")
fair_tlc(a)
#>   dimension                             indicator   met
#> 1 Traceable                         T1 Provenance  TRUE
#> 2 Traceable                        T2 Attribution  TRUE
#> 3  Licensed L1 Documented & minimally restrictive  TRUE
#> 4  Licensed           L2 Flowthrough transparency FALSE
#> 5 Connected                      C1 Connectedness  TRUE
#>                                                          detail
#> 1               data creation/generation provenance is recorded
#> 2              creators and publisher are recorded for citation
#> 3     a standard license is present that actually permits reuse
#> 4 downstream reuse/redistribution implications are determinable
#> 5               qualified links to related entities are present
# }
```
