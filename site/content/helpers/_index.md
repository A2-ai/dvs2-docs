+++
title = "Helpers"
sort_by = "weight"
weight = 4
template = "section.html"
description = "R-only utilities for threads, logging, versions, and byte sizes."
+++

The `dvs` R package includes utility functions that sit outside the four-verb
workflow. They configure the dvs core process-wide (threads, logging) or format
its output. They are R only; the CLI exposes the same controls through flags and
environment variables.

- [set_dvs_threads()](@/helpers/threads.md): set the process-wide thread pool size.
- [set_dvs_log_level()](@/helpers/log-level.md): route core log output to the R console.
- [format_byte_size()](@/helpers/format-bytes.md): human-readable byte sizes.
- [new_dvs_bytes()](@/helpers/bytes.md): the `dvs_bytes` vector type and pillar printing.
- [dvs_version()](@/helpers/version.md): report the core crate version.
