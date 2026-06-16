---
title: "CLI walkthrough"
subtitle: "The core loop with the dvs binary"
format:
  html:
    keep-md: true
execute:
  freeze: auto
---

This walkthrough runs the everyday loop from the terminal: initialize a project,
add a file, check its status, delete it, then get it back. It is the "I
re-cloned a project and need its data" sequence. The
[R walkthrough](getting-started.html) covers the same steps from R.

## Setup

R creates the sandbox directories and the dataset; all dvs operations run via
the `dvs` binary.


::: {.cell}

```{.r .cell-code}
options(width = 1000)
library(here)
```

::: {.cell-output .cell-output-stderr}

```
here() starts at /Users/elea/Documents/a2ai_github/dvs2-demo-repo
```


:::

```{.r .cell-code}
storage     <- basename(tempfile(fileext = "_storage"))
new_project <- basename(tempfile(fileext = "_project"))
dir.create(here::here(storage))
dir.create(here::here(new_project))
dir.create(here::here(new_project, "data"))
write.csv(Theoph, here::here(new_project, "data/theoph.csv"), row.names = FALSE)
Sys.setenv(DVS_PROJECT = here::here(new_project), DVS_STORAGE = here::here(storage))
```
:::


## 1. Initialize

Point storage at the sibling directory. See [dvs init](cli-init.html) for every
flag.


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs init "$DVS_STORAGE"
```


::: {.cell-output .cell-output-stdout}

```
DVS Initialized at "/Users/elea/Documents/a2ai_github/dvs2-demo-repo/file3854571482a1_project"
```


:::
:::


## 2. Add

Track the CSV with a message. See [dvs add](cli-add.html).


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs add data/theoph.csv -m "initial Theoph data"
```


::: {.cell-output .cell-output-stdout}

```
Added: data/theoph.csv [2.9 KB] --> saved [842 B] as cdd978e51298006701f7b285aaf979933f0af6b179bbdf3347014af3bcd48c06
```


:::
:::


## 3. Status

The file is tracked and `current`. See [dvs status](cli-status.html).


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs status
```


::: {.cell-output .cell-output-stdout}

```
+-----------------+---------+--------+
| path            | status  | size   |
+-----------------+---------+--------+
| data/theoph.csv | current | 2.9 KB |
+-----------------+---------+--------+
```


:::
:::


## 4. Remove the file

Delete the local copy, the moment after a fresh clone where the data is not on
disk yet.


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
rm data/theoph.csv
```
:::


## 5. Status again

The file is now `absent`: tracked, but missing locally.


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs status
```


::: {.cell-output .cell-output-stdout}

```
+-----------------+--------+--------+
| path            | status | size   |
+-----------------+--------+--------+
| data/theoph.csv | absent | 2.9 KB |
+-----------------+--------+--------+
```


:::
:::


::: {.callout-note}
dvs reports three states: `current`, `absent`, and `unsynced` (on disk but not
matching the stored hash). See [Storage and meta files](intro-internals.html).
:::

## 6. Get

Restore the file from storage. See [dvs get](cli-get.html).


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs get data/theoph.csv
```


::: {.cell-output .cell-output-stdout}

```
data/theoph.csv [2.9 KB]
Total: 1 files, 2.9 KB
```


:::
:::


## 7. Status again

The file is `current` again. The loop is complete.


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs status
```


::: {.cell-output .cell-output-stdout}

```
+-----------------+---------+--------+
| path            | status  | size   |
+-----------------+---------+--------+
| data/theoph.csv | current | 2.9 KB |
+-----------------+---------+--------+
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

- The [CLI](cli-init.html) reference covers every flag of
  [dvs init](cli-init.html), [dvs add](cli-add.html),
  [dvs status](cli-status.html), and [dvs get](cli-get.html).
- The same loop from R: [R walkthrough](getting-started.html).
- How dvs stores data: [Storage and meta files](intro-internals.html).
