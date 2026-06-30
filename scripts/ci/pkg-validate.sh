#!/usr/bin/env bash
set -euo pipefail

# Dedicated (slower) package-validation lane: build, pack, then validate the packed
# package's manifest/exports shape (publint) and ESM/CJS/types resolvability (attw).
# Kept out of the fast pre-commit path.

./scripts/ci/build.sh

echo "📦 Packing tarball for validation..."
rm -f ./*.tgz
bun pm pack
# Exactly one tarball exists after the rm + pack above; resolve it via a glob (not ls).
shopt -s nullglob
tarballs=(./*.tgz)
TARBALL="${tarballs[0]:-}"
if [[ -z ${TARBALL} || ! -f ${TARBALL} ]]; then
  echo "❌ Could not locate packed tarball." >&2
  exit 1
fi
echo "✅ Packed: ${TARBALL}"

echo "🔎 Running publint (manifest/exports shape)..."
bunx publint --strict

echo "🔎 Running attw (ESM/CJS/types resolvability)..."
bunx attw "${TARBALL}"

echo "✅ Package validation passed (publint + attw)."
