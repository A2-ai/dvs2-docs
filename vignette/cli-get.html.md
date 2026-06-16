---
title: "dvs get"
subtitle: "Restore files from storage"
format:
  html:
    keep-md: true
execute:
  freeze: auto
---

`dvs get` reads the meta files, finds the matching blobs in storage, and writes
the contents back to their original paths. It is the inverse of `add`: the loop
to run after re-cloning a project whose data is not on disk. Pass paths, a glob,
or both.

```text
Usage: dvs get [OPTIONS] [PATHS]...

Arguments:
  [PATHS]...

Options:
  -g, --glob <GLOB>        Select files by glob pattern
      --json               Output results as JSON
      --dry-run            Show what would be retrieved without writing files
      --threads <THREADS>  Threads (0 = auto-detect)
  -h, --help               Print help
```

## Options

| Flag | Argument | Default | Behavior |
|---|---|---|---|
| `[PATHS]...` | paths | none | Files to retrieve. |
| `-g`, `--glob` | pattern | none | Library-expanded glob, literal path separator (use `**` to recurse). |
| `--dry-run` | flag | off | Report what would be retrieved; write nothing. |
| `--threads` | integer | `0` (auto) | Thread pool size for this command. |
| `--json` | flag | off | Emit results as JSON. |

::: {.callout-note}
`get` exposes a short `-g` for `--glob`; `add` only has the long `--glob`.
:::

## Setup

Add three files, then delete them so `get` has something to restore.


::: {.cell}

```{.r .cell-code}
options(width = 1000)
library(here)
```

::: {.cell-output .cell-output-stderr}

```
here() starts at /Users/elea/Documents/a2ai_github/dvs2-demo-repo
```


:::

```{.r .cell-code}
proj    <- here::here(basename(tempfile(fileext = "_project")))
storage <- here::here(basename(tempfile(fileext = "_storage")))
dir.create(proj)
dir.create(storage)
dir.create(file.path(proj, "data", "sub"), recursive = TRUE)
write.csv(mtcars[1:8, ],   file.path(proj, "data", "f1.csv"))
write.csv(mtcars[9:16, ],  file.path(proj, "data", "f2.csv"))
write.csv(iris[1:10, ],    file.path(proj, "data", "sub", "f3.csv"), row.names = FALSE)
Sys.setenv(DVS_PROJECT = proj, DVS_STORAGE = storage)
```
:::



::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs init "$DVS_STORAGE" >/dev/null
dvs add data/f1.csv data/f2.csv data/sub/f3.csv >/dev/null
rm data/f1.csv data/f2.csv data/sub/f3.csv
dvs status --absent
```


::: {.cell-output .cell-output-stdout}

```
+-----------------+--------+-------+
| path            | status | size  |
+-----------------+--------+-------+
| data/f1.csv     | absent | 488 B |
+-----------------+--------+-------+
| data/f2.csv     | absent | 500 B |
+-----------------+--------+-------+
| data/sub/f3.csv | absent | 312 B |
+-----------------+--------+-------+
```


:::
:::


## Paths

Restore a single file. Output lists each retrieved file and a total.


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs get data/f1.csv
```


::: {.cell-output .cell-output-stdout}

```
data/f1.csv [488 B]
Total: 1 files, 488 B
```


:::
:::


After `get`, the file is `current` again.


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs status data/f1.csv
```


::: {.cell-output .cell-output-stdout}

```
+-------------+---------+-------+
| path        | status  | size  |
+-------------+---------+-------+
| data/f1.csv | current | 488 B |
+-------------+---------+-------+
```


:::
:::


## `-g`, `--glob`

Restore by glob. Use `**` to cross directory boundaries.


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs get -g "data/**/*.csv"
```


::: {.cell-output .cell-output-stdout}

```
data/f2.csv [500 B]
data/sub/f3.csv [312 B]
Total: 2 files, 812 B
```


:::
:::


## `--dry-run`

Report what would be retrieved without writing files.


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
rm data/f2.csv
dvs get data/f2.csv --dry-run
```


::: {.cell-output .cell-output-stdout}

```
data/f2.csv [500 B]
Total: 1 files, 500 B
```


:::
:::


The file is still absent after a dry run:


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs status --absent
```


::: {.cell-output .cell-output-stdout}

```
+-------------+--------+-------+
| path        | status | size  |
+-------------+--------+-------+
| data/f2.csv | absent | 500 B |
+-------------+--------+-------+
```


:::
:::


## `--threads`

Override the auto-detected thread count for this command.


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs get data/f2.csv --threads 2
```


::: {.cell-output .cell-output-stdout}

```
data/f2.csv [500 B]
Total: 1 files, 500 B
```


:::
:::


## `--json`

Each result row carries `path`, `outcome` (`copied` or `present`), and `size`.


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs get data/f1.csv --json
```


::: {.cell-output .cell-output-stdout}

```
[{"path":"data/f1.csv","outcome":"present","size":488}]
```


:::
:::


## Differences from R

The R function is [dvs_get()](r-get.html). It returns a data frame rather than
printed lines, has no `--threads` or `--json`, and exposes the progress bar as
an internal `progress_callback` handle.

## See also

- [dvs init](cli-init.html), [dvs add](cli-add.html), [dvs status](cli-status.html)
- [Storage and meta files](intro-internals.html)
