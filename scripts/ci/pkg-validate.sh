#!/usr/bin/env bash
set -euo pipefail

# Package-validation lane (kept out of the fast pre-commit path): build, pack, then check
# the packed manifest/exports shape (publint) and ESM/CJS/types resolvability (attw).
# publint/attw are pinned devDeps, run from node_modules/.bin so the versions are locked.
./scripts/ci/build.sh

rm -f ./*.tgz
bun pm pack
shopt -s nullglob
tarballs=(./*.tgz)
tarball="${tarballs[0]:-}"
[[ -f ${tarball} ]] || {
  echo "❌ no tarball produced" >&2
  exit 1
}

./node_modules/.bin/publint --strict
./node_modules/.bin/attw "${tarball}"
