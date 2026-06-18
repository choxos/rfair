import { describe, it, expect } from "vitest";
import { parseDoi, parseGithub } from "./harvest";

describe("parseDoi", () => {
  it("extracts a DOI", () => {
    expect(parseDoi("https://doi.org/10.5281/zenodo.8347772")).toBe("10.5281/zenodo.8347772");
  });
  it("does not throw on a bare % in the suffix (decodeURIComponent guard)", () => {
    expect(() => parseDoi("10.1234/ab%zz")).not.toThrow();
    expect(parseDoi("10.1234/ab%zz")).toBe("10.1234/ab%zz");
  });
  it("decodes percent-encoded characters when valid", () => {
    expect(parseDoi("10.1234/a%2Fb")).toBe("10.1234/a/b");
  });
  it("returns null when no DOI is present", () => {
    expect(parseDoi("https://github.com/owner/repo")).toBeNull();
  });
});

describe("parseGithub", () => {
  it("parses owner/repo and strips .git", () => {
    expect(parseGithub("https://github.com/owner/repo.git")).toEqual({ owner: "owner", repo: "repo" });
  });
  it("returns null for non-github", () => {
    expect(parseGithub("https://doi.org/10.5281/zenodo.1")).toBeNull();
  });
});
