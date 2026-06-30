#!/usr/bin/env bash
set -euo pipefail

# CI build: install pinned deps, then run the shared library build. Package-shape
# validation (publint/attw) lives in the package-validate lane (scripts/ci/pkg-validate.sh).
./scripts/ci/setup.sh
./scripts/local/build.sh
