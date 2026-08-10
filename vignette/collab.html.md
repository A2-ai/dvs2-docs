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
  compression metadata_folder_name backend_path                                                               backend_group
  <chr>       <lgl>                <chr>                                                                      <chr>        
1 zstd        NA                   /Users/elea/Documents/a2ai_github/dvs2-demo-repo/file113f9657e8f63_storage staff        
```


:::

```{.r .cell-code}
dvs_add(paths = fs::dir_ls("data", type = "file"), message = "small corpus v1")
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 3 × 5
  path             outcome hash                                                                  size stored_size
  <chr>            <chr>   <chr>                                                              <bytes>     <bytes>
1 data/small_1.csv copied  3c70d1ec43fe236cdd09f4682b9622ef05138036e850660ca3659f4e6f871a4c 1024.0 KB    428.0 KB
2 data/small_2.csv copied  6c66237fd385388fd55fbcf06ae607685f9afa1dc3e5bb1a3602a6e6e2f211f4 1024.0 KB    427.9 KB
3 data/small_3.csv copied  57961075255ecb34289fa5b34370d678496ecd40b774688a708f4315ecca00ba 1024.0 KB    427.9 KB
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
path = "/Users/elea/Documents/a2ai_github/dvs2-demo-repo/file113f9657e8f63_storage"
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
# A tibble: 3 × 8
  path             status hash                                                                  size created_by compression message         add_time           
  <chr>            <chr>  <chr>                                                              <bytes> <chr>      <chr>       <chr>           <dttm>             
1 data/small_1.csv absent 3c70d1ec43fe236cdd09f4682b9622ef05138036e850660ca3659f4e6f871a4c 1024.0 KB elea       zstd        small corpus v1 2026-08-10 15:28:11
2 data/small_2.csv absent 6c66237fd385388fd55fbcf06ae607685f9afa1dc3e5bb1a3602a6e6e2f211f4 1024.0 KB elea       zstd        small corpus v1 2026-08-10 15:28:11
3 data/small_3.csv absent 57961075255ecb34289fa5b34370d678496ecd40b774688a708f4315ecca00ba 1024.0 KB elea       zstd        small corpus v1 2026-08-10 15:28:11
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
# A tibble: 3 × 3
  path             outcome      size
  <chr>            <chr>     <bytes>
1 data/small_1.csv copied  1024.0 KB
2 data/small_2.csv copied  1024.0 KB
3 data/small_3.csv copied  1024.0 KB
```


:::

```{.r .cell-code}
dvs_status()
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 3 × 8
  path             status  hash                                                                  size created_by compression message         add_time           
  <chr>            <chr>   <chr>                                                              <bytes> <chr>      <chr>       <chr>           <dttm>             
1 data/small_1.csv current 3c70d1ec43fe236cdd09f4682b9622ef05138036e850660ca3659f4e6f871a4c 1024.0 KB elea       zstd        small corpus v1 2026-08-10 15:28:11
2 data/small_2.csv current 6c66237fd385388fd55fbcf06ae607685f9afa1dc3e5bb1a3602a6e6e2f211f4 1024.0 KB elea       zstd        small corpus v1 2026-08-10 15:28:11
3 data/small_3.csv current 57961075255ecb34289fa5b34370d678496ecd40b774688a708f4315ecca00ba 1024.0 KB elea       zstd        small corpus v1 2026-08-10 15:28:11
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
/Users/elea/Documents/a2ai_github/dvs2-demo-repo/file113f9657e8f63_storage
├── 3c
│   └── 70d1ec43fe236cdd09f4682b9622ef05138036e850660ca3659f4e6f871a4c
├── 57
│   └── 961075255ecb34289fa5b34370d678496ecd40b774688a708f4315ecca00ba
├── 6c
│   └── 66237fd385388fd55fbcf06ae607685f9afa1dc3e5bb1a3602a6e6e2f211f4
└── audit.log.jsonl
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
{"operation_id":"18aca83e-494b-4e06-be53-813335ba9d4c","timestamp":1786375691,"user":"elea","action":{"add":{"file":{"path":"data/small_2.csv","hashes":{"blake3":"6c66237fd385388fd55fbcf06ae607685f9afa1dc3e5bb1a3602a6e6e2f211f4"}},"compression":"zstd"}}}

{"operation_id":"18aca83e-494b-4e06-be53-813335ba9d4c","timestamp":1786375691,"user":"elea","action":{"add":{"file":{"path":"data/small_3.csv","hashes":{"blake3":"57961075255ecb34289fa5b34370d678496ecd40b774688a708f4315ecca00ba"}},"compression":"zstd"}}}
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
