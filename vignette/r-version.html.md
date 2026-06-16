---
title: "dvs_version()"
subtitle: "Report the core crate version"
format:
  html:
    keep-md: true
execute:
  freeze: auto
---

`dvs_version()` returns the version string of the dvs core crate that the R
package is built against.

```r
dvs_version()
```

## Parameters

None.

## Usage


::: {.cell}

```{.r .cell-code}
options(width = 1000)
library(dvs)
dvs_version()
```

::: {.cell-output .cell-output-stdout}

```
[1] "0.3.0"
```


:::
:::


## Differences from the CLI

The CLI reports its version with `dvs --version` (or `-V`).

## See also

- [set_dvs_threads()](r-threads.html), [set_dvs_log_level()](r-loglevel.html)
