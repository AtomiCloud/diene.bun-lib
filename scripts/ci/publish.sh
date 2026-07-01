#!/usr/bin/env bash
set -euo pipefail

[ -z "${NPM_API_KEY:-}" ] && echo "❌ NPM_API_KEY must be set (from the NPM_TOKEN secret)" >&2 && exit 1
[ -z "${GITHUB_REF_NAME:-}" ] && echo "❌ GITHUB_REF_NAME must be set (the pushed tag, e.g. v1.2.3)" >&2 && exit 1

VERSION="${GITHUB_REF_NAME#v}"

./scripts/ci/build.sh

echo "🔖 Stamping version ${VERSION}..."
bun pm pkg set "version=${VERSION}"

echo "🔐 Writing npm auth token..."
printf '//registry.npmjs.org/:_authToken=%s\n' "${NPM_API_KEY}" >.npmrc

echo "🚀 Publishing version ${VERSION}..."
bun publish --access public --tolerate-republish

echo "✅ Published version ${VERSION}"
