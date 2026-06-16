+++
title = "CLI"
sort_by = "weight"
weight = 3
template = "section.html"
description = "Version data from the terminal with the dvs binary."
+++

The `dvs` binary drives the same four verbs (`init`, `add`, `status`, `get`)
from the command line, with `--json` output on every command for scripting.
Install it with [cargo](https://rustup.rs):

```bash
cargo install --git https://github.com/A2-ai/dvs2 --locked --force --all-features dvs-cli
```

The vignettes below mirror the R package walkthroughs, driven entirely from the
shell.
