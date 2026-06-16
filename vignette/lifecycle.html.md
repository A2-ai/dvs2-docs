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
storage     <- basename(tempfile(fileext = "_storage"))
new_project <- basename(tempfile(fileext = "_project"))
dir.create(here::here(storage))
dir.create(here::here(new_project))
```
:::



::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))
mkdatasetfiles(n_files = 1, size_mb = 25, prefix = "large_", dir = "data/large", show_progress = !nzchar(Sys.getenv("QUARTO_DOCUMENT_PATH")))
mkdatasetfiles(n_files = 3, size_mb = 1,  prefix = "small_", dir = "data/small", show_progress = !nzchar(Sys.getenv("QUARTO_DOCUMENT_PATH")))
```
:::



::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))
dvs_init(here::here(storage))
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
setwd(here::here(new_project))
dvs_status()
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 4 × 8
  path                   status  hash                                                                  size created_by compression message                    add_time           
  <chr>                  <chr>   <chr>                                                              <bytes> <chr>      <chr>       <chr>                      <dttm>             
1 data/large/large_1.csv current 3c77885f59933a6334a438d0a77d2adcd06873bed58a00fc9807fce3d13ed838   25.0 MB elea       zstd        initial add of large file  2026-04-24 12:59:15
2 data/small/small_1.csv current e0fb0b7aac778f07ba37105d2e2a70d1cee429f50d77c3b0c9dd4ad4d2222937 1024.0 KB elea       zstd        initial add of small files 2026-04-24 12:59:15
3 data/small/small_2.csv current 1574af6b3e5cfd7fdba90c4f819fbd2bd128cd573c304588623fc09d49ae6b04 1024.0 KB elea       zstd        initial add of small files 2026-04-24 12:59:15
4 data/small/small_3.csv current 9d97b050e954474b51c5b3f06eafd07bc33366b9f3b09ea1211ac75c2704357a 1024.0 KB elea       zstd        initial add of small files 2026-04-24 12:59:15
```


:::
:::


# Modify a tracked file

Append a row to `large_1.csv`. The file now differs from the hash dvs recorded:


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))
cat("99,0,0,0,0,0\n", file = "data/large/large_1.csv", append = TRUE)
```
:::


`dvs_status()` reports the hash mismatch as `unsynced`:


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))
dvs_status(status = "unsynced")
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 8
  path                   status   hash                                                                size created_by compression message                   add_time           
  <chr>                  <chr>    <chr>                                                            <bytes> <chr>      <chr>       <chr>                     <dttm>             
1 data/large/large_1.csv unsynced 3c77885f59933a6334a438d0a77d2adcd06873bed58a00fc9807fce3d13ed838 25.0 MB elea       zstd        initial add of large file 2026-04-24 12:59:15
```


:::
:::


Re-add with a new message. dvs writes a new blob and overwrites the meta file:


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))
dvs_add("data/large/large_1.csv", message = "add row 99 — corrected dataset")
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 5
  path                   outcome hash                                                                size stored_size
  <chr>                  <chr>   <chr>                                                            <bytes>     <bytes>
1 data/large/large_1.csv copied  5e21922b470b3f9850c69729e53eb73df300672e6f43279aa43c7f252e54d03c 25.0 MB     10.5 MB
```


:::
:::


Back to `current`:


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))
dvs_status(status = "current")
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 4 × 8
  path                   status  hash                                                                  size created_by compression message                        add_time           
  <chr>                  <chr>   <chr>                                                              <bytes> <chr>      <chr>       <chr>                          <dttm>             
1 data/large/large_1.csv current 5e21922b470b3f9850c69729e53eb73df300672e6f43279aa43c7f252e54d03c   25.0 MB elea       zstd        add row 99 — corrected dataset 2026-04-24 12:59:15
2 data/small/small_1.csv current e0fb0b7aac778f07ba37105d2e2a70d1cee429f50d77c3b0c9dd4ad4d2222937 1024.0 KB elea       zstd        initial add of small files     2026-04-24 12:59:15
3 data/small/small_2.csv current 1574af6b3e5cfd7fdba90c4f819fbd2bd128cd573c304588623fc09d49ae6b04 1024.0 KB elea       zstd        initial add of small files     2026-04-24 12:59:15
4 data/small/small_3.csv current 9d97b050e954474b51c5b3f06eafd07bc33366b9f3b09ea1211ac75c2704357a 1024.0 KB elea       zstd        initial add of small files     2026-04-24 12:59:15
```


:::
:::


# `dry_run`

`dry_run = TRUE` reports what *would* happen without writing anything.

Modify the file again:


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))
cat("100,0,0,0,0,0\n", file = "data/large/large_1.csv", append = TRUE)
```
:::


Preview `dvs_add` without committing:


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))
dvs_add("data/large/large_1.csv", message = "dry run preview", dry_run = TRUE)
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 5
  path                   outcome hash                                                                size stored_size
  <chr>                  <chr>   <chr>                                                            <bytes>     <bytes>
1 data/large/large_1.csv copied  06c48bdae05977921d72ffec654c120bf19d6bdfa4988d61a6e821245ab90655 25.0 MB     25.0 MB
```


:::
:::


Status is still `unsynced`. Nothing was written:


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))
dvs_status(status = "unsynced")
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 8
  path                   status   hash                                                                size created_by compression message                        add_time           
  <chr>                  <chr>    <chr>                                                            <bytes> <chr>      <chr>       <chr>                          <dttm>             
1 data/large/large_1.csv unsynced 5e21922b470b3f9850c69729e53eb73df300672e6f43279aa43c7f252e54d03c 25.0 MB elea       zstd        add row 99 — corrected dataset 2026-04-24 12:59:15
```


:::
:::


Delete a file, then preview `dvs_get` without restoring:


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))
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
setwd(here::here(new_project))
dvs_status(status = "absent")
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 8
  path                   status hash                                                                  size created_by compression message                    add_time           
  <chr>                  <chr>  <chr>                                                              <bytes> <chr>      <chr>       <chr>                      <dttm>             
1 data/small/small_1.csv absent e0fb0b7aac778f07ba37105d2e2a70d1cee429f50d77c3b0c9dd4ad4d2222937 1024.0 KB elea       zstd        initial add of small files 2026-04-24 12:59:15
```


:::
:::


Restore for real:


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))
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
  path                   status   hash                                                                  size created_by compression message                        add_time           
  <chr>                  <chr>    <chr>                                                              <bytes> <chr>      <chr>       <chr>                          <dttm>             
1 data/large/large_1.csv unsynced 5e21922b470b3f9850c69729e53eb73df300672e6f43279aa43c7f252e54d03c   25.0 MB elea       zstd        add row 99 — corrected dataset 2026-04-24 12:59:15
2 data/small/small_1.csv current  e0fb0b7aac778f07ba37105d2e2a70d1cee429f50d77c3b0c9dd4ad4d2222937 1024.0 KB elea       zstd        initial add of small files     2026-04-24 12:59:15
3 data/small/small_2.csv current  1574af6b3e5cfd7fdba90c4f819fbd2bd128cd573c304588623fc09d49ae6b04 1024.0 KB elea       zstd        initial add of small files     2026-04-24 12:59:15
4 data/small/small_3.csv current  9d97b050e954474b51c5b3f06eafd07bc33366b9f3b09ea1211ac75c2704357a 1024.0 KB elea       zstd        initial add of small files     2026-04-24 12:59:15
```


:::
:::


# Scoped status and retrieval

`dvs_status()` and `dvs_get()` both scope to direct children of a directory by
default. Pass `recursive = TRUE` to include all descendants.

Add a file nested one level deeper so the contrast is visible:


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))
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
setwd(here::here(new_project))
dvs_status("data/small")
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 3 × 8
  path                   status  hash                                                                  size created_by compression message                    add_time           
  <chr>                  <chr>   <chr>                                                              <bytes> <chr>      <chr>       <chr>                      <dttm>             
1 data/small/small_1.csv current e0fb0b7aac778f07ba37105d2e2a70d1cee429f50d77c3b0c9dd4ad4d2222937 1024.0 KB elea       zstd        initial add of small files 2026-04-24 12:59:15
2 data/small/small_2.csv current 1574af6b3e5cfd7fdba90c4f819fbd2bd128cd573c304588623fc09d49ae6b04 1024.0 KB elea       zstd        initial add of small files 2026-04-24 12:59:15
3 data/small/small_3.csv current 9d97b050e954474b51c5b3f06eafd07bc33366b9f3b09ea1211ac75c2704357a 1024.0 KB elea       zstd        initial add of small files 2026-04-24 12:59:15
```


:::
:::


`dvs_status("data/small", recursive = TRUE)` includes all descendants:


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))
dvs_status("data/small", recursive = TRUE)
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 4 × 8
  path                           status  hash                                                                  size created_by compression message                    add_time           
  <chr>                          <chr>   <chr>                                                              <bytes> <chr>      <chr>       <chr>                      <dttm>             
1 data/small/nested/nested_1.csv current e0fb0b7aac778f07ba37105d2e2a70d1cee429f50d77c3b0c9dd4ad4d2222937 1024.0 KB elea       zstd        add nested file            2026-04-24 12:59:15
2 data/small/small_1.csv         current e0fb0b7aac778f07ba37105d2e2a70d1cee429f50d77c3b0c9dd4ad4d2222937 1024.0 KB elea       zstd        initial add of small files 2026-04-24 12:59:15
3 data/small/small_2.csv         current 1574af6b3e5cfd7fdba90c4f819fbd2bd128cd573c304588623fc09d49ae6b04 1024.0 KB elea       zstd        initial add of small files 2026-04-24 12:59:15
4 data/small/small_3.csv         current 9d97b050e954474b51c5b3f06eafd07bc33366b9f3b09ea1211ac75c2704357a 1024.0 KB elea       zstd        initial add of small files 2026-04-24 12:59:15
```


:::
:::


Delete all four files so retrieval can be demonstrated:


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))
unlink("data/small/small_1.csv")
unlink("data/small/small_2.csv")
unlink("data/small/small_3.csv")
unlink("data/small/nested/nested_1.csv")
dvs_status("data/small", recursive = TRUE)
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 4 × 8
  path                           status hash                                                                  size created_by compression message                    add_time           
  <chr>                          <chr>  <chr>                                                              <bytes> <chr>      <chr>       <chr>                      <dttm>             
1 data/small/nested/nested_1.csv absent e0fb0b7aac778f07ba37105d2e2a70d1cee429f50d77c3b0c9dd4ad4d2222937 1024.0 KB elea       zstd        add nested file            2026-04-24 12:59:15
2 data/small/small_1.csv         absent e0fb0b7aac778f07ba37105d2e2a70d1cee429f50d77c3b0c9dd4ad4d2222937 1024.0 KB elea       zstd        initial add of small files 2026-04-24 12:59:15
3 data/small/small_2.csv         absent 1574af6b3e5cfd7fdba90c4f819fbd2bd128cd573c304588623fc09d49ae6b04 1024.0 KB elea       zstd        initial add of small files 2026-04-24 12:59:15
4 data/small/small_3.csv         absent 9d97b050e954474b51c5b3f06eafd07bc33366b9f3b09ea1211ac75c2704357a 1024.0 KB elea       zstd        initial add of small files 2026-04-24 12:59:15
```


:::
:::


`dvs_get("data/small")` restores only the three direct children. The nested
file remains absent:


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))
dvs_get("data/small")
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 4 × 3
  path                           outcome      size
  <chr>                          <chr>     <bytes>
1 data/small/nested/nested_1.csv copied  1024.0 KB
2 data/small/small_1.csv         copied  1024.0 KB
3 data/small/small_2.csv         copied  1024.0 KB
4 data/small/small_3.csv         copied  1024.0 KB
```


:::

```{.r .cell-code}
dvs_status("data/small", recursive = TRUE)
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 4 × 8
  path                           status  hash                                                                  size created_by compression message                    add_time           
  <chr>                          <chr>   <chr>                                                              <bytes> <chr>      <chr>       <chr>                      <dttm>             
1 data/small/nested/nested_1.csv current e0fb0b7aac778f07ba37105d2e2a70d1cee429f50d77c3b0c9dd4ad4d2222937 1024.0 KB elea       zstd        add nested file            2026-04-24 12:59:15
2 data/small/small_1.csv         current e0fb0b7aac778f07ba37105d2e2a70d1cee429f50d77c3b0c9dd4ad4d2222937 1024.0 KB elea       zstd        initial add of small files 2026-04-24 12:59:15
3 data/small/small_2.csv         current 1574af6b3e5cfd7fdba90c4f819fbd2bd128cd573c304588623fc09d49ae6b04 1024.0 KB elea       zstd        initial add of small files 2026-04-24 12:59:15
4 data/small/small_3.csv         current 9d97b050e954474b51c5b3f06eafd07bc33366b9f3b09ea1211ac75c2704357a 1024.0 KB elea       zstd        initial add of small files 2026-04-24 12:59:15
```


:::
:::


Restore the nested file explicitly by path:


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))
dvs_get("data/small/nested/nested_1.csv")
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 3
  path                           outcome      size
  <chr>                          <chr>     <bytes>
1 data/small/nested/nested_1.csv present 1024.0 KB
```


:::

```{.r .cell-code}
dvs_status("data/small", recursive = TRUE)
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 4 × 8
  path                           status  hash                                                                  size created_by compression message                    add_time           
  <chr>                          <chr>   <chr>                                                              <bytes> <chr>      <chr>       <chr>                      <dttm>             
1 data/small/nested/nested_1.csv current e0fb0b7aac778f07ba37105d2e2a70d1cee429f50d77c3b0c9dd4ad4d2222937 1024.0 KB elea       zstd        add nested file            2026-04-24 12:59:15
2 data/small/small_1.csv         current e0fb0b7aac778f07ba37105d2e2a70d1cee429f50d77c3b0c9dd4ad4d2222937 1024.0 KB elea       zstd        initial add of small files 2026-04-24 12:59:15
3 data/small/small_2.csv         current 1574af6b3e5cfd7fdba90c4f819fbd2bd128cd573c304588623fc09d49ae6b04 1024.0 KB elea       zstd        initial add of small files 2026-04-24 12:59:15
4 data/small/small_3.csv         current 9d97b050e954474b51c5b3f06eafd07bc33366b9f3b09ea1211ac75c2704357a 1024.0 KB elea       zstd        initial add of small files 2026-04-24 12:59:15
```


:::
:::


# Integrity failure: missing storage blob

dvs blobs are content-addressed: the hash in the meta file is the key. If a
blob is missing from storage (e.g. accidental deletion), `dvs_get` returns an
`error` column describing the failure rather than restoring the file.

Locate and delete the blob for `small_2.csv`:


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))
meta_path <- grep(
  "small_2",
  fs::dir_ls(".dvs", recurse = TRUE, all = TRUE, glob = "*.dvs", type = "file"),
  value = TRUE
)
meta  <- jsonlite::fromJSON(meta_path)
hash  <- meta$hashes$blake3
blob  <- here::here(storage, substr(hash, 1, 2), substr(hash, 3, nchar(hash)))

cat("blob:", as.character(blob), "\n")
```

::: {.cell-output .cell-output-stdout}

```
blob: /Users/elea/Documents/a2ai_github/dvs2-demo/filed7a55797c959_storage/15/74af6b3e5cfd7fdba90c4f819fbd2bd128cd573c304588623fc09d49ae6b04 
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
setwd(here::here(new_project))
unlink("data/small/small_2.csv")
dvs_status(status = "absent")
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 8
  path                   status hash                                                                  size created_by compression message                    add_time           
  <chr>                  <chr>  <chr>                                                              <bytes> <chr>      <chr>       <chr>                      <dttm>             
1 data/small/small_2.csv absent 1574af6b3e5cfd7fdba90c4f819fbd2bd128cd573c304588623fc09d49ae6b04 1024.0 KB elea       zstd        initial add of small files 2026-04-24 12:59:15
```


:::
:::


`dvs_get` returns normally but with a non-empty `error` column. The blob is
gone so the file cannot be restored:


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))
dvs_get("data/small/small_2.csv")
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 2
  path                   error                                                                                                         
  <chr>                  <chr>                                                                                                         
1 data/small/small_2.csv Storage file missing for hash: Hashes(blake3=1574af6b3e5cfd7fdba90c4f819fbd2bd128cd573c304588623fc09d49ae6b04)
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
unlink(here::here(new_project), recursive = TRUE)
unlink(here::here(storage),     recursive = TRUE)
```
:::


---

**Next up**: [Collaboration](collab.html): two projects sharing one storage directory; what to commit to git and what to gitignore.
