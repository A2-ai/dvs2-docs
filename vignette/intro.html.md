---
title: "Introducing dvs"
subtitle: "version your data files next to your code, without putting them in git"
format:
  html:
    keep-md: true
execute:
  freeze: auto
---

## The problem

Analysis projects pair code with data, and git is only good at half of that
pairing. Source files diff cleanly and stay small. Data files do neither: a
25 MB CSV bloats every clone forever, binary formats produce useless diffs,
and large files routinely blow past repository size limits. So the data ends
up outside version control, on a shared drive, named `dataset_final_v2_REAL.csv`,
and nobody can say which version produced last month's results.

## What dvs does

dvs keeps your data files exactly where your code expects them, inside the
project tree, but it does not put them in git. Instead:

- the bytes go to a **shared storage directory** (typically an NFS mount),
  stored once per unique content and compressed with zstd
- git tracks a **small JSON meta file** per data file, recording the hash,
  size, who added it, when, and an optional message
- teammates run one command to **materialize the data** their clone is missing

There are four verbs: `init`, `add`, `status`, and `get`. They are available
as an R package and as a CLI, and both surfaces operate on the same project
interchangeably. This page walks the loop once, from R, and shows what ends
up where. The in-depth pages then take each surface further:
[the R package](intro-r.html), [the CLI](intro-cli.html), and
[collaboration](collab.html).

## Setup

A project directory and a sibling storage directory. In real use the storage
sits on shared infrastructure; a local directory behaves identically for the
walkthrough.


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



::: {.cell}

```{.r .cell-code}
storage     <- basename(tempfile(fileext = "_storage"))
new_project <- basename(tempfile(fileext = "_project"))
dir.create(here::here(storage))
dir.create(here::here(new_project))
```
:::


The project is a git repository with two data files: a PK concentration
table and a derived NCA summary.


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))
system2("git", c("init", "--quiet", "."))
dir.create("data/derived", recursive = TRUE)

write.csv(Theoph, "data/pk_profiles.csv", row.names = FALSE)
write.csv(
  data.frame(ID = 1:12, AUC = round(rnorm(12, 100, 15), 1)),
  "data/derived/nca_summary.csv",
  row.names = FALSE
)
```
:::


## Initialize

`dvs_init()` writes a `dvs.toml` at the project root, pointing at the storage
directory. That file is the whole project configuration, and it belongs in git.


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))
dvs_init(here::here(storage))
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 4
  compression metadata_folder_name backend_path                                                              backend_group
  <chr>       <lgl>                <chr>                                                                     <chr>        
1 zstd        NA                   /Users/elea/Documents/a2ai_github/dvs2-demo-repo/filef769341392a5_storage staff        
```


:::
:::



::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))
cat(readLines("dvs.toml"), sep = "\n")
```

::: {.cell-output .cell-output-stdout}

```
compression = "zstd"

[backend]
path = "/Users/elea/Documents/a2ai_github/dvs2-demo-repo/filef769341392a5_storage"
group = "staff"
```


:::
:::


## Add

`dvs_add()` hashes each file, copies the content to storage, and writes the
meta file. The `message` travels with the data, like a commit message for a
dataset. Note `stored_size`: the bytes land in storage compressed.


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))
dvs_add(glob = "data/**/*.csv", message = "PK profiles and NCA summary, data cut 2026-06")
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 2 × 5
  path                         outcome hash                                                                size stored_size
  <chr>                        <chr>   <chr>                                                            <bytes>     <bytes>
1 data/derived/nca_summary.csv copied  62de3804e721fa7caf1ecf835848c76e8fc45ff0830dac824284b8696c070902   101 B        82 B
2 data/pk_profiles.csv         copied  cdd978e51298006701f7b285aaf979933f0af6b179bbdf3347014af3bcd48c06  2.9 KB       842 B
```


:::
:::


## What git tracks now

This is the core of the design, so it is worth pausing on. The project tree
now contains a `.dvs/` folder that mirrors `data/`, holding one small meta
file per data file:


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))
fs::dir_tree(".dvs", all = FALSE)
```

::: {.cell-output .cell-output-stdout}

```
.dvs
└── data
    ├── derived
    │   └── nca_summary.csv.dvs
    └── pk_profiles.csv.dvs
```


:::
:::


Each meta file is a few hundred bytes of JSON. This, not the CSV, is what git
versions:


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))
cat(readLines(".dvs/data/pk_profiles.csv.dvs"), sep = "\n")
```

::: {.cell-output .cell-output-stdout}

```
{
  "hashes": {
    "blake3": "cdd978e51298006701f7b285aaf979933f0af6b179bbdf3347014af3bcd48c06"
  },
  "size": 2992,
  "created_by": "elea",
  "add_time": "2026-08-10T15:26:08.873341Z",
  "compression": "zstd",
  "message": "PK profiles and NCA summary, data cut 2026-06"
}
```


:::
:::


And dvs has already gitignored the data files themselves:


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))
cat("data/.gitignore:\n")
```

::: {.cell-output .cell-output-stdout}

```
data/.gitignore:
```


:::

```{.r .cell-code}
cat(readLines("data/.gitignore"), sep = "\n")
```

::: {.cell-output .cell-output-stdout}

```
/pk_profiles.csv
```


:::
:::


So a commit of this project carries `dvs.toml`, `.dvs/`, and the `.gitignore`
entries: a complete, versioned description of the data, at a size git is
happy with. The bytes themselves sit in storage, addressed by their hash:


::: {.cell}

```{.r .cell-code}
fs::dir_tree(here::here(storage))
```

::: {.cell-output .cell-output-stdout}

```
/Users/elea/Documents/a2ai_github/dvs2-demo-repo/filef769341392a5_storage
├── 62
│   └── de3804e721fa7caf1ecf835848c76e8fc45ff0830dac824284b8696c070902
├── audit.log.jsonl
└── cd
    └── d978e51298006701f7b285aaf979933f0af6b179bbdf3347014af3bcd48c06
```


:::
:::


## Status

`dvs_status()` compares every tracked file against its meta file. Right after
an add, everything is `current`.


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))
dvs_status()
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 2 × 8
  path                         status  hash                                                                size created_by compression message                                       add_time           
  <chr>                        <chr>   <chr>                                                            <bytes> <chr>      <chr>       <chr>                                         <dttm>             
1 data/derived/nca_summary.csv current 62de3804e721fa7caf1ecf835848c76e8fc45ff0830dac824284b8696c070902   101 B elea       zstd        PK profiles and NCA summary, data cut 2026-06 2026-08-10 15:26:08
2 data/pk_profiles.csv         current cdd978e51298006701f7b285aaf979933f0af6b179bbdf3347014af3bcd48c06  2.9 KB elea       zstd        PK profiles and NCA summary, data cut 2026-06 2026-08-10 15:26:08
```


:::
:::


Delete a file, the way a fresh clone arrives without data, and it flips to
`absent`: still tracked, not on disk.


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))
unlink("data/pk_profiles.csv")
dvs_status()
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 2 × 8
  path                         status  hash                                                                size created_by compression message                                       add_time           
  <chr>                        <chr>   <chr>                                                            <bytes> <chr>      <chr>       <chr>                                         <dttm>             
1 data/derived/nca_summary.csv current 62de3804e721fa7caf1ecf835848c76e8fc45ff0830dac824284b8696c070902   101 B elea       zstd        PK profiles and NCA summary, data cut 2026-06 2026-08-10 15:26:08
2 data/pk_profiles.csv         absent  cdd978e51298006701f7b285aaf979933f0af6b179bbdf3347014af3bcd48c06  2.9 KB elea       zstd        PK profiles and NCA summary, data cut 2026-06 2026-08-10 15:26:08
```


:::
:::


## Get

`dvs_get()` reads the meta file, pulls the content from storage, and verifies
the hash on the way in.


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))
dvs_get("data/pk_profiles.csv")
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 3
  path                 outcome    size
  <chr>                <chr>   <bytes>
1 data/pk_profiles.csv copied   2.9 KB
```


:::

```{.r .cell-code}
dvs_status()
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 2 × 8
  path                         status  hash                                                                size created_by compression message                                       add_time           
  <chr>                        <chr>   <chr>                                                            <bytes> <chr>      <chr>       <chr>                                         <dttm>             
1 data/derived/nca_summary.csv current 62de3804e721fa7caf1ecf835848c76e8fc45ff0830dac824284b8696c070902   101 B elea       zstd        PK profiles and NCA summary, data cut 2026-06 2026-08-10 15:26:08
2 data/pk_profiles.csv         current cdd978e51298006701f7b285aaf979933f0af6b179bbdf3347014af3bcd48c06  2.9 KB elea       zstd        PK profiles and NCA summary, data cut 2026-06 2026-08-10 15:26:08
```


:::
:::


That is the whole loop: add when data changes, get after a clone or checkout,
status any time you want to know where you stand.

## The same project, from the terminal

The CLI operates on the exact same project; the two surfaces are
interchangeable. Here is the status of the project we just built, from bash:




::: {.cell}

```{.bash .cell-code}
cd "$DVS_INTRO_PROJECT"
dvs status
```


::: {.cell-output .cell-output-stdout}

```
+------------------------------+---------+--------+
| path                         | status  | size   |
+------------------------------+---------+--------+
| data/derived/nca_summary.csv | current |  101 B |
+------------------------------+---------+--------+
| data/pk_profiles.csv         | current | 2.9 KB |
+------------------------------+---------+--------+
```


:::
:::


## Where to go next

- [The R package in depth](intro-r.html): many files, globs, dry runs,
  re-adding changed data, recursive scoping, and failure handling.
- [The CLI in depth](intro-cli.html): the same power from the terminal,
  plus JSON output and exit codes for pipelines.
- [Collaboration](collab.html): two users, one storage, and what to commit.
- Reference, one page per function: [dvs_init()](r-init.html),
  [dvs_add()](r-add.html), [dvs_status()](r-status.html), [dvs_get()](r-get.html).
- [Storage and meta files](intro-internals.html): the content-addressed
  layout, meta file fields, and the audit log.

## Cleanup


::: {.cell}

```{.r .cell-code}
unlink(here::here(new_project), recursive = TRUE)
unlink(here::here(storage),     recursive = TRUE)
```
:::

