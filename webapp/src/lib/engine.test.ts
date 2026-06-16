import { describe, it, expect } from "vitest";
import { licenseReuse, fairTlc, identifierHygiene } from "./reuse";
import { parseDoi, parseGithub } from "./harvest";
import type { RefData } from "./types";

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
