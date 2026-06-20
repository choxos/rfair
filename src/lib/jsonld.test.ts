import { describe, it, expect } from "vitest";
import { asJsonLd } from "./jsonld";
import type { Assessment } from "./types";

const base = {
  id: "https://doi.org/10.5281/zenodo.8347772",
  resolved_url: "https://zenodo.org/records/8347772",
  metric_version: "0.8",
  summary: [
    { category: "F", earned: 7, total: 7, percent: 100, maturity: 3 },
    { category: "FAIR", earned: 23, total: 26, percent: 88.5, maturity: 2 },
  ],
} as unknown as Assessment;

describe("asJsonLd", () => {
  it("emits a schema.org Rating plus DQV measurements", () => {
    const doc = JSON.parse(asJsonLd(base));
    expect(doc["@type"]).toContain("schema:Rating");
    expect(doc["@type"]).toContain("schema:Dataset");
    expect(doc["schema:ratingValue"]).toBe(88.5);
    expect(doc["schema:bestRating"]).toBe(100);
    expect(doc["dqv:hasQualityMeasurement"]).toHaveLength(2);
    expect(doc["rfair:metricVersion"]).toBe("0.8");
    expect(doc["dc:source"]).toBe(base.id);
  });

  it("uses SoftwareSourceCode for software metric sets", () => {
    const doc = JSON.parse(asJsonLd({ ...base, metric_version: "0.7_software" } as unknown as Assessment));
    expect(doc["@type"]).toContain("schema:SoftwareSourceCode");
    expect(doc["@type"]).not.toContain("schema:Dataset");
  });
});
