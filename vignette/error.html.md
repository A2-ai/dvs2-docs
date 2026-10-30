---
title: "Error reference"
subtitle: "errors dvs can raise, shown side by side for R and the CLI"
format:
  html:
    keep-md: true
execute:
  freeze: auto
---

::: {.callout-note}
This page is implementation detail, beyond what normal use requires.
:::

# Setup


::: {.cell}

```{.r .cell-code}
library(dvs)
library(here)

# Print tibbles wide so all columns appear on one row.
# 10000 is the ceiling base R allows.
options(width = 10000)
```
:::


Create a temporary storage directory and project root, then expose them to the
shell so the bash chunks below can use `$DVS_PROJECT` and `$DVS_STORAGE`.


::: {.cell}

```{.r .cell-code}
storage     <- basename(tempfile(fileext = "_storage"))
new_project <- basename(tempfile(fileext = "_project"))
dir.create(here::here(storage))
dir.create(here::here(new_project))

# Make it a git repo so dvs can find the project root
system2("git", c("init", here::here(new_project)), stdout = FALSE, stderr = FALSE)

Sys.setenv(DVS_PROJECT = here::here(new_project), DVS_STORAGE = here::here(storage))
```
:::


# `init` errors

## No storage backend given

The CLI needs a backend before the storage path: `dvs init local <PATH>` for a
directory, or `dvs init server` for a dvs server. A plain `dvs init <PATH>`, the
form from before the server backend, exits 2 and suggests the `local` form.
`dvs_init()` in R always uses a local directory.


::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs init "$DVS_STORAGE"
```


::: {.cell-output .cell-output-stdout}

```
Error: dvs init needs a backend before the storage path: did you mean `dvs init local /Users/elea/Documents/a2ai_github/dvs2-demo-repo/fileec027ca34b4c_storage`?
```


:::
:::


## Storage path is inside the repository

Passing a storage path that resolves to a subdirectory of the project root is
rejected. dvs refuses to version-control its own blob store.


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))
dvs_init(storage_path = here::here(new_project, "inside_storage"),
         root_dir     = here::here(new_project))
```

::: {.cell-output .cell-output-error}

```
Error in `dvs_init()`:
! The given storage path is within the repository.
```


:::
:::



::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs init local "$DVS_PROJECT/inside_storage"
```


::: {.cell-output .cell-output-stdout}

```
Error: The given storage path is within the repository.
```


:::
:::


## Project already initialised: `dvs.toml` exists

Once `dvs.toml` is present a second `init` call fails immediately.


::: {.cell}

```{.r .cell-code}
# First init succeeds
setwd(here::here(new_project))
dvs_init(storage_path = here::here(storage), root_dir = here::here(new_project))
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 4
  compression metadata_folder_name backend_path                                                              backend_group
  <chr>       <lgl>                <chr>                                                                     <chr>        
1 zstd        NA                   /Users/elea/Documents/a2ai_github/dvs2-demo-repo/fileec027ca34b4c_storage staff        
```


:::

```{.r .cell-code}
# Second init fails
dvs_init(storage_path = here::here(storage), root_dir = here::here(new_project))
```

::: {.cell-output .cell-output-error}

```
Error in `dvs_init()`:
! dvs is already initialized (dvs.toml exists)
```


:::
:::



::: {.cell}

```{.bash .cell-code}
# dvs.toml already created by the R chunk above
cd "$DVS_PROJECT"
dvs init local "$DVS_STORAGE"
```


::: {.cell-output .cell-output-stdout}

```
Error: dvs is already initialized (dvs.toml exists)
```


:::
:::


## Backend storage already exists

If `dvs.toml` is deleted but the storage directory still contains a previous
backend layout, re-running init refuses rather than silently reusing the
backend.


::: {.cell}

```{.r .cell-code}
# Use fresh temp dirs so we don't disrupt the main demo project
bse_storage <- basename(tempfile(fileext = "_storage"))
bse_project <- basename(tempfile(fileext = "_project"))
dir.create(here::here(bse_storage)); dir.create(here::here(bse_project))
system2("git", c("init", here::here(bse_project)), stdout = FALSE, stderr = FALSE)

setwd(here::here(bse_project))
dvs_init(storage_path = here::here(bse_storage), root_dir = here::here(bse_project))
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 4
  compression metadata_folder_name backend_path                                                              backend_group
  <chr>       <lgl>                <chr>                                                                     <chr>        
1 zstd        NA                   /Users/elea/Documents/a2ai_github/dvs2-demo-repo/fileec021f431ddf_storage staff        
```


:::

```{.r .cell-code}
# Remove dvs.toml but leave the storage intact
file.remove(here::here(bse_project, "dvs.toml"))
```

::: {.cell-output .cell-output-stdout}

```
[1] TRUE
```


:::

```{.r .cell-code}
# Second init detects the existing backend
dvs_init(storage_path = here::here(bse_storage), root_dir = here::here(bse_project))
```

::: {.cell-output .cell-output-error}

```
Error in `dvs_init()`:
! dvs is already initialized (backend storage exists)
```


:::
:::



::: {.cell}

```{.bash .cell-code}
BSE_STORAGE=$(mktemp -d)
BSE_PROJECT=$(mktemp -d)
git -C "$BSE_PROJECT" init -q
cd "$BSE_PROJECT"
dvs init local "$BSE_STORAGE" > /dev/null
rm dvs.toml
dvs init local "$BSE_STORAGE"
rm -rf "$BSE_STORAGE" "$BSE_PROJECT"
```


::: {.cell-output .cell-output-stdout}

```
Error: dvs is already initialized (backend storage exists)
```


:::
:::


# `add` errors

## Not inside a DVS project

Calling `dvs_add` / `dvs add` from a directory that has no `dvs.toml` anywhere
in its ancestor chain fails before touching the filesystem.


::: {.cell}

```{.r .cell-code}
outside <- basename(tempfile())
dir.create(here::here(outside))
setwd(here::here(outside))

dvs_add(paths = "anything.csv")
```

::: {.cell-output .cell-output-error}

```
Error in `dvs_add()`:
! Not in a DVS repository
```


:::
:::



::: {.cell}

```{.bash .cell-code}
OUTSIDE=$(mktemp -d)
cd "$OUTSIDE"
dvs add anything.csv
rm -rf "$OUTSIDE"
```


::: {.cell-output .cell-output-stdout}

```
Error: Not in a DVS repository
```


:::
:::


## No files to add: empty glob

A glob pattern that matches no files raises in the R package; the CLI prints
`Error: No files to add` and exits 1, so pipelines see the failure too.


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))
dvs_add(glob = "data/*.csv")
```

::: {.cell-output .cell-output-error}

```
Error in `dvs_add()`:
! No files to add
```


:::
:::



::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs add --glob "data/*.csv"
```


::: {.cell-output .cell-output-stdout}

```
Error: No files to add
```


:::
:::


## Path not found

Passing an explicit path that doesn't exist on disk aborts before any files
are processed. Neither surface does partial work.


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))
dvs_add(paths = "nonexistent_file.csv")
```

::: {.cell-output .cell-output-error}

```
Error in `dvs_add()`:
! Path not found: nonexistent_file.csv
```


:::
:::



::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs add nonexistent_file.csv
```


::: {.cell-output .cell-output-stdout}

```
Error: Path not found: nonexistent_file.csv
```


:::
:::


## Path resolves to a directory (no glob)

Passing a bare directory name with no glob is an invalid input, not an empty
match. Both surfaces refuse the batch with the same message (`path is a
directory`), and the CLI exits 2. Directories only make sense combined with a
glob, or via `--recursive` on `status` and `get`.


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))
dir.create(here::here(new_project, "mydir"), showWarnings = FALSE)
dvs_add(paths = "mydir")
```

::: {.cell-output .cell-output-error}

```
Error in `dvs_add()`:
! Refusing to add, the following paths are invalid:
  mydir: path is a directory
```


:::
:::



::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
mkdir -p mydir
dvs add mydir
```


::: {.cell-output .cell-output-stdout}

```
Error: Refusing to add, the following paths are invalid:
  mydir: path is a directory
```


:::
:::


## Path is outside the project root

You're inside the project but ask dvs to track a file that lives elsewhere on
disk, by absolute path. This is an invalid input: the whole batch is refused
before anything is written, and the R package raises the same way it does for
a missing path. (Earlier releases recorded this as an `error` row in the
result instead; 0.4.0 moved it to batch validation.)


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))
outside_file <- tempfile(fileext = ".csv")
writeLines("a,b,c", outside_file)
dvs_add(paths = outside_file)
```

::: {.cell-output .cell-output-error}

```
Error in `dvs_add()`:
! Refusing to add, the following paths are invalid:
  /var/folders/_x/bq8vb1b156sgl363l71by61h0000gn/T//RtmpVuDexU/fileec021acb53fc.csv: path is outside project
```


:::
:::



::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
OUTSIDE_FILE=$(mktemp -t dvs_outside).csv
echo "a,b,c" > "$OUTSIDE_FILE"
dvs add "$OUTSIDE_FILE"
rm -f "$OUTSIDE_FILE"
```


::: {.cell-output .cell-output-stdout}

```
Error: Refusing to add, the following paths are invalid:
  /var/folders/_x/bq8vb1b156sgl363l71by61h0000gn/T/dvs_outside.4Ocwz6sBcH.csv: path is outside project
```


:::
:::


## Mixed paths: one exists, one does not

When only some paths exist, both surfaces abort at the first missing path.
No partial add.


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))
writeLines("x", here::here(new_project, "present.csv"))
dvs_add(paths = c("present.csv", "missing.csv"))
```

::: {.cell-output .cell-output-error}

```
Error in `dvs_add()`:
! Path not found: missing.csv
```


:::
:::



::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
echo "x" > present.csv
dvs add present.csv missing.csv
```


::: {.cell-output .cell-output-stdout}

```
Error: Path not found: missing.csv
```


:::
:::


# `status` errors

## Not inside a DVS project

`dvs_status` / `dvs status` require a `dvs.toml` in the ancestor tree.


::: {.cell}

```{.r .cell-code}
outside2 <- basename(tempfile())
dir.create(here::here(outside2))
setwd(here::here(outside2))
dvs_status()
```

::: {.cell-output .cell-output-error}

```
Error in `dvs_status()`:
! Not in a DVS repository
```


:::
:::



::: {.cell}

```{.bash .cell-code}
OUTSIDE2=$(mktemp -d)
cd "$OUTSIDE2"
dvs status
rm -rf "$OUTSIDE2"
```


::: {.cell-output .cell-output-stdout}

```
Error: Not in a DVS repository
```


:::
:::


## Path outside the project root

Unlike `add`, an absolute path outside the project does **not** produce an
error for `status`. The path just doesn't match anything tracked and you
get the empty-set response.


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))
outside_status <- tempfile(fileext = ".csv")
writeLines("a,b,c", outside_status)
dvs_status(paths = outside_status) |> print(width = Inf, n = Inf)
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 0 × 10
# ℹ 10 variables: path <chr>, status <chr>, hash <chr>, size <bytes>, created_by <chr>, compression <chr>, message <chr>, code <chr>, error <chr>, add_time <dttm>
```


:::
:::



::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
OUTSIDE_S=$(mktemp -t dvs_outside_s).csv
echo "a,b,c" > "$OUTSIDE_S"
dvs status "$OUTSIDE_S"
rm -f "$OUTSIDE_S"
```


::: {.cell-output .cell-output-stdout}

```
No tracked files
```


:::
:::


## Mixed paths: one tracked, one does not exist

Unlike `add`, `status` quietly drops paths it can't match. You get a tibble
with only the tracked path and no error or warning about the missing one.


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))
# Track one real file so we have something to match against
writeLines("x", here::here(new_project, "present.csv"))
dvs_add(paths = "present.csv")
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 6
  path        outcome hash                                                                size stored_size duration_ms
  <chr>       <chr>   <chr>                                                            <bytes>     <bytes>       <dbl>
1 present.csv copied  44c77418e27569db9213c6b43d9049ecffb5496f7d0e3d4254bb68410adecc3e     2 B        11 B           3
```


:::

```{.r .cell-code}
dvs_status(paths = c("present.csv", "missing.csv")) |>
  print(width = Inf, n = Inf)
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 10
  path        status  hash                                                                size created_by compression message code  error add_time           
  <chr>       <chr>   <chr>                                                            <bytes> <chr>      <chr>       <chr>   <chr> <chr> <dttm>             
1 present.csv current 44c77418e27569db9213c6b43d9049ecffb5496f7d0e3d4254bb68410adecc3e     2 B elea       zstd        <NA>    <NA>  <NA>  2026-10-30 18:42:35
```


:::
:::



::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs status present.csv missing.csv
```


::: {.cell-output .cell-output-stdout}

```
+-------------+---------+------+
| path        | status  | size |
+-------------+---------+------+
| present.csv | current |  2 B |
+-------------+---------+------+

Checked 1
```


:::
:::


## Unparseable meta file

If a `.dvs` meta file is corrupted (non-JSON content), the parse error
surfaces as a per-file row in the result rather than a top-level abort. The
rest of the tree still resolves. In R the row has status `error`, the kind of
failure in `code` (`bad_metadata`) and the reason in `error`. The CLI prints
the reason, leaves the file out of the table and counts it as failed.


::: {.cell}

```{.r .cell-code}
# Fresh project so we can corrupt one meta file without affecting the rest
ump_storage <- basename(tempfile(fileext = "_storage"))
ump_project <- basename(tempfile(fileext = "_project"))
dir.create(here::here(ump_storage)); dir.create(here::here(ump_project))
system2("git", c("init", here::here(ump_project)), stdout = FALSE, stderr = FALSE)

setwd(here::here(ump_project))
dvs_init(storage_path = here::here(ump_storage), root_dir = here::here(ump_project))
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 4
  compression metadata_folder_name backend_path                                                              backend_group
  <chr>       <lgl>                <chr>                                                                     <chr>        
1 zstd        NA                   /Users/elea/Documents/a2ai_github/dvs2-demo-repo/fileec0263e982f9_storage staff        
```


:::

```{.r .cell-code}
writeLines("x", here::here(ump_project, "corrupt.csv"))
dvs_add(paths = "corrupt.csv")
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 6
  path        outcome hash                                                                size stored_size duration_ms
  <chr>       <chr>   <chr>                                                            <bytes>     <bytes>       <dbl>
1 corrupt.csv copied  44c77418e27569db9213c6b43d9049ecffb5496f7d0e3d4254bb68410adecc3e     2 B        11 B           1
```


:::

```{.r .cell-code}
# Corrupt the meta file
writeLines("garbage", here::here(ump_project, ".dvs", "corrupt.csv.dvs"))

dvs_status() |> print(width = Inf, n = Inf)
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 10
  path        status hash     size created_by compression message code         error                             add_time
  <chr>       <chr>  <chr> <bytes> <chr>      <chr>       <chr>   <chr>        <chr>                             <dttm>  
1 corrupt.csv error  <NA>       NA <NA>       <NA>        <NA>    bad_metadata expected value at line 1 column 1 NA      
```


:::

```{.r .cell-code}
Sys.setenv(UMP_PROJECT = here::here(ump_project))
```
:::



::: {.cell}

```{.bash .cell-code}
cd "$UMP_PROJECT"
dvs status
```


::: {.cell-output .cell-output-stdout}

```
Error getting status for corrupt.csv: expected value at line 1 column 1
+------+--------+------+
| path | status | size |
+------+--------+------+

1 failed
```


:::
:::


# `get` errors

## Not inside a DVS project


::: {.cell}

```{.r .cell-code}
outside3 <- basename(tempfile())
dir.create(here::here(outside3))
setwd(here::here(outside3))
dvs_get(paths = "something.csv")
```

::: {.cell-output .cell-output-error}

```
Error in `dvs_get()`:
! Not in a DVS repository
```


:::
:::



::: {.cell}

```{.bash .cell-code}
OUTSIDE3=$(mktemp -d)
cd "$OUTSIDE3"
dvs get something.csv
rm -rf "$OUTSIDE3"
```


::: {.cell-output .cell-output-stdout}

```
Error: Not in a DVS repository
```


:::
:::


## No files to get: empty glob

When the glob resolves to zero tracked files, there is nothing to get.
`dvs_get()` returns an empty result under the line `no tracked files matched`,
not an R error. The CLI prints the same line and exits 1.


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))
dvs_get(glob = "data/nope_*.csv")
```

::: {.cell-output .cell-output-stdout}

```
# no tracked files matched
# A tibble: 0 × 13
# ℹ 13 variables: path <chr>, local_path <chr>, before <chr>, action <chr>, satisfied <lgl>, size <bytes>, target_hash <chr>, local_hash <chr>, stored_copy <chr>, code <chr>, message <chr>, hint <chr>, duration_ms <dbl>
```


:::
:::



::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs get --glob "data/nope_*.csv"
```


::: {.cell-output .cell-output-stdout}

```
dvs get: no tracked files matched
```


:::
:::


## File is not tracked by DVS

Requesting a file that exists on disk but has never been `dvs add`-ed. This
is a result, not an R error: the row has `action` `failed` and `code`
`not_tracked`, and no other requested file is changed. The CLI prints the same
and exits 1.


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))
writeLines("col1,col2", here::here(new_project, "untracked.csv"))
dvs_get(paths = "untracked.csv")
```

::: {.cell-output .cell-output-stdout}

```
# Aborted, nothing changed: 1 file cannot be retrieved
# ! untracked.csv: not tracked by dvs
#     check the path; list tracked files with: dvs status
# A tibble: 1 × 13
  path          local_path    before      action satisfied    size target_hash local_hash stored_copy code        message            hint                                                duration_ms
* <chr>         <chr>         <chr>       <chr>  <lgl>     <bytes> <chr>       <chr>      <chr>       <chr>       <chr>              <chr>                                                     <dbl>
1 untracked.csv untracked.csv not_tracked failed FALSE          NA <NA>        <NA>       <NA>        not_tracked not tracked by dvs check the path; list tracked files with: dvs status          NA
```


:::
:::



::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
echo "col1,col2" > untracked.csv
dvs get untracked.csv
```


::: {.cell-output .cell-output-stdout}

```
failed        untracked.csv  not tracked by dvs

Aborted, nothing changed: 1 file cannot be retrieved
  untracked.csv: check the path; list tracked files with: dvs status
```


:::
:::


## File is not found at all

Requesting a path that neither exists on disk nor has metadata. dvs does not
tell it apart from an untracked file: it is `not_tracked` too.


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))
dvs_get(paths = "ghost.csv")
```

::: {.cell-output .cell-output-stdout}

```
# Aborted, nothing changed: 1 file cannot be retrieved
# ! ghost.csv: not tracked by dvs
#     check the path; list tracked files with: dvs status
# A tibble: 1 × 13
  path      local_path before      action satisfied    size target_hash local_hash stored_copy code        message            hint                                                duration_ms
* <chr>     <chr>      <chr>       <chr>  <lgl>     <bytes> <chr>       <chr>      <chr>       <chr>       <chr>              <chr>                                                     <dbl>
1 ghost.csv ghost.csv  not_tracked failed FALSE          NA <NA>        <NA>       <NA>        not_tracked not tracked by dvs check the path; list tracked files with: dvs status          NA
```


:::
:::



::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs get ghost.csv
```


::: {.cell-output .cell-output-stdout}

```
failed        ghost.csv  not tracked by dvs

Aborted, nothing changed: 1 file cannot be retrieved
  ghost.csv: check the path; list tracked files with: dvs status
```


:::
:::


## Storage blob missing for tracked file

The metadata `.dvs` file exists but the corresponding blob has been deleted
from storage, simulating a corrupted or partially-synced store. The row has
`code` `source_missing` and a hint on what to do. The local file is left
alone.


::: {.cell}

```{.r .cell-code}
# Use a fresh project; the main demo project still has live state we don't
# want to wreck for downstream chunks.
bm_storage <- basename(tempfile(fileext = "_storage"))
bm_project <- basename(tempfile(fileext = "_project"))
dir.create(here::here(bm_storage)); dir.create(here::here(bm_project))
system2("git", c("init", here::here(bm_project)), stdout = FALSE, stderr = FALSE)

setwd(here::here(bm_project))
dvs_init(storage_path = here::here(bm_storage), root_dir = here::here(bm_project))
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 4
  compression metadata_folder_name backend_path                                                              backend_group
  <chr>       <lgl>                <chr>                                                                     <chr>        
1 zstd        NA                   /Users/elea/Documents/a2ai_github/dvs2-demo-repo/fileec02106428c6_storage staff        
```


:::

```{.r .cell-code}
writeLines("x,y,z", here::here(bm_project, "tracked.csv"))
dvs_add(paths = "tracked.csv")
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 6
  path        outcome hash                                                                size stored_size duration_ms
  <chr>       <chr>   <chr>                                                            <bytes>     <bytes>       <dbl>
1 tracked.csv copied  1357bc0161e229426dd1fba64a6adfd193f667632c54a5614ebde7370b700a5a     6 B        15 B           1
```


:::

```{.r .cell-code}
# Remove the local copy and delete every blob from storage
file.remove(here::here(bm_project, "tracked.csv"))
```

::: {.cell-output .cell-output-stdout}

```
[1] TRUE
```


:::

```{.r .cell-code}
blob_files <- list.files(here::here(bm_storage), recursive = TRUE, full.names = TRUE)
invisible(file.remove(blob_files[!grepl("audit", blob_files)]))

dvs_get(paths = "tracked.csv") |> print(width = Inf, n = Inf)
```

::: {.cell-output .cell-output-stdout}

```
# Failed: 1 failed
# ! tracked.csv: this version is not in storage
#     the stored content of this version is missing (probably an interrupted upload); tell whoever added it
# A tibble: 1 × 13
  path        local_path  before action satisfied    size target_hash                                                      local_hash stored_copy code           message                        hint                                                                                                  duration_ms
* <chr>       <chr>       <chr>  <chr>  <lgl>     <bytes> <chr>                                                            <chr>      <chr>       <chr>          <chr>                          <chr>                                                                                                       <dbl>
1 tracked.csv tracked.csv absent failed FALSE         6 B 1357bc0161e229426dd1fba64a6adfd193f667632c54a5614ebde7370b700a5a <NA>       <NA>        source_missing this version is not in storage the stored content of this version is missing (probably an interrupted upload); tell whoever added it           0
```


:::

```{.r .cell-code}
Sys.setenv(BM_PROJECT = here::here(bm_project))
```
:::



::: {.cell}

```{.bash .cell-code}
cd "$BM_PROJECT"
dvs get tracked.csv
```


::: {.cell-output .cell-output-stdout}

```
failed        tracked.csv  this version is not in storage

Failed: 1 failed
  tracked.csv: the stored content of this version is missing (probably an interrupted upload); tell whoever added it
```


:::
:::


## Retrieved file does not match expected hash

The blob exists and decompresses successfully, but its content hashes to
something other than the hash recorded in the meta file. Simulates
content-level corruption of the blob. `get` verifies the bytes before it
writes the file, so the row has `code` `hash_mismatch` and no file is
written.


::: {.cell}

```{.r .cell-code}
# Fresh project + storage
hm_storage <- basename(tempfile(fileext = "_storage"))
hm_project <- basename(tempfile(fileext = "_project"))
dir.create(here::here(hm_storage)); dir.create(here::here(hm_project))
system2("git", c("init", here::here(hm_project)), stdout = FALSE, stderr = FALSE)

setwd(here::here(hm_project))
dvs_init(storage_path = here::here(hm_storage), root_dir = here::here(hm_project))
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 4
  compression metadata_folder_name backend_path                                                              backend_group
  <chr>       <lgl>                <chr>                                                                     <chr>        
1 zstd        NA                   /Users/elea/Documents/a2ai_github/dvs2-demo-repo/fileec0219da8a26_storage staff        
```


:::

```{.r .cell-code}
writeLines("original", here::here(hm_project, "tampered.csv"))
dvs_add(paths = "tampered.csv")
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 6
  path         outcome hash                                                                size stored_size duration_ms
  <chr>        <chr>   <chr>                                                            <bytes>     <bytes>       <dbl>
1 tampered.csv copied  4618385b07b77df8055daff68db05c4e3c37151fc3306a3f2bdbeb1958419234     9 B        18 B           1
```


:::

```{.r .cell-code}
# Replace the stored blob with zstd-compressed different content under the
# same filename (so the hash-keyed path resolves, but the decompressed bytes
# no longer match the recorded hash).
blob <- list.files(here::here(hm_storage), recursive = TRUE, full.names = TRUE)
blob <- blob[!grepl("audit", blob)]
stopifnot(length(blob) == 1)
Sys.chmod(blob, mode = "0644")
# zstd -q reads stdin and writes compressed bytes to stdout
system2("bash", c("-c",
                  sprintf("printf 'DIFFERENT BYTES' | zstd -q > %s",
                          shQuote(blob))))

# Remove local file so get actually goes to storage
file.remove(here::here(hm_project, "tampered.csv"))
```

::: {.cell-output .cell-output-stdout}

```
[1] TRUE
```


:::

```{.r .cell-code}
dvs_get(paths = "tampered.csv") |> print(width = Inf, n = Inf)
```

::: {.cell-output .cell-output-stdout}

```
# Failed: 1 failed
# ! tampered.csv: the stored content does not match the tracked hash
# A tibble: 1 × 13
  path         local_path   before action satisfied    size target_hash                                                      local_hash stored_copy code          message                                            hint  duration_ms
* <chr>        <chr>        <chr>  <chr>  <lgl>     <bytes> <chr>                                                            <chr>      <chr>       <chr>         <chr>                                              <chr>       <dbl>
1 tampered.csv tampered.csv absent failed FALSE         9 B 4618385b07b77df8055daff68db05c4e3c37151fc3306a3f2bdbeb1958419234 <NA>       <NA>        hash_mismatch the stored content does not match the tracked hash <NA>            1
```


:::

```{.r .cell-code}
Sys.setenv(HM_PROJECT = here::here(hm_project))
```
:::



::: {.cell}

```{.bash .cell-code}
cd "$HM_PROJECT"
dvs get tampered.csv
```


::: {.cell-output .cell-output-stdout}

```
failed        tampered.csv  the stored content does not match the tracked hash

Failed: 1 failed
```


:::
:::


# Cleanup


::: {.cell}

```{.r .cell-code}
setwd(here::here())
unlink(here::here(new_project), recursive = TRUE)
unlink(here::here(storage),     recursive = TRUE)
for (d in c("bse_project", "bse_storage", "ump_project", "ump_storage",
            "bm_project", "bm_storage", "hm_project", "hm_storage",
            "outside", "outside2", "outside3")) {
  if (exists(d)) unlink(here::here(get(d)), recursive = TRUE)
}
```
:::

