import { useCountUp } from "../lib/hooks";
import { scoreTone } from "../lib/fair";

/** Large animated radial gauge for the overall FAIR score. */
export function Gauge({ percent, size = 168 }: { percent: number; size?: number }) {
  const v = useCountUp(percent);
  const stroke = 13;
  const r = (size - stroke) / 2;
  const c = 2 * Math.PI * r;
  const tone = scoreTone(percent);
  const dash = (v / 100) * c;

  return (
    <div className="relative grid place-items-center" style={{ width: size, height: size }}>
      <svg width={size} height={size} className="-rotate-90">
        <circle cx={size / 2} cy={size / 2} r={r} fill="none"
          className="stroke-slate-200/80 dark:stroke-white/10" strokeWidth={stroke} />
        <circle cx={size / 2} cy={size / 2} r={r} fill="none" stroke={tone}
          strokeWidth={stroke} strokeLinecap="round"
          strokeDasharray={`${dash} ${c}`} />
      </svg>
      <div className="absolute text-center">
        <div className="text-4xl font-extrabold tabular-nums" style={{ color: tone }}>
          {Math.round(v)}<span className="text-xl font-bold">%</span>
        </div>
        <div className="text-[11px] font-semibold uppercase tracking-widest text-slate-400">
          FAIR
        </div>
      </div>
    </div>
  );
}

/** Small progress ring used inside the category cards. */
export function Ring({ percent, color, size = 56 }: { percent: number; color: string; size?: number }) {
  const stroke = 6;
  const r = (size - stroke) / 2;
  const c = 2 * Math.PI * r;
  const dash = (Math.max(0, Math.min(100, percent)) / 100) * c;
  return (
    <svg width={size} height={size} className="-rotate-90 shrink-0">
      <circle cx={size / 2} cy={size / 2} r={r} fill="none"
        className="stroke-slate-200 dark:stroke-white/10" strokeWidth={stroke} />
      <circle cx={size / 2} cy={size / 2} r={r} fill="none" stroke={color}
        strokeWidth={stroke} strokeLinecap="round"
        strokeDasharray={`${dash} ${c}`}
        style={{ transition: "stroke-dasharray .9s cubic-bezier(.22,1,.36,1)" }} />
      <text x="50%" y="50%" transform={`rotate(90 ${size / 2} ${size / 2})`}
        dominantBaseline="central" textAnchor="middle"
        className="fill-slate-700 dark:fill-slate-200 text-[12px] font-bold">
        {Math.round(percent)}
      </text>
    </svg>
  );
}
