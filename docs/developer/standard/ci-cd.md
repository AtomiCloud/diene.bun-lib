---
id: ci-cd
title: CI/CD Workflows
---

# CI/CD Workflows

This document describes the principles and patterns for CI/CD workflows in the workspace template.

## Architecture Overview

The CI/CD architecture is designed around three core principles:

1. **Local reproducibility** - All CI scripts must be runnable locally
2. **Separation of concerns** - GitHub Actions is just a task runner; logic lives in shell scripts
3. **Reusable patterns** - Abstract complexity into reusable workflows

## Three Workflow Types

| Workflow    | Trigger                          | Purpose                                    |
| ----------- | -------------------------------- | ------------------------------------------ |
| **CI**      | Every commit                     | Gates and checks that must pass regardless |
| **Release** | Merge to main (after CI success) | Semantic versioning, changelog, git tag    |
| **CD**      | New version (tag push)           | Deploy artifacts                           |

### CI Workflow

Runs on every commit to verify code quality. Example jobs might include:

- Pre-commit hooks (linting, formatting)
- Unit tests
- Integration tests
- Builds

### Release Workflow

Runs only after successful CI on main branch. Handles:

- Semantic versioning based on commit types
- Changelog generation
- Git tag creation
- GitHub release creation

### CD Workflow

Runs when a new version tag is pushed. Handles deployment operations.

### Artifact Publishing Model (npm Library)

This instance is a publishable npm library, so its artifact is an npm package (not a Docker
image or Helm chart). Publishing happens through reusable workflows on two triggers:

| Trigger          | When                       | What happens                                                                           |
| ---------------- | -------------------------- | -------------------------------------------------------------------------------------- |
| **CI** (commit)  | Every push                 | Build the dual ESM+CJS+types bundle and validate the package shape (`publint`, `attw`) |
| **CD** (release) | `v*.*.*` tag (sem-release) | Stamp the tag version into `package.json` and `bun publish` the package to npm         |

Key properties:

- The logic lives in `./scripts/ci/build.sh` (dual ESM+CJS+types build + tarball assertions),
  `./scripts/ci/pkg-validate.sh` (build → `bun pm pack` → `publint` + `attw`), and
  `./scripts/ci/publish.sh` (version stamp from `${{ github.ref_name }}` + `bun publish`). The
  reusable workflows `⚡reusable-package-validate.yaml` (CI lane) and `⚡reusable-publish.yaml`
  (CD lane) own setup and execution.
- The toolchain is **Bun-only** — `bun build`, `bunx tsc`, `bun pm pack`, and `bun publish` run
  under Bun with no node/npm runtime added to Nix. Publish runs in `nix develop .#cd`.
- Publish auth is the `NPM_TOKEN` CI secret (exposed as `NPM_API_KEY`), written to a `.npmrc`
  that is removed by a cleanup trap on exit. There is **no provenance/OIDC** (`id-token` is not
  requested); workflow permissions are `contents: read`.
- All Nix jobs (pre-commit, package-validate, publish, release) share the same Nix store cache
  via `nscloud-cache-tag-atomi-nix-store-cache`.

### Dev Shells

| Shell        | Used by                                 |
| ------------ | --------------------------------------- |
| `.#ci`       | CI checks (pre-commit, build, validate) |
| `.#cd`       | CD / npm publish                        |
| `.#releaser` | Semantic release                        |

## The Execution Pattern

```
Setup Nix -> Setup Caches -> nix develop -c ./scripts/ci/script.sh
```

**Why this pattern?**

- GitHub Actions is just a task runner
- Real logic lives in shell scripts
- Shell scripts run in Nix = **local reproducibility**
- You can run CI locally: `nix develop .#ci -c ./scripts/ci/script.sh`

### Example Execution

```yaml
- uses: AtomiCloud/actions.setup-nix@v3 # checks out the repo too
- run: nix develop .#ci -c ./scripts/ci/script.sh
```

## Reusable Workflow Conventions

### Naming

- Reusable workflows are named with `⚡` emoji prefix
- Format: `⚡reusable-{purpose}.yaml`
- Examples: `⚡reusable-precommit.yaml`, `⚡reusable-test.yaml`

### Separation of Responsibilities

**Caller workflow is responsible for:**

- Defining the trigger
- Wiring only the inputs the reusable workflow actually needs
- Choosing which reusable workflow to invoke

**Reusable workflow is responsible for:**

- Setup (`AtomiCloud/actions.setup-nix@v3` + `AtomiCloud/actions.cache-bun@v1`)
- Running the shell script from `scripts/ci/`

### Inputs: only when required

Reusable workflows declare an input **only if they use it**. Cache keys no longer depend on
platform/service, so `atomi_platform` / `atomi_service` are **not** required inputs — pre-commit,
build, package-validate, publish, and release take no inputs, and `⚡reusable-test.yaml` takes
only `mode`.

### Example: Reusable Workflow Structure

```yaml
# .github/workflows/⚡reusable-precommit.yaml
name: Reusable Pre-Commit

on:
  workflow_call:

jobs:
  precommit:
    runs-on:
      - nscloud-ubuntu-22.04-amd64-4x8-with-cache
      - nscloud-cache-size-50gb
      - nscloud-cache-tag-atomi-nix-store-cache
    steps:
      - uses: AtomiCloud/actions.setup-nix@v3 # checks out the repo too
      - run: nix develop .#ci -c ./scripts/ci/pre-commit.sh
```

<!-- prettier-ignore -->
```yaml
# .github/workflows/ci.yaml (caller)
name: CI

on:
  push:

jobs:
  precommit:
    uses: ./.github/workflows/⚡reusable-precommit.yaml
    secrets: inherit
```

## Infrastructure and Caching

### NS-Cloud Runners

Runners with Nix store caching for persistent build artifacts.

### Shared Nix Store Cache

All Nix jobs use a single shared cache tag — **not** per-service — so the whole org reuses one
warm store and saves cache space:

```yaml
nscloud-cache-tag-atomi-nix-store-cache
```

## Local Reproducibility

All CI scripts MUST be runnable locally:

```bash
nix develop .#ci -c ./scripts/ci/script.sh
```

This allows developers to:

- Debug CI failures locally
- Run checks without pushing
- Verify changes before committing

## Directory Structure

```
.github/
└── workflows/
    ├── ci.yaml                    # Main CI workflow
    ├── release.yaml               # Release workflow
    ├── cd.yaml                    # Deploy workflow
    ├── ⚡reusable-precommit.yaml  # Reusable pre-commit
    ├── ⚡reusable-test.yaml       # Reusable test (example)
    └── ⚡reusable-build.yaml      # Reusable build (example)

scripts/
└── ci/
    ├── pre-commit.sh              # CI: pre-commit hooks
    ├── test-unit.sh               # CI: unit tests
    ├── test-int.sh                # CI: integration tests
    └── build.sh                   # CI: build
```

## Summary

| Aspect                    | Pattern                                                     |
| ------------------------- | ----------------------------------------------------------- |
| **Workflow types**        | CI (every commit), Release (main merge), CD (tag push)      |
| **Execution**             | Nix -> Caches -> shell script                               |
| **Reusable workflows**    | Named with `⚡`, reusable workflow handles execution        |
| **Cache tag (shared)**    | `atomi-nix-store-cache` (one shared store, not per-service) |
| **Local reproducibility** | `nix develop .#ci -c ./scripts/ci/script.sh`                |
