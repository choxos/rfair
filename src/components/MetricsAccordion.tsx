import type { MetricResult } from "../lib/types";
import { MaturityBadge } from "./MaturityBadge";
import { CAT_LABEL, CAT_COLOR, CAT_KEYS } from "../lib/fair";

function Bar({ pct, color }: { pct: number; color: string }) {
  return (
    <span className="inline-block h-1.5 w-16 overflow-hidden rounded-full bg-slate-200 align-middle dark:bg-white/10">
      <span className="block h-full rounded-full" style={{ width: `${pct}%`, background: color }} />
    </span>
  );
}

function MetricRow({ m }: { m: MetricResult }) {
  const color = CAT_COLOR[m.category] ?? "#94a3b8";
  return (
    <details className="group rounded-xl border border-slate-200/70 bg-white/70 transition open:shadow-sm dark:border-white/10 dark:bg-white/5">
      <summary className="flex cursor-pointer list-none items-center gap-3 p-3 text-sm">
        <span className={"text-xs " + (m.status === "pass" ? "text-fair-a" : "text-slate-300 dark:text-slate-600")}>
          {m.status === "pass" ? "●" : "○"}
        </span>
        <span className="min-w-0 flex-1">
          <span className="font-mono text-[11px] text-slate-400">{m.metric_identifier}</span>{" "}
          <span className="font-medium text-slate-700 dark:text-slate-200">{m.metric_name}</span>
        </span>
        <Bar pct={m.percent} color={color} />
        <span className="w-12 text-right text-xs tabular-nums text-slate-500">{m.earned}/{m.total}</span>
        <span className="text-slate-300 transition group-open:rotate-180 dark:text-slate-600">⌄</span>
      </summary>
      <div className="space-y-3 border-t border-slate-200/70 p-3 text-sm dark:border-white/10">
        <div className="flex flex-wrap items-center gap-3 text-xs text-slate-500">
          <span>FAIR level <b>{m.maturity}</b> of 3</span>
          <MaturityBadge maturity={m.maturity} />
        </div>
        {m.tests.length > 0 && (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="text-slate-400">
                <tr>
                  <th className="py-1 pr-2 font-medium">Test</th>
                  <th className="pr-2 font-medium">Name</th>
                  <th className="pr-2 font-medium">Score</th>
                  <th className="pr-2 font-medium">Mat.</th>
                  <th className="font-medium">Result</th>
                </tr>
              </thead>
              <tbody>
                {m.tests.map((t) => (
                  <tr key={t.id} className="border-t border-slate-100 dark:border-white/5">
                    <td className="py-1 pr-2 font-mono text-slate-500">{t.id}</td>
                    <td className="pr-2">{t.name}</td>
                    <td className="pr-2 tabular-nums">{t.score}</td>
                    <td className="pr-2 tabular-nums">{t.maturity}</td>
                    <td className={t.status === "pass" ? "text-fair-a" : "text-slate-400"}>{t.status}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
        {m.output != null && (
          <pre className="overflow-x-auto rounded-lg bg-slate-50 p-2 text-[11px] dark:bg-white/5">
            {JSON.stringify(m.output, null, 2)}
          </pre>
        )}
      </div>
    </details>
  );
}

export function MetricsAccordion({ results }: { results: MetricResult[] }) {
  return (
    <div className="space-y-5">
      {CAT_KEYS.map((key) => {
        const rs = results.filter((r) => r.category === key);
        if (!rs.length) return null;
        return (
          <div key={key}>
            <h3 className="mb-2 flex items-center gap-2 text-xs font-semibold uppercase tracking-wide text-slate-400">
              <span className="h-2.5 w-2.5 rounded-full" style={{ background: CAT_COLOR[key] }} />
              {CAT_LABEL[key]}
            </h3>
            <div className="space-y-1.5">
              {rs.map((m) => <MetricRow key={m.metric_identifier} m={m} />)}
            </div>
          </div>
        );
      })}
    </div>
  );
}
