import { useEffect, useState } from "react";
import { loadData } from "./lib/data";
import { assess } from "./lib/engine";
import { useTheme } from "./lib/hooks";
import type { Assessment, MetricVersion, RefData } from "./lib/types";
import { Header } from "./components/Header";
import { SearchPanel } from "./components/SearchPanel";
import { EmptyState } from "./components/EmptyState";
import { ScoreHero } from "./components/ScoreHero";
import { CategoryCards } from "./components/CategoryCards";
import { Tabs, type TabKey } from "./components/Tabs";
import { MetricsAccordion } from "./components/MetricsAccordion";
import { ReusePanel, HarvestedMetadata } from "./components/SidePanels";

function ResultSkeleton() {
  return (
    <div className="space-y-6">
      <div className="skeleton h-44" />
      <div className="grid grid-cols-2 gap-3 lg:grid-cols-4">
        {[0, 1, 2, 3].map((i) => <div key={i} className="skeleton h-28" />)}
      </div>
      <div className="skeleton h-72" />
    </div>
  );
}

const isVersion = (v: string | null): v is MetricVersion => v === "0.8" || v === "0.7_software";

export default function App() {
  const [theme, toggleTheme] = useTheme();
  const [data, setData] = useState<RefData | null>(null);
  const [pid, setPid] = useState("");
  const [version, setVersion] = useState<MetricVersion>("0.8");
  const [result, setResult] = useState<Assessment | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [tab, setTab] = useState<TabKey>("metrics");

  useEffect(() => {
    loadData()
      .then((d) => {
        setData(d);
        const params = new URLSearchParams(location.search);
        const set = params.get("set");
        const ver: MetricVersion = isVersion(set) ? set : "0.8";
        if (isVersion(set)) setVersion(ver);
        const q = params.get("doi");
        if (q) {
          setPid(q);
          void run(q, d, ver);
        }
      })
      .catch((e) => setError(`Failed to load reference data: ${e}`));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  function changeVersion(v: MetricVersion) {
    setVersion(v);
    setResult(null);
    setError(null);
  }

  async function run(id?: string, ref?: RefData, ver?: MetricVersion) {
    const d = ref ?? data;
    const v = ver ?? version;
    const target = (id ?? pid).trim();
    if (!d || !target) return;
    setLoading(true);
    setError(null);
    setResult(null);
    try {
      const r = await assess(target, d, v);
      setResult(r);
      setTab("metrics");
      const u = new URL(location.href);
      u.searchParams.set("doi", target);
      u.searchParams.set("set", v);
      history.replaceState(null, "", u);
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e));
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="flex min-h-screen flex-col">
      <Header theme={theme} onToggle={toggleTheme} />

      <main className="mx-auto w-full max-w-5xl flex-1 px-4 py-8 sm:px-6 sm:py-12">
        <SearchPanel
          pid={pid}
          setPid={setPid}
          onRun={run}
          loading={loading}
          ready={!!data}
          version={version}
          setVersion={changeVersion}
        />

        {error && (
          <div role="alert" className="mx-auto mt-6 max-w-3xl rounded-xl border border-rose-200 bg-rose-50 p-3 text-sm text-rose-700 dark:border-rose-500/30 dark:bg-rose-500/10 dark:text-rose-300">
            {error}
          </div>
        )}

        <div className="mt-8">
          {loading && <ResultSkeleton />}

          {!loading && !result && !error && <EmptyState />}

          {!loading && result && (
            <div className="space-y-6">
              <ScoreHero result={result} />
              <CategoryCards summary={result.summary} />

              <div className="space-y-4">
                <Tabs tab={tab} setTab={setTab} />
                {tab === "metrics" && <MetricsAccordion results={result.results} />}
                {tab === "reuse" && (
                  <ReusePanel reuse={result.reuse} access={result.access} hygiene={result.hygiene} tlc={result.tlc} />
                )}
                {tab === "metadata" && (
                  <HarvestedMetadata metadata={result.metadata} sources={result.sources} />
                )}
              </div>
            </div>
          )}
        </div>
      </main>

      <footer className="border-t border-slate-200/60 py-6 text-center text-xs text-slate-400 dark:border-white/10">
        <p>
          rfuji · a native R implementation of the F-UJI FAIR metrics ·{" "}
          <a className="font-medium text-fair-f hover:underline dark:text-fair-a" href="https://github.com/choxos/rfuji" target="_blank" rel="noreferrer">
            GitHub
          </a>{" "}
          ·{" "}
          <a className="font-medium text-fair-f hover:underline dark:text-fair-a" href="https://choxos.github.io/rfuji/" target="_blank" rel="noreferrer">
            Docs
          </a>
        </p>
      </footer>
    </div>
  );
}
