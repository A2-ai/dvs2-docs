---
title: "dvs collaboration"
subtitle: "sharing data across projects and users through a common storage directory"
format:
  html:
    keep-md: true
execute:
  freeze: auto
---

# Overview

dvs separates *code* (tracked by git) from *data* (tracked by dvs). The
intended team workflow is:

1. **User A** adds data files → dvs copies blobs to **shared storage**, writes
   meta files under `.dvs/`
2. **User A** commits `dvs.toml` and the entire `.dvs/` tree to git (the meta
   files are small and text-based)
3. **User B** clones the repo. They get `dvs.toml` and `.dvs/` but *not* the
   data files (those are gitignored)
4. **User B** runs `dvs_get()` → dvs reads the meta files, locates blobs in
   shared storage, and writes the data files locally

The storage directory lives on shared infrastructure: a network mount,
an NFS/CIFS share, or any path your OS exposes as a local filesystem. In
this demo both users are simulated with separate temp dirs on the same
machine pointing at the same storage path.

# Setup


::: {.cell}

```{.r .cell-code}
options(width = 1000)
library(dvs)
library(fs)
library(here)
```

::: {.cell-output .cell-output-stderr}

```
here() starts at /Users/elea/Documents/a2ai_github/dvs2-demo
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
project_a      <- basename(tempfile(fileext = "_project_a"))
project_b      <- basename(tempfile(fileext = "_project_b"))
dir.create(here::here(shared_storage))
dir.create(here::here(project_a))
dir.create(here::here(project_b))
```
:::


# User A: add data


::: {.cell}

```{.r .cell-code}
setwd(here::here(project_a))
mkdatasetfiles(n_files = 3, size_mb = 1, prefix = "small_", dir = "data", show_progress = !nzchar(Sys.getenv("QUARTO_DOCUMENT_PATH")))
```
:::



::: {.cell}

```{.r .cell-code}
setwd(here::here(project_a))
dvs_init(here::here(shared_storage))
```

::: {.cell-output .cell-output-stdout}

```
DVS Initialized
```


:::

```{.r .cell-code}
invisible(dvs_add(paths = fs::dir_ls("data", type = "file"), message = "add small corpus v1"))
dvs_status()
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 3 × 8
  path             status  hash                                                                  size created_by compression message             add_time           
  <chr>            <chr>   <chr>                                                              <bytes> <chr>      <chr>       <chr>               <dttm>             
1 data/small_1.csv current e0fb0b7aac778f07ba37105d2e2a70d1cee429f50d77c3b0c9dd4ad4d2222937 1024.0 KB elea       zstd        add small corpus v1 2026-04-24 12:59:19
2 data/small_2.csv current 1574af6b3e5cfd7fdba90c4f819fbd2bd128cd573c304588623fc09d49ae6b04 1024.0 KB elea       zstd        add small corpus v1 2026-04-24 12:59:19
3 data/small_3.csv current 9d97b050e954474b51c5b3f06eafd07bc33366b9f3b09ea1211ac75c2704357a 1024.0 KB elea       zstd        add small corpus v1 2026-04-24 12:59:19
```


:::
:::


The `.dvs/` tree and `dvs.toml` are what user A would commit to git:


::: {.cell}

```{.r .cell-code}
setwd(here::here(project_a))
fs::dir_tree(".dvs", all = TRUE, regexp = "\\.git", invert = TRUE)
```

::: {.cell-output .cell-output-stdout}

```
.dvs
├── .cache
│   └── dvs.db
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
path = "/Users/elea/Documents/a2ai_github/dvs2-demo/filed83d8b62b99_storage"
group = "staff"
```


:::
:::


# Simulate a git clone (User B)

When user B clones the repo they receive `dvs.toml` and the `.dvs/` meta tree,
but `data/` is gitignored so the CSV files are absent:


::: {.cell}

```{.r .cell-code}
fs::file_copy(here::here(project_a, "dvs.toml"), here::here(project_b, "dvs.toml"))
fs::dir_copy( here::here(project_a, ".dvs"),     here::here(project_b, ".dvs"))
```
:::


User B's project shows all files as `absent`:


::: {.cell}

```{.r .cell-code}
setwd(here::here(project_b))
dvs_status()
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 3 × 8
  path             status hash                                                                  size created_by compression message             add_time           
  <chr>            <chr>  <chr>                                                              <bytes> <chr>      <chr>       <chr>               <dttm>             
1 data/small_1.csv absent e0fb0b7aac778f07ba37105d2e2a70d1cee429f50d77c3b0c9dd4ad4d2222937 1024.0 KB elea       zstd        add small corpus v1 2026-04-24 12:59:19
2 data/small_2.csv absent 1574af6b3e5cfd7fdba90c4f819fbd2bd128cd573c304588623fc09d49ae6b04 1024.0 KB elea       zstd        add small corpus v1 2026-04-24 12:59:19
3 data/small_3.csv absent 9d97b050e954474b51c5b3f06eafd07bc33366b9f3b09ea1211ac75c2704357a 1024.0 KB elea       zstd        add small corpus v1 2026-04-24 12:59:19
```


:::
:::


# User B: get data


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
:::


All files are now `current`:


::: {.cell}

```{.r .cell-code}
setwd(here::here(project_b))
dvs_status()
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 3 × 8
  path             status  hash                                                                  size created_by compression message             add_time           
  <chr>            <chr>   <chr>                                                              <bytes> <chr>      <chr>       <chr>               <dttm>             
1 data/small_1.csv current e0fb0b7aac778f07ba37105d2e2a70d1cee429f50d77c3b0c9dd4ad4d2222937 1024.0 KB elea       zstd        add small corpus v1 2026-04-24 12:59:19
2 data/small_2.csv current 1574af6b3e5cfd7fdba90c4f819fbd2bd128cd573c304588623fc09d49ae6b04 1024.0 KB elea       zstd        add small corpus v1 2026-04-24 12:59:19
3 data/small_3.csv current 9d97b050e954474b51c5b3f06eafd07bc33366b9f3b09ea1211ac75c2704357a 1024.0 KB elea       zstd        add small corpus v1 2026-04-24 12:59:19
```


:::
:::


Verify the content is byte-for-byte identical to what user A added:


::: {.cell}

```{.r .cell-code}
files_a <- sort(fs::dir_ls(here::here(project_a, "data"), type = "file"))
files_b <- sort(fs::dir_ls(here::here(project_b, "data"), type = "file"))

identical(
  lapply(files_a, read.csv),
  lapply(files_b, read.csv)
)
```

::: {.cell-output .cell-output-stdout}

```
[1] FALSE
```


:::
:::


# What belongs in git

| Path | Commit? | Notes |
|------|:-------:|-------|
| `dvs.toml` | ✅ | points to shared storage |
| `.dvs/**/*.dvs` | ✅ | meta files, the version ledger |
| `data/` | ❌ gitignore | large files live in dvs storage |
| `rv/library/` | ❌ gitignore | cached R packages rebuild from `rproject.toml` |
| `rv/scripts/` | ✅ | rv bootstrap helpers belong in the repo |

Minimal additions to `.gitignore`:

```text
data/
rv/library/
```

# Cleanup


::: {.cell}

```{.r .cell-code}
unlink(here::here(project_a),      recursive = TRUE)
unlink(here::here(project_b),      recursive = TRUE)
unlink(here::here(shared_storage), recursive = TRUE)
```
:::


---

**Next up**: [Configuration](config.html): `dvs.toml` fields, compression tradeoffs, threads, and custom metadata folder names.
