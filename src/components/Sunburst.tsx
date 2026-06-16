import { useRef, useState } from "react";
import type { CategoryScore, MetricResult } from "../lib/types";
import { CAT_KEYS, CAT_LABEL, CAT_COLOR, scoreTone, maturityTag } from "../lib/fair";
import { useCountUp } from "../lib/hooks";

/** Point on a circle of radius r at `deg` degrees, 0deg at top, clockwise. */
function polar(r: number, deg: number): [number, number] {
  const a = ((deg - 90) * Math.PI) / 180;
  return [r * Math.cos(a), r * Math.sin(a)];
}

/** SVG path for an annular sector (a ring slice) between two radii and angles. */
function sector(rIn: number, rOut: number, a0: number, a1: number): string {
  const large = a1 - a0 > 180 ? 1 : 0;
  const [x0o, y0o] = polar(rOut, a0);
  const [x1o, y1o] = polar(rOut, a1);
  const [x1i, y1i] = polar(rIn, a1);
  const [x0i, y0i] = polar(rIn, a0);
  return [
    `M ${x0o} ${y0o}`,
    `A ${rOut} ${rOut} 0 ${large} 1 ${x1o} ${y1o}`,
    `L ${x1i} ${y1i}`,
    `A ${rIn} ${rIn} 0 ${large} 0 ${x0i} ${y0i}`,
    "Z",
  ].join(" ");
}

/** Short metric label: "FsF-R1.1-01M" -> "R1.1"; "FRSM-15-R1.1" -> "R1.1". */
function shortId(id: string): string {
  const p = id.split("-");
  return id.startsWith("FRSM") ? p[2] ?? id : p[1] ?? id;
}

const op = (pct: number) => Math.max(0.16, Math.min(1, pct / 100));

interface Tip {
  key: string;
  heading: string;
  name?: string;
  score: string;
  pct: number;
  maturity?: number;
  color: string;
}
interface Arc {
  key: string;
  d: string;
  color: string;
  opacity: number;
  tip: Tip;
}

export function Sunburst({
  results,
  summary,
  size = 330,
}: {
  results: MetricResult[];
  summary: CategoryScore[];
  size?: number;
}) {
  const fair = summary.find((s) => s.category === "FAIR");
  const pct = useCountUp(fair ? fair.percent : 0);
  const wrapRef = useRef<HTMLDivElement>(null);
  const [hover, setHover] = useState<{ tip: Tip; x: number; y: number } | null>(null);

  function onMove(e: React.MouseEvent, tip: Tip) {
    const r = wrapRef.current?.getBoundingClientRect();
    if (!r) return;
    setHover({ tip, x: e.clientX - r.left, y: e.clientY - r.top });
  }

  // metrics grouped F, A, I, R in identifier order
  const groups = CAT_KEYS.map((k) => ({
    key: k,
    metrics: results
      .filter((r) => r.category === k)
      .sort((a, b) => a.metric_identifier.localeCompare(b.metric_identifier)),
  })).filter((g) => g.metrics.length);

  const n = groups.reduce((s, g) => s + g.metrics.length, 0) || 1;
  const step = 360 / n;
  const gap = 1.1; // degrees of separation between slices

  const rInner = [42, 64] as const; // category band
  const rOuter = [68, 96] as const; // metric band

  type Lbl = { x: number; y: number; text: string; anchor: string; cls: string; size: number };
  const innerArcs: Arc[] = [];
  const outerArcs: Arc[] = [];
  const labels: Lbl[] = [];

  let cursor = 0;
  for (const g of groups) {
    const a0 = cursor * step;
    const a1 = (cursor + g.metrics.length) * step;
    const cat = summary.find((s) => s.category === g.key);
    const catPct = cat ? cat.percent : 0;
    const ikey = `in-${g.key}`;

    innerArcs.push({
      key: ikey,
      d: sector(rInner[0], rInner[1], a0 + gap / 2, a1 - gap / 2),
      color: CAT_COLOR[g.key],
      opacity: op(catPct),
      tip: {
        key: ikey,
        heading: CAT_LABEL[g.key],
        score: cat ? `${cat.earned}/${cat.total} points` : "",
        pct: catPct,
        maturity: cat?.maturity,
        color: CAT_COLOR[g.key],
      },
    });

    // category name outside the outer ring, at the group mid-angle
    const mid = (a0 + a1) / 2;
    const [lx, ly] = polar(rOuter[1] + 11, mid);
    const cos = Math.cos(((mid - 90) * Math.PI) / 180);
    labels.push({
      x: lx,
      y: ly,
      text: CAT_LABEL[g.key],
      anchor: Math.abs(cos) < 0.3 ? "middle" : cos > 0 ? "start" : "end",
      cls: "fill-slate-500 dark:fill-slate-400 font-semibold",
      size: 8.5,
    });

    g.metrics.forEach((m, i) => {
      const m0 = (cursor + i) * step;
      const m1 = (cursor + i + 1) * step;
      const okey = `out-${m.metric_identifier}`;
      outerArcs.push({
        key: okey,
        d: sector(rOuter[0], rOuter[1], m0 + gap / 2, m1 - gap / 2),
        color: CAT_COLOR[g.key],
        opacity: op(m.percent),
        tip: {
          key: okey,
          heading: m.metric_identifier,
          name: m.metric_name,
          score: `${m.earned}/${m.total}`,
          pct: m.percent,
          maturity: m.maturity,
          color: CAT_COLOR[g.key],
        },
      });
      const mm = (m0 + m1) / 2;
      const [tx, ty] = polar((rOuter[0] + rOuter[1]) / 2, mm);
      labels.push({
        x: tx,
        y: ty,
        text: shortId(m.metric_identifier),
        anchor: "middle",
        cls: "fill-slate-700 dark:fill-white/90 font-medium",
        size: 7,
      });
    });

    cursor += g.metrics.length;
  }

  const half = rOuter[1] + 54;
  const tone = scoreTone(fair ? fair.percent : 0);
  const hk = hover?.tip.key;

  function arcEl(a: Arc) {
    const active = hk === a.key;
    return (
      <path
        key={a.key}
        d={a.d}
        fill={a.color}
        fillOpacity={active ? 1 : a.opacity}
        strokeWidth={active ? 2 : 1.3}
        className={active ? "[stroke:white] dark:[stroke:white]" : ""}
        style={{ cursor: "pointer", transition: "fill-opacity .12s" }}
        onMouseMove={(e) => onMove(e, a.tip)}
        onMouseEnter={(e) => onMove(e, a.tip)}
      />
    );
  }

  const W = 2 * half;
  // tooltip placement, clamped inside the graphic
  const tipW = 190;
  const tx = hover ? Math.max(6, Math.min(hover.x + 14, size - tipW - 6)) : 0;
  const ty = hover ? Math.max(6, hover.y + 14) : 0;

  return (
    <div ref={wrapRef} className="relative" style={{ width: size, height: size }}
      onMouseLeave={() => setHover(null)}>
      <svg
        width={size}
        height={size}
        viewBox={`${-half} ${-half} ${W} ${W}`}
        role="img"
        aria-label={`FAIR sunburst: overall ${Math.round(fair ? fair.percent : 0)} percent. Inner ring is the F/A/I/R categories, outer ring is the individual metrics. Hover a segment for its score.`}
        className="animate-[fade-in_.7s_ease] [&_path]:stroke-white dark:[&_path]:stroke-slate-950"
      >
        {innerArcs.map(arcEl)}
        {outerArcs.map(arcEl)}
        {labels.map((l, i) => (
          <text key={i} x={l.x} y={l.y} fontSize={l.size}
            textAnchor={l.anchor as "start" | "middle" | "end"}
            dominantBaseline="central" className={l.cls}
            style={{ pointerEvents: "none" }}>
            {l.text}
          </text>
        ))}
        <text x={0} y={-4} textAnchor="middle" dominantBaseline="central"
          fontSize={30} fontWeight={800} fill={tone} style={{ pointerEvents: "none" }}>
          {Math.round(pct)}
        </text>
        <text x={0} y={16} textAnchor="middle" dominantBaseline="central"
          fontSize={9} className="fill-slate-400" letterSpacing={2}
          style={{ pointerEvents: "none" }}>
          % FAIR
        </text>
      </svg>

      {hover && (
        <div
          className="pointer-events-none absolute z-20 rounded-xl border border-slate-200/70 bg-white/95 px-3 py-2 text-left shadow-lg backdrop-blur dark:border-white/10 dark:bg-slate-900/95"
          style={{ left: tx, top: ty, width: tipW }}
        >
          <div className="flex items-center gap-1.5">
            <span className="h-2.5 w-2.5 shrink-0 rounded-full" style={{ background: hover.tip.color }} />
            <span className="truncate font-mono text-xs font-semibold text-slate-700 dark:text-slate-200">
              {hover.tip.heading}
            </span>
          </div>
          {hover.tip.name && (
            <div className="mt-0.5 text-[11px] leading-snug text-slate-500 dark:text-slate-400">
              {hover.tip.name}
            </div>
          )}
          <div className="mt-1 flex items-center gap-2 text-[11px]">
            <span className="font-semibold" style={{ color: scoreTone(hover.tip.pct) }}>
              {Math.round(hover.tip.pct)}%
            </span>
            <span className="text-slate-500 dark:text-slate-400">{hover.tip.score}</span>
            {hover.tip.maturity != null && (
              <span className="ml-auto rounded px-1.5 py-0.5 text-[10px] font-semibold text-white"
                style={{ background: maturityTag(hover.tip.maturity).color }}>
                {maturityTag(hover.tip.maturity).label}
              </span>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
