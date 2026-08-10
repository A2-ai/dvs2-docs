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
dvs init "$DVS_STORAGE"
cat dvs.toml
```


::: {.cell-output .cell-output-stdout}

```
DVS Initialized at "/Users/elea/Documents/a2ai_github/dvs2-demo-repo/filef81a602de52a_project"
compression = "zstd"

[backend]
path = "/Users/elea/Documents/a2ai_github/dvs2-demo-repo/filef81a22e6d31c_storage"
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
Added: data/individual/individual_48.csv [3.0 MB] --> saved [1.3 MB] as 7d62b45f3c50dcaf1f3143a9c67d5a1606b58660359405f533483713157d3ce2
Added: data/individual/individual_49.csv [3.0 MB] --> saved [1.3 MB] as d855539255e6bcef2bdb7b3be9c727312db4c8eb6229851bb2ddd71667bde6e3
Added: data/individual/individual_50.csv [3.0 MB] --> saved [1.3 MB] as b05327be23b5f7172df2b5c2a19ba2a214b6d8c01d87f6231563a2b2dd9f464b
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
  "add_time": "2026-08-10T15:26:23.051906Z",
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


The `--absent` and `--unsynced` flags filter; without flags you get all
states:


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs status --absent
dvs status --unsynced
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
+------------------------+----------+---------+
| path                   | status   | size    |
+------------------------+----------+---------+
| data/large/large_1.csv | unsynced | 25.0 MB |
+------------------------+----------+---------+
```


:::
:::


`--with-metadata` widens the table with the hash, author, timestamp,
compression, and message:


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs status --unsynced --with-metadata
```


::: {.cell-output .cell-output-stdout}

```
+------------------------+----------+---------+------------------------------------------------------------------+------------+-----------------------------+-------------+-------------------+
| path                   | status   | size    | hash                                                             | created_by | add_time                    | compression | message           |
+------------------------+----------+---------+------------------------------------------------------------------+------------+-----------------------------+-------------+-------------------+
| data/large/large_1.csv | unsynced | 25.0 MB | 3c77885f59933a6334a438d0a77d2adcd06873bed58a00fc9807fce3d13ed838 | elea       | 2026-08-10T15:26:23.051906Z | zstd        | one large dataset |
+------------------------+----------+---------+------------------------------------------------------------------+------------+-----------------------------+-------------+-------------------+
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
[
    {
        "path": "data/individual/individual_04.csv",
        "status": "absent",
        "metadata": {
            "hashes": {
                "blake3": "388c35ea1e0f0f55cd73c6d6e84ad7659b3954f271103b51bcc868f9f07d1aee"
            },
            "size": 3145709,
            "created_by": "elea",
            "add_time": "2026-08-10T15:26:23.261707Z",
            "compression": "zstd",
            "message": "individual datasets"
        }
    },
    {
        "path": "data/individual/individual_08.csv",
        "status": "absent",
        "metadata": {
            "hashes": {
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
data/individual/individual_04.csv [3.0 MB]
data/individual/individual_08.csv [3.0 MB]
data/individual/individual_15.csv [3.0 MB]
Total: 3 files, 9.0 MB
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
```


:::
:::


### Directory scoping and --recursive

`get` and `status` accept directory paths, which cover their direct children
only. `-r/--recursive` walks the whole subtree. With no paths at all, `get`
scopes to the current directory, so at the project root `dvs get -r` means
"restore everything":


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
rm -r data
dvs get -r | tail -3
dvs status --absent
```


::: {.cell-output .cell-output-stdout}

```
error: the following required arguments were not provided:
  <PATHS>...

Usage: dvs get --recursive <PATHS>...

For more information, try '--help'.
+-----------------------------------+--------+-----------+
| path                              | status | size      |
+-----------------------------------+--------+-----------+
| data/individual/individual_01.csv | absent |    3.0 MB |
+-----------------------------------+--------+-----------+
| data/individual/individual_02.csv | absent |    3.0 MB |
+-----------------------------------+--------+-----------+
| data/individual/individual_03.csv | absent |    3.0 MB |
+-----------------------------------+--------+-----------+
| data/individual/individual_04.csv | absent |    3.0 MB |
+-----------------------------------+--------+-----------+
| data/individual/individual_05.csv | absent |    3.0 MB |
+-----------------------------------+--------+-----------+
| data/individual/individual_06.csv | absent |    3.0 MB |
+-----------------------------------+--------+-----------+
| data/individual/individual_07.csv | absent |    3.0 MB |
+-----------------------------------+--------+-----------+
| data/individual/individual_08.csv | absent |    3.0 MB |
+-----------------------------------+--------+-----------+
| data/individual/individual_09.csv | absent |    3.0 MB |
+-----------------------------------+--------+-----------+
| data/individual/individual_10.csv | absent |    3.0 MB |
+-----------------------------------+--------+-----------+
| data/individual/individual_11.csv | absent |    3.0 MB |
+-----------------------------------+--------+-----------+
| data/individual/individual_12.csv | absent |    3.0 MB |
+-----------------------------------+--------+-----------+
| data/individual/individual_13.csv | absent |    3.0 MB |
+-----------------------------------+--------+-----------+
| data/individual/individual_14.csv | absent |    3.0 MB |
+-----------------------------------+--------+-----------+
| data/individual/individual_15.csv | absent |    3.0 MB |
+-----------------------------------+--------+-----------+
| data/individual/individual_16.csv | absent |    3.0 MB |
+-----------------------------------+--------+-----------+
| data/individual/individual_17.csv | absent |    3.0 MB |
+-----------------------------------+--------+-----------+
| data/individual/individual_18.csv | absent |    3.0 MB |
+-----------------------------------+--------+-----------+
| data/individual/individual_19.csv | absent |    3.0 MB |
+-----------------------------------+--------+-----------+
| data/individual/individual_20.csv | absent |    3.0 MB |
+-----------------------------------+--------+-----------+
| data/individual/individual_21.csv | absent |    3.0 MB |
+-----------------------------------+--------+-----------+
| data/individual/individual_22.csv | absent |    3.0 MB |
+-----------------------------------+--------+-----------+
| data/individual/individual_23.csv | absent |    3.0 MB |
+-----------------------------------+--------+-----------+
| data/individual/individual_24.csv | absent |    3.0 MB |
+-----------------------------------+--------+-----------+
| data/individual/individual_25.csv | absent |    3.0 MB |
+-----------------------------------+--------+-----------+
| data/individual/individual_26.csv | absent |    3.0 MB |
+-----------------------------------+--------+-----------+
| data/individual/individual_27.csv | absent |    3.0 MB |
+-----------------------------------+--------+-----------+
| data/individual/individual_28.csv | absent |    3.0 MB |
+-----------------------------------+--------+-----------+
| data/individual/individual_29.csv | absent |    3.0 MB |
+-----------------------------------+--------+-----------+
| data/individual/individual_30.csv | absent |    3.0 MB |
+-----------------------------------+--------+-----------+
| data/individual/individual_31.csv | absent |    3.0 MB |
+-----------------------------------+--------+-----------+
| data/individual/individual_32.csv | absent |    3.0 MB |
+-----------------------------------+--------+-----------+
| data/individual/individual_33.csv | absent |    3.0 MB |
+-----------------------------------+--------+-----------+
| data/individual/individual_34.csv | absent |    3.0 MB |
+-----------------------------------+--------+-----------+
| data/individual/individual_35.csv | absent |    3.0 MB |
+-----------------------------------+--------+-----------+
| data/individual/individual_36.csv | absent |    3.0 MB |
+-----------------------------------+--------+-----------+
| data/individual/individual_37.csv | absent |    3.0 MB |
+-----------------------------------+--------+-----------+
| data/individual/individual_38.csv | absent |    3.0 MB |
+-----------------------------------+--------+-----------+
| data/individual/individual_39.csv | absent |    3.0 MB |
+-----------------------------------+--------+-----------+
| data/individual/individual_40.csv | absent |    3.0 MB |
+-----------------------------------+--------+-----------+
| data/individual/individual_41.csv | absent |    3.0 MB |
+-----------------------------------+--------+-----------+
| data/individual/individual_42.csv | absent |    3.0 MB |
+-----------------------------------+--------+-----------+
| data/individual/individual_43.csv | absent |    3.0 MB |
+-----------------------------------+--------+-----------+
| data/individual/individual_44.csv | absent |    3.0 MB |
+-----------------------------------+--------+-----------+
| data/individual/individual_45.csv | absent |    3.0 MB |
+-----------------------------------+--------+-----------+
| data/individual/individual_46.csv | absent |    3.0 MB |
+-----------------------------------+--------+-----------+
| data/individual/individual_47.csv | absent |    3.0 MB |
+-----------------------------------+--------+-----------+
| data/individual/individual_48.csv | absent |    3.0 MB |
+-----------------------------------+--------+-----------+
| data/individual/individual_49.csv | absent |    3.0 MB |
+-----------------------------------+--------+-----------+
| data/individual/individual_50.csv | absent |    3.0 MB |
+-----------------------------------+--------+-----------+
| data/large/large_1.csv            | absent |   25.0 MB |
+-----------------------------------+--------+-----------+
| data/small/small_1.csv            | absent | 1024.0 KB |
+-----------------------------------+--------+-----------+
| data/small/small_2.csv            | absent | 1024.0 KB |
+-----------------------------------+--------+-----------+
| data/small/small_3.csv            | absent | 1024.0 KB |
+-----------------------------------+--------+-----------+
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
Error: The following paths are not tracked by DVS:
  data/no_such_file.csv
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
+------------------------+--------+---------+
| path                   | status | size    |
+------------------------+--------+---------+
| data/large/large_1.csv | absent | 25.0 MB |
+------------------------+--------+---------+
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
+-----------------------------------+--------+-----------+
| data/small/small_3.csv            | absent | 1024.0 KB |
+-----------------------------------+--------+-----------+
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
