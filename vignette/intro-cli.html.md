---
title: "The CLI in depth"
subtitle: "globs, dry runs, tables, JSON, recursive retrieval, and exit codes"
format:
  html:
    keep-md: true
execute:
  freeze: auto
---

[Introducing dvs](intro.html) showed that the CLI and the R package operate on
the same project interchangeably. This page is the terminal side of the story:
the same verbs, plus the things a shell wants that an R session does not,
table output for humans, JSON for pipelines, and exit codes that scripts can
branch on. The R equivalent is [the R package in depth](intro-r.html).

## Setup

R generates the sandbox directories and data files; every dvs operation below
runs through the `dvs` binary.


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
:::



::: {.cell}

```{.r .cell-code}
source(here::here("R/mkdatasetfiles.R"))
```
:::



::: {.cell}

```{.r .cell-code}
storage     <- basename(tempfile(fileext = "_storage"))
new_project <- basename(tempfile(fileext = "_project"))
dir.create(here::here(storage))
dir.create(here::here(new_project))

setwd(here::here(new_project))
mkdatasetfiles(n_files = 1,  size_mb = 25, prefix = "large_",      dir = "data/large",      show_progress = FALSE)
mkdatasetfiles(n_files = 3,  size_mb = 1,  prefix = "small_",      dir = "data/small",      show_progress = FALSE)
mkdatasetfiles(n_files = 50, size_mb = 3,  prefix = "individual_", dir = "data/individual", show_progress = FALSE)

Sys.setenv(DVS_PROJECT = here::here(new_project), DVS_STORAGE = here::here(storage))
```
:::


## dvs init


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs init local "$DVS_STORAGE"
cat dvs.toml
```


::: {.cell-output .cell-output-stdout}

```
DVS Initialized at /Users/elea/Documents/a2ai_github/dvs2-demo-repo/file871f465edab1_project
compression = "zstd"

[backend]
path = "/Users/elea/Documents/a2ai_github/dvs2-demo-repo/file871f6ee81399_storage"
group = "staff"
```


:::
:::


`dvs.toml` is the entire project configuration. Commit it.

## dvs add

A single file, with a message worth reading later:


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs add data/large/large_1.csv -m "one large dataset"
```


::: {.cell-output .cell-output-stdout}

```
Added: data/large/large_1.csv [25.0 MB] --> saved [10.5 MB] as 3c77885f59933a6334a438d0a77d2adcd06873bed58a00fc9807fce3d13ed838

Added 1
```


:::
:::


Each line reports the size on disk, the compressed size that landed in
storage, and the content hash.

Many files at once, with a glob. Quote it: the glob is resolved by dvs, not
the shell, so it behaves identically to `glob =` in the R package:


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs add --glob "data/small/*.csv" -m "small corpus"
dvs add --glob "data/individual/individual_*.csv" -m "individual datasets" | tail -3
```


::: {.cell-output .cell-output-stdout}

```
Added: data/small/small_1.csv [1024.0 KB] --> saved [427.8 KB] as e0fb0b7aac778f07ba37105d2e2a70d1cee429f50d77c3b0c9dd4ad4d2222937
Added: data/small/small_2.csv [1024.0 KB] --> saved [427.9 KB] as 1574af6b3e5cfd7fdba90c4f819fbd2bd128cd573c304588623fc09d49ae6b04
Added: data/small/small_3.csv [1024.0 KB] --> saved [428.1 KB] as 9d97b050e954474b51c5b3f06eafd07bc33366b9f3b09ea1211ac75c2704357a

Added 3
Added: data/individual/individual_50.csv [3.0 MB] --> saved [1.3 MB] as b05327be23b5f7172df2b5c2a19ba2a214b6d8c01d87f6231563a2b2dd9f464b

Added 50
```


:::
:::


### Dry runs

`--dry-run` prints what would be added without writing anything. The output
is deliberately identical to a real run, so read it before you trust it, and
note that nothing below says "added":


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
echo "1,2,3" > data/small/new_file.csv
dvs add --glob "data/small/*.csv" --dry-run
```


::: {.cell-output .cell-output-stdout}

```
To add: data/small/new_file.csv [6 B] as 8ebd15e1b413963410d68a325723e4bc165afcd389a860e601b5aee8731e570e
Unchanged: data/small/small_1.csv [1024.0 KB] already tracked
Unchanged: data/small/small_2.csv [1024.0 KB] already tracked
Unchanged: data/small/small_3.csv [1024.0 KB] already tracked

Would add 1, 3 unchanged
```


:::
:::


### The meta file

Every tracked file has a JSON sidecar under `.dvs/`, and that sidecar is what
git versions:


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
cat .dvs/data/large/large_1.csv.dvs
```


::: {.cell-output .cell-output-stdout}

```
{
  "hashes": {
    "blake3": "3c77885f59933a6334a438d0a77d2adcd06873bed58a00fc9807fce3d13ed838"
  },
  "size": 26214390,
  "created_by": "elea",
  "add_time": "2026-10-30T11:11:57.682029Z",
  "compression": "zstd",
  "message": "one large dataset"
}
```


:::
:::


## dvs status

Human-readable by default, one row per tracked file:


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
rm data/small/new_file.csv
dvs status data/large data/small
```


::: {.cell-output .cell-output-stdout}

```
+------------------------+---------+-----------+
| path                   | status  | size      |
+------------------------+---------+-----------+
| data/large/large_1.csv | current |   25.0 MB |
+------------------------+---------+-----------+
| data/small/small_1.csv | current | 1024.0 KB |
+------------------------+---------+-----------+
| data/small/small_2.csv | current | 1024.0 KB |
+------------------------+---------+-----------+
| data/small/small_3.csv | current | 1024.0 KB |
+------------------------+---------+-----------+

Checked 4
```


:::
:::


Make some work for it: delete three files and modify one.


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
rm data/individual/individual_04.csv data/individual/individual_08.csv data/individual/individual_15.csv
echo "99,0,0,0,0,0" >> data/large/large_1.csv
```
:::


The `--absent` and `--modified` flags filter. Without flags you get all
statuses:


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs status --absent
dvs status --modified
```


::: {.cell-output .cell-output-stdout}

```
+-----------------------------------+--------+--------+
| path                              | status | size   |
+-----------------------------------+--------+--------+
| data/individual/individual_04.csv | absent | 3.0 MB |
+-----------------------------------+--------+--------+
| data/individual/individual_08.csv | absent | 3.0 MB |
+-----------------------------------+--------+--------+
| data/individual/individual_15.csv | absent | 3.0 MB |
+-----------------------------------+--------+--------+

Checked 3
+------------------------+----------+---------+
| path                   | status   | size    |
+------------------------+----------+---------+
| data/large/large_1.csv | modified | 25.0 MB |
+------------------------+----------+---------+

Checked 1
```


:::
:::


`--with-metadata` widens the table with the hash, author, timestamp,
compression, and message:


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs status --modified --with-metadata
```


::: {.cell-output .cell-output-stdout}

```
+------------------------+----------+---------+------------------------------------------------------------------+------------+-----------------------------+-------------+-------------------+
| path                   | status   | size    | hash                                                             | created_by | add_time                    | compression | message           |
+------------------------+----------+---------+------------------------------------------------------------------+------------+-----------------------------+-------------+-------------------+
| data/large/large_1.csv | modified | 25.0 MB | 3c77885f59933a6334a438d0a77d2adcd06873bed58a00fc9807fce3d13ed838 | elea       | 2026-10-30T11:11:57.682029Z | zstd        | one large dataset |
+------------------------+----------+---------+------------------------------------------------------------------+------------+-----------------------------+-------------+-------------------+

Checked 1
```


:::
:::


### JSON output

Every command takes `--json`. The result is machine-readable and stable,
which makes the CLI scriptable from anything:


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs status --absent --json | python3 -m json.tool | head -20
```


::: {.cell-output .cell-output-stdout}

```
{
    "command": "status",
    "counts": {
        "cancelled": 0,
        "failed": 0,
        "succeeded": 3,
        "total": 3
    },
    "dry_run": false,
    "duration_ms": 12,
    "error": null,
    "files": [
        {
            "baseline": {
                "blake3": "388c35ea1e0f0f55cd73c6d6e84ad7659b3954f271103b51bcc868f9f07d1aee",
                "size": 3145709
            },
            "code": null,
            "hint": null,
            "message": null,
```


:::
:::


## dvs get

Restore the absent files by glob:


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs get --glob "data/individual/individual_*.csv"
```


::: {.cell-output .cell-output-stdout}

```
restored      data/individual/individual_04.csv  3.0 MB
restored      data/individual/individual_08.csv  3.0 MB
restored      data/individual/individual_15.csv  3.0 MB

Restored 3, 47 already current
```


:::
:::


Re-add the modified file to bring the project back to all `current`:


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs add data/large/large_1.csv -m "append row 99"
```


::: {.cell-output .cell-output-stdout}

```
Added: data/large/large_1.csv [25.0 MB] --> saved [10.5 MB] as 5e21922b470b3f9850c69729e53eb73df300672e6f43279aa43c7f252e54d03c

Added 1
```


:::
:::


### Directory scoping and --recursive

`get` and `status` accept directory paths, which cover their direct children
only. `-r/--recursive` walks the whole subtree, and it is mutually exclusive
with `--glob`. `get` always needs at least one path or a glob, so "restore
everything" from the project root is `dvs get . -r` (or, equivalently,
`dvs get --glob '**/*'`):


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
rm -r data
dvs get . -r | tail -3
dvs status --absent
```


::: {.cell-output .cell-output-stdout}

```
restored      data/small/small_3.csv             1024.0 KB

Restored 54
No tracked files matching the filter
```


:::
:::


Nothing absent: the whole `data/` tree came back from storage.

## Exit codes

The CLI is built for pipelines, so failures are visible to the shell. A
request naming an untracked path is refused as a whole (nothing happens) and
exits nonzero:


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs get data/no_such_file.csv || echo "exit code: $?"
```


::: {.cell-output .cell-output-stdout}

```
failed        data/no_such_file.csv  not tracked by dvs

Aborted, nothing changed: 1 file cannot be retrieved
  data/no_such_file.csv: check the path; list tracked files with: dvs status
exit code: 1
```


:::
:::


`status` treats unknown paths more gently, because "show me what matches" is
a question, not an instruction: unmatched paths are dropped and the command
still exits 0:


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs status data/large data/no_such_dir && echo "exit code: 0"
```


::: {.cell-output .cell-output-stdout}

```
+------------------------+---------+---------+
| path                   | status  | size    |
+------------------------+---------+---------+
| data/large/large_1.csv | current | 25.0 MB |
+------------------------+---------+---------+

Checked 1
exit code: 0
```


:::
:::


## Threads

`add`, `get`, and `status` hash and copy in parallel. `--threads` overrides
the auto-detected pool for one invocation; the `DVS_NUM_THREADS` environment
variable does it globally:


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs status --threads 2 | tail -3
```


::: {.cell-output .cell-output-stdout}

```
+-----------------------------------+---------+-----------+

Checked 54
```


:::
:::


## Cleanup


::: {.cell}

```{.r .cell-code}
unlink(here::here(new_project), recursive = TRUE)
unlink(here::here(storage),     recursive = TRUE)
```
:::


## Where to go next

- [Collaboration](collab.html): two users, one storage, and what to commit.
- Reference, one page per command: [dvs init](cli-init.html),
  [dvs add](cli-add.html), [dvs status](cli-status.html), [dvs get](cli-get.html).
- [Storage and meta files](intro-internals.html): what is actually in `.dvs/`
  and the storage directory.
