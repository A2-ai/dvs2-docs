---
title: "The R package in depth"
subtitle: "many files, globs, dry runs, changing data, scoped retrieval, and failure handling"
format:
  html:
    keep-md: true
execute:
  freeze: auto
---

[Introducing dvs](intro.html) walked the four verbs once. This page works the
R package the way a real project does: dozens of files at different sizes,
data that changes after it was added, previews before writes, retrieval
scoped to subdirectories, and the failure modes you will eventually meet.

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


The demo needs files worth versioning. `mkdatasetfiles()` is a small test-data
generator used throughout these demos (it is not part of dvs); it writes CSV
files of a chosen size and count. Its source is in the
[appendix](#appendix-the-test-data-generator).


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


One large file, a small corpus, and fifty individual datasets, mirroring the
shape of a typical modeling project:


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))

mkdatasetfiles(n_files = 1,  size_mb = 25, prefix = "large_",      dir = "data/large",      show_progress = FALSE)
mkdatasetfiles(n_files = 3,  size_mb = 1,  prefix = "small_",      dir = "data/small",      show_progress = FALSE)
mkdatasetfiles(n_files = 50, size_mb = 3,  prefix = "individual_", dir = "data/individual", show_progress = FALSE)

fs::dir_info("data", recurse = TRUE, type = "file") |>
  dplyr::mutate(dir = fs::path_dir(path)) |>
  dplyr::summarise(files = dplyr::n(), size = sum(size), .by = dir)
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 3 × 3
  dir             files        size
  <chr>           <int> <fs::bytes>
1 data/individual    50        150M
2 data/large          1         25M
3 data/small          3          3M
```


:::
:::


About 180 MB that git should never see.


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))
dvs_init(here::here(storage))
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 4
  compression metadata_folder_name backend_path                                                              backend_group
  <chr>       <lgl>                <chr>                                                                     <chr>        
1 zstd        NA                   /Users/elea/Documents/a2ai_github/dvs2-demo-repo/filef2513083abf8_storage staff        
```


:::
:::


## Adding files three ways

A single path, a vector of paths, and a glob. The `message` is recorded in
each meta file, so make it earn its keep.


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))

dvs_add("data/large/large_1.csv", message = "one large dataset")
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 6
  path                   outcome hash                                                                size stored_size duration_ms
  <chr>                  <chr>   <chr>                                                            <bytes>     <bytes>       <dbl>
1 data/large/large_1.csv copied  3c77885f59933a6334a438d0a77d2adcd06873bed58a00fc9807fce3d13ed838 25.0 MB     10.5 MB         346
```


:::
:::


The result is a tibble, one row per file. `size` is the file on disk;
`stored_size` is what actually landed in storage after zstd compression.

A vector of paths, straight from `fs::dir_ls()`:


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))

dvs_add(paths = fs::dir_ls("data/small", type = "file"), message = "small corpus")
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 3 × 6
  path                   outcome hash                                                                  size stored_size duration_ms
  <chr>                  <chr>   <chr>                                                              <bytes>     <bytes>       <dbl>
1 data/small/small_1.csv copied  e0fb0b7aac778f07ba37105d2e2a70d1cee429f50d77c3b0c9dd4ad4d2222937 1024.0 KB    427.8 KB          24
2 data/small/small_2.csv copied  1574af6b3e5cfd7fdba90c4f819fbd2bd128cd573c304588623fc09d49ae6b04 1024.0 KB    427.9 KB          25
3 data/small/small_3.csv copied  9d97b050e954474b51c5b3f06eafd07bc33366b9f3b09ea1211ac75c2704357a 1024.0 KB    428.1 KB          24
```


:::
:::


And a glob, resolved by dvs itself (not the shell), which keeps behavior
identical between R and the CLI:


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))

dvs_add(glob = "data/individual/individual_*.csv", message = "individual datasets")
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 50 × 6
   path                              outcome hash                                                                size stored_size duration_ms
   <chr>                             <chr>   <chr>                                                            <bytes>     <bytes>       <dbl>
 1 data/individual/individual_01.csv copied  57856e362f74d4319cdb81f0454e205a91e7ad8c83e3442aee7da4c676902d53  3.0 MB      1.3 MB         154
 2 data/individual/individual_02.csv copied  85ee4a308973f2ef5cda8d4a1a6228a4ff69e0f72de5c2dfd1aa8f9a409e2b5c  3.0 MB      1.3 MB         141
 3 data/individual/individual_03.csv copied  cd648605e42fddc1c08fc761b3683021e0be3a4578b0ec9e02e84e9645db8d58  3.0 MB      1.3 MB         147
 4 data/individual/individual_04.csv copied  388c35ea1e0f0f55cd73c6d6e84ad7659b3954f271103b51bcc868f9f07d1aee  3.0 MB      1.3 MB         161
 5 data/individual/individual_05.csv copied  0dbb9776c7188194995a8ddc0dca67a9814ef7fa165cc035518386c6e51cbb92  3.0 MB      1.3 MB         152
 6 data/individual/individual_06.csv copied  e3d9340328668ac4a61180c62664fa53726de78410ac7b90679b9f81cee2b852  3.0 MB      1.3 MB         161
 7 data/individual/individual_07.csv copied  e755c66eba55a05f0cb10a6c068f29a373de0baaed2649f0b8828ff302c65d61  3.0 MB      1.3 MB         177
 8 data/individual/individual_08.csv copied  93cb8aaac5d09feba55d44274f96b3b67f81fd66fce959e86e6b5af80b670d61  3.0 MB      1.3 MB         150
 9 data/individual/individual_09.csv copied  26af472b0caf28693778231ceacf48504b4c09d2cc877dd9c4a7f1a21144d72f  3.0 MB      1.3 MB         155
10 data/individual/individual_10.csv copied  804e10256f674fbb79860959dc612b3f73171c96871a6707278eaea594f9d470  3.0 MB      1.3 MB         169
# ℹ 40 more rows
```


:::
:::


Adding a file that has not changed is a no-op. The outcome says `present`
and the meta file is left alone:


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))

dvs_add("data/large/large_1.csv", message = "this message is not written")
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 6
  path                   outcome hash                                                                size stored_size duration_ms
  <chr>                  <chr>   <chr>                                                            <bytes>     <bytes>       <dbl>
1 data/large/large_1.csv present 3c77885f59933a6334a438d0a77d2adcd06873bed58a00fc9807fce3d13ed838 25.0 MB     25.0 MB           0
```


:::
:::


## Status is a data frame

`dvs_status()` returns a tibble with the full metadata: hash, size, who added
it, when, the compression mode, and the message. Filter it with the `status`
argument or with ordinary dplyr.


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))

dvs_status()
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 54 × 10
   path                              status  hash                                                                size created_by compression message             code  error add_time           
   <chr>                             <chr>   <chr>                                                            <bytes> <chr>      <chr>       <chr>               <chr> <chr> <dttm>             
 1 data/individual/individual_01.csv current 57856e362f74d4319cdb81f0454e205a91e7ad8c83e3442aee7da4c676902d53  3.0 MB elea       zstd        individual datasets <NA>  <NA>  2026-10-30 18:43:17
 2 data/individual/individual_02.csv current 85ee4a308973f2ef5cda8d4a1a6228a4ff69e0f72de5c2dfd1aa8f9a409e2b5c  3.0 MB elea       zstd        individual datasets <NA>  <NA>  2026-10-30 18:43:17
 3 data/individual/individual_03.csv current cd648605e42fddc1c08fc761b3683021e0be3a4578b0ec9e02e84e9645db8d58  3.0 MB elea       zstd        individual datasets <NA>  <NA>  2026-10-30 18:43:17
 4 data/individual/individual_04.csv current 388c35ea1e0f0f55cd73c6d6e84ad7659b3954f271103b51bcc868f9f07d1aee  3.0 MB elea       zstd        individual datasets <NA>  <NA>  2026-10-30 18:43:17
 5 data/individual/individual_05.csv current 0dbb9776c7188194995a8ddc0dca67a9814ef7fa165cc035518386c6e51cbb92  3.0 MB elea       zstd        individual datasets <NA>  <NA>  2026-10-30 18:43:17
 6 data/individual/individual_06.csv current e3d9340328668ac4a61180c62664fa53726de78410ac7b90679b9f81cee2b852  3.0 MB elea       zstd        individual datasets <NA>  <NA>  2026-10-30 18:43:17
 7 data/individual/individual_07.csv current e755c66eba55a05f0cb10a6c068f29a373de0baaed2649f0b8828ff302c65d61  3.0 MB elea       zstd        individual datasets <NA>  <NA>  2026-10-30 18:43:17
 8 data/individual/individual_08.csv current 93cb8aaac5d09feba55d44274f96b3b67f81fd66fce959e86e6b5af80b670d61  3.0 MB elea       zstd        individual datasets <NA>  <NA>  2026-10-30 18:43:17
 9 data/individual/individual_09.csv current 26af472b0caf28693778231ceacf48504b4c09d2cc877dd9c4a7f1a21144d72f  3.0 MB elea       zstd        individual datasets <NA>  <NA>  2026-10-30 18:43:17
10 data/individual/individual_10.csv current 804e10256f674fbb79860959dc612b3f73171c96871a6707278eaea594f9d470  3.0 MB elea       zstd        individual datasets <NA>  <NA>  2026-10-30 18:43:17
# ℹ 44 more rows
```


:::
:::



::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))

dvs_status(status = "current") |> nrow()
```

::: {.cell-output .cell-output-stdout}

```
[1] 54
```


:::
:::


## When data changes

Append a row to the large file. Its hash no longer matches the meta file, so
its status flips to `modified`:


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))

cat("99,0,0,0,0,0\n", file = "data/large/large_1.csv", append = TRUE)
dvs_status(status = "modified")
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 10
  path                   status   hash                                                                size created_by compression message           code  error add_time           
  <chr>                  <chr>    <chr>                                                            <bytes> <chr>      <chr>       <chr>             <chr> <chr> <dttm>             
1 data/large/large_1.csv modified 3c77885f59933a6334a438d0a77d2adcd06873bed58a00fc9807fce3d13ed838 25.0 MB elea       zstd        one large dataset <NA>  <NA>  2026-10-30 18:43:17
```


:::
:::


Re-add it with a message that says why. dvs writes the new content to storage
as a new blob and updates the meta file; the old blob stays, so clones pinned
to the old meta file still resolve.


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))

dvs_add("data/large/large_1.csv", message = "append row 99, corrected dataset")
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 6
  path                   outcome hash                                                                size stored_size duration_ms
  <chr>                  <chr>   <chr>                                                            <bytes>     <bytes>       <dbl>
1 data/large/large_1.csv copied  5e21922b470b3f9850c69729e53eb73df300672e6f43279aa43c7f252e54d03c 25.0 MB     10.5 MB         344
```


:::

```{.r .cell-code}
dvs_status(status = "modified")
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 0 × 10
# ℹ 10 variables: path <chr>, status <chr>, hash <chr>, size <bytes>, created_by <chr>, compression <chr>, message <chr>, code <chr>, error <chr>, add_time <dttm>
```


:::
:::


## Dry runs

`dry_run = TRUE` reports what would happen without writing anything. The
output has the same shape as the real call, so the only way to know nothing
happened is that nothing happened:


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))

cat("100,0,0,0,0,0\n", file = "data/large/large_1.csv", append = TRUE)
dvs_add("data/large/large_1.csv", message = "preview only", dry_run = TRUE)
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 6
  path                   outcome hash                                                                size stored_size duration_ms
  <chr>                  <chr>   <chr>                                                            <bytes>     <bytes>       <dbl>
1 data/large/large_1.csv copied  06c48bdae05977921d72ffec654c120bf19d6bdfa4988d61a6e821245ab90655 25.0 MB     25.0 MB          27
```


:::

```{.r .cell-code}
dvs_status(status = "modified")
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 10
  path                   status   hash                                                                size created_by compression message                          code  error add_time           
  <chr>                  <chr>    <chr>                                                            <bytes> <chr>      <chr>       <chr>                            <chr> <chr> <dttm>             
1 data/large/large_1.csv modified 5e21922b470b3f9850c69729e53eb73df300672e6f43279aa43c7f252e54d03c 25.0 MB elea       zstd        append row 99, corrected dataset <NA>  <NA>  2026-10-30 18:43:18
```


:::
:::


Still `modified`: no blob was written, no meta file updated. The same works
for retrieval:


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))

dvs_add("data/large/large_1.csv", message = "append row 100")
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 6
  path                   outcome hash                                                                size stored_size duration_ms
  <chr>                  <chr>   <chr>                                                            <bytes>     <bytes>       <dbl>
1 data/large/large_1.csv copied  06c48bdae05977921d72ffec654c120bf19d6bdfa4988d61a6e821245ab90655 25.0 MB     10.5 MB         367
```


:::

```{.r .cell-code}
unlink("data/small/small_1.csv")
dvs_get("data/small/small_1.csv", dry_run = TRUE)
```

::: {.cell-output .cell-output-stdout}

```
# Would restore 1
# A tibble: 1 × 13
  path                   local_path             before action        satisfied      size target_hash                                                      local_hash stored_copy code  message hint  duration_ms
* <chr>                  <chr>                  <chr>  <chr>         <lgl>       <bytes> <chr>                                                            <chr>      <chr>       <chr> <chr>   <chr>       <dbl>
1 data/small/small_1.csv data/small/small_1.csv absent would_restore TRUE      1024.0 KB e0fb0b7aac778f07ba37105d2e2a70d1cee429f50d77c3b0c9dd4ad4d2222937 <NA>       <NA>        <NA>  <NA>    <NA>            0
```


:::

```{.r .cell-code}
dvs_status(status = "absent")
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 10
  path                   status hash                                                                  size created_by compression message      code  error add_time           
  <chr>                  <chr>  <chr>                                                              <bytes> <chr>      <chr>       <chr>        <chr> <chr> <dttm>             
1 data/small/small_1.csv absent e0fb0b7aac778f07ba37105d2e2a70d1cee429f50d77c3b0c9dd4ad4d2222937 1024.0 KB elea       zstd        small corpus <NA>  <NA>  2026-10-30 18:43:17
```


:::
:::



::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))

dvs_get("data/small/small_1.csv")
```

::: {.cell-output .cell-output-stdout}

```
# Restored 1
# A tibble: 1 × 13
  path                   local_path             before action   satisfied      size target_hash                                                      local_hash stored_copy code  message hint  duration_ms
* <chr>                  <chr>                  <chr>  <chr>    <lgl>       <bytes> <chr>                                                            <chr>      <chr>       <chr> <chr>   <chr>       <dbl>
1 data/small/small_1.csv data/small/small_1.csv absent restored TRUE      1024.0 KB e0fb0b7aac778f07ba37105d2e2a70d1cee429f50d77c3b0c9dd4ad4d2222937 <NA>       <NA>        <NA>  <NA>    <NA>           16
```


:::

```{.r .cell-code}
dvs_status(status = "absent")
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 0 × 10
# ℹ 10 variables: path <chr>, status <chr>, hash <chr>, size <bytes>, created_by <chr>, compression <chr>, message <chr>, code <chr>, error <chr>, add_time <dttm>
```


:::
:::


## Scoped status and retrieval

Both `dvs_status()` and `dvs_get()` take directory paths and, by default,
consider only their direct children. `recursive = TRUE` includes every
descendant. Add a nested file so the difference is visible:


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))

mkdatasetfiles(n_files = 1, size_mb = 1, prefix = "nested_", dir = "data/small/nested", show_progress = FALSE)
invisible(dvs_add("data/small/nested/nested_1.csv", message = "nested file"))
```
:::



::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))

dvs_status("data/small")
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 3 × 10
  path                   status  hash                                                                  size created_by compression message      code  error add_time           
  <chr>                  <chr>   <chr>                                                              <bytes> <chr>      <chr>       <chr>        <chr> <chr> <dttm>             
1 data/small/small_1.csv current e0fb0b7aac778f07ba37105d2e2a70d1cee429f50d77c3b0c9dd4ad4d2222937 1024.0 KB elea       zstd        small corpus <NA>  <NA>  2026-10-30 18:43:17
2 data/small/small_2.csv current 1574af6b3e5cfd7fdba90c4f819fbd2bd128cd573c304588623fc09d49ae6b04 1024.0 KB elea       zstd        small corpus <NA>  <NA>  2026-10-30 18:43:17
3 data/small/small_3.csv current 9d97b050e954474b51c5b3f06eafd07bc33366b9f3b09ea1211ac75c2704357a 1024.0 KB elea       zstd        small corpus <NA>  <NA>  2026-10-30 18:43:17
```


:::
:::



::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))

dvs_status("data/small", recursive = TRUE)
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 4 × 10
  path                           status  hash                                                                  size created_by compression message      code  error add_time           
  <chr>                          <chr>   <chr>                                                              <bytes> <chr>      <chr>       <chr>        <chr> <chr> <dttm>             
1 data/small/nested/nested_1.csv current e0fb0b7aac778f07ba37105d2e2a70d1cee429f50d77c3b0c9dd4ad4d2222937 1024.0 KB elea       zstd        nested file  <NA>  <NA>  2026-10-30 18:43:19
2 data/small/small_1.csv         current e0fb0b7aac778f07ba37105d2e2a70d1cee429f50d77c3b0c9dd4ad4d2222937 1024.0 KB elea       zstd        small corpus <NA>  <NA>  2026-10-30 18:43:17
3 data/small/small_2.csv         current 1574af6b3e5cfd7fdba90c4f819fbd2bd128cd573c304588623fc09d49ae6b04 1024.0 KB elea       zstd        small corpus <NA>  <NA>  2026-10-30 18:43:17
4 data/small/small_3.csv         current 9d97b050e954474b51c5b3f06eafd07bc33366b9f3b09ea1211ac75c2704357a 1024.0 KB elea       zstd        small corpus <NA>  <NA>  2026-10-30 18:43:17
```


:::
:::


Retrieval scopes the same way. Delete everything under `data/small`, then
restore only the direct children:


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))

unlink(fs::dir_ls("data/small", recurse = TRUE, type = "file"))
dvs_get("data/small")
```

::: {.cell-output .cell-output-stdout}

```
# Restored 3
# A tibble: 3 × 13
  path                   local_path             before action   satisfied      size target_hash                                                      local_hash stored_copy code  message hint  duration_ms
* <chr>                  <chr>                  <chr>  <chr>    <lgl>       <bytes> <chr>                                                            <chr>      <chr>       <chr> <chr>   <chr>       <dbl>
1 data/small/small_1.csv data/small/small_1.csv absent restored TRUE      1024.0 KB e0fb0b7aac778f07ba37105d2e2a70d1cee429f50d77c3b0c9dd4ad4d2222937 <NA>       <NA>        <NA>  <NA>    <NA>           29
2 data/small/small_2.csv data/small/small_2.csv absent restored TRUE      1024.0 KB 1574af6b3e5cfd7fdba90c4f819fbd2bd128cd573c304588623fc09d49ae6b04 <NA>       <NA>        <NA>  <NA>    <NA>           28
3 data/small/small_3.csv data/small/small_3.csv absent restored TRUE      1024.0 KB 9d97b050e954474b51c5b3f06eafd07bc33366b9f3b09ea1211ac75c2704357a <NA>       <NA>        <NA>  <NA>    <NA>           28
```


:::

```{.r .cell-code}
dvs_status("data/small", recursive = TRUE)
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 4 × 10
  path                           status  hash                                                                  size created_by compression message      code  error add_time           
  <chr>                          <chr>   <chr>                                                              <bytes> <chr>      <chr>       <chr>        <chr> <chr> <dttm>             
1 data/small/nested/nested_1.csv absent  e0fb0b7aac778f07ba37105d2e2a70d1cee429f50d77c3b0c9dd4ad4d2222937 1024.0 KB elea       zstd        nested file  <NA>  <NA>  2026-10-30 18:43:19
2 data/small/small_1.csv         current e0fb0b7aac778f07ba37105d2e2a70d1cee429f50d77c3b0c9dd4ad4d2222937 1024.0 KB elea       zstd        small corpus <NA>  <NA>  2026-10-30 18:43:17
3 data/small/small_2.csv         current 1574af6b3e5cfd7fdba90c4f819fbd2bd128cd573c304588623fc09d49ae6b04 1024.0 KB elea       zstd        small corpus <NA>  <NA>  2026-10-30 18:43:17
4 data/small/small_3.csv         current 9d97b050e954474b51c5b3f06eafd07bc33366b9f3b09ea1211ac75c2704357a 1024.0 KB elea       zstd        small corpus <NA>  <NA>  2026-10-30 18:43:17
```


:::
:::


The nested file is still `absent`; a recursive get brings it back:


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))

dvs_get("data/small", recursive = TRUE)
```

::: {.cell-output .cell-output-stdout}

```
# Restored 1, 3 already current
# A tibble: 4 × 13
  path                           local_path                     before  action    satisfied      size target_hash                                                      local_hash                                                       stored_copy code  message hint  duration_ms
* <chr>                          <chr>                          <chr>   <chr>     <lgl>       <bytes> <chr>                                                            <chr>                                                            <chr>       <chr> <chr>   <chr>       <dbl>
1 data/small/nested/nested_1.csv data/small/nested/nested_1.csv absent  restored  TRUE      1024.0 KB e0fb0b7aac778f07ba37105d2e2a70d1cee429f50d77c3b0c9dd4ad4d2222937 <NA>                                                             <NA>        <NA>  <NA>    <NA>           12
2 data/small/small_1.csv         data/small/small_1.csv         current unchanged TRUE      1024.0 KB e0fb0b7aac778f07ba37105d2e2a70d1cee429f50d77c3b0c9dd4ad4d2222937 e0fb0b7aac778f07ba37105d2e2a70d1cee429f50d77c3b0c9dd4ad4d2222937 <NA>        <NA>  <NA>    <NA>            1
3 data/small/small_2.csv         data/small/small_2.csv         current unchanged TRUE      1024.0 KB 1574af6b3e5cfd7fdba90c4f819fbd2bd128cd573c304588623fc09d49ae6b04 1574af6b3e5cfd7fdba90c4f819fbd2bd128cd573c304588623fc09d49ae6b04 <NA>        <NA>  <NA>    <NA>            1
4 data/small/small_3.csv         data/small/small_3.csv         current unchanged TRUE      1024.0 KB 9d97b050e954474b51c5b3f06eafd07bc33366b9f3b09ea1211ac75c2704357a 9d97b050e954474b51c5b3f06eafd07bc33366b9f3b09ea1211ac75c2704357a <NA>        <NA>  <NA>    <NA>            1
```


:::

```{.r .cell-code}
dvs_status("data/small", recursive = TRUE)
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 4 × 10
  path                           status  hash                                                                  size created_by compression message      code  error add_time           
  <chr>                          <chr>   <chr>                                                              <bytes> <chr>      <chr>       <chr>        <chr> <chr> <dttm>             
1 data/small/nested/nested_1.csv current e0fb0b7aac778f07ba37105d2e2a70d1cee429f50d77c3b0c9dd4ad4d2222937 1024.0 KB elea       zstd        nested file  <NA>  <NA>  2026-10-30 18:43:19
2 data/small/small_1.csv         current e0fb0b7aac778f07ba37105d2e2a70d1cee429f50d77c3b0c9dd4ad4d2222937 1024.0 KB elea       zstd        small corpus <NA>  <NA>  2026-10-30 18:43:17
3 data/small/small_2.csv         current 1574af6b3e5cfd7fdba90c4f819fbd2bd128cd573c304588623fc09d49ae6b04 1024.0 KB elea       zstd        small corpus <NA>  <NA>  2026-10-30 18:43:17
4 data/small/small_3.csv         current 9d97b050e954474b51c5b3f06eafd07bc33366b9f3b09ea1211ac75c2704357a 1024.0 KB elea       zstd        small corpus <NA>  <NA>  2026-10-30 18:43:17
```


:::
:::


## When things fail

dvs collects per-file failures instead of aborting the batch. A file that
fails after the batch starts becomes a row with its `error` column set,
sitting next to the rows that succeeded.

The classic failure: a blob missing from storage. Simulate it by deleting
one blob directly (the meta file knows the hash, and the hash is the storage
address):


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))

meta <- jsonlite::fromJSON(".dvs/data/small/small_2.csv.dvs")
hash <- meta$hashes$blake3
blob <- here::here(storage, substr(hash, 1, 2), substr(hash, 3, nchar(hash)))
fs::file_delete(blob)

unlink("data/small/small_2.csv")
dvs_get("data/small/small_2.csv")
```

::: {.cell-output .cell-output-stdout}

```
# Failed: 1 failed
# ! data/small/small_2.csv: this version is not in storage
#     the stored content of this version is missing (probably an interrupted upload); tell whoever added it
# A tibble: 1 × 13
  path                   local_path             before action satisfied      size target_hash                                                      local_hash stored_copy code           message                        hint                                                                                                  duration_ms
* <chr>                  <chr>                  <chr>  <chr>  <lgl>       <bytes> <chr>                                                            <chr>      <chr>       <chr>          <chr>                          <chr>                                                                                                       <dbl>
1 data/small/small_2.csv data/small/small_2.csv absent failed FALSE     1024.0 KB 1574af6b3e5cfd7fdba90c4f819fbd2bd128cd573c304588623fc09d49ae6b04 <NA>       <NA>        source_missing this version is not in storage the stored content of this version is missing (probably an interrupted upload); tell whoever added it           0
```


:::
:::


The get returns normally, reports the failure in `error`, and leaves
everything else intact. Note what it did not do: write a corrupt file.
Retrieval verifies the hash before the file is moved into place.

Batch validation is stricter up front: if any requested path is not tracked
at all (a typo, say), the whole request is refused before anything is
retrieved, and `dvs_get()` raises an error.

## Untracking a file

There is no `dvs_remove()`. To stop tracking a file, delete its meta file:


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))

fs::file_delete(".dvs/data/large/large_1.csv.dvs")
dvs_status() |> nrow()
```

::: {.cell-output .cell-output-stdout}

```
[1] 54
```


:::
:::


The data file stays on disk; dvs simply no longer has an opinion about it.
Its blobs remain in storage (other projects may reference them).

## Cleanup


::: {.cell}

```{.r .cell-code}
unlink(here::here(new_project), recursive = TRUE)
unlink(here::here(storage),     recursive = TRUE)
```
:::


## Where to go next

- [The CLI in depth](intro-cli.html): the same operations from the terminal,
  plus JSON output and exit codes.
- [Collaboration](collab.html): sharing one storage across projects and users.
- Reference: [dvs_add()](r-add.html), [dvs_status()](r-status.html),
  [dvs_get()](r-get.html), [dvs_init()](r-init.html).

## Appendix: the test data generator

`mkdatasetfiles()` writes `n_files` CSVs of roughly `size_mb` each into `dir`,
naming them `<prefix>1.csv`, `<prefix>2.csv`, and so on. Each file gets its
own seed, so files in a batch are the same size but not identical (identical
content would share a single blob in storage, which is exactly what you want
in production and exactly what you do not want in a demo about many files).

```r
mkdatasetfiles <- function(n_files,
                           dir,
                           size_mb,
                           prefix = "file_",
                           dataset = datasets::ChickWeight,
                           extra_cols = 10L,
                           max_int = 1000L,
                           chunk_size_mb = 8,
                           chunk_rows = NULL,
                           show_progress = TRUE) {
  stopifnot(
    length(n_files) == 1L, is.numeric(n_files), n_files >= 1, n_files == as.integer(n_files),
    length(dir) == 1L, nzchar(dir),
    length(size_mb) == 1L, is.numeric(size_mb), size_mb > 0,
    length(prefix) == 1L, nzchar(prefix),
    is.data.frame(dataset),
    length(extra_cols) == 1L, extra_cols >= 0, extra_cols == as.integer(extra_cols),
    length(max_int) == 1L, max_int >= 1, max_int == as.integer(max_int),
    length(chunk_size_mb) == 1L, is.numeric(chunk_size_mb), chunk_size_mb > 0,
    is.null(chunk_rows) ||
      (length(chunk_rows) == 1L && chunk_rows >= 1 && chunk_rows == as.integer(chunk_rows)),
    is.logical(show_progress), length(show_progress) == 1L
  )

  dir.create(dir, recursive = TRUE, showWarnings = FALSE)

  target_bytes <- as.numeric(size_mb) * 1024^2
  chunk_target_bytes <- min(as.numeric(chunk_size_mb) * 1024^2, target_bytes)
  width <- max(1L, nchar(as.character(n_files)))

  dataset[] <- lapply(dataset, as.character)
  n_base <- nrow(dataset)
  if (n_base == 0L) stop("`dataset` must have at least one row.")

  base_names <- names(dataset)
  extra_names <- if (extra_cols > 0L) paste0("rand", seq_len(extra_cols)) else character(0)
  header_raw <- charToRaw(paste0(paste(c(base_names, extra_names), collapse = ","), "\n"))
  base_row_lines <- do.call(paste, c(dataset, list(sep = ",")))
  rand_lut <- if (extra_cols > 0L) as.character(0:(max_int - 1L)) else NULL
  out_files <- character(n_files)

  make_chunk_lines <- if (extra_cols > 0L) {
    function(start_row, n_rows) {
      idx <- ((seq.int(start_row, length.out = n_rows) - 1L) %% n_base) + 1L
      rand_chr <- matrix(
        rand_lut[sample.int(max_int, n_rows * extra_cols, replace = TRUE)],
        nrow = n_rows,
        ncol = extra_cols
      )
      rand_lines <- do.call(
        paste,
        c(as.data.frame(rand_chr, stringsAsFactors = FALSE), list(sep = ","))
      )
      paste0(base_row_lines[idx], ",", rand_lines)
    }
  } else {
    function(start_row, n_rows) {
      idx <- ((seq.int(start_row, length.out = n_rows) - 1L) %% n_base) + 1L
      base_row_lines[idx]
    }
  }

  chunk_rows <- if (is.null(chunk_rows)) {
    sample_n <- min(n_base, 1000L)
    sample_lines <- make_chunk_lines(1L, sample_n)
    sample_bytes <- as.numeric(utils::object.size(sample_lines))
    bytes_per_row <- max(1, ceiling(sample_bytes / sample_n))
    max(1L, as.integer(floor(chunk_target_bytes / bytes_per_row)))
  } else {
    as.integer(chunk_rows)
  }

  pb <- NULL
  if (show_progress) {
    pb <- utils::txtProgressBar(min = 0L, max = n_files, style = 3)
    on.exit(if (!is.null(pb)) close(pb), add = TRUE)
  }

  had_seed <- exists(".Random.seed", envir = globalenv(), inherits = FALSE)
  saved_seed <- if (had_seed) get(".Random.seed", envir = globalenv(), inherits = FALSE)
  on.exit({
    if (had_seed) {
      assign(".Random.seed", saved_seed, envir = globalenv())
    } else if (exists(".Random.seed", envir = globalenv(), inherits = FALSE)) {
      rm(".Random.seed", envir = globalenv())
    }
  }, add = TRUE)

  for (i in seq_len(n_files)) {
    set.seed(i)

    out_path <- file.path(dir, sprintf("%s%0*d.csv", prefix, width, i))
    out_files[i] <- out_path

    file_con <- file(out_path, open = "wb")
    on.exit(close(file_con), add = TRUE)

    writeBin(header_raw, file_con)
    bytes_written <- length(header_raw)
    start_row <- 1L

    repeat {
      remaining_bytes <- target_bytes - bytes_written
      if (remaining_bytes <= 0L) break

      lines <- make_chunk_lines(start_row, chunk_rows)
      line_bytes <- nchar(lines, type = "bytes") + 1L
      keep_n <- findInterval(remaining_bytes, cumsum(line_bytes))
      if (keep_n == 0L) break

      if (keep_n < length(lines)) {
        lines <- lines[seq_len(keep_n)]
        line_bytes <- line_bytes[seq_len(keep_n)]
      }

      writeChar(paste(lines, collapse = "\n"), file_con, eos = NULL, useBytes = TRUE)
      writeBin(as.raw(10L), file_con)

      bytes_written <- bytes_written + sum(line_bytes)
      start_row <- ((start_row + length(lines) - 1L) %% n_base) + 1L

      if (length(lines) < chunk_rows) break
    }

    close(file_con)
    on.exit(NULL, add = FALSE)

    if (show_progress) utils::setTxtProgressBar(pb, i)
  }

  invisible(file.path(normalizePath(dir, winslash = "/", mustWork = FALSE), basename(out_files)))
}
```
