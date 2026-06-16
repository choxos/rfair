import { useEffect, useState } from "react";
import { loadData } from "./lib/data";
import { assess } from "./lib/engine";
import type { Assessment, RefData } from "./lib/types";
import { Donut } from "./components/Donut";
import { CategoryCards } from "./components/CategoryCards";
import { MetricsAccordion } from "./components/MetricsAccordion";
import { ReusePanel, HarvestedMetadata } from "./components/SidePanels";

type Tab = "metrics" | "reuse" | "metadata";

export default function App() {
  const [data, setData] = useState<RefData | null>(null);
  const [pid, setPid] = useState("https://doi.org/10.5281/zenodo.8347772");
  const [result, setResult] = useState<Assessment | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [tab, setTab] = useState<Tab>("metrics");

  useEffect(() => {
    loadData().then(setData).catch((e) => setError(`Failed to load reference data: ${e}`));
  }, []);

  async function run() {
    if (!data || !pid.trim()) return;
    setLoading(true); setError(null);
    try {
      setResult(await assess(pid, data));
    } catch (e) {
      setError(String(e));
    } finally {
      setLoading(false);
    }
  }

  function download() {
    if (!result) return;
    const blob = new Blob([JSON.stringify(result, null, 2)], { type: "application/json" });
    const a = document.createElement("a");
    a.href = URL.createObjectURL(blob);
    a.download = "rfuji-result.json";
    a.click();
  }

  return (
    <div className="mx-auto max-w-5xl p-4 sm:p-6">
      <header className="mb-6">
        <h1 className="text-3xl font-bold text-fair-dark">rfuji</h1>
        <p className="text-slate-500">Assess the FAIRness of a research data object in your browser.</p>
      </header>

      <div className="rounded-lg border bg-white p-4 shadow-sm">
        <label className="mb-1 block text-sm font-medium">Research data object (DOI / PID / URL)</label>
        <div className="flex gap-2">
          <input
            className="flex-1 rounded border px-3 py-2 text-sm"
            value={pid}
            onChange={(e) => setPid(e.target.value)}
            onKeyDown={(e) => e.key === "Enter" && run()}
            placeholder="https://doi.org/10.5281/zenodo.8347772"
          />
          <button
            className="rounded bg-fair-f px-4 py-2 text-sm font-semibold text-white disabled:opacity-50"
            onClick={run} disabled={loading || !data}
          >
            {loading ? "Assessing…" : "Assess"}
          </button>
        </div>
        <p className="mt-2 text-xs text-slate-400">
          Runs entirely in your browser using CORS-enabled registry APIs (DataCite, Crossref).
          Landing-page harvesting is blocked by browser security, so scores can be lower than the
          full R engine (<code>rfuji::assess_fair()</code>).
        </p>
      </div>

      {error && <div className="mt-4 rounded border border-rose-200 bg-rose-50 p-3 text-sm text-rose-700">{error}</div>}

      {result && (
        <div className="mt-6 space-y-6">
          <div className="flex flex-col items-center gap-6 sm:flex-row sm:items-start">
            <Donut summary={result.summary} results={result.results} />
            <div className="flex-1 space-y-3">
              <div className="text-sm text-slate-500">
                Resolved: <a className="text-fair-f underline" href={result.resolved_url ?? result.id} target="_blank" rel="noreferrer">{result.resolved_url ?? result.id}</a>
              </div>
              <CategoryCards summary={result.summary} />
            </div>
          </div>

          <div>
            <div className="mb-3 flex gap-1 border-b">
              {(["metrics", "reuse", "metadata"] as Tab[]).map((t) => (
                <button
                  key={t}
                  className={`px-3 py-2 text-sm font-medium ${tab === t ? "border-b-2 border-fair-f text-fair-f" : "text-slate-500"}`}
                  onClick={() => setTab(t)}
                >
                  {t === "metrics" ? "Metrics" : t === "reuse" ? "Reuse & access" : "Harvested metadata"}
                </button>
              ))}
              <button className="ml-auto px-3 py-2 text-sm text-green-700" onClick={download}>Download JSON</button>
            </div>
            {tab === "metrics" && <MetricsAccordion results={result.results} />}
            {tab === "reuse" && <ReusePanel reuse={result.reuse} access={result.access} hygiene={result.hygiene} tlc={result.tlc} />}
            {tab === "metadata" && <HarvestedMetadata metadata={result.metadata} sources={result.sources} />}
          </div>
        </div>
      )}

      <footer className="mt-10 text-center text-xs text-slate-400">
        rfuji · native R implementation of the F-UJI FAIR metrics ·{" "}
        <a className="underline" href="https://github.com/choxos/rfuji">GitHub</a>
      </footer>
    </div>
  );
}
