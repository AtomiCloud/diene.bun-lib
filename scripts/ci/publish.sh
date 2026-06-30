#!/usr/bin/env bash
set -euo pipefail

# Publishes the library to npm on a v*.*.* tag. Bun-only: no node/npm runtime.
# Auth: NPM_API_KEY (mapped from the NPM_TOKEN CI secret) written to .npmrc.
# Version: derived from the pushed tag (semantic-release only tags; package.json stays 0.0.0
# in-repo), so we stamp the tag version into package.json before publishing.

: "${NPM_API_KEY:?NPM_API_KEY must be set (mapped from the NPM_TOKEN secret)}"
: "${GITHUB_REF_NAME:?GITHUB_REF_NAME must be set (the pushed tag, e.g. v1.2.3)}"

PKG_VERSION="${GITHUB_REF_NAME#v}"
export PKG_VERSION

echo "🏗️  Building publishable artifacts..."
./scripts/ci/build.sh

# Back up the pristine manifest, then register ONE linear trap (no functions, per
# shell-scripts.md) BEFORE any mutation. It restores package.json AND scrubs the token on
# EVERY exit path — including a mid-flight `set -e` failure from the version stamp or
# `bun publish` below — so the working tree never keeps the release version or the secret.
cp package.json package.json.orig
trap 'rm -f .npmrc; mv -f package.json.orig package.json' EXIT

echo "🔖 Setting package version to ${PKG_VERSION} (from tag ${GITHUB_REF_NAME})..."
# Single quotes are intentional: the ${...} below is a JS template literal evaluated by
# `bun -e`, not a shell expansion. PKG_VERSION reaches the script via process.env.
# shellcheck disable=SC2016
bun -e 'const p = await Bun.file("package.json").json(); p.version = process.env.PKG_VERSION; await Bun.write("package.json", `${JSON.stringify(p, null, 2)}\n`);'

echo "🔐 Writing .npmrc auth token..."
printf '//registry.npmjs.org/:_authToken=%s\n' "${NPM_API_KEY}" >.npmrc

echo "🚀 Publishing @atomicloud/bun-lib@${PKG_VERSION} to npm..."
bun publish --access public --tolerate-republish

echo "✅ Publish complete."
