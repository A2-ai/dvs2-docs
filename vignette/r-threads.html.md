---
title: "set_dvs_threads()"
subtitle: "Set the process-wide thread pool size"
format:
  html:
    keep-md: true
execute:
  freeze: auto
---

`set_dvs_threads()` sets how many threads dvs uses for parallel file operations
(`dvs_add()`, `dvs_get()`, `dvs_status()`). The value is stored as the
`dvs.num_threads` option and synced to the dvs core before each operation. It is
process-wide; there is no per-call thread argument in R.

```r
set_dvs_threads(threads)
```

## Parameters

| Name | Type | Default | Behavior |
|---|---|---|---|
| `threads` | integer(1) or `NULL` | required | Number of threads (must be a positive integer), or `NULL` to revert to automatic detection. |

Returns the previous value invisibly.

## Setup


::: {.cell}

```{.r .cell-code}
options(width = 1000)
library(dvs)
```
:::


## Set a fixed thread count

Set a fixed number of threads. It takes effect on the next add, get, or status.


::: {.cell}

```{.r .cell-code}
set_dvs_threads(2)
getOption("dvs.num_threads")
```

::: {.cell-output .cell-output-stdout}

```
[1] 2
```


:::
:::


## Reset to automatic

Pass `NULL` to revert to automatic detection. The automatic default is
`min(parallelism * 4, 16)`.


::: {.cell}

```{.r .cell-code}
set_dvs_threads(NULL)
getOption("dvs.num_threads")
```

::: {.cell-output .cell-output-stdout}

```
NULL
```


:::
:::


## Differences from the CLI

The CLI sets threads per call with `--threads <N>`, or process-wide with the
`DVS_NUM_THREADS` environment variable. The R setting is process-wide only; see
the `--threads` flag on any [CLI command](cli-init.html).

## See also

- [set_dvs_log_level()](r-loglevel.html), [dvs_version()](r-version.html)
- [dvs_add()](r-add.html), [dvs_get()](r-get.html), [dvs_status()](r-status.html)
