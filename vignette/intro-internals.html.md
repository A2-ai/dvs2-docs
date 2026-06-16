---
title: "Storage and meta files"
subtitle: "blob layout, hashing, meta JSON, and compression"
format:
  html:
    keep-md: true
execute:
  freeze: auto
---

::: {.callout-note}
This page is implementation detail, beyond what normal use requires. You do not
need any of it to run the four verbs.
:::

This page builds a project with files of several sizes, then inspects the
metadata folder and the storage directory to show how dvs lays data out: a
content-addressed blob store, a `.dvs` meta file per tracked file, and per-file
compression.

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
here() starts at /Users/elea/Documents/a2ai_github/dvs2-demo-repo
```


:::
:::



# Helpers


::: {.cell}

```{.r .cell-code}
source(here::here("R/mkdatasetfiles.R"))
```
:::




::: {.cell}

```{.r .cell-code}
storage     <- basename(tempfile(fileext = "_storage"))
new_project <- basename(tempfile(fileext = "_project"))
dir.create(here::here(storage))
dir.create(here::here(new_project))
```
:::



::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))

mkdatasetfiles(n_files = 1,  size_mb = 25, prefix = "large_",      dir = "data/large",      show_progress = !nzchar(Sys.getenv("QUARTO_DOCUMENT_PATH")))
mkdatasetfiles(n_files = 3,  size_mb = 1,  prefix = "small_",      dir = "data/small",      show_progress = !nzchar(Sys.getenv("QUARTO_DOCUMENT_PATH")))
mkdatasetfiles(n_files = 50, size_mb = 3,  prefix = "individual_", dir = "data/individual", show_progress = !nzchar(Sys.getenv("QUARTO_DOCUMENT_PATH")))
```
:::



::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))

dvs_init(here::here(storage), compression = "none")
```

::: {.cell-output .cell-output-stdout}

```
DVS Initialized
```


:::

```{.r .cell-code}
dvs_add("data/large/large_1.csv", message = "add one large dataset")
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 5
  path                   outcome hash                                                                size stored_size
  <chr>                  <chr>   <chr>                                                            <bytes>     <bytes>
1 data/large/large_1.csv copied  3c77885f59933a6334a438d0a77d2adcd06873bed58a00fc9807fce3d13ed838 25.0 MB     25.0 MB
```


:::

```{.r .cell-code}
dvs_add(paths = fs::dir_ls("data/small", type = "file"), message = "add small corpus datasets")
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 3 × 5
  path                   outcome hash                                                                  size stored_size
  <chr>                  <chr>   <chr>                                                              <bytes>     <bytes>
1 data/small/small_1.csv copied  e0fb0b7aac778f07ba37105d2e2a70d1cee429f50d77c3b0c9dd4ad4d2222937 1024.0 KB   1024.0 KB
2 data/small/small_2.csv copied  1574af6b3e5cfd7fdba90c4f819fbd2bd128cd573c304588623fc09d49ae6b04 1024.0 KB   1024.0 KB
3 data/small/small_3.csv copied  9d97b050e954474b51c5b3f06eafd07bc33366b9f3b09ea1211ac75c2704357a 1024.0 KB   1024.0 KB
```


:::

```{.r .cell-code}
dvs_add(glob = "data/individual/individual_*.csv", message = "add individual datasets via glob")
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 50 × 5
   path                              outcome hash                                                                size stored_size
   <chr>                             <chr>   <chr>                                                            <bytes>     <bytes>
 1 data/individual/individual_01.csv copied  57856e362f74d4319cdb81f0454e205a91e7ad8c83e3442aee7da4c676902d53  3.0 MB      3.0 MB
 2 data/individual/individual_02.csv copied  85ee4a308973f2ef5cda8d4a1a6228a4ff69e0f72de5c2dfd1aa8f9a409e2b5c  3.0 MB      3.0 MB
 3 data/individual/individual_03.csv copied  cd648605e42fddc1c08fc761b3683021e0be3a4578b0ec9e02e84e9645db8d58  3.0 MB      3.0 MB
 4 data/individual/individual_04.csv copied  388c35ea1e0f0f55cd73c6d6e84ad7659b3954f271103b51bcc868f9f07d1aee  3.0 MB      3.0 MB
 5 data/individual/individual_05.csv copied  0dbb9776c7188194995a8ddc0dca67a9814ef7fa165cc035518386c6e51cbb92  3.0 MB      3.0 MB
 6 data/individual/individual_06.csv copied  e3d9340328668ac4a61180c62664fa53726de78410ac7b90679b9f81cee2b852  3.0 MB      3.0 MB
 7 data/individual/individual_07.csv copied  e755c66eba55a05f0cb10a6c068f29a373de0baaed2649f0b8828ff302c65d61  3.0 MB      3.0 MB
 8 data/individual/individual_08.csv copied  93cb8aaac5d09feba55d44274f96b3b67f81fd66fce959e86e6b5af80b670d61  3.0 MB      3.0 MB
 9 data/individual/individual_09.csv copied  26af472b0caf28693778231ceacf48504b4c09d2cc877dd9c4a7f1a21144d72f  3.0 MB      3.0 MB
10 data/individual/individual_10.csv copied  804e10256f674fbb79860959dc612b3f73171c96871a6707278eaea594f9d470  3.0 MB      3.0 MB
# ℹ 40 more rows
```


:::
:::


# Internals of `.dvs`

`.dvs` is hidden, so `fs::` helpers need `all = TRUE`.


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))

fs::dir_tree(".dvs", all = TRUE, regexp = "\\.git", invert = TRUE)
```

::: {.cell-output .cell-output-stdout}

```
.dvs
├── .cache
│   └── dvs.db
└── data
    ├── individual
    │   ├── individual_01.csv.dvs
    │   ├── individual_02.csv.dvs
    │   ├── individual_03.csv.dvs
    │   ├── individual_04.csv.dvs
    │   ├── individual_05.csv.dvs
    │   ├── individual_06.csv.dvs
    │   ├── individual_07.csv.dvs
    │   ├── individual_08.csv.dvs
    │   ├── individual_09.csv.dvs
    │   ├── individual_10.csv.dvs
    │   ├── individual_11.csv.dvs
    │   ├── individual_12.csv.dvs
    │   ├── individual_13.csv.dvs
    │   ├── individual_14.csv.dvs
    │   ├── individual_15.csv.dvs
    │   ├── individual_16.csv.dvs
    │   ├── individual_17.csv.dvs
    │   ├── individual_18.csv.dvs
    │   ├── individual_19.csv.dvs
    │   ├── individual_20.csv.dvs
    │   ├── individual_21.csv.dvs
    │   ├── individual_22.csv.dvs
    │   ├── individual_23.csv.dvs
    │   ├── individual_24.csv.dvs
    │   ├── individual_25.csv.dvs
    │   ├── individual_26.csv.dvs
    │   ├── individual_27.csv.dvs
    │   ├── individual_28.csv.dvs
    │   ├── individual_29.csv.dvs
    │   ├── individual_30.csv.dvs
    │   ├── individual_31.csv.dvs
    │   ├── individual_32.csv.dvs
    │   ├── individual_33.csv.dvs
    │   ├── individual_34.csv.dvs
    │   ├── individual_35.csv.dvs
    │   ├── individual_36.csv.dvs
    │   ├── individual_37.csv.dvs
    │   ├── individual_38.csv.dvs
    │   ├── individual_39.csv.dvs
    │   ├── individual_40.csv.dvs
    │   ├── individual_41.csv.dvs
    │   ├── individual_42.csv.dvs
    │   ├── individual_43.csv.dvs
    │   ├── individual_44.csv.dvs
    │   ├── individual_45.csv.dvs
    │   ├── individual_46.csv.dvs
    │   ├── individual_47.csv.dvs
    │   ├── individual_48.csv.dvs
    │   ├── individual_49.csv.dvs
    │   └── individual_50.csv.dvs
    ├── large
    │   └── large_1.csv.dvs
    └── small
        ├── small_1.csv.dvs
        ├── small_2.csv.dvs
        └── small_3.csv.dvs
```


:::
:::



::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))

fs::dir_info(".dvs", recurse = TRUE, all = TRUE, type = "file") |>
  dplyr::filter(!grepl("\\.git", path)) |>
  dplyr::select(size, path, type)
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 55 × 3
          size path                                       type 
   <fs::bytes> <fs::path>                                 <fct>
 1         20K .dvs/.cache/dvs.db                         file 
 2         264 .dvs/data/individual/individual_01.csv.dvs file 
 3         263 .dvs/data/individual/individual_02.csv.dvs file 
 4         264 .dvs/data/individual/individual_03.csv.dvs file 
 5         264 .dvs/data/individual/individual_04.csv.dvs file 
 6         264 .dvs/data/individual/individual_05.csv.dvs file 
 7         264 .dvs/data/individual/individual_06.csv.dvs file 
 8         264 .dvs/data/individual/individual_07.csv.dvs file 
 9         264 .dvs/data/individual/individual_08.csv.dvs file 
10         264 .dvs/data/individual/individual_09.csv.dvs file 
# ℹ 45 more rows
```


:::
:::



::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))

fs::dir_info(".dvs", recurse = TRUE, all = TRUE, type = "file") |>
  dplyr::filter(!grepl("\\.git", path)) |>
  dplyr::mutate(subdir = path |> fs::path_dir() |> fs::path_rel(".dvs")) |>
  dplyr::reframe(n_files = dplyr::n(), size = sum(size), .by = subdir)
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 4 × 3
  subdir          n_files        size
  <fs::path>        <int> <fs::bytes>
1 .cache                1         20K
2 data/individual      50       12.9K
3 data/large            1         254
4 data/small            3         771
```


:::
:::


# Meta files

Each tracked data file has a `.dvs` meta file under `.dvs/`, mirroring the data tree.


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))

meta_files <- fs::dir_ls(".dvs", recurse = TRUE, all = TRUE, glob = "*.dvs", type = "file")
meta_files <- meta_files[!grepl("\\.git", meta_files)]
meta_files
```

::: {.cell-output .cell-output-stdout}

```
.dvs/data/individual/individual_01.csv.dvs .dvs/data/individual/individual_02.csv.dvs .dvs/data/individual/individual_03.csv.dvs .dvs/data/individual/individual_04.csv.dvs .dvs/data/individual/individual_05.csv.dvs .dvs/data/individual/individual_06.csv.dvs .dvs/data/individual/individual_07.csv.dvs .dvs/data/individual/individual_08.csv.dvs .dvs/data/individual/individual_09.csv.dvs .dvs/data/individual/individual_10.csv.dvs .dvs/data/individual/individual_11.csv.dvs .dvs/data/individual/individual_12.csv.dvs .dvs/data/individual/individual_13.csv.dvs .dvs/data/individual/individual_14.csv.dvs .dvs/data/individual/individual_15.csv.dvs .dvs/data/individual/individual_16.csv.dvs .dvs/data/individual/individual_17.csv.dvs .dvs/data/individual/individual_18.csv.dvs .dvs/data/individual/individual_19.csv.dvs .dvs/data/individual/individual_20.csv.dvs .dvs/data/individual/individual_21.csv.dvs .dvs/data/individual/individual_22.csv.dvs .dvs/data/individual/individual_23.csv.dvs 
.dvs/data/individual/individual_24.csv.dvs .dvs/data/individual/individual_25.csv.dvs .dvs/data/individual/individual_26.csv.dvs .dvs/data/individual/individual_27.csv.dvs .dvs/data/individual/individual_28.csv.dvs .dvs/data/individual/individual_29.csv.dvs .dvs/data/individual/individual_30.csv.dvs .dvs/data/individual/individual_31.csv.dvs .dvs/data/individual/individual_32.csv.dvs .dvs/data/individual/individual_33.csv.dvs .dvs/data/individual/individual_34.csv.dvs .dvs/data/individual/individual_35.csv.dvs .dvs/data/individual/individual_36.csv.dvs .dvs/data/individual/individual_37.csv.dvs .dvs/data/individual/individual_38.csv.dvs .dvs/data/individual/individual_39.csv.dvs .dvs/data/individual/individual_40.csv.dvs .dvs/data/individual/individual_41.csv.dvs .dvs/data/individual/individual_42.csv.dvs .dvs/data/individual/individual_43.csv.dvs .dvs/data/individual/individual_44.csv.dvs .dvs/data/individual/individual_45.csv.dvs .dvs/data/individual/individual_46.csv.dvs 
.dvs/data/individual/individual_47.csv.dvs .dvs/data/individual/individual_48.csv.dvs .dvs/data/individual/individual_49.csv.dvs .dvs/data/individual/individual_50.csv.dvs .dvs/data/large/large_1.csv.dvs            .dvs/data/small/small_1.csv.dvs            .dvs/data/small/small_2.csv.dvs            .dvs/data/small/small_3.csv.dvs            
```


:::
:::


Contents of the meta file for `data/large/large_1.csv`:


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))

large_meta <- grep("large_1", meta_files, value = TRUE)
large_meta
```

::: {.cell-output .cell-output-stdout}

```
  .dvs/data/large/large_1.csv.dvs 
".dvs/data/large/large_1.csv.dvs" 
```


:::
:::



```{.r .cell-code}
setwd(here::here(new_project))
cat("```json\n")
```

```json

```{.r .cell-code}
cat(jsonlite::toJSON(jsonlite::fromJSON(large_meta, simplifyVector = FALSE), pretty = TRUE, auto_unbox = TRUE))
```

{
  "hashes": {
    "blake3": "3c77885f59933a6334a438d0a77d2adcd06873bed58a00fc9807fce3d13ed838"
  },
  "size": 26214390,
  "created_by": "elea",
  "add_time": "2026-06-16T16:49:51.156354Z",
  "compression": "none",
  "message": "add one large dataset"
}

```{.r .cell-code}
cat("\n```\n")
```

```
# Storage directory


::: {.cell}

```{.r .cell-code}
fs::dir_tree(here::here(storage), all = TRUE, regexp = "\\.git", invert = TRUE)
```

::: {.cell-output .cell-output-stdout}

```
/Users/elea/Documents/a2ai_github/dvs2-demo-repo/file469b15e12878_storage
├── 0d
│   └── bb9776c7188194995a8ddc0dca67a9814ef7fa165cc035518386c6e51cbb92
├── 15
│   └── 74af6b3e5cfd7fdba90c4f819fbd2bd128cd573c304588623fc09d49ae6b04
├── 1d
│   └── 884347c3d0433a2833ef586c83afebb2bc30cdea12d323e80f25526aacaae4
├── 1f
│   └── e13d85d36ee596cf9bc781919808458b2cd00b49bcb342e8c5db5cce915c62
├── 26
│   ├── af472b0caf28693778231ceacf48504b4c09d2cc877dd9c4a7f1a21144d72f
│   └── bfcc219ab65cd79ce696d013ae6148055d01c187e2c31570452315e441819f
├── 2a
│   └── ecd8dc9adb04d3777e23ac721bbc2828e599be8ad35af4b87400cd41148671
├── 2f
│   └── 05406da9b7905880f2f6230ca5883637820d1abecbdd12190696242e4a3077
├── 31
│   └── 758fcb8655fd233cf99e0ab466f4a7d997b85a51ecfc804965aad4d3125d18
├── 34
│   └── fd92ee0ed3122e814c275ba2d4bcf83e749ea0a4fda462d56afbd0f62fea8a
├── 38
│   └── 8c35ea1e0f0f55cd73c6d6e84ad7659b3954f271103b51bcc868f9f07d1aee
├── 3c
│   └── 77885f59933a6334a438d0a77d2adcd06873bed58a00fc9807fce3d13ed838
├── 3e
│   └── 5fb7f5dab7515086635a93328785b2b703922b6b7499cf3de2d6f4e954e98c
├── 44
│   └── 3b0aad3af092b510e3624d737d71f60cf771b5bf387c1f7126e0cd712cc8cf
├── 45
│   └── 6eaf1e596ccf2e8cc982c9ca3192f996efa0638d9dbd96a03f90fc35a34c51
├── 48
│   └── dff588f909e9720dff2a675afef20a44add218cb55e7883736326938917b73
├── 49
│   └── d367f13b24c611561d1dae7d9860390b8239689a7a7ffac393b3eaf8907be7
├── 4b
│   └── bae46269b915721b8a461f9138afaa04dbe69c2a6be89ccbd3d26abc09f869
├── 57
│   ├── 216386358ca115c810f01903cce60423037feee2faf2d3a26032627ed7ca9d
│   └── 856e362f74d4319cdb81f0454e205a91e7ad8c83e3442aee7da4c676902d53
├── 5b
│   └── 8ed16fac2af119cd417960ca8ef817507f2a74352cd10b4809fe77ad0f9759
├── 62
│   └── 058b6bf8fb1c380f4fded49604df6fa144c84e49775dd879f084124d6ea8a1
├── 71
│   └── f792a1264e4704e7f53e99f741d4baa46f0fa3ef864a83ada590a954da34e9
├── 77
│   └── d27c2060525b39adcfd943235b96f0c0158e2c6eda8ef3d007f23b0a9b29b0
├── 78
│   └── ffc0ed3e6b077436ef61504935dd65137caa45893173527f53f14dd54073c9
├── 7c
│   └── f60960fa5161e67262be59e546dc42cada90c99a6d9c767cc9eda8530a282d
├── 7d
│   └── 62b45f3c50dcaf1f3143a9c67d5a1606b58660359405f533483713157d3ce2
├── 80
│   └── 4e10256f674fbb79860959dc612b3f73171c96871a6707278eaea594f9d470
├── 81
│   └── 9f86f6a3bdc6ce6d08f3529690c674e01d89dbfcd6e5491630db4ea2add30a
├── 85
│   └── ee4a308973f2ef5cda8d4a1a6228a4ff69e0f72de5c2dfd1aa8f9a409e2b5c
├── 88
│   └── ba43b3a95a505c9605335a03f0a07d89dbb0b0fd1824d2e50f109ec8267468
├── 8d
│   └── 0524a0aaca6787bebacce86072df4b16930660998654c202a0235888512d3e
├── 93
│   ├── ca349f3eb8b7bae487fc3c871b38b702ca8774e1e47e291dbf4deef768188f
│   └── cb8aaac5d09feba55d44274f96b3b67f81fd66fce959e86e6b5af80b670d61
├── 96
│   └── 49f8ae18c09b20768f4f017ab983c75b90b3e4e5935d1308e935f2ac4e9b4b
├── 9d
│   ├── 97b050e954474b51c5b3f06eafd07bc33366b9f3b09ea1211ac75c2704357a
│   └── ec1c7c19612c726f715faef5d6057b9e4dde7d5c20d70b056cbe6f2bd7c91c
├── a0
│   └── 23d54af885922c1f2e65efa78cd32d6cef07a3a31a2edb7cbe67e862964ac7
├── ad
│   └── ebf3682c67ecf60ed348fa6eb031c786496275e9b8a47082e4839cf0d02a4d
├── audit.log.jsonl
├── b0
│   └── 5327be23b5f7172df2b5c2a19ba2a214b6d8c01d87f6231563a2b2dd9f464b
├── bc
│   └── 2c089b5bfd013e062b7cea8e22907983fb40e7824b8d309ec0dc7c46fdc6e4
├── bd
│   └── d2150b27e4b6b90cba72e1a5e9e7fa0fd38e90702c0169393c86e2dc85691a
├── c2
│   └── 332280ea27acd678ed478ae719549e643820c193e35a4362ffc57d02a211a8
├── cd
│   └── 648605e42fddc1c08fc761b3683021e0be3a4578b0ec9e02e84e9645db8d58
├── d3
│   └── 25a9ede2e5b2509fd4893dfdb350e4fd653e9a9e4fb6b2605f72ae315659c8
├── d8
│   └── 55539255e6bcef2bdb7b3be9c727312db4c8eb6229851bb2ddd71667bde6e3
├── df
│   └── 09093a115feea9827440955103488d2c73bcbaf8a56f7ff79842b19348645f
├── e0
│   └── fb0b7aac778f07ba37105d2e2a70d1cee429f50d77c3b0c9dd4ad4d2222937
├── e3
│   ├── 9164399b7147c57fc78e073fff926a23d1165b4436a5c71f70941d8acb4a58
│   └── d9340328668ac4a61180c62664fa53726de78410ac7b90679b9f81cee2b852
├── e4
│   └── 7dda9fc7f57f5acaf284aed70e127bbc78ed1a67195936cbbcf4e6d1c321b2
├── e7
│   └── 55c66eba55a05f0cb10a6c068f29a373de0baaed2649f0b8828ff302c65d61
├── ec
│   └── 1caea68524d4fb96a4ec8e9127229bc3c2e23d669be92f5add767c59889ab8
└── f3
    └── cd94c8247890360ef1b61bb7cdc49f6463c39c08b7f0e0c62ea9dec575b0fa
```


:::
:::



::: {.cell}

```{.r .cell-code}
fs::dir_info(here::here(storage), recurse = TRUE, all = TRUE, type = "file") |>
  dplyr::filter(!grepl("\\.git", path)) |>
  dplyr::mutate(subdir = path |> fs::path_dir() |> fs::path_rel(here::here(storage))) |>
  dplyr::reframe(n_files = dplyr::n(), size = sum(size), .by = subdir)
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 50 × 3
   subdir     n_files        size
   <fs::path>   <int> <fs::bytes>
 1 0d               1          3M
 2 15               1       1024K
 3 1d               1          3M
 4 1f               1          3M
 5 26               2          6M
 6 2a               1          3M
 7 2f               1          3M
 8 31               1          3M
 9 34               1          3M
10 38               1          3M
# ℹ 40 more rows
```


:::
:::


# Hashed blob is plain text

Pick up the blake3 hash from the meta file.


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))

meta <- jsonlite::fromJSON(large_meta)
meta
```

::: {.cell-output .cell-output-stdout}

```
$hashes
$hashes$blake3
[1] "3c77885f59933a6334a438d0a77d2adcd06873bed58a00fc9807fce3d13ed838"


$size
[1] 26214390

$created_by
[1] "elea"

$add_time
[1] "2026-06-16T16:49:51.156354Z"

$compression
[1] "none"

$message
[1] "add one large dataset"
```


:::

```{.r .cell-code}
hash <- meta$hashes$blake3
hash
```

::: {.cell-output .cell-output-stdout}

```
[1] "3c77885f59933a6334a438d0a77d2adcd06873bed58a00fc9807fce3d13ed838"
```


:::
:::


Blobs are split into `<first-2>/<rest>`:


::: {.cell}

```{.r .cell-code}
large_blob <- here::here(storage, substr(hash, 1, 2), substr(hash, 3, nchar(hash)))
large_blob
```

::: {.cell-output .cell-output-stdout}

```
[1] "/Users/elea/Documents/a2ai_github/dvs2-demo-repo/file469b15e12878_storage/3c/77885f59933a6334a438d0a77d2adcd06873bed58a00fc9807fce3d13ed838"
```


:::

```{.r .cell-code}
fs::file_exists(large_blob)
```

::: {.cell-output .cell-output-stdout}

```
/Users/elea/Documents/a2ai_github/dvs2-demo-repo/file469b15e12878_storage/3c/77885f59933a6334a438d0a77d2adcd06873bed58a00fc9807fce3d13ed838 
                                                                                                                                       TRUE 
```


:::
:::


Initialized with `compression = "none"`, the stored object is the original CSV, addressable by hash. Readable as-is.


::: {.cell}

```{.r .cell-code}
readLines(large_blob, n = 5)
```

::: {.cell-output .cell-output-stdout}

```
[1] "weight,Time,Chick,Diet,rand1,rand2,rand3,rand4,rand5,rand6,rand7,rand8,rand9,rand10" "42,0,1,1,835,744,435,780,819,845,933,348,470,634"                                    "51,2,1,1,678,501,383,179,313,256,607,120,393,638"                                    "59,4,1,1,128,687,923,696,798,190,506,122,254,584"                                    "64,6,1,1,929,315,597,366,830,800,287,457,774,403"                                   
```


:::
:::



::: {.cell}

```{.r .cell-code}
readLines(
  n = 5, here::here(new_project, "data", "large", "large_1.csv")
)
```

::: {.cell-output .cell-output-stdout}

```
[1] "weight,Time,Chick,Diet,rand1,rand2,rand3,rand4,rand5,rand6,rand7,rand8,rand9,rand10" "42,0,1,1,835,744,435,780,819,845,933,348,470,634"                                    "51,2,1,1,678,501,383,179,313,256,607,120,393,638"                                    "59,4,1,1,128,687,923,696,798,190,506,122,254,584"                                    "64,6,1,1,929,315,597,366,830,800,287,457,774,403"                                   
```


:::
:::




# `.dvs/` mirrors `data/`

Meta files live under `.dvs/` at the same relative paths as the data files they track.


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))

fs::dir_tree("data", regexp = "\\.git", invert = TRUE)
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

fs::dir_tree(".dvs", all = TRUE, regexp = "\\.git", invert = TRUE)
```

::: {.cell-output .cell-output-stdout}

```
.dvs
├── .cache
│   └── dvs.db
└── data
    ├── individual
    │   ├── individual_01.csv.dvs
    │   ├── individual_02.csv.dvs
    │   ├── individual_03.csv.dvs
    │   ├── individual_04.csv.dvs
    │   ├── individual_05.csv.dvs
    │   ├── individual_06.csv.dvs
    │   ├── individual_07.csv.dvs
    │   ├── individual_08.csv.dvs
    │   ├── individual_09.csv.dvs
    │   ├── individual_10.csv.dvs
    │   ├── individual_11.csv.dvs
    │   ├── individual_12.csv.dvs
    │   ├── individual_13.csv.dvs
    │   ├── individual_14.csv.dvs
    │   ├── individual_15.csv.dvs
    │   ├── individual_16.csv.dvs
    │   ├── individual_17.csv.dvs
    │   ├── individual_18.csv.dvs
    │   ├── individual_19.csv.dvs
    │   ├── individual_20.csv.dvs
    │   ├── individual_21.csv.dvs
    │   ├── individual_22.csv.dvs
    │   ├── individual_23.csv.dvs
    │   ├── individual_24.csv.dvs
    │   ├── individual_25.csv.dvs
    │   ├── individual_26.csv.dvs
    │   ├── individual_27.csv.dvs
    │   ├── individual_28.csv.dvs
    │   ├── individual_29.csv.dvs
    │   ├── individual_30.csv.dvs
    │   ├── individual_31.csv.dvs
    │   ├── individual_32.csv.dvs
    │   ├── individual_33.csv.dvs
    │   ├── individual_34.csv.dvs
    │   ├── individual_35.csv.dvs
    │   ├── individual_36.csv.dvs
    │   ├── individual_37.csv.dvs
    │   ├── individual_38.csv.dvs
    │   ├── individual_39.csv.dvs
    │   ├── individual_40.csv.dvs
    │   ├── individual_41.csv.dvs
    │   ├── individual_42.csv.dvs
    │   ├── individual_43.csv.dvs
    │   ├── individual_44.csv.dvs
    │   ├── individual_45.csv.dvs
    │   ├── individual_46.csv.dvs
    │   ├── individual_47.csv.dvs
    │   ├── individual_48.csv.dvs
    │   ├── individual_49.csv.dvs
    │   └── individual_50.csv.dvs
    ├── large
    │   └── large_1.csv.dvs
    └── small
        ├── small_1.csv.dvs
        ├── small_2.csv.dvs
        └── small_3.csv.dvs
```


:::
:::


# Cleanup


::: {.cell}

```{.r .cell-code}
unlink(here::here(new_project), recursive = TRUE)
unlink(here::here(storage),     recursive = TRUE)
```
:::


## See also

- [The dvs.toml project file](config.html): the project configuration.
- [The audit log](audit.html): the append-only record of every add.
- The command references: [dvs_add()](r-add.html) / [dvs add](cli-add.html).
