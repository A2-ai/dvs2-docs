---
title: "dvs demo vignettes"
subtitle: "a guided tour of dvs — data version control for R projects"
format:
  html:
    keep-md: true
---

**dvs** is a data version control system for R. It stores large data files in
a content-addressed blob storage directory (separate from your git repo) and
tracks them through small, text-based meta files that live alongside your code.

## Reading order

| Vignette | What it covers |
|----------|----------------|
| [Setup](setup.html) | Bootstrap a new project: rv, dvs source build, quarto scaffolding |
| [Getting Started](getting-started.html) | `dvs_init`, `dvs_add`, `dvs_status`, `dvs_get` — five minutes, R API |
| [Getting Started — CLI](getting-started-cli.html) | Same five-minute walkthrough via the `dvs` binary |
| [Introduction](intro.html) | Core R API with larger datasets: status states, glob adds, partial restore |
| [CLI](intro-cli.html) | Same operations from the terminal via the `dvs` binary |
| [Internals](intro-internals.html) | `.dvs/` folder layout, meta files, blob addressing, audit log |
| [Lifecycle](lifecycle.html) | Modifying tracked files, `unsynced` status, `dry_run`, integrity failures |
| [Collaboration](collab.html) | Two projects sharing one storage; what to commit vs gitignore |
| [Configuration](config.html) | `dvs.toml` fields, compression tradeoffs, threads, custom folder names |
| [Audit log](audit.html) | Parsing and querying `audit.log.jsonl` with purrr + dplyr |
| [Errors](error.html) | Every error `dvs` raises, R and CLI side-by-side |
| [Random files](random_files.html) | `mkdatasetfiles()` helper used throughout these vignettes |

<!-- ## Roadmap / Current limitations

| Feature | Status |
|---------|--------|
| `dvs_remove` / untrack a file | **Not implemented** — delete the `.dvs` meta file manually |
| Remote / cloud storage backends | **Not implemented** — storage must be a locally-mounted path |
| File history / snapshots | **Not implemented** — dvs is content-addressed; re-adding rewrites the meta | -->

## Quick reference

```r
library(dvs)

dvs_init(storage_path)                          # initialise a repo
dvs_add(paths, glob, message, dry_run)          # hash & store files
dvs_status(paths, recursive, status)            # current | absent | unsynced
dvs_get(paths, glob, dry_run)                   # restore files from storage
set_dvs_threads(n)                              # parallelism control
```

```bash
dvs init  <storage>
dvs add   [paths...] [--glob <pattern>] [-m <message>] [--dry-run]
dvs status [paths...] [--absent] [--unsynced] [--current] [--with-metadata]
dvs get   [paths...] [--glob <pattern>] [--dry-run]
```
