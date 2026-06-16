---
title: "new_dvs_bytes()"
subtitle: "The dvs_bytes vector and pillar printing"
format:
  html:
    keep-md: true
execute:
  freeze: auto
---

`new_dvs_bytes()` constructs a `dvs_bytes` vector. The `size` and `stored_size`
columns returned by [dvs_add()](r-add.html), [dvs_status()](r-status.html), and
[dvs_get()](r-get.html) are `dvs_bytes` values, so they print as human-readable
sizes in a tibble. Values are stored as `double` to represent sizes past 2 GB
without integer overflow.

```r
new_dvs_bytes(x)
```

## Parameters

| Name | Type | Default | Behavior |
|---|---|---|---|
| `x` | numeric | required | Byte counts (may include `NA`). |

## Construct a value


::: {.cell}

```{.r .cell-code}
options(width = 1000)
library(dvs)
b <- new_dvs_bytes(c(512, 1048576, 1073741824))
class(b)
```

::: {.cell-output .cell-output-stdout}

```
[1] "dvs_bytes" "numeric"  
```


:::
:::


## Printing in a tibble

A bare `dvs_bytes` vector prints as plain numbers, but as a tibble column it
renders via `pillar_shaft()` and `type_sum()` as right-aligned, human-readable
sizes (the `<bytes>` column type).


::: {.cell}

```{.r .cell-code}
tibble::tibble(file = c("small", "medium", "large"), size = b)
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 3 × 2
  file      size
  <chr>  <bytes>
1 small    512 B
2 medium  1.0 MB
3 large   1.0 GB
```


:::
:::


## Arithmetic and summaries

The `Ops` group generic keeps the `dvs_bytes` class for `+` and `-` (the result
is still bytes) and drops it for other operators. The `Summary` group generic
keeps it for `sum`, `min`, `max`, and `range`. A summed column stays a
`dvs_bytes` value in a tibble.


::: {.cell}

```{.r .cell-code}
suppressMessages(library(dplyr))
tibble::tibble(size = b) |> summarise(total = sum(size))
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 1
    total
  <bytes>
1  1.0 GB
```


:::
:::


## See also

- [format_byte_size()](r-format-bytes.html): the underlying formatter.
- [dvs_add()](r-add.html), [dvs_status()](r-status.html), [dvs_get()](r-get.html)
