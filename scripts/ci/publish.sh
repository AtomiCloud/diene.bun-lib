#!/usr/bin/env bash
set -euo pipefail

[ -z "${NPM_API_KEY:-}" ] && echo "❌ NPM_API_KEY must be set (from the NPM_API_KEY secret)" >&2 && exit 1
[ -z "${GITHUB_REF_NAME:-}" ] && echo "❌ GITHUB_REF_NAME must be set (the pushed tag, e.g. v1.2.3)" >&2 && exit 1

VERSION="${GITHUB_REF_NAME#v}"

./scripts/ci/build.sh

# The release commit already carries the stamped version — verify instead of mutating.
echo "🔎 Verifying package.json is stamped with ${VERSION}..."
[ "$(jq -r .version package.json)" != "${VERSION}" ] && echo "❌ package.json version ($(jq -r .version package.json)) != tag version (${VERSION})" >&2 && exit 1

echo "🔐 Writing npm auth token..."
printf '//registry.npmjs.org/:_authToken=%s\n' "${NPM_API_KEY}" >.npmrc

echo "🚀 Publishing version ${VERSION}..."
bun publish --access public --tolerate-republish

echo "✅ Published version ${VERSION}"
