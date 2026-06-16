---
title: "Introduction to dvs CLI"
subtitle: "the same operations driven from the terminal via the `dvs` binary"
format:
  html:
    keep-md: true
execute:
  freeze: auto
---

# Setup

R creates the sandbox directories and data files; all dvs operations below run
via the `dvs` CLI binary.


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


Pass the paths to the shell so bash chunks can use them:


::: {.cell}

```{.r .cell-code}
Sys.setenv(DVS_PROJECT = here::here(new_project), DVS_STORAGE = here::here(storage))
```
:::


# `dvs init`


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs init "$DVS_STORAGE"
cat dvs.toml
```


::: {.cell-output .cell-output-stdout}

```
DVS Initialized at "/Users/elea/Documents/a2ai_github/dvs2-demo/filed5023154044b_project"
compression = "zstd"

[backend]
path = "/Users/elea/Documents/a2ai_github/dvs2-demo/filed5021a8d478b_storage"
group = "staff"
```


:::
:::


# `dvs add`

Add a single file with a message:


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs add data/large/large_1.csv -m "add one large dataset"
```


::: {.cell-output .cell-output-stdout}

```
Added: data/large/large_1.csv [25.0 MB] --> saved [10.5 MB] as 3c77885f59933a6334a438d0a77d2adcd06873bed58a00fc9807fce3d13ed838
```


:::
:::


Add a directory of files via glob:


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs add --glob "data/small/*.csv" -m "add small corpus datasets"
```


::: {.cell-output .cell-output-stdout}

```
Added: data/small/small_1.csv [1024.0 KB] --> saved [427.8 KB] as e0fb0b7aac778f07ba37105d2e2a70d1cee429f50d77c3b0c9dd4ad4d2222937
Added: data/small/small_2.csv [1024.0 KB] --> saved [427.9 KB] as 1574af6b3e5cfd7fdba90c4f819fbd2bd128cd573c304588623fc09d49ae6b04
Added: data/small/small_3.csv [1024.0 KB] --> saved [428.1 KB] as 9d97b050e954474b51c5b3f06eafd07bc33366b9f3b09ea1211ac75c2704357a
```


:::
:::


Add 50 files at once:


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs add --glob "data/individual/individual_*.csv" -m "add individual datasets"
```


::: {.cell-output .cell-output-stdout}

```
Added: data/individual/individual_01.csv [3.0 MB] --> saved [1.3 MB] as 57856e362f74d4319cdb81f0454e205a91e7ad8c83e3442aee7da4c676902d53
Added: data/individual/individual_02.csv [3.0 MB] --> saved [1.3 MB] as 85ee4a308973f2ef5cda8d4a1a6228a4ff69e0f72de5c2dfd1aa8f9a409e2b5c
Added: data/individual/individual_03.csv [3.0 MB] --> saved [1.3 MB] as cd648605e42fddc1c08fc761b3683021e0be3a4578b0ec9e02e84e9645db8d58
Added: data/individual/individual_04.csv [3.0 MB] --> saved [1.3 MB] as 388c35ea1e0f0f55cd73c6d6e84ad7659b3954f271103b51bcc868f9f07d1aee
Added: data/individual/individual_05.csv [3.0 MB] --> saved [1.3 MB] as 0dbb9776c7188194995a8ddc0dca67a9814ef7fa165cc035518386c6e51cbb92
Added: data/individual/individual_06.csv [3.0 MB] --> saved [1.3 MB] as e3d9340328668ac4a61180c62664fa53726de78410ac7b90679b9f81cee2b852
Added: data/individual/individual_07.csv [3.0 MB] --> saved [1.3 MB] as e755c66eba55a05f0cb10a6c068f29a373de0baaed2649f0b8828ff302c65d61
Added: data/individual/individual_08.csv [3.0 MB] --> saved [1.3 MB] as 93cb8aaac5d09feba55d44274f96b3b67f81fd66fce959e86e6b5af80b670d61
Added: data/individual/individual_09.csv [3.0 MB] --> saved [1.3 MB] as 26af472b0caf28693778231ceacf48504b4c09d2cc877dd9c4a7f1a21144d72f
Added: data/individual/individual_10.csv [3.0 MB] --> saved [1.3 MB] as 804e10256f674fbb79860959dc612b3f73171c96871a6707278eaea594f9d470
Added: data/individual/individual_11.csv [3.0 MB] --> saved [1.3 MB] as bdd2150b27e4b6b90cba72e1a5e9e7fa0fd38e90702c0169393c86e2dc85691a
Added: data/individual/individual_12.csv [3.0 MB] --> saved [1.3 MB] as e47dda9fc7f57f5acaf284aed70e127bbc78ed1a67195936cbbcf4e6d1c321b2
Added: data/individual/individual_13.csv [3.0 MB] --> saved [1.3 MB] as 2aecd8dc9adb04d3777e23ac721bbc2828e599be8ad35af4b87400cd41148671
Added: data/individual/individual_14.csv [3.0 MB] --> saved [1.3 MB] as 31758fcb8655fd233cf99e0ab466f4a7d997b85a51ecfc804965aad4d3125d18
Added: data/individual/individual_15.csv [3.0 MB] --> saved [1.3 MB] as bc2c089b5bfd013e062b7cea8e22907983fb40e7824b8d309ec0dc7c46fdc6e4
Added: data/individual/individual_16.csv [3.0 MB] --> saved [1.3 MB] as 57216386358ca115c810f01903cce60423037feee2faf2d3a26032627ed7ca9d
Added: data/individual/individual_17.csv [3.0 MB] --> saved [1.3 MB] as 34fd92ee0ed3122e814c275ba2d4bcf83e749ea0a4fda462d56afbd0f62fea8a
Added: data/individual/individual_18.csv [3.0 MB] --> saved [1.3 MB] as 71f792a1264e4704e7f53e99f741d4baa46f0fa3ef864a83ada590a954da34e9
Added: data/individual/individual_19.csv [3.0 MB] --> saved [1.3 MB] as 443b0aad3af092b510e3624d737d71f60cf771b5bf387c1f7126e0cd712cc8cf
Added: data/individual/individual_20.csv [3.0 MB] --> saved [1.3 MB] as df09093a115feea9827440955103488d2c73bcbaf8a56f7ff79842b19348645f
Added: data/individual/individual_21.csv [3.0 MB] --> saved [1.3 MB] as 2f05406da9b7905880f2f6230ca5883637820d1abecbdd12190696242e4a3077
Added: data/individual/individual_22.csv [3.0 MB] --> saved [1.3 MB] as 9dec1c7c19612c726f715faef5d6057b9e4dde7d5c20d70b056cbe6f2bd7c91c
Added: data/individual/individual_23.csv [3.0 MB] --> saved [1.3 MB] as 1fe13d85d36ee596cf9bc781919808458b2cd00b49bcb342e8c5db5cce915c62
Added: data/individual/individual_24.csv [3.0 MB] --> saved [1.3 MB] as c2332280ea27acd678ed478ae719549e643820c193e35a4362ffc57d02a211a8
Added: data/individual/individual_25.csv [3.0 MB] --> saved [1.3 MB] as 8d0524a0aaca6787bebacce86072df4b16930660998654c202a0235888512d3e
Added: data/individual/individual_26.csv [3.0 MB] --> saved [1.3 MB] as 48dff588f909e9720dff2a675afef20a44add218cb55e7883736326938917b73
Added: data/individual/individual_27.csv [3.0 MB] --> saved [1.3 MB] as 77d27c2060525b39adcfd943235b96f0c0158e2c6eda8ef3d007f23b0a9b29b0
Added: data/individual/individual_28.csv [3.0 MB] --> saved [1.3 MB] as 5b8ed16fac2af119cd417960ca8ef817507f2a74352cd10b4809fe77ad0f9759
Added: data/individual/individual_29.csv [3.0 MB] --> saved [1.3 MB] as 49d367f13b24c611561d1dae7d9860390b8239689a7a7ffac393b3eaf8907be7
Added: data/individual/individual_30.csv [3.0 MB] --> saved [1.3 MB] as 62058b6bf8fb1c380f4fded49604df6fa144c84e49775dd879f084124d6ea8a1
Added: data/individual/individual_31.csv [3.0 MB] --> saved [1.3 MB] as 7cf60960fa5161e67262be59e546dc42cada90c99a6d9c767cc9eda8530a282d
Added: data/individual/individual_32.csv [3.0 MB] --> saved [1.3 MB] as ec1caea68524d4fb96a4ec8e9127229bc3c2e23d669be92f5add767c59889ab8
Added: data/individual/individual_33.csv [3.0 MB] --> saved [1.3 MB] as d325a9ede2e5b2509fd4893dfdb350e4fd653e9a9e4fb6b2605f72ae315659c8
Added: data/individual/individual_34.csv [3.0 MB] --> saved [1.3 MB] as adebf3682c67ecf60ed348fa6eb031c786496275e9b8a47082e4839cf0d02a4d
Added: data/individual/individual_35.csv [3.0 MB] --> saved [1.3 MB] as e39164399b7147c57fc78e073fff926a23d1165b4436a5c71f70941d8acb4a58
Added: data/individual/individual_36.csv [3.0 MB] --> saved [1.3 MB] as 3e5fb7f5dab7515086635a93328785b2b703922b6b7499cf3de2d6f4e954e98c
Added: data/individual/individual_37.csv [3.0 MB] --> saved [1.3 MB] as 456eaf1e596ccf2e8cc982c9ca3192f996efa0638d9dbd96a03f90fc35a34c51
Added: data/individual/individual_38.csv [3.0 MB] --> saved [1.3 MB] as f3cd94c8247890360ef1b61bb7cdc49f6463c39c08b7f0e0c62ea9dec575b0fa
Added: data/individual/individual_39.csv [3.0 MB] --> saved [1.3 MB] as 88ba43b3a95a505c9605335a03f0a07d89dbb0b0fd1824d2e50f109ec8267468
Added: data/individual/individual_40.csv [3.0 MB] --> saved [1.3 MB] as 9649f8ae18c09b20768f4f017ab983c75b90b3e4e5935d1308e935f2ac4e9b4b
Added: data/individual/individual_41.csv [3.0 MB] --> saved [1.3 MB] as 93ca349f3eb8b7bae487fc3c871b38b702ca8774e1e47e291dbf4deef768188f
Added: data/individual/individual_42.csv [3.0 MB] --> saved [1.3 MB] as a023d54af885922c1f2e65efa78cd32d6cef07a3a31a2edb7cbe67e862964ac7
Added: data/individual/individual_43.csv [3.0 MB] --> saved [1.3 MB] as 78ffc0ed3e6b077436ef61504935dd65137caa45893173527f53f14dd54073c9
Added: data/individual/individual_44.csv [3.0 MB] --> saved [1.3 MB] as 1d884347c3d0433a2833ef586c83afebb2bc30cdea12d323e80f25526aacaae4
Added: data/individual/individual_45.csv [3.0 MB] --> saved [1.3 MB] as 4bbae46269b915721b8a461f9138afaa04dbe69c2a6be89ccbd3d26abc09f869
Added: data/individual/individual_46.csv [3.0 MB] --> saved [1.3 MB] as 26bfcc219ab65cd79ce696d013ae6148055d01c187e2c31570452315e441819f
Added: data/individual/individual_47.csv [3.0 MB] --> saved [1.3 MB] as 819f86f6a3bdc6ce6d08f3529690c674e01d89dbfcd6e5491630db4ea2add30a
Added: data/individual/individual_48.csv [3.0 MB] --> saved [1.3 MB] as 7d62b45f3c50dcaf1f3143a9c67d5a1606b58660359405f533483713157d3ce2
Added: data/individual/individual_49.csv [3.0 MB] --> saved [1.3 MB] as d855539255e6bcef2bdb7b3be9c727312db4c8eb6229851bb2ddd71667bde6e3
Added: data/individual/individual_50.csv [3.0 MB] --> saved [1.3 MB] as b05327be23b5f7172df2b5c2a19ba2a214b6d8c01d87f6231563a2b2dd9f464b
```


:::
:::


## `--dry-run`

Preview what *would* be added without writing anything:


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs add --glob "data/small/*.csv" --dry-run
```
:::


## Meta file

Each tracked file gets a `.dvs` meta file that records its hash:


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
cat .dvs/data/large/large_1.csv.dvs
```


::: {.cell-output .cell-output-stdout}

```
{
  "hashes": {
    "blake3": "3c77885f59933a6334a438d0a77d2adcd06873bed58a00fc9807fce3d13ed838"
  },
  "size": 26214390,
  "created_by": "elea",
  "add_time": "2026-04-24T12:58:56.091032Z",
  "compression": "zstd",
  "message": "add one large dataset"
}
```


:::
:::


# `dvs status`

Default, show all tracked files:


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs status
```


::: {.cell-output .cell-output-stdout}

```
+-----------------------------------+---------+-----------+
| path                              | status  | size      |
+-----------------------------------+---------+-----------+
| data/individual/individual_01.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_02.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_03.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_04.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_05.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_06.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_07.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_08.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_09.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_10.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_11.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_12.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_13.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_14.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_15.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_16.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_17.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_18.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_19.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_20.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_21.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_22.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_23.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_24.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_25.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_26.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_27.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_28.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_29.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_30.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_31.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_32.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_33.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_34.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_35.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_36.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_37.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_38.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_39.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_40.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_41.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_42.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_43.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_44.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_45.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_46.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_47.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_48.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_49.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_50.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/large/large_1.csv            | current |   25.0 MB |
+-----------------------------------+---------+-----------+
| data/small/small_1.csv            | current | 1024.0 KB |
+-----------------------------------+---------+-----------+
| data/small/small_2.csv            | current | 1024.0 KB |
+-----------------------------------+---------+-----------+
| data/small/small_3.csv            | current | 1024.0 KB |
+-----------------------------------+---------+-----------+
```


:::
:::


Filter by status:


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs status --current
```


::: {.cell-output .cell-output-stdout}

```
+-----------------------------------+---------+-----------+
| path                              | status  | size      |
+-----------------------------------+---------+-----------+
| data/individual/individual_01.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_02.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_03.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_04.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_05.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_06.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_07.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_08.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_09.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_10.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_11.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_12.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_13.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_14.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_15.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_16.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_17.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_18.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_19.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_20.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_21.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_22.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_23.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_24.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_25.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_26.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_27.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_28.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_29.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_30.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_31.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_32.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_33.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_34.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_35.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_36.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_37.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_38.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_39.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_40.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_41.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_42.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_43.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_44.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_45.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_46.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_47.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_48.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_49.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/individual/individual_50.csv | current |    3.0 MB |
+-----------------------------------+---------+-----------+
| data/large/large_1.csv            | current |   25.0 MB |
+-----------------------------------+---------+-----------+
| data/small/small_1.csv            | current | 1024.0 KB |
+-----------------------------------+---------+-----------+
| data/small/small_2.csv            | current | 1024.0 KB |
+-----------------------------------+---------+-----------+
| data/small/small_3.csv            | current | 1024.0 KB |
+-----------------------------------+---------+-----------+
```


:::
:::


Show extended metadata columns with `--with-metadata`:


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs status --with-metadata
```


::: {.cell-output .cell-output-stdout}

```
+-----------------------------------+---------+-----------+------------------------------------------------------------------+------------+-----------------------------+-------------+---------------------------+
| path                              | status  | size      | hash                                                             | created_by | add_time                    | compression | message                   |
+-----------------------------------+---------+-----------+------------------------------------------------------------------+------------+-----------------------------+-------------+---------------------------+
| data/individual/individual_01.csv | current |    3.0 MB | 57856e362f74d4319cdb81f0454e205a91e7ad8c83e3442aee7da4c676902d53 | elea       | 2026-04-24T12:58:56.308559Z | zstd        | add individual datasets   |
+-----------------------------------+---------+-----------+------------------------------------------------------------------+------------+-----------------------------+-------------+---------------------------+
| data/individual/individual_02.csv | current |    3.0 MB | 85ee4a308973f2ef5cda8d4a1a6228a4ff69e0f72de5c2dfd1aa8f9a409e2b5c | elea       | 2026-04-24T12:58:56.273187Z | zstd        | add individual datasets   |
+-----------------------------------+---------+-----------+------------------------------------------------------------------+------------+-----------------------------+-------------+---------------------------+
| data/individual/individual_03.csv | current |    3.0 MB | cd648605e42fddc1c08fc761b3683021e0be3a4578b0ec9e02e84e9645db8d58 | elea       | 2026-04-24T12:58:56.342198Z | zstd        | add individual datasets   |
+-----------------------------------+---------+-----------+------------------------------------------------------------------+------------+-----------------------------+-------------+---------------------------+
| data/individual/individual_04.csv | current |    3.0 MB | 388c35ea1e0f0f55cd73c6d6e84ad7659b3954f271103b51bcc868f9f07d1aee | elea       | 2026-04-24T12:58:56.273132Z | zstd        | add individual datasets   |
+-----------------------------------+---------+-----------+------------------------------------------------------------------+------------+-----------------------------+-------------+---------------------------+
| data/individual/individual_05.csv | current |    3.0 MB | 0dbb9776c7188194995a8ddc0dca67a9814ef7fa165cc035518386c6e51cbb92 | elea       | 2026-04-24T12:58:56.33824Z  | zstd        | add individual datasets   |
+-----------------------------------+---------+-----------+------------------------------------------------------------------+------------+-----------------------------+-------------+---------------------------+
| data/individual/individual_06.csv | current |    3.0 MB | e3d9340328668ac4a61180c62664fa53726de78410ac7b90679b9f81cee2b852 | elea       | 2026-04-24T12:58:56.346531Z | zstd        | add individual datasets   |
+-----------------------------------+---------+-----------+------------------------------------------------------------------+------------+-----------------------------+-------------+---------------------------+
| data/individual/individual_07.csv | current |    3.0 MB | e755c66eba55a05f0cb10a6c068f29a373de0baaed2649f0b8828ff302c65d61 | elea       | 2026-04-24T12:58:56.272909Z | zstd        | add individual datasets   |
+-----------------------------------+---------+-----------+------------------------------------------------------------------+------------+-----------------------------+-------------+---------------------------+
| data/individual/individual_08.csv | current |    3.0 MB | 93cb8aaac5d09feba55d44274f96b3b67f81fd66fce959e86e6b5af80b670d61 | elea       | 2026-04-24T12:58:56.303418Z | zstd        | add individual datasets   |
+-----------------------------------+---------+-----------+------------------------------------------------------------------+------------+-----------------------------+-------------+---------------------------+
| data/individual/individual_09.csv | current |    3.0 MB | 26af472b0caf28693778231ceacf48504b4c09d2cc877dd9c4a7f1a21144d72f | elea       | 2026-04-24T12:58:56.343272Z | zstd        | add individual datasets   |
+-----------------------------------+---------+-----------+------------------------------------------------------------------+------------+-----------------------------+-------------+---------------------------+
| data/individual/individual_10.csv | current |    3.0 MB | 804e10256f674fbb79860959dc612b3f73171c96871a6707278eaea594f9d470 | elea       | 2026-04-24T12:58:56.310045Z | zstd        | add individual datasets   |
+-----------------------------------+---------+-----------+------------------------------------------------------------------+------------+-----------------------------+-------------+---------------------------+
| data/individual/individual_11.csv | current |    3.0 MB | bdd2150b27e4b6b90cba72e1a5e9e7fa0fd38e90702c0169393c86e2dc85691a | elea       | 2026-04-24T12:58:56.338659Z | zstd        | add individual datasets   |
+-----------------------------------+---------+-----------+------------------------------------------------------------------+------------+-----------------------------+-------------+---------------------------+
| data/individual/individual_12.csv | current |    3.0 MB | e47dda9fc7f57f5acaf284aed70e127bbc78ed1a67195936cbbcf4e6d1c321b2 | elea       | 2026-04-24T12:58:56.272989Z | zstd        | add individual datasets   |
+-----------------------------------+---------+-----------+------------------------------------------------------------------+------------+-----------------------------+-------------+---------------------------+
| data/individual/individual_13.csv | current |    3.0 MB | 2aecd8dc9adb04d3777e23ac721bbc2828e599be8ad35af4b87400cd41148671 | elea       | 2026-04-24T12:58:56.27383Z  | zstd        | add individual datasets   |
+-----------------------------------+---------+-----------+------------------------------------------------------------------+------------+-----------------------------+-------------+---------------------------+
| data/individual/individual_14.csv | current |    3.0 MB | 31758fcb8655fd233cf99e0ab466f4a7d997b85a51ecfc804965aad4d3125d18 | elea       | 2026-04-24T12:58:56.308451Z | zstd        | add individual datasets   |
+-----------------------------------+---------+-----------+------------------------------------------------------------------+------------+-----------------------------+-------------+---------------------------+
| data/individual/individual_15.csv | current |    3.0 MB | bc2c089b5bfd013e062b7cea8e22907983fb40e7824b8d309ec0dc7c46fdc6e4 | elea       | 2026-04-24T12:58:56.344647Z | zstd        | add individual datasets   |
+-----------------------------------+---------+-----------+------------------------------------------------------------------+------------+-----------------------------+-------------+---------------------------+
| data/individual/individual_16.csv | current |    3.0 MB | 57216386358ca115c810f01903cce60423037feee2faf2d3a26032627ed7ca9d | elea       | 2026-04-24T12:58:56.312362Z | zstd        | add individual datasets   |
+-----------------------------------+---------+-----------+------------------------------------------------------------------+------------+-----------------------------+-------------+---------------------------+
| data/individual/individual_17.csv | current |    3.0 MB | 34fd92ee0ed3122e814c275ba2d4bcf83e749ea0a4fda462d56afbd0f62fea8a | elea       | 2026-04-24T12:58:56.307659Z | zstd        | add individual datasets   |
+-----------------------------------+---------+-----------+------------------------------------------------------------------+------------+-----------------------------+-------------+---------------------------+
| data/individual/individual_18.csv | current |    3.0 MB | 71f792a1264e4704e7f53e99f741d4baa46f0fa3ef864a83ada590a954da34e9 | elea       | 2026-04-24T12:58:56.306756Z | zstd        | add individual datasets   |
+-----------------------------------+---------+-----------+------------------------------------------------------------------+------------+-----------------------------+-------------+---------------------------+
| data/individual/individual_19.csv | current |    3.0 MB | 443b0aad3af092b510e3624d737d71f60cf771b5bf387c1f7126e0cd712cc8cf | elea       | 2026-04-24T12:58:56.309811Z | zstd        | add individual datasets   |
+-----------------------------------+---------+-----------+------------------------------------------------------------------+------------+-----------------------------+-------------+---------------------------+
| data/individual/individual_20.csv | current |    3.0 MB | df09093a115feea9827440955103488d2c73bcbaf8a56f7ff79842b19348645f | elea       | 2026-04-24T12:58:56.304558Z | zstd        | add individual datasets   |
+-----------------------------------+---------+-----------+------------------------------------------------------------------+------------+-----------------------------+-------------+---------------------------+
| data/individual/individual_21.csv | current |    3.0 MB | 2f05406da9b7905880f2f6230ca5883637820d1abecbdd12190696242e4a3077 | elea       | 2026-04-24T12:58:56.275126Z | zstd        | add individual datasets   |
+-----------------------------------+---------+-----------+------------------------------------------------------------------+------------+-----------------------------+-------------+---------------------------+
| data/individual/individual_22.csv | current |    3.0 MB | 9dec1c7c19612c726f715faef5d6057b9e4dde7d5c20d70b056cbe6f2bd7c91c | elea       | 2026-04-24T12:58:56.331519Z | zstd        | add individual datasets   |
+-----------------------------------+---------+-----------+------------------------------------------------------------------+------------+-----------------------------+-------------+---------------------------+
| data/individual/individual_23.csv | current |    3.0 MB | 1fe13d85d36ee596cf9bc781919808458b2cd00b49bcb342e8c5db5cce915c62 | elea       | 2026-04-24T12:58:56.273379Z | zstd        | add individual datasets   |
+-----------------------------------+---------+-----------+------------------------------------------------------------------+------------+-----------------------------+-------------+---------------------------+
| data/individual/individual_24.csv | current |    3.0 MB | c2332280ea27acd678ed478ae719549e643820c193e35a4362ffc57d02a211a8 | elea       | 2026-04-24T12:58:56.27312Z  | zstd        | add individual datasets   |
+-----------------------------------+---------+-----------+------------------------------------------------------------------+------------+-----------------------------+-------------+---------------------------+
| data/individual/individual_25.csv | current |    3.0 MB | 8d0524a0aaca6787bebacce86072df4b16930660998654c202a0235888512d3e | elea       | 2026-04-24T12:58:56.310166Z | zstd        | add individual datasets   |
+-----------------------------------+---------+-----------+------------------------------------------------------------------+------------+-----------------------------+-------------+---------------------------+
| data/individual/individual_26.csv | current |    3.0 MB | 48dff588f909e9720dff2a675afef20a44add218cb55e7883736326938917b73 | elea       | 2026-04-24T12:58:56.273044Z | zstd        | add individual datasets   |
+-----------------------------------+---------+-----------+------------------------------------------------------------------+------------+-----------------------------+-------------+---------------------------+
| data/individual/individual_27.csv | current |    3.0 MB | 77d27c2060525b39adcfd943235b96f0c0158e2c6eda8ef3d007f23b0a9b29b0 | elea       | 2026-04-24T12:58:56.273111Z | zstd        | add individual datasets   |
+-----------------------------------+---------+-----------+------------------------------------------------------------------+------------+-----------------------------+-------------+---------------------------+
| data/individual/individual_28.csv | current |    3.0 MB | 5b8ed16fac2af119cd417960ca8ef817507f2a74352cd10b4809fe77ad0f9759 | elea       | 2026-04-24T12:58:56.341899Z | zstd        | add individual datasets   |
+-----------------------------------+---------+-----------+------------------------------------------------------------------+------------+-----------------------------+-------------+---------------------------+
| data/individual/individual_29.csv | current |    3.0 MB | 49d367f13b24c611561d1dae7d9860390b8239689a7a7ffac393b3eaf8907be7 | elea       | 2026-04-24T12:58:56.305898Z | zstd        | add individual datasets   |
+-----------------------------------+---------+-----------+------------------------------------------------------------------+------------+-----------------------------+-------------+---------------------------+
| data/individual/individual_30.csv | current |    3.0 MB | 62058b6bf8fb1c380f4fded49604df6fa144c84e49775dd879f084124d6ea8a1 | elea       | 2026-04-24T12:58:56.304015Z | zstd        | add individual datasets   |
+-----------------------------------+---------+-----------+------------------------------------------------------------------+------------+-----------------------------+-------------+---------------------------+
| data/individual/individual_31.csv | current |    3.0 MB | 7cf60960fa5161e67262be59e546dc42cada90c99a6d9c767cc9eda8530a282d | elea       | 2026-04-24T12:58:56.337074Z | zstd        | add individual datasets   |
+-----------------------------------+---------+-----------+------------------------------------------------------------------+------------+-----------------------------+-------------+---------------------------+
| data/individual/individual_32.csv | current |    3.0 MB | ec1caea68524d4fb96a4ec8e9127229bc3c2e23d669be92f5add767c59889ab8 | elea       | 2026-04-24T12:58:56.307132Z | zstd        | add individual datasets   |
+-----------------------------------+---------+-----------+------------------------------------------------------------------+------------+-----------------------------+-------------+---------------------------+
| data/individual/individual_33.csv | current |    3.0 MB | d325a9ede2e5b2509fd4893dfdb350e4fd653e9a9e4fb6b2605f72ae315659c8 | elea       | 2026-04-24T12:58:56.348244Z | zstd        | add individual datasets   |
+-----------------------------------+---------+-----------+------------------------------------------------------------------+------------+-----------------------------+-------------+---------------------------+
| data/individual/individual_34.csv | current |    3.0 MB | adebf3682c67ecf60ed348fa6eb031c786496275e9b8a47082e4839cf0d02a4d | elea       | 2026-04-24T12:58:56.337378Z | zstd        | add individual datasets   |
+-----------------------------------+---------+-----------+------------------------------------------------------------------+------------+-----------------------------+-------------+---------------------------+
| data/individual/individual_35.csv | current |    3.0 MB | e39164399b7147c57fc78e073fff926a23d1165b4436a5c71f70941d8acb4a58 | elea       | 2026-04-24T12:58:56.340737Z | zstd        | add individual datasets   |
+-----------------------------------+---------+-----------+------------------------------------------------------------------+------------+-----------------------------+-------------+---------------------------+
| data/individual/individual_36.csv | current |    3.0 MB | 3e5fb7f5dab7515086635a93328785b2b703922b6b7499cf3de2d6f4e954e98c | elea       | 2026-04-24T12:58:56.272889Z | zstd        | add individual datasets   |
+-----------------------------------+---------+-----------+------------------------------------------------------------------+------------+-----------------------------+-------------+---------------------------+
| data/individual/individual_37.csv | current |    3.0 MB | 456eaf1e596ccf2e8cc982c9ca3192f996efa0638d9dbd96a03f90fc35a34c51 | elea       | 2026-04-24T12:58:56.313033Z | zstd        | add individual datasets   |
+-----------------------------------+---------+-----------+------------------------------------------------------------------+------------+-----------------------------+-------------+---------------------------+
| data/individual/individual_38.csv | current |    3.0 MB | f3cd94c8247890360ef1b61bb7cdc49f6463c39c08b7f0e0c62ea9dec575b0fa | elea       | 2026-04-24T12:58:56.274617Z | zstd        | add individual datasets   |
+-----------------------------------+---------+-----------+------------------------------------------------------------------+------------+-----------------------------+-------------+---------------------------+
| data/individual/individual_39.csv | current |    3.0 MB | 88ba43b3a95a505c9605335a03f0a07d89dbb0b0fd1824d2e50f109ec8267468 | elea       | 2026-04-24T12:58:56.313834Z | zstd        | add individual datasets   |
+-----------------------------------+---------+-----------+------------------------------------------------------------------+------------+-----------------------------+-------------+---------------------------+
| data/individual/individual_40.csv | current |    3.0 MB | 9649f8ae18c09b20768f4f017ab983c75b90b3e4e5935d1308e935f2ac4e9b4b | elea       | 2026-04-24T12:58:56.27309Z  | zstd        | add individual datasets   |
+-----------------------------------+---------+-----------+------------------------------------------------------------------+------------+-----------------------------+-------------+---------------------------+
| data/individual/individual_41.csv | current |    3.0 MB | 93ca349f3eb8b7bae487fc3c871b38b702ca8774e1e47e291dbf4deef768188f | elea       | 2026-04-24T12:58:56.333821Z | zstd        | add individual datasets   |
+-----------------------------------+---------+-----------+------------------------------------------------------------------+------------+-----------------------------+-------------+---------------------------+
| data/individual/individual_42.csv | current |    3.0 MB | a023d54af885922c1f2e65efa78cd32d6cef07a3a31a2edb7cbe67e862964ac7 | elea       | 2026-04-24T12:58:56.273287Z | zstd        | add individual datasets   |
+-----------------------------------+---------+-----------+------------------------------------------------------------------+------------+-----------------------------+-------------+---------------------------+
| data/individual/individual_43.csv | current |    3.0 MB | 78ffc0ed3e6b077436ef61504935dd65137caa45893173527f53f14dd54073c9 | elea       | 2026-04-24T12:58:56.368507Z | zstd        | add individual datasets   |
+-----------------------------------+---------+-----------+------------------------------------------------------------------+------------+-----------------------------+-------------+---------------------------+
| data/individual/individual_44.csv | current |    3.0 MB | 1d884347c3d0433a2833ef586c83afebb2bc30cdea12d323e80f25526aacaae4 | elea       | 2026-04-24T12:58:56.365225Z | zstd        | add individual datasets   |
+-----------------------------------+---------+-----------+------------------------------------------------------------------+------------+-----------------------------+-------------+---------------------------+
| data/individual/individual_45.csv | current |    3.0 MB | 4bbae46269b915721b8a461f9138afaa04dbe69c2a6be89ccbd3d26abc09f869 | elea       | 2026-04-24T12:58:56.351101Z | zstd        | add individual datasets   |
+-----------------------------------+---------+-----------+------------------------------------------------------------------+------------+-----------------------------+-------------+---------------------------+
| data/individual/individual_46.csv | current |    3.0 MB | 26bfcc219ab65cd79ce696d013ae6148055d01c187e2c31570452315e441819f | elea       | 2026-04-24T12:58:56.273639Z | zstd        | add individual datasets   |
+-----------------------------------+---------+-----------+------------------------------------------------------------------+------------+-----------------------------+-------------+---------------------------+
| data/individual/individual_47.csv | current |    3.0 MB | 819f86f6a3bdc6ce6d08f3529690c674e01d89dbfcd6e5491630db4ea2add30a | elea       | 2026-04-24T12:58:56.338774Z | zstd        | add individual datasets   |
+-----------------------------------+---------+-----------+------------------------------------------------------------------+------------+-----------------------------+-------------+---------------------------+
| data/individual/individual_48.csv | current |    3.0 MB | 7d62b45f3c50dcaf1f3143a9c67d5a1606b58660359405f533483713157d3ce2 | elea       | 2026-04-24T12:58:56.337944Z | zstd        | add individual datasets   |
+-----------------------------------+---------+-----------+------------------------------------------------------------------+------------+-----------------------------+-------------+---------------------------+
| data/individual/individual_49.csv | current |    3.0 MB | d855539255e6bcef2bdb7b3be9c727312db4c8eb6229851bb2ddd71667bde6e3 | elea       | 2026-04-24T12:58:56.272944Z | zstd        | add individual datasets   |
+-----------------------------------+---------+-----------+------------------------------------------------------------------+------------+-----------------------------+-------------+---------------------------+
| data/individual/individual_50.csv | current |    3.0 MB | b05327be23b5f7172df2b5c2a19ba2a214b6d8c01d87f6231563a2b2dd9f464b | elea       | 2026-04-24T12:58:56.306359Z | zstd        | add individual datasets   |
+-----------------------------------+---------+-----------+------------------------------------------------------------------+------------+-----------------------------+-------------+---------------------------+
| data/large/large_1.csv            | current |   25.0 MB | 3c77885f59933a6334a438d0a77d2adcd06873bed58a00fc9807fce3d13ed838 | elea       | 2026-04-24T12:58:56.091032Z | zstd        | add one large dataset     |
+-----------------------------------+---------+-----------+------------------------------------------------------------------+------------+-----------------------------+-------------+---------------------------+
| data/small/small_1.csv            | current | 1024.0 KB | e0fb0b7aac778f07ba37105d2e2a70d1cee429f50d77c3b0c9dd4ad4d2222937 | elea       | 2026-04-24T12:58:56.246093Z | zstd        | add small corpus datasets |
+-----------------------------------+---------+-----------+------------------------------------------------------------------+------------+-----------------------------+-------------+---------------------------+
| data/small/small_2.csv            | current | 1024.0 KB | 1574af6b3e5cfd7fdba90c4f819fbd2bd128cd573c304588623fc09d49ae6b04 | elea       | 2026-04-24T12:58:56.246128Z | zstd        | add small corpus datasets |
+-----------------------------------+---------+-----------+------------------------------------------------------------------+------------+-----------------------------+-------------+---------------------------+
| data/small/small_3.csv            | current | 1024.0 KB | 9d97b050e954474b51c5b3f06eafd07bc33366b9f3b09ea1211ac75c2704357a | elea       | 2026-04-24T12:58:56.246094Z | zstd        | add small corpus datasets |
+-----------------------------------+---------+-----------+------------------------------------------------------------------+------------+-----------------------------+-------------+---------------------------+
```


:::
:::


In the R package these metadata columns (`hash`, `created_by`, `add_time`,
`compression`, `message`) are returned by default. They are already computed
when resolving status, so `dvs_status()` surfaces them without an extra flag.

Delete a few files to produce `absent` entries:


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
rm data/individual/individual_04.csv data/individual/individual_08.csv data/individual/individual_15.csv
dvs status --absent
```


::: {.cell-output .cell-output-stdout}

```
+-----------------------------------+--------+--------+
| path                              | status | size   |
+-----------------------------------+--------+--------+
| data/individual/individual_04.csv | absent | 3.0 MB |
+-----------------------------------+--------+--------+
| data/individual/individual_08.csv | absent | 3.0 MB |
+-----------------------------------+--------+--------+
| data/individual/individual_15.csv | absent | 3.0 MB |
+-----------------------------------+--------+--------+
```


:::
:::


Modify a file to produce an `unsynced` entry:


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
echo "99,0,0,0,0,0" >> data/large/large_1.csv
dvs status --unsynced
```


::: {.cell-output .cell-output-stdout}

```
+------------------------+----------+---------+
| path                   | status   | size    |
+------------------------+----------+---------+
| data/large/large_1.csv | unsynced | 25.0 MB |
+------------------------+----------+---------+
```


:::
:::


## JSON output

Every command accepts `--json` for machine-readable output:


```{.r .cell-code}
setwd(here::here(new_project))
out <- system2("dvs", c("status", "--absent", "--json"), stdout = TRUE)
cat("```json\n")
```

```json

```{.r .cell-code}
cat(jsonlite::toJSON(jsonlite::fromJSON(paste(out, collapse = "\n"),
                                        simplifyVector = FALSE),
                     pretty = TRUE, auto_unbox = TRUE))
```

[
  {
    "path": "data/individual/individual_04.csv",
    "status": "absent",
    "metadata": {
      "hashes": {
        "blake3": "388c35ea1e0f0f55cd73c6d6e84ad7659b3954f271103b51bcc868f9f07d1aee"
      },
      "size": 3145709,
      "created_by": "elea",
      "add_time": "2026-04-24T12:58:56.273132Z",
      "compression": "zstd",
      "message": "add individual datasets"
    }
  },
  {
    "path": "data/individual/individual_08.csv",
    "status": "absent",
    "metadata": {
      "hashes": {
        "blake3": "93cb8aaac5d09feba55d44274f96b3b67f81fd66fce959e86e6b5af80b670d61"
      },
      "size": 3145716,
      "created_by": "elea",
      "add_time": "2026-04-24T12:58:56.303418Z",
      "compression": "zstd",
      "message": "add individual datasets"
    }
  },
  {
    "path": "data/individual/individual_15.csv",
    "status": "absent",
    "metadata": {
      "hashes": {
        "blake3": "bc2c089b5bfd013e062b7cea8e22907983fb40e7824b8d309ec0dc7c46fdc6e4"
      },
      "size": 3145693,
      "created_by": "elea",
      "add_time": "2026-04-24T12:58:56.344647Z",
      "compression": "zstd",
      "message": "add individual datasets"
    }
  }
]

```{.r .cell-code}
cat("\n```\n")
```

```

# `dvs get`

Restore absent files by glob:


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs get --glob "data/individual/individual_*.csv"
dvs status --absent
```


::: {.cell-output .cell-output-stdout}

```
data/individual/individual_04.csv [3.0 MB]
data/individual/individual_08.csv [3.0 MB]
data/individual/individual_15.csv [3.0 MB]
Total: 3 files, 9.0 MB
No tracked files matching the filter
```


:::
:::


## `--dry-run`


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
rm data/individual/individual_01.csv
dvs get --glob "data/individual/individual_*.csv" --dry-run
```


::: {.cell-output .cell-output-stdout}

```
data/individual/individual_01.csv [3.0 MB]
Total: 1 files, 3.0 MB
```


:::
:::


# `--threads`

Override the auto-detected thread count for any command:


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs status --threads 2
```


::: {.cell-output .cell-output-stdout}

```
+-----------------------------------+----------+-----------+
| path                              | status   | size      |
+-----------------------------------+----------+-----------+
| data/individual/individual_01.csv | absent   |    3.0 MB |
+-----------------------------------+----------+-----------+
| data/individual/individual_02.csv | current  |    3.0 MB |
+-----------------------------------+----------+-----------+
| data/individual/individual_03.csv | current  |    3.0 MB |
+-----------------------------------+----------+-----------+
| data/individual/individual_04.csv | current  |    3.0 MB |
+-----------------------------------+----------+-----------+
| data/individual/individual_05.csv | current  |    3.0 MB |
+-----------------------------------+----------+-----------+
| data/individual/individual_06.csv | current  |    3.0 MB |
+-----------------------------------+----------+-----------+
| data/individual/individual_07.csv | current  |    3.0 MB |
+-----------------------------------+----------+-----------+
| data/individual/individual_08.csv | current  |    3.0 MB |
+-----------------------------------+----------+-----------+
| data/individual/individual_09.csv | current  |    3.0 MB |
+-----------------------------------+----------+-----------+
| data/individual/individual_10.csv | current  |    3.0 MB |
+-----------------------------------+----------+-----------+
| data/individual/individual_11.csv | current  |    3.0 MB |
+-----------------------------------+----------+-----------+
| data/individual/individual_12.csv | current  |    3.0 MB |
+-----------------------------------+----------+-----------+
| data/individual/individual_13.csv | current  |    3.0 MB |
+-----------------------------------+----------+-----------+
| data/individual/individual_14.csv | current  |    3.0 MB |
+-----------------------------------+----------+-----------+
| data/individual/individual_15.csv | current  |    3.0 MB |
+-----------------------------------+----------+-----------+
| data/individual/individual_16.csv | current  |    3.0 MB |
+-----------------------------------+----------+-----------+
| data/individual/individual_17.csv | current  |    3.0 MB |
+-----------------------------------+----------+-----------+
| data/individual/individual_18.csv | current  |    3.0 MB |
+-----------------------------------+----------+-----------+
| data/individual/individual_19.csv | current  |    3.0 MB |
+-----------------------------------+----------+-----------+
| data/individual/individual_20.csv | current  |    3.0 MB |
+-----------------------------------+----------+-----------+
| data/individual/individual_21.csv | current  |    3.0 MB |
+-----------------------------------+----------+-----------+
| data/individual/individual_22.csv | current  |    3.0 MB |
+-----------------------------------+----------+-----------+
| data/individual/individual_23.csv | current  |    3.0 MB |
+-----------------------------------+----------+-----------+
| data/individual/individual_24.csv | current  |    3.0 MB |
+-----------------------------------+----------+-----------+
| data/individual/individual_25.csv | current  |    3.0 MB |
+-----------------------------------+----------+-----------+
| data/individual/individual_26.csv | current  |    3.0 MB |
+-----------------------------------+----------+-----------+
| data/individual/individual_27.csv | current  |    3.0 MB |
+-----------------------------------+----------+-----------+
| data/individual/individual_28.csv | current  |    3.0 MB |
+-----------------------------------+----------+-----------+
| data/individual/individual_29.csv | current  |    3.0 MB |
+-----------------------------------+----------+-----------+
| data/individual/individual_30.csv | current  |    3.0 MB |
+-----------------------------------+----------+-----------+
| data/individual/individual_31.csv | current  |    3.0 MB |
+-----------------------------------+----------+-----------+
| data/individual/individual_32.csv | current  |    3.0 MB |
+-----------------------------------+----------+-----------+
| data/individual/individual_33.csv | current  |    3.0 MB |
+-----------------------------------+----------+-----------+
| data/individual/individual_34.csv | current  |    3.0 MB |
+-----------------------------------+----------+-----------+
| data/individual/individual_35.csv | current  |    3.0 MB |
+-----------------------------------+----------+-----------+
| data/individual/individual_36.csv | current  |    3.0 MB |
+-----------------------------------+----------+-----------+
| data/individual/individual_37.csv | current  |    3.0 MB |
+-----------------------------------+----------+-----------+
| data/individual/individual_38.csv | current  |    3.0 MB |
+-----------------------------------+----------+-----------+
| data/individual/individual_39.csv | current  |    3.0 MB |
+-----------------------------------+----------+-----------+
| data/individual/individual_40.csv | current  |    3.0 MB |
+-----------------------------------+----------+-----------+
| data/individual/individual_41.csv | current  |    3.0 MB |
+-----------------------------------+----------+-----------+
| data/individual/individual_42.csv | current  |    3.0 MB |
+-----------------------------------+----------+-----------+
| data/individual/individual_43.csv | current  |    3.0 MB |
+-----------------------------------+----------+-----------+
| data/individual/individual_44.csv | current  |    3.0 MB |
+-----------------------------------+----------+-----------+
| data/individual/individual_45.csv | current  |    3.0 MB |
+-----------------------------------+----------+-----------+
| data/individual/individual_46.csv | current  |    3.0 MB |
+-----------------------------------+----------+-----------+
| data/individual/individual_47.csv | current  |    3.0 MB |
+-----------------------------------+----------+-----------+
| data/individual/individual_48.csv | current  |    3.0 MB |
+-----------------------------------+----------+-----------+
| data/individual/individual_49.csv | current  |    3.0 MB |
+-----------------------------------+----------+-----------+
| data/individual/individual_50.csv | current  |    3.0 MB |
+-----------------------------------+----------+-----------+
| data/large/large_1.csv            | unsynced |   25.0 MB |
+-----------------------------------+----------+-----------+
| data/small/small_1.csv            | current  | 1024.0 KB |
+-----------------------------------+----------+-----------+
| data/small/small_2.csv            | current  | 1024.0 KB |
+-----------------------------------+----------+-----------+
| data/small/small_3.csv            | current  | 1024.0 KB |
+-----------------------------------+----------+-----------+
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


---

**Next up**: [Internals](intro-internals.html): how dvs organises meta files and blob storage.
