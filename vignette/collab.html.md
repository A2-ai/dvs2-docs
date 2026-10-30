---
title: "Collaboration"
subtitle: "two users, one storage: sharing data through git plus a shared drive"
format:
  html:
    keep-md: true
execute:
  freeze: auto
---

## How teams share data with dvs

dvs splits a project into two halves that travel differently: code and
metadata move through git, data bytes move through a shared storage
directory. The team workflow is:

1. User A adds data files. dvs copies the bytes to shared storage and writes
   one small meta file per data file under `.dvs/`.
2. User A commits `dvs.toml` and the `.dvs/` tree. The data files themselves
   are gitignored (dvs wrote those entries during the add).
3. User B clones the repo and gets the metadata but no data.
4. User B runs `dvs_get()`. dvs reads each meta file, finds the blob in
   shared storage by its hash, and materializes the file.

The storage directory lives on infrastructure both users can reach, typically
an NFS mount. This demo simulates the two users with two project directories
on one machine, pointing at the same storage path; nothing else about the
flow changes.

## Setup


::: {.cell}

```{.r .cell-code}
options(width = 1000)
library(dvs)
library(fs)
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
shared_storage <- basename(tempfile(fileext = "_storage"))
project_a      <- basename(tempfile(fileext = "_project"))
project_b      <- basename(tempfile(fileext = "_project"))
dir.create(here::here(shared_storage))
dir.create(here::here(project_a))
dir.create(here::here(project_b))
```
:::


## User A: init, add, commit


::: {.cell}

```{.r .cell-code}
setwd(here::here(project_a))
mkdatasetfiles(n_files = 3, size_mb = 1, prefix = "small_", dir = "data", show_progress = FALSE)

dvs_init(here::here(shared_storage))
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 4
  compression metadata_folder_name backend_path                                                              backend_group
  <chr>       <lgl>                <chr>                                                                     <chr>        
1 zstd        NA                   /Users/elea/Documents/a2ai_github/dvs2-demo-repo/file884f659a64ce_storage staff        
```


:::

```{.r .cell-code}
dvs_add(paths = fs::dir_ls("data", type = "file"), message = "small corpus v1")
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 3 × 6
  path             outcome hash                                                                  size stored_size duration_ms
  <chr>            <chr>   <chr>                                                              <bytes>     <bytes>       <dbl>
1 data/small_1.csv copied  e0fb0b7aac778f07ba37105d2e2a70d1cee429f50d77c3b0c9dd4ad4d2222937 1024.0 KB    427.8 KB           7
2 data/small_2.csv copied  1574af6b3e5cfd7fdba90c4f819fbd2bd128cd573c304588623fc09d49ae6b04 1024.0 KB    427.9 KB           7
3 data/small_3.csv copied  9d97b050e954474b51c5b3f06eafd07bc33366b9f3b09ea1211ac75c2704357a 1024.0 KB    428.1 KB           6
```


:::
:::


What user A now commits to git is the configuration plus the meta tree, a
few hundred bytes per tracked file:


::: {.cell}

```{.r .cell-code}
setwd(here::here(project_a))
fs::dir_tree(".dvs")
```

::: {.cell-output .cell-output-stdout}

```
.dvs
└── data
    ├── small_1.csv.dvs
    ├── small_2.csv.dvs
    └── small_3.csv.dvs
```


:::
:::



::: {.cell}

```{.r .cell-code}
cat(readLines(here::here(project_a, "dvs.toml")), sep = "\n")
```

::: {.cell-output .cell-output-stdout}

```
compression = "zstd"

[backend]
path = "/Users/elea/Documents/a2ai_github/dvs2-demo-repo/file884f659a64ce_storage"
group = "staff"
```


:::
:::


## User B: clone, then get

Copying `dvs.toml` and `.dvs/` into the second project directory stands in
for `git clone`; the data files are gitignored, so a real clone would not
carry them either:


::: {.cell}

```{.r .cell-code}
fs::file_copy(here::here(project_a, "dvs.toml"), here::here(project_b, "dvs.toml"))
fs::dir_copy( here::here(project_a, ".dvs"),     here::here(project_b, ".dvs"))
```
:::


User B's status: everything tracked, nothing on disk.


::: {.cell}

```{.r .cell-code}
setwd(here::here(project_b))
dvs_status()
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 3 × 10
  path             status hash                                                                  size created_by compression message         code  error add_time           
  <chr>            <chr>  <chr>                                                              <bytes> <chr>      <chr>       <chr>           <chr> <chr> <dttm>             
1 data/small_1.csv absent e0fb0b7aac778f07ba37105d2e2a70d1cee429f50d77c3b0c9dd4ad4d2222937 1024.0 KB elea       zstd        small corpus v1 <NA>  <NA>  2026-10-30 11:12:04
2 data/small_2.csv absent 1574af6b3e5cfd7fdba90c4f819fbd2bd128cd573c304588623fc09d49ae6b04 1024.0 KB elea       zstd        small corpus v1 <NA>  <NA>  2026-10-30 11:12:04
3 data/small_3.csv absent 9d97b050e954474b51c5b3f06eafd07bc33366b9f3b09ea1211ac75c2704357a 1024.0 KB elea       zstd        small corpus v1 <NA>  <NA>  2026-10-30 11:12:04
```


:::
:::


One call materializes the project:


::: {.cell}

```{.r .cell-code}
setwd(here::here(project_b))
dvs_get(glob = "data/*.csv")
```

::: {.cell-output .cell-output-stdout}

```
# Restored 3
# A tibble: 3 × 13
  path             local_path       before action   satisfied      size target_hash                                                      local_hash stored_copy code  message hint  duration_ms
* <chr>            <chr>            <chr>  <chr>    <lgl>       <bytes> <chr>                                                            <chr>      <chr>       <chr> <chr>   <chr>       <dbl>
1 data/small_1.csv data/small_1.csv absent restored TRUE      1024.0 KB e0fb0b7aac778f07ba37105d2e2a70d1cee429f50d77c3b0c9dd4ad4d2222937 <NA>       <NA>        <NA>  <NA>    <NA>            3
2 data/small_2.csv data/small_2.csv absent restored TRUE      1024.0 KB 1574af6b3e5cfd7fdba90c4f819fbd2bd128cd573c304588623fc09d49ae6b04 <NA>       <NA>        <NA>  <NA>    <NA>            3
3 data/small_3.csv data/small_3.csv absent restored TRUE      1024.0 KB 9d97b050e954474b51c5b3f06eafd07bc33366b9f3b09ea1211ac75c2704357a <NA>       <NA>        <NA>  <NA>    <NA>            3
```


:::

```{.r .cell-code}
dvs_status()
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 3 × 10
  path             status  hash                                                                  size created_by compression message         code  error add_time           
  <chr>            <chr>   <chr>                                                              <bytes> <chr>      <chr>       <chr>           <chr> <chr> <dttm>             
1 data/small_1.csv current e0fb0b7aac778f07ba37105d2e2a70d1cee429f50d77c3b0c9dd4ad4d2222937 1024.0 KB elea       zstd        small corpus v1 <NA>  <NA>  2026-10-30 11:12:04
2 data/small_2.csv current 1574af6b3e5cfd7fdba90c4f819fbd2bd128cd573c304588623fc09d49ae6b04 1024.0 KB elea       zstd        small corpus v1 <NA>  <NA>  2026-10-30 11:12:04
3 data/small_3.csv current 9d97b050e954474b51c5b3f06eafd07bc33366b9f3b09ea1211ac75c2704357a 1024.0 KB elea       zstd        small corpus v1 <NA>  <NA>  2026-10-30 11:12:04
```


:::
:::


And the content is byte-for-byte what user A added, verified by hash during
retrieval:


::: {.cell}

```{.r .cell-code}
identical(
  unname(lapply(sort(fs::dir_ls(here::here(project_a, "data"), type = "file")), read.csv)),
  unname(lapply(sort(fs::dir_ls(here::here(project_b, "data"), type = "file")), read.csv))
)
```

::: {.cell-output .cell-output-stdout}

```
[1] TRUE
```


:::
:::


## Deduplication comes free

Storage is content-addressed: the blob's name is its hash, so identical
content stored from anywhere on the team lands in the same place exactly
once. Both projects above reference the same three blobs; adding the same
file from a third project would move zero bytes.


::: {.cell}

```{.r .cell-code}
fs::dir_tree(here::here(shared_storage))
```

::: {.cell-output .cell-output-stdout}

```
/Users/elea/Documents/a2ai_github/dvs2-demo-repo/file884f659a64ce_storage
├── 15
│   └── 74af6b3e5cfd7fdba90c4f819fbd2bd128cd573c304588623fc09d49ae6b04
├── 9d
│   └── 97b050e954474b51c5b3f06eafd07bc33366b9f3b09ea1211ac75c2704357a
├── audit.log.jsonl
└── e0
    └── fb0b7aac778f07ba37105d2e2a70d1cee429f50d77c3b0c9dd4ad4d2222937
```


:::
:::


## The audit trail

The storage directory keeps an append-only log, `audit.log.jsonl`, recording
every `init` and `add` that touched it: who, when, which file, which hash.
On a shared drive this is the team's answer to "where did this dataset come
from":


::: {.cell}

```{.r .cell-code}
log_lines <- readLines(here::here(shared_storage, "audit.log.jsonl"))
cat(tail(log_lines, 2), sep = "\n\n")
```

::: {.cell-output .cell-output-stdout}

```
{"operation_id":"e109dbae-d214-48af-b369-601942e01277","timestamp":1793358724,"user":"elea","action":{"add":{"file":{"path":"data/small_3.csv","hashes":{"blake3":"9d97b050e954474b51c5b3f06eafd07bc33366b9f3b09ea1211ac75c2704357a"}},"compression":"zstd","message":"small corpus v1"}}}

{"operation_id":"e109dbae-d214-48af-b369-601942e01277","timestamp":1793358724,"user":"elea","action":{"add":{"file":{"path":"data/small_2.csv","hashes":{"blake3":"1574af6b3e5cfd7fdba90c4f819fbd2bd128cd573c304588623fc09d49ae6b04"}},"compression":"zstd","message":"small corpus v1"}}}
```


:::
:::


## What belongs in git

| Path | Commit? | Why |
|------|:-------:|-----|
| `dvs.toml` | yes | points every clone at the shared storage |
| `.dvs/**/*.dvs` | yes | the version ledger, one meta file per data file |
| `.gitignore` entries | yes | written by dvs during add, keep data out of git |
| `data/` | no | the bytes live in dvs storage |

## Cleanup


::: {.cell}

```{.r .cell-code}
unlink(here::here(project_a),      recursive = TRUE)
unlink(here::here(project_b),      recursive = TRUE)
unlink(here::here(shared_storage), recursive = TRUE)
```
:::


## Where to go next

- [Introducing dvs](intro.html): the short version of everything above.
- [The R package in depth](intro-r.html) and [the CLI in depth](intro-cli.html).
- [The audit log](audit.html): every field in `audit.log.jsonl`, explained.
- [Storage and meta files](intro-internals.html): the content-addressed layout.
