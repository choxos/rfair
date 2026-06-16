# rfuji <img src="https://img.shields.io/badge/FAIR-assessment-118AB2" alt="FAIR assessment" align="right" />

> Assess the FAIRness of research data objects, natively in R.

`rfuji` is a native R implementation of the
[F-UJI](https://github.com/pangaea-data-publisher/fuji) (FAIRsFAIR Research Data
Object Assessment) metrics. Given a persistent identifier or URL it resolves the
object, harvests metadata from its landing page and from registries (DataCite,
Crossref, GitHub), and scores it against the FAIRsFAIR metrics
([v0.8](https://doi.org/10.5281/zenodo.15045911)) for Findability, Accessibility,
Interoperability, and Reusability.

Unlike the original `rfuji` (an HTTP client for an external F-UJI server), this
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
library(rfuji)

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

## Interactive app

```r
launch_rfuji()   # bslib Shiny app: scores, per-metric report, reuse/access panels
```

A browser version (registry-only, no install) is published at
**<https://choxos.github.io/rfuji/app/>**.

## How it works

```
id_parse() → resolve → harvest (DataCite JSON · landing-page JSON-LD/Dublin Core/
OpenGraph · signposting typed links · XML · RDF · GitHub) → merge → 17 metric
evaluators → F/A/I/R score → fair_assessment
```

Reference data (SPDX licenses, file formats, access rights, protocols, metadata
standards, FAIR principles, reusabledata.org curations) is baked in from the
F-UJI sources by the scripts in `data-raw/`.

## Acknowledgements

A native R port of [F-UJI](https://github.com/pangaea-data-publisher/fuji)
(© PANGAEA, MIT), itself based on the FAIRsFAIR metrics. License reusability uses
the [(Re)usable Data Project](https://reusabledata.org) rubric; FAIR principle
definitions come from the [FAIR-nanopubs](https://w3id.org/fair/principles)
vocabulary referenced by [go-fair.org](https://www.go-fair.org/fair-principles/).

## License

MIT © rfuji authors. See `LICENSE`.
