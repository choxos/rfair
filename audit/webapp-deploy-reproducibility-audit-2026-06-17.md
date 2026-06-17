# Web App Deploy Reproducibility Audit

Date: 2026-06-17
Branch: `webapp`
Scope: web app deployment workflow and release metadata

## Finding

The web app deploy workflow still installed dependencies with `npm install`,
which can rewrite or reinterpret the lockfile during CI. Earlier this was a
workaround for platform-specific optional native dependencies, but the current
lockfile now supports `npm ci` locally.

The web app README also pointed to `.github/workflows/deploy-app.yaml`, while
the actual workflow file is `.github/workflows/deploy.yaml`.

## Implementation

- Switched the deploy workflow install step to lockfile-exact `npm ci`.
- Added `cache-dependency-path: package-lock.json` to make the npm cache key
  explicit.
- Added a lockfile guard before Node setup so CI fails clearly if the webapp
  branch ever loses `package-lock.json`.
- Updated the README to reference the actual workflow filename.
- Bumped the web app package version to `2.2.6`.

## Verification

- `npm ci`
- `npm audit --audit-level=moderate`
- `npm test`
- `npm run build`

All local checks passed. `npm ci` installed from the committed lockfile and
reported 0 vulnerabilities. The explicit audit also reported 0 vulnerabilities.
