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

function addServiceSource(sources: { source: string; method: string }[], source: string) {
  if (!sources.some((s) => s.source === source && s.method === "metadata_service_fetch")) {
    sources.push({ source, method: "metadata_service_fetch" });
  }
}

function setIfMissing(out: Reference, key: string, value: unknown) {
  if (value == null) return;
  if (Array.isArray(value) && value.length === 0) return;
  if (out[key] == null) out[key] = value;
}

function asArray(v: any): any[] {
  return Array.isArray(v) ? v : v == null ? [] : [v];
}

function literal(v: any): string | undefined {
  if (typeof v === "string" && v.trim()) return v.trim();
  if (v && typeof v === "object") return literal(v.name ?? v["@value"] ?? v.value);
  return undefined;
}

function literals(v: any): string[] {
  return asArray(v).map(literal).filter((x): x is string => !!x);
}

function normalizeDoi(value: unknown): string | undefined {
  if (typeof value !== "string") return undefined;
  const m = value.match(/(?:doi:\s*|https?:\/\/(?:dx\.)?doi\.org\/)?(10\.\d{4,9}\/[^\s"'<>,)]+)/i);
  return m?.[1];
}

function codemetaSoftwareDoi(text: string): string | undefined {
  if (!text.trim()) return undefined;
  try {
    const cm = JSON.parse(text);
    const candidates = [
      cm.doi,
      cm.identifier,
      cm["@id"],
      cm.sameAs,
    ].flatMap(asArray);
    for (const value of candidates) {
      const doi = normalizeDoi(literal(value) ?? value);
      if (doi) return doi;
    }
  } catch {
    return undefined;
  }
  return undefined;
}

function codemetaLicenses(text: string): string[] {
  if (!text.trim()) return [];
  try {
    const cm = JSON.parse(text);
    return asArray(cm.license)
      .map((value) => literal(value) ?? literal(value?.["@id"]) ?? literal(value?.url))
      .filter((value): value is string => !!value);
  } catch {
    return [];
  }
}

function citationSoftwareDoi(text: string): string | undefined {
  const m = text.match(/^\s*doi\s*:\s*["']?([^"'\n#]+)["']?/im);
  return normalizeDoi(m?.[1]);
}

function tryJson(text: string): any | null {
  try { return JSON.parse(text); } catch { return null; }
}

function stripXml(s: string): string {
  return s.replace(/<[^>]+>/g, " ").replace(/\s+/g, " ").trim();
}

function xmlValues(xml: string, localName: string): string[] {
  const re = new RegExp(`<(?:[\\w.-]+:)?${localName}\\b[^>]*>([\\s\\S]*?)<\\/(?:[\\w.-]+:)?${localName}>`, "gi");
  return [...xml.matchAll(re)].map((m) => stripXml(m[1])).filter(Boolean);
}

function hasXmlElement(xml: string, localName: string): boolean {
  return new RegExp(`<(?:[\\w.-]+:)?${localName}\\b`, "i").test(xml);
}

function endpointWithParams(endpoint: string, params: Record<string, string>): string {
  const u = new URL(endpoint);
  for (const [k, v] of Object.entries(params)) u.searchParams.set(k, v);
  return u.toString();
}

function findJsonLdNode(j: any): any {
  const nodes = Array.isArray(j) ? j : asArray(j?.["@graph"] ?? j);
  return nodes.find((n) => {
    const types = literals(n?.["@type"]).map((t) => t.toLowerCase());
    return types.some((t) => /dataset|creativework|software|datacatalog|distribution/.test(t));
  }) ?? nodes[0] ?? j;
}

function hasJsonLdMetadata(j: any): boolean {
  const node = findJsonLdNode(j);
  return !!(node && typeof node === "object" &&
    (node["@type"] || node["@graph"] || node.name || node.headline || node.description || node.contentUrl || node.distribution));
}

function applyJsonLd(j: any, out: Reference) {
  const node = findJsonLdNode(j);
  setIfMissing(out, "object_type", literal(node?.["@type"]) ?? "Dataset");
  setIfMissing(out, "title", literal(node?.name ?? node?.headline));
  setIfMissing(out, "summary", literal(node?.description));
  const kw = Array.isArray(node?.keywords) ? literals(node.keywords) :
    typeof node?.keywords === "string" ? node.keywords.split(",").map((s: string) => s.trim()).filter(Boolean) : [];
  setIfMissing(out, "keywords", kw);
  setIfMissing(out, "license", literals(node?.license));
  setIfMissing(out, "publication_date", literal(node?.datePublished ?? node?.dateCreated));
  setIfMissing(out, "creator", literals(node?.creator ?? node?.author));
  setIfMissing(out, "publisher", literal(node?.publisher));
  const content = literals(node?.contentUrl ?? node?.distribution?.contentUrl)
    .map((url) => ({ url }));
  setIfMissing(out, "object_content_identifier", content);
}

function applyDublinCoreXml(xml: string, out: Reference) {
  setIfMissing(out, "title", xmlValues(xml, "title")[0]);
  setIfMissing(out, "creator", xmlValues(xml, "creator"));
  setIfMissing(out, "publisher", xmlValues(xml, "publisher")[0]);
  setIfMissing(out, "publication_date", xmlValues(xml, "date")[0]);
  setIfMissing(out, "keywords", xmlValues(xml, "subject"));
  setIfMissing(out, "summary", xmlValues(xml, "description")[0]);
  const ids = xmlValues(xml, "identifier").filter((u) => /^https?:|^doi:|^10\./i.test(u));
  setIfMissing(out, "object_content_identifier", ids.map((url) => ({ url })));
  setIfMissing(out, "license", xmlValues(xml, "rights"));
}

function looksLikeMetadataXml(xml: string): boolean {
  return !hasXmlElement(xml, "html") &&
    (hasXmlElement(xml, "metadata") || hasXmlElement(xml, "dc") || hasXmlElement(xml, "record") || hasXmlElement(xml, "rdf"));
}

function applyLinkHeader(link: string | null, out: Reference): boolean {
  if (!link) return false;
  const links = [...link.matchAll(/<([^>]+)>;\s*rel="?([^",;]+)"?/gi)]
    .map((m) => ({ url: m[1], rel: m[2].toLowerCase() }));
  if (!links.length) return false;
  const items = links.filter((l) => /item|describedby|cite-as/.test(l.rel));
  setIfMissing(out, "object_content_identifier", items.filter((l) => l.rel === "item").map((l) => ({ url: l.url })));
  setIfMissing(out, "related_resources", links.filter((l) => l.rel !== "item")
    .map((l) => ({ related_resource: l.url, relation_type: l.rel })));
  return items.length > 0;
}

async function validateOaiService(endpoint: string, identifier: string, out: Reference): Promise<boolean> {
  const r = await fetch(endpointWithParams(endpoint, {
    verb: "GetRecord",
    metadataPrefix: "oai_dc",
    identifier,
  }));
  const record = r.ok ? await r.text() : null;
  if (record && !hasXmlElement(record, "error") && (hasXmlElement(record, "record") || hasXmlElement(record, "dc"))) {
    applyDublinCoreXml(record, out);
    return true;
  }
  return false;
}

function hasSparqlResult(j: any): boolean {
  return typeof j?.boolean === "boolean" || Array.isArray(j?.results?.bindings);
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
  let metadataLicenses: string[] = [];

  if (sig.has_citation) {
    const base = `https://raw.githubusercontent.com/${gh.owner}/${gh.repo}/${branch}`;
    const codemeta = await getText(`${base}/codemeta.json`);
    const citation = await getText(`${base}/CITATION.cff`);
    const txt = `${codemeta}\n${citation}`;
    sig.registry_doi = codemetaSoftwareDoi(codemeta) ?? citationSoftwareDoi(citation);
    metadataLicenses = codemetaLicenses(codemeta);
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
  if (!metadata.license && metadataLicenses.length) metadata.license = metadataLicenses;
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
        const txt = await r.text();
        const j = tryJson(txt);
        if (j && hasJsonLdMetadata(j)) {
          applyJsonLd(j, metadata);
          recordMetadataService(metadata, serviceEndpoint, options.metadataServiceType);
          metadata.metadata_service_payload_type = r.headers.get("content-type") ?? "unknown";
          addServiceSource(sources, "DCAT");
        }
      }
    } catch { /* network/CORS */ }
  }

  if (serviceEndpoint && options.metadataServiceType === "schema_org") {
    try {
      const r = await fetch(serviceEndpoint);
      if (r.ok) {
        const txt = await r.text();
        const raw = /json|ld\+json/i.test(r.headers.get("content-type") ?? "") ? tryJson(txt) : null;
        const scripts = raw ? [raw] : [...txt.matchAll(/<script[^>]+type=["']application\/ld\+json["'][^>]*>([\s\S]*?)<\/script>/gi)]
          .map((m) => tryJson(m[1]))
          .filter((j) => j && hasJsonLdMetadata(j));
        if (scripts.length) {
          try {
            const j = scripts.length === 1 ? scripts[0] : scripts;
            applyJsonLd(j, metadata);
            recordMetadataService(metadata, serviceEndpoint, options.metadataServiceType);
            metadata.schema_org_type = Array.isArray(j) ? j.map((x: any) => x?.["@type"]).filter(Boolean) : j?.["@type"];
            addServiceSource(sources, "schema.org");
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
        if (rec && typeof rec === "object" && (rec.title || rec.name || rec.id)) {
          recordMetadataService(metadata, serviceEndpoint, options.metadataServiceType);
          if (rec?.title && !metadata.title) metadata.title = rec.title;
          if (rec?.notes && !metadata.summary) metadata.summary = rec.notes;
          if (rec?.license_id && !metadata.license) metadata.license = [rec.license_id];
          addServiceSource(sources, "CKAN");
        }
      }
    } catch { /* network/CORS */ }
  }

  if (serviceEndpoint && options.metadataServiceType === "datacite") {
    try {
      const r = await fetch(serviceEndpoint);
      if (r.ok) {
        const j = await r.json();
        const a = j?.data?.attributes;
        if (a && typeof a === "object") {
          mapDatacite(a, doi ?? input.trim(), metadata);
          recordMetadataService(metadata, serviceEndpoint, options.metadataServiceType);
          addServiceSource(sources, "DataCite");
        }
      }
    } catch { /* network/CORS */ }
  }

  if (serviceEndpoint && options.metadataServiceType === "crossref") {
    try {
      const r = await fetch(serviceEndpoint);
      if (r.ok) {
        const m = (await r.json())?.message;
        if (m && typeof m === "object") {
          mapCrossref(m, doi ?? input.trim(), metadata);
          recordMetadataService(metadata, serviceEndpoint, options.metadataServiceType);
          addServiceSource(sources, "Crossref");
        }
      }
    } catch { /* network/CORS */ }
  }

  if (serviceEndpoint && options.metadataServiceType === "oai_pmh") {
    try {
      if (await validateOaiService(serviceEndpoint, input.trim(), metadata)) {
        recordMetadataService(metadata, serviceEndpoint, options.metadataServiceType);
        addServiceSource(sources, "OAI-PMH");
      }
    } catch { /* network/CORS */ }
  }

  if (serviceEndpoint && options.metadataServiceType === "ogc_csw") {
    try {
      const r = await fetch(endpointWithParams(serviceEndpoint, { service: "CSW", request: "GetCapabilities" }));
      if (r.ok) {
        const txt = await r.text();
        if (hasXmlElement(txt, "Capabilities") || hasXmlElement(txt, "ServiceIdentification")) {
          setIfMissing(metadata, "title", xmlValues(txt, "Title")[0]);
          recordMetadataService(metadata, serviceEndpoint, options.metadataServiceType);
          addServiceSource(sources, "OGC CSW");
        }
      }
    } catch { /* network/CORS */ }
  }

  if (serviceEndpoint && options.metadataServiceType === "sparql") {
    try {
      const r = await fetch(endpointWithParams(serviceEndpoint, {
        query: "ASK { ?s ?p ?o }",
        format: "application/sparql-results+json",
      }));
      if (r.ok) {
        const j = await r.json();
        if (hasSparqlResult(j)) {
          metadata.metadata_service_payload_type = r.headers.get("content-type") ?? "unknown";
          recordMetadataService(metadata, serviceEndpoint, options.metadataServiceType);
          addServiceSource(sources, "SPARQL");
        }
      }
    } catch { /* network/CORS */ }
  }

  if (serviceEndpoint && (options.metadataServiceType === "signposting" || options.metadataServiceType === "typed_links")) {
    try {
      let r = await fetch(serviceEndpoint, { method: "HEAD" });
      if (!r.ok || !r.headers.get("link")) r = await fetch(serviceEndpoint);
      if (r.ok && r.headers.get("link")) {
        if (applyLinkHeader(r.headers.get("link"), metadata)) {
          recordMetadataService(metadata, serviceEndpoint, options.metadataServiceType);
          addServiceSource(sources, options.metadataServiceType === "signposting" ? "Signposting" : "Typed links");
        }
      }
    } catch { /* network/CORS */ }
  }

  if (serviceEndpoint && options.metadataServiceType === "ro_crate") {
    try {
      const r = await fetch(serviceEndpoint);
      if (r.ok) {
        const j = await r.json();
        if (j?.["@graph"]) {
          applyJsonLd(j, metadata);
          recordMetadataService(metadata, serviceEndpoint, options.metadataServiceType);
          addServiceSource(sources, "RO-Crate");
        }
      }
    } catch { /* network/CORS */ }
  }

  if (serviceEndpoint && options.metadataServiceType === "other") {
    try {
      const r = await fetch(serviceEndpoint);
      if (r.ok) {
        const txt = await r.text();
        const j = tryJson(txt);
        const jsonLike = j && hasJsonLdMetadata(j);
        const xmlLike = looksLikeMetadataXml(txt);
        if (jsonLike) applyJsonLd(j, metadata);
        else if (xmlLike) applyDublinCoreXml(txt, metadata);
        if (jsonLike || xmlLike) {
          recordMetadataService(metadata, serviceEndpoint, options.metadataServiceType);
          metadata.metadata_service_payload_type = r.headers.get("content-type") ?? "unknown";
          addServiceSource(sources, "Metadata service");
        }
      }
    } catch { /* network/CORS */ }
  }
  delete metadata.landing_url;
  return { doi, metadata, sources, resolved };
}
