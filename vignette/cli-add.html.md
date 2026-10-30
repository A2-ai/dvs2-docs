---
title: "dvs add"
subtitle: "Track files in dvs storage"
format:
  html:
    keep-md: true
execute:
  freeze: auto
---

`dvs add` hashes files, copies their contents into storage, and writes a `.dvs`
meta file next to each one. Pass paths, a glob, or both. At least one path or
`--glob` is required.

```text
Usage: dvs add [OPTIONS] [PATHS]...

Arguments:
  [PATHS]...  Files to add, or directories to search with --glob

Options:
      --glob <GLOB>        Add the files matching this glob
  -m, --message <MESSAGE>  An optional message to record
      --dry-run            Show what would be added without changing anything
  -h, --help               Print help

Global Options:
      --json               Output results as JSON
      --emit-events        Stream results and progress as NDJSON
      --threads <THREADS>  Threads (0 = auto-detect)
```

## Options

| Flag | Argument | Default | Behavior |
|---|---|---|---|
| `[PATHS]...` | paths | none | Files to add. Shell expands any globs before dvs sees them. |
| `--glob` | pattern | none | Library-expanded glob. Uses a literal path separator (see below). |
| `-m`, `--message` | text | none | Message recorded in each meta file. |
| `--dry-run` | flag | off | Report what would be added. Write nothing. |
| `--threads` | integer | `0` (auto) | Thread pool size for this command. |
| `--json` | flag | off | Emit results as JSON. |

## Setup


::: {.cell}

```{.r .cell-code}
options(width = 1000)
library(here)
proj    <- here::here(basename(tempfile(fileext = "_project")))
storage <- here::here(basename(tempfile(fileext = "_storage")))
dir.create(proj)
dir.create(storage)
dir.create(file.path(proj, "data"))
dir.create(file.path(proj, "glob", "nested"), recursive = TRUE)
write.csv(Theoph, file.path(proj, "data", "theoph.csv"), row.names = FALSE)
write.csv(mtcars[1:8, ],   file.path(proj, "data", "cars_a.csv"))
write.csv(mtcars[9:16, ],  file.path(proj, "data", "cars_b.csv"))
write.csv(iris[1:10, ],    file.path(proj, "glob", "g1.csv"), row.names = FALSE)
write.csv(iris[11:20, ],   file.path(proj, "glob", "g2.csv"), row.names = FALSE)
write.csv(iris[21:30, ],   file.path(proj, "glob", "nested", "g3.csv"), row.names = FALSE)
Sys.setenv(DVS_PROJECT = proj, DVS_STORAGE = storage)
```
:::



::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs init local "$DVS_STORAGE"
```


::: {.cell-output .cell-output-stdout}

```
DVS Initialized at /Users/elea/Documents/a2ai_github/dvs2-demo-repo/filed5ec2e689b63_project
```


:::
:::


## Paths

Add a single file. The output reports the on-disk size, the stored (compressed)
size, and the content hash.


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs add data/theoph.csv
```


::: {.cell-output .cell-output-stdout}

```
Added: data/theoph.csv [2.9 KB] --> saved [842 B] as cdd978e51298006701f7b285aaf979933f0af6b179bbdf3347014af3bcd48c06

Added 1
```


:::
:::


Add several files in one call.


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs add data/cars_a.csv data/cars_b.csv
```


::: {.cell-output .cell-output-stdout}

```
Added: data/cars_a.csv [488 B] --> saved [306 B] as 5e2c49dd5c8a24a2ffe102e42804812c7eabc2c49682240480558eac390c5d65
Added: data/cars_b.csv [500 B] --> saved [275 B] as c9c0ca2ba19bf1d65159ba2b7300c3336fdf113c92b79901e06be4b40fcd8871

Added 2
```


:::
:::


## `-m`, `--message`

Record a message in the meta files.


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs add glob/g1.csv -m "iris head sample"
```


::: {.cell-output .cell-output-stdout}

```
Added: glob/g1.csv [312 B] --> saved [140 B] as 881b133ef44731569b7844e1dc60f10e5fc4a9f2c2ac36fe20b2bba636d6bbce

Added 1
```


:::
:::


## `--glob`

A library-expanded glob uses a literal path separator: `*.csv` matches files in
the target directory only, not in subdirectories. Here `glob/*.csv` skips the
nested file.


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs add --glob "glob/*.csv"
```


::: {.cell-output .cell-output-stdout}

```
Unchanged: glob/g1.csv [312 B] already tracked
Added: glob/g2.csv [312 B] --> saved [147 B] as a8eebfc0b894a2818e8c9edffe742df01a934073e3602a978836d622665786f7

Added 1, 1 unchanged
```


:::
:::


::: {.callout-tip}
Use `**` to cross directory boundaries. `glob/**/*.csv` matches the nested file
that `glob/*.csv` skipped.
:::


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs add --glob "glob/**/*.csv"
```


::: {.cell-output .cell-output-stdout}

```
Unchanged: glob/g1.csv [312 B] already tracked
Unchanged: glob/g2.csv [312 B] already tracked
Added: glob/nested/g3.csv [310 B] --> saved [146 B] as 6d19965b2ae61ed235114e9739c4e1d1d52994d3be9f95e436ac1b7c69bb4582

Added 1, 2 unchanged
```


:::
:::


## `--dry-run`

Report what would be added without writing blobs or meta files.


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
printf "a,b\n1,2\n" > data/preview.csv
dvs add data/preview.csv --dry-run
```


::: {.cell-output .cell-output-stdout}

```
To add: data/preview.csv [8 B] as c42223f1fbf292f60491e1d0666e49af4b7eb75a63385041b98391acecf68562

Would add 1
```


:::
:::


## `--threads`

Override the auto-detected thread count for this command.


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
printf "c,d\n3,4\n" > data/threaded.csv
dvs add data/threaded.csv --threads 2
```


::: {.cell-output .cell-output-stdout}

```
Added: data/threaded.csv [8 B] --> saved [17 B] as 6693c03bd85d4f549a20ce2ddc42bad62ecf28bc6a9d3e717d434a30100ef3d6

Added 1
```


:::
:::


## `--json`

The result is one versioned object: `command`, `outcome`, `counts`, `bytes`,
timings, and a `files` list with a row per file (`path`, `outcome` (`copied` or
`present`), `hash`, `size`, `stored_size`, `duration_ms`, and `code`, `message`
and `hint` for a failure).


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
printf "e,f\n5,6\n" > data/as_json.csv
dvs add data/as_json.csv --json
```


::: {.cell-output .cell-output-stdout}

```
{"bytes":{"already_stored":0,"to_transfer":8,"total":8,"transferred":8},"command":"add","counts":{"cancelled":0,"failed":0,"succeeded":1,"total":1},"dry_run":false,"duration_ms":3,"error":null,"files":[{"code":null,"duration_ms":2,"hash":"30d20548da5fc9cabc8f23c2e8ad91195de922e541627f2ef5402967546f78e3","hint":null,"message":null,"outcome":"copied","path":"data/as_json.csv","size":8,"stored_size":17}],"finished_at":"2026-10-30T18:41:09.104Z","outcome":"complete","started_at":"2026-10-30T18:41:09.100Z","v":1}
```


:::
:::


## Invalid paths refuse the batch

Input paths are validated before anything is written. A directory passed
without a glob, or a path outside the project root, refuses the whole batch:
nothing is added, and `add` exits 2.


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs add data data/threaded.csv; echo "exit code: $?"
```


::: {.cell-output .cell-output-stdout}

```
Error: Refusing to add, the following paths are invalid:
  data: path is a directory
exit code: 2
```


:::
:::


A path that does not exist stops `add` the same way, with "Path not found" and
exit code 1.


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs add data/missing.csv; echo "exit code: $?"
```


::: {.cell-output .cell-output-stdout}

```
Error: Path not found: data/missing.csv
exit code: 1
```


:::
:::


A failure in the copy phase of an already valid batch behaves differently.
Files that can be copied are still added, the failing ones are reported per
file, and `add` exits 1 all the same.

## Differences from R

The R function is [dvs_add()](r-add.html). It returns a data frame rather than
printed lines, has no `--threads` or `--json`, and shows a progress bar only in
interactive sessions, rather than always printing one.

## See also

- [dvs init](cli-init.html), [dvs status](cli-status.html), [dvs get](cli-get.html)
- [Storage and meta files](intro-internals.html)
- [The audit log](audit.html)
