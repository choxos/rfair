export const CAT_KEYS = ["F", "A", "I", "R"] as const;
export type CatKey = (typeof CAT_KEYS)[number];

export const CAT_LABEL: Record<CatKey, string> = {
  F: "Findable",
  A: "Accessible",
  I: "Interoperable",
  R: "Reusable",
};

export const CAT_COLOR: Record<string, string> = {
  F: "#118ab2",
  A: "#06d6a0",
  I: "#f4c430",
  R: "#ef476f",
};

export const CAT_BLURB: Record<CatKey, string> = {
  F: "Has a unique, persistent identifier and rich, indexed metadata.",
  A: "Metadata and data are retrievable over an open, standard protocol.",
  I: "Uses formal, shared vocabularies and links to related resources.",
  R: "Carries a clear license, provenance, and community standards for reuse.",
};

export const MATURITY_LABEL = ["incomplete", "initial", "moderate", "advanced"];
export const MATURITY_COLOR = ["#fb923c", "#eab308", "#84cc16", "#10b981"];

export function maturityTag(m: number) {
  const i = Math.min(3, Math.max(0, Math.round(m)));
  return { label: MATURITY_LABEL[i], color: MATURITY_COLOR[i], level: i };
}

export function scoreTone(pct: number): string {
  if (pct >= 75) return "#10b981";
  if (pct >= 50) return "#84cc16";
  if (pct >= 25) return "#eab308";
  return "#fb923c";
}
