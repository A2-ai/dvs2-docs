+++
title = "R Package"
sort_by = "weight"
weight = 2
template = "section.html"
description = "Version data from R with library(dvs): init, add, status, get."
+++

The `dvs` R package wraps the dvs core so you can version data without leaving
your R session. New to dvs? Start with the
[R walkthrough](@/getting-started/r.md) in Getting Started.

Install it with [rv](https://github.com/A2-ai/rv):

```bash
rv add dvs --git https://github.com/A2-ai/dvs2 --branch main --directory dvs-rpkg
```

These chapters go past the basics: adding files in bulk (single files, whole
folders, and globs) and at large sizes, the full file lifecycle across edits and
restores, sharing one storage location across projects, and the helper used to
generate test data.
