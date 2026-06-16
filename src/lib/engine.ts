import type { Assessment, AssessmentOptions, CategoryScore, MetricResult, MetricTest, MetricVersion, Reference, RefData, SoftwareSignals } from "./types";
import { SOFTWARE_METRIC_VERSIONS } from "./types";
import { harvest, harvestSoftware, parseGithub } from "./harvest";
import { reuseFromMetadata, classifyAccess, identifierHygiene, fairTlc } from "./reuse";

// Engine state for one assessment.
interface Ctx {
  id: string;
  doi: string | null;
  metadata: Reference;
  sources: { source: string; method: string }[];
  resolved: string | null;
}

interface Eval {
  metric_identifier: string;
  total: number;
  tests: { id: string; score: number; maturity: number; name: string; status: "pass" | "fail" }[];
  earned: number;
  maturity: number;
  status: "pass" | "fail";
  output?: unknown;
}

function principleOf(mid: string): { principle: string; category: string } {
  const m = mid.match(/^(?:FRSM-[0-9]+|FsF)-(([FAIR])[0-9](\.[0-9])?)/);
  return m ? { principle: m[1], category: m[2] } : { principle: "", category: "" };
}

function newEval(def: any): Eval {
  return {
    metric_identifier: def.metric_identifier,
    total: Number(def.total_score ?? 0),
    tests: (def.metric_tests ?? []).map((t: any) => ({
      id: t.metric_test_identifier, name: t.metric_test_name ?? "",
      score: Number(t.metric_test_score ?? 0), maturity: Number(t.metric_test_maturity ?? 0),
      status: "fail" as const,
    })),
    earned: 0, maturity: 0, status: "fail",
  };
}
const METRIC_ALIASES: Record<string, string> = {
  "FsF-F1-01D": "FsF-F1-01MD",
  "FsF-F1-01M": "FsF-F1-01MD",
  "FsF-F1-01DD": "FsF-F1-01MD",
  "FsF-F1-02D": "FsF-F1-02MD",
  "FsF-F1-02M": "FsF-F1-02MD",
  "FsF-F1-02DD": "FsF-F1-02MD",
  "FsF-I1-02M": "FsF-I2-01M",
  "FsF-R1-01MD": "FsF-R1-01M",
};

function agnosticMetricId(mid: string): string {
  const fsf = mid.match(/^FsF-[FAIR][0-9]?(\.[0-9])?-[0-9]+[MD]+/);
  if (fsf) return fsf[0];
  const frsm = mid.match(/^FRSM-[0-9]+-[FAIR][0-9]?(\.[0-9])?/);
  if (frsm) return frsm[0];
  return mid;
}
function canonicalMetricId(mid: string): string {
  const agnostic = agnosticMetricId(mid);
  return METRIC_ALIASES[agnostic] ?? agnostic;
}
function normalizedTestId(id: string): string {
  return id.replace(/-CESSDA(?=-[0-9]+$)/i, "").replace(/[-_](ss|env)$/i, "");
}
function passSuffix(e: Eval, mid: string, suffix: string) {
  const targets = new Set([`${mid}${suffix}`, `${agnosticMetricId(mid)}${suffix}`, `${canonicalMetricId(mid)}${suffix}`]);
  const t = e.tests.find((x) => targets.has(normalizedTestId(x.id)) || targets.has(x.id));
  if (!t) return;
  if (t.status === "pass") return;
  t.status = "pass";
  e.earned += t.score;
  e.maturity = Math.max(e.maturity, t.maturity);
  e.status = "pass";
}

const asList = (v: unknown): unknown[] => (Array.isArray(v) ? v : v == null ? [] : [v]);
const has = (md: Reference, k: string) => md[k] != null && asList(md[k]).length > 0;
const urlScheme = (u: string): string => { try { return new URL(u).protocol.replace(":", "").toLowerCase(); } catch { return ""; } };
function contentUrls(md: Reference): string[] {
  return asList(md.object_content_identifier).map((x: any) => (x && typeof x === "object" ? x.url : x)).filter((u): u is string => !!u);
}

// Evaluators that score from registry (DataCite/Crossref) metadata.
function runEvaluator(mid: string, e: Eval, ctx: Ctx, data: RefData) {
  const md = ctx.metadata;
  const stdProto = (s: string) => !!s && s in data.protocols;
  const protoAuth = (s: string) => stdProto(s) && !!data.protocols[s]?.auth;
  const metaScheme = urlScheme(ctx.resolved ?? (ctx.doi ? `https://doi.org/${ctx.doi}` : ctx.id));
  const key = canonicalMetricId(mid);

  switch (key) {
    case "FsF-F1-01MD":
      if (ctx.doi || /^https?:/.test(ctx.id)) passSuffix(e, mid, "-1");
      break;
    case "FsF-F1-02MD":
      if (ctx.doi) { passSuffix(e, mid, "-1"); if (ctx.resolved) passSuffix(e, mid, "-2"); }
      break;
    case "FsF-F2-01M": {
      const found = Object.keys(md);
      const citation = ["creator", "title", "object_identifier", "publication_date", "publisher", "object_type"];
      const desc = [...citation, "summary", "keywords"];
      if (ctx.sources.length) passSuffix(e, mid, "-1");
      if (citation.every((k) => found.includes(k))) passSuffix(e, mid, "-2");
      if (desc.every((k) => found.includes(k))) passSuffix(e, mid, "-3");
      break;
    }
    case "FsF-F3-01M":
      if (has(md, "object_format") || has(md, "object_size") || contentUrls(md).length) passSuffix(e, mid, "-1");
      if (contentUrls(md).length) passSuffix(e, mid, "-2");
      break;
    case "FsF-F4-01M":
      // embedded offering methods are not available client-side (CORS)
      if (ctx.sources.some((s) => /datacite/i.test(s.source))) passSuffix(e, mid, "-2");
      if (ctx.sources.length) passSuffix(e, mid, "-3");
      break;
    case "FsF-A1-01M": {
      const real = asList(md.access_level).filter((a: any) => typeof a === "string"
        && !/creativecommons|legalcode|spdx\.org\/licenses/i.test(a)
        && /(open|closed|restricted|embargoed)Access|eu-repo\/semantics/i.test(a));
      if (real.length) { passSuffix(e, mid, "-1"); passSuffix(e, mid, "-2"); passSuffix(e, mid, "-3"); }
      break;
    }
    case "FsF-A1-03D":
      if (contentUrls(md).some((u) => stdProto(urlScheme(u)))) passSuffix(e, mid, "-1");
      break;
    case "FsF-A1-02M":
      if (stdProto(metaScheme)) passSuffix(e, mid, "-1");
      break;
    case "FsF-A2-01M":
      if ((ctx.doi || ctx.resolved) && /^https?/.test(metaScheme)) passSuffix(e, mid, "-1");
      break;
    case "FsF-A1-02MD":
      if (ctx.resolved || ctx.doi) passSuffix(e, mid, "-1");
      if (contentUrls(md).some((u) => stdProto(urlScheme(u)))) passSuffix(e, mid, "-2");
      break;
    case "FsF-A1.1-01MD":
      if (stdProto(metaScheme)) passSuffix(e, mid, "-1");
      if (contentUrls(md).some((u) => stdProto(urlScheme(u)))) passSuffix(e, mid, "-2");
      break;
    case "FsF-A1.2-01MD":
      if (protoAuth(metaScheme)) passSuffix(e, mid, "-1");
      if (contentUrls(md).some((u) => protoAuth(urlScheme(u)))) passSuffix(e, mid, "-2");
      break;
    case "FsF-I1-01M":
      if (ctx.sources.some((s) => s.method === "embedded")) passSuffix(e, mid, "-1");
      if (ctx.sources.some((s) => s.method === "content_negotiation")) passSuffix(e, mid, "-2");
      break;
    case "FsF-I3-01M": {
      const rels = asList(md.related_resources);
      if (rels.length) {
        passSuffix(e, mid, "-1");
        if (rels.some((r: any) => r?.related_resource && /(10\.\d|https?:|hdl|ark:)/.test(String(r.related_resource)))) passSuffix(e, mid, "-2");
      }
      break;
    }
    case "FsF-R1-01M":
      if (has(md, "object_type") || contentUrls(md).length) passSuffix(e, mid, "-1");
      if (has(md, "object_type")) passSuffix(e, mid, "-1a");
      if (contentUrls(md).length) passSuffix(e, mid, "-1b");
      if (has(md, "object_format") || has(md, "object_size") || contentUrls(md).length) passSuffix(e, mid, "-2");
      if (has(md, "object_format") || has(md, "object_size")) passSuffix(e, mid, "-2a");
      if (has(md, "measured_variable")) passSuffix(e, mid, "-2b");
      if (has(md, "metadata_service")) passSuffix(e, mid, "-2c");
      if (has(md, "object_format") || has(md, "object_size") || contentUrls(md).length) passSuffix(e, mid, "-3");
      if (has(md, "measured_variable")) passSuffix(e, mid, "-4");
      break;
    case "FsF-R1.1-01M":
      if (reuseFromMetadata(md.license, data).length) {
        passSuffix(e, mid, "-1");
        passSuffix(e, mid, "-2");
      }
      break;
    case "FsF-R1.2-01M": {
      const prov = ["contributor", "creator", "publisher", "created_date", "modified_date", "publication_date", "related_resources"];
      if (prov.some((k) => has(md, k))) passSuffix(e, mid, "-1");
      break;
    }
    case "FsF-R1.3-01M":
      // generic standards (DataCite/schema.org) -> multidisciplinary test-3
      if (ctx.sources.some((s) => /datacite|schema/i.test(s.source))) passSuffix(e, mid, "-3");
      break;
    case "FsF-R1.3-02D": {
      const fmts = new Set([...data.formats.science, ...data.formats.long_term, ...data.formats.open]);
      const cand = [md.object_format, ...contentUrls(md)].filter((x): x is string => typeof x === "string").map((x) => x.toLowerCase());
      if (cand.some((c) => fmts.has(c))) passSuffix(e, mid, "-1");
      break;
    }
  }
}

// FRSM (research software) evaluators, scoring from harvested repository
// signals. Ports R/eval_frsm.R; `pass(e, "<mid>-<n>")` matches the metric-test
// identifiers in metrics_v0.7_software.json (e.g. "FRSM-01-F1-1").
const semver = (v?: string) => !!v && /^v?\d+\.\d+/.test(v);

function runFrsm(mid: string, e: Eval, s: SoftwareSignals, metaLicense: boolean) {
  switch (canonicalMetricId(mid)) {
    case "FRSM-01-F1":
      if (s.identifier) passSuffix(e, mid, "-1");
      if (s.registry_doi) { passSuffix(e, mid, "-2"); passSuffix(e, mid, "-3"); }
      break;
    case "FRSM-02-F1.1":
      if (s.has_citation) passSuffix(e, mid, "-1");
      break;
    case "FRSM-03-F1.2":
      if (s.version) passSuffix(e, mid, "-1");
      if (semver(s.version)) passSuffix(e, mid, "-2");
      if (s.has_citation) passSuffix(e, mid, "-3");
      break;
    case "FRSM-04-F2":
      if (s.name && s.description) passSuffix(e, mid, "-1");
      if (s.has_readme) passSuffix(e, mid, "-2");
      if (s.has_citation) passSuffix(e, mid, "-3");
      break;
    case "FRSM-05-R1":
      if (s.has_readme) passSuffix(e, mid, "-1");
      if (s.has_ci) passSuffix(e, mid, "-2");
      if (s.has_requirements) passSuffix(e, mid, "-3");
      break;
    case "FRSM-06-F2":
      if (s.contributors > 0) passSuffix(e, mid, "-1");
      if (s.has_citation) passSuffix(e, mid, "-2");
      break;
    case "FRSM-07-F3":
      if (s.has_citation) passSuffix(e, mid, "-1");
      if (s.registry_doi) passSuffix(e, mid, "-2");
      break;
    case "FRSM-08-F4":
      if (s.registry_doi) { passSuffix(e, mid, "-1"); passSuffix(e, mid, "-2"); }
      break;
    case "FRSM-09-A1":
      if (s.identifier && /^https/.test(s.identifier)) passSuffix(e, mid, "-1");
      break;
    case "FRSM-10-I1":
      if (s.has_requirements) passSuffix(e, mid, "-1");
      break;
    case "FRSM-11-I1":
      if (s.has_api) passSuffix(e, mid, "-1");
      break;
    case "FRSM-12-I2":
      if (s.has_citation) passSuffix(e, mid, "-1");
      break;
    case "FRSM-13-R1":
      if (s.has_requirements) { passSuffix(e, mid, "-1"); passSuffix(e, mid, "-2"); }
      break;
    case "FRSM-14-R1":
      if (s.has_tests) passSuffix(e, mid, "-1");
      if (s.has_ci) passSuffix(e, mid, "-2");
      break;
    case "FRSM-15-R1.1":
      if (s.has_license) passSuffix(e, mid, "-1");
      break;
    case "FRSM-16-R1.1":
      if (metaLicense) passSuffix(e, mid, "-1");
      break;
    case "FRSM-17-R1.2":
      if (s.contributors > 0 || s.version) passSuffix(e, mid, "-1");
      break;
  }
}

function buildResult(def: any, e: Eval): MetricResult {
  const earned = Math.min(e.earned, e.total);
  const pc = principleOf(def.metric_identifier);
  const tests: MetricTest[] = e.tests.map((t) => ({ id: t.id, name: t.name, score: t.score, maturity: t.maturity, status: t.status }));
  return {
    id: Number(def.metric_number ?? 0),
    metric_identifier: def.metric_identifier,
    metric_name: def.metric_name ?? "",
    principle: pc.principle, category: pc.category,
    earned, total: e.total, percent: e.total ? Math.round((earned / e.total) * 1000) / 10 : 0,
    maturity: e.maturity, status: e.status, tests, output: e.output, debug: [],
  };
}

function summarize(results: MetricResult[]): CategoryScore[] {
  const cats = ["F", "A", "I", "R"];
  const out: CategoryScore[] = [];
  let te = 0, tt = 0;
  const mats: number[] = [];
  for (const c of cats) {
    const rs = results.filter((r) => r.category === c);
    if (!rs.length) continue;
    const earned = rs.reduce((s, r) => s + r.earned, 0);
    const total = rs.reduce((s, r) => s + r.total, 0);
    const meanMat = rs.reduce((s, r) => s + r.maturity, 0) / rs.length;
    const maturity = meanMat > 0 && meanMat < 1 ? 1 : Math.round(meanMat);
    out.push({ category: c, earned, total, percent: total ? Math.round((earned / total) * 1000) / 10 : 0, maturity });
    te += earned; tt += total; mats.push(maturity);
  }
  const fairMat = mats.length ? (() => { const m = mats.reduce((a, b) => a + b, 0) / 4; return m > 0 && m < 1 ? 1 : Math.round(m); })() : 0;
  out.push({ category: "FAIR", earned: te, total: tt, percent: tt ? Math.round((te / tt) * 1000) / 10 : 0, maturity: fairMat });
  return out;
}

const DEFAULT_OPTIONS: AssessmentOptions = {
  useDatacite: true,
  metadataServiceEndpoint: "",
  metadataServiceType: "oai_pmh",
};

export async function assess(
  input: string,
  data: RefData,
  version: MetricVersion = "0.8",
  options: AssessmentOptions = DEFAULT_OPTIONS,
): Promise<Assessment> {
  return SOFTWARE_METRIC_VERSIONS.has(version) ? assessSoftware(input, data, version) : assessData(input, data, version, options);
}

async function assessData(input: string, data: RefData, version: MetricVersion, options: AssessmentOptions): Promise<Assessment> {
  const h = await harvest(input, options);
  const ctx: Ctx = { id: input.trim(), doi: h.doi, metadata: h.metadata, sources: h.sources, resolved: h.resolved };
  const metrics = data.metricSets?.[version] ?? data.metrics;

  const results: MetricResult[] = (metrics.metrics ?? []).map((def: any) => {
    const e = newEval(def);
    runEvaluator(def.metric_identifier, e, ctx, data);
    return buildResult(def, e);
  }).filter((r: MetricResult) => r.category)
    .sort((a: MetricResult, b: MetricResult) => a.id - b.id);

  const urls = [ctx.resolved, ctx.doi ? `https://doi.org/${ctx.doi}` : null, ...contentUrls(ctx.metadata)].filter((u): u is string => !!u);
  const reuse = reuseFromMetadata(ctx.metadata.license, data);
  const hasRelated = asList(ctx.metadata.related_resources).length > 0;
  return {
    id: ctx.id, doi: ctx.doi, resolved_url: ctx.resolved, metric_version: version,
    metadata: ctx.metadata, sources: ctx.sources, results, summary: summarize(results),
    reuse,
    access: classifyAccess(ctx.metadata.access_level, urls, data),
    hygiene: identifierHygiene(ctx.id),
    tlc: fairTlc(ctx.metadata, reuse, hasRelated),
  };
}

async function assessSoftware(input: string, data: RefData, version: MetricVersion): Promise<Assessment> {
  const gh = parseGithub(input.trim());
  if (!gh) {
    throw new Error("Software (FRSM) assessment needs a code repository URL, e.g. https://github.com/owner/repo");
  }
  const h = await harvestSoftware(gh);
  const metaLicense = h.metadata.license != null;

  const metrics = data.metricSets?.[version] ?? data.softwareMetrics;
  const results: MetricResult[] = (metrics.metrics ?? []).map((def: any) => {
    const e = newEval(def);
    runFrsm(def.metric_identifier, e, h.signals, metaLicense);
    return buildResult(def, e);
  }).filter((r: MetricResult) => r.category)
    .sort((a: MetricResult, b: MetricResult) => a.id - b.id);

  const reuse = reuseFromMetadata(h.metadata.license, data);
  const urls = [h.resolved].filter((u): u is string => !!u);
  return {
    id: input.trim(), doi: null, resolved_url: h.resolved, metric_version: version,
    metadata: h.metadata, sources: h.sources, results, summary: summarize(results),
    reuse,
    access: classifyAccess(h.metadata.access_level, urls, data),
    hygiene: identifierHygiene(input.trim()),
    tlc: fairTlc(h.metadata, reuse, asList(h.metadata.related_resources).length > 0),
  };
}
