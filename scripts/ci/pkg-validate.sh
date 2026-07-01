#!/usr/bin/env bash
set -euo pipefail

./scripts/ci/build.sh

echo "📦 Packing tarball..."
rm -f ./*.tgz
bun pm pack
shopt -s nullglob
tarballs=(./*.tgz)
tarball="${tarballs[0]:-}"
[[ -f ${tarball} ]] || {
  echo "❌ no tarball produced" >&2
  exit 1
}

echo "🔎 Linting package shape (publint)..."
./node_modules/.bin/publint --strict

echo "🔎 Checking type resolvability (attw)..."
./node_modules/.bin/attw "${tarball}"

echo "✅ Package validation passed"
