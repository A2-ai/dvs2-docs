+++
title = "CLI"
sort_by = "weight"
weight = 3
template = "section.html"
description = "Version data from the terminal with the dvs binary."
+++

The `dvs` binary drives four subcommands: `init`, `add`, `status`, `get`. Every
command accepts `--json` for machine-readable output. New to dvs? Start with the
[CLI walkthrough](@/getting-started/cli.md) in Getting Started.

## Install

With [cargo](https://rustup.rs):

```bash
cargo install --git https://github.com/A2-ai/dvs2 --locked --force --all-features dvs-cli
```

## Global options

These apply to the top level and to every subcommand:

| Flag | Behavior |
|---|---|
| `--json` | Emit results as JSON. |
| `--threads <N>` | Thread pool size for the command (`0` = auto-detect). Process-wide default via the `DVS_NUM_THREADS` environment variable. |
| `-V`, `--version` | Print the version. |

## Commands

One page per command, covering every flag.

- [dvs init](@/cli/init.md): start a project and configure storage.
- [dvs add](@/cli/add.md): track files in storage.
- [dvs status](@/cli/status.md): report the sync status of tracked files.
- [dvs get](@/cli/get.md): restore files from storage.

## How the CLI differs from R

The CLI and the [R package](@/r-package/_index.md) cover the same operations with
different shapes: the CLI prints tables (or JSON) and takes a per-call
`--threads`, while R returns data frames and sets threads process-wide. `status`
hides metadata behind `--with-metadata`; R always returns it. `init` uses
`--no-compression` where R uses `compression = "none"`.
