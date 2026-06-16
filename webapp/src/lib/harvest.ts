import type { Reference } from "./types";

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

export interface Harvested {
  doi: string | null;
  metadata: Reference;
  sources: { source: string; method: string }[];
  resolved: string | null;
}

export async function harvest(input: string): Promise<Harvested> {
  const doi = parseDoi(input);
  const metadata: Reference = {};
  const sources: { source: string; method: string }[] = [];
  let resolved: string | null = null;

  const gh = parseGithub(input);
  if (gh) {
    resolved = await harvestGithub(gh, metadata);
    if (resolved) sources.push({ source: "GitHub", method: "content_negotiation" });
  }

  if (doi) {
    try {
      const r = await fetch(`https://api.datacite.org/dois/${encodeURIComponent(doi)}`);
      if (r.ok) {
        const a = (await r.json())?.data?.attributes ?? {};
        mapDatacite(a, doi, metadata);
        resolved = (metadata.landing_url as string) ?? null;
        sources.push({ source: "DataCite", method: "content_negotiation" });
      }
    } catch { /* network/CORS */ }

    if (!metadata.title) {
      try {
        const r = await fetch(`https://api.crossref.org/works/${encodeURIComponent(doi)}`);
        if (r.ok) {
          mapCrossref((await r.json())?.message ?? {}, doi, metadata);
          sources.push({ source: "Crossref", method: "content_negotiation" });
        }
      } catch { /* network/CORS */ }
    }
  }
  delete metadata.landing_url;
  return { doi, metadata, sources, resolved };
}
