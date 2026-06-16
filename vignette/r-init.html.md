---
title: "dvs_init()"
subtitle: "Initialize a project and configure storage"
format:
  html:
    keep-md: true
execute:
  freeze: auto
---

`dvs_init()` creates a `dvs.toml` project file and a metadata folder (`.dvs` by
default), recording where file contents are stored and how they are compressed.

```r
dvs_init(
  storage_path,
  root_dir = NULL,
  group = NULL,
  metadata_folder_name = NULL,
  compression = c("zstd", "none")
)
```

## Parameters

| Name | Type | Default | Behavior |
|---|---|---|---|
| `storage_path` | character(1) | required | Directory where file contents are stored. |
| `root_dir` | character(1) | `NULL` (current directory) | Where `dvs.toml` and the metadata folder are created. |
| `group` | character(1) | `NULL` | Unix group set on the storage directory and stored files. |
| `metadata_folder_name` | character(1) | `NULL` (`.dvs`) | Name of the metadata folder. |
| `compression` | character(1) | `"zstd"` | Compression for stored files. One of `"zstd"` or `"none"`. |

## Setup

Each example initializes its own project directory, because `dvs_init()` errors
if a `dvs.toml` already exists in the target root.


::: {.cell}

```{.r .cell-code}
options(width = 1000)
library(dvs)
base <- tempfile("dvs_init_")
dir.create(base)
```
:::


## `storage_path` and `root_dir`

`storage_path` is the only required argument. `root_dir` controls where the
project file lands; it defaults to the current working directory.


::: {.cell}

```{.r .cell-code}
proj  <- file.path(base, "basic")
store <- file.path(base, "basic-store")
dir.create(proj)
dir.create(store)
dvs_init(store, root_dir = proj)
```

::: {.cell-output .cell-output-stdout}

```
DVS Initialized
```


:::
:::


`dvs.toml` is written in `root_dir` and records the storage path:


::: {.cell}

```{.r .cell-code}
cat(readLines(file.path(proj, "dvs.toml")), sep = "\n")
```

::: {.cell-output .cell-output-stdout}

```
compression = "zstd"

[backend]
path = "/var/folders/_x/bq8vb1b156sgl363l71by61h0000gn/T//RtmpP5AuC2/dvs_init_1a0b333ff86a/basic-store"
group = "staff"
```


:::
:::


## `group`

`group` sets a Unix group on the storage directory and stored files for shared
access. The group must exist and you must be a member. This example is not
executed; it depends on a specific group on the host.


::: {.cell}

```{.r .cell-code}
proj  <- file.path(base, "grouped")
store <- file.path(base, "grouped-store")
dir.create(proj)
dir.create(store)
dvs_init(store, root_dir = proj, group = "rstudio")
```
:::


```r
$status
[1] "initialized"
```

The chosen group is written to `dvs.toml` under `[backend]`.

## `metadata_folder_name`

Use a metadata folder name other than `.dvs`. The name is recorded in
`dvs.toml`.


::: {.cell}

```{.r .cell-code}
proj  <- file.path(base, "meta")
store <- file.path(base, "meta-store")
dir.create(proj)
dir.create(store)
dvs_init(store, root_dir = proj, metadata_folder_name = ".meta")
```

::: {.cell-output .cell-output-stdout}

```
DVS Initialized
```


:::

```{.r .cell-code}
list.files(proj, all.files = TRUE, no.. = TRUE)
```

::: {.cell-output .cell-output-stdout}

```
[1] ".meta"    "dvs.toml"
```


:::
:::


## `compression`

`compression` is an enum: `"zstd"` (default) or `"none"`. With `"none"` the
stored blob is the same size as the input. Here the same file is added under
both settings and the `stored_size` column differs.


::: {.cell}

```{.r .cell-code}
mk <- function(name, comp) {
  proj  <- file.path(base, name)
  store <- file.path(base, paste0(name, "-store"))
  dir.create(proj)
  dir.create(store)
  dvs_init(store, root_dir = proj, compression = comp)
  write.csv(mtcars, file.path(proj, "cars.csv"))
  old <- setwd(proj)
  on.exit(setwd(old))
  dvs_add("cars.csv")
}
mk("zstd-proj", "zstd")
```

::: {.cell-output .cell-output-stdout}

```
DVS Initialized
```


:::

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 5
  path     outcome hash                                                                size stored_size
  <chr>    <chr>   <chr>                                                            <bytes>     <bytes>
1 cars.csv copied  5920946da5cfd6b4b32cf7b2fb866d926637dadb1b38d3d943bf8db3b9ebdb63  1.7 KB       905 B
```


:::

```{.r .cell-code}
mk("none-proj", "none")
```

::: {.cell-output .cell-output-stdout}

```
DVS Initialized
```


:::

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 5
  path     outcome hash                                                                size stored_size
  <chr>    <chr>   <chr>                                                            <bytes>     <bytes>
1 cars.csv copied  5920946da5cfd6b4b32cf7b2fb866d926637dadb1b38d3d943bf8db3b9ebdb63  1.7 KB      1.7 KB
```


:::
:::


::: {.callout-note}
There is no `no_compression` argument. The CLI flag `--no-compression` maps to
`compression = "none"`. See [dvs init](cli-init.html).
:::

## Return value

`dvs_init()` returns a list with a single `status` element and prints a
confirmation line. It is called for its side effect of creating the project.


::: {.cell}

```{.r .cell-code}
proj  <- file.path(base, "ret")
store <- file.path(base, "ret-store")
dir.create(proj)
dir.create(store)
res <- dvs_init(store, root_dir = proj)
```

::: {.cell-output .cell-output-stdout}

```
DVS Initialized
```


:::

```{.r .cell-code}
str(res)
```

::: {.cell-output .cell-output-stdout}

```
List of 1
 $ status: chr "initialized"
```


:::
:::


## Differences from the CLI

The CLI command is [dvs init](cli-init.html). It uses a `--no-compression`
boolean instead of the `compression` enum, and adds `--threads` and `--json`,
which the R surface does not have. Threads are set process-wide with
[set_dvs_threads()](r-threads.html).

## See also

- [dvs_add()](r-add.html), [dvs_status()](r-status.html), [dvs_get()](r-get.html)
- [The dvs.toml project file](config.html)
- [Storage and meta files](intro-internals.html)
