# Serialize a FAIR assessment to RDF (DQV + schema.org Rating).

Emits the assessment as W3C Data Quality Vocabulary quality measurements
plus a schema.org Rating, the machine-readable form the F-UJI service
publishes.

## Usage

``` r
as_rdf(x, format = c("jsonld", "turtle"))
```

## Arguments

- x:

  A
  [fair_assessment](https://choxos.github.io/rfuji/reference/fair_assessment.md)
  object.

- format:

  `"jsonld"` (default) or `"turtle"` (needs the optional `rdflib`
  package).

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
#>     "rfuji": "https://github.com/choxos/rfuji#"
#>   },
#>   "@type": ["schema:Dataset", "dqv:QualityMetadata", "schema:Rating"],
#>   "dc:creator": "rfuji",
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
#>   "rfuji:metricVersion": "0.8",
#>   "rfuji:softwareVersion": "2.3.0",
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
#>     }
#>   ]
#> }
# }
```
