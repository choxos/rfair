import type { CategoryScore, MetricResult } from "../lib/types";
import { CAT_KEYS, CAT_LABEL, CAT_COLOR, scoreTone } from "../lib/fair";
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

/** Short metric label: "FsF-R1.1-01M" -> "R1.1". */
function shortId(id: string): string {
  return id.split("-")[1] ?? id;
}

const op = (pct: number) => Math.max(0.16, Math.min(1, pct / 100));

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

  type Arc = { d: string; color: string; opacity: number; key: string; title: string };
  type Lbl = { x: number; y: number; text: string; anchor: string; cls: string; size: number; rot?: number };
  const innerArcs: Arc[] = [];
  const outerArcs: Arc[] = [];
  const labels: Lbl[] = [];

  let cursor = 0;
  for (const g of groups) {
    const a0 = cursor * step;
    const a1 = (cursor + g.metrics.length) * step;
    const cat = summary.find((s) => s.category === g.key);
    const catPct = cat ? cat.percent : 0;

    innerArcs.push({
      d: sector(rInner[0], rInner[1], a0 + gap / 2, a1 - gap / 2),
      color: CAT_COLOR[g.key],
      opacity: op(catPct),
      key: `in-${g.key}`,
      title: `${CAT_LABEL[g.key]}: ${Math.round(catPct)}%`,
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
      outerArcs.push({
        d: sector(rOuter[0], rOuter[1], m0 + gap / 2, m1 - gap / 2),
        color: CAT_COLOR[g.key],
        opacity: op(m.percent),
        key: `out-${m.metric_identifier}`,
        title: `${m.metric_identifier} — ${m.metric_name}: ${m.earned}/${m.total} (${Math.round(m.percent)}%)`,
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
        rot: 0,
      });
    });

    cursor += g.metrics.length;
  }

  const half = rOuter[1] + 54;
  const tone = scoreTone(fair ? fair.percent : 0);

  return (
    <svg
      width={size}
      height={size}
      viewBox={`${-half} ${-half} ${2 * half} ${2 * half}`}
      role="img"
      aria-label={`FAIR sunburst: overall ${Math.round(fair ? fair.percent : 0)} percent, with inner ring of F/A/I/R categories and outer ring of individual metrics.`}
      className="animate-[fade-in_.7s_ease] [&_path]:stroke-white dark:[&_path]:stroke-slate-950"
    >
      {innerArcs.map((a) => (
        <path key={a.key} d={a.d} fill={a.color} fillOpacity={a.opacity} strokeWidth={1.3}>
          <title>{a.title}</title>
        </path>
      ))}
      {outerArcs.map((a) => (
        <path key={a.key} d={a.d} fill={a.color} fillOpacity={a.opacity} strokeWidth={1.3}>
          <title>{a.title}</title>
        </path>
      ))}
      {labels.map((l, i) => (
        <text
          key={i}
          x={l.x}
          y={l.y}
          fontSize={l.size}
          textAnchor={l.anchor as "start" | "middle" | "end"}
          dominantBaseline="central"
          className={l.cls}
        >
          {l.text}
        </text>
      ))}
      <text x={0} y={-4} textAnchor="middle" dominantBaseline="central"
        fontSize={30} fontWeight={800} fill={tone}>
        {Math.round(pct)}
      </text>
      <text x={0} y={16} textAnchor="middle" dominantBaseline="central"
        fontSize={9} className="fill-slate-400" letterSpacing={2}>
        % FAIR
      </text>
    </svg>
  );
}
