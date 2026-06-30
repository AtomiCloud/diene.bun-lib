#!/usr/bin/env bash
set -euo pipefail

# Builds the publishable library (ESM + CJS + flat types) into dist/.
# Pure build only — no CI setup (bun install) and no packaging assertions; those
# CI-only concerns live in scripts/ci/build.sh, which delegates here. This keeps the
# local `pls build` task free of CI-script coupling (see docs/developer/standard/taskfile.md).

ESM="dist/index.js"
CJS="dist/index.cjs"
DTS="dist/index.d.ts"
DCTS="dist/index.d.cts"

echo "🧹 Cleaning dist/..."
rm -rf dist

echo "🔨 Building ESM bundle (ioredis external)..."
bun build ./src/index.ts --outfile "${ESM}" --format esm --target node --external ioredis

echo "🔨 Building CJS bundle (ioredis external)..."
bun build ./src/index.ts --outfile "${CJS}" --format cjs --target node --external ioredis

echo "🔠 Type-checking declarations (tsc)..."
# tsc both type-checks the build config and proves declarations emit cleanly, but its
# per-file output is throwaway: dts-bundle-generator (below) is the sole owner of dist/'s
# declarations. Emit to a temp dir so no per-file .d.ts leaks into the published tarball
# and no src/-subdirectory names are hardcoded for cleanup.
tsc_out="$(mktemp -d)"
trap 'rm -rf "${tsc_out}"' EXIT
bunx tsc -p tsconfig.build.json --outDir "${tsc_out}"

echo "🔠 Bundling flat type declarations..."
# Single flat declaration (no internal relative imports → resolvable under node16 from
# both ESM and CJS callers).
bunx dts-bundle-generator -o "${DTS}" src/index.ts --no-check
# Provide a CJS-flavoured declaration for the "require" condition (avoids attw FalseESM).
cp "${DTS}" "${DCTS}"

# Assert all four artifacts exist (missing-artifact guard, spec AC6/FR6). Inlined
# linear loop — a 4-item postcondition check with a single caller earns no separate
# script (keeps the build self-contained, no indirection jump for maintainers).
echo "🔎 Asserting build artifacts..."
missing=0
for artifact in "${ESM}" "${CJS}" "${DTS}" "${DCTS}"; do
  if [[ ! -f ${artifact} ]]; then
    echo "❌ Build artifact missing: ${artifact}" >&2
    missing=1
  fi
done
if [[ ${missing} -ne 0 ]]; then
  echo "❌ One or more build artifacts are missing." >&2
  exit 1
fi
echo "✅ All build artifacts present: ${ESM} ${CJS} ${DTS} ${DCTS}"
