import type { ReactNode } from "react";
import type { AccessInfo, HygieneInfo, LicenseReuse, Reference, TlcRow } from "../lib/types";

function Card({ title, children }: { title: string; children: ReactNode }) {
  return (
    <div className="card p-4">
      <h3 className="mb-2 text-xs font-semibold uppercase tracking-wide text-slate-400">{title}</h3>
      {children}
    </div>
  );
}

function Check({ ok }: { ok: boolean }) {
  return <span className={ok ? "text-fair-a" : "text-slate-300 dark:text-slate-600"}>{ok ? "✓" : "○"}</span>;
}

export function ReusePanel({ reuse, access, hygiene, tlc }: { reuse: LicenseReuse[]; access: AccessInfo; hygiene: HygieneInfo; tlc: TlcRow[] }) {
  return (
    <div className="grid gap-3 md:grid-cols-2 lg:grid-cols-4">
      <Card title="License reusability">
        {reuse.length ? (
          <ul className="space-y-2 text-sm">
            {reuse.map((l, i) => (
              <li key={i}>
                <span className="block break-all font-mono text-[11px] text-slate-400">{l.license}</span>
                <div className={l.is_open ? "font-medium text-fair-a" : "font-medium text-fair-r"}>
                  {l.category} <span className="text-slate-400">· {l.rdp_category}</span>
                </div>
              </li>
            ))}
          </ul>
        ) : <p className="text-sm text-slate-400">No license detected.</p>}
      </Card>

      <Card title="FAIR-TLC">
        <ul className="space-y-1 text-sm">
          {tlc.map((t, i) => (
            <li key={i} className="flex items-center justify-between gap-2">
              <span className="text-slate-600 dark:text-slate-300">{t.indicator}</span>
              <Check ok={t.met} />
            </li>
          ))}
        </ul>
        <p className="mt-2 text-[11px] text-slate-400">Traceable · Licensed · Connected (Haendel et al.)</p>
      </Card>

      <Card title="Access & sensitivity">
        <p className="text-sm">Access level: <b>{access.access}</b></p>
        <div className="my-2 flex flex-wrap gap-1.5">
          {access.controlled_access && <span className="rounded-full bg-amber-500/90 px-2 py-0.5 text-[11px] font-medium text-white">controlled-access</span>}
          {access.sensitive && <span className="rounded-full bg-fair-r px-2 py-0.5 text-[11px] font-medium text-white">sensitive</span>}
          {!access.controlled_access && !access.sensitive && <span className="text-xs text-slate-400">no flags</span>}
        </div>
        <p className="text-xs text-slate-500 dark:text-slate-400">{access.note}</p>
      </Card>

      <Card title="Identifier hygiene">
        {hygiene.hygiene_ok ? (
          <span className="inline-flex items-center gap-1.5 rounded-full bg-fair-a/90 px-2.5 py-0.5 text-xs font-medium text-white">
            <Check ok /> no issues
          </span>
        ) : (
          <ul className="list-disc space-y-1 pl-4 text-xs text-fair-r">
            {hygiene.issues.map((s, i) => <li key={i}>{s}</li>)}
          </ul>
        )}
        {hygiene.scheme && (
          <p className="mt-2 text-[11px] text-slate-400">
            scheme: {hygiene.scheme} · {hygiene.is_persistent ? "persistent" : "non-persistent"}
          </p>
        )}
      </Card>
    </div>
  );
}

export function HarvestedMetadata({ metadata, sources }: { metadata: Reference; sources: { source: string; method: string }[] }) {
  return (
    <Card title="Harvested metadata">
      <div className="mb-2 flex flex-wrap gap-1.5">
        {sources.length ? sources.map((s, i) => (
          <span key={i} className="rounded-full border border-slate-200 px-2 py-0.5 text-[11px] text-slate-500 dark:border-white/10 dark:text-slate-400">
            {s.source} <span className="text-slate-400">· {s.method}</span>
          </span>
        )) : <span className="text-xs text-slate-400">no sources</span>}
      </div>
      <pre className="max-h-96 overflow-auto rounded-lg bg-slate-50 p-3 text-[11px] leading-relaxed dark:bg-white/5">
        {JSON.stringify(metadata, null, 2)}
      </pre>
    </Card>
  );
}
