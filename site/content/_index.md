+++
title = "dvs"
sort_by = "weight"
description = "An independent data version control system for data-intensive projects."
+++

## What dvs is

**dvs** (data version system) versions large or sensitive datasets, common in
pharma and other data-intensive work, without committing their contents to your
source tree. File contents live in a content-addressed blob store (typically a
shared drive). Each tracked file gets a small text meta file that lives next to
your code.

dvs is an **independent** version control system. It works alongside Git,
keeping multi-gigabyte data out of your history while the meta files travel with
your commits. It also works without Git, on its own. Either way the four verbs
are the same: `init`, `add`, `status`, `get`.

You can drive it from the **R package** (`library(dvs)`) or the **CLI** (the
`dvs` binary). This guide covers both, side by side.

## Where to start

[Getting Started](@/getting-started/_index.md) has the install steps and a short
walkthrough of the core workflow on a small dataset, for both the CLI and R.
From there the [R Package](@/r-package/_index.md) and [CLI](@/cli/_index.md)
sections cover bulk operations, the file lifecycle, and shared storage, and
[Reference](@/reference/_index.md) goes deeper on storage internals,
configuration, the audit log, and the full error surface.
