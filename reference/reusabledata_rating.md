# Look up a (Re)usable Data Project curation for a source.

Look up a (Re)usable Data Project curation for a source.

## Usage

``` r
reusabledata_rating(urls = NULL, source = NULL)
```

## Arguments

- urls:

  Character vector of URLs (e.g. landing page, content URLs).

- source:

  Optional source name or id to match.

## Value

The matched curation record (list) or `NULL`.

## Examples

``` r
reusabledata_rating(source = "dbgap")$license_type
#> [1] "unknown"
```
