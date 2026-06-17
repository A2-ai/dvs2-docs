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

## Helpers

R-only utilities that sit outside the four-verb workflow. They configure the
dvs core process-wide (threads, logging) or format its output. The CLI exposes
the same controls through flags and environment variables.

- [set_dvs_threads()](@/helpers/threads.md): set the process-wide thread pool size.
- [set_dvs_log_level()](@/helpers/log-level.md): route core log output to the R console.
- [dvs_version()](@/helpers/version.md): report the core crate version.
- [format_byte_size()](@/helpers/format-bytes.md): human-readable byte sizes.
- [new_dvs_bytes()](@/helpers/bytes.md): the `dvs_bytes` vector type and pillar printing.

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
