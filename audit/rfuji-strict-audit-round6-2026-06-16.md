# rfuji Strict Audit - Round 6 Webapp Service Validation - 2026-06-16

## Verdict

Round 6 found a follow-on correctness issue in the browser metadata-service
support added in round 5: several service handlers treated any HTTP 200 response
as validated service evidence, even when the payload was not shaped like the
selected protocol or metadata format.

This was narrower than the round-4 request-only evidence bug, but still
score-relevant. A broken service endpoint returning an HTML error page, empty
JSON object, malformed `Link` header, or protocol error could be recorded as
`metadata_service` and contribute to metadata-service evidence.

## Current State Audited

- Package branch audited: `main` after merged PR #12.
- Webapp branch audited: `webapp` after merged PR #13.
- Prior audit artifact reviewed:
  `audit/rfuji-strict-audit-round5-2026-06-16.md`.
- Scope: browser metadata-service validation, false-positive service evidence,
  legacy metric sweep stability, and webapp release metadata.

## Finding Fixed

### High - Some webapp service handlers accepted malformed 200 responses

The webapp correctly avoided scoring request-only metadata service endpoints,
but after a fetch it still accepted some malformed responses too broadly:

- `dcat` could accept any parseable JSON, including `{}`.
- `schema_org` could accept empty raw JSON-LD.
- `oai_pmh` accepted an OAI-PMH error response as service evidence.
- `ogc_csw` accepted arbitrary XML/HTML with HTTP 200.
- `sparql` accepted any HTTP 200 response without verifying SPARQL result JSON.
- `signposting` and `typed_links` accepted a non-empty but unparsable `Link`
  header.
- `datacite`, `crossref`, `ckan`, `ro_crate`, and generic `other` metadata
  document handling lacked minimum response-shape checks.

Fix implemented:

- Added response-shape validation helpers for JSON-LD-like metadata, metadata
  XML, OAI-PMH, SPARQL result JSON, and link headers.
- Service evidence is recorded only when the selected handler sees a protocol-
  or format-shaped response.
- OAI-PMH now requires a record-like `GetRecord` response for the assessed
  identifier; an OAI error response no longer falls back to service-only
  evidence.
- Invalid HTTP 200 responses remain visible as `metadata_service_request`, but
  no longer create `metadata_service` or `metadata_service_fetch` evidence.
- Added a Vitest regression that iterates every exposed metadata-service option
  and verifies malformed responses do not score.
- Bumped the webapp package metadata to `2.2.3`.

## Verification

Passing local gates after the fix:

- `npm test` in `webapp`: 14 passed.
- `npm run typecheck` in `webapp`: passed.
- `npm run build` in `webapp`: passed.
- `Rscript -e 'devtools::test()'`: 204 passed, 1 expected Shiny skip.
- `coderabbit review --agent -t uncommitted`: 0 package/audit findings.
- `coderabbit review --agent -t uncommitted --dir webapp`: rate-limited with
  a 19 minute 58 second wait after prior reviews; local webapp tests,
  typecheck, build, and targeted negative regressions passed.
- Browser engine legacy sweep remained non-zero:
  - `0.8`: 16/26.
  - `0.6a2a`: 5.5/8.
  - `0.5`: 14/24.
  - `0.5ssv2`: 15/24.
  - `0.5ss`: 6/7.
  - `0.5env`: 14/24.
  - `0.4`: 14/25.
  - `0.3`: 18/21.
  - `0.2`: 17/21.

## Remaining Risks

### Medium - Browser service harvesting is still intentionally shallow

The webapp now validates response shape before scoring service evidence, but it
does not fully implement upstream F-UJI harvesting for OAI-PMH, CSW, SPARQL, or
repository-specific APIs. Browser CORS and lightweight parsing remain limiting
factors.

### Low - Runtime UI smoke coverage still missing

Vitest covers the engine and option behavior, but there is still no Playwright
smoke test that clicks every metric version and metadata-service option in the
built UI.

## Bottom Line

The webapp no longer treats arbitrary successful HTTP responses as metadata
service evidence. This keeps the expanded service selector useful without
inflating scores for broken or unrelated endpoints.
