import { useEffect, useState } from "react";
import { loadData } from "./lib/data";
import { assess } from "./lib/engine";
import { useTheme } from "./lib/hooks";
import { METRIC_SETS, METADATA_SERVICE_TYPES } from "./lib/types";
import type { Assessment, AssessmentOptions, MetadataServiceType, MetricVersion, RefData } from "./lib/types";
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

const isVersion = (v: string | null): v is MetricVersion =>
  !!v && METRIC_SETS.some((m) => m.value === v);
const isServiceType = (v: string | null): v is MetadataServiceType =>
  !!v && METADATA_SERVICE_TYPES.some((m) => m.value === v);

export default function App() {
  const [theme, toggleTheme] = useTheme();
  const [data, setData] = useState<RefData | null>(null);
  const [pid, setPid] = useState("");
  const [version, setVersion] = useState<MetricVersion>("0.8");
  const [options, setOptions] = useState<AssessmentOptions>({
    useDatacite: true,
    metadataServiceEndpoint: "",
    metadataServiceType: "oai_pmh",
  });
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
        const serviceType = params.get("service_type");
        const nextOptions: AssessmentOptions = {
          useDatacite: params.get("datacite") !== "0",
          metadataServiceEndpoint: params.get("service") ?? "",
          metadataServiceType: isServiceType(serviceType) ? serviceType : "oai_pmh",
        };
        setOptions(nextOptions);
        const q = params.get("doi");
        if (q) {
          setPid(q);
          void run(q, d, ver, nextOptions);
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

  async function run(id?: string, ref?: RefData, ver?: MetricVersion, opts?: AssessmentOptions) {
    const d = ref ?? data;
    const v = ver ?? version;
    const o = opts ?? options;
    const target = (id ?? pid).trim();
    if (!d || !target) return;
    setLoading(true);
    setError(null);
    setResult(null);
    try {
      const r = await assess(target, d, v, o);
      setResult(r);
      setTab("metrics");
      const u = new URL(location.href);
      u.searchParams.set("doi", target);
      u.searchParams.set("set", v);
      u.searchParams.set("datacite", o.useDatacite ? "1" : "0");
      if (o.metadataServiceEndpoint.trim()) {
        u.searchParams.set("service", o.metadataServiceEndpoint.trim());
        u.searchParams.set("service_type", o.metadataServiceType);
      } else {
        u.searchParams.delete("service");
        u.searchParams.delete("service_type");
      }
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
          options={options}
          setOptions={setOptions}
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
          rfair · a native R implementation of the F-UJI FAIR metrics ·{" "}
          <a className="font-medium text-fair-f hover:underline dark:text-fair-a" href="https://github.com/choxos/rfair" target="_blank" rel="noreferrer">
            GitHub
          </a>{" "}
          ·{" "}
          <a className="font-medium text-fair-f hover:underline dark:text-fair-a" href="https://choxos.github.io/rfair/" target="_blank" rel="noreferrer">
            Docs
          </a>
        </p>
      </footer>
    </div>
  );
}
