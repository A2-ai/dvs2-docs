---
title: "Random Files"
format:
  html:
    keep-md: true
execute:
  freeze: auto
---

The `mkdatasetfiles()` helper lives in `R/mkdatasetfiles.R`:



Load it:


::: {.cell}

```{.r .cell-code}
source(here::here("R/mkdatasetfiles.R"))
```
:::


1 small file



::: {.cell}

```{.r .cell-code}
mkdatasetfiles(n_files = 1,
              dir = here::here("tmp_random_files"),
              prefix = "small_",
              size_mb = 1,
              chunk_rows = 200L,
              dataset = Theoph, extra_cols = 25,
              show_progress = !nzchar(Sys.getenv("QUARTO_DOCUMENT_PATH"))) ->
  small_file
```
:::



view the file


::: {.cell}

```{.r .cell-code}
read.csv(small_file, nrows = 5)
```
:::

File size


::: {.cell}

```{.r .cell-code}
fs::file_info(small_file)[,c("size", "type", "path")]
```
:::


That's a 1MB. Good!

1 large file


::: {.cell}

```{.r .cell-code}
mkdatasetfiles(n_files = 1,
              chunk_rows = 200000L,
              dir = here::here("tmp_random_files"),
              size_mb = 25,
              prefix = "large_",
              dataset = Theoph, extra_cols = 25,
              show_progress = !nzchar(Sys.getenv("QUARTO_DOCUMENT_PATH"))) ->
  large_file
```
:::




::: {.cell}

```{.r .cell-code}
fs::file_info(large_file)[,c("size", "type", "path")]
```
:::



::: {.cell}

```{.r .cell-code}
large_file_data <- read.csv(large_file)

duplicated(large_file_data) |> table(useNA = "always") |> print() |> summary()
```
:::


2 individual files


::: {.cell}

```{.r .cell-code}
mkdatasetfiles(n_files = 2, dir = here::here("tmp_random_files"), size_mb = 10, prefix = "individual_", dataset = Theoph, extra_cols = 10,
              show_progress = !nzchar(Sys.getenv("QUARTO_DOCUMENT_PATH"))) ->
  individual_files
```
:::



file info to confirm


::: {.cell}

```{.r .cell-code}
fs::file_info(individual_files)[,c("size", "type", "path")]
```
:::


Are they identical?


::: {.cell}

```{.r .cell-code}
individual_datasets <- lapply(individual_files, \(path) read.csv(path))

all.equal(individual_datasets[[1]], individual_datasets[[2]]) |>
  isTRUE()
```
:::


The generated individual files are not duplicates. Good.

---

Return to the [full index](index.html) for an overview of all dvs demo vignettes.

