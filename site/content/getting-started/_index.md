+++
title = "Getting Started"
sort_by = "weight"
weight = 1
template = "section.html"
description = "Install dvs, then version your first dataset, with or without Git."
+++

dvs versions large or sensitive data files independently of your source control.
Contents go to a content-addressed blob store; small text meta files sit next to
your code and record what is tracked. It works alongside Git or on its own.

## Install

**CLI** (the `dvs` binary), with [cargo](https://rustup.rs):

```bash
cargo install --git https://github.com/A2-ai/dvs2 --locked --force --all-features dvs-cli
```

**R package** (`dvs`), with [rv](https://github.com/A2-ai/rv):

```bash
rv add dvs --git https://github.com/A2-ai/dvs2 --branch main --directory dvs-rpkg
```

## Pick a track

Both expose the same four verbs (`init`, `add`, `status`, `get`):

- [R Package](@/r-package/_index.md): drive dvs from R with `library(dvs)`.
- [CLI](@/cli/_index.md): drive dvs from the terminal with the `dvs` binary.

The page below walks through bootstrapping a fresh project.
