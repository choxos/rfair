# Recommend how to fix the failed tests of a FAIR assessment

Lists every metric test that did not pass, with one concrete action a
data curator or software maintainer can take to pass it (for example
"Add a license to the metadata as a URL or SPDX identifier"). Actions
come from a curated table covering the FsF data metrics and the FRSM
software metrics; tests of legacy metric versions fall back to a
metric-level action.

## Usage

``` r
fair_recommendations(x)
```

## Arguments

- x:

  A
  [fair_assessment](https://choxos.github.io/rfair/reference/fair_assessment.md)
  from
  [`assess_fair()`](https://choxos.github.io/rfair/reference/assess_fair.md).

## Value

A data frame, most valuable fixes first, with columns
`metric_identifier`, `test_identifier`, `test_name`, `points` (the score
passing the test would add, given the metric's cap), and
`recommendation`.

## See also

[`fair_compare()`](https://choxos.github.io/rfair/reference/fair_compare.md)
to check the effect of a fix.

## Examples

``` r
data(fair_example)
head(fair_recommendations(fair_example))
#>   metric_identifier test_identifier
#> 1        FsF-I2-01M    FsF-I2-01M-2
#> 2      FsF-R1.3-02D  FsF-R1.3-02D-1
#> 3       FsF-F1-01MD   FsF-F1-01MD-2
#> 4       FsF-F1-02MD   FsF-F1-02MD-4
#> 5       FsF-F1-02MD   FsF-F1-02MD-5
#> 6        FsF-R1-01M    FsF-R1-01M-3
#>                                                                                                                                        test_name
#> 1                                                       Metadata uses terms from registered vocabularies that are identified by their namespaces
#> 2 Data is available in a file format recommended by the research community (long term file formats, open file formats or scientific file format)
#> 3                                                       Data identifier follows a defined unique identifier syntax (IRI, URL, UUID, HASH or PID)
#> 4                                                                                 Data identifier follows a defined persistent identifier syntax
#> 5                                                                 Persistent identifier for data is registered and maintained by a PID authority
#> 6                                                                              Measured variables or observation types are specified in metadata
#>   points
#> 1      2
#> 2      1
#> 3      0
#> 4      0
#> 5      0
#> 6      0
#>                                                                                                                                               recommendation
#> 1 Use terms from registered semantic vocabularies (for example ontologies listed in BioPortal or the LOD cloud) and expose their namespaces in RDF metadata.
#> 2       Publish the data in an open, long-term, or community-recommended file format (for example CSV, NetCDF, HDF5) and declare the format in the metadata.
#> 3                                                                 Give each data file a unique identifier (a stable URL or PID) and list it in the metadata.
#> 4                                                                       Give the data files persistent identifiers, or link them from a record that has one.
#> 5                                                                          Register the data file identifiers with a PID authority so they resolve reliably.
#> 6                                                List the measured variables or observation types in the metadata (for example schema.org variableMeasured).
```
