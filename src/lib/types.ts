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
  metricSets?: Record<string, { config?: Record<string, unknown>; metrics: any[] }>;
  licenses: { licenseId: string; name: string; detailsUrl: string; isOsiApproved: boolean; seeAlso: string[] }[];
  formats: { science: string[]; long_term: string[]; open: string[] };
  access: { id: string; uri: string; access_condition: string }[];
  protocols: Record<string, { name?: string; auth?: string }>;
}

/** Available metric sets the browser engine can score. */
export type MetricVersion =
  | "0.8"
  | "0.5"
  | "0.5ssv2"
  | "0.5ss"
  | "0.5env"
  | "0.7_software"
  | "0.7_software_cessda"
  | "0.6a2a"
  | "0.4"
  | "0.3"
  | "0.2";

export const METRIC_SETS: { value: MetricVersion; label: string; short: string }[] = [
  { value: "0.8", label: "FsF Metrics v0.8 - Domain agnostic", short: "Data v0.8" },
  { value: "0.5", label: "FsF Metrics v0.5 - Domain agnostic", short: "Data v0.5" },
  { value: "0.5ssv2", label: "FsF Metrics v0.5 - Social Sciences full (beta)", short: "Social Sciences" },
  { value: "0.5ss", label: "FsF Metrics v0.5 - Social Sciences part (beta)", short: "Social Sciences part" },
  { value: "0.5env", label: "FsF Metrics v0.5 - Earth & Environmental Sciences (alpha)", short: "Earth & Env" },
  { value: "0.7_software", label: "FRSM Metrics v0.7 - Software", short: "Software" },
  { value: "0.7_software_cessda", label: "FRSM Metrics v0.7 - Software CESSDA", short: "Software CESSDA" },
  { value: "0.6a2a", label: "FsF Metrics v0.6 A2A draft", short: "A2A" },
  { value: "0.4", label: "FsF Metrics v0.4 legacy", short: "v0.4" },
  { value: "0.3", label: "FsF Metrics v0.3 legacy", short: "v0.3" },
  { value: "0.2", label: "FsF Metrics v0.2 legacy", short: "v0.2" },
];

export const SOFTWARE_METRIC_VERSIONS = new Set<MetricVersion>(["0.7_software", "0.7_software_cessda"]);

export type MetadataServiceType =
  | "oai_pmh"
  | "ogc_csw"
  | "sparql"
  | "dcat"
  | "schema_org"
  | "datacite"
  | "crossref"
  | "signposting"
  | "typed_links"
  | "ro_crate"
  | "ckan"
  | "other";

export const METADATA_SERVICE_TYPES: { value: MetadataServiceType; label: string }[] = [
  { value: "oai_pmh", label: "OAI-PMH" },
  { value: "ogc_csw", label: "OGC CSW" },
  { value: "sparql", label: "SPARQL" },
  { value: "dcat", label: "DCAT catalog/document" },
  { value: "schema_org", label: "schema.org JSON-LD" },
  { value: "datacite", label: "DataCite API/content negotiation" },
  { value: "crossref", label: "Crossref API" },
  { value: "signposting", label: "Signposting" },
  { value: "typed_links", label: "Typed links" },
  { value: "ro_crate", label: "RO-Crate metadata" },
  { value: "ckan", label: "CKAN API" },
  { value: "other", label: "Other metadata document" },
];

export interface AssessmentOptions {
  useDatacite: boolean;
  metadataServiceEndpoint: string;
  metadataServiceType: MetadataServiceType;
}

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
  has_spdx_license: boolean;
  has_metadata_spdx_license: boolean;
  has_open_api: boolean;
  has_machine_readable_api: boolean;
  has_data_format_docs: boolean;
  has_open_data_formats: boolean;
  has_schema_reference: boolean;
}
