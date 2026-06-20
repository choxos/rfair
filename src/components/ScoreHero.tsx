import { useState } from "react";
import type { Assessment } from "../lib/types";
import { asJsonLd } from "../lib/jsonld";
import { Sunburst } from "./Sunburst";
import { MaturityBadge } from "./MaturityBadge";

function Action({ onClick, children }: { onClick: () => void; children: React.ReactNode }) {
  return (
    <button
      onClick={onClick}
      className="inline-flex items-center gap-1.5 rounded-lg border border-slate-200 bg-white/60 px-3 py-1.5 text-xs font-medium text-slate-600 transition hover:border-fair-f hover:text-fair-f dark:border-white/10 dark:bg-white/5 dark:text-slate-300 dark:hover:text-fair-a"
    >
      {children}
    </button>
  );
}

export function ScoreHero({ result }: { result: Assessment }) {
  const [flash, setFlash] = useState<string | null>(null);
  const fair = result.summary.find((s) => s.category === "FAIR");
  const resolved = result.resolved_url ?? result.id;

  const note = (msg: string) => {
    setFlash(msg);
    window.setTimeout(() => setFlash(null), 1600);
  };

  const save = (text: string, name: string, type: string) => {
    const blob = new Blob([text], { type });
    const a = document.createElement("a");
    a.href = URL.createObjectURL(blob);
    a.download = name;
    a.click();
    URL.revokeObjectURL(a.href);
  };
  const download = () => save(JSON.stringify(result, null, 2), "rfair-result.json", "application/json");
  const downloadJsonLd = () => save(asJsonLd(result), "rfair-result.jsonld", "application/ld+json");
  const copyJson = async () => {
    await navigator.clipboard.writeText(JSON.stringify(result, null, 2));
    note("JSON copied");
  };
  const share = async () => {
    const url = `${location.origin}${location.pathname}?doi=${encodeURIComponent(result.id)}`;
    await navigator.clipboard.writeText(url);
    note("Link copied");
  };

  return (
    <section className="card animate-[rise_.5s_cubic-bezier(.22,1,.36,1)] p-5 sm:p-6">
      <div className="flex flex-col items-center gap-6 sm:flex-row sm:items-center">
        <Sunburst results={result.results} summary={result.summary} />
        <div className="min-w-0 flex-1 text-center sm:text-left">
          <div className="text-xs font-semibold uppercase tracking-wider text-slate-400">
            Assessed object
          </div>
          <a href={resolved} target="_blank" rel="noreferrer"
            className="block truncate text-sm font-medium text-fair-f hover:underline dark:text-fair-a">
            {resolved}
          </a>
          <div className="mt-2 flex flex-wrap items-center justify-center gap-x-4 gap-y-1 text-xs text-slate-500 sm:justify-start dark:text-slate-400">
            {fair && (
              <span>
                <b className="text-slate-700 dark:text-slate-200">{fair.earned}</b> of{" "}
                <b className="text-slate-700 dark:text-slate-200">{fair.total}</b> points
              </span>
            )}
            {fair && (
              <span className="inline-flex items-center gap-1">
                maturity <MaturityBadge maturity={fair.maturity} />
              </span>
            )}
            <span>metrics v{result.metric_version}</span>
          </div>
          <div className="mt-4 flex flex-wrap items-center justify-center gap-2 sm:justify-start">
            <Action onClick={download}>↓ JSON</Action>
            <Action onClick={downloadJsonLd}>↓ JSON-LD</Action>
            <Action onClick={copyJson}>⧉ Copy JSON</Action>
            <Action onClick={share}>🔗 Share link</Action>
            {flash && <span className="text-xs font-medium text-fair-a">{flash}</span>}
          </div>
        </div>
      </div>
    </section>
  );
}
