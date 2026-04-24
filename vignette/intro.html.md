---
title: "Introduction to dvs"
subtitle: "a data version control system"
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



# Helpers


::: {.cell}

```{.r .cell-code}
source(here::here("R/mkdatasetfiles.R"))
```
:::



See `vignette/random_files.qmd` for a demonstration of this function. 



::: {.cell}

```{.r .cell-code}
storage     <- basename(tempfile(fileext = "_storage"))
new_project <- basename(tempfile(fileext = "_project"))
dir.create(here::here(storage))
dir.create(here::here(new_project))
```
:::



Let us add 1x25MB file (large), 3x1MB (small) and 50x3MB files (individual)


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))

mkdatasetfiles(n_files = 1,  size_mb = 25, prefix = "large_",      dir = "data/large",      show_progress = !nzchar(Sys.getenv("QUARTO_DOCUMENT_PATH"))) -> large_file
mkdatasetfiles(n_files = 3,  size_mb = 1,  prefix = "small_",      dir = "data/small",      show_progress = !nzchar(Sys.getenv("QUARTO_DOCUMENT_PATH"))) -> small_files
mkdatasetfiles(n_files = 50, size_mb = 3,  prefix = "individual_", dir = "data/individual", show_progress = !nzchar(Sys.getenv("QUARTO_DOCUMENT_PATH"))) -> individual_files
```
:::




::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))

fs::dir_tree(
  "data"
)
```

::: {.cell-output .cell-output-stdout}

```
data
├── individual
│   ├── individual_01.csv
│   ├── individual_02.csv
│   ├── individual_03.csv
│   ├── individual_04.csv
│   ├── individual_05.csv
│   ├── individual_06.csv
│   ├── individual_07.csv
│   ├── individual_08.csv
│   ├── individual_09.csv
│   ├── individual_10.csv
│   ├── individual_11.csv
│   ├── individual_12.csv
│   ├── individual_13.csv
│   ├── individual_14.csv
│   ├── individual_15.csv
│   ├── individual_16.csv
│   ├── individual_17.csv
│   ├── individual_18.csv
│   ├── individual_19.csv
│   ├── individual_20.csv
│   ├── individual_21.csv
│   ├── individual_22.csv
│   ├── individual_23.csv
│   ├── individual_24.csv
│   ├── individual_25.csv
│   ├── individual_26.csv
│   ├── individual_27.csv
│   ├── individual_28.csv
│   ├── individual_29.csv
│   ├── individual_30.csv
│   ├── individual_31.csv
│   ├── individual_32.csv
│   ├── individual_33.csv
│   ├── individual_34.csv
│   ├── individual_35.csv
│   ├── individual_36.csv
│   ├── individual_37.csv
│   ├── individual_38.csv
│   ├── individual_39.csv
│   ├── individual_40.csv
│   ├── individual_41.csv
│   ├── individual_42.csv
│   ├── individual_43.csv
│   ├── individual_44.csv
│   ├── individual_45.csv
│   ├── individual_46.csv
│   ├── individual_47.csv
│   ├── individual_48.csv
│   ├── individual_49.csv
│   └── individual_50.csv
├── large
│   └── large_1.csv
└── small
    ├── small_1.csv
    ├── small_2.csv
    └── small_3.csv
```


:::
:::




::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))

fs::dir_info(
  "data",recurse = TRUE, type = "directory",
)[, c("size", "path", "type")]
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 3 × 3
         size path            type     
  <fs::bytes> <fs::path>      <fct>    
1       1.62K data/individual directory
2          96 data/large      directory
3         160 data/small      directory
```


:::
:::


False sizes unfortunately;


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))

fs::dir_info(
  "data",recurse = TRUE, type = "file",
)[, c("size", "path", "type")] 
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 54 × 3
          size path                              type 
   <fs::bytes> <fs::path>                        <fct>
 1          3M data/individual/individual_01.csv file 
 2          3M data/individual/individual_02.csv file 
 3          3M data/individual/individual_03.csv file 
 4          3M data/individual/individual_04.csv file 
 5          3M data/individual/individual_05.csv file 
 6          3M data/individual/individual_06.csv file 
 7          3M data/individual/individual_07.csv file 
 8          3M data/individual/individual_08.csv file 
 9          3M data/individual/individual_09.csv file 
10          3M data/individual/individual_10.csv file 
# ℹ 44 more rows
```


:::
:::




::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))


fs::dir_info(
  "data",recurse = TRUE, type = "file",
) |> 
  dplyr::mutate(data_dir = path |> fs::path_dir() |> fs::path_rel("data")) |> 
  dplyr::select(path, type, size, data_dir) |>
  dplyr::reframe(size = sum(size), .by = c(data_dir))
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 3 × 2
  data_dir          size
  <fs::path> <fs::bytes>
1 individual        150M
2 large              25M
3 small               3M
```


:::
:::


Initialize a dvs repository


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



::: {.cell}

```{.r .cell-code}
cat(
  readLines(here::here(new_project, "dvs.toml"))
)
```

::: {.cell-output .cell-output-stdout}

```
compression = "zstd"  [backend] path = "/Users/elea/Documents/a2ai_github/dvs2-demo/filed3da5c73f7a9_storage" group = "staff"
```


:::
:::



Add the new files in the project to the dvs repository


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))

# single file
dvs_add("data/large/large_1.csv", message = "add one large dataset")
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 5
  path                   outcome hash                                                                size stored_size
  <chr>                  <chr>   <chr>                                                            <bytes>     <bytes>
1 data/large/large_1.csv copied  3c77885f59933a6334a438d0a77d2adcd06873bed58a00fc9807fce3d13ed838 25.0 MB     10.5 MB
```


:::

```{.r .cell-code}
# whole folder
dvs_add(paths = fs::dir_ls("data/small", type = "file"), message = "add small corpus datasets")
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 3 × 5
  path                   outcome hash                                                                  size stored_size
  <chr>                  <chr>   <chr>                                                              <bytes>     <bytes>
1 data/small/small_1.csv copied  e0fb0b7aac778f07ba37105d2e2a70d1cee429f50d77c3b0c9dd4ad4d2222937 1024.0 KB    427.8 KB
2 data/small/small_2.csv copied  1574af6b3e5cfd7fdba90c4f819fbd2bd128cd573c304588623fc09d49ae6b04 1024.0 KB    427.9 KB
3 data/small/small_3.csv copied  9d97b050e954474b51c5b3f06eafd07bc33366b9f3b09ea1211ac75c2704357a 1024.0 KB    428.1 KB
```


:::

```{.r .cell-code}
# glob
# dvs_add("data/individual", glob = "individiual_*.csv", message = "add individual datasets via glob")
dvs_add(glob = "data/individual/individual_*.csv", message = "add individual datasets via glob")
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 50 × 5
   path                              outcome hash                                                                size stored_size
   <chr>                             <chr>   <chr>                                                            <bytes>     <bytes>
 1 data/individual/individual_01.csv copied  57856e362f74d4319cdb81f0454e205a91e7ad8c83e3442aee7da4c676902d53  3.0 MB      1.3 MB
 2 data/individual/individual_02.csv copied  85ee4a308973f2ef5cda8d4a1a6228a4ff69e0f72de5c2dfd1aa8f9a409e2b5c  3.0 MB      1.3 MB
 3 data/individual/individual_03.csv copied  cd648605e42fddc1c08fc761b3683021e0be3a4578b0ec9e02e84e9645db8d58  3.0 MB      1.3 MB
 4 data/individual/individual_04.csv copied  388c35ea1e0f0f55cd73c6d6e84ad7659b3954f271103b51bcc868f9f07d1aee  3.0 MB      1.3 MB
 5 data/individual/individual_05.csv copied  0dbb9776c7188194995a8ddc0dca67a9814ef7fa165cc035518386c6e51cbb92  3.0 MB      1.3 MB
 6 data/individual/individual_06.csv copied  e3d9340328668ac4a61180c62664fa53726de78410ac7b90679b9f81cee2b852  3.0 MB      1.3 MB
 7 data/individual/individual_07.csv copied  e755c66eba55a05f0cb10a6c068f29a373de0baaed2649f0b8828ff302c65d61  3.0 MB      1.3 MB
 8 data/individual/individual_08.csv copied  93cb8aaac5d09feba55d44274f96b3b67f81fd66fce959e86e6b5af80b670d61  3.0 MB      1.3 MB
 9 data/individual/individual_09.csv copied  26af472b0caf28693778231ceacf48504b4c09d2cc877dd9c4a7f1a21144d72f  3.0 MB      1.3 MB
10 data/individual/individual_10.csv copied  804e10256f674fbb79860959dc612b3f73171c96871a6707278eaea594f9d470  3.0 MB      1.3 MB
# ℹ 40 more rows
```


:::
:::



Status


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))

dvs_status()
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 54 × 8
   path                              status  hash                                                                size created_by compression message                          add_time           
   <chr>                             <chr>   <chr>                                                            <bytes> <chr>      <chr>       <chr>                            <dttm>             
 1 data/individual/individual_01.csv current 57856e362f74d4319cdb81f0454e205a91e7ad8c83e3442aee7da4c676902d53  3.0 MB elea       zstd        add individual datasets via glob 2026-04-24 12:58:43
 2 data/individual/individual_02.csv current 85ee4a308973f2ef5cda8d4a1a6228a4ff69e0f72de5c2dfd1aa8f9a409e2b5c  3.0 MB elea       zstd        add individual datasets via glob 2026-04-24 12:58:43
 3 data/individual/individual_03.csv current cd648605e42fddc1c08fc761b3683021e0be3a4578b0ec9e02e84e9645db8d58  3.0 MB elea       zstd        add individual datasets via glob 2026-04-24 12:58:43
 4 data/individual/individual_04.csv current 388c35ea1e0f0f55cd73c6d6e84ad7659b3954f271103b51bcc868f9f07d1aee  3.0 MB elea       zstd        add individual datasets via glob 2026-04-24 12:58:43
 5 data/individual/individual_05.csv current 0dbb9776c7188194995a8ddc0dca67a9814ef7fa165cc035518386c6e51cbb92  3.0 MB elea       zstd        add individual datasets via glob 2026-04-24 12:58:43
 6 data/individual/individual_06.csv current e3d9340328668ac4a61180c62664fa53726de78410ac7b90679b9f81cee2b852  3.0 MB elea       zstd        add individual datasets via glob 2026-04-24 12:58:43
 7 data/individual/individual_07.csv current e755c66eba55a05f0cb10a6c068f29a373de0baaed2649f0b8828ff302c65d61  3.0 MB elea       zstd        add individual datasets via glob 2026-04-24 12:58:43
 8 data/individual/individual_08.csv current 93cb8aaac5d09feba55d44274f96b3b67f81fd66fce959e86e6b5af80b670d61  3.0 MB elea       zstd        add individual datasets via glob 2026-04-24 12:58:43
 9 data/individual/individual_09.csv current 26af472b0caf28693778231ceacf48504b4c09d2cc877dd9c4a7f1a21144d72f  3.0 MB elea       zstd        add individual datasets via glob 2026-04-24 12:58:43
10 data/individual/individual_10.csv current 804e10256f674fbb79860959dc612b3f73171c96871a6707278eaea594f9d470  3.0 MB elea       zstd        add individual datasets via glob 2026-04-24 12:58:43
# ℹ 44 more rows
```


:::
:::



Let us accidentally delete a few individual files:

::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))

unlink("data/individual/individual_04.csv")
unlink("data/individual/individual_08.csv")
unlink("data/individual/individual_15.csv")
unlink("data/individual/individual_16.csv")
unlink("data/individual/individual_23.csv")
```
:::



First, what is the status?


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))

dvs_status(status = "absent")
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 5 × 8
  path                              status hash                                                                size created_by compression message                          add_time           
  <chr>                             <chr>  <chr>                                                            <bytes> <chr>      <chr>       <chr>                            <dttm>             
1 data/individual/individual_04.csv absent 388c35ea1e0f0f55cd73c6d6e84ad7659b3954f271103b51bcc868f9f07d1aee  3.0 MB elea       zstd        add individual datasets via glob 2026-04-24 12:58:43
2 data/individual/individual_08.csv absent 93cb8aaac5d09feba55d44274f96b3b67f81fd66fce959e86e6b5af80b670d61  3.0 MB elea       zstd        add individual datasets via glob 2026-04-24 12:58:43
3 data/individual/individual_15.csv absent bc2c089b5bfd013e062b7cea8e22907983fb40e7824b8d309ec0dc7c46fdc6e4  3.0 MB elea       zstd        add individual datasets via glob 2026-04-24 12:58:43
4 data/individual/individual_16.csv absent 57216386358ca115c810f01903cce60423037feee2faf2d3a26032627ed7ca9d  3.0 MB elea       zstd        add individual datasets via glob 2026-04-24 12:58:43
5 data/individual/individual_23.csv absent 1fe13d85d36ee596cf9bc781919808458b2cd00b49bcb342e8c5db5cce915c62  3.0 MB elea       zstd        add individual datasets via glob 2026-04-24 12:58:43
```


:::
:::



Or filter manually with `dplyr`:


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))

dplyr::filter(dvs_status(), status == "absent")
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 5 × 8
  path                              status hash                                                                size created_by compression message                          add_time           
  <chr>                             <chr>  <chr>                                                            <bytes> <chr>      <chr>       <chr>                            <dttm>             
1 data/individual/individual_04.csv absent 388c35ea1e0f0f55cd73c6d6e84ad7659b3954f271103b51bcc868f9f07d1aee  3.0 MB elea       zstd        add individual datasets via glob 2026-04-24 12:58:43
2 data/individual/individual_08.csv absent 93cb8aaac5d09feba55d44274f96b3b67f81fd66fce959e86e6b5af80b670d61  3.0 MB elea       zstd        add individual datasets via glob 2026-04-24 12:58:43
3 data/individual/individual_15.csv absent bc2c089b5bfd013e062b7cea8e22907983fb40e7824b8d309ec0dc7c46fdc6e4  3.0 MB elea       zstd        add individual datasets via glob 2026-04-24 12:58:43
4 data/individual/individual_16.csv absent 57216386358ca115c810f01903cce60423037feee2faf2d3a26032627ed7ca9d  3.0 MB elea       zstd        add individual datasets via glob 2026-04-24 12:58:43
5 data/individual/individual_23.csv absent 1fe13d85d36ee596cf9bc781919808458b2cd00b49bcb342e8c5db5cce915c62  3.0 MB elea       zstd        add individual datasets via glob 2026-04-24 12:58:43
```


:::
:::




Let us restore them:


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))

dvs_get(glob = "data/individual/individual_*.csv")
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 50 × 3
   path                              outcome    size
   <chr>                             <chr>   <bytes>
 1 data/individual/individual_01.csv present  3.0 MB
 2 data/individual/individual_02.csv present  3.0 MB
 3 data/individual/individual_03.csv present  3.0 MB
 4 data/individual/individual_04.csv copied   3.0 MB
 5 data/individual/individual_05.csv present  3.0 MB
 6 data/individual/individual_06.csv present  3.0 MB
 7 data/individual/individual_07.csv present  3.0 MB
 8 data/individual/individual_08.csv copied   3.0 MB
 9 data/individual/individual_09.csv present  3.0 MB
10 data/individual/individual_10.csv present  3.0 MB
# ℹ 40 more rows
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

This was the happy path — init, add, status, get. Everything worked as expected.

**Next up**: [CLI](intro-cli.html) — the same operations driven from the terminal via the `dvs` binary. After that, [Internals](intro-internals.html) digs into the `.dvs/` folder layout, meta files, and content-addressed blob storage.

