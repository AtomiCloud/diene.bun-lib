<!-- Badge targets point at AtomiCloud/diene.bun-lib and the @atomicloud/bun-lib npm package, and are rewritten on template promotion. -->

[![npm version](https://img.shields.io/npm/v/@atomicloud/bun-lib)](https://www.npmjs.com/package/@atomicloud/bun-lib)
[![npm downloads](https://img.shields.io/npm/dm/@atomicloud/bun-lib)](https://www.npmjs.com/package/@atomicloud/bun-lib)
[![CI](https://github.com/AtomiCloud/diene.bun-lib/actions/workflows/ci.yaml/badge.svg)](https://github.com/AtomiCloud/diene.bun-lib/actions/workflows/ci.yaml)
[![Coverage](https://codecov.io/gh/AtomiCloud/diene.bun-lib/branch/main/graph/badge.svg)](https://codecov.io/gh/AtomiCloud/diene.bun-lib)
[![Unit Tests](https://img.shields.io/github/check-runs/AtomiCloud/diene.bun-lib/main?nameFilter=Unit%20Tests%20%2F%20Unit%20Tests&label=Unit%20Tests)](https://github.com/AtomiCloud/diene.bun-lib/actions/workflows/ci.yaml)
[![Integration Tests](https://img.shields.io/github/check-runs/AtomiCloud/diene.bun-lib/main?nameFilter=Integration%20Tests%20%2F%20Integration%20Tests&label=Integration%20Tests)](https://github.com/AtomiCloud/diene.bun-lib/actions/workflows/ci.yaml)
[![Commits per month](https://img.shields.io/github/commit-activity/m/AtomiCloud/diene.bun-lib)](https://github.com/AtomiCloud/diene.bun-lib/commits/main)

# @atomicloud/bun-lib

A small, publishable TypeScript library shipped as dual **ESM + CommonJS** with bundled type
declarations. It exposes a sample key/value API (key namespacing plus a Redis-backed store) and
serves as the baseline for AtomiCloud Bun libraries.

## Installation

```bash
bun add @atomicloud/bun-lib
# or
npm install @atomicloud/bun-lib
```

`ioredis` is a runtime dependency and is installed automatically.

## Usage

### ESM

```ts
import { buildSampleKey, createRedisStore, persistSample } from '@atomicloud/bun-lib';
import type { IKeyValueStore, RedisConnection } from '@atomicloud/bun-lib';

// Build a namespaced key: "bun-base:sample-key"
const key = buildSampleKey('Bun Base', 'sample key');

// Round-trip a value through a Redis-backed store
const connection: RedisConnection = { host: '127.0.0.1', port: 6379 };
const store: IKeyValueStore = createRedisStore(connection);
const value = await persistSample(store, 'Bun Base', 'sample key', 'sample value');
await store.close();
```

### CommonJS

```js
const { buildSampleKey, createRedisStore, persistSample } = require('@atomicloud/bun-lib');

const key = buildSampleKey('Bun Base', 'sample key');
```

# Development Environment

All binaries, tools, and PATH are managed by **Nix**. Do not install tools manually or modify PATH outside of the nix configuration.

## Prerequisites

1. **[Nix](https://nixos.org/download)** — package manager
2. **[direnv](https://direnv.net/docs/installation.html)** — auto-loads the nix shell on `cd`

## Getting Started

```bash
direnv allow    # first time only — loads the nix dev shell
```

Once allowed, direnv automatically loads the development environment whenever you enter the project directory.

## Nix Configuration

See [docs/developer/standard/nix.md](docs/developer/standard/nix.md) for the full guide on:

- File structure (`flake.nix`, `nix/`, `.envrc`)
- Adding/removing packages
- Environment groups and shells
- Formatters and pre-commit hooks
- Adding registries

## Bun Baseline

See [docs/developer/bun-baseline.md](docs/developer/bun-baseline.md) for Bun-specific commands, test modes, coverage, and runtime notes.
