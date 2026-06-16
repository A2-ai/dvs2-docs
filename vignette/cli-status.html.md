---
title: "dvs status"
subtitle: "Report the sync status of tracked files"
format:
  html:
    keep-md: true
execute:
  freeze: auto
---

`dvs status` reports each tracked file as `current` (on disk and matching the
stored hash), `absent` (tracked but missing on disk), or `unsynced` (on disk but
not matching the stored hash). By default it prints a compact table.

```text
Usage: dvs status [OPTIONS] [PATHS]...

Arguments:
  [PATHS]...  Paths (files or directories) to check status for

Options:
      --json               Output results as JSON
  -r, --recursive          Recurse into subdirectories of given directories
      --current            Include current files
      --absent             Include absent files
      --unsynced           Include unsynced files
      --with-metadata      Show all metadata columns
      --threads <THREADS>  Threads (0 = auto-detect)
  -h, --help               Print help
```

## Options

| Flag | Argument | Default | Behavior |
|---|---|---|---|
| `[PATHS]...` | paths | whole project | Files or directories to report. |
| `-r`, `--recursive` | flag | off | Include files in subdirectories of given directories. |
| `--current` | flag | off | Include `current` files. |
| `--absent` | flag | off | Include `absent` files. |
| `--unsynced` | flag | off | Include `unsynced` files. |
| `--with-metadata` | flag | off | Add hash, created_by, add_time, compression, message columns. |
| `--threads` | integer | `0` (auto) | Thread pool size for this command. |
| `--json` | flag | off | Emit results as JSON. |

The three status flags are independent booleans and combine. With none set, all
statuses are shown.

## Setup

Add three files, then delete one and edit another so all three states appear.


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
rm data/f2.csv                      # -> absent
echo "extra,row" >> data/f1.csv     # -> unsynced
```
:::


## All files

With no arguments and no filters, every tracked file is reported.


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs status
```


::: {.cell-output .cell-output-stdout}

```
+-----------------+----------+-------+
| path            | status   | size  |
+-----------------+----------+-------+
| data/f1.csv     | unsynced | 488 B |
+-----------------+----------+-------+
| data/f2.csv     | absent   | 500 B |
+-----------------+----------+-------+
| data/sub/f3.csv | current  | 312 B |
+-----------------+----------+-------+
```


:::
:::


## Paths

Scope the report to specific files or directories.


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs status data/sub/f3.csv
```


::: {.cell-output .cell-output-stdout}

```
+-----------------+---------+-------+
| path            | status  | size  |
+-----------------+---------+-------+
| data/sub/f3.csv | current | 312 B |
+-----------------+---------+-------+
```


:::
:::


## `-r`, `--recursive`

Without `-r`, a directory argument reports only files directly in it. With `-r`,
files in subdirectories are included too.


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs status data
```


::: {.cell-output .cell-output-stdout}

```
+-------------+----------+-------+
| path        | status   | size  |
+-------------+----------+-------+
| data/f1.csv | unsynced | 488 B |
+-------------+----------+-------+
| data/f2.csv | absent   | 500 B |
+-------------+----------+-------+
```


:::
:::



::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs status data -r
```


::: {.cell-output .cell-output-stdout}

```
+-----------------+----------+-------+
| path            | status   | size  |
+-----------------+----------+-------+
| data/f1.csv     | unsynced | 488 B |
+-----------------+----------+-------+
| data/f2.csv     | absent   | 500 B |
+-----------------+----------+-------+
| data/sub/f3.csv | current  | 312 B |
+-----------------+----------+-------+
```


:::
:::


## Status filters

Each filter alone:


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs status --current
```


::: {.cell-output .cell-output-stdout}

```
+-----------------+---------+-------+
| path            | status  | size  |
+-----------------+---------+-------+
| data/sub/f3.csv | current | 312 B |
+-----------------+---------+-------+
```


:::
:::



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



::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs status --unsynced
```


::: {.cell-output .cell-output-stdout}

```
+-------------+----------+-------+
| path        | status   | size  |
+-------------+----------+-------+
| data/f1.csv | unsynced | 488 B |
+-------------+----------+-------+
```


:::
:::


Filters combine:


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs status --absent --unsynced
```


::: {.cell-output .cell-output-stdout}

```
+-------------+----------+-------+
| path        | status   | size  |
+-------------+----------+-------+
| data/f1.csv | unsynced | 488 B |
+-------------+----------+-------+
| data/f2.csv | absent   | 500 B |
+-------------+----------+-------+
```


:::
:::


## `--with-metadata`

By default the table shows `path`, `status`, and `size`. `--with-metadata` adds
the hash, creator, add time, compression, and message columns.


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs status --with-metadata
```


::: {.cell-output .cell-output-stdout}

```
+-----------------+----------+-------+------------------------------------------------------------------+------------+-----------------------------+-------------+---------+
| path            | status   | size  | hash                                                             | created_by | add_time                    | compression | message |
+-----------------+----------+-------+------------------------------------------------------------------+------------+-----------------------------+-------------+---------+
| data/f1.csv     | unsynced | 488 B | 5e2c49dd5c8a24a2ffe102e42804812c7eabc2c49682240480558eac390c5d65 | elea       | 2026-06-16T16:36:11.887408Z | zstd        |         |
+-----------------+----------+-------+------------------------------------------------------------------+------------+-----------------------------+-------------+---------+
| data/f2.csv     | absent   | 500 B | c9c0ca2ba19bf1d65159ba2b7300c3336fdf113c92b79901e06be4b40fcd8871 | elea       | 2026-06-16T16:36:11.887448Z | zstd        |         |
+-----------------+----------+-------+------------------------------------------------------------------+------------+-----------------------------+-------------+---------+
| data/sub/f3.csv | current  | 312 B | 881b133ef44731569b7844e1dc60f10e5fc4a9f2c2ac36fe20b2bba636d6bbce | elea       | 2026-06-16T16:36:11.887349Z | zstd        |         |
+-----------------+----------+-------+------------------------------------------------------------------+------------+-----------------------------+-------------+---------+
```


:::
:::


## `--threads`

Override the auto-detected thread count for this command.


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs status --threads 2
```


::: {.cell-output .cell-output-stdout}

```
+-----------------+----------+-------+
| path            | status   | size  |
+-----------------+----------+-------+
| data/f1.csv     | unsynced | 488 B |
+-----------------+----------+-------+
| data/f2.csv     | absent   | 500 B |
+-----------------+----------+-------+
| data/sub/f3.csv | current  | 312 B |
+-----------------+----------+-------+
```


:::
:::


## `--json`

JSON output always includes the full metadata, regardless of `--with-metadata`.


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs status --json
```


::: {.cell-output .cell-output-stdout}

```
[{"path":"data/f1.csv","status":"unsynced","metadata":{"hashes":{"blake3":"5e2c49dd5c8a24a2ffe102e42804812c7eabc2c49682240480558eac390c5d65"},"size":488,"created_by":"elea","add_time":"2026-06-16T16:36:11.887408Z","compression":"zstd"}},{"path":"data/f2.csv","status":"absent","metadata":{"hashes":{"blake3":"c9c0ca2ba19bf1d65159ba2b7300c3336fdf113c92b79901e06be4b40fcd8871"},"size":500,"created_by":"elea","add_time":"2026-06-16T16:36:11.887448Z","compression":"zstd"}},{"path":"data/sub/f3.csv","status":"current","metadata":{"hashes":{"blake3":"881b133ef44731569b7844e1dc60f10e5fc4a9f2c2ac36fe20b2bba636d6bbce"},"size":312,"created_by":"elea","add_time":"2026-06-16T16:36:11.887349Z","compression":"zstd"}}]
```


:::
:::


## Differences from R

The R function is [dvs_status()](r-status.html). It always returns the metadata
columns as a data frame, so there is no `--with-metadata` toggle; select columns
instead. Its filters are a single `status` character vector
(`c("current", "absent", "unsynced")`) rather than independent flags, and it has
no `--threads` or `--json`.

## See also

- [dvs init](cli-init.html), [dvs add](cli-add.html), [dvs get](cli-get.html)
- [Storage and meta files](intro-internals.html)
