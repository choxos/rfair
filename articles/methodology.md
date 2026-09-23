# How rfair works: methodology and architecture

This vignette describes what rfair measures and how, in enough detail to
interpret and reproduce its scores. For a quick tour see
[`vignette("rfair")`](https://choxos.github.io/rfair/articles/rfair.md);
for the reuse/sensitivity extensions see
[`vignette("beyond-fuji")`](https://choxos.github.io/rfair/articles/beyond-fuji.md).

## 1. Background: FAIR, the FAIRsFAIR metrics, and F-UJI

The **FAIR principles** (Wilkinson et al. 2016) state that research data
should be **F**indable, **A**ccessible, **I**nteroperable, and
**R**eusable. They are aspirational; to assess a real data object you
need *measurable* indicators.

The **FAIRsFAIR** project turned the principles into a concrete,
testable metric set, and the **F-UJI** tool (Devaraju & Huber, PANGAEA)
implemented an automated assessment service for them. F-UJI is a Python
web service: you send it a persistent identifier (PID) and it returns
per-metric scores.

`rfair` is a **native R reimplementation** of the F-UJI metrics (version
0.8). It performs the whole assessment in R, with no external server, so
assessments are scriptable, reproducible, and embeddable in R pipelines.
The original `rfair` package (v1) was only an HTTP client for an F-UJI
server; this version (v2) is the engine itself.

## 2. The assessment pipeline

A single call to
[`assess_fair()`](https://choxos.github.io/rfair/reference/assess_fair.md)
runs this pipeline:

    identifier
       │  id_parse()            scheme detection + normalization + resolver URL
       ▼
    resolution                  content-negotiated GET, follow redirects -> landing page
       │  resolve_landing_page()   (a failure is recorded in $resolution, not scored)
       ▼
    harvesting                  a sequence of collectors, in priority order:
       │   collect_html_meta()      embedded schema.org (JSON-LD, microdata, RDFa),
       │                            Dublin Core, OpenGraph, Highwire meta tags
       │   collect_signposting()    HTTP Link header + <link rel> typed links
       │   collect_datacite()       DataCite JSON via content negotiation
       │   collect_csl()            CSL JSON for Crossref and other DOI agencies
       │   collect_xml()            DataCite XML, Dublin Core, MODS, EML, ISO19139
       │   collect_rdf()            JSON-LD (native) and Turtle/RDF-XML (via rdflib)
       │   collect_forge()          GitHub, GitLab, or Codeberg repository +
       │                            codemeta.json + CITATION.cff; software DOIs
       │                            are bridged to their linked repository
       │   collect_repository_files() file lists from Zenodo, figshare, Dataverse,
       │                            or Dryad APIs when no data links were found
       │   harvest_data()           headers of a streamed GET on up to five data
       │                            links: HTTP status, MIME type, and size
       ▼
    mapping + merging           each source is mapped to one reference schema and
       │  merge_metadata()         merged (first-non-empty for scalars; union for
       │                           lists; longer-but-similar replacement)
       ▼
    evaluation                  one evaluator per metric inspects the merged metadata
       │  run_evaluators()         and the resolved identifier, scoring each test
       ▼
    scoring                     per-test scores -> per-metric -> F/A/I/R -> overall
       │  get_assessment_summary()
       ▼
    fair_assessment             tidy S3 object (print / summary / as.data.frame /
                                as_fuji_json / as_rdf)

### Identifier handling

[`id_parse()`](https://choxos.github.io/rfair/reference/id_parse.md)
recognizes DOIs, Handles, ARKs, URNs, UUIDs, `identifiers.org` PIDs,
w3id, and plain URLs, normalizes them, and constructs a resolver URL.
Persistence is inferred from the scheme.

``` r

id_parse("https://doi.org/10.5281/zenodo.8347772")[c("preferred_schema", "is_persistent", "identifier_url")]
#> $preferred_schema
#> [1] "doi"
#> 
#> $is_persistent
#> [1] TRUE
#> 
#> $identifier_url
#> [1] "https://doi.org/10.5281/zenodo.8347772"
```

### Harvesting and content negotiation

Different repositories expose metadata in different ways. rfair asks for
several representations of the same object via HTTP **content
negotiation** (the `Accept` header) and scrapes the landing page, then
**merges** everything into a single reference schema (~30 elements:
`creator`, `title`, `publisher`, `publication_date`, `license`,
`access_level`, `object_content_identifier`, `related_resources`, …).
When two sources disagree, scalars keep the first non-empty value
(replaced only by a longer, sufficiently-similar string), and
list-valued elements are unioned.

### The metric model

Metrics are data-driven: their definitions, tests, scores, and maturity
levels come from the bundled FAIRsFAIR YAML, not from hard-coded R
logic.

``` r

rfair_metric_versions()      # bundled metric versions
#>  [1] "0.8"                 "0.5"                 "0.5ssv2"            
#>  [4] "0.5ss"               "0.5env"              "0.7_software"       
#>  [7] "0.7_software_cessda" "0.6a2a"              "0.4"                
#> [10] "0.3"                 "0.2"
# v0.8 has 17 metrics across F/A/I/R (one row each):
nrow(as.data.frame(assess_fair("https://doi.org/10.5281/zenodo.8347772", resolve = FALSE)))
#> [1] 17
```

Each metric has one or more **tests**. A test contributes a *score* and
a *maturity* level (a CMMI level from 0 to 3: incomplete, initial,
moderate, advanced) when it passes. Metrics use one of two scoring
mechanisms:

- **cumulative**: passed tests’ scores add up;
- **alternative**: tests are alternative routes to the same points (the
  earned score is capped at the metric total).

The criterium engine (`criterium_engine.R`) builds each metric’s result
from the YAML and lets evaluators mark tests passed;
[`as_fuji_json()`](https://choxos.github.io/rfair/reference/as_fuji_json.md)
then emits a payload matching the upstream F-UJI `FAIRResults` schema.

## 3. What each FAIR category measures (v0.8)

|  | metric | what rfair checks |
|----|----|----|
| **F** | F1-01MD | identifier follows a unique scheme (URI/URN/UUID/HASH/PID) |
|  | F1-02MD | identifier is persistent and registered (resolves) |
|  | F2-01M | core descriptive metadata present (creator, title, id, date, publisher, type, summary, keywords) |
|  | F3-01M | metadata links to the downloadable data content |
|  | F4-01M | metadata offered in a search-engine-ingestible way (embedded JSON-LD / meta tags) |
| **A** | A1-01M | access level / rights are stated in metadata |
|  | A1-02MD | metadata and data are retrievable via their identifiers |
|  | A1.1-01MD | identifiers use a standardized communication protocol (http/https/ftp) |
|  | A1.2-01MD | the protocol supports authentication where needed |
| **I** | I1-01M | metadata uses a formal, machine-readable representation (JSON-LD/RDF/XML) |
|  | I2-01M | metadata uses terms from registered semantic vocabularies |
|  | I3-01M | qualified references to related entities (with relation types) |
| **R** | R1-01M | metadata describes the data content (type, format/size) |
|  | R1.1-01M | a machine-readable license is present and SPDX/CC-recognized |
|  | R1.2-01M | provenance information (creators, dates, contributors) |
|  | R1.3-01M | a community-/discipline-endorsed metadata standard is used |
|  | R1.3-02D | data is in a recommended (scientific/open/long-term) file format |

The score for a category is the sum of earned over total across its
metrics; the overall FAIR score is the sum across all 17, and the
maturity is the (clamped) mean of the per-category maturities.

``` r

# the canonical principle definitions these metrics map to
fair_principles("I")[, c("id", "definition")]
#>   id
#> 1 I1
#> 2 I2
#> 3 I3
#>                                                                                                  definition
#> 1 (meta)data use a formal, accessible, shared, and broadly applicable language for knowledge representation
#> 2                                                   (meta)data use vocabularies that follow FAIR principles
#> 3                                               (meta)data include qualified references to other (meta)data
```

## 4. Software FAIR (FRSM)

For software objects, rfair also bundles the FRSM (FAIR for Research
Software) metric set; select it with `metric_version = "0.7_software"`.
The forge harvester (GitHub, GitLab, Codeberg and other Forgejo/Gitea
instances) inspects the repository file tree for signals (a license
file, tests, CI workflows, dependency manifests, a registry DOI, a
release version, contributors, Software Heritage and package registry
archiving) and the 17 FRSM evaluators score from them. A software DOI
whose metadata links a repository (such as Zenodo’s `IsSupplementTo`
link to GitHub) is scored from that repository.

FRSM scoring is heuristic and not yet validated against expert
judgement; the results carry `evidence_type = "heuristic"`.
[`frsm_agreement()`](https://choxos.github.io/rfair/reference/frsm_agreement.md)
supports a validation study: raters judge each FRSM test for a sample of
repositories (template in
`system.file("extdata", "frsm_validation_template.csv", package = "rfair")`),
and the function reports per-test agreement and Cohen’s kappa between
rfair and the raters’ majority, and between raters.

## 5. Fidelity to F-UJI

Because rfair reimplements an existing scoring engine, it includes a
non-CRAN conformance harness. `tests/conformance/run.R` runs identifiers
through both rfair and a version-matched F-UJI server and compares
per-metric earned scores; a scheduled workflow runs it monthly against
the F-UJI Docker image. On 2026-09-22, against F-UJI 4.0.0 (metrics
v0.8), rfair 0.2.0 matched **97.6% of 85 metric comparisons** over five
fixture DOIs (rfair 0.1.0: 91.8%). The one remaining divergence is the
data file-format metric for zip archives: F-UJI downloads the files and
lists the formats inside with Apache Tika, while rfair reads the
declared and served content types. A separate harness
(`tests/conformance/parity.R`) compares the R engine with the browser
TypeScript engine on registry-derivable metrics after the `webapp`
branch is checked out alongside the package.

## 6. Beyond F-UJI

rfair adds checks that automated FAIR tools usually miss, motivated by
peer review of a COVID-19 FAIR study: license *reusability* (not just
presence) with the (Re)usable Data Project taxonomy,
controlled-access/sensitive-data flagging, identifier hygiene, and the
**FAIR-TLC** (Traceable, Licensed, Connected) extension. See
[`vignette("beyond-fuji")`](https://choxos.github.io/rfair/articles/beyond-fuji.md).

## 7. Limitations

- The browser app is registry-only (CORS): it cannot harvest landing
  pages, so some metrics score lower than the R engine.
- I2-01M (semantic vocabularies) scores 0 for objects whose metadata
  uses only default namespaces (dc/schema.org/DataCite) and no terms
  from registered vocabularies; this matches F-UJI.
- RDF Turtle/RDF-XML harvesting needs the optional `rdflib` package
  (system `librdf`), and
  [`as_rdf()`](https://choxos.github.io/rfair/reference/as_rdf.md)
  Turtle output also needs `jsonld`; without them those paths are
  skipped.
- Live scores depend on the object’s current metadata and on third-party
  services (DataCite, doi.org, code forges, repository APIs) being
  reachable. Failed sources are listed in `$harvest_errors`.

## References

- Wilkinson et al. (2016). The FAIR Guiding Principles. *Sci Data*.
- Devaraju & Huber. F-UJI.
  <https://github.com/pangaea-data-publisher/fuji>
- FAIRsFAIR metrics.
- Carbon et al. (2019). (Re)usable data licensing. *PLOS ONE*.
