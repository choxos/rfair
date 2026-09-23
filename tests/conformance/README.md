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

## Scheduled runs

`.github/workflows/conformance.yaml` runs this harness monthly (and on demand)
against the F-UJI Docker image, and uploads the per-metric comparison
(`conformance-v0.8.csv`) and the image digest as a workflow artifact. Set
`CONFORMANCE_OUT` to write the same CSV locally.

## Results

Measured on 2026-09-22 against a locally run F-UJI 4.0.0 (metrics v0.8), five
fixture DOIs, 85 metric comparisons (earned-score match):

| rfair | agreement |
|---|---|
| 0.1.0 (`main`) | 91.8% |
| 0.2.0 | 95.3% |

The remaining differences:

* **FsF-R1.3-02D** (data file format; Zenodo, PANGAEA): F-UJI downloads the
  files and detects their format with Apache Tika; rfair reads the declared
  and served content types.
* **FsF-I2-01M** (semantic vocabularies; PANGAEA, Dryad): F-UJI checks the
  namespaces against its full linked-vocabulary corpus.

An earlier manual run (2026-06-16, F-UJI 4.0.0) measured 94.1% on the Zenodo
DOI alone and 85.3% over PANGAEA and Dryad.

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
