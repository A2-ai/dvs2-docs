---
title: "format_byte_size()"
subtitle: "Human-readable byte sizes"
format:
  html:
    keep-md: true
execute:
  freeze: auto
---

`format_byte_size()` formats a byte count as a human-readable size string. It is
the same formatter used to print the `size` columns returned by
[dvs_add()](r-add.html), [dvs_status()](r-status.html), and
[dvs_get()](r-get.html).

```r
format_byte_size(size_bytes)
```

## Parameters

| Name | Type | Default | Behavior |
|---|---|---|---|
| `size_bytes` | numeric(1) | required | A single non-negative byte count. |

## Usage


::: {.cell}

```{.r .cell-code}
options(width = 1000)
library(dvs)
sapply(c(0, 512, 2048, 5e6, 3e9), format_byte_size)
```

::: {.cell-output .cell-output-stdout}

```
[1] "0 B"    "512 B"  "2.0 KB" "4.8 MB" "2.8 GB"
```


:::
:::


## See also

- [new_dvs_bytes()](r-bytes.html): the `dvs_bytes` vector type that uses this formatter.
- [set_dvs_threads()](r-threads.html), [dvs_version()](r-version.html)
