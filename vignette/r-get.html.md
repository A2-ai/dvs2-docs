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

A local file that differs from the tracked version is replaced without asking
only when dvs itself put it there, for example after switching git branches.
Otherwise it is a conflict, handled by `on_conflict`.

```r
dvs_get(
  paths = character(0),
  glob = NULL,
  recursive = FALSE,
  dry_run = FALSE,
  on_conflict = NULL,
  on_error = NULL
)
```

## Parameters

| Name | Type | Default | Behavior |
|---|---|---|---|
| `paths` | character | `character(0)` | Files to retrieve. |
| `glob` | character(1) | `NULL` | Library-expanded glob. Uses a literal path separator (use `**` to recurse). |
| `recursive` | logical(1) | `FALSE` | If `TRUE`, walk explicit directory paths recursively (same as the CLI `-r`). |
| `dry_run` | logical(1) | `FALSE` | Report what would be retrieved. Write nothing. |
| `on_conflict` | character(1) | `NULL` | `"abort"`, `"skip"` or `"overwrite"`. What to do with files that have local changes. `NULL` takes `DVS_GET_ON_CONFLICT`, then `[get] on_conflict` in `dvs.toml`, then `"abort"`. |
| `on_error` | character(1) | `NULL` | `"return"`, `"warn"` or `"error"`. What to do when get did not do as asked. `NULL` takes the `dvs.on_error` option, then `"return"`. |

In interactive sessions a progress bar is shown while files are processed. It is
not a parameter, and no bar appears in scripts, rendered documents, or dry runs.

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
# A tibble: 1 × 4
  compression metadata_folder_name backend_path                                                                            backend_group
  <chr>       <lgl>                <chr>                                                                                   <chr>        
1 zstd        NA                   /private/var/folders/_x/bq8vb1b156sgl363l71by61h0000gn/T/RtmpgQNOo9/storage_5ed18147cd0 staff        
```


:::

```{.r .cell-code}
dvs_add(c("data/f1.csv", "data/f2.csv", "data/sub/f3.csv"))
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 3 × 6
  path            outcome hash                                                                size stored_size duration_ms
  <chr>           <chr>   <chr>                                                            <bytes>     <bytes>       <dbl>
1 data/f1.csv     copied  5e2c49dd5c8a24a2ffe102e42804812c7eabc2c49682240480558eac390c5d65   488 B       306 B           0
2 data/f2.csv     copied  c9c0ca2ba19bf1d65159ba2b7300c3336fdf113c92b79901e06be4b40fcd8871   500 B       275 B           0
3 data/sub/f3.csv copied  881b133ef44731569b7844e1dc60f10e5fc4a9f2c2ac36fe20b2bba636d6bbce   312 B       140 B           1
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

Restore a single file. The result has one row per requested file, under a
summary line. `before` is the state of the file before the get, and `action` is
what get did with it.


::: {.cell}

```{.r .cell-code}
setwd(proj)
dvs_get("data/f1.csv")
```

::: {.cell-output .cell-output-stdout}

```
# Restored 1
# A tibble: 1 × 13
  path        local_path  before action   satisfied    size target_hash                                                      local_hash stored_copy code  message hint  duration_ms
* <chr>       <chr>       <chr>  <chr>    <lgl>     <bytes> <chr>                                                            <chr>      <chr>       <chr> <chr>   <chr>       <dbl>
1 data/f1.csv data/f1.csv absent restored TRUE        488 B 5e2c49dd5c8a24a2ffe102e42804812c7eabc2c49682240480558eac390c5d65 <NA>       <NA>        <NA>  <NA>    <NA>            0
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
# Restored 2, 1 already current
# A tibble: 3 × 13
  path            local_path      before  action    satisfied    size target_hash                                                      local_hash                                                       stored_copy code  message hint  duration_ms
* <chr>           <chr>           <chr>   <chr>     <lgl>     <bytes> <chr>                                                            <chr>                                                            <chr>       <chr> <chr>   <chr>       <dbl>
1 data/f1.csv     data/f1.csv     current unchanged TRUE        488 B 5e2c49dd5c8a24a2ffe102e42804812c7eabc2c49682240480558eac390c5d65 5e2c49dd5c8a24a2ffe102e42804812c7eabc2c49682240480558eac390c5d65 <NA>        <NA>  <NA>    <NA>            0
2 data/f2.csv     data/f2.csv     absent  restored  TRUE        500 B c9c0ca2ba19bf1d65159ba2b7300c3336fdf113c92b79901e06be4b40fcd8871 <NA>                                                             <NA>        <NA>  <NA>    <NA>            0
3 data/sub/f3.csv data/sub/f3.csv absent  restored  TRUE        312 B 881b133ef44731569b7844e1dc60f10e5fc4a9f2c2ac36fe20b2bba636d6bbce <NA>                                                             <NA>        <NA>  <NA>    <NA>            0
```


:::
:::


## `recursive`

A directory path restores only the files directly in it. Here the nested
`data/sub/f3.csv` is left alone.


::: {.cell}

```{.r .cell-code}
setwd(proj)
file.remove("data/f1.csv", "data/f2.csv", "data/sub/f3.csv")
```

::: {.cell-output .cell-output-stdout}

```
[1] TRUE TRUE TRUE
```


:::

```{.r .cell-code}
dvs_get("data")
```

::: {.cell-output .cell-output-stdout}

```
# Restored 2
# A tibble: 2 × 13
  path        local_path  before action   satisfied    size target_hash                                                      local_hash stored_copy code  message hint  duration_ms
* <chr>       <chr>       <chr>  <chr>    <lgl>     <bytes> <chr>                                                            <chr>      <chr>       <chr> <chr>   <chr>       <dbl>
1 data/f1.csv data/f1.csv absent restored TRUE        488 B 5e2c49dd5c8a24a2ffe102e42804812c7eabc2c49682240480558eac390c5d65 <NA>       <NA>        <NA>  <NA>    <NA>            0
2 data/f2.csv data/f2.csv absent restored TRUE        500 B c9c0ca2ba19bf1d65159ba2b7300c3336fdf113c92b79901e06be4b40fcd8871 <NA>       <NA>        <NA>  <NA>    <NA>            0
```


:::
:::



::: {.cell}

```{.r .cell-code}
setwd(proj)
dvs_status("data/sub/f3.csv")[, c("path", "status")]
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 2
  path            status
  <chr>           <chr> 
1 data/sub/f3.csv absent
```


:::
:::


With `recursive = TRUE` the whole subtree is restored. Files already back on
disk are `current` before and `unchanged` after. They are not copied again.


::: {.cell}

```{.r .cell-code}
setwd(proj)
dvs_get("data", recursive = TRUE)
```

::: {.cell-output .cell-output-stdout}

```
# Restored 1, 2 already current
# A tibble: 3 × 13
  path            local_path      before  action    satisfied    size target_hash                                                      local_hash                                                       stored_copy code  message hint  duration_ms
* <chr>           <chr>           <chr>   <chr>     <lgl>     <bytes> <chr>                                                            <chr>                                                            <chr>       <chr> <chr>   <chr>       <dbl>
1 data/f1.csv     data/f1.csv     current unchanged TRUE        488 B 5e2c49dd5c8a24a2ffe102e42804812c7eabc2c49682240480558eac390c5d65 5e2c49dd5c8a24a2ffe102e42804812c7eabc2c49682240480558eac390c5d65 <NA>        <NA>  <NA>    <NA>            0
2 data/f2.csv     data/f2.csv     current unchanged TRUE        500 B c9c0ca2ba19bf1d65159ba2b7300c3336fdf113c92b79901e06be4b40fcd8871 c9c0ca2ba19bf1d65159ba2b7300c3336fdf113c92b79901e06be4b40fcd8871 <NA>        <NA>  <NA>    <NA>            0
3 data/sub/f3.csv data/sub/f3.csv absent  restored  TRUE        312 B 881b133ef44731569b7844e1dc60f10e5fc4a9f2c2ac36fe20b2bba636d6bbce <NA>                                                             <NA>        <NA>  <NA>    <NA>            0
```


:::
:::


`glob` and `recursive` are mutually exclusive; passing both raises an error.

## `dry_run`

With `dry_run = TRUE` the result reports what would be retrieved
(`would_restore`), but no file is written. `satisfied` is the prediction.


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
# Would restore 1
# A tibble: 1 × 13
  path        local_path  before action        satisfied    size target_hash                                                      local_hash stored_copy code  message hint  duration_ms
* <chr>       <chr>       <chr>  <chr>         <lgl>     <bytes> <chr>                                                            <chr>      <chr>       <chr> <chr>   <chr>       <dbl>
1 data/f2.csv data/f2.csv absent would_restore TRUE        500 B c9c0ca2ba19bf1d65159ba2b7300c3336fdf113c92b79901e06be4b40fcd8871 <NA>       <NA>        <NA>  <NA>    <NA>            0
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


## `on_conflict`

Edit a tracked file. Its status is `modified`, so a get of it is a conflict.
With the default, `"abort"`, get changes no file at all, not even the absent
`data/f2.csv`. The `code` and `hint` columns say why and what to do.


::: {.cell}

```{.r .cell-code}
setwd(proj)
write.csv(mtcars[1:9, ], "data/f1.csv")
res <- dvs_get("data")
res[, c("path", "before", "action", "satisfied", "code")]
```

::: {.cell-output .cell-output-stdout}

```
# 2 of 2 rows from:
# Aborted, nothing changed: 1 file has local changes
# on_conflict = abort (default)
# A tibble: 2 × 5
  path        before   action  satisfied code         
  <chr>       <chr>    <chr>   <lgl>     <chr>        
1 data/f1.csv modified not_run FALSE     local_changes
2 data/f2.csv absent   not_run FALSE     batch_aborted
```


:::
:::


`"skip"` leaves the conflicting file and gets the rest:


::: {.cell}

```{.r .cell-code}
setwd(proj)
dvs_get("data", on_conflict = "skip")[, c("path", "before", "action", "satisfied")]
```

::: {.cell-output .cell-output-stdout}

```
# 2 of 2 rows from:
# Partial: restored 1, skipped 1
# on_conflict = skip (command line)
# A tibble: 2 × 4
  path        before   action   satisfied
  <chr>       <chr>    <chr>    <lgl>    
1 data/f1.csv modified skipped  FALSE    
2 data/f2.csv absent   restored TRUE     
```


:::
:::


`"overwrite"` replaces the file with the tracked version. The local changes are
lost.


::: {.cell}

```{.r .cell-code}
setwd(proj)
dvs_get("data/f1.csv", on_conflict = "overwrite")[, c("path", "before", "action", "satisfied")]
```

::: {.cell-output .cell-output-stdout}

```
# 1 of 1 rows from:
# Replaced 1
# on_conflict = overwrite (command line)
# A tibble: 1 × 4
  path        before   action   satisfied
  <chr>       <chr>    <chr>    <lgl>    
1 data/f1.csv modified replaced TRUE     
```


:::
:::


The policy can also come from the `DVS_GET_ON_CONFLICT` environment variable or
from `[get] on_conflict` in `dvs.toml`. `dvs.toml` cannot set `"overwrite"`.
That raises a `dvs_config_error`.

## `on_error`

By default `dvs_get()` returns its result even when it did not do as asked,
that is when a file failed or `"abort"` held files back. `"warn"` also warns.
`"error"` raises an error of class `dvs_get_incomplete`, which carries the
result as `cnd$result`.


::: {.cell}

```{.r .cell-code}
setwd(proj)
write.csv(mtcars[1:10, ], "data/f1.csv")
dvs_get("data/f1.csv", on_error = "error")
```

::: {.cell-output .cell-output-error}

```
Error in `dvs_get()`:
! Aborted, nothing changed: 1 file has local changes
on_conflict = abort (default)
! data/f1.csv: local changes since dvs last wrote this file
    keep your version: dvs add data/f1.csv (makes it the tracked version); take the tracked version: dvs get --force data/f1.csv (replaces yours)
See the `code`, `message` and `hint` columns of `cnd$result`.
```


:::
:::


In scripts and pipelines, pass `on_error = "error"` or set
`options(dvs.on_error = "error")`, so the analysis cannot go on with data that
was not updated.

## Return value

A tibble of class `dvs_get_result` with one row per requested file and always
the same columns:

| Column | Type | Description |
|---|---|---|
| `path` | character | Path relative to the project root. |
| `local_path` | character | Path relative to the working directory. |
| `before` | character | State before the get: `absent`, `current`, `clean`, `modified`, `unknown`, `not_tracked`, `not_a_file` or `unsafe_path`. |
| `action` | character | What get did: `restored`, `replaced`, `unchanged`, `skipped`, `not_run`, `failed`, `would_restore` or `would_replace`. |
| `satisfied` | logical | `TRUE` when the file is at its tracked version afterwards. |
| `size` | `dvs_bytes` | Size of the tracked version. |
| `target_hash` | character | blake3 hash of the tracked version. |
| `local_hash` | character | blake3 hash of the local file before the get, or `NA`. |
| `stored_copy` | character | For a conflict, whether the local version has a copy in storage: `present`, `absent` or `unknown`. `NA` otherwise. |
| `code` | character | The kind of problem, such as `local_changes`, or `NA`. |
| `message` | character | What went wrong, or `NA`. |
| `hint` | character | The next step, in CLI syntax, or `NA`. |
| `duration_ms` | double | Milliseconds spent on the file, `NA` when it was never hashed or copied. |

A file that cannot be retrieved, such as an untracked path, is a row with
`action` `failed`, not an R error. Outside a dvs project `dvs_get()` raises an
error. The `size` column is a [dvs_bytes](r-bytes.html) value.

`dvs_result_info()` returns what applies to the whole operation: `outcome`
(`complete`, `aborted`, `partial` or `failed`), `did_as_asked`, `on_conflict`
and its `source`, the `counts`, and the `summary` printed above the rows.


::: {.cell}

```{.r .cell-code}
setwd(proj)
info <- dvs_result_info(res)
info[c("outcome", "did_as_asked", "on_conflict", "source")]
```

::: {.cell-output .cell-output-stdout}

```
$outcome
[1] "aborted"

$did_as_asked
[1] FALSE

$on_conflict
[1] "abort"

$source
[1] "default"
```


:::
:::


## Differences from the CLI

The CLI command is [dvs get](cli-get.html). It prints lines rather than
returning a data frame, and adds `--threads` and `--json`, which the R surface
does not have. Its `--force` is short for `--on-conflict overwrite`. It has no
`on_error`: its exit code is non-zero when get did not do as asked. Threads are set process-wide with
[set_dvs_threads()](r-threads.html).

## See also

- [dvs_init()](r-init.html), [dvs_add()](r-add.html), [dvs_status()](r-status.html)
- [Storage and meta files](intro-internals.html)
