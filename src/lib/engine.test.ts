import { describe, it, expect } from "vitest";
import { assess } from "./engine";
import { licenseReuse, fairTlc, identifierHygiene } from "./reuse";
import { harvest, parseDoi, parseGithub } from "./harvest";
import type { AssessmentOptions, RefData } from "./types";

// CC / software licenses resolve via regex, so an empty license table suffices.
const data = { licenses: [] } as unknown as RefData;

describe("licenseReuse + RDP taxonomy", () => {
  it("classifies CC-BY as open / permissive", () => {
    const r = licenseReuse("https://creativecommons.org/licenses/by/4.0/", data);
    expect(r.is_open).toBe(true);
    expect(r.rdp_category).toBe("permissive");
    expect(r.facilitates_reuse).toBe(true);
  });
  it("classifies CC-BY-NC-ND as restrictive (present but not open)", () => {
    const r = licenseReuse("https://creativecommons.org/licenses/by-nc-nd/4.0/", data);
    expect(r.is_open).toBe(false);
    expect(r.rdp_category).toBe("restrictive");
  });
  it("classifies CC-BY-SA as copyleft", () => {
    expect(licenseReuse("https://creativecommons.org/licenses/by-sa/4.0/", data).rdp_category).toBe("copyleft");
  });
});

describe("identifierHygiene", () => {
  it("flags layered identifiers", () => {
    expect(identifierHygiene("RRID:MGI:5577054").hygiene_ok).toBe(false);
  });
  it("accepts a DOI", () => {
    expect(identifierHygiene("https://doi.org/10.5281/zenodo.8347772").hygiene_ok).toBe(true);
  });
});

describe("fairTlc", () => {
  it("returns five Traceable/Licensed/Connected indicators", () => {
    const rows = fairTlc({ creator: ["x"], publisher: "p", created_date: "2020", related_resources: [{}] },
                         [licenseReuse("CC-BY-4.0", data)], true);
    expect(rows).toHaveLength(5);
    expect(rows.filter((r) => r.met).length).toBeGreaterThan(0);
  });
});

describe("parsers", () => {
  it("parseDoi", () => expect(parseDoi("https://doi.org/10.5281/zenodo.1")).toBe("10.5281/zenodo.1"));
  it("parseGithub", () => expect(parseGithub("https://github.com/owner/repo")?.repo).toBe("repo"));
});

describe("metadata service options", () => {
  const baseOptions: AssessmentOptions = {
    useDatacite: false,
    metadataServiceEndpoint: "https://example.org/oai",
    metadataServiceType: "oai_pmh",
  };

  it("records unharvested service requests without scoring sources", async () => {
    const originalFetch = globalThis.fetch;
    globalThis.fetch = (async () => ({
      ok: false,
      status: 404,
      headers: { get: () => null },
      json: async () => ({}),
      text: async () => "",
    } as unknown as Response)) as typeof fetch;

    try {
      const h = await harvest("https://example.org/dataset", baseOptions);
      expect(h.sources).toEqual([]);
      expect(h.metadata.metadata_service).toBeUndefined();
      expect(h.metadata.metadata_service_request).toEqual([{ url: "https://example.org/oai", type: "oai_pmh" }]);
    } finally {
      globalThis.fetch = originalFetch;
    }
  });

  it("records metadata service only after a successful supported fetch", async () => {
    const originalFetch = globalThis.fetch;
    globalThis.fetch = (async () => ({
      ok: true,
      headers: { get: () => "application/ld+json" },
      json: async () => ({}),
      text: async () => "",
    } as unknown as Response)) as typeof fetch;

    try {
      const h = await harvest("https://example.org/dataset", {
        ...baseOptions,
        metadataServiceEndpoint: "https://example.org/catalog.jsonld",
        metadataServiceType: "dcat",
      });
      expect(h.sources).toEqual([{ source: "DCAT", method: "metadata_service_fetch" }]);
      expect(h.metadata.metadata_service).toEqual([{ url: "https://example.org/catalog.jsonld", type: "dcat" }]);
    } finally {
      globalThis.fetch = originalFetch;
    }
  });
});

describe("software assessment", () => {
  it("scores FRSM metrics from harvested GitHub signals", async () => {
    const originalFetch = globalThis.fetch;
    globalThis.fetch = (async (url: string | URL | Request) => {
      const href = String(url);
      const json = href.includes("/git/trees/")
        ? { tree: [
            { path: "README.md" },
            { path: "LICENSE" },
            { path: "package.json" },
            { path: "tests/engine.test.ts" },
            { path: ".github/workflows/ci.yml" },
            { path: "CITATION.cff" },
          ] }
        : href.includes("/contributors")
          ? [{ login: "a" }, { login: "b" }]
          : href.includes("/releases/latest")
            ? { tag_name: "v1.2.3" }
            : {
                html_url: "https://github.com/owner/repo",
                name: "repo",
                description: "demo package",
                topics: ["fair"],
                license: { spdx_id: "MIT" },
                owner: { login: "owner" },
                created_at: "2026-01-01T00:00:00Z",
                updated_at: "2026-01-02T00:00:00Z",
                language: "TypeScript",
                default_branch: "main",
              };
      const text = "doi: 10.5281/zenodo.12345\nversion: 1.2.3\n";
      return { ok: true, json: async () => json, text: async () => text } as Response;
    }) as typeof fetch;

    try {
      const ref = {
        ...data,
        metrics: { metrics: [] },
        softwareMetrics: {
          metrics: [
            {
              metric_identifier: "FRSM-01-F1",
              metric_number: 1,
              metric_name: "Software identifier",
              total_score: 3,
              metric_tests: [
                { metric_test_identifier: "FRSM-01-F1-1", metric_test_name: "identifier", metric_test_score: 1, metric_test_maturity: 1 },
                { metric_test_identifier: "FRSM-01-F1-2", metric_test_name: "persistent", metric_test_score: 1, metric_test_maturity: 2 },
                { metric_test_identifier: "FRSM-01-F1-3", metric_test_name: "domain", metric_test_score: 1, metric_test_maturity: 3 },
              ],
            },
            {
              metric_identifier: "FRSM-04-F2",
              metric_number: 4,
              metric_name: "Descriptive metadata",
              total_score: 3,
              metric_tests: [
                { metric_test_identifier: "FRSM-04-F2-1", metric_test_name: "name", metric_test_score: 1, metric_test_maturity: 1 },
                { metric_test_identifier: "FRSM-04-F2-2", metric_test_name: "readme", metric_test_score: 1, metric_test_maturity: 2 },
                { metric_test_identifier: "FRSM-04-F2-3", metric_test_name: "citation", metric_test_score: 1, metric_test_maturity: 3 },
              ],
            },
            {
              metric_identifier: "FRSM-15-R1.1",
              metric_number: 15,
              metric_name: "Source license",
              total_score: 1,
              metric_tests: [
                { metric_test_identifier: "FRSM-15-R1.1-1", metric_test_name: "license", metric_test_score: 1, metric_test_maturity: 2 },
              ],
            },
          ],
        },
        formats: { science: [], long_term: [], open: [] },
        access: [],
        protocols: {},
      } as unknown as RefData;

      const result = await assess("https://github.com/owner/repo", ref, "0.7_software");
      expect(result.metric_version).toBe("0.7_software");
      expect(result.results.map((r) => r.metric_identifier)).toEqual(["FRSM-01-F1", "FRSM-04-F2", "FRSM-15-R1.1"]);
      expect(result.results.find((r) => r.metric_identifier === "FRSM-01-F1")?.earned).toBe(3);
      expect(result.results.find((r) => r.metric_identifier === "FRSM-15-R1.1")?.earned).toBe(1);
      expect(result.summary.find((s) => s.category === "FAIR")?.earned).toBe(7);
    } finally {
      globalThis.fetch = originalFetch;
    }
  });
});
