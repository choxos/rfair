import { describe, it, expect } from "vitest";
import { identifierHygiene } from "./reuse";

describe("identifierHygiene", () => {
  const cases: [string, string | null, boolean][] = [
    ["https://doi.org/10.5281/zenodo.1", "doi", true],
    ["10.5061/dryad.x", "doi", true],
    ["https://hdl.handle.net/2027/x", "handle", true],
    ["ark:/12345/x", "ark", true],
    ["urn:nbn:de:1234", "urn", true],
    ["https://identifiers.org/geo:GSE1", "pid", true],
    ["geo:GSE12345", "geo", true],
    ["bioproject:PRJEB123", "bioproject", true],
    ["https://example.org/dataset/1", "url", false],
  ];
  for (const [id, scheme, persistent] of cases) {
    it(`classifies ${id}`, () => {
      const h = identifierHygiene(id);
      expect(h.scheme).toBe(scheme);
      expect(h.is_persistent).toBe(persistent);
    });
  }

  it("persistent identifiers report no scheme issue", () => {
    const h = identifierHygiene("ark:/12345/x");
    expect(h.issues.some((i) => /not.*recognized/i.test(i))).toBe(false);
    expect(h.is_persistent).toBe(true);
  });

  it("flags an unrecognized plain URL as non-persistent", () => {
    expect(identifierHygiene("https://example.org/x").hygiene_ok).toBe(false);
  });
});
