# Classify the access level and sensitivity of a data object.

Classify the access level and sensitivity of a data object.

## Usage

``` r
classify_access(access_level = NULL, urls = NULL, source = NULL)
```

## Arguments

- access_level:

  Access codes/URIs harvested from metadata (character).

- urls:

  Landing-page and content URLs (for host-based detection).

- source:

  Optional source name/id.

## Value

A list with `access` (public/embargoed/restricted/closed/
metadataonly/unknown), `controlled_access`, `sensitive`, the matched
`reusabledata` record (or NULL), and a human-readable `note`.

## Examples

``` r
classify_access(access_level = "info:eu-repo/semantics/openAccess")$access
#> [1] "public"
```
