---
title: "dvs_add()"
subtitle: "Track files in dvs storage"
format:
  html:
    keep-md: true
execute:
  freeze: auto
---

`dvs_add()` hashes files, copies their contents into storage, writes a `.dvs`
meta file next to each one, and returns a tibble of results. Pass paths, a glob,
or both.

```r
dvs_add(paths = character(0), message = NULL, glob = NULL, dry_run = FALSE)
```

## Parameters

| Name | Type | Default | Behavior |
|---|---|---|---|
| `paths` | character | `character(0)` | Files to add. |
| `message` | character(1) | `NULL` | Message recorded in each meta file. |
| `glob` | character(1) | `NULL` | Library-expanded glob. Uses a literal path separator (use `**` to recurse). |
| `dry_run` | logical(1) | `FALSE` | Report what would be added. Write nothing. |

In interactive sessions a progress bar is shown while files are processed. It is
not a parameter, and no bar appears in scripts, rendered documents, or dry runs.

## Setup


::: {.cell}

```{.r .cell-code}
options(width = 1000)
library(dvs)
proj  <- tempfile("project_")
store <- tempfile("storage_")
dir.create(proj)
dir.create(store)
dir.create(file.path(proj, "data", "sub"), recursive = TRUE)
write.csv(mtcars[1:8, ],  file.path(proj, "data", "f1.csv"))
write.csv(mtcars[9:16, ], file.path(proj, "data", "f2.csv"))
write.csv(mtcars[3:10, ], file.path(proj, "data", "f3.csv"))
write.csv(iris[1:10, ],   file.path(proj, "data", "g1.csv"), row.names = FALSE)
write.csv(iris[11:20, ],  file.path(proj, "data", "g2.csv"), row.names = FALSE)
write.csv(iris[21:30, ],  file.path(proj, "data", "sub", "g3.csv"), row.names = FALSE)
setwd(proj)
dvs_init(store)
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 4
  compression metadata_folder_name backend_path                                                                            backend_group
  <chr>       <lgl>                <chr>                                                                                   <chr>        
1 zstd        NA                   /private/var/folders/_x/bq8vb1b156sgl363l71by61h0000gn/T/RtmpgSx4pP/storage_d193e14069b staff        
```


:::
:::


## `paths`

Add a single file. The result has one row per file: the on-disk `size`, the
stored (compressed) `stored_size`, the content `hash`, and `outcome`.


::: {.cell}

```{.r .cell-code}
setwd(proj)
dvs_add("data/f1.csv")
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 6
  path        outcome hash                                                                size stored_size duration_ms
  <chr>       <chr>   <chr>                                                            <bytes>     <bytes>       <dbl>
1 data/f1.csv copied  5e2c49dd5c8a24a2ffe102e42804812c7eabc2c49682240480558eac390c5d65   488 B       306 B           1
```


:::
:::


`paths` is a character vector, so several files go in one call:


::: {.cell}

```{.r .cell-code}
setwd(proj)
dvs_add(c("data/f2.csv", "data/f3.csv"))
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 2 × 6
  path        outcome hash                                                                size stored_size duration_ms
  <chr>       <chr>   <chr>                                                            <bytes>     <bytes>       <dbl>
1 data/f2.csv copied  c9c0ca2ba19bf1d65159ba2b7300c3336fdf113c92b79901e06be4b40fcd8871   500 B       275 B           0
2 data/f3.csv copied  a84f725603d7fd025bb6deb4889fd25465c0d23dfcbd0129f4fc7aa1472ecc2c   488 B       302 B           0
```


:::
:::


## `message`

Record a message in the meta files. It surfaces later as the `message` column
of [dvs_status()](r-status.html).


::: {.cell}

```{.r .cell-code}
setwd(proj)
dvs_add("data/g1.csv", message = "iris head sample")
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 6
  path        outcome hash                                                                size stored_size duration_ms
  <chr>       <chr>   <chr>                                                            <bytes>     <bytes>       <dbl>
1 data/g1.csv copied  881b133ef44731569b7844e1dc60f10e5fc4a9f2c2ac36fe20b2bba636d6bbce   312 B       140 B           0
```


:::
:::


## `glob`

A library-expanded glob uses a literal path separator: `data/*.csv` matches
files in `data/` only, not in subdirectories.


::: {.cell}

```{.r .cell-code}
setwd(proj)
dvs_add(glob = "data/*.csv")
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 5 × 6
  path        outcome hash                                                                size stored_size duration_ms
  <chr>       <chr>   <chr>                                                            <bytes>     <bytes>       <dbl>
1 data/f1.csv present 5e2c49dd5c8a24a2ffe102e42804812c7eabc2c49682240480558eac390c5d65   488 B       488 B           1
2 data/f2.csv present c9c0ca2ba19bf1d65159ba2b7300c3336fdf113c92b79901e06be4b40fcd8871   500 B       500 B           1
3 data/f3.csv present a84f725603d7fd025bb6deb4889fd25465c0d23dfcbd0129f4fc7aa1472ecc2c   488 B       488 B           1
4 data/g1.csv present 881b133ef44731569b7844e1dc60f10e5fc4a9f2c2ac36fe20b2bba636d6bbce   312 B       312 B           1
5 data/g2.csv copied  a8eebfc0b894a2818e8c9edffe742df01a934073e3602a978836d622665786f7   312 B       147 B           0
```


:::
:::


::: {.callout-tip}
Use `**` to cross directory boundaries. `data/**/*.csv` matches the nested file
that `data/*.csv` skipped.
:::


::: {.cell}

```{.r .cell-code}
setwd(proj)
dvs_add(glob = "data/**/*.csv")
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 6 × 6
  path            outcome hash                                                                size stored_size duration_ms
  <chr>           <chr>   <chr>                                                            <bytes>     <bytes>       <dbl>
1 data/f1.csv     present 5e2c49dd5c8a24a2ffe102e42804812c7eabc2c49682240480558eac390c5d65   488 B       488 B           0
2 data/f2.csv     present c9c0ca2ba19bf1d65159ba2b7300c3336fdf113c92b79901e06be4b40fcd8871   500 B       500 B           0
3 data/f3.csv     present a84f725603d7fd025bb6deb4889fd25465c0d23dfcbd0129f4fc7aa1472ecc2c   488 B       488 B           0
4 data/g1.csv     present 881b133ef44731569b7844e1dc60f10e5fc4a9f2c2ac36fe20b2bba636d6bbce   312 B       312 B           0
5 data/g2.csv     present a8eebfc0b894a2818e8c9edffe742df01a934073e3602a978836d622665786f7   312 B       312 B           0
6 data/sub/g3.csv copied  6d19965b2ae61ed235114e9739c4e1d1d52994d3be9f95e436ac1b7c69bb4582   310 B       146 B           1
```


:::
:::


## `dry_run`

With `dry_run = TRUE` the result reports what would be added, but no blob or meta
file is written.


::: {.cell}

```{.r .cell-code}
setwd(proj)
write.csv(iris[31:40, ], "data/preview.csv", row.names = FALSE)
dvs_add("data/preview.csv", dry_run = TRUE)
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 6
  path             outcome hash                                                                size stored_size duration_ms
  <chr>            <chr>   <chr>                                                            <bytes>     <bytes>       <dbl>
1 data/preview.csv copied  172ce4213a1914a59a72e11b4555784b29fd0722787b2a8dbb52cdd9cdbf966a   314 B       314 B           0
```


:::
:::


The file is not tracked afterward:


::: {.cell}

```{.r .cell-code}
setwd(proj)
dvs_status("data/preview.csv")
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 0 × 10
# ℹ 10 variables: path <chr>, status <chr>, hash <chr>, size <bytes>, created_by <chr>, compression <chr>, message <chr>, code <chr>, error <chr>, add_time <dttm>
```


:::
:::


## Return value

A tibble with one row per file:

| Column | Type | Description |
|---|---|---|
| `path` | character | File path. |
| `outcome` | character | `copied` (new content stored) or `present` (already stored). |
| `hash` | character | blake3 content hash. |
| `size` | `dvs_bytes` | On-disk size. |
| `stored_size` | `dvs_bytes` | Stored (compressed) size. In a dry run, `size`. |
| `duration_ms` | double | Milliseconds spent on the file. |

A file that fails does not stop the others. When one fails, the result also has
the columns `code` (the kind of failure, for example `io_error`) and `error`
(the reason), and that row has `NA` in `outcome`, `hash`, `size` and
`stored_size`. A path that does not exist raises an error and adds nothing. The
`size` and `stored_size` columns are [dvs_bytes](r-bytes.html) values that
print as human-readable sizes.

## Differences from the CLI

The CLI command is [dvs add](cli-add.html). It prints lines and exits non-zero
on partial failure, and adds `--threads` and `--json`, which the R surface does
not have. Threads are set process-wide with [set_dvs_threads()](r-threads.html).

## See also

- [dvs_init()](r-init.html), [dvs_status()](r-status.html), [dvs_get()](r-get.html)
- [Storage and meta files](intro-internals.html)
- [The audit log](audit.html)
