# Serialize a FAIR assessment to RDF (DQV + schema.org Rating + FTR).

Emits the assessment as W3C Data Quality Vocabulary quality measurements
(one per FAIR category and one per metric) plus a schema.org Rating, the
machine-readable form the F-UJI service publishes, and one FAIR Test
Result per metric test using the OSTrails FAIR Testing Resource
vocabulary (<https://w3id.org/ftr/>, version 1.3.0): `prov:value` pass
or fail, `ftr:completion`, the evidence as `ftr:log`, and for failed
tests the
[`fair_recommendations()`](https://choxos.github.io/rfair/reference/fair_recommendations.md)
action as an `ftr:suggestion`. Metrics and tests are identified within
the metric specification (for example
`https://doi.org/10.5281/zenodo.6461229#FsF-F1-01MD-1`).

## Usage

``` r
as_rdf(x, format = c("jsonld", "turtle"))
```

## Arguments

- x:

  A
  [fair_assessment](https://choxos.github.io/rfair/reference/fair_assessment.md)
  object.

- format:

  `"jsonld"` (default) or `"turtle"` (needs the optional `rdflib` and
  `jsonld` packages).

## Value

A character scalar of serialized RDF.

## Examples

``` r
# \donttest{
a <- assess_fair("https://doi.org/10.5281/zenodo.8347772")
cat(as_rdf(a))
#> {
#>   "@context": {
#>     "dcat": "http://www.w3.org/ns/dcat#",
#>     "dc": "http://purl.org/dc/terms/",
#>     "schema": "http://schema.org/",
#>     "dqv": "http://www.w3.org/ns/dqv#",
#>     "prov": "http://www.w3.org/ns/prov#",
#>     "ftr": "https://w3id.org/ftr#",
#>     "rfair": "https://github.com/choxos/rfair#"
#>   },
#>   "@type": ["schema:Dataset", "dqv:QualityMetadata", "schema:Rating"],
#>   "dc:creator": "rfair",
#>   "dc:title": "FAIR assessment results for https://doi.org/10.5281/zenodo.8347772",
#>   "dc:source": "https://doi.org/10.5281/zenodo.8347772",
#>   "schema:ratingValue": 88.46,
#>   "schema:bestRating": 100,
#>   "schema:worstRating": 0,
#>   "schema:reviewAspect": "FAIRness",
#>   "prov:wasGeneratedBy": {
#>     "@type": "prov:Activity",
#>     "prov:used": "https://doi.org/10.5281/zenodo.8347772"
#>   },
#>   "prov:wasDerivedFrom": {
#>     "@type": "ftr:TestResultSet",
#>     "prov:hadMember": [
#>       {
#>         "@type": "ftr:TestResult",
#>         "dc:identifier": "FsF-F1-01MD-1",
#>         "dc:title": "Metadata identifier follows a defined unique identifier syntax or scheme (IRI, URL, UUID, HASH or PID)",
#>         "prov:value": "pass",
#>         "ftr:completion": 1,
#>         "ftr:outputFromTest": {
#>           "@id": "https://doi.org/10.5281/zenodo.15045911#FsF-F1-01MD-1"
#>         },
#>         "ftr:assessmentTarget": {
#>           "@id": "https://zenodo.org/records/8347772"
#>         },
#>         "ftr:log": "doi"
#>       },
#>       {
#>         "@type": "ftr:TestResult",
#>         "dc:identifier": "FsF-F1-01MD-2",
#>         "dc:title": "Data identifier follows a defined unique identifier syntax (IRI, URL, UUID, HASH or PID)",
#>         "prov:value": "fail",
#>         "ftr:completion": 0,
#>         "ftr:outputFromTest": {
#>           "@id": "https://doi.org/10.5281/zenodo.15045911#FsF-F1-01MD-2"
#>         },
#>         "ftr:assessmentTarget": {
#>           "@id": "https://zenodo.org/records/8347772"
#>         },
#>         "ftr:suggestion": {
#>           "@type": "ftr:GuidanceContext",
#>           "dc:description": "Give each data file a unique identifier (a stable URL or PID) and list it in the metadata."
#>         }
#>       },
#>       {
#>         "@type": "ftr:TestResult",
#>         "dc:identifier": "FsF-F1-02MD-1",
#>         "dc:title": "Metadata identifier follows a defined persistent identifier syntax",
#>         "prov:value": "pass",
#>         "ftr:completion": 1,
#>         "ftr:outputFromTest": {
#>           "@id": "https://doi.org/10.5281/zenodo.15045911#FsF-F1-02MD-1"
#>         },
#>         "ftr:assessmentTarget": {
#>           "@id": "https://zenodo.org/records/8347772"
#>         },
#>         "ftr:log": "doi"
#>       },
#>       {
#>         "@type": "ftr:TestResult",
#>         "dc:identifier": "FsF-F1-02MD-2",
#>         "dc:title": "Persistent identifier for metadata is registered and maintained by a PID authority",
#>         "prov:value": "pass",
#>         "ftr:completion": 1,
#>         "ftr:outputFromTest": {
#>           "@id": "https://doi.org/10.5281/zenodo.15045911#FsF-F1-02MD-2"
#>         },
#>         "ftr:assessmentTarget": {
#>           "@id": "https://zenodo.org/records/8347772"
#>         },
#>         "ftr:log": "https://zenodo.org/records/8347772"
#>       },
#>       {
#>         "@type": "ftr:TestResult",
#>         "dc:identifier": "FsF-F1-02MD-4",
#>         "dc:title": "Data identifier follows a defined persistent identifier syntax",
#>         "prov:value": "fail",
#>         "ftr:completion": 0,
#>         "ftr:outputFromTest": {
#>           "@id": "https://doi.org/10.5281/zenodo.15045911#FsF-F1-02MD-4"
#>         },
#>         "ftr:assessmentTarget": {
#>           "@id": "https://zenodo.org/records/8347772"
#>         },
#>         "ftr:suggestion": {
#>           "@type": "ftr:GuidanceContext",
#>           "dc:description": "Give the data files persistent identifiers, or link them from a record that has one."
#>         }
#>       },
#>       {
#>         "@type": "ftr:TestResult",
#>         "dc:identifier": "FsF-F1-02MD-5",
#>         "dc:title": "Persistent identifier for data is registered and maintained by a PID authority",
#>         "prov:value": "fail",
#>         "ftr:completion": 0,
#>         "ftr:outputFromTest": {
#>           "@id": "https://doi.org/10.5281/zenodo.15045911#FsF-F1-02MD-5"
#>         },
#>         "ftr:assessmentTarget": {
#>           "@id": "https://zenodo.org/records/8347772"
#>         },
#>         "ftr:suggestion": {
#>           "@type": "ftr:GuidanceContext",
#>           "dc:description": "Register the data file identifiers with a PID authority so they resolve reliably."
#>         }
#>       },
#>       {
#>         "@type": "ftr:TestResult",
#>         "dc:identifier": "FsF-F2-01M-2",
#>         "dc:title": "Core data citation metadata is available",
#>         "prov:value": "pass",
#>         "ftr:completion": 1,
#>         "ftr:outputFromTest": {
#>           "@id": "https://doi.org/10.5281/zenodo.15045911#FsF-F2-01M-2"
#>         },
#>         "ftr:assessmentTarget": {
#>           "@id": "https://zenodo.org/records/8347772"
#>         },
#>         "ftr:log": "creator, title, object_identifier, publication_date, publisher, object_type"
#>       },
#>       {
#>         "@type": "ftr:TestResult",
#>         "dc:identifier": "FsF-F2-01M-3",
#>         "dc:title": "Core descriptive metadata is available",
#>         "prov:value": "pass",
#>         "ftr:completion": 1,
#>         "ftr:outputFromTest": {
#>           "@id": "https://doi.org/10.5281/zenodo.15045911#FsF-F2-01M-3"
#>         },
#>         "ftr:assessmentTarget": {
#>           "@id": "https://zenodo.org/records/8347772"
#>         },
#>         "ftr:log": "creator, title, object_identifier, publication_date, publisher, object_type, summary, keywords"
#>       },
#>       {
#>         "@type": "ftr:TestResult",
#>         "dc:identifier": "FsF-F3-01M-2",
#>         "dc:title": "Metadata contains a PID or URL which indicates the location of the downloadable data content",
#>         "prov:value": "pass",
#>         "ftr:completion": 1,
#>         "ftr:outputFromTest": {
#>           "@id": "https://doi.org/10.5281/zenodo.15045911#FsF-F3-01M-2"
#>         },
#>         "ftr:assessmentTarget": {
#>           "@id": "https://zenodo.org/records/8347772"
#>         },
#>         "ftr:log": "https://zenodo.org/records/8347772/files/pangaea-data-publisher/fuji-v2.2.5.zip"
#>       },
#>       {
#>         "@type": "ftr:TestResult",
#>         "dc:identifier": "FsF-F4-01M-1",
#>         "dc:title": "Metadata is given in a way major search engines can ingest it for their catalogues (Dublin Core or schema.org or DCAT encoded in microdata, RDFa, embedded JSON-LD or meta tags see e.g. Google Dataset Search webmaster guidelines)",
#>         "prov:value": "pass",
#>         "ftr:completion": 1,
#>         "ftr:outputFromTest": {
#>           "@id": "https://doi.org/10.5281/zenodo.15045911#FsF-F4-01M-1"
#>         },
#>         "ftr:assessmentTarget": {
#>           "@id": "https://zenodo.org/records/8347772"
#>         },
#>         "ftr:log": "schema.org; opengraph; highwire"
#>       },
#>       {
#>         "@type": "ftr:TestResult",
#>         "dc:identifier": "FsF-A1-01M-1",
#>         "dc:title": "Information about access restrictions or rights can be identified in metadata",
#>         "prov:value": "pass",
#>         "ftr:completion": 1,
#>         "ftr:outputFromTest": {
#>           "@id": "https://doi.org/10.5281/zenodo.15045911#FsF-A1-01M-1"
#>         },
#>         "ftr:assessmentTarget": {
#>           "@id": "https://zenodo.org/records/8347772"
#>         },
#>         "ftr:log": "info:eu-repo/semantics/openAccess"
#>       },
#>       {
#>         "@type": "ftr:TestResult",
#>         "dc:identifier": "FsF-A1-02MD-1",
#>         "dc:title": "Metadata are retrievable via their specified identifier",
#>         "prov:value": "pass",
#>         "ftr:completion": 1,
#>         "ftr:outputFromTest": {
#>           "@id": "https://doi.org/10.5281/zenodo.15045911#FsF-A1-02MD-1"
#>         },
#>         "ftr:assessmentTarget": {
#>           "@id": "https://zenodo.org/records/8347772"
#>         },
#>         "ftr:log": "https://zenodo.org/records/8347772; https://zenodo.org/api/records/8347772; https://data.crosscite.org/10.5281%2Fzenodo.8347772"
#>       },
#>       {
#>         "@type": "ftr:TestResult",
#>         "dc:identifier": "FsF-A1-02MD-2",
#>         "dc:title": "Data are retrievable via the identifiers given in metadata",
#>         "prov:value": "pass",
#>         "ftr:completion": 1,
#>         "ftr:outputFromTest": {
#>           "@id": "https://doi.org/10.5281/zenodo.15045911#FsF-A1-02MD-2"
#>         },
#>         "ftr:assessmentTarget": {
#>           "@id": "https://zenodo.org/records/8347772"
#>         },
#>         "ftr:log": "https://zenodo.org/records/8347772/files/pangaea-data-publisher/fuji-v2.2.5.zip"
#>       },
#>       {
#>         "@type": "ftr:TestResult",
#>         "dc:identifier": "FsF-A1.1-01MD-1",
#>         "dc:title": "Identifier leading to metadata matches a scheme indicating a standardized web communication protocol.",
#>         "prov:value": "pass",
#>         "ftr:completion": 1,
#>         "ftr:outputFromTest": {
#>           "@id": "https://doi.org/10.5281/zenodo.15045911#FsF-A1.1-01MD-1"
#>         },
#>         "ftr:assessmentTarget": {
#>           "@id": "https://zenodo.org/records/8347772"
#>         },
#>         "ftr:log": "https"
#>       },
#>       {
#>         "@type": "ftr:TestResult",
#>         "dc:identifier": "FsF-A1.1-01MD-2",
#>         "dc:title": "Identifier leading to data are matching a schema indicating a standardized web communication protocol.",
#>         "prov:value": "pass",
#>         "ftr:completion": 1,
#>         "ftr:outputFromTest": {
#>           "@id": "https://doi.org/10.5281/zenodo.15045911#FsF-A1.1-01MD-2"
#>         },
#>         "ftr:assessmentTarget": {
#>           "@id": "https://zenodo.org/records/8347772"
#>         },
#>         "ftr:log": "https://zenodo.org/records/8347772/files/pangaea-data-publisher/fuji-v2.2.5.zip"
#>       },
#>       {
#>         "@type": "ftr:TestResult",
#>         "dc:identifier": "FsF-A1.2-01MD-1",
#>         "dc:title": "The communication protocol found in identifiers (IRIs) leading to metadata supports authentication.",
#>         "prov:value": "pass",
#>         "ftr:completion": 1,
#>         "ftr:outputFromTest": {
#>           "@id": "https://doi.org/10.5281/zenodo.15045911#FsF-A1.2-01MD-1"
#>         },
#>         "ftr:assessmentTarget": {
#>           "@id": "https://zenodo.org/records/8347772"
#>         },
#>         "ftr:log": "https"
#>       },
#>       {
#>         "@type": "ftr:TestResult",
#>         "dc:identifier": "FsF-A1.2-01MD-2",
#>         "dc:title": "The communication protocol identified in data links (IRIs) supports authentication.",
#>         "prov:value": "pass",
#>         "ftr:completion": 1,
#>         "ftr:outputFromTest": {
#>           "@id": "https://doi.org/10.5281/zenodo.15045911#FsF-A1.2-01MD-2"
#>         },
#>         "ftr:assessmentTarget": {
#>           "@id": "https://zenodo.org/records/8347772"
#>         },
#>         "ftr:log": "https://zenodo.org/records/8347772/files/pangaea-data-publisher/fuji-v2.2.5.zip"
#>       },
#>       {
#>         "@type": "ftr:TestResult",
#>         "dc:identifier": "FsF-I1-01M-1",
#>         "dc:title": "Parsable, structured metadata (JSON-LD, RDFa) is embedded in the landing page XHTML/HTML code",
#>         "prov:value": "pass",
#>         "ftr:completion": 1,
#>         "ftr:outputFromTest": {
#>           "@id": "https://doi.org/10.5281/zenodo.15045911#FsF-I1-01M-1"
#>         },
#>         "ftr:assessmentTarget": {
#>           "@id": "https://zenodo.org/records/8347772"
#>         },
#>         "ftr:log": "embedded JSON-LD/RDFa"
#>       },
#>       {
#>         "@type": "ftr:TestResult",
#>         "dc:identifier": "FsF-I1-01M-2",
#>         "dc:title": "Parsable, structured metadata (RDF, JSON-LD) is accessible through content negotiation, typed links or sparql endpoint",
#>         "prov:value": "pass",
#>         "ftr:completion": 1,
#>         "ftr:outputFromTest": {
#>           "@id": "https://doi.org/10.5281/zenodo.15045911#FsF-I1-01M-2"
#>         },
#>         "ftr:assessmentTarget": {
#>           "@id": "https://zenodo.org/records/8347772"
#>         },
#>         "ftr:log": "content negotiation"
#>       },
#>       {
#>         "@type": "ftr:TestResult",
#>         "dc:identifier": "FsF-I2-01M-2",
#>         "dc:title": "Metadata uses terms from registered vocabularies that are identified by their namespaces",
#>         "prov:value": "fail",
#>         "ftr:completion": 0,
#>         "ftr:outputFromTest": {
#>           "@id": "https://doi.org/10.5281/zenodo.15045911#FsF-I2-01M-2"
#>         },
#>         "ftr:assessmentTarget": {
#>           "@id": "https://zenodo.org/records/8347772"
#>         },
#>         "ftr:suggestion": {
#>           "@type": "ftr:GuidanceContext",
#>           "dc:description": "Use terms from registered semantic vocabularies (for example ontologies listed in BioPortal or the LOD cloud) and expose their namespaces in RDF metadata."
#>         }
#>       },
#>       {
#>         "@type": "ftr:TestResult",
#>         "dc:identifier": "FsF-I3-01M-1",
#>         "dc:title": "Related resources are referenced in plain text within appropriate metadata properties indicating the relation type",
#>         "prov:value": "pass",
#>         "ftr:completion": 1,
#>         "ftr:outputFromTest": {
#>           "@id": "https://doi.org/10.5281/zenodo.15045911#FsF-I3-01M-1"
#>         },
#>         "ftr:assessmentTarget": {
#>           "@id": "https://zenodo.org/records/8347772"
#>         },
#>         "ftr:log": "2 related resources"
#>       },
#>       {
#>         "@type": "ftr:TestResult",
#>         "dc:identifier": "FsF-I3-01M-2",
#>         "dc:title": "Related resources are referenced by machine readable links or identifiers within appropriate metadata properties indicating the relation type",
#>         "prov:value": "pass",
#>         "ftr:completion": 1,
#>         "ftr:outputFromTest": {
#>           "@id": "https://doi.org/10.5281/zenodo.15045911#FsF-I3-01M-2"
#>         },
#>         "ftr:assessmentTarget": {
#>           "@id": "https://zenodo.org/records/8347772"
#>         },
#>         "ftr:log": "qualified by identifiers"
#>       },
#>       {
#>         "@type": "ftr:TestResult",
#>         "dc:identifier": "FsF-R1-01M-1",
#>         "dc:title": "Minimum information (resource type) about the available data content is specified in the metadata",
#>         "prov:value": "pass",
#>         "ftr:completion": 1,
#>         "ftr:outputFromTest": {
#>           "@id": "https://doi.org/10.5281/zenodo.15045911#FsF-R1-01M-1"
#>         },
#>         "ftr:assessmentTarget": {
#>           "@id": "https://zenodo.org/records/8347772"
#>         },
#>         "ftr:log": "https://schema.org/SoftwareSourceCode; Software; SoftwareSourceCode; https://zenodo.org/records/8347772/files/pangaea-data-publisher/fuji-v2.2.5.zip"
#>       },
#>       {
#>         "@type": "ftr:TestResult",
#>         "dc:identifier": "FsF-R1-01M-2",
#>         "dc:title": "Information on the manner and form (file size and type or service (API) endpoint and protocol) in which data is delivered is provided",
#>         "prov:value": "pass",
#>         "ftr:completion": 1,
#>         "ftr:outputFromTest": {
#>           "@id": "https://doi.org/10.5281/zenodo.15045911#FsF-R1-01M-2"
#>         },
#>         "ftr:assessmentTarget": {
#>           "@id": "https://zenodo.org/records/8347772"
#>         },
#>         "ftr:log": "file type/size, data links, or service endpoint"
#>       },
#>       {
#>         "@type": "ftr:TestResult",
#>         "dc:identifier": "FsF-R1-01M-3",
#>         "dc:title": "Measured variables or observation types are specified in metadata",
#>         "prov:value": "pass",
#>         "ftr:completion": 1,
#>         "ftr:outputFromTest": {
#>           "@id": "https://doi.org/10.5281/zenodo.15045911#FsF-R1-01M-3"
#>         },
#>         "ftr:assessmentTarget": {
#>           "@id": "https://zenodo.org/records/8347772"
#>         },
#>         "ftr:log": "declared content descriptor"
#>       },
#>       {
#>         "@type": "ftr:TestResult",
#>         "dc:identifier": "FsF-R1.1-01M-1",
#>         "dc:title": "Licence information is given in an appropriate metadata element",
#>         "prov:value": "pass",
#>         "ftr:completion": 1,
#>         "ftr:outputFromTest": {
#>           "@id": "https://doi.org/10.5281/zenodo.15045911#FsF-R1.1-01M-1"
#>         },
#>         "ftr:assessmentTarget": {
#>           "@id": "https://zenodo.org/records/8347772"
#>         },
#>         "ftr:log": "https://opensource.org/license/mit/; https://opensource.org/licenses/MIT; info:eu-repo/semantics/openAccess; MIT License; Open Access"
#>       },
#>       {
#>         "@type": "ftr:TestResult",
#>         "dc:identifier": "FsF-R1.2-01M-1",
#>         "dc:title": "Metadata contains elements which hold provenance information which can be mapped to PROV based on PROV-DC.",
#>         "prov:value": "pass",
#>         "ftr:completion": 1,
#>         "ftr:outputFromTest": {
#>           "@id": "https://doi.org/10.5281/zenodo.15045911#FsF-R1.2-01M-1"
#>         },
#>         "ftr:assessmentTarget": {
#>           "@id": "https://zenodo.org/records/8347772"
#>         },
#>         "ftr:log": "creator; publisher; modified_date; publication_date; related_resources; object_type"
#>       },
#>       {
#>         "@type": "ftr:TestResult",
#>         "dc:identifier": "FsF-R1.2-01M-2",
#>         "dc:title": "Metadata contains elements which hold provenance information using formal provenance ontologies (PROV, PAV).",
#>         "prov:value": "fail",
#>         "ftr:completion": 0,
#>         "ftr:outputFromTest": {
#>           "@id": "https://doi.org/10.5281/zenodo.15045911#FsF-R1.2-01M-2"
#>         },
#>         "ftr:assessmentTarget": {
#>           "@id": "https://zenodo.org/records/8347772"
#>         },
#>         "ftr:suggestion": {
#>           "@type": "ftr:GuidanceContext",
#>           "dc:description": "Express provenance with a formal ontology such as PROV-O or PAV in RDF metadata."
#>         }
#>       },
#>       {
#>         "@type": "ftr:TestResult",
#>         "dc:identifier": "FsF-R1.3-01M-1",
#>         "dc:title": "Community specific metadata standard is detected using namespaces or schemas found in provided metadata",
#>         "prov:value": "fail",
#>         "ftr:completion": 0,
#>         "ftr:outputFromTest": {
#>           "@id": "https://doi.org/10.5281/zenodo.15045911#FsF-R1.3-01M-1"
#>         },
#>         "ftr:assessmentTarget": {
#>           "@id": "https://zenodo.org/records/8347772"
#>         },
#>         "ftr:suggestion": {
#>           "@type": "ftr:GuidanceContext",
#>           "dc:description": "Describe the data with a metadata standard of its research community (for example EML, ISO 19115, DDI, or a domain schema) and expose it."
#>         }
#>       },
#>       {
#>         "@type": "ftr:TestResult",
#>         "dc:identifier": "FsF-R1.3-01M-3",
#>         "dc:title": "Multidisciplinary but community endorsed metadata (RDA Metadata Standards Catalog, fairsharing) standard is detected by namespace",
#>         "prov:value": "pass",
#>         "ftr:completion": 1,
#>         "ftr:outputFromTest": {
#>           "@id": "https://doi.org/10.5281/zenodo.15045911#FsF-R1.3-01M-3"
#>         },
#>         "ftr:assessmentTarget": {
#>           "@id": "https://zenodo.org/records/8347772"
#>         },
#>         "ftr:log": "schemaorg; datacite"
#>       },
#>       {
#>         "@type": "ftr:TestResult",
#>         "dc:identifier": "FsF-R1.3-02D-1",
#>         "dc:title": "Data is available in a file format recommended by the research community (long term file formats, open file formats or scientific file format)",
#>         "prov:value": "fail",
#>         "ftr:completion": 0,
#>         "ftr:outputFromTest": {
#>           "@id": "https://doi.org/10.5281/zenodo.15045911#FsF-R1.3-02D-1"
#>         },
#>         "ftr:assessmentTarget": {
#>           "@id": "https://zenodo.org/records/8347772"
#>         },
#>         "ftr:suggestion": {
#>           "@type": "ftr:GuidanceContext",
#>           "dc:description": "Publish the data in an open, long-term, or community-recommended file format (for example CSV, NetCDF, HDF5) and declare the format in the metadata."
#>         }
#>       }
#>     ]
#>   },
#>   "rfair:metricVersion": "0.8",
#>   "rfair:softwareVersion": "0.2.0",
#>   "dqv:hasQualityMeasurement": [
#>     {
#>       "@type": "dqv:QualityMeasurement",
#>       "dqv:value": 100,
#>       "dqv:isMeasurementOf": "https://w3id.org/fair/principles/terms/F"
#>     },
#>     {
#>       "@type": "dqv:QualityMeasurement",
#>       "dqv:value": 100,
#>       "dqv:isMeasurementOf": "https://w3id.org/fair/principles/terms/A"
#>     },
#>     {
#>       "@type": "dqv:QualityMeasurement",
#>       "dqv:value": 66.67,
#>       "dqv:isMeasurementOf": "https://w3id.org/fair/principles/terms/I"
#>     },
#>     {
#>       "@type": "dqv:QualityMeasurement",
#>       "dqv:value": 83.33,
#>       "dqv:isMeasurementOf": "https://w3id.org/fair/principles/terms/R"
#>     },
#>     {
#>       "@type": "dqv:QualityMeasurement",
#>       "dqv:value": 88.46,
#>       "dqv:isMeasurementOf": "https://w3id.org/fair/principles/terms/FAIR"
#>     },
#>     {
#>       "@type": "dqv:QualityMeasurement",
#>       "dqv:value": 100,
#>       "dqv:computedOn": {
#>         "@id": "https://zenodo.org/records/8347772"
#>       },
#>       "dqv:isMeasurementOf": {
#>         "@id": "https://doi.org/10.5281/zenodo.15045911#FsF-F1-01MD",
#>         "@type": "dqv:Metric",
#>         "dc:title": "Metadata and data are assigned a globally unique identifier."
#>       }
#>     },
#>     {
#>       "@type": "dqv:QualityMeasurement",
#>       "dqv:value": 100,
#>       "dqv:computedOn": {
#>         "@id": "https://zenodo.org/records/8347772"
#>       },
#>       "dqv:isMeasurementOf": {
#>         "@id": "https://doi.org/10.5281/zenodo.15045911#FsF-F1-02MD",
#>         "@type": "dqv:Metric",
#>         "dc:title": "Metadata and data are assigned a persistent identifier."
#>       }
#>     },
#>     {
#>       "@type": "dqv:QualityMeasurement",
#>       "dqv:value": 100,
#>       "dqv:computedOn": {
#>         "@id": "https://zenodo.org/records/8347772"
#>       },
#>       "dqv:isMeasurementOf": {
#>         "@id": "https://doi.org/10.5281/zenodo.15045911#FsF-F2-01M",
#>         "@type": "dqv:Metric",
#>         "dc:title": "Metadata includes descriptive core elements (creator, title, data identifier, publisher, publication date, summary and keywords) to support data findability."
#>       }
#>     },
#>     {
#>       "@type": "dqv:QualityMeasurement",
#>       "dqv:value": 100,
#>       "dqv:computedOn": {
#>         "@id": "https://zenodo.org/records/8347772"
#>       },
#>       "dqv:isMeasurementOf": {
#>         "@id": "https://doi.org/10.5281/zenodo.15045911#FsF-F3-01M",
#>         "@type": "dqv:Metric",
#>         "dc:title": "Metadata includes the identifier of the data it describes."
#>       }
#>     },
#>     {
#>       "@type": "dqv:QualityMeasurement",
#>       "dqv:value": 100,
#>       "dqv:computedOn": {
#>         "@id": "https://zenodo.org/records/8347772"
#>       },
#>       "dqv:isMeasurementOf": {
#>         "@id": "https://doi.org/10.5281/zenodo.15045911#FsF-F4-01M",
#>         "@type": "dqv:Metric",
#>         "dc:title": "Metadata is offered in such a way that it can be registered or indexed by search engines."
#>       }
#>     },
#>     {
#>       "@type": "dqv:QualityMeasurement",
#>       "dqv:value": 100,
#>       "dqv:computedOn": {
#>         "@id": "https://zenodo.org/records/8347772"
#>       },
#>       "dqv:isMeasurementOf": {
#>         "@id": "https://doi.org/10.5281/zenodo.15045911#FsF-A1-01M",
#>         "@type": "dqv:Metric",
#>         "dc:title": "Metadata contains access level and access conditions of the data."
#>       }
#>     },
#>     {
#>       "@type": "dqv:QualityMeasurement",
#>       "dqv:value": 100,
#>       "dqv:computedOn": {
#>         "@id": "https://zenodo.org/records/8347772"
#>       },
#>       "dqv:isMeasurementOf": {
#>         "@id": "https://doi.org/10.5281/zenodo.15045911#FsF-A1-02MD",
#>         "@type": "dqv:Metric",
#>         "dc:title": "Metadata and data are retrievable by their identifier"
#>       }
#>     },
#>     {
#>       "@type": "dqv:QualityMeasurement",
#>       "dqv:value": 100,
#>       "dqv:computedOn": {
#>         "@id": "https://zenodo.org/records/8347772"
#>       },
#>       "dqv:isMeasurementOf": {
#>         "@id": "https://doi.org/10.5281/zenodo.15045911#FsF-A1.1-01MD",
#>         "@type": "dqv:Metric",
#>         "dc:title": "A standardized communication protocol is used to access metadata and data."
#>       }
#>     },
#>     {
#>       "@type": "dqv:QualityMeasurement",
#>       "dqv:value": 100,
#>       "dqv:computedOn": {
#>         "@id": "https://zenodo.org/records/8347772"
#>       },
#>       "dqv:isMeasurementOf": {
#>         "@id": "https://doi.org/10.5281/zenodo.15045911#FsF-A1.2-01MD",
#>         "@type": "dqv:Metric",
#>         "dc:title": "Metadata and data are accessible through a standardized communication protocol which supports authentication."
#>       }
#>     },
#>     {
#>       "@type": "dqv:QualityMeasurement",
#>       "dqv:value": 100,
#>       "dqv:computedOn": {
#>         "@id": "https://zenodo.org/records/8347772"
#>       },
#>       "dqv:isMeasurementOf": {
#>         "@id": "https://doi.org/10.5281/zenodo.15045911#FsF-I1-01M",
#>         "@type": "dqv:Metric",
#>         "dc:title": "Metadata is represented using a formal knowledge representation language."
#>       }
#>     },
#>     {
#>       "@type": "dqv:QualityMeasurement",
#>       "dqv:value": 0,
#>       "dqv:computedOn": {
#>         "@id": "https://zenodo.org/records/8347772"
#>       },
#>       "dqv:isMeasurementOf": {
#>         "@id": "https://doi.org/10.5281/zenodo.15045911#FsF-I2-01M",
#>         "@type": "dqv:Metric",
#>         "dc:title": "Metadata uses registered semantic resources"
#>       }
#>     },
#>     {
#>       "@type": "dqv:QualityMeasurement",
#>       "dqv:value": 100,
#>       "dqv:computedOn": {
#>         "@id": "https://zenodo.org/records/8347772"
#>       },
#>       "dqv:isMeasurementOf": {
#>         "@id": "https://doi.org/10.5281/zenodo.15045911#FsF-I3-01M",
#>         "@type": "dqv:Metric",
#>         "dc:title": "Metadata includes qualified references between the data and its related entities."
#>       }
#>     },
#>     {
#>       "@type": "dqv:QualityMeasurement",
#>       "dqv:value": 100,
#>       "dqv:computedOn": {
#>         "@id": "https://zenodo.org/records/8347772"
#>       },
#>       "dqv:isMeasurementOf": {
#>         "@id": "https://doi.org/10.5281/zenodo.15045911#FsF-R1-01M",
#>         "@type": "dqv:Metric",
#>         "dc:title": "Metadata specifies the content of the data."
#>       }
#>     },
#>     {
#>       "@type": "dqv:QualityMeasurement",
#>       "dqv:value": 100,
#>       "dqv:computedOn": {
#>         "@id": "https://zenodo.org/records/8347772"
#>       },
#>       "dqv:isMeasurementOf": {
#>         "@id": "https://doi.org/10.5281/zenodo.15045911#FsF-R1.1-01M",
#>         "@type": "dqv:Metric",
#>         "dc:title": "Metadata includes license information under which data can be reused."
#>       }
#>     },
#>     {
#>       "@type": "dqv:QualityMeasurement",
#>       "dqv:value": 100,
#>       "dqv:computedOn": {
#>         "@id": "https://zenodo.org/records/8347772"
#>       },
#>       "dqv:isMeasurementOf": {
#>         "@id": "https://doi.org/10.5281/zenodo.15045911#FsF-R1.2-01M",
#>         "@type": "dqv:Metric",
#>         "dc:title": "Metadata includes provenance information about data creation or generation."
#>       }
#>     },
#>     {
#>       "@type": "dqv:QualityMeasurement",
#>       "dqv:value": 100,
#>       "dqv:computedOn": {
#>         "@id": "https://zenodo.org/records/8347772"
#>       },
#>       "dqv:isMeasurementOf": {
#>         "@id": "https://doi.org/10.5281/zenodo.15045911#FsF-R1.3-01M",
#>         "@type": "dqv:Metric",
#>         "dc:title": "Metadata follows a standard recommended by the target research community of the data."
#>       }
#>     },
#>     {
#>       "@type": "dqv:QualityMeasurement",
#>       "dqv:value": 0,
#>       "dqv:computedOn": {
#>         "@id": "https://zenodo.org/records/8347772"
#>       },
#>       "dqv:isMeasurementOf": {
#>         "@id": "https://doi.org/10.5281/zenodo.15045911#FsF-R1.3-02D",
#>         "@type": "dqv:Metric",
#>         "dc:title": "Data is available in a file format recommended by the target research community."
#>       }
#>     }
#>   ]
#> }
# }
```
