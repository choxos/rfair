import type { Assessment, CategoryScore, MetricResult, MetricTest, Reference, RefData } from "./types";
import { harvest } from "./harvest";
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
function pass(e: Eval, id: string) {
  const t = e.tests.find((x) => x.id === id);
  if (!t) return;
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

  switch (mid) {
    case "FsF-F1-01MD":
      if (ctx.doi || /^https?:/.test(ctx.id)) pass(e, `${mid}-1`);
      break;
    case "FsF-F1-02MD":
      if (ctx.doi) { pass(e, `${mid}-1`); if (ctx.resolved) pass(e, `${mid}-2`); }
      break;
    case "FsF-F2-01M": {
      const found = Object.keys(md);
      const citation = ["creator", "title", "object_identifier", "publication_date", "publisher", "object_type"];
      const desc = [...citation, "summary", "keywords"];
      if (citation.every((k) => found.includes(k))) pass(e, `${mid}-2`);
      if (desc.every((k) => found.includes(k))) pass(e, `${mid}-3`);
      break;
    }
    case "FsF-F3-01M":
      if (contentUrls(md).length) pass(e, `${mid}-2`);
      break;
    case "FsF-F4-01M":
      // embedded offering methods only -> not available client-side (CORS)
      break;
    case "FsF-A1-01M": {
      const real = asList(md.access_level).filter((a: any) => typeof a === "string"
        && !/creativecommons|legalcode|spdx\.org\/licenses/i.test(a)
        && /(open|closed|restricted|embargoed)Access|eu-repo\/semantics/i.test(a));
      if (real.length) pass(e, `${mid}-1`);
      break;
    }
    case "FsF-A1-02MD":
      if (ctx.resolved || ctx.doi) pass(e, `${mid}-1`);
      if (contentUrls(md).some((u) => stdProto(urlScheme(u)))) pass(e, `${mid}-2`);
      break;
    case "FsF-A1.1-01MD":
      if (stdProto(metaScheme)) pass(e, `${mid}-1`);
      if (contentUrls(md).some((u) => stdProto(urlScheme(u)))) pass(e, `${mid}-2`);
      break;
    case "FsF-A1.2-01MD":
      if (protoAuth(metaScheme)) pass(e, `${mid}-1`);
      if (contentUrls(md).some((u) => protoAuth(urlScheme(u)))) pass(e, `${mid}-2`);
      break;
    case "FsF-I1-01M":
      if (ctx.sources.some((s) => s.method === "content_negotiation")) pass(e, `${mid}-2`);
      break;
    case "FsF-I3-01M": {
      const rels = asList(md.related_resources);
      if (rels.length) {
        pass(e, `${mid}-1`);
        if (rels.some((r: any) => r?.related_resource && /(10\.\d|https?:|hdl|ark:)/.test(String(r.related_resource)))) pass(e, `${mid}-2`);
      }
      break;
    }
    case "FsF-R1-01M":
      if (has(md, "object_type")) pass(e, `${mid}-1`);
      if (has(md, "object_format") || has(md, "object_size") || contentUrls(md).length) pass(e, `${mid}-2`);
      break;
    case "FsF-R1.1-01M":
      if (reuseFromMetadata(md.license, data).length) {
        pass(e, `${mid}-1`);
      }
      break;
    case "FsF-R1.2-01M": {
      const prov = ["contributor", "creator", "publisher", "created_date", "modified_date", "publication_date", "related_resources"];
      if (prov.some((k) => has(md, k))) pass(e, `${mid}-1`);
      break;
    }
    case "FsF-R1.3-01M":
      // generic standards (DataCite/schema.org) -> multidisciplinary test-3
      if (ctx.sources.some((s) => /datacite|schema/i.test(s.source))) pass(e, `${mid}-3`);
      break;
    case "FsF-R1.3-02D": {
      const fmts = new Set([...data.formats.science, ...data.formats.long_term, ...data.formats.open]);
      const cand = [md.object_format, ...contentUrls(md)].filter((x): x is string => typeof x === "string").map((x) => x.toLowerCase());
      if (cand.some((c) => fmts.has(c))) pass(e, `${mid}-1`);
      break;
    }
  }
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

export async function assess(input: string, data: RefData): Promise<Assessment> {
  const h = await harvest(input);
  const ctx: Ctx = { id: input.trim(), doi: h.doi, metadata: h.metadata, sources: h.sources, resolved: h.resolved };

  const results: MetricResult[] = (data.metrics.metrics ?? []).map((def: any) => {
    const e = newEval(def);
    runEvaluator(def.metric_identifier, e, ctx, data);
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
  }).filter((r: MetricResult) => r.category)
    .sort((a: MetricResult, b: MetricResult) => a.id - b.id);

  const urls = [ctx.resolved, ctx.doi ? `https://doi.org/${ctx.doi}` : null, ...contentUrls(ctx.metadata)].filter((u): u is string => !!u);
  const reuse = reuseFromMetadata(ctx.metadata.license, data);
  const hasRelated = asList(ctx.metadata.related_resources).length > 0;
  return {
    id: ctx.id, doi: ctx.doi, resolved_url: ctx.resolved, metric_version: "0.8",
    metadata: ctx.metadata, sources: ctx.sources, results, summary: summarize(results),
    reuse,
    access: classifyAccess(ctx.metadata.access_level, urls, data),
    hygiene: identifierHygiene(ctx.id),
    tlc: fairTlc(ctx.metadata, reuse, hasRelated),
  };
}
