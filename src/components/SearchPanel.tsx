import {
  METADATA_SERVICE_TYPES,
  SOFTWARE_METRIC_VERSIONS,
  type AssessmentOptions,
  type MetadataServiceType,
  METRIC_SETS,
  type MetricVersion,
} from "../lib/types";

const DATA_EXAMPLES = [
    { label: "Zenodo", id: "https://doi.org/10.5281/zenodo.8347772" },
    { label: "PANGAEA", id: "https://doi.org/10.1594/PANGAEA.908011" },
    { label: "Dryad", id: "https://doi.org/10.5061/dryad.q573n5tj9" },
    { label: "GitHub repo", id: "https://github.com/pangaea-data-publisher/fuji" },
];
const SOFTWARE_EXAMPLES = [
    { label: "F-UJI", id: "https://github.com/pangaea-data-publisher/fuji" },
    { label: "rfuji", id: "https://github.com/choxos/rfuji" },
    { label: "datacite", id: "https://github.com/datacite/datacite" },
];

export function SearchPanel({
  pid,
  setPid,
  onRun,
  loading,
  ready,
  version,
  setVersion,
  options,
  setOptions,
}: {
  pid: string;
  setPid: (s: string) => void;
  onRun: (id?: string) => void;
  loading: boolean;
  ready: boolean;
  version: MetricVersion;
  setVersion: (v: MetricVersion) => void;
  options: AssessmentOptions;
  setOptions: (o: AssessmentOptions) => void;
}) {
  const software = SOFTWARE_METRIC_VERSIONS.has(version);
  const examples = software ? SOFTWARE_EXAMPLES : DATA_EXAMPLES;
  return (
    <section className="mx-auto max-w-3xl text-center">
      <h1 className="bg-gradient-to-br from-slate-900 to-slate-500 bg-clip-text text-3xl font-extrabold tracking-tight text-transparent sm:text-4xl dark:from-white dark:to-slate-400">
        How FAIR is your {software ? "research software" : "research data"}?
      </h1>
      <p className="mx-auto mt-3 max-w-xl text-sm text-slate-500 dark:text-slate-400">
        {software
          ? "Paste a code repository URL. rfuji scores it against the FRSM (FAIR for Research Software) metrics, in your browser."
          : "Paste a DOI, persistent identifier, or URL. rfuji scores it against the F-UJI FAIR metrics, in your browser."}
      </p>

      <div className="card mt-6 p-2 text-left shadow-md">
        <div className="mb-2 flex items-center gap-2 px-1 pt-1">
          <label htmlFor="metric-set" className="text-xs font-medium text-slate-400">
            Metric set
          </label>
          <select
            id="metric-set"
            value={version}
            onChange={(e) => setVersion(e.target.value as MetricVersion)}
            className="rounded-lg border border-slate-200 bg-white/70 px-2 py-1 text-xs font-medium text-slate-600 outline-none focus:border-fair-f dark:border-white/10 dark:bg-white/5 dark:text-slate-300"
          >
            {METRIC_SETS.map((m) => (
              <option key={m.value} value={m.value}>{m.label}</option>
            ))}
          </select>
        </div>
        <div className="flex flex-col gap-2 sm:flex-row">
          <input
            className="min-w-0 flex-1 rounded-xl bg-transparent px-4 py-3 text-sm outline-none placeholder:text-slate-400"
            value={pid}
            onChange={(e) => setPid(e.target.value)}
            onKeyDown={(e) => e.key === "Enter" && onRun()}
            placeholder={software ? "https://github.com/owner/repo" : "https://doi.org/10.5281/zenodo.8347772"}
            aria-label={software ? "Code repository URL" : "Research data object identifier"}
            autoFocus
          />
          <button
            className="rounded-xl bg-gradient-to-br from-fair-f to-brand-600 px-6 py-3 text-sm font-semibold text-white shadow-sm transition hover:brightness-110 active:scale-[.98] disabled:cursor-not-allowed disabled:opacity-50"
            onClick={() => onRun()}
            disabled={loading || !ready}
          >
            {loading ? "Assessing…" : "Assess"}
          </button>
        </div>
        {!software && (
          <div className="mt-3 rounded-lg border border-slate-200/70 bg-slate-50/70 p-3 dark:border-white/10 dark:bg-white/5">
            <div className="grid gap-3 sm:grid-cols-[1fr_auto]">
              <label className="flex items-center gap-2 text-xs font-medium text-slate-600 dark:text-slate-300">
                <input
                  type="checkbox"
                  checked={options.useDatacite}
                  onChange={(e) => setOptions({ ...options, useDatacite: e.target.checked })}
                  className="h-4 w-4 rounded border-slate-300 text-fair-f focus:ring-fair-f"
                />
                Use DataCite
              </label>
              <select
                value={options.metadataServiceType}
                onChange={(e) => setOptions({ ...options, metadataServiceType: e.target.value as MetadataServiceType })}
                className="rounded-lg border border-slate-200 bg-white px-2 py-1 text-xs font-medium text-slate-600 outline-none focus:border-fair-f dark:border-white/10 dark:bg-slate-900 dark:text-slate-300"
                aria-label="Metadata service type"
              >
                {METADATA_SERVICE_TYPES.map((m) => (
                  <option key={m.value} value={m.value}>{m.label}</option>
                ))}
              </select>
            </div>
            <input
              className="mt-2 w-full min-w-0 rounded-lg border border-slate-200 bg-white px-3 py-2 text-xs outline-none placeholder:text-slate-400 focus:border-fair-f dark:border-white/10 dark:bg-slate-900"
              value={options.metadataServiceEndpoint}
              onChange={(e) => setOptions({ ...options, metadataServiceEndpoint: e.target.value })}
              placeholder="Optional metadata service endpoint"
              aria-label="Metadata service endpoint"
            />
          </div>
        )}
      </div>

      <div className="mt-3 flex flex-wrap items-center justify-center gap-2 text-xs">
        <span className="text-slate-400">Try:</span>
        {examples.map((ex) => (
          <button
            key={ex.id}
            onClick={() => {
              setPid(ex.id);
              onRun(ex.id);
            }}
            disabled={loading || !ready}
            className="rounded-full border border-slate-200 bg-white/60 px-3 py-1 font-medium text-slate-600 transition hover:border-fair-f hover:text-fair-f disabled:opacity-50 dark:border-white/10 dark:bg-white/5 dark:text-slate-300 dark:hover:text-fair-a"
          >
            {ex.label}
          </button>
        ))}
      </div>
    </section>
  );
}
