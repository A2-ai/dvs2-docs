---
title: "Random Files"
format:
  html:
    keep-md: true
execute:
  freeze: auto
---

## Overview

`mkdatasetfiles()` is a test-data generator used throughout these vignettes. It is not part of
dvs. It produces a chosen number of CSV files at a chosen size, so you can exercise dvs add,
push, fetch, hash, and compression at any scale, from a single 1 MB file to multi-gigabyte
batches of hundreds of files.

Key controls:

- `n_files`: how many files to generate
- `size_mb`: target on-disk size for each file (bytes are padded to this target)
- `dir`: output directory (created automatically)
- `prefix`: filename prefix; files are numbered `<prefix>1.csv`, `<prefix>2.csv`, and so on
- `dataset`: base R data frame whose columns seed the content (default: `ChickWeight`)
- `extra_cols`: number of random-integer columns appended to each row (increases width, and
  therefore file size, independently of row count)

Each file gets its own `set.seed(i)`, so the files in a batch are distinct even though they are
the same size.

The helper is sourced inline at the top of any vignette that needs test files; nothing is
installed into the R session permanently.

---

The `mkdatasetfiles()` helper lives in `R/mkdatasetfiles.R`:

```r
mkdatasetfiles <- function(n_files,
                           dir,
                           size_mb,
                           prefix = "file_",
                           dataset = datasets::ChickWeight,
                           extra_cols = 10L,
                           max_int = 1000L,
                           chunk_size_mb = 8,
                           chunk_rows = NULL,
                           show_progress = TRUE) {
  stopifnot(
    length(n_files) == 1L, is.numeric(n_files), n_files >= 1, n_files == as.integer(n_files),
    length(dir) == 1L, nzchar(dir),
    length(size_mb) == 1L, is.numeric(size_mb), size_mb > 0,
    length(prefix) == 1L, nzchar(prefix),
    is.data.frame(dataset),
    length(extra_cols) == 1L, extra_cols >= 0, extra_cols == as.integer(extra_cols),
    length(max_int) == 1L, max_int >= 1, max_int == as.integer(max_int),
    length(chunk_size_mb) == 1L, is.numeric(chunk_size_mb), chunk_size_mb > 0,
    is.null(chunk_rows) ||
      (length(chunk_rows) == 1L && chunk_rows >= 1 && chunk_rows == as.integer(chunk_rows)),
    is.logical(show_progress), length(show_progress) == 1L
  )

  dir.create(dir, recursive = TRUE, showWarnings = FALSE)

  target_bytes <- as.numeric(size_mb) * 1024^2
  chunk_target_bytes <- min(as.numeric(chunk_size_mb) * 1024^2, target_bytes)
  width <- max(1L, nchar(as.character(n_files)))

  dataset[] <- lapply(dataset, as.character)
  n_base <- nrow(dataset)
  if (n_base == 0L) stop("`dataset` must have at least one row.")

  base_names <- names(dataset)
  extra_names <- if (extra_cols > 0L) paste0("rand", seq_len(extra_cols)) else character(0)
  header_raw <- charToRaw(paste0(paste(c(base_names, extra_names), collapse = ","), "\n"))
  base_row_lines <- do.call(paste, c(dataset, list(sep = ",")))
  rand_lut <- if (extra_cols > 0L) as.character(0:(max_int - 1L)) else NULL
  out_files <- character(n_files)

  make_chunk_lines <- if (extra_cols > 0L) {
    function(start_row, n_rows) {
      idx <- ((seq.int(start_row, length.out = n_rows) - 1L) %% n_base) + 1L
      rand_chr <- matrix(
        rand_lut[sample.int(max_int, n_rows * extra_cols, replace = TRUE)],
        nrow = n_rows,
        ncol = extra_cols
      )
      rand_lines <- do.call(
        paste,
        c(as.data.frame(rand_chr, stringsAsFactors = FALSE), list(sep = ","))
      )
      paste0(base_row_lines[idx], ",", rand_lines)
    }
  } else {
    function(start_row, n_rows) {
      idx <- ((seq.int(start_row, length.out = n_rows) - 1L) %% n_base) + 1L
      base_row_lines[idx]
    }
  }

  chunk_rows <- if (is.null(chunk_rows)) {
    sample_n <- min(n_base, 1000L)
    sample_lines <- make_chunk_lines(1L, sample_n)
    sample_bytes <- as.numeric(utils::object.size(sample_lines))
    bytes_per_row <- max(1, ceiling(sample_bytes / sample_n))
    max(1L, as.integer(floor(chunk_target_bytes / bytes_per_row)))
  } else {
    as.integer(chunk_rows)
  }

  pb <- NULL
  if (show_progress) {
    pb <- utils::txtProgressBar(min = 0L, max = n_files, style = 3)
    on.exit(if (!is.null(pb)) close(pb), add = TRUE)
  }

  had_seed <- exists(".Random.seed", envir = globalenv(), inherits = FALSE)
  saved_seed <- if (had_seed) get(".Random.seed", envir = globalenv(), inherits = FALSE)
  on.exit({
    if (had_seed) {
      assign(".Random.seed", saved_seed, envir = globalenv())
    } else if (exists(".Random.seed", envir = globalenv(), inherits = FALSE)) {
      rm(".Random.seed", envir = globalenv())
    }
  }, add = TRUE)

  for (i in seq_len(n_files)) {
    set.seed(i)

    out_path <- file.path(dir, sprintf("%s%0*d.csv", prefix, width, i))
    out_files[i] <- out_path

    file_con <- file(out_path, open = "wb")
    on.exit(close(file_con), add = TRUE)

    writeBin(header_raw, file_con)
    bytes_written <- length(header_raw)
    start_row <- 1L

    repeat {
      remaining_bytes <- target_bytes - bytes_written
      if (remaining_bytes <= 0L) break

      lines <- make_chunk_lines(start_row, chunk_rows)
      line_bytes <- nchar(lines, type = "bytes") + 1L
      keep_n <- findInterval(remaining_bytes, cumsum(line_bytes))
      if (keep_n == 0L) break

      if (keep_n < length(lines)) {
        lines <- lines[seq_len(keep_n)]
        line_bytes <- line_bytes[seq_len(keep_n)]
      }

      writeChar(paste(lines, collapse = "\n"), file_con, eos = NULL, useBytes = TRUE)
      writeBin(as.raw(10L), file_con)

      bytes_written <- bytes_written + sum(line_bytes)
      start_row <- ((start_row + length(lines) - 1L) %% n_base) + 1L

      if (length(lines) < chunk_rows) break
    }

    close(file_con)
    on.exit(NULL, add = FALSE)

    if (show_progress) utils::setTxtProgressBar(pb, i)
  }

  invisible(file.path(normalizePath(dir, winslash = "/", mustWork = FALSE), basename(out_files)))
}
```

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

::: {.cell-output .cell-output-stdout}

```
  Subject   Wt Dose Time  conc rand1 rand2 rand3 rand4 rand5 rand6 rand7 rand8
1       1 79.6 4.02 0.00  0.74   835   217   463   793   915   685   184   796
2       1 79.6 4.02 0.25  2.84   678   609   673   108   340   918   438   592
3       1 79.6 4.02 0.57  6.57   128   193   732   687   485   217   779   519
4       1 79.6 4.02 1.12 10.50   929    18   492   518   563   462   112   549
5       1 79.6 4.02 2.02  9.66   508   272   674   623   471   988   509   120
  rand9 rand10 rand11 rand12 rand13 rand14 rand15 rand16 rand17 rand18 rand19
1   736    386    473    879    805    668    531    755    643    653    839
2   815    944    680    124    923    341    706    725    333    971     84
3   978    723    569    441    220     51    956    447    146    956    542
4    79    345    829    120    721    639    637    957    250    353    909
5   725    729    589    406    172    370    716    127    360    472    490
  rand20 rand21 rand22 rand23 rand24 rand25
1    475    406    260    457    103    897
2    661    743    286     35    255    810
3    584    654     63    529    271    229
4    813    429    862     36    215    485
5    447    670    673    591    727    847
```


:::
:::

File size


::: {.cell}

```{.r .cell-code}
fs::file_info(small_file)[,c("size", "type", "path")]
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 3
         size type  path                                                        
  <fs::bytes> <fct> <fs::path>                                                  
1       1024K file  …ocuments/a2ai_github/dvs2-demo/tmp_random_files/small_1.csv
```


:::
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

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 3
         size type  path                                                        
  <fs::bytes> <fct> <fs::path>                                                  
1         25M file  …ocuments/a2ai_github/dvs2-demo/tmp_random_files/large_1.csv
```


:::
:::



::: {.cell}

```{.r .cell-code}
large_file_data <- read.csv(large_file)

duplicated(large_file_data) |> table(useNA = "always") |> print() |> summary()
```

::: {.cell-output .cell-output-stdout}

```

 FALSE   <NA> 
222825      0 
```


:::

::: {.cell-output .cell-output-stdout}

```
Number of cases in table: 222825 
Number of factors: 1 
```


:::
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

::: {.cell-output .cell-output-stdout}

```
# A tibble: 2 × 3
         size type  path                                                        
  <fs::bytes> <fct> <fs::path>                                                  
1         10M file  …nts/a2ai_github/dvs2-demo/tmp_random_files/individual_1.csv
2         10M file  …nts/a2ai_github/dvs2-demo/tmp_random_files/individual_2.csv
```


:::
:::


Are they identical?


::: {.cell}

```{.r .cell-code}
individual_datasets <- lapply(individual_files, \(path) read.csv(path))

all.equal(individual_datasets[[1]], individual_datasets[[2]]) |>
  isTRUE()
```

::: {.cell-output .cell-output-stdout}

```
[1] FALSE
```


:::
:::


The generated individual files are not duplicates. Good.

---

Return to the [full index](index.html) for an overview of all dvs demo vignettes.

