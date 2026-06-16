const EXAMPLES: { label: string; id: string }[] = [
  { label: "Zenodo", id: "https://doi.org/10.5281/zenodo.8347772" },
  { label: "PANGAEA", id: "https://doi.org/10.1594/PANGAEA.908011" },
  { label: "Dryad", id: "https://doi.org/10.5061/dryad.q573n5tj9" },
  { label: "GitHub repo", id: "https://github.com/pangaea-data-publisher/fuji" },
];

export function SearchPanel({
  pid,
  setPid,
  onRun,
  loading,
  ready,
}: {
  pid: string;
  setPid: (s: string) => void;
  onRun: (id?: string) => void;
  loading: boolean;
  ready: boolean;
}) {
  return (
    <section className="mx-auto max-w-3xl text-center">
      <h1 className="bg-gradient-to-br from-slate-900 to-slate-500 bg-clip-text text-3xl font-extrabold tracking-tight text-transparent sm:text-4xl dark:from-white dark:to-slate-400">
        How FAIR is your research data?
      </h1>
      <p className="mx-auto mt-3 max-w-xl text-sm text-slate-500 dark:text-slate-400">
        Paste a DOI, persistent identifier, or URL. rfuji scores it against the
        F-UJI FAIR metrics, entirely in your browser.
      </p>

      <div className="card mt-6 p-2 text-left shadow-md">
        <div className="flex flex-col gap-2 sm:flex-row">
          <input
            className="min-w-0 flex-1 rounded-xl bg-transparent px-4 py-3 text-sm outline-none placeholder:text-slate-400"
            value={pid}
            onChange={(e) => setPid(e.target.value)}
            onKeyDown={(e) => e.key === "Enter" && onRun()}
            placeholder="https://doi.org/10.5281/zenodo.8347772"
            aria-label="Research data object identifier"
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
      </div>

      <div className="mt-3 flex flex-wrap items-center justify-center gap-2 text-xs">
        <span className="text-slate-400">Try:</span>
        {EXAMPLES.map((ex) => (
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
