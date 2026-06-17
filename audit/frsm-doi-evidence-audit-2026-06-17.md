# FRSM DOI Evidence Audit

Date: 2026-06-17
Branch: `webapp`
Scope: browser FRSM scorer, GitHub software harvesting, release/version parity

## Finding

The browser FRSM scorer over-credited `https://github.com/choxos/rfuji` after
the 2.3.0 metadata pass. It reported:

- `0.7_software`: 29/45
- `0.7_software_cessda`: 26/42

The R scorer reported:

- `0.7_software`: 25/45
- `0.7_software_cessda`: 22/42

The difference was not a genuine FAIR improvement. The browser harvester used a
generic DOI regex over the concatenated `codemeta.json` and `CITATION.cff`
contents. That treated the upstream F-UJI DOI in `codemeta.json` `isBasedOn` as
if it were an archived DOI for rfuji itself.

## Implementation

- Restricted browser `registry_doi` extraction to explicit software DOI fields:
  `CITATION.cff` `doi`, and CodeMeta `doi`, `identifier`, `@id`, or `sameAs`.
- Left provenance fields such as `isBasedOn` out of software DOI detection.
- Added a regression test proving that an upstream DOI in `isBasedOn` does not
  create a software registry DOI or persistent related-resource record.
- Added CodeMeta license harvesting for software repositories, so a machine
  readable license in `codemeta.json` supports FRSM-R1.1 and the reuse panel
  even when the GitHub repository API reports `NOASSERTION`.
- Added SPDX URL normalization in the reuse classifier, so
  `https://spdx.org/licenses/MIT.html` is recognized as a permissive open
  software license rather than `custom/unknown`.
- Bumped the web app version from `2.2.3` to `2.2.4`.

## Verification

- `npm test`: pass, 16 tests.
- `npm run build`: pass.
- `scripts/test-engine.mts https://github.com/choxos/rfuji 0.7_software`:
  FAIR 25/45, Findability 11/20, Interoperability 3/7.
- `scripts/test-engine.mts https://github.com/choxos/rfuji 0.7_software_cessda`:
  FAIR 22/42, Findability 10/18, Interoperability 2/6.
- The smoke output now reports `license` as harvested and reuse as
  `open (software)`.

## Result

The honest browser score now matches the R scorer until rfuji has its own
archived software DOI:

- `0.7_software`: 25/45
- `0.7_software_cessda`: 22/42

FRSM-F4 remains unmet until a real persistent metadata record exists for rfuji,
for example a Zenodo DOI minted for a GitHub release.
