#!/usr/bin/env bash
set -euo pipefail

# Publish the library to npm on a v*.*.* tag (Bun-only). Auth via NPM_API_KEY (from the
# NPM_TOKEN secret); version comes from the tag (semantic-release only tags, so package.json
# stays 0.0.0 in-repo and is stamped here).
: "${NPM_API_KEY:?NPM_API_KEY must be set (from the NPM_TOKEN secret)}"
: "${GITHUB_REF_NAME:?GITHUB_REF_NAME must be set (the pushed tag, e.g. v1.2.3)}"

./scripts/ci/build.sh

# Restore the manifest and scrub the token on every exit path, so neither the release
# version nor the secret is left in the working tree.
cp package.json package.json.orig
trap 'rm -f .npmrc; mv -f package.json.orig package.json' EXIT

bun pm pkg set "version=${GITHUB_REF_NAME#v}"
printf '//registry.npmjs.org/:_authToken=%s\n' "${NPM_API_KEY}" >.npmrc
bun publish --access public --tolerate-republish
