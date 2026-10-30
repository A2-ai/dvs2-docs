---
title: "dvs status"
subtitle: "Report the sync status of tracked files"
format:
  html:
    keep-md: true
execute:
  freeze: auto
---

`dvs status` reports each tracked file with one of five statuses:

- `current`: on disk and matching the tracked version.
- `absent`: tracked but missing on disk.
- `stale`: on disk as dvs last wrote or added it, while the tracked version has
  changed since, for example after a `git pull`. `dvs get` updates it.
- `modified`: on disk, but different from the tracked version and from what dvs
  last wrote or added there. This is a local edit.
- `unsynced`: on disk and different from the tracked version, with no record of
  what dvs last wrote there.

A file whose metadata cannot be read is listed with status `error`. By default
`dvs status` prints a compact table and a `Checked N` summary line.

```text
Usage: dvs status [OPTIONS] [PATHS]...

Arguments:
  [PATHS]...  Paths (files or directories) to check status for

Options:
  -r, --recursive          Recurse into subdirectories of given directories
  -g, --glob <GLOB>        Only include the tracked files matching this glob
      --current            Include current files
      --absent             Include absent files
      --stale              Include stale files
      --modified           Include modified files
      --unsynced           Include unsynced files
      --with-metadata      Show all metadata columns
  -h, --help               Print help

Global Options:
      --json               Output results as JSON
      --emit-events        Stream results and progress as NDJSON
      --threads <THREADS>  Threads (0 = auto-detect)
```

## Options

| Flag | Argument | Default | Behavior |
|---|---|---|---|
| `[PATHS]...` | paths | whole project | Files or directories to report. |
| `-r`, `--recursive` | flag | off | Include files in subdirectories of given directories. |
| `-g`, `--glob` | pattern | none | Library-expanded glob, literal path separator (use `**` to recurse). |
| `--current` | flag | off | Include `current` files. |
| `--absent` | flag | off | Include `absent` files. |
| `--stale` | flag | off | Include `stale` files. |
| `--modified` | flag | off | Include `modified` files. |
| `--unsynced` | flag | off | Include `unsynced` files. |
| `--with-metadata` | flag | off | Add hash, created_by, add_time, compression, message columns. |
| `--threads` | integer | `0` (auto) | Thread pool size for this command. |
| `--json` | flag | off | Emit results as JSON. |

The five status flags are independent booleans and combine. With none set, all
statuses are shown.

## Setup

Add three files, then delete one and edit another, so `current`, `absent` and
`modified` appear.


::: {.cell}

```{.r .cell-code}
options(width = 1000)
library(here)
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
dvs init local "$DVS_STORAGE" >/dev/null
dvs add data/f1.csv data/f2.csv data/sub/f3.csv >/dev/null
rm data/f2.csv                      # -> absent
echo "extra,row" >> data/f1.csv     # -> modified
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
| data/f1.csv     | modified | 488 B |
+-----------------+----------+-------+
| data/f2.csv     | absent   | 500 B |
+-----------------+----------+-------+
| data/sub/f3.csv | current  | 312 B |
+-----------------+----------+-------+

Checked 3
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

Checked 1
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
| data/f1.csv | modified | 488 B |
+-------------+----------+-------+
| data/f2.csv | absent   | 500 B |
+-------------+----------+-------+

Checked 2
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
| data/f1.csv     | modified | 488 B |
+-----------------+----------+-------+
| data/f2.csv     | absent   | 500 B |
+-----------------+----------+-------+
| data/sub/f3.csv | current  | 312 B |
+-----------------+----------+-------+

Checked 3
```


:::
:::


## `-g`, `--glob`

Report the files matching a library-expanded glob. The path separator is
literal, so `data/*.csv` stops at `data/`; use `**` to cross directory
boundaries.


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs status -g "data/*.csv"
```


::: {.cell-output .cell-output-stdout}

```
+-------------+----------+-------+
| path        | status   | size  |
+-------------+----------+-------+
| data/f1.csv | modified | 488 B |
+-------------+----------+-------+
| data/f2.csv | absent   | 500 B |
+-------------+----------+-------+

Checked 2
```


:::
:::


`--recursive` and `--glob` are mutually exclusive; passing both is a usage
error.

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

Checked 1
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

Checked 1
```


:::
:::



::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs status --modified
```


::: {.cell-output .cell-output-stdout}

```
+-------------+----------+-------+
| path        | status   | size  |
+-------------+----------+-------+
| data/f1.csv | modified | 488 B |
+-------------+----------+-------+

Checked 1
```


:::
:::


Filters combine:


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs status --absent --modified
```


::: {.cell-output .cell-output-stdout}

```
+-------------+----------+-------+
| path        | status   | size  |
+-------------+----------+-------+
| data/f1.csv | modified | 488 B |
+-------------+----------+-------+
| data/f2.csv | absent   | 500 B |
+-------------+----------+-------+

Checked 2
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
| data/f1.csv     | modified | 488 B | 5e2c49dd5c8a24a2ffe102e42804812c7eabc2c49682240480558eac390c5d65 | elea       | 2026-10-30T11:10:18.777289Z | zstd        |         |
+-----------------+----------+-------+------------------------------------------------------------------+------------+-----------------------------+-------------+---------+
| data/f2.csv     | absent   | 500 B | c9c0ca2ba19bf1d65159ba2b7300c3336fdf113c92b79901e06be4b40fcd8871 | elea       | 2026-10-30T11:10:18.777213Z | zstd        |         |
+-----------------+----------+-------+------------------------------------------------------------------+------------+-----------------------------+-------------+---------+
| data/sub/f3.csv | current  | 312 B | 881b133ef44731569b7844e1dc60f10e5fc4a9f2c2ac36fe20b2bba636d6bbce | elea       | 2026-10-30T11:10:18.777231Z | zstd        |         |
+-----------------+----------+-------+------------------------------------------------------------------+------------+-----------------------------+-------------+---------+

Checked 3
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
| data/f1.csv     | modified | 488 B |
+-----------------+----------+-------+
| data/f2.csv     | absent   | 500 B |
+-----------------+----------+-------+
| data/sub/f3.csv | current  | 312 B |
+-----------------+----------+-------+

Checked 3
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
{"command":"status","counts":{"cancelled":0,"failed":0,"succeeded":3,"total":3},"dry_run":false,"duration_ms":0,"error":null,"files":[{"baseline":{"blake3":"5e2c49dd5c8a24a2ffe102e42804812c7eabc2c49682240480558eac390c5d65","size":488},"code":null,"hint":null,"message":null,"metadata":{"add_time":"2026-10-30T11:10:18.777289Z","compression":"zstd","created_by":"elea","hashes":{"blake3":"5e2c49dd5c8a24a2ffe102e42804812c7eabc2c49682240480558eac390c5d65"},"size":488},"path":"data/f1.csv","status":"modified","working":{"hash_source":"cache","hashes":{"blake3":"e4296ff77df5d7d480fed68bb1104ab94a6eaa46f1913b7590a7173b379fd509"},"size":498,"state":"present"}},{"baseline":{"blake3":"c9c0ca2ba19bf1d65159ba2b7300c3336fdf113c92b79901e06be4b40fcd8871","size":500},"code":null,"hint":null,"message":null,"metadata":{"add_time":"2026-10-30T11:10:18.777213Z","compression":"zstd","created_by":"elea","hashes":{"blake3":"c9c0ca2ba19bf1d65159ba2b7300c3336fdf113c92b79901e06be4b40fcd8871"},"size":500},"path":"data/f2.csv","status":"absent","working":{"hash_source":null,"hashes":null,"size":null,"state":"absent"}},{"baseline":{"blake3":"881b133ef44731569b7844e1dc60f10e5fc4a9f2c2ac36fe20b2bba636d6bbce","size":312},"code":null,"hint":null,"message":null,"metadata":{"add_time":"2026-10-30T11:10:18.777231Z","compression":"zstd","created_by":"elea","hashes":{"blake3":"881b133ef44731569b7844e1dc60f10e5fc4a9f2c2ac36fe20b2bba636d6bbce"},"size":312},"path":"data/sub/f3.csv","status":"current","working":{"hash_source":"cache","hashes":{"blake3":"881b133ef44731569b7844e1dc60f10e5fc4a9f2c2ac36fe20b2bba636d6bbce"},"size":312,"state":"present"}}],"finished_at":"2026-10-30T11:10:19.016Z","outcome":"complete","started_at":"2026-10-30T11:10:19.015Z","v":1}
```


:::
:::


## Differences from R

The R function is [dvs_status()](r-status.html). It always returns the metadata
columns as a data frame, so there is no `--with-metadata` toggle; select columns
instead. Its filters are a single `status` character vector
(`c("current", "absent", "stale", "modified", "unsynced")`) rather than
independent flags, and it has
no `--threads` or `--json`.

## See also

- [dvs init](cli-init.html), [dvs add](cli-add.html), [dvs get](cli-get.html)
- [Storage and meta files](intro-internals.html)
