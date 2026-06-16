export type Reference = Record<string, unknown>;

export interface MetricTest {
  id: string;
  name: string;
  score: number;
  maturity: number;
  status: "pass" | "fail";
}

export interface MetricResult {
  id: number;
  metric_identifier: string;
  metric_name: string;
  principle: string;
  category: string;
  earned: number;
  total: number;
  percent: number;
  maturity: number;
  status: "pass" | "fail";
  tests: MetricTest[];
  output?: unknown;
  debug: string[];
}

export interface CategoryScore {
  category: string;
  earned: number;
  total: number;
  percent: number;
  maturity: number;
}

export interface LicenseReuse {
  license: string;
  category: string;
  rdp_category: "permissive" | "copyleft" | "restrictive" | "unknown";
  facilitates_reuse: boolean;
  is_open: boolean;
  permits_commercial: boolean;
  permits_derivatives: boolean;
  share_alike: boolean;
  note: string;
}

export interface TlcRow {
  dimension: "Traceable" | "Licensed" | "Connected";
  indicator: string;
  met: boolean;
}

export interface AccessInfo {
  access: string;
  controlled_access: boolean;
  sensitive: boolean;
  note: string;
}

export interface HygieneInfo {
  scheme: string | null;
  is_persistent: boolean;
  hygiene_ok: boolean;
  issues: string[];
}

export interface Assessment {
  id: string;
  doi: string | null;
  resolved_url: string | null;
  metric_version: string;
  metadata: Reference;
  sources: { source: string; method: string }[];
  results: MetricResult[];
  summary: CategoryScore[];
  reuse: LicenseReuse[];
  access: AccessInfo;
  hygiene: HygieneInfo;
  tlc: TlcRow[];
}

export interface RefData {
  metrics: { config?: Record<string, unknown>; metrics: any[] };
  softwareMetrics: { config?: Record<string, unknown>; metrics: any[] };
  licenses: { licenseId: string; name: string; detailsUrl: string; isOsiApproved: boolean; seeAlso: string[] }[];
  formats: { science: string[]; long_term: string[]; open: string[] };
  access: { id: string; uri: string; access_condition: string }[];
  protocols: Record<string, { name?: string; auth?: string }>;
}

/** Available metric sets the browser engine can score. */
export type MetricVersion = "0.8" | "0.7_software";

export const METRIC_SETS: { value: MetricVersion; label: string; short: string }[] = [
  { value: "0.8", label: "FAIR Data — FsF v0.8", short: "Data" },
  { value: "0.7_software", label: "Research Software — FRSM v0.7", short: "Software" },
];

/** Software signals harvested from a code repository for the FRSM metrics. */
export interface SoftwareSignals {
  identifier?: string;
  version?: string;
  registry_doi?: string;
  name?: string;
  description?: string;
  language?: string;
  topics: string[];
  contributors: number;
  has_license: boolean;
  has_readme: boolean;
  has_citation: boolean;
  has_tests: boolean;
  has_ci: boolean;
  has_requirements: boolean;
  has_docs: boolean;
  has_api: boolean;
}
