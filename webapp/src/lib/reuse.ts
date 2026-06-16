import type { RefData, LicenseReuse, AccessInfo, HygieneInfo, TlcRow, Reference } from "./types";

const CC_RE = /creativecommons\.org\/licenses\/(by(?:-nc)?(?:-nd)?(?:-sa)?)\/([0-9.]+)/i;

function resolveLicenseId(license: string, data: RefData): string | null {
  if (/^https?:/i.test(license)) {
    if (/creativecommons\.org\/publicdomain\//i.test(license)) return "CC0-1.0";
    const m = license.match(CC_RE);
    if (m) return `CC-${m[1]}-${m[2]}`.toUpperCase();
    const hit = data.licenses.find((l) => (l.seeAlso ?? []).includes(license));
    return hit?.licenseId ?? null;
  }
  return /^[A-Za-z0-9.+-]+$/.test(license) ? license : null;
}

export function licenseReuse(license: string, data: RefData): LicenseReuse {
  const out: LicenseReuse = {
    license, category: "custom/unknown", rdp_category: "unknown", facilitates_reuse: false,
    is_open: false, permits_commercial: false, permits_derivatives: false, share_alike: false,
    note: "License could not be classified; manual review needed.",
  };
  const id = resolveLicenseId(license, data);
  if (!id) return out;
  const u = id.toUpperCase();
  if (/^CC0|^PDDL|PUBLICDOMAIN|^ZERO/.test(u)) {
    Object.assign(out, { category: "open (public domain)", is_open: true, permits_commercial: true, permits_derivatives: true, note: "Public-domain dedication: open for any reuse." });
  } else if (/^CC-BY/.test(u)) {
    const nc = /NC/.test(u), nd = /ND/.test(u), sa = /SA/.test(u);
    out.permits_commercial = !nc; out.permits_derivatives = !nd; out.is_open = !nc && !nd; out.share_alike = sa;
    out.category = out.is_open ? (sa ? "open (share-alike)" : "open (attribution)")
      : nc && nd ? "restrictive (non-commercial, no-derivatives)" : nc ? "restrictive (non-commercial)" : "restrictive (no-derivatives)";
    out.note = out.is_open ? "Meets the Open Definition." : "License present but NOT open for reuse (commercial use or derivatives restricted).";
  } else if (/^ODBL/.test(u)) {
    Object.assign(out, { category: "open (data)", is_open: true, permits_commercial: true, permits_derivatives: true, share_alike: true, note: "Open data license (share-alike)." });
  } else if (/^ODC-BY/.test(u)) {
    Object.assign(out, { category: "open (data)", is_open: true, permits_commercial: true, permits_derivatives: true, note: "Open data license (attribution)." });
  } else if (/^(GPL|LGPL|AGPL|EPL|EUPL|MPL)/.test(u)) {
    Object.assign(out, { category: "open (software, copyleft)", is_open: true, permits_commercial: true, permits_derivatives: true, share_alike: true, note: "Copyleft software license." });
  } else if (/^(MIT|BSD|APACHE|ISC|ZLIB|UNLICENSE)/.test(u)) {
    Object.assign(out, { category: "open (software)", is_open: true, permits_commercial: true, permits_derivatives: true, note: "Permissive software license; note this is a software, not data, license." });
  }
  // (Re)usable Data Project taxonomy (Carbon et al. 2019)
  out.rdp_category = !out.is_open && out.category !== "custom/unknown" ? "restrictive"
    : out.is_open ? (out.share_alike ? "copyleft" : "permissive") : "unknown";
  out.facilitates_reuse = out.rdp_category === "permissive";
  return out;
}

// FAIR-TLC (Traceable, Licensed, Connected) -- Haendel et al. (zenodo.203295).
export function fairTlc(metadata: Reference, reuse: LicenseReuse[], hasRelated: boolean): TlcRow[] {
  const has = (k: string) => metadata[k] != null;
  const documented = reuse.length > 0;
  const minimallyRestrictive = reuse.some((l) => l.is_open);
  const flowthrough = documented && reuse.every((l) => l.category !== "custom/unknown");
  return [
    { dimension: "Traceable", indicator: "T1 Provenance", met: has("created_date") || has("modified_date") || has("publication_date") },
    { dimension: "Traceable", indicator: "T2 Attribution", met: has("creator") && (has("publisher") || has("contributor")) },
    { dimension: "Licensed", indicator: "L1 Documented & minimally restrictive", met: documented && minimallyRestrictive },
    { dimension: "Licensed", indicator: "L2 Flowthrough transparency", met: flowthrough },
    { dimension: "Connected", indicator: "C1 Connectedness", met: hasRelated || has("related_resources") },
  ];
}

export function reuseFromMetadata(license: unknown, data: RefData): LicenseReuse[] {
  const list = Array.isArray(license) ? license : license ? [license] : [];
  const accessLike = /info:eu-repo\/semantics\/|\/accessRights|(open|closed|restricted|embargoed)Access/i;
  return list
    .filter((l): l is string => typeof l === "string" && !accessLike.test(l))
    .map((l) => licenseReuse(l, data));
}

export function classifyAccess(accessLevel: unknown, urls: string[], data: RefData): AccessInfo {
  const codes = data.access.reduce<Record<string, string>>((acc, a) => {
    if (a.id) acc[a.id] = a.access_condition;
    if (a.uri) acc[a.uri] = a.access_condition;
    return acc;
  }, {});
  const vals = (Array.isArray(accessLevel) ? accessLevel : accessLevel ? [accessLevel] : []) as string[];
  let access = "unknown";
  for (const v of vals) {
    if (/creativecommons|legalcode|spdx\.org\/licenses/i.test(v)) continue;
    const tail = v.replace(/.*[/#]/, "");
    if (codes[v] || codes[tail]) { access = codes[v] || codes[tail]; break; }
    if (/openAccess/.test(v)) { access = "public"; break; }
    if (/closedAccess/.test(v)) { access = "closed"; break; }
    if (/restrictedAccess/.test(v)) { access = "restricted"; break; }
    if (/embargoedAccess/.test(v)) { access = "embargoed"; break; }
  }
  const controlledHosts = /dbgap|ega-archive|ncbi\.nlm\.nih\.gov\/gap/i;
  const controlled = ["restricted", "closed", "embargoed"].includes(access) || urls.some((u) => controlledHosts.test(u));
  const sensitive = urls.some((u) => controlledHosts.test(u));
  const note = controlled
    ? "Controlled-access data: restricted availability may be legitimate; evaluate metadata richness rather than open download."
    : access === "public" ? "Open access." : "Access level could not be determined from metadata.";
  return { access, controlled_access: controlled, sensitive, note };
}

export function identifierHygiene(id: string): HygieneInfo {
  const issues: string[] = [];
  const layered = /^rrid:/i.test(id) || (/^[A-Za-z]+:[A-Za-z]+:[^:/]+$/.test(id) && !/^(urn|info):/i.test(id));
  if (layered) issues.push("Compound/layered identifier (e.g. RRID:MGI:...) reduces interoperability; prefer the underlying source PID.");
  const isDoi = /(10\.\d{2,9}\/)/.test(id);
  const scheme = isDoi ? "doi" : /^https?:\/\//.test(id) ? "url" : null;
  const persistent = isDoi || /hdl\.handle\.net|\/ark:/.test(id);
  if (!scheme) issues.push("Identifier scheme not recognized; may not follow identifier best practices.");
  else if (!persistent) issues.push("Not a persistent identifier; prefer a DOI, Handle, or ARK.");
  return { scheme, is_persistent: persistent, hygiene_ok: issues.length === 0, issues };
}
