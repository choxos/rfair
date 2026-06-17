import { describe, it, expect } from "vitest";
import { assess } from "./engine";
import { licenseReuse, fairTlc, identifierHygiene } from "./reuse";
import { harvest, harvestSoftware, parseDoi, parseGithub } from "./harvest";
import { METADATA_SERVICE_TYPES } from "./types";
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
  it("classifies canonical SPDX license URLs", () => {
    const r = licenseReuse("https://spdx.org/licenses/MIT.html", data);
    expect(r.is_open).toBe(true);
    expect(r.rdp_category).toBe("permissive");
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
      text: async () => JSON.stringify({ "@type": "Dataset", name: "DCAT dataset" }),
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

  it("validates every exposed metadata service option after a successful fetch", async () => {
    const originalFetch = globalThis.fetch;
    const response = ({
      contentType = "application/json",
      json = {},
      link = null as string | null,
      text = JSON.stringify(json),
    } = {}) => ({
      ok: true,
      status: 200,
      headers: { get: (name: string) => name.toLowerCase() === "content-type" ? contentType : name.toLowerCase() === "link" ? link : null },
      json: async () => json,
      text: async () => text,
    } as unknown as Response);

    globalThis.fetch = (async (url: string | URL | Request) => {
      const href = String(url);
      if (href.includes("dcat")) return response({ json: { "@type": "Dataset", name: "DCAT dataset" } });
      if (href.includes("schema_org")) return response({
        contentType: "application/ld+json",
        json: { "@type": "Dataset", name: "schema dataset" },
      });
      if (href.includes("datacite")) return response({
        json: { data: { attributes: { doi: "10.1234/example", titles: [{ title: "DataCite dataset" }] } } },
      });
      if (href.includes("crossref")) return response({
        json: { message: { DOI: "10.1234/example", title: ["Crossref dataset"] } },
      });
      if (href.includes("oai_pmh")) return response({
        contentType: "application/xml",
        text: "<record><metadata><oai_dc:dc><dc:title>OAI dataset</dc:title></oai_dc:dc></metadata></record>",
      });
      if (href.includes("ogc_csw")) return response({
        contentType: "application/xml",
        text: "<Capabilities><ServiceIdentification><Title>CSW catalog</Title></ServiceIdentification></Capabilities>",
      });
      if (href.includes("sparql")) return response({
        contentType: "application/sparql-results+json",
        json: { boolean: true },
      });
      if (href.includes("signposting")) return response({ link: '<https://example.org/file.csv>; rel="item"' });
      if (href.includes("typed_links")) return response({ link: '<https://example.org/metadata.json>; rel="describedby"' });
      if (href.includes("ro_crate")) return response({
        json: { "@graph": [{ "@id": "./", "@type": "Dataset", name: "RO-Crate dataset" }] },
      });
      if (href.includes("ckan")) return response({
        json: { result: { title: "CKAN dataset", name: "ckan-dataset" } },
      });
      return response({
        contentType: "application/xml",
        text: "<metadata><title>Generic metadata</title></metadata>",
      });
    }) as typeof fetch;

    try {
      for (const { value } of METADATA_SERVICE_TYPES) {
        const h = await harvest("https://doi.org/10.1234/example", {
          useDatacite: false,
          metadataServiceEndpoint: `https://example.org/${value}`,
          metadataServiceType: value,
        });
        expect(h.metadata.metadata_service).toEqual([{ url: `https://example.org/${value}`, type: value }]);
        expect(h.sources.some((s) => s.method === "metadata_service_fetch")).toBe(true);
      }
    } finally {
      globalThis.fetch = originalFetch;
    }
  });

  it("does not score malformed metadata service responses", async () => {
    const originalFetch = globalThis.fetch;
    globalThis.fetch = (async (url: string | URL | Request) => {
      const href = String(url);
      const text = href.includes("verb=GetRecord")
        ? "<OAI-PMH><error code=\"idDoesNotExist\">missing</error></OAI-PMH>"
        : "<html>not a metadata service</html>";
      return {
        ok: true,
        status: 200,
        headers: { get: () => "text/html" },
        json: async () => ({}),
        text: async () => text,
      } as unknown as Response;
    }) as typeof fetch;

    try {
      for (const { value } of METADATA_SERVICE_TYPES) {
        const h = await harvest("https://doi.org/10.1234/example", {
          useDatacite: false,
          metadataServiceEndpoint: `https://example.org/${value}`,
          metadataServiceType: value,
        });
        expect(h.metadata.metadata_service).toBeUndefined();
        expect(h.sources.some((s) => s.method === "metadata_service_fetch")).toBe(false);
        expect(h.metadata.metadata_service_request).toEqual([{ url: `https://example.org/${value}`, type: value }]);
      }
    } finally {
      globalThis.fetch = originalFetch;
    }
  });

  it("scores metric-level legacy metric sets without per-test definitions", async () => {
    const originalFetch = globalThis.fetch;
    globalThis.fetch = (async () => ({
      ok: true,
      headers: { get: () => "application/json" },
      json: async () => ({
        data: {
          attributes: {
            doi: "10.1234/example",
            types: { resourceTypeGeneral: "Dataset" },
            creators: [{ name: "Ada Lovelace" }],
            titles: [{ title: "Legacy dataset" }],
            publisher: "Example Repository",
            publicationYear: 2026,
            descriptions: [{ descriptionType: "Abstract", description: "A dataset." }],
            subjects: [{ subject: "legacy" }],
          },
        },
      }),
      text: async () => "",
    } as unknown as Response)) as typeof fetch;

    try {
      const ref = {
        ...data,
        metrics: { metrics: [] },
        metricSets: {
          "0.3": {
            metrics: [
              { metric_identifier: "FsF-F1-01D", metric_number: 1, metric_name: "Unique identifier", total_score: 1 },
              { metric_identifier: "FsF-F2-01M", metric_number: 2, metric_name: "Core metadata", total_score: 2 },
            ],
          },
        },
        formats: { science: [], long_term: [], open: [] },
        access: [],
        protocols: {},
      } as unknown as RefData;

      const result = await assess("https://doi.org/10.1234/example", ref, "0.3");
      expect(result.results.find((r) => r.metric_identifier === "FsF-F1-01D")?.earned).toBe(1);
      expect(result.results.find((r) => r.metric_identifier === "FsF-F2-01M")?.earned).toBe(2);
      expect(result.summary.find((s) => s.category === "FAIR")?.earned).toBe(3);
    } finally {
      globalThis.fetch = originalFetch;
    }
  });
});

describe("software assessment", () => {
  it("does not treat upstream CodeMeta DOIs as the software DOI", async () => {
    const originalFetch = globalThis.fetch;
    globalThis.fetch = (async (url: string | URL | Request) => {
      const href = String(url);
      if (href.includes("/git/trees/")) {
        return { ok: true, json: async () => ({ tree: [{ path: "codemeta.json" }, { path: "CITATION.cff" }] }), text: async () => "" } as Response;
      }
      if (href.includes("/contributors")) {
        return { ok: true, json: async () => [{ login: "a" }], text: async () => "" } as Response;
      }
      if (href.includes("/releases/latest")) {
        return { ok: true, json: async () => ({ tag_name: "v1.2.3" }), text: async () => "" } as Response;
      }
      if (href.endsWith("/codemeta.json")) {
        return {
          ok: true,
          json: async () => ({}),
          text: async () => JSON.stringify({
            identifier: "https://github.com/owner/repo",
            isBasedOn: ["https://doi.org/10.5281/zenodo.3775793"],
            license: "https://spdx.org/licenses/MIT.html",
            version: "1.2.3",
          }),
        } as Response;
      }
      if (href.endsWith("/CITATION.cff")) {
        return {
          ok: true,
          json: async () => ({}),
          text: async () => "cff-version: 1.2.0\nversion: 1.2.3\n",
        } as Response;
      }
      return {
        ok: true,
        json: async () => ({
          html_url: "https://github.com/owner/repo",
          name: "repo",
          description: "demo package",
          topics: [],
          license: { spdx_id: "NOASSERTION" },
          owner: { login: "owner" },
          created_at: "2026-01-01T00:00:00Z",
          updated_at: "2026-01-02T00:00:00Z",
          language: "TypeScript",
          default_branch: "main",
        }),
        text: async () => "",
      } as Response;
    }) as typeof fetch;

    try {
      const h = await harvestSoftware({ owner: "owner", repo: "repo" });
      expect(h.signals.registry_doi).toBeUndefined();
      expect(h.metadata.related_resources).toBeUndefined();
      expect(h.metadata.license).toEqual(["https://spdx.org/licenses/MIT.html"]);
    } finally {
      globalThis.fetch = originalFetch;
    }
  });

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
