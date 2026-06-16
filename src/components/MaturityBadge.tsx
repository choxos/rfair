import { maturityTag } from "../lib/fair";

export function MaturityBadge({ maturity }: { maturity: number }) {
  const t = maturityTag(maturity);
  return (
    <span
      className="inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-[11px] font-semibold text-white"
      style={{ background: t.color }}
      title={`Maturity level ${t.level} of 3`}
    >
      {t.label}
    </span>
  );
}
