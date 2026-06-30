#!/usr/bin/env bash
set -euo pipefail

# Build the publishable library (dual ESM + CJS bundle + flat type declarations) into dist/.
rm -rf dist
bun build ./src/index.ts --outfile dist/index.js --format esm --target node --external ioredis
bun build ./src/index.ts --outfile dist/index.cjs --format cjs --target node --external ioredis

# Typecheck, then emit one flat .d.ts (resolvable from ESM and CJS); .d.cts mirrors it.
bunx tsc -p tsconfig.json
bunx dts-bundle-generator -o dist/index.d.ts src/index.ts --no-check
cp dist/index.d.ts dist/index.d.cts

for artifact in dist/index.js dist/index.cjs dist/index.d.ts dist/index.d.cts; do
  [[ -f ${artifact} ]] || {
    echo "❌ build artifact missing: ${artifact}" >&2
    exit 1
  }
done
echo "✅ built dist/index.{js,cjs,d.ts,d.cts}"
