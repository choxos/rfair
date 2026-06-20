import { CAT_KEYS, CAT_LABEL, CAT_BLURB, CAT_COLOR } from "../lib/fair";

export function EmptyState() {
  return (
    <section className="mx-auto mt-10 max-w-4xl animate-[fade-in_.6s_ease]">
      <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
        {CAT_KEYS.map((k) => (
          <div key={k} className="card p-4">
            <div className="flex items-center gap-2">
              <span className="grid h-7 w-7 place-items-center rounded-lg text-sm font-black text-white"
                style={{ background: CAT_COLOR[k] }}>
                {k}
              </span>
              <span className="text-sm font-semibold">{CAT_LABEL[k]}</span>
            </div>
            <p className="mt-2 text-xs leading-relaxed text-slate-500 dark:text-slate-400">
              {CAT_BLURB[k]}
            </p>
          </div>
        ))}
      </div>
      <p className="mt-5 text-center text-xs text-slate-400">
        Runs entirely in your browser against CORS-enabled registry APIs
        (DataCite, Crossref, GitHub). Nothing is sent to a server. Landing-page
        harvesting is blocked by browser security, so scores can be lower than
        the full R engine{" "}
        <code className="rounded bg-slate-100 px-1 py-0.5 dark:bg-white/10">
          rfair::assess_fair()
        </code>
        .
      </p>
    </section>
  );
}
