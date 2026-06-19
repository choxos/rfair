# rfair <img src="https://img.shields.io/badge/FAIR-assessment-118AB2" alt="FAIR assessment" align="right" />

> Assess the FAIRness of research data objects, natively in R.

`rfair` is a native R implementation of the
[F-UJI](https://github.com/pangaea-data-publisher/fuji) (FAIRsFAIR Research Data
Object Assessment) metrics. Given a persistent identifier or URL it resolves the
object, harvests metadata from its landing page and from registries (DataCite,
Crossref, GitHub), and scores it against the FAIRsFAIR metrics
([v0.8](https://doi.org/10.5281/zenodo.15045911) by default) for Findability,
Accessibility, Interoperability, and Reusability.

Unlike the original `rfair` (an HTTP client for an external F-UJI server), this
version performs the **entire assessment in R** — no Python, no server.

It also goes **beyond F-UJI** with checks that automated FAIR tools usually miss
(prompted by peer review of a COVID-19 FAIR-assessment study): whether a license
actually permits reuse, whether data is controlled-access / sensitive, and
whether identifiers follow best practices.

## Installation

```r
# install.packages("remotes")
remotes::install_github("choxos/rfuji")
```

## Quick start

```r
library(rfair)

a <- assess_fair("https://doi.org/10.5281/zenodo.8347772")
a
#> <fair_assessment> https://doi.org/10.5281/zenodo.8347772
#>   resolved: https://zenodo.org/records/8347772
#>   metrics: v0.8 (17 metrics)
#>   FAIR      earned  percent  maturity
#>   F            7/7   100.0%         3
#>   A            7/7   100.0%         3
#>   I            4/6    66.7%         2
#>   R            5/6    83.3%         2
#>   FAIR       23/26    88.5%         2
# (illustrative; exact scores depend on the object's live metadata)

summary(a)            # F/A/I/R score table
as.data.frame(a)      # one row per metric
as_fuji_json(a)       # F-UJI-compatible JSON
as_rdf(a)             # DQV + schema.org Rating (JSON-LD)
```

## Metric versions and F-UJI options

`rfair` bundles the current F-UJI website choices plus release-specific legacy
metric files from upstream F-UJI:

```r
rfair_metric_versions()
#> 0.8 0.5 0.5ssv2 0.5ss 0.5env 0.7_software ...

assess_fair(
  "https://doi.org/10.5281/zenodo.8347772",
  metric_version = "0.5ssv2",
  use_datacite = TRUE,
  metadata_service_endpoint = "https://example.org/oai",
  metadata_service_type = "oai_pmh"
)
```

Supported metadata service type labels include OAI-PMH, OGC CSW, SPARQL, DCAT,
schema.org JSON-LD, DataCite, Crossref, Signposting, typed links, RO-Crate, CKAN,
and a generic other metadata document option.

## Beyond F-UJI

```r
# A license can be present yet NOT open for reuse
license_reuse("https://creativecommons.org/licenses/by-nc-nd/4.0/")$is_open
#> [1] FALSE

# Controlled-access / sensitive data is not a FAIR failure
classify_access(access_level = "closedAccess",
                urls = "https://www.ncbi.nlm.nih.gov/gap/...")$controlled_access
#> [1] TRUE

# Identifier hygiene (layered / non-persistent PIDs)
identifier_hygiene("RRID:MGI:5577054")$issues

# Canonical FAIR principle definitions (go-fair.org / FAIR-nanopubs)
fair_principles("R")
```

These results are attached to every assessment (`a$reuse`, `a$access`,
`a$identifier_hygiene`) and shown in the app.

## Batch assessment and rtransparent

`assess_fair_batch()` scores a vector of identifiers and returns one tidy row
per identifier. `assess_data_code()` bridges
[rtransparent](https://github.com/choxos/rtransparent): it takes the data and
code identifiers rtransparent extracts from articles (its `open_data_links` and
`open_code_links` columns; DOIs, repository URLs, and identifiers.org
`prefix:accession` codes such as `geo:GSE…`) and scores each, using the FsF data
metrics for data and the FRSM software metrics for code.

```r
rt <- rtransparent::rt_data_code_pmc(xml)          # is_open_data, open_data_links, ...
scores <- assess_data_code(rt, id_col = "pmid")    # one row per (article, data/code link)
```

`split_identifiers()` parses the `" ; "`-joined link strings on their own.

## Interactive app

```r
launch_rfair()   # bslib Shiny app: scores, per-metric report, reuse/access panels
```

A browser version (registry-only, no install) is published at
**<https://choxos.github.io/rfuji/app/>**.

## HTTP API scaffold

`rfair` also ships a Plumber scaffold and OpenAPI contract for teams that want
to expose the same assessment engine over HTTP:

```r
api <- system.file("plumber", "rfair-api.R", package = "rfair")
pr <- plumber::pr(api)
pr$run(port = 8000)
```

The machine-readable API contract is installed at:

```r
system.file("openapi", "rfair-openapi.yaml", package = "rfair")
```

## How it works

```
id_parse() → resolve → harvest (DataCite JSON · landing-page JSON-LD/Dublin Core/
OpenGraph · signposting typed links · XML · RDF · GitHub) → merge → 17 metric
evaluators → F/A/I/R score → fair_assessment
```

Reference data (SPDX licenses, file formats, access rights, protocols, metadata
standards, FAIR principles, reusabledata.org curations) is baked in from the
F-UJI sources by the scripts in `data-raw/`.

## Citation and metadata

The repository includes `CITATION.cff` and `codemeta.json` so software harvesters
can find rfair's authorship, license, version, dependencies, repository URL, and
upstream F-UJI provenance. A repository-specific archived DOI has not yet been
minted; once one exists, add it to both metadata files before the next release.

## Acknowledgements

`rfair` began as a fork of the
[rfuji](https://github.com/NFDI4Chem/rfuji) F-UJI API client (Steffen Neumann)
and reimplements the assessment engine natively in R. It is a native R port of
[F-UJI](https://github.com/pangaea-data-publisher/fuji)
(© PANGAEA, MIT), itself based on the FAIRsFAIR metrics. License reusability uses
the [(Re)usable Data Project](https://reusabledata.org) rubric; FAIR principle
definitions come from the [FAIR-nanopubs](https://peta-pico.github.io/FAIR-nanopubs/principles/index-en.html)
vocabulary referenced by [go-fair.org](https://www.go-fair.org/fair-principles/).

## License

MIT © rfair authors. See `LICENSE`.
