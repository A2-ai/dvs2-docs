---
title: "Introduction to dvs CLI"
subtitle: "the same operations driven from the terminal via the `dvs` binary"
format:
  html:
    keep-md: true
execute:
  freeze: auto
---

# Setup

R creates the sandbox directories and data files; all dvs operations below run
via the `dvs` CLI binary.


::: {.cell}

```{.r .cell-code}
library(dvs)
library(fs)
library(here)
```
:::



::: {.cell}

```{.r .cell-code}
source(here::here("R/mkdatasetfiles.R"))
```
:::



::: {.cell}

```{.r .cell-code}
storage     <- tempfile(fileext = "_storage", tmpdir = here::here())
new_project <- tempfile(fileext = "_project", tmpdir = here::here())
dir.create(storage)
dir.create(new_project)
```
:::



::: {.cell}

```{.r .cell-code}
setwd(new_project)
mkdatasetfiles(n_files = 1,  size_mb = 25, prefix = "large_",      dir = "data/large",      show_progress = !nzchar(Sys.getenv("QUARTO_DOCUMENT_PATH")))
mkdatasetfiles(n_files = 3,  size_mb = 1,  prefix = "small_",      dir = "data/small",      show_progress = !nzchar(Sys.getenv("QUARTO_DOCUMENT_PATH")))
mkdatasetfiles(n_files = 50, size_mb = 3,  prefix = "individual_", dir = "data/individual", show_progress = !nzchar(Sys.getenv("QUARTO_DOCUMENT_PATH")))
```
:::


Pass the paths to the shell so bash chunks can use them:


::: {.cell}

```{.r .cell-code}
Sys.setenv(DVS_PROJECT = new_project, DVS_STORAGE = storage)
```
:::


# `dvs init`


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs init "$DVS_STORAGE"
cat dvs.toml
```
:::


# `dvs add`

Add a single file with a message:


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs add data/large/large_1.csv -m "add one large dataset"
```
:::


Add a directory of files via glob:


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs add --glob "data/small/*.csv" -m "add small corpus datasets"
```
:::


Add 50 files at once:


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs add --glob "data/individual/individual_*.csv" -m "add individual datasets"
```
:::


## `--dry-run`

Preview what *would* be added without writing anything:


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs add --glob "data/small/*.csv" --dry-run
```
:::


## Meta file

Each tracked file gets a `.dvs` meta file that records its hash:


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
cat .dvs/data/large/large_1.csv.dvs
```
:::


# `dvs status`

Default — show all tracked files:


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs status
```
:::


Filter by status:


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs status --current
```
:::


Show extended metadata columns with `--with-metadata`:


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs status --with-metadata
```
:::


In the R package these metadata columns (`hash`, `created_by`, `add_time`,
`compression`, `message`) are returned by default — they're already computed
when resolving status, so `dvs_status()` surfaces them without an extra flag.

Delete a few files to produce `absent` entries:


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
rm data/individual/individual_04.csv data/individual/individual_08.csv data/individual/individual_15.csv
dvs status --absent
```
:::


Modify a file to produce an `unsynced` entry:


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
echo "99,0,0,0,0,0" >> data/large/large_1.csv
dvs status --unsynced
```
:::


## JSON output

Every command accepts `--json` for machine-readable output:


```{.r .cell-code}
setwd(new_project)
out <- system2("dvs", c("status", "--absent", "--json"), stdout = TRUE)
cat("```json\n")
cat(jsonlite::toJSON(jsonlite::fromJSON(paste(out, collapse = "\n"),
                                        simplifyVector = FALSE),
                     pretty = TRUE, auto_unbox = TRUE))
cat("\n```\n")
```

# `dvs get`

Restore absent files by glob:


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs get --glob "data/individual/individual_*.csv"
dvs status --absent
```
:::


## `--dry-run`


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
rm data/individual/individual_01.csv
dvs get --glob "data/individual/individual_*.csv" --dry-run
```
:::


# `--threads`

Override the auto-detected thread count for any command:


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs status --threads 2
```
:::


# Cleanup


::: {.cell}

```{.r .cell-code}
unlink(new_project, recursive = TRUE)
unlink(storage,     recursive = TRUE)
```
:::


---

**Next up**: [Internals](intro-internals.html) — see how dvs organises meta files and blob storage under the hood.
