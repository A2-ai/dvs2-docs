---
title: "dvs_status()"
subtitle: "Report the sync status of tracked files"
format:
  html:
    keep-md: true
execute:
  freeze: auto
---

`dvs_status()` reports each tracked file as `current` (on disk and matching the
stored hash), `absent` (tracked but missing on disk), or `unsynced` (on disk but
not matching the stored hash). It returns a tibble that always includes the full
metadata columns.

```r
dvs_status(
  paths = character(0),
  recursive = NULL,
  status = c("current", "absent", "unsynced")
)
```

## Parameters

| Name | Type | Default | Behavior |
|---|---|---|---|
| `paths` | character | `character(0)` (whole project) | Files or directories to report. |
| `recursive` | logical(1) | `NULL` (treated as `FALSE`) | Include files in subdirectories of given directories. |
| `status` | character | all three | Statuses to include. Validated with `match.arg(several.ok = TRUE)`. |

## Setup

Add three files, then delete one and edit another so all three states appear.


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
write.csv(iris[1:10, ],   file.path(proj, "data", "sub", "f3.csv"), row.names = FALSE)
setwd(proj)
dvs_init(store)
```

::: {.cell-output .cell-output-stdout}

```
DVS Initialized
```


:::

```{.r .cell-code}
dvs_add(c("data/f1.csv", "data/f2.csv", "data/sub/f3.csv"), message = "initial add")
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 3 × 5
  path            outcome hash                                                                size stored_size
  <chr>           <chr>   <chr>                                                            <bytes>     <bytes>
1 data/f1.csv     copied  5e2c49dd5c8a24a2ffe102e42804812c7eabc2c49682240480558eac390c5d65   488 B       306 B
2 data/f2.csv     copied  c9c0ca2ba19bf1d65159ba2b7300c3336fdf113c92b79901e06be4b40fcd8871   500 B       275 B
3 data/sub/f3.csv copied  881b133ef44731569b7844e1dc60f10e5fc4a9f2c2ac36fe20b2bba636d6bbce   312 B       140 B
```


:::

```{.r .cell-code}
file.remove("data/f2.csv")                                   # -> absent
```

::: {.cell-output .cell-output-stdout}

```
[1] TRUE
```


:::

```{.r .cell-code}
write.csv(mtcars[1:9, ], "data/f1.csv")                       # -> unsynced
```
:::


## All files

With no arguments, every tracked file is reported, with all metadata columns.


::: {.cell}

```{.r .cell-code}
setwd(proj)
dvs_status()
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 3 × 8
  path            status   hash                                                                size created_by compression message     add_time           
  <chr>           <chr>    <chr>                                                            <bytes> <chr>      <chr>       <chr>       <dttm>             
1 data/f1.csv     unsynced 5e2c49dd5c8a24a2ffe102e42804812c7eabc2c49682240480558eac390c5d65   488 B elea       zstd        initial add 2026-06-16 16:40:54
2 data/f2.csv     absent   c9c0ca2ba19bf1d65159ba2b7300c3336fdf113c92b79901e06be4b40fcd8871   500 B elea       zstd        initial add 2026-06-16 16:40:54
3 data/sub/f3.csv current  881b133ef44731569b7844e1dc60f10e5fc4a9f2c2ac36fe20b2bba636d6bbce   312 B elea       zstd        initial add 2026-06-16 16:40:54
```


:::
:::


## `paths`

Scope the report to specific files or directories.


::: {.cell}

```{.r .cell-code}
setwd(proj)
dvs_status("data/sub/f3.csv")
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 8
  path            status  hash                                                                size created_by compression message     add_time           
  <chr>           <chr>   <chr>                                                            <bytes> <chr>      <chr>       <chr>       <dttm>             
1 data/sub/f3.csv current 881b133ef44731569b7844e1dc60f10e5fc4a9f2c2ac36fe20b2bba636d6bbce   312 B elea       zstd        initial add 2026-06-16 16:40:54
```


:::
:::


## `recursive`

Without `recursive`, a directory argument reports only files directly in it.
With `recursive = TRUE`, files in subdirectories are included too.


::: {.cell}

```{.r .cell-code}
setwd(proj)
dvs_status("data")
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 2 × 8
  path        status   hash                                                                size created_by compression message     add_time           
  <chr>       <chr>    <chr>                                                            <bytes> <chr>      <chr>       <chr>       <dttm>             
1 data/f1.csv unsynced 5e2c49dd5c8a24a2ffe102e42804812c7eabc2c49682240480558eac390c5d65   488 B elea       zstd        initial add 2026-06-16 16:40:54
2 data/f2.csv absent   c9c0ca2ba19bf1d65159ba2b7300c3336fdf113c92b79901e06be4b40fcd8871   500 B elea       zstd        initial add 2026-06-16 16:40:54
```


:::
:::



::: {.cell}

```{.r .cell-code}
setwd(proj)
dvs_status("data", recursive = TRUE)
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 3 × 8
  path            status   hash                                                                size created_by compression message     add_time           
  <chr>           <chr>    <chr>                                                            <bytes> <chr>      <chr>       <chr>       <dttm>             
1 data/f1.csv     unsynced 5e2c49dd5c8a24a2ffe102e42804812c7eabc2c49682240480558eac390c5d65   488 B elea       zstd        initial add 2026-06-16 16:40:54
2 data/f2.csv     absent   c9c0ca2ba19bf1d65159ba2b7300c3336fdf113c92b79901e06be4b40fcd8871   500 B elea       zstd        initial add 2026-06-16 16:40:54
3 data/sub/f3.csv current  881b133ef44731569b7844e1dc60f10e5fc4a9f2c2ac36fe20b2bba636d6bbce   312 B elea       zstd        initial add 2026-06-16 16:40:54
```


:::
:::


## `status`

Pass a single status, or several via the `match.arg(several.ok = TRUE)`
mechanism.


::: {.cell}

```{.r .cell-code}
setwd(proj)
dvs_status(status = "absent")
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 8
  path        status hash                                                                size created_by compression message     add_time           
  <chr>       <chr>  <chr>                                                            <bytes> <chr>      <chr>       <chr>       <dttm>             
1 data/f2.csv absent c9c0ca2ba19bf1d65159ba2b7300c3336fdf113c92b79901e06be4b40fcd8871   500 B elea       zstd        initial add 2026-06-16 16:40:54
```


:::
:::



::: {.cell}

```{.r .cell-code}
setwd(proj)
dvs_status(status = c("absent", "unsynced"))
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 2 × 8
  path        status   hash                                                                size created_by compression message     add_time           
  <chr>       <chr>    <chr>                                                            <bytes> <chr>      <chr>       <chr>       <dttm>             
1 data/f1.csv unsynced 5e2c49dd5c8a24a2ffe102e42804812c7eabc2c49682240480558eac390c5d65   488 B elea       zstd        initial add 2026-06-16 16:40:54
2 data/f2.csv absent   c9c0ca2ba19bf1d65159ba2b7300c3336fdf113c92b79901e06be4b40fcd8871   500 B elea       zstd        initial add 2026-06-16 16:40:54
```


:::
:::


## Selecting columns

`dvs_status()` always returns the full metadata, so there is no toggle for it.
Select the columns you want with `[]` or dplyr.


::: {.cell}

```{.r .cell-code}
setwd(proj)
dvs_status()[, c("path", "status", "size")]
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 3 × 3
  path            status      size
  <chr>           <chr>    <bytes>
1 data/f1.csv     unsynced   488 B
2 data/f2.csv     absent     500 B
3 data/sub/f3.csv current    312 B
```


:::
:::



::: {.cell}

```{.r .cell-code}
setwd(proj)
suppressMessages(library(dplyr))
dvs_status() |> select(path, status, message, add_time)
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 3 × 4
  path            status   message     add_time           
  <chr>           <chr>    <chr>       <dttm>             
1 data/f1.csv     unsynced initial add 2026-06-16 16:40:54
2 data/f2.csv     absent   initial add 2026-06-16 16:40:54
3 data/sub/f3.csv current  initial add 2026-06-16 16:40:54
```


:::
:::


## Return value

A tibble with one row per file:

| Column | Type | Description |
|---|---|---|
| `path` | character | File path. |
| `status` | character | `current`, `absent`, or `unsynced`. |
| `hash` | character | blake3 content hash. |
| `size` | `dvs_bytes` | Stored size. |
| `created_by` | character | User who added the file. |
| `compression` | character | `zstd` or `none`, recorded per file. |
| `message` | character | Message from `dvs_add()`, or `NA`. |
| `add_time` | POSIXct | When the file was added. |

Rows that fail carry an `error` column. The `size` column is a
[dvs_bytes](r-bytes.html) value.

## Differences from the CLI

The CLI command is [dvs status](cli-status.html). It shows a compact `path`,
`status`, `size` table by default and only adds the metadata columns with
`--with-metadata`; `dvs_status()` always returns them. Its filters are
independent `--current` / `--absent` / `--unsynced` flags rather than a single
`status` vector, and it adds `--threads` and `--json`.

## See also

- [dvs_init()](r-init.html), [dvs_add()](r-add.html), [dvs_get()](r-get.html)
- [Storage and meta files](intro-internals.html)
