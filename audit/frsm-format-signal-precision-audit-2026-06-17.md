# FRSM Format Signal Precision Audit

Date: 2026-06-17
Branch: `main`
Scope: R-side FRSM open-format and schema-reference software signals

## Finding

The previous FRSM evidence scoring patch correctly credited existing OpenAPI and
SPDX evidence, but the R harvester used the same interface-definition signal for
three related concepts:

- API/interface definition present.
- Open data formats documented.
- Schema reference present.

That was acceptable for `rfuji` because its OpenAPI file is a public,
machine-readable contract for JSON/RDF assessment outputs, but it was too broad
for other software repositories. A repository with a GraphQL or Proto interface
could otherwise receive open-data-format credit without an explicit open-format
or schema-format path.

## Implementation

- Kept OpenAPI, Swagger, Proto, and GraphQL detection for API evidence.
- Added separate path-pattern checks for open data-format evidence, including
  OpenAPI/Swagger contracts, JSON-LD, RDF/RDFS, Turtle, CSV/TSV, Parquet,
  Feather, HDF5, NetCDF, XML, and related files.
- Added separate path-pattern checks for schema-reference evidence, including
  OpenAPI/Swagger contracts, JSON Schema, XSD, RDFS, Proto, and GraphQL.
- Bumped the R package version to `2.3.2`.

## Expected Result

The current `rfuji` score remains unchanged because the repository still has a
public OpenAPI contract:

- `0.7_software`: 31/45, F 11/20, I 7/7, R 12/16.
- `0.7_software_cessda`: 27/42, F 10/18, I 6/6, R 10/15.

The broader effect is stricter scoring for other repositories: API evidence no
longer automatically implies open data-format evidence unless the file paths
also match open-format or schema-reference evidence.
