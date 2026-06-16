import type { ReactNode } from "react";
import type { AccessInfo, HygieneInfo, LicenseReuse, Reference, TlcRow } from "../lib/types";

function Card({ title, children }: { title: string; children: ReactNode }) {
  return (
    <div className="rounded-lg border bg-white p-3 shadow-sm">
      <h3 className="mb-2 text-sm font-semibold text-slate-700">{title}</h3>
      {children}
    </div>
  );
}

export function ReusePanel({ reuse, access, hygiene, tlc }: { reuse: LicenseReuse[]; access: AccessInfo; hygiene: HygieneInfo; tlc: TlcRow[] }) {
  return (
    <div className="grid gap-3 md:grid-cols-2 lg:grid-cols-4">
      <Card title="License reusability">
        {reuse.length ? (
          <ul className="space-y-1 text-sm">
            {reuse.map((l, i) => (
              <li key={i}>
                <span className="font-mono text-xs">{l.license}</span>
                <div className={l.is_open ? "text-green-700" : "text-rose-600"}>
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
              <span className="text-slate-600">{t.indicator}</span>
              <span className={t.met ? "text-green-600" : "text-slate-300"}>{t.met ? "✓" : "○"}</span>
            </li>
          ))}
        </ul>
        <p className="mt-1 text-xs text-slate-400">Traceable · Licensed · Connected (Haendel et al.)</p>
      </Card>
      <Card title="Access & sensitivity">
        <p className="text-sm">Access level: <b>{access.access}</b></p>
        <div className="my-1 flex gap-1">
          {access.controlled_access && <span className="rounded bg-amber-500 px-2 py-0.5 text-xs text-white">controlled-access</span>}
          {access.sensitive && <span className="rounded bg-rose-500 px-2 py-0.5 text-xs text-white">sensitive</span>}
        </div>
        <p className="text-xs text-slate-500">{access.note}</p>
      </Card>
      <Card title="Identifier hygiene">
        {hygiene.hygiene_ok ? (
          <span className="rounded bg-green-600 px-2 py-0.5 text-xs text-white">no issues</span>
        ) : (
          <ul className="list-disc pl-4 text-xs text-rose-600">{hygiene.issues.map((s, i) => <li key={i}>{s}</li>)}</ul>
        )}
      </Card>
    </div>
  );
}

export function HarvestedMetadata({ metadata, sources }: { metadata: Reference; sources: { source: string; method: string }[] }) {
  return (
    <Card title="Harvested metadata">
      <p className="mb-2 text-xs text-slate-500">
        Sources: {sources.map((s) => `${s.source} (${s.method})`).join(", ") || "none"}
      </p>
      <pre className="max-h-96 overflow-auto rounded bg-slate-50 p-2 text-xs">{JSON.stringify(metadata, null, 2)}</pre>
    </Card>
  );
}
