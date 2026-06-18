# Convert a FAIR assessment to F-UJI-compatible JSON.

Produces a payload matching the upstream F-UJI `FAIRResults` schema, so
the output can be consumed by tools built for the F-UJI service.

## Usage

``` r
as_fuji_json(x, pretty = TRUE)
```

## Arguments

- x:

  A
  [fair_assessment](https://choxos.github.io/rfuji/reference/fair_assessment.md)
  object.

- pretty:

  Whether to pretty-print the JSON.

## Value

A JSON string (class `json`).

## Examples

``` r
# \donttest{
a <- assess_fair("https://doi.org/10.5281/zenodo.8347772")
cat(as_fuji_json(a))
#> {
#>   "test_id": "4114fa229002ed3433f77ebd3857888da20b07c6",
#>   "request": {
#>     "object_identifier": "https://doi.org/10.5281/zenodo.8347772",
#>     "metric_version": "0.8",
#>     "use_datacite": true,
#>     "metadata_service_endpoint": "",
#>     "metadata_service_type": "",
#>     "test_debug": false
#>   },
#>   "start_timestamp": "2026-06-18T18:06:13+0000",
#>   "end_timestamp": "2026-06-18T18:06:19+0000",
#>   "software_version": "2.6.0",
#>   "metric_version": "0.8",
#>   "metric_specification": "https://doi.org/10.5281/zenodo.15045911",
#>   "total_metrics": 17,
#>   "summary": {
#>     "score_earned": {
#>       "A": 7,
#>       "F": 7,
#>       "I": 4,
#>       "R": 5,
#>       "A1": 3,
#>       "A1.1": 2,
#>       "A1.2": 2,
#>       "F1": 2,
#>       "F2": 2,
#>       "F3": 1,
#>       "F4": 2,
#>       "I1": 2,
#>       "I2": 0,
#>       "I3": 2,
#>       "R1": 2,
#>       "R1.1": 1,
#>       "R1.2": 1,
#>       "R1.3": 1,
#>       "FAIR": 23
#>     },
#>     "score_total": {
#>       "A": 7,
#>       "F": 7,
#>       "I": 6,
#>       "R": 6,
#>       "A1": 3,
#>       "A1.1": 2,
#>       "A1.2": 2,
#>       "F1": 2,
#>       "F2": 2,
#>       "F3": 1,
#>       "F4": 2,
#>       "I1": 2,
#>       "I2": 2,
#>       "I3": 2,
#>       "R1": 2,
#>       "R1.1": 1,
#>       "R1.2": 1,
#>       "R1.3": 2,
#>       "FAIR": 26
#>     },
#>     "score_percent": {
#>       "A": 100,
#>       "F": 100,
#>       "I": 66.67,
#>       "R": 83.33,
#>       "A1": 100,
#>       "A1.1": 100,
#>       "A1.2": 100,
#>       "F1": 100,
#>       "F2": 100,
#>       "F3": 100,
#>       "F4": 100,
#>       "I1": 100,
#>       "I2": 0,
#>       "I3": 100,
#>       "R1": 100,
#>       "R1.1": 100,
#>       "R1.2": 100,
#>       "R1.3": 50,
#>       "FAIR": 88.46
#>     },
#>     "maturity": {
#>       "A": 3,
#>       "F": 3,
#>       "I": 2,
#>       "R": 2,
#>       "A1": 3,
#>       "A1.1": 3,
#>       "A1.2": 3,
#>       "F1": 3,
#>       "F2": 3,
#>       "F3": 3,
#>       "F4": 3,
#>       "I1": 3,
#>       "I2": 0,
#>       "I3": 3,
#>       "R1": 3,
#>       "R1.1": 3,
#>       "R1.2": 2,
#>       "R1.3": 1,
#>       "FAIR": 2.5
#>     },
#>     "status_total": {
#>       "A1": 2,
#>       "A1.1": 1,
#>       "A1.2": 1,
#>       "F1": 2,
#>       "F2": 1,
#>       "F3": 1,
#>       "F4": 1,
#>       "I1": 1,
#>       "I2": 1,
#>       "I3": 1,
#>       "R1": 1,
#>       "R1.1": 1,
#>       "R1.2": 1,
#>       "R1.3": 2,
#>       "A": 4,
#>       "F": 5,
#>       "I": 3,
#>       "R": 5,
#>       "FAIR": 17
#>     },
#>     "status_passed": {
#>       "A1": 2,
#>       "A1.1": 1,
#>       "A1.2": 1,
#>       "F1": 2,
#>       "F2": 1,
#>       "F3": 1,
#>       "F4": 1,
#>       "I1": 1,
#>       "I2": 0,
#>       "I3": 1,
#>       "R1": 1,
#>       "R1.1": 1,
#>       "R1.2": 1,
#>       "R1.3": 1,
#>       "A": 4,
#>       "F": 5,
#>       "I": 2,
#>       "R": 4,
#>       "FAIR": 15
#>     }
#>   },
#>   "results": [
#>     {
#>       "id": 1,
#>       "metric_identifier": "FsF-F1-01MD",
#>       "metric_name": "Metadata and data are assigned a globally unique identifier.",
#>       "metric_tests": {
#>         "FsF-F1-01MD-1": {
#>           "metric_test_identifier": "FsF-F1-01MD-1",
#>           "metric_test_name": "Metadata identifier follows a defined unique identifier syntax or scheme (IRI, URL, UUID, HASH or PID)",
#>           "agnostic_test_identifier": "FsF-F1-01MD-1",
#>           "metric_test_score": {
#>             "earned": 1,
#>             "total": 1
#>           },
#>           "metric_test_maturity": 3,
#>           "metric_test_status": "pass",
#>           "evidence": "doi"
#>         },
#>         "FsF-F1-01MD-2": {
#>           "metric_test_identifier": "FsF-F1-01MD-2",
#>           "metric_test_name": "Data identifier follows a defined unique identifier syntax (IRI, URL, UUID, HASH or PID)",
#>           "agnostic_test_identifier": "FsF-F1-01MD-2",
#>           "metric_test_score": {
#>             "earned": 0,
#>             "total": 0
#>           },
#>           "metric_test_maturity": 3,
#>           "metric_test_status": "fail",
#>           "evidence": []
#>         }
#>       },
#>       "test_status": "pass",
#>       "score": {
#>         "earned": 1,
#>         "total": 1,
#>         "percent": 100
#>       },
#>       "maturity": 3,
#>       "output": {
#>         "guid": "https://doi.org/10.5281/zenodo.8347772",
#>         "guid_scheme": "doi"
#>       }
#>     },
#>     {
#>       "id": 2,
#>       "metric_identifier": "FsF-F1-02MD",
#>       "metric_name": "Metadata and data are assigned a persistent identifier.",
#>       "metric_tests": {
#>         "FsF-F1-02MD-1": {
#>           "metric_test_identifier": "FsF-F1-02MD-1",
#>           "metric_test_name": "Metadata identifier follows a defined persistent identifier syntax",
#>           "agnostic_test_identifier": "FsF-F1-02MD-1",
#>           "metric_test_score": {
#>             "earned": 0.5,
#>             "total": 0.5
#>           },
#>           "metric_test_maturity": 1,
#>           "metric_test_status": "pass",
#>           "evidence": "doi"
#>         },
#>         "FsF-F1-02MD-2": {
#>           "metric_test_identifier": "FsF-F1-02MD-2",
#>           "metric_test_name": "Persistent identifier for metadata is registered and maintained by a PID authority",
#>           "agnostic_test_identifier": "FsF-F1-02MD-2",
#>           "metric_test_score": {
#>             "earned": 0.5,
#>             "total": 0.5
#>           },
#>           "metric_test_maturity": 3,
#>           "metric_test_status": "pass",
#>           "evidence": "https://zenodo.org/records/8347772"
#>         },
#>         "FsF-F1-02MD-4": {
#>           "metric_test_identifier": "FsF-F1-02MD-4",
#>           "metric_test_name": "Data identifier follows a defined persistent identifier syntax",
#>           "agnostic_test_identifier": "FsF-F1-02MD-4",
#>           "metric_test_score": {
#>             "earned": 0,
#>             "total": 0
#>           },
#>           "metric_test_maturity": 3,
#>           "metric_test_status": "fail",
#>           "evidence": []
#>         },
#>         "FsF-F1-02MD-5": {
#>           "metric_test_identifier": "FsF-F1-02MD-5",
#>           "metric_test_name": "Persistent identifier for data is registered and maintained by a PID authority",
#>           "agnostic_test_identifier": "FsF-F1-02MD-5",
#>           "metric_test_score": {
#>             "earned": 0,
#>             "total": 0
#>           },
#>           "metric_test_maturity": 3,
#>           "metric_test_status": "fail",
#>           "evidence": []
#>         }
#>       },
#>       "test_status": "pass",
#>       "score": {
#>         "earned": 1,
#>         "total": 1,
#>         "percent": 100
#>       },
#>       "maturity": 3,
#>       "output": {
#>         "pid": "https://doi.org/10.5281/zenodo.8347772",
#>         "pid_scheme": "doi",
#>         "resolved_url": "https://zenodo.org/records/8347772"
#>       }
#>     },
#>     {
#>       "id": 5,
#>       "metric_identifier": "FsF-F2-01M",
#>       "metric_name": "Metadata includes descriptive core elements (creator, title, data identifier, publisher, publication date, summary and keywords) to support data findability.",
#>       "metric_tests": {
#>         "FsF-F2-01M-2": {
#>           "metric_test_identifier": "FsF-F2-01M-2",
#>           "metric_test_name": "Core data citation metadata is available",
#>           "agnostic_test_identifier": "FsF-F2-01M-2",
#>           "metric_test_score": {
#>             "earned": 1,
#>             "total": 1
#>           },
#>           "metric_test_maturity": 2,
#>           "metric_test_status": "pass",
#>           "evidence": "creator, title, object_identifier, publication_date, publisher, object_type"
#>         },
#>         "FsF-F2-01M-3": {
#>           "metric_test_identifier": "FsF-F2-01M-3",
#>           "metric_test_name": "Core descriptive metadata is available",
#>           "agnostic_test_identifier": "FsF-F2-01M-3",
#>           "metric_test_score": {
#>             "earned": 1,
#>             "total": 1
#>           },
#>           "metric_test_maturity": 3,
#>           "metric_test_status": "pass",
#>           "evidence": "creator, title, object_identifier, publication_date, publisher, object_type, summary, keywords"
#>         }
#>       },
#>       "test_status": "pass",
#>       "score": {
#>         "earned": 2,
#>         "total": 2,
#>         "percent": 100
#>       },
#>       "maturity": 3,
#>       "output": {
#>         "core_metadata_status": "all metadata",
#>         "core_metadata_found": {
#>           "title": "F-UJI - An Automated FAIR Data Assessment Tool",
#>           "object_type": [
#>             "https://schema.org/SoftwareSourceCode",
#>             "Software",
#>             "SoftwareSourceCode"
#>           ],
#>           "publication_date": "2023-09-15",
#>           "creator": [
#>             "Devaraju, Anusuriya",
#>             "Huber, Robert",
#>             "Anusuriya Devaraju",
#>             "Robert Huber"
#>           ],
#>           "publisher": [
#>             {
#>               "name": "Zenodo"
#>             }
#>           ],
#>           "summary": "FAIRsFAIR has developed F-UJI, a service based on REST, and is piloting a programmatic assessment of the FAIRness of research datasets in five trustworthy data repositories.",
#>           "keywords": [
#>             "PANGAEA",
#>             "FAIRsFAIR",
#>             "FAIR Principles",
#>             "Data Object Assessment",
#>             "Swagger",
#>             "FAIR",
#>             "Research Data",
#>             "FAIR data",
#>             "Metadata harvesting"
#>           ],
#>           "object_identifier": "https://doi.org/10.5281/zenodo.8347772"
#>         }
#>       }
#>     },
#>     {
#>       "id": 6,
#>       "metric_identifier": "FsF-F3-01M",
#>       "metric_name": "Metadata includes the identifier of the data it describes.",
#>       "metric_tests": {
#>         "FsF-F3-01M-2": {
#>           "metric_test_identifier": "FsF-F3-01M-2",
#>           "metric_test_name": "Metadata contains a PID or URL which indicates the location of the downloadable data content",
#>           "agnostic_test_identifier": "FsF-F3-01M-2",
#>           "metric_test_score": {
#>             "earned": 1,
#>             "total": 1
#>           },
#>           "metric_test_maturity": 3,
#>           "metric_test_status": "pass",
#>           "evidence": "https://zenodo.org/records/8347772/files/pangaea-data-publisher/fuji-v2.2.5.zip"
#>         }
#>       },
#>       "test_status": "pass",
#>       "score": {
#>         "earned": 1,
#>         "total": 1,
#>         "percent": 100
#>       },
#>       "maturity": 3,
#>       "output": {
#>         "object_content_identifier": "https://zenodo.org/records/8347772/files/pangaea-data-publisher/fuji-v2.2.5.zip"
#>       }
#>     },
#>     {
#>       "id": 7,
#>       "metric_identifier": "FsF-F4-01M",
#>       "metric_name": "Metadata is offered in such a way that it can be registered or indexed by search engines.",
#>       "metric_tests": {
#>         "FsF-F4-01M-1": {
#>           "metric_test_identifier": "FsF-F4-01M-1",
#>           "metric_test_name": "Metadata is given in a way major search engines can ingest it for their catalogues (Dublin Core or schema.org or DCAT encoded in microdata, RDFa, embedded JSON-LD or meta tags see e.g. Google Dataset Search webmaster guidelines)",
#>           "agnostic_test_identifier": "FsF-F4-01M-1",
#>           "metric_test_score": {
#>             "earned": 2,
#>             "total": 2
#>           },
#>           "metric_test_maturity": 3,
#>           "metric_test_status": "pass",
#>           "evidence": ["schema.org", "opengraph", "highwire"]
#>         }
#>       },
#>       "test_status": "pass",
#>       "score": {
#>         "earned": 2,
#>         "total": 2,
#>         "percent": 100
#>       },
#>       "maturity": 3,
#>       "output": {
#>         "search_mechanisms": ["schema.org", "opengraph", "highwire"]
#>       }
#>     },
#>     {
#>       "id": 8,
#>       "metric_identifier": "FsF-A1-01M",
#>       "metric_name": "Metadata contains access level and access conditions of the data.",
#>       "metric_tests": {
#>         "FsF-A1-01M-1": {
#>           "metric_test_identifier": "FsF-A1-01M-1",
#>           "metric_test_name": "Information about access restrictions or rights can be identified in metadata",
#>           "agnostic_test_identifier": "FsF-A1-01M-1",
#>           "metric_test_score": {
#>             "earned": 1,
#>             "total": 1
#>           },
#>           "metric_test_maturity": 3,
#>           "metric_test_status": "pass",
#>           "evidence": "info:eu-repo/semantics/openAccess"
#>         }
#>       },
#>       "test_status": "pass",
#>       "score": {
#>         "earned": 1,
#>         "total": 1,
#>         "percent": 100
#>       },
#>       "maturity": 3,
#>       "output": {
#>         "access_level": "info:eu-repo/semantics/openAccess",
#>         "access_condition": "public"
#>       }
#>     },
#>     {
#>       "id": 9,
#>       "metric_identifier": "FsF-A1-02MD",
#>       "metric_name": "Metadata and data are retrievable by their identifier",
#>       "metric_tests": {
#>         "FsF-A1-02MD-1": {
#>           "metric_test_identifier": "FsF-A1-02MD-1",
#>           "metric_test_name": "Metadata are retrievable via their specified identifier",
#>           "agnostic_test_identifier": "FsF-A1-02MD-1",
#>           "metric_test_score": {
#>             "earned": 1,
#>             "total": 1
#>           },
#>           "metric_test_maturity": 3,
#>           "metric_test_status": "pass",
#>           "evidence": "https://zenodo.org/records/8347772"
#>         },
#>         "FsF-A1-02MD-2": {
#>           "metric_test_identifier": "FsF-A1-02MD-2",
#>           "metric_test_name": "Data are retrievable via the identifiers given in metadata",
#>           "agnostic_test_identifier": "FsF-A1-02MD-2",
#>           "metric_test_score": {
#>             "earned": 1,
#>             "total": 1
#>           },
#>           "metric_test_maturity": 3,
#>           "metric_test_status": "pass",
#>           "evidence": "https://zenodo.org/records/8347772/files/pangaea-data-publisher/fuji-v2.2.5.zip"
#>         }
#>       },
#>       "test_status": "pass",
#>       "score": {
#>         "earned": 2,
#>         "total": 2,
#>         "percent": 100
#>       },
#>       "maturity": 3,
#>       "output": null
#>     },
#>     {
#>       "id": 11,
#>       "metric_identifier": "FsF-A1.1-01MD",
#>       "metric_name": "A standardized communication protocol is used to access metadata and data.",
#>       "metric_tests": {
#>         "FsF-A1.1-01MD-1": {
#>           "metric_test_identifier": "FsF-A1.1-01MD-1",
#>           "metric_test_name": "Identifier leading to metadata matches a scheme indicating a standardized web communication protocol.",
#>           "agnostic_test_identifier": "FsF-A1.1-01MD-1",
#>           "metric_test_score": {
#>             "earned": 1,
#>             "total": 1
#>           },
#>           "metric_test_maturity": 3,
#>           "metric_test_status": "pass",
#>           "evidence": "https"
#>         },
#>         "FsF-A1.1-01MD-2": {
#>           "metric_test_identifier": "FsF-A1.1-01MD-2",
#>           "metric_test_name": "Identifier leading to data are matching a schema indicating a standardized web communication protocol.",
#>           "agnostic_test_identifier": "FsF-A1.1-01MD-2",
#>           "metric_test_score": {
#>             "earned": 1,
#>             "total": 1
#>           },
#>           "metric_test_maturity": 3,
#>           "metric_test_status": "pass",
#>           "evidence": "https://zenodo.org/records/8347772/files/pangaea-data-publisher/fuji-v2.2.5.zip"
#>         }
#>       },
#>       "test_status": "pass",
#>       "score": {
#>         "earned": 2,
#>         "total": 2,
#>         "percent": 100
#>       },
#>       "maturity": 3,
#>       "output": null
#>     },
#>     {
#>       "id": 12,
#>       "metric_identifier": "FsF-A1.2-01MD",
#>       "metric_name": "Metadata and data are accessible through a standardized communication protocol which supports authentication.",
#>       "metric_tests": {
#>         "FsF-A1.2-01MD-1": {
#>           "metric_test_identifier": "FsF-A1.2-01MD-1",
#>           "metric_test_name": "The communication protocol found in identifiers (IRIs) leading to metadata supports authentication.",
#>           "agnostic_test_identifier": "FsF-A1.2-01MD-1",
#>           "metric_test_score": {
#>             "earned": 1,
#>             "total": 1
#>           },
#>           "metric_test_maturity": 3,
#>           "metric_test_status": "pass",
#>           "evidence": "https"
#>         },
#>         "FsF-A1.2-01MD-2": {
#>           "metric_test_identifier": "FsF-A1.2-01MD-2",
#>           "metric_test_name": "The communication protocol identified in data links (IRIs) supports authentication.",
#>           "agnostic_test_identifier": "FsF-A1.2-01MD-2",
#>           "metric_test_score": {
#>             "earned": 1,
#>             "total": 1
#>           },
#>           "metric_test_maturity": 3,
#>           "metric_test_status": "pass",
#>           "evidence": "https://zenodo.org/records/8347772/files/pangaea-data-publisher/fuji-v2.2.5.zip"
#>         }
#>       },
#>       "test_status": "pass",
#>       "score": {
#>         "earned": 2,
#>         "total": 2,
#>         "percent": 100
#>       },
#>       "maturity": 3,
#>       "output": null
#>     },
#>     {
#>       "id": 13,
#>       "metric_identifier": "FsF-I1-01M",
#>       "metric_name": "Metadata is represented using a formal knowledge representation language.",
#>       "metric_tests": {
#>         "FsF-I1-01M-1": {
#>           "metric_test_identifier": "FsF-I1-01M-1",
#>           "metric_test_name": "Parsable, structured metadata (JSON-LD, RDFa) is embedded in the landing page XHTML/HTML code",
#>           "agnostic_test_identifier": "FsF-I1-01M-1",
#>           "metric_test_score": {
#>             "earned": 2,
#>             "total": 2
#>           },
#>           "metric_test_maturity": 2,
#>           "metric_test_status": "pass",
#>           "evidence": "embedded JSON-LD/RDFa"
#>         },
#>         "FsF-I1-01M-2": {
#>           "metric_test_identifier": "FsF-I1-01M-2",
#>           "metric_test_name": "Parsable, structured metadata (RDF, JSON-LD) is accessible through content negotiation, typed links or sparql endpoint",
#>           "agnostic_test_identifier": "FsF-I1-01M-2",
#>           "metric_test_score": {
#>             "earned": 2,
#>             "total": 2
#>           },
#>           "metric_test_maturity": 3,
#>           "metric_test_status": "pass",
#>           "evidence": "content negotiation"
#>         }
#>       },
#>       "test_status": "pass",
#>       "score": {
#>         "earned": 2,
#>         "total": 2,
#>         "percent": 100
#>       },
#>       "maturity": 3,
#>       "output": null
#>     },
#>     {
#>       "id": 14,
#>       "metric_identifier": "FsF-I2-01M",
#>       "metric_name": "Metadata uses registered semantic resources",
#>       "metric_tests": {
#>         "FsF-I2-01M-2": {
#>           "metric_test_identifier": "FsF-I2-01M-2",
#>           "metric_test_name": "Metadata uses terms from registered vocabularies that are identified by their namespaces",
#>           "agnostic_test_identifier": "FsF-I2-01M-2",
#>           "metric_test_score": {
#>             "earned": 0,
#>             "total": 2
#>           },
#>           "metric_test_maturity": 3,
#>           "metric_test_status": "fail",
#>           "evidence": []
#>         }
#>       },
#>       "test_status": "fail",
#>       "score": {
#>         "earned": 0,
#>         "total": 2,
#>         "percent": 0
#>       },
#>       "maturity": 0,
#>       "output": null
#>     },
#>     {
#>       "id": 15,
#>       "metric_identifier": "FsF-I3-01M",
#>       "metric_name": "Metadata includes qualified references between the data and its related entities.",
#>       "metric_tests": {
#>         "FsF-I3-01M-1": {
#>           "metric_test_identifier": "FsF-I3-01M-1",
#>           "metric_test_name": "Related resources are referenced in plain text within appropriate metadata properties indicating the relation type",
#>           "agnostic_test_identifier": "FsF-I3-01M-1",
#>           "metric_test_score": {
#>             "earned": 2,
#>             "total": 2
#>           },
#>           "metric_test_maturity": 2,
#>           "metric_test_status": "pass",
#>           "evidence": "2 related resources"
#>         },
#>         "FsF-I3-01M-2": {
#>           "metric_test_identifier": "FsF-I3-01M-2",
#>           "metric_test_name": "Related resources are referenced by machine readable links or identifiers within appropriate metadata properties indicating the relation type",
#>           "agnostic_test_identifier": "FsF-I3-01M-2",
#>           "metric_test_score": {
#>             "earned": 2,
#>             "total": 2
#>           },
#>           "metric_test_maturity": 3,
#>           "metric_test_status": "pass",
#>           "evidence": "qualified by identifiers"
#>         }
#>       },
#>       "test_status": "pass",
#>       "score": {
#>         "earned": 2,
#>         "total": 2,
#>         "percent": 100
#>       },
#>       "maturity": 3,
#>       "output": [
#>         {
#>           "related_resource": "https://github.com/pangaea-data-publisher/fuji/tree/v2.2.5",
#>           "relation_type": "IsSupplementTo"
#>         },
#>         {
#>           "related_resource": "10.5281/zenodo.6361400",
#>           "relation_type": "IsVersionOf"
#>         }
#>       ]
#>     },
#>     {
#>       "id": 16,
#>       "metric_identifier": "FsF-R1-01M",
#>       "metric_name": "Metadata specifies the content of the data.",
#>       "metric_tests": {
#>         "FsF-R1-01M-1": {
#>           "metric_test_identifier": "FsF-R1-01M-1",
#>           "metric_test_name": "Minimum information (resource type) about the available data content is specified in the metadata",
#>           "agnostic_test_identifier": "FsF-R1-01M-1",
#>           "metric_test_score": {
#>             "earned": 1,
#>             "total": 1
#>           },
#>           "metric_test_maturity": 1,
#>           "metric_test_status": "pass",
#>           "evidence": ["https://schema.org/SoftwareSourceCode", "Software", "SoftwareSourceCode", "https://zenodo.org/records/8347772/files/pangaea-data-publisher/fuji-v2.2.5.zip"]
#>         },
#>         "FsF-R1-01M-2": {
#>           "metric_test_identifier": "FsF-R1-01M-2",
#>           "metric_test_name": "Information on the manner and form (file size and type or service (API) endpoint and protocol) in which data is delivered is provided",
#>           "agnostic_test_identifier": "FsF-R1-01M-2",
#>           "metric_test_score": {
#>             "earned": 1,
#>             "total": 1
#>           },
#>           "metric_test_maturity": 3,
#>           "metric_test_status": "pass",
#>           "evidence": "file type/size, data links, or service endpoint"
#>         },
#>         "FsF-R1-01M-3": {
#>           "metric_test_identifier": "FsF-R1-01M-3",
#>           "metric_test_name": "Measured variables or observation types are specified in metadata",
#>           "agnostic_test_identifier": "FsF-R1-01M-3",
#>           "metric_test_score": {
#>             "earned": 0,
#>             "total": 0
#>           },
#>           "metric_test_maturity": 3,
#>           "metric_test_status": "pass",
#>           "evidence": "declared content descriptor"
#>         }
#>       },
#>       "test_status": "pass",
#>       "score": {
#>         "earned": 2,
#>         "total": 2,
#>         "percent": 100
#>       },
#>       "maturity": 3,
#>       "output": null
#>     },
#>     {
#>       "id": 17,
#>       "metric_identifier": "FsF-R1.1-01M",
#>       "metric_name": "Metadata includes license information under which data can be reused.",
#>       "metric_tests": {
#>         "FsF-R1.1-01M-1": {
#>           "metric_test_identifier": "FsF-R1.1-01M-1",
#>           "metric_test_name": "Licence information is given in an appropriate metadata element",
#>           "agnostic_test_identifier": "FsF-R1.1-01M-1",
#>           "metric_test_score": {
#>             "earned": 1,
#>             "total": 1
#>           },
#>           "metric_test_maturity": 3,
#>           "metric_test_status": "pass",
#>           "evidence": ["https://opensource.org/licenses/MIT", "info:eu-repo/semantics/openAccess", "MIT License", "Open Access"]
#>         }
#>       },
#>       "test_status": "pass",
#>       "score": {
#>         "earned": 1,
#>         "total": 1,
#>         "percent": 100
#>       },
#>       "maturity": 3,
#>       "output": [
#>         {
#>           "license": "https://opensource.org/licenses/MIT",
#>           "id": "MIT",
#>           "is_url": true,
#>           "spdx_uri": "http://spdx.org/licenses/MIT.html",
#>           "osi_approved": true,
#>           "valid": true
#>         },
#>         {
#>           "license": "info:eu-repo/semantics/openAccess",
#>           "id": null,
#>           "is_url": false,
#>           "spdx_uri": null,
#>           "osi_approved": false,
#>           "valid": false
#>         },
#>         {
#>           "license": "MIT License",
#>           "id": "MIT",
#>           "is_url": false,
#>           "spdx_uri": "http://spdx.org/licenses/MIT.html",
#>           "osi_approved": true,
#>           "valid": true
#>         },
#>         {
#>           "license": "Open Access",
#>           "id": null,
#>           "is_url": false,
#>           "spdx_uri": null,
#>           "osi_approved": false,
#>           "valid": false
#>         }
#>       ]
#>     },
#>     {
#>       "id": 18,
#>       "metric_identifier": "FsF-R1.2-01M",
#>       "metric_name": "Metadata includes provenance information about data creation or generation.",
#>       "metric_tests": {
#>         "FsF-R1.2-01M-1": {
#>           "metric_test_identifier": "FsF-R1.2-01M-1",
#>           "metric_test_name": "Metadata contains elements which hold provenance information which can be mapped to PROV based on PROV-DC.",
#>           "agnostic_test_identifier": "FsF-R1.2-01M-1",
#>           "metric_test_score": {
#>             "earned": 1,
#>             "total": 1
#>           },
#>           "metric_test_maturity": 2,
#>           "metric_test_status": "pass",
#>           "evidence": ["creator", "publisher", "modified_date", "publication_date", "related_resources", "object_type"]
#>         },
#>         "FsF-R1.2-01M-2": {
#>           "metric_test_identifier": "FsF-R1.2-01M-2",
#>           "metric_test_name": "Metadata contains elements which hold provenance information using formal provenance ontologies (PROV, PAV).",
#>           "agnostic_test_identifier": "FsF-R1.2-01M-2",
#>           "metric_test_score": {
#>             "earned": 0,
#>             "total": 1
#>           },
#>           "metric_test_maturity": 3,
#>           "metric_test_status": "fail",
#>           "evidence": []
#>         }
#>       },
#>       "test_status": "pass",
#>       "score": {
#>         "earned": 1,
#>         "total": 1,
#>         "percent": 100
#>       },
#>       "maturity": 2,
#>       "output": {
#>         "provenance_elements": ["creator", "publisher", "modified_date", "publication_date", "related_resources", "object_type"]
#>       }
#>     },
#>     {
#>       "id": 19,
#>       "metric_identifier": "FsF-R1.3-01M",
#>       "metric_name": "Metadata follows a standard recommended by the target research community of the data.",
#>       "metric_tests": {
#>         "FsF-R1.3-01M-1": {
#>           "metric_test_identifier": "FsF-R1.3-01M-1",
#>           "metric_test_name": "Community specific metadata standard is detected using namespaces or schemas found in provided metadata",
#>           "agnostic_test_identifier": "FsF-R1.3-01M-1",
#>           "metric_test_score": {
#>             "earned": 0,
#>             "total": 1
#>           },
#>           "metric_test_maturity": 3,
#>           "metric_test_status": "fail",
#>           "evidence": []
#>         },
#>         "FsF-R1.3-01M-3": {
#>           "metric_test_identifier": "FsF-R1.3-01M-3",
#>           "metric_test_name": "Multidisciplinary but community endorsed metadata (RDA Metadata Standards Catalog, fairsharing) standard is detected by namespace",
#>           "agnostic_test_identifier": "FsF-R1.3-01M-3",
#>           "metric_test_score": {
#>             "earned": 1,
#>             "total": 1
#>           },
#>           "metric_test_maturity": 1,
#>           "metric_test_status": "pass",
#>           "evidence": ["schemaorg", "datacite"]
#>         }
#>       },
#>       "test_status": "pass",
#>       "score": {
#>         "earned": 1,
#>         "total": 1,
#>         "percent": 100
#>       },
#>       "maturity": 1,
#>       "output": [
#>         {
#>           "metadata_standard": "schemaorg",
#>           "type": "generic",
#>           "url": "http://schema.org",
#>           "subject_areas": "Multidisciplinary"
#>         },
#>         {
#>           "metadata_standard": "datacite",
#>           "type": "generic",
#>           "url": "http://datacite.org/schema",
#>           "subject_areas": "Multidisciplinary"
#>         }
#>       ]
#>     },
#>     {
#>       "id": 20,
#>       "metric_identifier": "FsF-R1.3-02D",
#>       "metric_name": "Data is available in a file format recommended by the target research community.",
#>       "metric_tests": {
#>         "FsF-R1.3-02D-1": {
#>           "metric_test_identifier": "FsF-R1.3-02D-1",
#>           "metric_test_name": "Data is available in a file format recommended by the research community (long term file formats, open file formats or scientific file format)",
#>           "agnostic_test_identifier": "FsF-R1.3-02D-1",
#>           "metric_test_score": {
#>             "earned": 0,
#>             "total": 1
#>           },
#>           "metric_test_maturity": 3,
#>           "metric_test_status": "fail",
#>           "evidence": []
#>         }
#>       },
#>       "test_status": "fail",
#>       "score": {
#>         "earned": 0,
#>         "total": 1,
#>         "percent": 0
#>       },
#>       "maturity": 0,
#>       "output": null
#>     }
#>   ],
#>   "resolved_url": "https://zenodo.org/records/8347772"
#> }
# }
```
