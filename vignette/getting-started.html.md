---
title: "Getting Started with dvs"
subtitle: "init, add, status, and get: five minutes end to end"
format:
  html:
    keep-md: true
execute:
  freeze: auto
---

## Setup


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


Create isolated temporary directories for this demo:


::: {.cell}

```{.r .cell-code}
storage     <- basename(tempfile(fileext = "_storage"))
new_project <- basename(tempfile(fileext = "_project"))
dir.create(here::here(storage))
dir.create(here::here(new_project))
```
:::


Save the built-in `Theoph` pharmacokinetic dataset as a CSV:


::: {.cell}

```{.r .cell-code}
dir.create(here::here(new_project, "data"))
write.csv(Theoph, here::here(new_project, "data/theoph.csv"), row.names = FALSE)
```
:::


## `dvs_init`

Initialize a dvs repository pointing at the storage directory:


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


## `dvs_status` (before any adds)

No files are tracked yet:


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))
dvs_status()
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 0 × 0
```


:::
:::


## `dvs_add`

Track the dataset with a message:


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))
dvs_add("data/theoph.csv", message = "add Theoph dataset")
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


## `dvs_status`

The file is now tracked and `current`:


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))
dvs_status()
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 8
  path            status  hash                                                                size created_by compression message            add_time           
  <chr>           <chr>   <chr>                                                            <bytes> <chr>      <chr>       <chr>              <dttm>             
1 data/theoph.csv current cdd978e51298006701f7b285aaf979933f0af6b179bbdf3347014af3bcd48c06  2.9 KB elea       zstd        add Theoph dataset 2026-04-24 12:58:26
```


:::
:::


## Add a second copy

Write another copy of the dataset and track it:


::: {.cell}

```{.r .cell-code}
write.csv(Theoph, here::here(new_project, "data/theoph_v2.csv"), row.names = FALSE)
```
:::



::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))
dvs_add("data/theoph_v2.csv", message = "add second Theoph copy")
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 5
  path               outcome hash                                                                size stored_size
  <chr>              <chr>   <chr>                                                            <bytes>     <bytes>
1 data/theoph_v2.csv copied  cdd978e51298006701f7b285aaf979933f0af6b179bbdf3347014af3bcd48c06  2.9 KB      2.9 KB
```


:::

```{.r .cell-code}
dvs_status()
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 2 × 8
  path               status  hash                                                                size created_by compression message                add_time           
  <chr>              <chr>   <chr>                                                            <bytes> <chr>      <chr>       <chr>                  <dttm>             
1 data/theoph.csv    current cdd978e51298006701f7b285aaf979933f0af6b179bbdf3347014af3bcd48c06  2.9 KB elea       zstd        add Theoph dataset     2026-04-24 12:58:26
2 data/theoph_v2.csv current cdd978e51298006701f7b285aaf979933f0af6b179bbdf3347014af3bcd48c06  2.9 KB elea       zstd        add second Theoph copy 2026-04-24 12:58:26
```


:::
:::


## Modify a file, check status

Append a row to `theoph.csv` to simulate a local edit after it was stored:


::: {.cell}

```{.r .cell-code}
write.csv(
  rbind(Theoph, Theoph[1L, ]),
  here::here(new_project, "data/theoph.csv"),
  row.names = FALSE
)
```
:::


`dvs_status` detects that the file on disk no longer matches the stored hash:


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))
dvs_status()
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 2 × 8
  path               status   hash                                                                size created_by compression message                add_time           
  <chr>              <chr>    <chr>                                                            <bytes> <chr>      <chr>       <chr>                  <dttm>             
1 data/theoph.csv    unsynced cdd978e51298006701f7b285aaf979933f0af6b179bbdf3347014af3bcd48c06  2.9 KB elea       zstd        add Theoph dataset     2026-04-24 12:58:26
2 data/theoph_v2.csv current  cdd978e51298006701f7b285aaf979933f0af6b179bbdf3347014af3bcd48c06  2.9 KB elea       zstd        add second Theoph copy 2026-04-24 12:58:26
```


:::
:::


## Delete the original, check status


::: {.cell}

```{.r .cell-code}
unlink(here::here(new_project, "data/theoph.csv"))
```
:::


`theoph.csv` now shows `absent`; `theoph_v2.csv` remains `current`:


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))
dvs_status()
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 2 × 8
  path               status  hash                                                                size created_by compression message                add_time           
  <chr>              <chr>   <chr>                                                            <bytes> <chr>      <chr>       <chr>                  <dttm>             
1 data/theoph.csv    absent  cdd978e51298006701f7b285aaf979933f0af6b179bbdf3347014af3bcd48c06  2.9 KB elea       zstd        add Theoph dataset     2026-04-24 12:58:26
2 data/theoph_v2.csv current cdd978e51298006701f7b285aaf979933f0af6b179bbdf3347014af3bcd48c06  2.9 KB elea       zstd        add second Theoph copy 2026-04-24 12:58:26
```


:::
:::


## `dvs_get`

Restore the deleted file from storage:


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


Both files are `current` again:


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))
dvs_status()
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 2 × 8
  path               status  hash                                                                size created_by compression message                add_time           
  <chr>              <chr>   <chr>                                                            <bytes> <chr>      <chr>       <chr>                  <dttm>             
1 data/theoph.csv    current cdd978e51298006701f7b285aaf979933f0af6b179bbdf3347014af3bcd48c06  2.9 KB elea       zstd        add Theoph dataset     2026-04-24 12:58:26
2 data/theoph_v2.csv current cdd978e51298006701f7b285aaf979933f0af6b179bbdf3347014af3bcd48c06  2.9 KB elea       zstd        add second Theoph copy 2026-04-24 12:58:26
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


---

**Next up**: [Getting Started, CLI](getting-started-cli.html): the same workflow driven from the terminal via the `dvs` binary.
