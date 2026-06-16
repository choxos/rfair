// Emit the TS engine's per-metric scores as JSON for one identifier, for the
// R<->TS parity harness (tests/conformance/parity.R). Reads reference data from
// the directory in $RFUJI_DATA.
import { readFileSync } from "node:fs";
import { assess } from "../src/lib/engine";

const DIR = process.env.RFUJI_DATA;
if (!DIR) { console.error("set RFUJI_DATA to the public/data directory"); process.exit(1); }
const read = (f: string) => JSON.parse(readFileSync(`${DIR}/${f}`, "utf8"));
const data: any = {
  metrics: read("metrics_v0.8.json"), licenses: read("licenses.json"),
  formats: read("file_formats.json"), access: read("access_rights.json"),
  protocols: read("standard_protocols.json"),
};
const a = await assess(process.argv[2] ?? "", data);
console.log(JSON.stringify(a.results.map((r: any) => ({ metric: r.metric_identifier, earned: r.earned, total: r.total }))));
