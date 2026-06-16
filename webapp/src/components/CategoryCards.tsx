import type { CategoryScore } from "../lib/types";

const LABELS: Record<string, string> = { F: "Findable", A: "Accessible", I: "Interoperable", R: "Reusable" };
const CAT: Record<string, string> = { F: "#118AB2", A: "#06D6A0", I: "#FFD166", R: "#EF476F" };
const MATURITY = ["incomplete", "initial", "moderate", "advanced"];
const MATURITY_COLOR = ["#fe7d37", "#dfb317", "#97ca00", "#4c1"];

export function MaturityBadge({ maturity }: { maturity: number }) {
  const m = Math.min(Math.max(Math.round(maturity), 0), 3);
  return (
    <span className="rounded px-2 py-0.5 text-xs font-semibold text-white" style={{ background: MATURITY_COLOR[m] }}>
      {MATURITY[m]}
    </span>
  );
}

export function CategoryCards({ summary }: { summary: CategoryScore[] }) {
  const cats = summary.filter((s) => ["F", "A", "I", "R"].includes(s.category));
  return (
    <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
      {cats.map((c) => (
        <div key={c.category} className="rounded-lg border bg-white p-3 shadow-sm">
          <div className="flex items-center gap-2">
            <span className="h-3 w-3 rounded-full" style={{ background: CAT[c.category] }} />
            <span className="text-sm font-semibold">{LABELS[c.category]}</span>
          </div>
          <div className="mt-1 text-2xl font-bold">{Math.round(c.percent)}%</div>
          <div className="text-xs text-slate-500">{c.earned} of {c.total}</div>
          <div className="mt-2"><MaturityBadge maturity={c.maturity} /></div>
        </div>
      ))}
    </div>
  );
}
