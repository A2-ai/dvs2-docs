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
dvs_add(paths = character(0), message = NULL, glob = NULL, dry_run = NULL)
```

## Parameters

| Name | Type | Default | Behavior |
|---|---|---|---|
| `paths` | character | `character(0)` | Files to add. |
| `message` | character(1) | `NULL` | Message recorded in each meta file. |
| `glob` | character(1) | `NULL` | Library-expanded glob. Uses a literal path separator (use `**` to recurse). |
| `dry_run` | logical(1) | `NULL` (treated as `FALSE`) | Report what would be added; write nothing. |

A progress bar is shown automatically while files are processed (the wrapper
creates an internal `progress_callback` handle); it is not a parameter. No bar
is shown for a dry run.

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
write.csv(iris[1:10, ],   file.path(proj, "data", "g1.csv"), row.names = FALSE)
write.csv(iris[11:20, ],  file.path(proj, "data", "g2.csv"), row.names = FALSE)
write.csv(iris[21:30, ],  file.path(proj, "data", "sub", "g3.csv"), row.names = FALSE)
setwd(proj)
dvs_init(store)
```

::: {.cell-output .cell-output-stdout}

```
DVS Initialized
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
# A tibble: 1 × 5
  path        outcome hash                                                                size stored_size
  <chr>       <chr>   <chr>                                                            <bytes>     <bytes>
1 data/f1.csv copied  5e2c49dd5c8a24a2ffe102e42804812c7eabc2c49682240480558eac390c5d65   488 B       306 B
```


:::
:::


Add several files in one call:


::: {.cell}

```{.r .cell-code}
setwd(proj)
dvs_add(c("data/f2.csv"))
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 5
  path        outcome hash                                                                size stored_size
  <chr>       <chr>   <chr>                                                            <bytes>     <bytes>
1 data/f2.csv copied  c9c0ca2ba19bf1d65159ba2b7300c3336fdf113c92b79901e06be4b40fcd8871   500 B       275 B
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
# A tibble: 1 × 5
  path        outcome hash                                                                size stored_size
  <chr>       <chr>   <chr>                                                            <bytes>     <bytes>
1 data/g1.csv copied  881b133ef44731569b7844e1dc60f10e5fc4a9f2c2ac36fe20b2bba636d6bbce   312 B       140 B
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
# A tibble: 4 × 5
  path        outcome hash                                                                size stored_size
  <chr>       <chr>   <chr>                                                            <bytes>     <bytes>
1 data/f1.csv present 5e2c49dd5c8a24a2ffe102e42804812c7eabc2c49682240480558eac390c5d65   488 B       488 B
2 data/f2.csv present c9c0ca2ba19bf1d65159ba2b7300c3336fdf113c92b79901e06be4b40fcd8871   500 B       500 B
3 data/g1.csv present 881b133ef44731569b7844e1dc60f10e5fc4a9f2c2ac36fe20b2bba636d6bbce   312 B       312 B
4 data/g2.csv copied  a8eebfc0b894a2818e8c9edffe742df01a934073e3602a978836d622665786f7   312 B       147 B
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
# A tibble: 5 × 5
  path            outcome hash                                                                size stored_size
  <chr>           <chr>   <chr>                                                            <bytes>     <bytes>
1 data/f1.csv     present 5e2c49dd5c8a24a2ffe102e42804812c7eabc2c49682240480558eac390c5d65   488 B       488 B
2 data/f2.csv     present c9c0ca2ba19bf1d65159ba2b7300c3336fdf113c92b79901e06be4b40fcd8871   500 B       500 B
3 data/g1.csv     present 881b133ef44731569b7844e1dc60f10e5fc4a9f2c2ac36fe20b2bba636d6bbce   312 B       312 B
4 data/g2.csv     present a8eebfc0b894a2818e8c9edffe742df01a934073e3602a978836d622665786f7   312 B       312 B
5 data/sub/g3.csv copied  6d19965b2ae61ed235114e9739c4e1d1d52994d3be9f95e436ac1b7c69bb4582   310 B       146 B
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
# A tibble: 1 × 5
  path             outcome hash                                                                size stored_size
  <chr>            <chr>   <chr>                                                            <bytes>     <bytes>
1 data/preview.csv copied  172ce4213a1914a59a72e11b4555784b29fd0722787b2a8dbb52cdd9cdbf966a   314 B       314 B
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
# A tibble: 0 × 0
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
| `stored_size` | `dvs_bytes` | Stored (compressed) size. |

Rows that fail carry an `error` column instead. The `size` and `stored_size`
columns are [dvs_bytes](r-bytes.html) values that print as human-readable sizes.

## Differences from the CLI

The CLI command is [dvs add](cli-add.html). It prints lines and exits non-zero
on partial failure, and adds `--threads` and `--json`, which the R surface does
not have. Threads are set process-wide with [set_dvs_threads()](r-threads.html).

## See also

- [dvs_init()](r-init.html), [dvs_status()](r-status.html), [dvs_get()](r-get.html)
- [Storage and meta files](intro-internals.html)
- [The audit log](audit.html)
