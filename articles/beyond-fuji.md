# Beyond F-UJI: reuse, sensitivity, hygiene, and FAIR-TLC

Automated FAIR tools have well-documented blind spots. In peer review of
a COVID-19 FAIR-assessment study, the reviewer (Melissa Haendel) noted
that such tools reward the *presence* of a license, an identifier, or a
metadata field without checking whether the data is actually reusable,
legitimately restricted, or properly identified. `rfuji` adds checks for
exactly these.

## A license can be present yet not open for reuse

Detecting that a license exists says nothing about whether you may reuse
the data.
[`license_reuse()`](https://choxos.github.io/rfuji/reference/license_reuse.md)
classifies the actual permissions, and maps each license to the
six-category taxonomy of the [(Re)usable Data
Project](https://reusabledata.org) (Carbon et al. 2019).

``` r

license_reuse("https://creativecommons.org/licenses/by/4.0/")[c("category", "rdp_category", "facilitates_reuse")]
#> $category
#> [1] "open (attribution)"
#> 
#> $rdp_category
#> [1] "permissive"
#> 
#> $facilitates_reuse
#> [1] TRUE
license_reuse("https://creativecommons.org/licenses/by-nc-nd/4.0/")[c("category", "rdp_category", "facilitates_reuse")]
#> $category
#> [1] "restrictive (non-commercial, no-derivatives)"
#> 
#> $rdp_category
#> [1] "restrictive"
#> 
#> $facilitates_reuse
#> [1] FALSE
```

Only *permissive* licenses facilitate reuse without negotiation;
CC-BY-NC-ND is present and standard, yet restrictive.

## Controlled-access and sensitive data is not a FAIR failure

Data behind a data-use agreement (e.g. human/clinical data) is
legitimately restricted; it should be judged on metadata richness, not
open download.
[`classify_access()`](https://choxos.github.io/rfuji/reference/classify_access.md)
flags this, drawing on the (Re)usable Data Project curations.

``` r

classify_access(access_level = "closedAccess",
                urls = "https://www.ncbi.nlm.nih.gov/gap/?term=phs000424")[c("access", "controlled_access", "sensitive")]
#> $access
#> [1] "closed"
#> 
#> $controlled_access
#> [1] TRUE
#> 
#> $sensitive
#> [1] TRUE
```

## Identifier hygiene

Layered identifiers (an identifier minted on top of another) and
non-persistent identifiers reduce interoperability.

``` r

identifier_hygiene("RRID:MGI:5577054")$issues
#> [1] "Compound/layered identifier: an identifier minted on top of another (e.g. RRID:MGI:...) reduces interoperability; prefer the underlying source PID."
#> [2] "Identifier scheme not recognized; may not follow identifier best practices."
identifier_hygiene("https://doi.org/10.5281/zenodo.8347772")$hygiene_ok
#> [1] TRUE
```

## FAIR-TLC: Traceable, Licensed, Connected

The reviewer’s own framework extends FAIR with three principles
([Haendel et al., FAIR+](https://doi.org/10.5281/zenodo.203295)): data
should be **Traceable** (provenance, attribution), **Licensed** (clearly
and reusably), and **Connected** (qualified links to related entities).
[`fair_tlc()`](https://choxos.github.io/rfuji/reference/fair_tlc.md)
computes these from an assessment.

``` r

a <- assess_fair("https://doi.org/10.5281/zenodo.8347772")
fair_tlc(a)
#>   dimension                             indicator   met
#> 1 Traceable                         T1 Provenance  TRUE
#> 2 Traceable                        T2 Attribution  TRUE
#> 3  Licensed L1 Documented & minimally restrictive  TRUE
#> 4  Licensed           L2 Flowthrough transparency  TRUE
#> 5 Connected                      C1 Connectedness  TRUE
```

## The canonical FAIR principles

For reference, the authoritative principle definitions (from the
FAIR-nanopubs vocabulary used by go-fair.org):

``` r

head(fair_principles(), 4)
#>   id label category
#> 1 F1    F1        F
#> 2 F2    F2        F
#> 3 F3    F3        F
#> 4 F4    F4        F
#>                                                                        definition
#> 1             (meta)data are assigned a globally unique and persistent identifier
#> 2                     data are described with rich metadata (defined by R1 below)
#> 3 metadata clearly and explicitly include the identifier of the data it describes
#> 4                   (meta)data are registered or indexed in a searchable resource
#>                                         uri
#> 1 https://w3id.org/fair/principles/terms/F1
#> 2 https://w3id.org/fair/principles/terms/F2
#> 3 https://w3id.org/fair/principles/terms/F3
#> 4 https://w3id.org/fair/principles/terms/F4
```
