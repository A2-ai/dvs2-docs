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

A local file that differs from the tracked version is replaced without asking
only when dvs itself put it there, for example after switching git branches.
Otherwise it is a conflict, handled by `--on-conflict`.

```text
Usage: dvs get [OPTIONS] [PATHS]...

Arguments:
  [PATHS]...  Tracked files or directories to retrieve

Options:
  -g, --glob <GLOB>           Only retrieve the tracked files matching this glob
  -r, --recursive             Recurse into subdirectories of directory inputs
      --dry-run               Show what would be retrieved without writing files
      --on-conflict <POLICY>  abort, skip or overwrite files with local changes
  -f, --force                 Same as --on-conflict overwrite
  -h, --help                  Print help

Global Options:
      --json                  Output results as JSON
      --emit-events           Stream results and progress as NDJSON
      --threads <THREADS>     Threads (0 = auto-detect)
```

## Options

| Flag | Argument | Default | Behavior |
|---|---|---|---|
| `[PATHS]...` | paths | none | Files to retrieve. |
| `-g`, `--glob` | pattern | none | Library-expanded glob, literal path separator (use `**` to recurse). |
| `-r`, `--recursive` | flag | off | Walk subdirectories of directory inputs. Without it, a directory retrieves only its direct children. |
| `--dry-run` | flag | off | Report what would be retrieved. Write nothing. |
| `--on-conflict` | `abort`, `skip`, `overwrite` | `DVS_GET_ON_CONFLICT`, then `[get] on_conflict` in `dvs.toml`, then `abort` | What to do with files that have local changes. `abort` changes nothing, `skip` leaves them and gets the rest, `overwrite` replaces them. |
| `-f`, `--force` | flag | off | Same as `--on-conflict overwrite`. |
| `--threads` | integer | `0` (auto) | Thread pool size for this command. |
| `--json` | flag | off | Emit results as JSON. |

`--recursive` and `--glob` are mutually exclusive. At least one path or
`--glob` is required; `dvs get` with neither is a usage error.

::: {.callout-note}
`get` exposes a short `-g` for `--glob`; `add` only has the long `--glob`.
:::

## Setup

Add three files, then delete them so `get` has something to restore.


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

Checked 3
```


:::
:::


## Paths

Restore a single file. Output lists each retrieved file and a summary line.


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs get data/f1.csv
```


::: {.cell-output .cell-output-stdout}

```
restored      data/f1.csv  488 B

Restored 1
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

Checked 1
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
restored      data/f2.csv      500 B
restored      data/sub/f3.csv  312 B

Restored 2, 1 already current
```


:::
:::


## `-r`, `--recursive`

A directory argument retrieves only the files directly in it. Here the nested
`data/sub/f3.csv` is left alone.


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
rm data/f1.csv data/f2.csv data/sub/f3.csv
dvs get data
dvs status --absent
```


::: {.cell-output .cell-output-stdout}

```
restored      data/f1.csv  488 B
restored      data/f2.csv  500 B

Restored 2
+-----------------+--------+-------+
| path            | status | size  |
+-----------------+--------+-------+
| data/sub/f3.csv | absent | 312 B |
+-----------------+--------+-------+

Checked 1
```


:::
:::


With `-r` the rest of the subtree is retrieved.


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs get data -r
```


::: {.cell-output .cell-output-stdout}

```
restored      data/sub/f3.csv  312 B

Restored 1, 2 already current
```


:::
:::


## Restore the whole project

`get` needs at least one path or a `--glob`, so there is no bare `dvs get` that
means "everything". Pass the project root as a recursive directory instead: from
the root, `dvs get . -r` restores every tracked file. A directory argument is
resolved from where you run it, so the same command in a subdirectory restores
only that subtree.


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
rm data/f1.csv data/f2.csv data/sub/f3.csv
dvs get . -r
```


::: {.cell-output .cell-output-stdout}

```
restored      data/f1.csv      488 B
restored      data/f2.csv      500 B
restored      data/sub/f3.csv  312 B

Restored 3
```


:::
:::


`dvs get -g '**/*'` does the same thing through the glob surface. Quote the
pattern so the shell does not expand it first.

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
would restore data/f2.csv  500 B

Would restore 1
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

Checked 1
```


:::
:::


## `--on-conflict`, `-f`

Edit a tracked file, so it is `modified`. With the default, `abort`, `get`
changes no file at all, not even the absent `data/f2.csv`, and exits non-zero.
It says why and what to do.


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
echo "extra,row" >> data/f1.csv
dvs get data/f1.csv data/f2.csv
echo "exit code: $?"
```


::: {.cell-output .cell-output-stdout}

```
not run       data/f1.csv  local changes since dvs last wrote this file
not run       data/f2.csv  held back: another requested file has a problem

Aborted, nothing changed: 1 file has local changes
on_conflict = abort (default)
  keep your version:         dvs add data/f1.csv   (makes it the tracked version)
  get the other files:       rerun with --on-conflict skip
  take the tracked version:  dvs get --force data/f1.csv   (replaces yours; copy it first to keep both)
exit code: 3
```


:::
:::


`--on-conflict skip` leaves the conflicting file and gets the rest:


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs get data/f1.csv data/f2.csv --on-conflict skip
```


::: {.cell-output .cell-output-stdout}

```
skipped       data/f1.csv  local changes since dvs last wrote this file
restored      data/f2.csv  500 B

Partial: restored 1, skipped 1
on_conflict = skip (argument)
  keep your version:         dvs add data/f1.csv   (makes it the tracked version)
  take the tracked version:  dvs get --force data/f1.csv   (replaces yours; copy it first to keep both)
```


:::
:::


`--force` (or `--on-conflict overwrite`) replaces it with the tracked version.
The local changes are lost.


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs get data/f1.csv --force
dvs status data/f1.csv
```


::: {.cell-output .cell-output-stdout}

```
replaced      data/f1.csv  local changes were discarded

Replaced 1
on_conflict = overwrite (argument)
+-------------+---------+-------+
| path        | status  | size  |
+-------------+---------+-------+
| data/f1.csv | current | 488 B |
+-------------+---------+-------+

Checked 1
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
Nothing to do, 1 already current
```


:::
:::


## `--json`

The result is one versioned object: `command`, `outcome`, `counts`, `bytes`,
timings, and a `files` list with a row per file (`path`, `before`, `action`,
`satisfied`, `size`, the hashes, and `code`, `message` and `hint` for a
problem).


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs get data/f1.csv --json
```


::: {.cell-output .cell-output-stdout}

```
{"bytes":{"already_stored":488,"to_transfer":0,"total":488,"transferred":0},"command":"get","counts":{"cancelled":0,"failed":0,"not_run":0,"replaced":0,"restored":0,"skipped":0,"succeeded":1,"total":1,"unchanged":1,"would_replace":0,"would_restore":0},"dry_run":false,"duration_ms":1,"error":null,"files":[{"action":"unchanged","before":"current","code":null,"duration_ms":0,"hint":null,"local_hash":"5e2c49dd5c8a24a2ffe102e42804812c7eabc2c49682240480558eac390c5d65","local_path":"data/f1.csv","message":null,"path":"data/f1.csv","satisfied":true,"size":488,"stored_copy":null,"target_hash":"5e2c49dd5c8a24a2ffe102e42804812c7eabc2c49682240480558eac390c5d65"}],"finished_at":"2026-10-30T18:41:20.069Z","on_conflict":"abort","outcome":"complete","source":"default","started_at":"2026-10-30T18:41:20.067Z","v":1}
```


:::
:::


## Differences from R

The R function is [dvs_get()](r-get.html). It returns a data frame rather than
printed lines, has no `--threads` or `--json`, and shows a progress bar only in
interactive sessions. It takes `on_conflict` like `--on-conflict` but has no
`--force`. Where the CLI exits non-zero, it returns the result, and its
`on_error` argument can make it warn or raise an error instead.

## See also

- [dvs init](cli-init.html), [dvs add](cli-add.html), [dvs status](cli-status.html)
- [Storage and meta files](intro-internals.html)
