---
title: "dvs_get()"
subtitle: "Restore files from storage"
format:
  html:
    keep-md: true
execute:
  freeze: auto
---

`dvs_get()` reads the meta files, finds the matching blobs in storage, and
writes the contents back to their original paths. It is the inverse of
[dvs_add()](r-add.html): the call to run after re-cloning a project whose data
is not on disk.

```r
dvs_get(paths = character(0), glob = NULL, dry_run = NULL)
```

## Parameters

| Name | Type | Default | Behavior |
|---|---|---|---|
| `paths` | character | `character(0)` | Files to retrieve. |
| `glob` | character(1) | `NULL` | Library-expanded glob. Uses a literal path separator (use `**` to recurse). |
| `dry_run` | logical(1) | `NULL` (treated as `FALSE`) | Report what would be retrieved; write nothing. |

A progress bar is shown automatically while files are processed (the wrapper
creates an internal `progress_callback` handle); it is not a parameter. No bar
is shown for a dry run.

## Setup

Add three files, then delete them so `dvs_get()` has something to restore.


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
dvs_add(c("data/f1.csv", "data/f2.csv", "data/sub/f3.csv"))
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
file.remove("data/f1.csv", "data/f2.csv", "data/sub/f3.csv")
```

::: {.cell-output .cell-output-stdout}

```
[1] TRUE TRUE TRUE
```


:::

```{.r .cell-code}
dvs_status(status = "absent")[, c("path", "status")]
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 3 × 2
  path            status
  <chr>           <chr> 
1 data/f1.csv     absent
2 data/f2.csv     absent
3 data/sub/f3.csv absent
```


:::
:::


## `paths`

Restore a single file. The result reports `path`, `outcome`, and `size`.


::: {.cell}

```{.r .cell-code}
setwd(proj)
dvs_get("data/f1.csv")
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 3
  path        outcome    size
  <chr>       <chr>   <bytes>
1 data/f1.csv copied    488 B
```


:::
:::


The file is `current` again:


::: {.cell}

```{.r .cell-code}
setwd(proj)
dvs_status("data/f1.csv")[, c("path", "status")]
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 2
  path        status 
  <chr>       <chr>  
1 data/f1.csv current
```


:::
:::


## `glob`

Restore by glob. Use `**` to cross directory boundaries.


::: {.cell}

```{.r .cell-code}
setwd(proj)
dvs_get(glob = "data/**/*.csv")
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 3 × 3
  path            outcome    size
  <chr>           <chr>   <bytes>
1 data/f1.csv     present   488 B
2 data/f2.csv     copied    500 B
3 data/sub/f3.csv copied    312 B
```


:::
:::


## `dry_run`

With `dry_run = TRUE` the result reports what would be retrieved, but no file is
written.


::: {.cell}

```{.r .cell-code}
setwd(proj)
file.remove("data/f2.csv")
```

::: {.cell-output .cell-output-stdout}

```
[1] TRUE
```


:::

```{.r .cell-code}
dvs_get("data/f2.csv", dry_run = TRUE)
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 3
  path        outcome    size
  <chr>       <chr>   <bytes>
1 data/f2.csv copied    500 B
```


:::
:::


The file is still absent after a dry run:


::: {.cell}

```{.r .cell-code}
setwd(proj)
dvs_status("data/f2.csv")[, c("path", "status")]
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 2
  path        status
  <chr>       <chr> 
1 data/f2.csv absent
```


:::
:::


## Return value

A tibble with one row per file:

| Column | Type | Description |
|---|---|---|
| `path` | character | File path. |
| `outcome` | character | `copied` (written from storage) or `present` (already on disk). |
| `size` | `dvs_bytes` | Retrieved size. |

Rows that fail carry an `error` column. The `size` column is a
[dvs_bytes](r-bytes.html) value.

## Differences from the CLI

The CLI command is [dvs get](cli-get.html). It prints lines rather than
returning a data frame, and adds `--threads` and `--json`, which the R surface
does not have. Threads are set process-wide with
[set_dvs_threads()](r-threads.html).

## See also

- [dvs_init()](r-init.html), [dvs_add()](r-add.html), [dvs_status()](r-status.html)
- [Storage and meta files](intro-internals.html)
