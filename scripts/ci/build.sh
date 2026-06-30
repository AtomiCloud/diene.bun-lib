#!/usr/bin/env bash
set -euo pipefail

ESM="dist/index.js"
CJS="dist/index.cjs"
DTS="dist/index.d.ts"
DCTS="dist/index.d.cts"

./scripts/ci/setup.sh

# Single build path: the actual ESM/CJS/types build lives in the local helper so that
# `pls build` can reuse it without depending on a CI script (taskfile convention).
./scripts/local/build.sh

echo "📦 Asserting packed tarball contents..."
pack_output="$(bun pm pack --dry-run 2>&1)"
# Raw output replay (not a progress line): printf, not an emoji echo, per shell-scripts.md.
printf '%s\n' "${pack_output}"

# Extract the packed file paths (lines like: "packed 1.82KB dist/index.js").
packed_files="$(printf '%s\n' "${pack_output}" | sed -n 's/^packed [^ ]* //p')"

if [[ -z ${packed_files} ]]; then
  echo "❌ Could not determine packed tarball contents." >&2
  exit 1
fi

# Every packed entry must be dist/**, package.json, README.md or LICENSE — nothing else.
stray=0
while IFS= read -r entry; do
  [[ -z ${entry} ]] && continue
  case "${entry}" in
  dist/* | package.json | README.md | LICENSE | LICENSE.*) ;;
  *)
    echo "❌ Stray file in tarball: ${entry}" >&2
    stray=1
    ;;
  esac
done <<<"${packed_files}"
if [[ ${stray} -ne 0 ]]; then
  echo "❌ Tarball contains files outside the intended publish set." >&2
  exit 1
fi

# Required entries must be present in the tarball.
for required in "${ESM}" "${CJS}" "${DTS}" "${DCTS}" "package.json" "README.md" "LICENSE"; do
  if ! grep -qxF "${required}" <<<"${packed_files}"; then
    echo "❌ Required file missing from tarball: ${required}" >&2
    exit 1
  fi
done
echo "✅ Tarball contents verified (dist/**, package.json, README.md, LICENSE only)."
