# The canonical FAIR (sub)principles.

The canonical FAIR (sub)principles.

## Usage

``` r
fair_principles(category = NULL)
```

## Arguments

- category:

  Optional filter: one or more of "F", "A", "I", "R".

## Value

A data frame with `id`, `label`, `category`, `definition`, and `uri`
(the w3id.org/fair/principles term URI).

## Examples

``` r
fair_principles()
#>      id label category
#> 1    F1    F1        F
#> 2    F2    F2        F
#> 3    F3    F3        F
#> 4    F4    F4        F
#> 5    A1    A1        A
#> 6  A1.1  A1.1        A
#> 7  A1.2  A1.2        A
#> 8    A2    A2        A
#> 9    I1    I1        I
#> 10   I2    I2        I
#> 11   I3    I3        I
#> 12   R1    R1        R
#> 13 R1.1  R1.1        R
#> 14 R1.2  R1.2        R
#> 15 R1.3  R1.3        R
#>                                                                                                   definition
#> 1                                        (meta)data are assigned a globally unique and persistent identifier
#> 2                                                data are described with rich metadata (defined by R1 below)
#> 3                            metadata clearly and explicitly include the identifier of the data it describes
#> 4                                              (meta)data are registered or indexed in a searchable resource
#> 5                (meta)data are retrievable by their identifier using a standardized communications protocol
#> 6                                                  the protocol is open, free, and universally implementable
#> 7                     the protocol allows for an authentication and authorization procedure, where necessary
#> 8                                        metadata are accessible, even when the data are no longer available
#> 9  (meta)data use a formal, accessible, shared, and broadly applicable language for knowledge representation
#> 10                                                   (meta)data use vocabularies that follow FAIR principles
#> 11                                               (meta)data include qualified references to other (meta)data
#> 12                      meta(data) are richly described with a plurality of accurate and relevant attributes
#> 13                                    (meta)data are released with a clear and accessible data usage license
#> 14                                                        (meta)data are associated with detailed provenance
#> 15                                                       (meta)data meet domain-relevant community standards
#>                                            uri
#> 1    https://w3id.org/fair/principles/terms/F1
#> 2    https://w3id.org/fair/principles/terms/F2
#> 3    https://w3id.org/fair/principles/terms/F3
#> 4    https://w3id.org/fair/principles/terms/F4
#> 5    https://w3id.org/fair/principles/terms/A1
#> 6  https://w3id.org/fair/principles/terms/A1.1
#> 7  https://w3id.org/fair/principles/terms/A1.2
#> 8    https://w3id.org/fair/principles/terms/A2
#> 9    https://w3id.org/fair/principles/terms/I1
#> 10   https://w3id.org/fair/principles/terms/I2
#> 11   https://w3id.org/fair/principles/terms/I3
#> 12   https://w3id.org/fair/principles/terms/R1
#> 13 https://w3id.org/fair/principles/terms/R1.1
#> 14 https://w3id.org/fair/principles/terms/R1.2
#> 15 https://w3id.org/fair/principles/terms/R1.3
fair_principles("R")
#>     id label category
#> 1   R1    R1        R
#> 2 R1.1  R1.1        R
#> 3 R1.2  R1.2        R
#> 4 R1.3  R1.3        R
#>                                                                             definition
#> 1 meta(data) are richly described with a plurality of accurate and relevant attributes
#> 2               (meta)data are released with a clear and accessible data usage license
#> 3                                   (meta)data are associated with detailed provenance
#> 4                                  (meta)data meet domain-relevant community standards
#>                                           uri
#> 1   https://w3id.org/fair/principles/terms/R1
#> 2 https://w3id.org/fair/principles/terms/R1.1
#> 3 https://w3id.org/fair/principles/terms/R1.2
#> 4 https://w3id.org/fair/principles/terms/R1.3
```
