---
title: "dvs lifecycle"
subtitle: "modify, re-add, dry-run, and storage integrity failures"
format:
  html:
    keep-md: true
execute:
  freeze: auto
---

# Setup


::: {.cell}

```{.r .cell-code}
library(dvs)
library(fs)
library(here)
```

::: {.cell-output .cell-output-stderr}

```
here() starts at /Users/elea/Documents/a2ai_github/dvs2/dvs2-demo
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
storage     <- tempfile(fileext = "_storage", tmpdir = here::here())
new_project <- tempfile(fileext = "_project", tmpdir = here::here())
dir.create(storage)
dir.create(new_project)
```
:::



::: {.cell}

```{.r .cell-code}
setwd(new_project)
mkdatasetfiles(n_files = 1, size_mb = 25, prefix = "large_", dir = "data/large", show_progress = !nzchar(Sys.getenv("QUARTO_DOCUMENT_PATH")))
mkdatasetfiles(n_files = 3, size_mb = 1,  prefix = "small_", dir = "data/small", show_progress = !nzchar(Sys.getenv("QUARTO_DOCUMENT_PATH")))
```
:::



::: {.cell}

```{.r .cell-code}
setwd(new_project)
dvs_init(storage)
```

::: {.cell-output .cell-output-stdout}

```
DVS Initialized
```


:::

```{.r .cell-code}
invisible(dvs_add("data/large/large_1.csv",
                  message = "initial add of large file"))
invisible(dvs_add(paths = fs::dir_ls("data/small", type = "file"),
                  message = "initial add of small files"))
```
:::


All files are `current`:


::: {.cell}

```{.r .cell-code}
setwd(new_project)
dvs_status()
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 4 × 8
  path                   status  hash        size created_by compression message
  <chr>                  <chr>   <chr>    <bytes> <chr>      <chr>       <chr>  
1 data/large/large_1.csv current 45c0c…   25.0 MB elea       zstd        initia…
2 data/small/small_1.csv current e0fb0… 1024.0 KB elea       zstd        initia…
3 data/small/small_2.csv current 1574a… 1024.0 KB elea       zstd        initia…
4 data/small/small_3.csv current 9d97b… 1024.0 KB elea       zstd        initia…
# ℹ 1 more variable: add_time <dttm>
```


:::
:::


# Modify a tracked file

Append a row to `large_1.csv` — the file now differs from the hash dvs recorded:


::: {.cell}

```{.r .cell-code}
setwd(new_project)
cat("99,0,0,0,0,0\n", file = "data/large/large_1.csv", append = TRUE)
```
:::


`dvs_status()` reports the hash mismatch as `unsynced`:


::: {.cell}

```{.r .cell-code}
setwd(new_project)
dvs_status(status = "unsynced")
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 8
  path   status hash     size created_by compression message add_time           
  <chr>  <chr>  <chr> <bytes> <chr>      <chr>       <chr>   <dttm>             
1 data/… unsyn… 45c0… 25.0 MB elea       zstd        initia… 2026-04-24 08:49:56
```


:::
:::


Re-add with a new message. dvs writes a new blob and overwrites the meta file:


::: {.cell}

```{.r .cell-code}
setwd(new_project)
dvs_add("data/large/large_1.csv", message = "add row 99 — corrected dataset")
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 5
  path                   outcome hash                           size stored_size
  <chr>                  <chr>   <chr>                       <bytes>     <bytes>
1 data/large/large_1.csv copied  3d25427f55c367c3385717f614… 25.0 MB     10.5 MB
```


:::
:::


Back to `current`:


::: {.cell}

```{.r .cell-code}
setwd(new_project)
dvs_status(status = "current")
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 4 × 8
  path                   status  hash        size created_by compression message
  <chr>                  <chr>   <chr>    <bytes> <chr>      <chr>       <chr>  
1 data/large/large_1.csv current 3d254…   25.0 MB elea       zstd        add ro…
2 data/small/small_1.csv current e0fb0… 1024.0 KB elea       zstd        initia…
3 data/small/small_2.csv current 1574a… 1024.0 KB elea       zstd        initia…
4 data/small/small_3.csv current 9d97b… 1024.0 KB elea       zstd        initia…
# ℹ 1 more variable: add_time <dttm>
```


:::
:::


# `dry_run`

`dry_run = TRUE` reports what *would* happen without writing anything.

Modify the file again:


::: {.cell}

```{.r .cell-code}
setwd(new_project)
cat("100,0,0,0,0,0\n", file = "data/large/large_1.csv", append = TRUE)
```
:::


Preview `dvs_add` without committing:


::: {.cell}

```{.r .cell-code}
setwd(new_project)
dvs_add("data/large/large_1.csv", message = "dry run preview", dry_run = TRUE)
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 5
  path                   outcome hash                           size stored_size
  <chr>                  <chr>   <chr>                       <bytes>     <bytes>
1 data/large/large_1.csv copied  38c2d4d8bbc6b017aa6a03b243… 25.0 MB          NA
```


:::
:::


Status is still `unsynced` — nothing was written:


::: {.cell}

```{.r .cell-code}
setwd(new_project)
dvs_status(status = "unsynced")
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 8
  path   status hash     size created_by compression message add_time           
  <chr>  <chr>  <chr> <bytes> <chr>      <chr>       <chr>   <dttm>             
1 data/… unsyn… 3d25… 25.0 MB elea       zstd        add ro… 2026-04-24 08:49:56
```


:::
:::


Delete a file, then preview `dvs_get` without restoring:


::: {.cell}

```{.r .cell-code}
setwd(new_project)
unlink("data/small/small_1.csv")
dvs_get("data/small/small_1.csv", dry_run = TRUE)
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 3
  path                   outcome      size
  <chr>                  <chr>     <bytes>
1 data/small/small_1.csv copied  1024.0 KB
```


:::
:::


Status still shows `absent`:


::: {.cell}

```{.r .cell-code}
setwd(new_project)
dvs_status(status = "absent")
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 8
  path                   status hash         size created_by compression message
  <chr>                  <chr>  <chr>     <bytes> <chr>      <chr>       <chr>  
1 data/small/small_1.csv absent e0fb0b… 1024.0 KB elea       zstd        initia…
# ℹ 1 more variable: add_time <dttm>
```


:::
:::


Restore for real:


::: {.cell}

```{.r .cell-code}
setwd(new_project)
dvs_get("data/small/small_1.csv")
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 3
  path                   outcome      size
  <chr>                  <chr>     <bytes>
1 data/small/small_1.csv copied  1024.0 KB
```


:::

```{.r .cell-code}
dvs_status()
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 4 × 8
  path                   status   hash       size created_by compression message
  <chr>                  <chr>    <chr>   <bytes> <chr>      <chr>       <chr>  
1 data/large/large_1.csv unsynced 3d25…   25.0 MB elea       zstd        add ro…
2 data/small/small_1.csv current  e0fb… 1024.0 KB elea       zstd        initia…
3 data/small/small_2.csv current  1574… 1024.0 KB elea       zstd        initia…
4 data/small/small_3.csv current  9d97… 1024.0 KB elea       zstd        initia…
# ℹ 1 more variable: add_time <dttm>
```


:::
:::


# Scoped status and retrieval

`dvs_status()` and `dvs_get()` both scope to direct children of a directory by
default. Pass `recursive = TRUE` to include all descendants.

Add a file nested one level deeper so the contrast is visible:


::: {.cell}

```{.r .cell-code}
setwd(new_project)
dir.create("data/small/nested", recursive = TRUE)
mkdatasetfiles(n_files = 1, size_mb = 1, prefix = "nested_", dir = "data/small/nested",
               show_progress = !nzchar(Sys.getenv("QUARTO_DOCUMENT_PATH")))
invisible(dvs_add("data/small/nested/nested_1.csv", message = "add nested file"))
```
:::


`dvs_status("data/small")` shows only the three files directly in `data/small/`,
not the nested one:


::: {.cell}

```{.r .cell-code}
setwd(new_project)
dvs_status("data/small")
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 3 × 8
  path                   status  hash        size created_by compression message
  <chr>                  <chr>   <chr>    <bytes> <chr>      <chr>       <chr>  
1 data/small/small_1.csv current e0fb0… 1024.0 KB elea       zstd        initia…
2 data/small/small_2.csv current 1574a… 1024.0 KB elea       zstd        initia…
3 data/small/small_3.csv current 9d97b… 1024.0 KB elea       zstd        initia…
# ℹ 1 more variable: add_time <dttm>
```


:::
:::


`dvs_status("data/small", recursive = TRUE)` includes all descendants:


::: {.cell}

```{.r .cell-code}
setwd(new_project)
dvs_status("data/small", recursive = TRUE)
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 4 × 8
  path                     status hash       size created_by compression message
  <chr>                    <chr>  <chr>   <bytes> <chr>      <chr>       <chr>  
1 data/small/nested/neste… curre… e0fb… 1024.0 KB elea       zstd        add ne…
2 data/small/small_1.csv   curre… e0fb… 1024.0 KB elea       zstd        initia…
3 data/small/small_2.csv   curre… 1574… 1024.0 KB elea       zstd        initia…
4 data/small/small_3.csv   curre… 9d97… 1024.0 KB elea       zstd        initia…
# ℹ 1 more variable: add_time <dttm>
```


:::
:::


Delete all four files so retrieval can be demonstrated:


::: {.cell}

```{.r .cell-code}
setwd(new_project)
unlink("data/small/small_1.csv")
unlink("data/small/small_2.csv")
unlink("data/small/small_3.csv")
unlink("data/small/nested/nested_1.csv")
dvs_status("data/small", recursive = TRUE)
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 4 × 8
  path                     status hash       size created_by compression message
  <chr>                    <chr>  <chr>   <bytes> <chr>      <chr>       <chr>  
1 data/small/nested/neste… absent e0fb… 1024.0 KB elea       zstd        add ne…
2 data/small/small_1.csv   absent e0fb… 1024.0 KB elea       zstd        initia…
3 data/small/small_2.csv   absent 1574… 1024.0 KB elea       zstd        initia…
4 data/small/small_3.csv   absent 9d97… 1024.0 KB elea       zstd        initia…
# ℹ 1 more variable: add_time <dttm>
```


:::
:::


`dvs_get("data/small")` restores only the three direct children — the nested
file remains absent:


::: {.cell}

```{.r .cell-code}
setwd(new_project)
dvs_get("data/small")
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 3 × 3
  path                   outcome      size
  <chr>                  <chr>     <bytes>
1 data/small/small_1.csv copied  1024.0 KB
2 data/small/small_2.csv copied  1024.0 KB
3 data/small/small_3.csv copied  1024.0 KB
```


:::

```{.r .cell-code}
dvs_status("data/small", recursive = TRUE)
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 4 × 8
  path                     status hash       size created_by compression message
  <chr>                    <chr>  <chr>   <bytes> <chr>      <chr>       <chr>  
1 data/small/nested/neste… absent e0fb… 1024.0 KB elea       zstd        add ne…
2 data/small/small_1.csv   curre… e0fb… 1024.0 KB elea       zstd        initia…
3 data/small/small_2.csv   curre… 1574… 1024.0 KB elea       zstd        initia…
4 data/small/small_3.csv   curre… 9d97… 1024.0 KB elea       zstd        initia…
# ℹ 1 more variable: add_time <dttm>
```


:::
:::


`dvs_get("data/small", recursive = TRUE)` restores the nested file as well:


::: {.cell}

```{.r .cell-code}
setwd(new_project)
dvs_get("data/small", recursive = TRUE)
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 4 × 3
  path                           outcome      size
  <chr>                          <chr>     <bytes>
1 data/small/nested/nested_1.csv copied  1024.0 KB
2 data/small/small_1.csv         present 1024.0 KB
3 data/small/small_2.csv         present 1024.0 KB
4 data/small/small_3.csv         present 1024.0 KB
```


:::

```{.r .cell-code}
dvs_status("data/small", recursive = TRUE)
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 4 × 8
  path                     status hash       size created_by compression message
  <chr>                    <chr>  <chr>   <bytes> <chr>      <chr>       <chr>  
1 data/small/nested/neste… curre… e0fb… 1024.0 KB elea       zstd        add ne…
2 data/small/small_1.csv   curre… e0fb… 1024.0 KB elea       zstd        initia…
3 data/small/small_2.csv   curre… 1574… 1024.0 KB elea       zstd        initia…
4 data/small/small_3.csv   curre… 9d97… 1024.0 KB elea       zstd        initia…
# ℹ 1 more variable: add_time <dttm>
```


:::
:::


# Integrity failure: missing storage blob

dvs blobs are content-addressed — the hash in the meta file is the key. If a
blob is missing from storage (e.g. accidental deletion), `dvs_get` returns an
`error` column describing the failure rather than restoring the file.

Locate and delete the blob for `small_2.csv`:


::: {.cell}

```{.r .cell-code}
setwd(new_project)
meta_path <- grep(
  "small_2",
  fs::dir_ls(".dvs", recurse = TRUE, all = TRUE, glob = "*.dvs", type = "file"),
  value = TRUE
)
meta  <- jsonlite::fromJSON(meta_path)
hash  <- meta$hashes$blake3
blob  <- fs::path(storage, substr(hash, 1, 2), substr(hash, 3, nchar(hash)))

cat("blob:", as.character(blob), "\n")
```

::: {.cell-output .cell-output-stdout}

```
blob: /Users/elea/Documents/a2ai_github/dvs2/dvs2-demo/file55021c326ac3_storage/15/74af6b3e5cfd7fdba90c4f819fbd2bd128cd573c304588623fc09d49ae6b04 
```


:::

```{.r .cell-code}
cat("exists:", fs::file_exists(blob), "\n")
```

::: {.cell-output .cell-output-stdout}

```
exists: TRUE 
```


:::

```{.r .cell-code}
fs::file_delete(blob)
cat("exists after delete:", fs::file_exists(blob), "\n")
```

::: {.cell-output .cell-output-stdout}

```
exists after delete: FALSE 
```


:::
:::


Remove the local copy so a restore is needed:


::: {.cell}

```{.r .cell-code}
setwd(new_project)
unlink("data/small/small_2.csv")
dvs_status(status = "absent")
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 8
  path                   status hash         size created_by compression message
  <chr>                  <chr>  <chr>     <bytes> <chr>      <chr>       <chr>  
1 data/small/small_2.csv absent 1574af… 1024.0 KB elea       zstd        initia…
# ℹ 1 more variable: add_time <dttm>
```


:::
:::


`dvs_get` returns normally but with a non-empty `error` column — the blob is
gone so the file cannot be restored:


::: {.cell}

```{.r .cell-code}
setwd(new_project)
dvs_get("data/small/small_2.csv")
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 2
  path                   error                                                  
  <chr>                  <chr>                                                  
1 data/small/small_2.csv Storage file missing for hash: Hashes(blake3=1574af6b3…
```


:::
:::


# Untracking files

There is **no `dvs_remove` in the current release**. To stop tracking a file,
delete its meta file under `.dvs/` manually:

```r
# dvs will no longer track large_1.csv after its meta file is removed
fs::file_delete(".dvs/data/large/large_1.csv.dvs")
```

After the meta file is gone `dvs_status()` no longer reports on that file.

# Cleanup


::: {.cell}

```{.r .cell-code}
unlink(new_project, recursive = TRUE)
unlink(storage,     recursive = TRUE)
```
:::


---

**Next up**: [Collaboration](collab.html) — two projects sharing one storage directory; what to commit to git and what to gitignore.
