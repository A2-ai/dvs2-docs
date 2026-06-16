+++
title = "R Package"
sort_by = "weight"
weight = 2
template = "section.html"
description = "Version data from R with library(dvs): init, add, status, get."
+++

The `dvs` R package wraps the dvs core. Each function returns a native R object:
the verbs return tibbles, `dvs_init()` returns a list. New to dvs? Start with the
[R walkthrough](@/getting-started/r.md) in Getting Started.

## Install

With [rv](https://github.com/A2-ai/rv):

```bash
rv add dvs --git https://github.com/A2-ai/dvs2 --branch main --directory dvs-rpkg
```

## Functions

One page per function, covering every parameter.

- [dvs_init()](@/r-package/init.md): initialize a project and configure storage.
- [dvs_add()](@/r-package/add.md): track files in storage.
- [dvs_status()](@/r-package/status.md): report the sync status of tracked files.
- [dvs_get()](@/r-package/get.md): restore files from storage.

The R-only [helpers](@/helpers/_index.md) (threads, logging, byte sizes) have
their own section.

## How the R surface differs from the CLI

The R functions and the [CLI](@/cli/_index.md) cover the same operations with
different shapes:

- R returns native data frames and lists; there is no `--json`.
- `dvs_status()` always returns the metadata columns; the CLI hides them behind
  `--with-metadata`.
- Threads are set process-wide with [set_dvs_threads()](@/helpers/threads.md);
  the CLI takes a per-call `--threads`.
- `dvs_init()` uses `compression = c("zstd", "none")`; the CLI uses a
  `--no-compression` flag.
