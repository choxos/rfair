import type { CategoryScore } from "../lib/types";
import { CAT_KEYS, CAT_LABEL, CAT_COLOR, CAT_BLURB } from "../lib/fair";
import { Ring } from "./Gauge";
import { MaturityBadge } from "./MaturityBadge";

export function CategoryCards({ summary }: { summary: CategoryScore[] }) {
  const byKey = new Map(summary.map((s) => [s.category, s]));
  return (
    <div className="grid grid-cols-2 gap-3 lg:grid-cols-4">
      {CAT_KEYS.map((k, i) => {
        const c = byKey.get(k);
        const pct = c ? c.percent : 0;
        return (
          <div
            key={k}
            className="card group p-4 transition hover:-translate-y-0.5 hover:shadow-md"
            style={{ animation: `rise .5s cubic-bezier(.22,1,.36,1) ${i * 70}ms both` }}
            title={CAT_BLURB[k]}
          >
            <div className="flex items-center gap-3">
              <Ring percent={pct} color={CAT_COLOR[k]} />
              <div className="min-w-0">
                <div className="truncate text-sm font-semibold" style={{ color: CAT_COLOR[k] }}>
                  {CAT_LABEL[k]}
                </div>
                <div className="text-xs text-slate-500 dark:text-slate-400">
                  {c ? `${c.earned} of ${c.total}` : "—"}
                </div>
              </div>
            </div>
            <div className="mt-3">
              {c ? <MaturityBadge maturity={c.maturity} /> : null}
            </div>
          </div>
        );
      })}
    </div>
  );
}
