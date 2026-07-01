#!/usr/bin/env bash
set -euo pipefail

: "${NPM_API_KEY:?❌ NPM_API_KEY must be set (from the NPM_TOKEN secret)}"
: "${GITHUB_REF_NAME:?❌ GITHUB_REF_NAME must be set (the pushed tag, e.g. v1.2.3)}"

VERSION="${GITHUB_REF_NAME#v}"

./scripts/ci/build.sh

# Restore the manifest and scrub the token on every exit path.
cp package.json package.json.orig
trap 'rm -f .npmrc; mv -f package.json.orig package.json' EXIT

echo "🔖 Stamping version ${VERSION}..."
bun pm pkg set "version=${VERSION}"

echo "🔐 Writing npm auth token..."
printf '//registry.npmjs.org/:_authToken=%s\n' "${NPM_API_KEY}" >.npmrc

echo "🚀 Publishing @atomicloud/bun-lib@${VERSION}..."
bun publish --access public --tolerate-republish

echo "✅ Published @atomicloud/bun-lib@${VERSION}"
