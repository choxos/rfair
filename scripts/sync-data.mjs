// Refresh the reference JSON under public/data from the R package's
// single-source-of-truth (inst/extdata/web, built by the data-raw pipeline).
//
// The web app lives on its own `webapp` branch, so the R package is not present
// by default. public/data is committed here so the app builds standalone; run
// this only to refresh it, with the package checked out alongside. Point at the
// package with RFUJI_PKG, or use a sibling/parent git worktree:
//   git worktree add webapp webapp
//   (cd webapp && npm run sync-data)
//
// or:
//   git worktree add ../rfuji-pkg main
//   RFUJI_PKG=../rfuji-pkg npm run sync-data
import { cpSync, mkdirSync, readdirSync, existsSync } from "node:fs";
import { dirname, join, isAbsolute, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, "..");

function packageRoot(candidate) {
  const d = isAbsolute(candidate) ? candidate : resolve(root, candidate);
  return existsSync(join(d, "DESCRIPTION")) && existsSync(join(d, "inst", "extdata", "web"))
    ? d
    : null;
}

const candidates = process.env.RFUJI_PKG
  ? [process.env.RFUJI_PKG]
  : [
      join(root, ".."),          // ./webapp worktree inside the package checkout
      join(root, "..", "rfuji"), // sibling clone fallback
      join(root, "..", "rfuji-pkg"),
    ];
const pkg = candidates.map(packageRoot).find(Boolean);
const src = pkg ? join(pkg, "inst", "extdata", "web") : "";
const dest = join(root, "public", "data");

if (!pkg || !existsSync(src)) {
  console.warn(
    `sync-data: package source not found; using the committed public/data.\n` +
      "Set RFUJI_PKG to the R package root to refresh (see scripts/sync-data.mjs)."
  );
  process.exit(0);
}

mkdirSync(dest, { recursive: true });
for (const f of readdirSync(src)) {
  if (f.endsWith(".json")) {
    cpSync(join(src, f), join(dest, f));
    console.log("synced", f);
  }
}
