---
title: "set_dvs_log_level()"
subtitle: "Route core log output to the R console"
format:
  html:
    keep-md: true
execute:
  freeze: auto
---

`set_dvs_log_level()` controls which log messages from the dvs core are routed
to R's console. `error` and `warn` go to stderr; `info`, `debug`, and `trace`
go to stdout. The default at package load is `off`.

```r
set_dvs_log_level(level = c("off", "error", "warn", "info", "debug", "trace"))
```

## Parameters

| Name | Type | Default | Behavior |
|---|---|---|---|
| `level` | character(1) | `"off"` | One of `off`, `error`, `warn`, `info`, `debug`, `trace`. Validated with `match.arg()`. |

Called for its side effect; returns `NULL` invisibly.

## Setup


::: {.cell}

```{.r .cell-code}
options(width = 1000)
library(dvs)
proj  <- tempfile("project_")
store <- tempfile("storage_")
dir.create(proj)
dir.create(store)
write.csv(mtcars, file.path(proj, "cars.csv"))
setwd(proj)
dvs_init(store)
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 4
  compression metadata_folder_name backend_path                                                                             backend_group
  <chr>       <lgl>                <chr>                                                                                    <chr>        
1 zstd        NA                   /private/var/folders/_x/bq8vb1b156sgl363l71by61h0000gn/T/RtmpXFfbEf/storage_770b7d88a436 staff        
```


:::
:::


## Enable logging around an operation

Set the level to `"info"` before an add, then reset to `"off"`.


::: {.cell}

```{.r .cell-code}
setwd(proj)
set_dvs_log_level("info")
dvs_add("cars.csv")
```

::: {.cell-output .cell-output-stdout}

```
Successfully added cars.csv (Copied)
```


:::

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 6
  path     outcome hash                                                                size stored_size duration_ms
  <chr>    <chr>   <chr>                                                            <bytes>     <bytes>       <dbl>
1 cars.csv copied  5920946da5cfd6b4b32cf7b2fb866d926637dadb1b38d3d943bf8db3b9ebdb63  1.7 KB       905 B           0
```


:::

```{.r .cell-code}
set_dvs_log_level("off")
```
:::


## Restore the default

`"off"` is the load-time default and silences core log output.


::: {.cell}

```{.r .cell-code}
set_dvs_log_level("off")
```
:::


::: {.callout-note}
The R package does not consult the `RUST_LOG` environment variable;
`set_dvs_log_level()` is the only way to change the level. `RUST_LOG` applies to
the CLI binary only.
:::

## See also

- [set_dvs_threads()](r-threads.html), [dvs_version()](r-version.html)
- [Error reference](error.html)
