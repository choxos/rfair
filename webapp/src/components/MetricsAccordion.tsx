import type { MetricResult } from "../lib/types";
import { MaturityBadge } from "./CategoryCards";

const CATS = [
  { key: "F", label: "Findable" },
  { key: "A", label: "Accessible" },
  { key: "I", label: "Interoperable" },
  { key: "R", label: "Reusable" },
];

function MetricRow({ m }: { m: MetricResult }) {
  return (
    <details className="rounded border bg-white">
      <summary className="flex cursor-pointer items-center justify-between gap-2 p-2 text-sm">
        <span className="font-medium text-slate-700">
          <span className="font-mono text-xs text-slate-500">{m.metric_identifier}</span> {m.metric_name}
        </span>
        <span className="flex items-center gap-2 whitespace-nowrap">
          <span className="text-slate-500">{m.earned}/{m.total}</span>
          <span className={m.status === "pass" ? "text-green-600" : "text-rose-400"}>
            {m.status === "pass" ? "✓" : "○"}
          </span>
        </span>
      </summary>
      <div className="space-y-2 border-t p-3 text-sm">
        <div className="flex items-center gap-3">
          <span>FAIR level: <b>{m.maturity} of 3</b></span>
          <MaturityBadge maturity={m.maturity} />
          <span>Score: <b>{m.earned} of {m.total}</b></span>
        </div>
        {m.tests.length > 0 && (
          <table className="w-full text-left text-xs">
            <thead className="text-slate-500">
              <tr><th className="py-1">Test</th><th>Name</th><th>Score</th><th>Maturity</th><th>Result</th></tr>
            </thead>
            <tbody>
              {m.tests.map((t) => (
                <tr key={t.id} className="border-t">
                  <td className="py-1 font-mono">{t.id}</td>
                  <td>{t.name}</td>
                  <td>{t.score}</td>
                  <td>{t.maturity}</td>
                  <td className={t.status === "pass" ? "text-green-600" : "text-slate-400"}>{t.status}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
        {m.output != null && (
          <pre className="overflow-x-auto rounded bg-slate-50 p-2 text-xs">{JSON.stringify(m.output, null, 2)}</pre>
        )}
      </div>
    </details>
  );
}

export function MetricsAccordion({ results }: { results: MetricResult[] }) {
  return (
    <div className="space-y-4">
      {CATS.map(({ key, label }) => {
        const rs = results.filter((r) => r.category === key);
        if (!rs.length) return null;
        return (
          <div key={key}>
            <h3 className="mb-2 text-sm font-semibold uppercase tracking-wide text-slate-500">{label}</h3>
            <div className="space-y-1.5">{rs.map((m) => <MetricRow key={m.metric_identifier} m={m} />)}</div>
          </div>
        );
      })}
    </div>
  );
}
