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
  licenses: { licenseId: string; name: string; detailsUrl: string; isOsiApproved: boolean; seeAlso: string[] }[];
  formats: { science: string[]; long_term: string[]; open: string[] };
  access: { id: string; uri: string; access_condition: string }[];
  protocols: Record<string, { name?: string; auth?: string }>;
}
