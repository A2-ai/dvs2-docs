+++
title = "dvs"
sort_by = "weight"
description = "An independent data versioning system for data-intensive projects."
+++

## What dvs is

**dvs** (data versioning system) versions large or sensitive datasets, common in
pharma and other data-intensive work, without committing their contents to your
source tree. File contents live in a content-addressed blob store, typically a
shared drive; each tracked file gets a small text meta file that sits next to
your code. dvs is an **independent** versioning system: alongside Git it
keeps multi-gigabyte data out of your history while the meta files travel with
your commits, and it works on its own just as well. Either way the four verbs
are the same, `init`, `add`, `status`, `get`, and you can run them from the
**R package** (`library(dvs)`) or the **CLI** (the `dvs` binary). This guide
covers both, side by side.

## Where to start

[Getting Started](@/getting-started/_index.md) has the install steps and a short
walkthrough of the core workflow on a small dataset, for both the CLI and R.
From there the [R Package](@/r-package/_index.md) and [CLI](@/cli/_index.md)
sections document every function and command (the R Package section also covers
the R-only helper utilities), and [Internals](@/internals/_index.md) goes
deeper on storage, configuration, the audit log, and the error surface.
