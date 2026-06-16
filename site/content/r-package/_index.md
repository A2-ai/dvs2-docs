+++
title = "R Package"
sort_by = "weight"
weight = 2
template = "section.html"
description = "Version data from R with library(dvs): init, add, status, get."
+++

The `dvs` R package wraps the dvs core so you can version data without leaving
your R session. Install it with [rv](https://github.com/A2-ai/rv):

```bash
rv add dvs --git https://github.com/A2-ai/dvs2 --branch main --directory dvs-rpkg
```

The vignettes below start from a five-minute end-to-end walkthrough and build up
to the full file lifecycle, sharing storage across projects, and the helper used
to generate test data.
