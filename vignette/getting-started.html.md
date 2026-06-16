---
title: "R walkthrough"
subtitle: "The core loop with library(dvs)"
format:
  html:
    keep-md: true
execute:
  freeze: auto
---

This walkthrough runs the everyday loop from R: initialize a project, add a
file, check its status, delete it, then get it back. It is the "I re-cloned a
project and need its data" sequence. The [CLI walkthrough](getting-started-cli.html)
covers the same steps from the terminal.

## Setup


::: {.cell}

```{.r .cell-code}
options(width = 1000)
library(dvs)
library(here)
```

::: {.cell-output .cell-output-stderr}

```
here() starts at /Users/elea/Documents/a2ai_github/dvs2-demo-repo
```


:::
:::


Create a project directory and a sibling storage directory, then save R's
built-in `Theoph` dataset as a CSV.


::: {.cell}

```{.r .cell-code}
storage     <- basename(tempfile(fileext = "_storage"))
new_project <- basename(tempfile(fileext = "_project"))
dir.create(here::here(storage))
dir.create(here::here(new_project))
dir.create(here::here(new_project, "data"))
write.csv(Theoph, here::here(new_project, "data/theoph.csv"), row.names = FALSE)
```
:::


## 1. Initialize

Point storage at the sibling directory. See [dvs_init()](r-init.html) for every
parameter.


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))
dvs_init(here::here(storage))
```

::: {.cell-output .cell-output-stdout}

```
DVS Initialized
```


:::
:::


## 2. Add

Track the CSV with a message. See [dvs_add()](r-add.html).


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))
dvs_add("data/theoph.csv", message = "initial Theoph data")
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 5
  path            outcome hash                                                                size stored_size
  <chr>           <chr>   <chr>                                                            <bytes>     <bytes>
1 data/theoph.csv copied  cdd978e51298006701f7b285aaf979933f0af6b179bbdf3347014af3bcd48c06  2.9 KB       842 B
```


:::
:::


## 3. Status

The file is tracked and `current`. See [dvs_status()](r-status.html).


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))
dvs_status()
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 8
  path            status  hash                                                                size created_by compression message             add_time           
  <chr>           <chr>   <chr>                                                            <bytes> <chr>      <chr>       <chr>               <dttm>             
1 data/theoph.csv current cdd978e51298006701f7b285aaf979933f0af6b179bbdf3347014af3bcd48c06  2.9 KB elea       zstd        initial Theoph data 2026-06-16 16:46:45
```


:::
:::


## 4. Remove the file

Delete the local copy, the moment after a fresh clone where the data is not on
disk yet.


::: {.cell}

```{.r .cell-code}
unlink(here::here(new_project, "data/theoph.csv"))
```
:::


## 5. Status again

The file is now `absent`: tracked, but missing locally.


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))
dvs_status()
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 8
  path            status hash                                                                size created_by compression message             add_time           
  <chr>           <chr>  <chr>                                                            <bytes> <chr>      <chr>       <chr>               <dttm>             
1 data/theoph.csv absent cdd978e51298006701f7b285aaf979933f0af6b179bbdf3347014af3bcd48c06  2.9 KB elea       zstd        initial Theoph data 2026-06-16 16:46:45
```


:::
:::


::: {.callout-note}
dvs reports three states: `current`, `absent`, and `unsynced` (on disk but not
matching the stored hash). See [Storage and meta files](intro-internals.html).
:::

## 6. Get

Restore the file from storage. See [dvs_get()](r-get.html).


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))
dvs_get("data/theoph.csv")
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 3
  path            outcome    size
  <chr>           <chr>   <bytes>
1 data/theoph.csv copied   2.9 KB
```


:::
:::


## 7. Status again

The file is `current` again. The loop is complete.


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))
dvs_status()
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 8
  path            status  hash                                                                size created_by compression message             add_time           
  <chr>           <chr>   <chr>                                                            <bytes> <chr>      <chr>       <chr>               <dttm>             
1 data/theoph.csv current cdd978e51298006701f7b285aaf979933f0af6b179bbdf3347014af3bcd48c06  2.9 KB elea       zstd        initial Theoph data 2026-06-16 16:46:45
```


:::
:::


## Cleanup


::: {.cell}

```{.r .cell-code}
unlink(here::here(new_project), recursive = TRUE)
unlink(here::here(storage),     recursive = TRUE)
```
:::


## Next steps

- The [R Package](r-init.html) reference covers every parameter of
  [dvs_init()](r-init.html), [dvs_add()](r-add.html),
  [dvs_status()](r-status.html), and [dvs_get()](r-get.html).
- The same loop from the terminal: [CLI walkthrough](getting-started-cli.html).
- How dvs stores data: [Storage and meta files](intro-internals.html).
