# Conformance harness (rfair vs F-UJI)

Measures how closely the native rfair engine matches upstream F-UJI, per metric,
over the fixture identifiers in `identifiers.yaml`. Not run by `R CMD check`
(needs network + a running reference server).

## 1. Start a version-matched reference F-UJI

Use the local fuji clone so the reference uses the same `metrics_v0.8`:

```sh
cd ~/Documents/GitHub/fuji
# install once (Python 3.13): pip install -e .  (or use uv)
python -m fuji_server -c fuji_server/config/server.ini   # serves http://localhost:1071
```

(Or run the official Docker image and map port 1071.)

## 2. Run the harness

```sh
cd ~/Documents/GitHub/rfair
Rscript tests/conformance/run.R                 # all fixtures
Rscript tests/conformance/run.R https://doi.org/10.5281/zenodo.8347772
```

Point at a different reference with `FUJI_ENDPOINT`, and supply
`FUJI_USER`/`FUJI_PASS` if the instance needs HTTP basic auth.

## 3. Read the output

It prints per-metric earned-score agreement and an overall fidelity %.

## Result (historical / manual, not reproduced by CI)

Measured **manually on 2026-06-16** against a locally-run F-UJI 4.0.0 (metrics
v0.8). This is *not* reproduced by CI (no reference server runs in CI), so treat
it as a historical measurement: reproduce it by following steps 1-2 above with a
live F-UJI at `localhost:1071`.

| identifier | exact per-metric agreement |
|---|---|
| Zenodo `10.5281/zenodo.8347772` | **16/17 = 94.1%** |
| PANGAEA + Dryad (2 DOIs) | 29/34 = 85.3% |

The only consistent divergence is **FsF-R1.3-02D** (data file format), which
depends on deeper data-file harvesting (F-UJI uses Tika content detection;
rfair uses HTTP HEAD content-type). This met the ≥85% Phase 1 gate at that time.

The R↔TS parity harness (`parity.R`) compares the R engine against the
TypeScript engine, which lives on the separate **`webapp` branch**. Materialize
it alongside the package first:

```sh
git worktree add webapp webapp
(cd webapp && npm install)        # esbuild is an explicit devDependency there
Rscript tests/conformance/parity.R
```

It last measured 100% R/TS agreement on registry-core metrics. It is not yet
wired into CI as a gate.
