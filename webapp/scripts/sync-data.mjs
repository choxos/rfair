// Copy the single-source-of-truth reference JSON (built by the R data-raw
// pipeline) from the package into the web app's public/data folder.
import { cpSync, mkdirSync, readdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const src = join(here, "..", "..", "inst", "extdata", "web");
const dest = join(here, "..", "public", "data");

mkdirSync(dest, { recursive: true });
for (const f of readdirSync(src)) {
  if (f.endsWith(".json")) {
    cpSync(join(src, f), join(dest, f));
    console.log("synced", f);
  }
}
