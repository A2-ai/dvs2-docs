---
title: "Getting Started with dvs CLI"
subtitle: "init, add, status, and get — five minutes end to end"
format:
  html:
    keep-md: true
execute:
  freeze: auto
---

## Setup

R creates the sandbox directories and dataset; all dvs operations below run via
the `dvs` CLI binary.


::: {.cell}

```{.r .cell-code}
options(width = 1000)
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


Expose the paths to the shell:


::: {.cell}

```{.r .cell-code}
Sys.setenv(DVS_PROJECT = here::here(new_project), DVS_STORAGE = here::here(storage))
```
:::


## `dvs init`

Initialize a dvs repository pointing at the storage directory:


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs init "$DVS_STORAGE"
cat dvs.toml
```


::: {.cell-output .cell-output-stdout}

```
DVS Initialized at "/Users/elea/Documents/a2ai_github/dvs2-demo/filed33b3b2c4b20_project"
compression = "zstd"

[backend]
path = "/Users/elea/Documents/a2ai_github/dvs2-demo/filed33b2e93187b_storage"
group = "staff"
```


:::
:::


## `dvs status` (before any adds)

No files are tracked yet:


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs status
```


::: {.cell-output .cell-output-stdout}

```
No tracked files
```


:::
:::


## `dvs add`

Track the dataset with a message:


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs add data/theoph.csv -m "add Theoph dataset"
```


::: {.cell-output .cell-output-stdout}

```
Added: data/theoph.csv [2.9 KB] --> saved [842 B] as cdd978e51298006701f7b285aaf979933f0af6b179bbdf3347014af3bcd48c06
```


:::
:::


## `dvs status`

The file is now tracked and `current`:


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


## Add a second copy

Write another copy of the dataset and track it:


::: {.cell}

```{.r .cell-code}
write.csv(Theoph, here::here(new_project, "data/theoph_v2.csv"), row.names = FALSE)
```
:::



::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs add data/theoph_v2.csv -m "add second Theoph copy"
dvs status
```


::: {.cell-output .cell-output-stdout}

```
Added: data/theoph_v2.csv [2.9 KB] as cdd978e51298006701f7b285aaf979933f0af6b179bbdf3347014af3bcd48c06
+--------------------+---------+--------+
| path               | status  | size   |
+--------------------+---------+--------+
| data/theoph.csv    | current | 2.9 KB |
+--------------------+---------+--------+
| data/theoph_v2.csv | current | 2.9 KB |
+--------------------+---------+--------+
```


:::
:::


## Modify a file, check status

Append a row to `theoph.csv` to simulate a local edit after it was stored:


::: {.cell}

```{.bash .cell-code}
echo "99,70.5,320,0,0.1" >> "$DVS_PROJECT/data/theoph.csv"
```
:::


`dvs status` detects that the file on disk no longer matches the stored hash:


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs status
```


::: {.cell-output .cell-output-stdout}

```
+--------------------+----------+--------+
| path               | status   | size   |
+--------------------+----------+--------+
| data/theoph.csv    | unsynced | 2.9 KB |
+--------------------+----------+--------+
| data/theoph_v2.csv | current  | 2.9 KB |
+--------------------+----------+--------+
```


:::
:::


## Delete the original, check status


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
rm data/theoph.csv
dvs status
```


::: {.cell-output .cell-output-stdout}

```
+--------------------+---------+--------+
| path               | status  | size   |
+--------------------+---------+--------+
| data/theoph.csv    | absent  | 2.9 KB |
+--------------------+---------+--------+
| data/theoph_v2.csv | current | 2.9 KB |
+--------------------+---------+--------+
```


:::
:::


`theoph.csv` shows `absent`; `theoph_v2.csv` remains `current`.

## `dvs get`

Restore the deleted file from storage:


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


Both files are `current` again:


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs status
```


::: {.cell-output .cell-output-stdout}

```
+--------------------+---------+--------+
| path               | status  | size   |
+--------------------+---------+--------+
| data/theoph.csv    | current | 2.9 KB |
+--------------------+---------+--------+
| data/theoph_v2.csv | current | 2.9 KB |
+--------------------+---------+--------+
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

**Next up**: [Getting Started — R API](getting-started.html) — the same workflow using the `dvs` R package functions directly.
