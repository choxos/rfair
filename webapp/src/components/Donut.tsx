import type { CategoryScore, MetricResult } from "../lib/types";

const CAT: Record<string, string> = { F: "#118AB2", A: "#06D6A0", I: "#FFD166", R: "#EF476F" };

function Ring({ segments, r, width }: { segments: { frac: number; color: string; opacity: number }[]; r: number; width: number }) {
  const C = 2 * Math.PI * r;
  let cum = 0;
  return (
    <>
      <circle cx={100} cy={100} r={r} fill="none" stroke="#e2e8f0" strokeWidth={width} />
      {segments.map((s, i) => {
        const el = (
          <circle key={i} cx={100} cy={100} r={r} fill="none" stroke={s.color}
            strokeOpacity={s.opacity} strokeWidth={width}
            strokeDasharray={`${s.frac * C} ${C}`} strokeDashoffset={-cum * C} />
        );
        cum += s.frac;
        return el;
      })}
    </>
  );
}

export function Donut({ summary, results }: { summary: CategoryScore[]; results: MetricResult[] }) {
  const cats = summary.filter((s) => ["F", "A", "I", "R"].includes(s.category));
  const fair = summary.find((s) => s.category === "FAIR");
  const totalCat = cats.reduce((s, c) => s + c.total, 0) || 1;
  const inner = cats.map((c) => ({ frac: c.total / totalCat, color: CAT[c.category], opacity: Math.max(0.18, c.percent / 100) }));

  // outer ring: individual metrics, sized by their total, colored by category
  const totalMetric = results.reduce((s, m) => s + m.total, 0) || 1;
  const outer = results.map((m) => ({ frac: m.total / totalMetric, color: CAT[m.category] ?? "#94a3b8", opacity: Math.max(0.12, m.percent / 100) }));

  return (
    <div className="relative flex items-center justify-center" style={{ width: 220, height: 220 }}>
      <svg width={220} height={220} viewBox="0 0 200 200" className="-rotate-90">
        <Ring segments={outer} r={88} width={12} />
        <Ring segments={inner} r={66} width={26} />
      </svg>
      <div className="absolute text-center">
        <div className="text-3xl font-bold text-fair-dark">{fair ? Math.round(fair.percent) : 0}%</div>
        <div className="text-xs uppercase tracking-wide text-slate-400">FAIR</div>
      </div>
    </div>
  );
}
