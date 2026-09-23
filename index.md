# rfair ![FAIR assessment](https://img.shields.io/badge/FAIR-assessment-118AB2)

> Assess the FAIRness of research data objects and software, natively in
> R.

`rfair` is a native R implementation of the
[F-UJI](https://github.com/pangaea-data-publisher/fuji) (FAIRsFAIR
Research Data Object Assessment) metrics. Given a persistent identifier
or URL it resolves the object, harvests metadata from its landing page,
from DOI registries (DataCite, Crossref, and other agencies), from code
forges (GitHub, GitLab, Codeberg), and from repository APIs (Zenodo,
figshare, Dataverse, Dryad), and scores it against the FAIRsFAIR metrics
([v0.8](https://doi.org/10.5281/zenodo.15045911) by default) for
Findability, Accessibility, Interoperability, and Reusability.

`rfair` began as a fork of
[`rfuji`](https://github.com/NFDI4Chem/rfuji), an HTTP client for an
external F-UJI server; unlike that client it performs the **entire
assessment in R**: no Python, no server. It also scores **research
software** against the FRSM (FAIR for Research Software) metrics, which
operationalize the [FAIR4RS
Principles](https://doi.org/10.15497/RDA00068) (Chue Hong et al. 2022).

It also goes **beyond F-UJI** with checks that automated FAIR tools
usually miss (prompted by peer review of a COVID-19 FAIR-assessment
study): whether a license actually permits reuse, whether data is
controlled-access / sensitive, and whether identifiers follow best
practices.

## Installation

``` r

# From CRAN
install.packages("rfair")

# Development version from GitHub
# install.packages("remotes")
remotes::install_github("choxos/rfair")
```

## Interactive app

No install required: a browser version (registry-only) is published at
**<https://choxos.github.io/rfair/app/>**. Inside R, launch the bundled
Shiny app:

``` r

launch_rfair()   # bslib Shiny app: scores, per-metric report, reuse/access panels
```

## Quick start

``` r

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
plot(a, type = "sunburst")   # concentric FAIR sunburst (also "category" / "metric")
as_fuji_json(a)       # F-UJI-compatible JSON
as_rdf(a)             # DQV + schema.org Rating + FAIR Test Results (JSON-LD)

fair_recommendations(a)   # what to fix, largest score gain first
fair_compare(a, a2)       # a2: the same record after a metadata fix

# Research software, scored against the FRSM metrics (GitHub, GitLab,
# Codeberg, or a software DOI that links its repository):
sw <- assess_fair("https://github.com/pangaea-data-publisher/fuji",
                  metric_version = "0.7_software")
sw$software                  # the repository signals the FRSM tests use

fair4rs_principles()         # the FAIR4RS principles the software metrics map to
fair4rs_principles("R")      # filter to one foundational principle
```

## Metric versions and F-UJI options

`rfair` bundles the current F-UJI website choices plus release-specific
legacy metric files from upstream F-UJI:

``` r

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

Supported metadata service type labels include OAI-PMH, OGC CSW, SPARQL,
DCAT, schema.org JSON-LD, DataCite, Crossref, Signposting, typed links,
RO-Crate, CKAN, and a generic other metadata document option.

## Beyond F-UJI

``` r

# A license can be present yet NOT open for reuse
license_reuse("https://creativecommons.org/licenses/by-nc-nd/4.0/")$is_open
#> [1] FALSE

# Controlled-access / sensitive data is not a FAIR failure
classify_access(access_level = "closedAccess",
                urls = "https://www.ncbi.nlm.nih.gov/gap/...")$controlled_access
#> [1] TRUE

# Identifier hygiene (layered / non-persistent PIDs)
identifier_hygiene("RRID:MGI:5577054")$issues

# Canonical FAIR principle definitions (GO FAIR Foundation / FAIR-nanopubs)
fair_principles("R")
```

These results are attached to every assessment (`a$reuse`, `a$access`,
`a$identifier_hygiene`) and shown in the app.

## Batch assessment and rtransparent

[`assess_fair_batch()`](https://choxos.github.io/rfair/reference/assess_fair_batch.md)
scores a vector of identifiers and returns one tidy row per identifier.
[`assess_data_code()`](https://choxos.github.io/rfair/reference/assess_data_code.md)
bridges [rtransparent](https://github.com/choxos/rtransparency): it
takes the data and code identifiers rtransparent extracts from articles
(its `open_data_links` and `open_code_links` columns; DOIs, repository
URLs, and identifiers.org `prefix:accession` codes such as `geo:GSE…`)
and scores each, using the FsF data metrics for data and the FRSM
software metrics for code.

``` r

rt <- rtransparent::rt_data_code_pmc(xml)          # is_open_data, open_data_links, ...
scores <- assess_data_code(rt, id_col = "pmid")    # one row per (article, data/code link)
```

[`split_identifiers()`](https://choxos.github.io/rfair/reference/split_identifiers.md)
parses the `" ; "`-joined link strings on their own.

Long runs can go faster and survive interruptions:

``` r

res <- assess_fair_batch(ids, workers = 4, keep = TRUE)   # parallel; keep full results
res2 <- assess_fair_batch(ids, previous = res)            # resume: skip rows already scored
attr(res, "assessments")                                   # the fair_assessment objects
```

The batch output has `resolved` and `http_status` columns, so dead links
are counted rather than scored. Set `GITHUB_PAT` for software
assessments: without a token GitHub allows 60 API requests an hour
(about 15 repositories). `options(rfair.cache_dir = "path")` caches HTTP
responses between runs, and `assess_fair(max_time = 60)` caps the time
spent on one identifier.

## HTTP API scaffold

`rfair` also ships a Plumber scaffold and OpenAPI contract for teams
that want to expose the same assessment engine over HTTP:

``` r

api <- system.file("plumber", "rfair-api.R", package = "rfair")
pr <- plumber::pr(api)
pr$run(port = 8000)
```

The machine-readable API contract is installed at:

``` r

system.file("openapi", "rfair-openapi.yaml", package = "rfair")
```

The API and the Shiny app fetch whatever URL a visitor sends, so both
set `options(rfair.block_private_hosts = TRUE)`: URLs that are not
http(s), and hosts that resolve to loopback, private, link-local, or
cloud metadata addresses, are refused. Each request connects to the
address that was checked, so DNS rebinding cannot swap it, and every
redirect is checked, with credentials dropped when a redirect changes
scheme, host, or port. Headless rendering is off in the API unless the
server sets `RFAIR_API_ALLOW_HEADLESS=true`, and it runs outside this
guard. Before exposing either publicly, also put it behind a proxy with
request limits.

## How it works

    id_parse()  ->  resolve  ->  harvest  ->  merge  ->  17 metric evaluators
                ->  F/A/I/R score  ->  fair_assessment

    harvest: landing page (schema.org JSON-LD, microdata, RDFa; Dublin Core,
    OpenGraph, Highwire meta tags) · signposting typed links · DataCite JSON ·
    CSL JSON (Crossref and other DOI agencies) · XML (DataCite, MODS, EML,
    ISO 19139) · RDF · code forges (GitHub, GitLab, Codeberg) · repository file
    APIs (Zenodo, figshare, Dataverse, Dryad) · data link probes

rfair is checked against the reference F-UJI service with
`tests/conformance/run.R`, monthly in CI: on 2026-09-22 it matched F-UJI
4.0.0 on 97.6% of 85 metric comparisons (see
`tests/conformance/README.md`). The FRSM software scores are heuristic
and not yet validated against expert ratings;
[`frsm_agreement()`](https://choxos.github.io/rfair/reference/frsm_agreement.md)
supports that study.

Reference data (SPDX licenses, file formats, access rights, protocols,
metadata standards, FAIR principles, reusabledata.org curations) is
baked in from the F-UJI sources by the scripts in `data-raw/`.

## Citation and metadata

The repository includes `CITATION.cff` and `codemeta.json` so software
harvesters can find rfair’s authorship, license, version, dependencies,
repository URL, and upstream F-UJI provenance. Each release is archived
on Zenodo with a citable DOI; the concept DOI
[10.5281/zenodo.20775127](https://doi.org/10.5281/zenodo.20775127)
always resolves to the latest version. Cite the version you used, or run
`citation("rfair")`.

## Acknowledgements

`rfair` began as a fork of the
[rfuji](https://github.com/NFDI4Chem/rfuji) F-UJI API client (Steffen
Neumann) and reimplements the assessment engine natively in R. It is a
native R port of [F-UJI](https://github.com/pangaea-data-publisher/fuji)
(© PANGAEA, MIT), itself based on the FAIRsFAIR metrics. The software
metrics operationalize the **FAIR Principles for Research Software
(FAIR4RS)**: Chue Hong, N. P., Katz, D. S., Barker, M., Lamprecht,
A.-L., Martinez, C., Psomopoulos, F. E., Harrow, J., Castro, L. J.,
Gruenpeter, M., Martinez, P. A., Honeyman, T., et al. (2022). *FAIR
Principles for Research Software (FAIR4RS Principles)* (1.0). Research
Data Alliance. <https://doi.org/10.15497/RDA00068> (CC BY 4.0). License
reusability uses the [(Re)usable Data Project](https://reusabledata.org)
rubric; data FAIR principle definitions come from the
[FAIR-nanopubs](https://peta-pico.github.io/FAIR-nanopubs/principles/index-en.html)
vocabulary referenced by [the GO FAIR
Foundation](https://www.gofair.foundation/fair-principles).

## Use of AI

Parts of `rfair` were developed with the assistance of AI coding tools
(Anthropic’s Claude, via Claude Code), including code drafting,
documentation, and test scaffolding. All AI-assisted output was
reviewed, tested, and verified by the author, who is solely responsible
for the package and its correctness.

## License

GPL-3. See <https://www.gnu.org/licenses/gpl-3.0> for the full license
text. rfair bundles reference data from external projects under their
own (MIT, CC0-1.0, CC-BY-4.0) licenses; see `LICENSE.note` for the
provenance and terms.
