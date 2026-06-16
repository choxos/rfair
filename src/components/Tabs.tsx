export type TabKey = "metrics" | "reuse" | "metadata";

const TABS: { key: TabKey; label: string }[] = [
  { key: "metrics", label: "Metrics" },
  { key: "reuse", label: "Reuse & access" },
  { key: "metadata", label: "Metadata" },
];

export function Tabs({ tab, setTab }: { tab: TabKey; setTab: (t: TabKey) => void }) {
  return (
    <div
      role="tablist"
      aria-label="Result sections"
      className="inline-flex rounded-xl border border-slate-200/70 bg-white/60 p-1 text-sm backdrop-blur-sm dark:border-white/10 dark:bg-white/5"
    >
      {TABS.map((t) => {
        const active = tab === t.key;
        return (
          <button
            key={t.key}
            role="tab"
            aria-selected={active}
            onClick={() => setTab(t.key)}
            className={
              "rounded-lg px-3.5 py-1.5 font-medium transition " +
              (active
                ? "bg-gradient-to-br from-fair-f to-brand-600 text-white shadow-sm"
                : "text-slate-500 hover:text-slate-800 dark:text-slate-400 dark:hover:text-white")
            }
          >
            {t.label}
          </button>
        );
      })}
    </div>
  );
}
