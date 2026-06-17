import type { AssessmentOptions, Reference, SoftwareSignals } from "./types";

// In the browser we can only reach CORS-enabled registry APIs (DataCite,
// Crossref). Landing-page harvesting (embedded JSON-LD, RDF/XML) is blocked by
// CORS, so some metrics score lower here than in the R engine. See README.

export function parseDoi(input: string): string | null {
  const m = input.match(/(10\.\d{2,9}\/[^\s"'<>]+)/);
  return m ? decodeURIComponent(m[1]) : null;
}

export function parseGithub(input: string): { owner: string; repo: string } | null {
  const m = input.match(/github\.com\/([^/]+)\/([^/?#]+)/);
  return m ? { owner: m[1], repo: m[2].replace(/\.git$/, "") } : null;
}

async function harvestGithub(gh: { owner: string; repo: string }, out: Reference): Promise<string | null> {
  try {
    const r = await fetch(`https://api.github.com/repos/${gh.owner}/${gh.repo}`);
    if (!r.ok) return null;
    const j: any = await r.json();
    out.object_identifier = j.html_url;
    out.title = j.name;
    out.summary = j.description;
    out.object_type = "Software";
    if (j.topics?.length) out.keywords = j.topics;
    const spdx = j.license?.spdx_id;
    if (spdx && spdx !== "NOASSERTION") out.license = [spdx];
    out.publisher = j.owner?.login;
    out.created_date = j.created_at;
    out.modified_date = j.updated_at;
    out.language = j.language;
    return j.html_url;
  } catch {
    return null;
  }
}

function listText(arr: any, key: string): string[] {
  if (!Array.isArray(arr)) return [];
  return arr.map((e) => (e && typeof e === "object" ? e[key] : e)).filter((v) => typeof v === "string" && v);
}

function mapDatacite(a: any, doi: string, out: Reference) {
  out.object_identifier = a.doi ?? doi;
  out.object_type = a.types?.resourceTypeGeneral;
  const creators = listText(a.creators, "name");
  if (creators.length) out.creator = creators;
  if (a.titles?.[0]?.title) out.title = a.titles[0].title;
  const pub = a.publisher;
  out.publisher = typeof pub === "object" && pub ? pub.name : pub;
  const kw = listText(a.subjects, "subject");
  if (kw.length) out.keywords = kw;
  const avail = (a.dates ?? []).filter((d: any) => d.dateType === "Available").map((d: any) => d.date);
  out.publication_date = avail[0] ?? (a.publicationYear ? String(a.publicationYear) : undefined);
  const rights = (a.rightsList ?? []).map((r: any) => r.rightsUri || r.rights).filter(Boolean);
  if (rights.length) {
    out.license = rights;
    out.access_level = rights;
  }
  const abstract = (a.descriptions ?? []).find((d: any) => d.descriptionType === "Abstract");
  out.summary = abstract?.description ?? a.descriptions?.[0]?.description;
  const rel = (a.relatedIdentifiers ?? [])
    .filter((r: any) => r.relatedIdentifier)
    .map((r: any) => ({ related_resource: r.relatedIdentifier, relation_type: r.relationType }));
  if (rel.length) out.related_resources = rel;
  if (a.sizes?.length) out.object_size = a.sizes[0];
  if (a.formats?.length) out.object_format = a.formats[0];
  if (a.language) out.language = a.language;
  if (a.contentUrl?.length) out.object_content_identifier = a.contentUrl.map((u: string) => ({ url: u }));
  if (a.url) out.landing_url = a.url;
}

function mapCrossref(m: any, doi: string, out: Reference) {
  out.object_identifier = m.DOI ? `https://doi.org/${m.DOI}` : doi;
  out.object_type = m.type;
  if (m.title?.length) out.title = m.title[0];
  const creators = (m.author ?? []).map((a: any) => [a.family, a.given].filter(Boolean).join(", ")).filter(Boolean);
  if (creators.length) out.creator = creators;
  out.publisher = m.publisher;
  const dp = m.issued?.["date-parts"]?.[0] ?? m.created?.["date-parts"]?.[0];
  if (dp) out.publication_date = dp.join("-");
  if (m.subject?.length) out.keywords = m.subject;
  if (m.abstract) out.summary = m.abstract.replace(/<[^>]+>/g, "");
  const lic = (m.license ?? []).map((l: any) => l.URL).filter(Boolean);
  if (lic.length) out.license = lic;
  const links = (m.link ?? []).map((l: any) => ({ url: l.URL })).filter((l: any) => l.url);
  if (links.length) out.object_content_identifier = links;
}

function recordMetadataService(out: Reference, endpoint: string, type: AssessmentOptions["metadataServiceType"]) {
  out.metadata_service = [{ url: endpoint, type }];
}

export interface SoftwareHarvest {
  signals: SoftwareSignals;
  metadata: Reference;
  sources: { source: string; method: string }[];
  resolved: string | null;
}

const getJson = (u: string): Promise<any> =>
  fetch(u).then((r) => (r.ok ? r.json() : null)).catch(() => null);
const getText = (u: string): Promise<string> =>
  fetch(u).then((r) => (r.ok ? r.text() : "")).catch(() => "");

// Harvest the software signals the FRSM metrics need from a GitHub repository
// (ports collect_github.R::harvest_software_signals). GitHub's API is
// CORS-enabled, so this runs client-side.
export async function harvestSoftware(gh: { owner: string; repo: string }): Promise<SoftwareHarvest> {
  const api = `https://api.github.com/repos/${gh.owner}/${gh.repo}`;
  const j = await getJson(api);
  if (!j) throw new Error("Could not read that GitHub repository (check the URL, or GitHub's rate limit).");

  const branch = j.default_branch || "main";
  const sig: SoftwareSignals = {
    identifier: j.html_url, name: j.name, description: j.description ?? undefined,
    language: j.language ?? undefined, topics: j.topics ?? [], contributors: 0,
    has_license: !!(j.license && j.license.spdx_id && j.license.spdx_id !== "NOASSERTION"),
    has_readme: false, has_citation: false, has_tests: false, has_ci: false,
    has_requirements: false, has_docs: false, has_api: false,
  };

  const tree = await getJson(`${api}/git/trees/${branch}?recursive=1`);
  const paths: string[] = (tree?.tree ?? []).map((t: any) => String(t.path ?? "").toLowerCase());
  const any = (re: RegExp) => paths.some((p) => re.test(p));
  sig.has_license = sig.has_license || any(/^licen[sc]e/);
  sig.has_readme = any(/^readme/);
  sig.has_citation = any(/^citation\.cff|^codemeta\.json/);
  sig.has_tests = any(/(^|\/)tests?(\/|$)|(^|\/)test_|_test\.|\.test\./);
  sig.has_ci = any(/^\.github\/workflows\/|^\.travis|^\.circleci|^azure-pipelines|^\.gitlab-ci/);
  sig.has_requirements = any(/^(requirements.*\.txt|setup\.py|setup\.cfg|pyproject\.toml|package\.json|description|environment\.ya?ml|renv\.lock|cargo\.toml|go\.mod|pom\.xml|build\.gradle)$/);
  sig.has_docs = any(/^docs?\/|readthedocs|mkdocs\.ya?ml/);
  sig.has_api = any(/openapi|swagger|\.proto$|graphql/);

  const contrib = await getJson(`${api}/contributors?per_page=100`);
  sig.contributors = Array.isArray(contrib) ? contrib.length : 0;

  const rel = await getJson(`${api}/releases/latest`);
  sig.version = rel?.tag_name || undefined;

  if (sig.has_citation) {
    const base = `https://raw.githubusercontent.com/${gh.owner}/${gh.repo}/${branch}`;
    const txt = (await getText(`${base}/codemeta.json`)) + "\n" + (await getText(`${base}/CITATION.cff`));
    const dm = txt.match(/10\.\d{4,9}\/[^\s"'<>,)]+/);
    if (dm) sig.registry_doi = dm[0];
    if (!sig.version) {
      const vm = txt.match(/"?version"?\s*[:=]\s*"?v?(\d+\.\d+[^\s",}]*)/i);
      if (vm) sig.version = vm[1];
    }
  }

  const metadata: Reference = {
    object_identifier: j.html_url, title: j.name, summary: j.description ?? undefined,
    object_type: "Software", creator: j.owner?.login ? [j.owner.login] : undefined,
    publisher: j.owner?.login, access_level: ["public"],
  };
  if (j.topics?.length) metadata.keywords = j.topics;
  const spdx = j.license?.spdx_id;
  if (spdx && spdx !== "NOASSERTION") metadata.license = [spdx];
  if (sig.version) metadata.version = sig.version;
  if (sig.language) metadata.language = sig.language;
  if (sig.registry_doi) {
    metadata.related_resources = [{ related_resource: sig.registry_doi, relation_type: "IsSupplementTo" }];
  }

  return { signals: sig, metadata, sources: [{ source: "GitHub", method: "content_negotiation" }], resolved: j.html_url };
}

export interface Harvested {
  doi: string | null;
  metadata: Reference;
  sources: { source: string; method: string }[];
  resolved: string | null;
}

export async function harvest(input: string, options: AssessmentOptions): Promise<Harvested> {
  const doi = parseDoi(input);
  const metadata: Reference = {};
  const sources: { source: string; method: string }[] = [];
  let resolved: string | null = null;
  const serviceEndpoint = options.metadataServiceEndpoint.trim();
  if (serviceEndpoint) metadata.metadata_service_request = [{ url: serviceEndpoint, type: options.metadataServiceType }];

  const gh = parseGithub(input);
  if (gh) {
    resolved = await harvestGithub(gh, metadata);
    if (resolved) sources.push({ source: "GitHub", method: "content_negotiation" });
  }

  if (doi && options.useDatacite) {
    try {
      const r = await fetch(`https://api.datacite.org/dois/${encodeURIComponent(doi)}`);
      if (r.ok) {
        const a = (await r.json())?.data?.attributes ?? {};
        mapDatacite(a, doi, metadata);
        resolved = (metadata.landing_url as string) ?? null;
        sources.push({ source: "DataCite", method: "content_negotiation" });
      }
    } catch { /* network/CORS */ }
  }

  if (doi && !metadata.title) {
    try {
      const r = await fetch(`https://api.crossref.org/works/${encodeURIComponent(doi)}`);
      if (r.ok) {
        mapCrossref((await r.json())?.message ?? {}, doi, metadata);
        sources.push({ source: "Crossref", method: "content_negotiation" });
      }
    } catch { /* network/CORS */ }
  }

  if (serviceEndpoint && options.metadataServiceType === "dcat") {
    try {
      const r = await fetch(serviceEndpoint);
      if (r.ok) {
        recordMetadataService(metadata, serviceEndpoint, options.metadataServiceType);
        metadata.metadata_service_payload_type = r.headers.get("content-type") ?? "unknown";
        sources.push({ source: "DCAT", method: "metadata_service_fetch" });
      }
    } catch { /* network/CORS */ }
  }

  if (serviceEndpoint && options.metadataServiceType === "schema_org") {
    try {
      const r = await fetch(serviceEndpoint);
      if (r.ok) {
        const txt = await r.text();
        const m = txt.match(/<script[^>]+type=["']application\/ld\+json["'][^>]*>([\s\S]*?)<\/script>/i);
        if (m) {
          try {
            const j = JSON.parse(m[1]);
            recordMetadataService(metadata, serviceEndpoint, options.metadataServiceType);
            metadata.schema_org_type = Array.isArray(j) ? j.map((x: any) => x?.["@type"]).filter(Boolean) : j?.["@type"];
            sources.push({ source: "schema.org", method: "metadata_service_fetch" });
          } catch { /* invalid JSON-LD */ }
        }
      }
    } catch { /* network/CORS */ }
  }

  if (serviceEndpoint && options.metadataServiceType === "ckan") {
    try {
      const u = new URL(serviceEndpoint);
      const id = doi ?? input.trim();
      u.searchParams.set("id", id);
      const r = await fetch(u.toString());
      if (r.ok) {
        const j = await r.json();
        const rec = j?.result ?? j;
        recordMetadataService(metadata, serviceEndpoint, options.metadataServiceType);
        if (rec?.title && !metadata.title) metadata.title = rec.title;
        if (rec?.notes && !metadata.summary) metadata.summary = rec.notes;
        if (rec?.license_id && !metadata.license) metadata.license = [rec.license_id];
        sources.push({ source: "CKAN", method: "metadata_service_fetch" });
      }
    } catch { /* network/CORS */ }
  }
  delete metadata.landing_url;
  return { doi, metadata, sources, resolved };
}
