#!/usr/bin/env bash
set -euo pipefail

./scripts/ci/build.sh

echo "📦 Packing tarball..."
bun pm pack --filename pkg.tgz

echo "🔎 Linting package shape (publint)..."
./node_modules/.bin/publint --strict

echo "🔎 Checking type resolvability (attw)..."
./node_modules/.bin/attw pkg.tgz

echo "✅ Package validation passed"
