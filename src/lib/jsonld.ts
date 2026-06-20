import type { Assessment } from "./types";

// Serialize an assessment as W3C DQV quality measurements plus a schema.org
// Rating, mirroring R/as_rdf.R and the machine-readable result F-UJI publishes.
// Suitable for embedding in a landing page (<script type="application/ld+json">).
const PRINCIPLE = "https://w3id.org/fair/principles/terms/";

export function asJsonLd(a: Assessment): string {
  const fair = a.summary.find((s) => s.category === "FAIR");
  const measurements = a.summary.map((s) => ({
    "@type": "dqv:QualityMeasurement",
    "dqv:value": s.percent,
    "dqv:isMeasurementOf": PRINCIPLE + s.category,
  }));
  const subjectType = /software/i.test(a.metric_version)
    ? "schema:SoftwareSourceCode"
    : "schema:Dataset";

  const doc = {
    "@context": {
      dc: "http://purl.org/dc/terms/",
      schema: "http://schema.org/",
      dqv: "http://www.w3.org/ns/dqv#",
      prov: "http://www.w3.org/ns/prov#",
      rfair: "https://github.com/choxos/rfair#",
    },
    "@type": [subjectType, "dqv:QualityMetadata", "schema:Rating"],
    "dc:creator": "rfair (web)",
    "dc:title": `FAIR assessment results for ${a.id}`,
    "dc:source": a.id,
    "schema:url": a.resolved_url ?? a.id,
    "schema:ratingValue": fair?.percent ?? 0,
    "schema:bestRating": 100,
    "schema:worstRating": 0,
    "schema:reviewAspect": "FAIRness",
    "prov:wasGeneratedBy": { "@type": "prov:Activity", "prov:used": a.id },
    "rfair:metricVersion": a.metric_version,
    "dqv:hasQualityMeasurement": measurements,
  };
  return JSON.stringify(doc, null, 2);
}
