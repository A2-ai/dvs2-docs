---
title: "dvs configuration"
subtitle: "dvs.toml fields, compression tradeoffs, threads, and metadata folder name"
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
mkdatasetfiles(n_files = 5, size_mb = 5, prefix = "file_", dir = "data", show_progress = !nzchar(Sys.getenv("QUARTO_DOCUMENT_PATH")))
dvs_init(here::here(storage))
```

::: {.cell-output .cell-output-stdout}

```
DVS Initialized
```


:::
:::


# `dvs.toml`

`dvs_init()` writes a `dvs.toml` at the project root:


::: {.cell}

```{.r .cell-code}
cat(readLines(here::here(new_project, "dvs.toml")), sep = "\n")
```

::: {.cell-output .cell-output-stdout}

```
compression = "zstd"

[backend]
path = "/Users/elea/Documents/a2ai_github/dvs2-demo/filed8e74e275450_storage"
group = "staff"
```


:::
:::


| Field | Meaning |
|-------|---------|
| `storage_path` | Where dvs copies blobs. Any directory reachable from this machine — local path or network mount. |
| `metadata_folder_name` | Defaults to `.dvs`. The folder that mirrors your data tree and holds meta files. Change if `.dvs` collides with another tool. |
| `compression` | `"zstd"` (default) or `"none"`. zstd typically halves storage footprint for tabular data. |

# Compression: `zstd` vs `none`

Same data, two different compression settings — compare resulting storage size.


::: {.cell}

```{.r .cell-code}
storage_zstd <- basename(tempfile(fileext = "_zstd_storage"))
storage_none <- basename(tempfile(fileext = "_none_storage"))
project_zstd <- basename(tempfile(fileext = "_zstd_project"))
project_none <- basename(tempfile(fileext = "_none_project"))
for (d in c(storage_zstd, storage_none, project_zstd, project_none)) dir.create(here::here(d))
```
:::



::: {.cell}

```{.r .cell-code}
setwd(here::here(project_zstd))
mkdatasetfiles(n_files = 5, size_mb = 10, prefix = "data_", dir = "data", show_progress = !nzchar(Sys.getenv("QUARTO_DOCUMENT_PATH")))
```
:::



::: {.cell}

```{.r .cell-code}
setwd(here::here(project_none))
mkdatasetfiles(n_files = 5, size_mb = 10, prefix = "data_", dir = "data", show_progress = !nzchar(Sys.getenv("QUARTO_DOCUMENT_PATH")))
```
:::



::: {.cell}

```{.r .cell-code}
setwd(here::here(project_zstd))
dvs_init(here::here(storage_zstd), compression = "zstd")
```

::: {.cell-output .cell-output-stdout}

```
DVS Initialized
```


:::

```{.r .cell-code}
invisible(dvs_add(glob = "data/*.csv", message = "add with zstd compression"))
```
:::



::: {.cell}

```{.r .cell-code}
setwd(here::here(project_none))
dvs_init(here::here(storage_none), compression = "none")
```

::: {.cell-output .cell-output-stdout}

```
DVS Initialized
```


:::

```{.r .cell-code}
invisible(dvs_add(glob = "data/*.csv", message = "add with no compression"))
```
:::


Compare storage sizes:


::: {.cell}

```{.r .cell-code}
storage_summary <- function(path, label) {
  info <- fs::dir_info(path, recurse = TRUE, type = "file") |>
    dplyr::filter(!grepl("\\.git|audit\\.log", path))
  dplyr::tibble(
    compression  = label,
    n_blobs      = nrow(info),
    size_bytes   = sum(as.numeric(info$size)),
    size_mb      = round(sum(as.numeric(info$size)) / 1e6, 2)
  )
}

comparison <- dplyr::bind_rows(
  storage_summary(here::here(storage_zstd), "zstd"),
  storage_summary(here::here(storage_none), "none")
)

comparison |>
  dplyr::mutate(ratio = round(size_bytes / size_bytes[compression == "none"], 3))
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 2 × 5
  compression n_blobs size_bytes size_mb ratio
  <chr>         <int>      <dbl>   <dbl> <dbl>
1 zstd              5   22042575    22.0  0.42
2 none              5   52428720    52.4  1   
```


:::
:::


# Threads

`set_dvs_threads()` controls how many parallel threads dvs uses for hashing
and copying blobs. The default is auto-detect (one thread per logical CPU).


::: {.cell}

```{.r .cell-code}
storage_t <- basename(tempfile(fileext = "_threads_storage"))
project_t <- basename(tempfile(fileext = "_threads_project"))
dir.create(here::here(storage_t))
dir.create(here::here(project_t))
```
:::



::: {.cell}

```{.r .cell-code}
setwd(here::here(project_t))
mkdatasetfiles(n_files = 50, size_mb = 3, prefix = "f_", dir = "data", show_progress = !nzchar(Sys.getenv("QUARTO_DOCUMENT_PATH")))
dvs_init(here::here(storage_t))
```

::: {.cell-output .cell-output-stdout}

```
DVS Initialized
```


:::
:::


Time `dvs_add` with a single thread:


::: {.cell}

```{.r .cell-code}
set_dvs_threads(1)
t1 <- system.time({
  setwd(here::here(project_t))
  invisible(dvs_add(glob = "data/*.csv", message = "1 thread"))
})
cat("1 thread :", round(t1["elapsed"], 2), "s\n")
```

::: {.cell-output .cell-output-stdout}

```
1 thread : 0.89 s
```


:::
:::


Re-stage files by appending a byte so dvs sees them as unsynced:


::: {.cell}

```{.r .cell-code}
setwd(here::here(project_t))
for (f in fs::dir_ls("data", type = "file")) write("", f, append = TRUE)
```
:::


Time with four threads:


::: {.cell}

```{.r .cell-code}
set_dvs_threads(4)
t4 <- system.time({
  setwd(here::here(project_t))
  invisible(dvs_add(glob = "data/*.csv", message = "4 threads"))
})
cat("4 threads:", round(t4["elapsed"], 2), "s\n")
```

::: {.cell-output .cell-output-stdout}

```
4 threads: 0.24 s
```


:::
:::


# Custom metadata folder name

`metadata_folder_name` overrides the default `.dvs` folder. Useful when
another tool in the project already claims that name.


::: {.cell}

```{.r .cell-code}
storage_m <- basename(tempfile(fileext = "_meta_storage"))
project_m <- basename(tempfile(fileext = "_meta_project"))
dir.create(here::here(storage_m))
dir.create(here::here(project_m))
```
:::



::: {.cell}

```{.r .cell-code}
setwd(here::here(project_m))
mkdatasetfiles(n_files = 1, size_mb = 1, prefix = "d_", dir = "data", show_progress = !nzchar(Sys.getenv("QUARTO_DOCUMENT_PATH")))
dvs_init(here::here(storage_m), metadata_folder_name = "datalock")
```

::: {.cell-output .cell-output-stdout}

```
DVS Initialized
```


:::

```{.r .cell-code}
invisible(dvs_add(glob = "data/*.csv", message = "custom folder name demo"))
```
:::


The meta files live under `datalock/` instead of `.dvs/`:


::: {.cell}

```{.r .cell-code}
setwd(here::here(project_m))
fs::dir_tree("datalock", all = TRUE)
```

::: {.cell-output .cell-output-stdout}

```
datalock
├── .cache
│   └── dvs.db
└── data
    └── d_1.csv.dvs
```


:::
:::


The `dvs.toml` records the custom name so all subsequent operations pick it up
automatically:


::: {.cell}

```{.r .cell-code}
cat(readLines(here::here(project_m, "dvs.toml")), sep = "\n")
```

::: {.cell-output .cell-output-stdout}

```
compression = "zstd"
metadata_folder_name = "datalock"

[backend]
path = "/Users/elea/Documents/a2ai_github/dvs2-demo/filed8e74b51bf6b_meta_storage"
group = "staff"
```


:::
:::


# `group` (Unix only)

`dvs_init(storage, group = "mygroup")` sets the Unix group on the storage
directory and all blobs written to it. This ensures that members of the group
can read and write blobs without permission errors on shared filesystems.

```r
# example — not executed here
dvs_init("/mnt/shared/storage", group = "data-team")
```

# Cleanup


::: {.cell}

```{.r .cell-code}
for (d in c(storage, new_project,
            storage_zstd, storage_none, project_zstd, project_none,
            storage_t, project_t,
            storage_m, project_m)) {
  unlink(here::here(d), recursive = TRUE)
}
```
:::


---

**Next up**: [Audit log](audit.html) — parsing and querying `audit.log.jsonl` with purrr and dplyr.
