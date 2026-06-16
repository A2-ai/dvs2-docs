---
title: "The dvs.toml project file"
subtitle: "configuration fields and project discovery"
format:
  html:
    keep-md: true
execute:
  freeze: auto
---

::: {.callout-note}
This page is implementation detail, beyond what normal use requires. The
[dvs_init()](r-init.html) / [dvs init](cli-init.html) pages cover setting these
values; this page describes the file they write.
:::

`dvs_init()` writes a `dvs.toml` at the project root. It records where blobs are
stored and how the project is configured. Every later command finds the project
by walking up from the working directory to the nearest `dvs.toml`.

## Setup


::: {.cell}

```{.r .cell-code}
options(width = 1000)
library(dvs)
base <- tempfile("dvs_config_")
dir.create(base)
```
:::


## A default project


::: {.cell}

```{.r .cell-code}
proj  <- file.path(base, "default")
store <- file.path(base, "default-store")
dir.create(proj)
dir.create(store)
dvs_init(store, root_dir = proj)
```

::: {.cell-output .cell-output-stdout}

```
DVS Initialized
```


:::

```{.r .cell-code}
cat(readLines(file.path(proj, "dvs.toml")), sep = "\n")
```

::: {.cell-output .cell-output-stdout}

```
compression = "zstd"

[backend]
path = "/var/folders/_x/bq8vb1b156sgl363l71by61h0000gn/T//Rtmp2njh1C/dvs_config_8a6ed47685c/default-store"
group = "staff"
```


:::
:::


| Field | Meaning |
|---|---|
| `compression` | `"zstd"` (default) or `"none"`. Recorded per file in the meta files, so changing this later does not break old retrievals. |
| `[backend] path` | Storage directory for blobs. Any path reachable from this machine: a local path or a network mount. |
| `[backend] group` | Unix group set on the storage directory and stored files. Defaults to the creating user's group. |
| `metadata_folder_name` | Name of the metadata folder (default `.dvs`). Only written when set to a non-default value. |

## Non-default fields

Fields set to non-default values are written explicitly. Here the metadata
folder is renamed and compression is disabled.


::: {.cell}

```{.r .cell-code}
proj  <- file.path(base, "custom")
store <- file.path(base, "custom-store")
dir.create(proj)
dir.create(store)
dvs_init(store, root_dir = proj, metadata_folder_name = ".datalock", compression = "none")
```

::: {.cell-output .cell-output-stdout}

```
DVS Initialized
```


:::

```{.r .cell-code}
cat(readLines(file.path(proj, "dvs.toml")), sep = "\n")
```

::: {.cell-output .cell-output-stdout}

```
compression = "none"
metadata_folder_name = ".datalock"

[backend]
path = "/var/folders/_x/bq8vb1b156sgl363l71by61h0000gn/T//Rtmp2njh1C/dvs_config_8a6ed47685c/custom-store"
group = "staff"
```


:::
:::


## Project discovery

A command finds its project by walking up from the working directory to the
nearest `dvs.toml`. A `dvs.toml` in a parent directory does not block a nested
project: you can initialize a project inside another one, and you can have
several projects in a single Git repository.


::: {.cell}

```{.r .cell-code}
root <- file.path(base, "repo")
sub  <- file.path(root, "sub")
dir.create(sub, recursive = TRUE)
dir.create(file.path(base, "repo-store"))
dir.create(file.path(base, "sub-store"))
dvs_init(file.path(base, "repo-store"), root_dir = root)
```

::: {.cell-output .cell-output-stdout}

```
DVS Initialized
```


:::

```{.r .cell-code}
dvs_init(file.path(base, "sub-store"), root_dir = sub)
```

::: {.cell-output .cell-output-stdout}

```
DVS Initialized
```


:::

```{.r .cell-code}
list.files(root, pattern = "dvs.toml", recursive = TRUE)
```

::: {.cell-output .cell-output-stdout}

```
[1] "dvs.toml"     "sub/dvs.toml"
```


:::
:::


Each `dvs.toml` configures the files beneath it independently.

::: {.callout-warning}
`dvs_init()` errors if a `dvs.toml` already exists in the target root
(`dvs is already initialized`). It does not overwrite an existing project.
:::

## Shared storage

The storage path can be a shared network mount, so several people version data
against one store. Content is addressed by hash, so identical files added by
different users share a single blob. `[backend] group` sets the Unix group on
the storage directory and stored files, giving collaborators read and write
access.

Each user commits their `.dvs` meta files (and `dvs.toml`) to Git; the data
itself stays out of Git. After cloning, a collaborator runs
[dvs_get()](r-get.html) / [dvs get](cli-get.html) to retrieve the files the meta
files point to. This is the same loop as the
[R walkthrough](getting-started.html), shared across a team.

## See also

- [dvs_init()](r-init.html) / [dvs init](cli-init.html): setting these fields.
- [Storage and meta files](intro-internals.html): the blob and meta layout.
- [The audit log](audit.html): the record kept in the storage directory.
