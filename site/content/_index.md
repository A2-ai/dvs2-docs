+++
title = "dvs"
sort_by = "weight"
description = "An independent data version control system for data-intensive projects."
+++

## What dvs is

**dvs** (data version system) versions large or sensitive datasets — the kind
that are routine in pharma and other data-intensive work — without committing
their contents to your source tree. File contents live in a content-addressed
blob store (typically a shared drive); each tracked file gets a small text meta
file that lives next to your code.

dvs is an **independent** version control system. It works **alongside Git** —
keeping multi-gigabyte data out of your history while the meta files travel with
your commits — and it works **entirely without Git** too, on its own. Either
way the four verbs are the same: `init`, `add`, `status`, `get`.

You can drive it from the **R package** (`library(dvs)`) or the **CLI** (the
`dvs` binary). These vignettes cover both, side by side.

## Where to start

New here? Read [Getting Started](@/getting-started/_index.md), then pick a track:
the [R Package](@/r-package/_index.md) or the [CLI](@/cli/_index.md). The
[Reference](@/reference/_index.md) section goes deeper on storage internals,
configuration, the audit log, and the full error surface.
