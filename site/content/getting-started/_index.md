+++
title = "Getting Started"
sort_by = "weight"
weight = 1
template = "section.html"
description = "Install dvs, then run the core workflow on a small dataset."
+++

dvs versions large or sensitive data files independently of your source control.
File contents go to a content-addressed blob store. Small text meta files sit
next to your code and record what is tracked. dvs works alongside Git or on its
own.

## Install

**CLI** (the `dvs` binary), with [cargo](https://rustup.rs):

```bash
cargo install --git https://github.com/A2-ai/dvs2 --locked --force --all-features dvs-cli
```

**R package** (`dvs`), with [rv](https://github.com/A2-ai/rv):

```bash
rv add dvs --git https://github.com/A2-ai/dvs2 --branch main --directory dvs-rpkg
```

## The core workflow

The CLI and the R package expose the same four verbs: `init`, `add`, `status`,
`get`. The two walkthroughs below take one small dataset (R's built-in `Theoph`,
saved as a CSV) through the full loop: initialize a repository, add the file,
check status, delete it, then get it back.

- [CLI walkthrough](@/getting-started/cli.md): the workflow from the terminal.
- [R walkthrough](@/getting-started/r.md): the same workflow with `library(dvs)`.

Once the basics are clear, the [R Package](@/r-package/_index.md) and
[CLI](@/cli/_index.md) sections document every function and command, the
[Helpers](@/helpers/_index.md) section covers the R-only utilities, and
[Internals](@/internals/_index.md) goes deeper on storage and configuration.
