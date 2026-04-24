---
title: "dvs Error Reference"
subtitle: "every error dvs can raise, shown side-by-side for R and the CLI"
format:
  html:
    keep-md: true
execute:
  freeze: auto
---

# Setup


::: {.cell}

```{.r .cell-code}
library(dvs)
library(here)
```

::: {.cell-output .cell-output-stderr}

```
here() starts at /Users/elea/Documents/a2ai_github/dvs2-demo
```


:::

```{.r .cell-code}
# Print tibbles wide so all columns appear on one row.
# options(width = Inf) is rejected by base R (max 10000); 10000 is the ceiling.
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

## Storage path is inside the repository

Passing a storage path that resolves to a subdirectory of the project root is
rejected — dvs refuses to version-control its own blob store.


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))
dvs_init(storage_path = here::here(new_project, "inside_storage"),
         root_dir     = here::here(new_project))
```

::: {.cell-output .cell-output-error}

```
Error in `dvs_init_impl()`:
! The given storage path is within the repository.
```


:::
:::



::: {.cell}

```{.bash .cell-code}
cd "$DVS_PROJECT"
dvs init "$DVS_PROJECT/inside_storage"
```


::: {.cell-output .cell-output-stdout}

```
Error: The given storage path is within the repository.
```


:::
:::


## Project already initialised — `dvs.toml` exists

Once `dvs.toml` is present a second `init` call fails immediately.


::: {.cell}

```{.r .cell-code}
# First init succeeds
setwd(here::here(new_project))
dvs_init(storage_path = here::here(storage), root_dir = here::here(new_project))
```

::: {.cell-output .cell-output-stdout}

```
DVS Initialized
```


:::

```{.r .cell-code}
# Second init fails
dvs_init(storage_path = here::here(storage), root_dir = here::here(new_project))
```

::: {.cell-output .cell-output-error}

```
Error in `dvs_init_impl()`:
! dvs is already initialized (dvs.toml exists)
```


:::
:::



::: {.cell}

```{.bash .cell-code}
# dvs.toml already created by the R chunk above
cd "$DVS_PROJECT"
dvs init "$DVS_STORAGE"
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
DVS Initialized
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
Error in `dvs_init_impl()`:
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
dvs init "$BSE_STORAGE" > /dev/null
rm dvs.toml
dvs init "$BSE_STORAGE"
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
Error in `dvs_add_impl()`:
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


## No files to add — empty glob

A glob pattern that matches no files raises in the R package; the CLI prints
`No files to add` and exits 0.


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))
dvs_add(glob = "data/*.csv")
```

::: {.cell-output .cell-output-error}

```
Error in `dvs_add_impl()`:
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
are processed — neither surface does partial work.


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))
dvs_add(paths = "nonexistent_file.csv")
```

::: {.cell-output .cell-output-error}

```
Error in `dvs_add_impl()`:
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

Passing a bare directory name with no glob matches no files. The R package
raises, the CLI prints `No files to add` and exits 0 — mild surface
divergence.


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))
dir.create(here::here(new_project, "mydir"), showWarnings = FALSE)
dvs_add(paths = "mydir")
```

::: {.cell-output .cell-output-error}

```
Error in `dvs_add_impl()`:
! No files to add
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
Error: No files to add
```


:::
:::


## Path is outside the project root

You're inside the project but ask dvs to track a file that lives elsewhere on
disk, by absolute path. R returns a 2-column tibble — `path` + `error` — with
the failure recorded as a row rather than an R-level condition.


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))
outside_file <- tempfile(fileext = ".csv")
writeLines("a,b,c", outside_file)
res <- dvs_add(paths = outside_file)
res |> print(width = Inf, n = Inf)
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 2
  path                                                                              error                  
  <chr>                                                                             <chr>                  
1 /var/folders/_x/bq8vb1b156sgl363l71by61h0000gn/T//Rtmp6V9XA4/filedae122a0d3ca.csv path is outside project
```


:::
:::


Inspect the result columns directly — `path` is the offending path, `error`
is a plain character string:


::: {.cell}

```{.r .cell-code}
str(res)
```

::: {.cell-output .cell-output-stdout}

```
tibble [1 × 2] (S3: tbl_df/tbl/data.frame)
 $ path : chr "/var/folders/_x/bq8vb1b156sgl363l71by61h0000gn/T//Rtmp6V9XA4/filedae122a0d3ca.csv"
 $ error: chr "path is outside project"
```


:::

```{.r .cell-code}
res$path
```

::: {.cell-output .cell-output-stdout}

```
[1] "/var/folders/_x/bq8vb1b156sgl363l71by61h0000gn/T//Rtmp6V9XA4/filedae122a0d3ca.csv"
```


:::

```{.r .cell-code}
res$error
```

::: {.cell-output .cell-output-stdout}

```
[1] "path is outside project"
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
Error adding /var/folders/_x/bq8vb1b156sgl363l71by61h0000gn/T/dvs_outside.AMrsbIi84I.csv: path is outside project
Error: Some files failed to add
```


:::
:::


## Mixed paths: one exists, one does not

When only some paths exist, both surfaces abort at the first missing path —
no partial add.


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))
writeLines("x", here::here(new_project, "present.csv"))
dvs_add(paths = c("present.csv", "missing.csv"))
```

::: {.cell-output .cell-output-error}

```
Error in `dvs_add_impl()`:
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
Error in `dvs_status_impl()`:
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
error for `status` — the path just doesn't match anything tracked and you
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
# A tibble: 0 × 0
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

Unlike `add`, `status` quietly drops paths it can't match — you get a tibble
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
# A tibble: 1 × 5
  path        outcome hash                                                                size stored_size
  <chr>       <chr>   <chr>                                                            <bytes>     <bytes>
1 present.csv copied  44c77418e27569db9213c6b43d9049ecffb5496f7d0e3d4254bb68410adecc3e     2 B        11 B
```


:::

```{.r .cell-code}
dvs_status(paths = c("present.csv", "missing.csv")) |>
  print(width = Inf, n = Inf)
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 7
  path        status  hash                                                                size created_by compression add_time           
  <chr>       <chr>   <chr>                                                            <bytes> <chr>      <chr>       <dttm>             
1 present.csv current 44c77418e27569db9213c6b43d9049ecffb5496f7d0e3d4254bb68410adecc3e     2 B elea       zstd        2026-04-24 12:59:45
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
```


:::
:::


## Unparseable meta file

If a `.dvs` metadata file is corrupted (non-JSON content), the parse error
surfaces as a per-file row in the result rather than a top-level abort — the
rest of the tree still resolves.


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
DVS Initialized
```


:::

```{.r .cell-code}
writeLines("x", here::here(ump_project, "corrupt.csv"))
dvs_add(paths = "corrupt.csv")
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 5
  path        outcome hash                                                                size stored_size
  <chr>       <chr>   <chr>                                                            <bytes>     <bytes>
1 corrupt.csv copied  44c77418e27569db9213c6b43d9049ecffb5496f7d0e3d4254bb68410adecc3e     2 B        11 B
```


:::

```{.r .cell-code}
# Corrupt the meta file
writeLines("garbage", here::here(ump_project, ".dvs", "corrupt.csv.dvs"))

dvs_status() |> print(width = Inf, n = Inf)
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 3
  path        error                             add_time
  <chr>       <chr>                             <dttm>  
1 corrupt.csv expected value at line 1 column 1 NA      
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
Error: Some files failed to get status
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
Error in `dvs_get_impl()`:
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


## No files to get — empty glob

When the glob resolves to zero tracked files, `dvs get` aborts.


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))
dvs_get(glob = "data/nope_*.csv")
```

::: {.cell-output .cell-output-error}

```
Error in `dvs_get_impl()`:
! No files to get
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
Error: No files to get
```


:::
:::


## File is not tracked by DVS

Requesting a file that exists on disk but has never been `dvs add`-ed.


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))
writeLines("col1,col2", here::here(new_project, "untracked.csv"))
dvs_get(paths = "untracked.csv")
```

::: {.cell-output .cell-output-error}

```
Error in `dvs_get_impl()`:
! No files to get
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
Error: No files to get
```


:::
:::


## File is not found at all

Requesting a path that neither exists on disk nor has metadata.


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))
dvs_get(paths = "ghost.csv")
```

::: {.cell-output .cell-output-error}

```
Error in `dvs_get_impl()`:
! No files to get
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
Error: No files to get
```


:::
:::


## Storage blob missing for tracked file

The metadata `.dvs` file exists but the corresponding blob has been deleted
from storage — simulating a corrupted or partially-synced store.


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
DVS Initialized
```


:::

```{.r .cell-code}
writeLines("x,y,z", here::here(bm_project, "tracked.csv"))
dvs_add(paths = "tracked.csv")
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 5
  path        outcome hash                                                                size stored_size
  <chr>       <chr>   <chr>                                                            <bytes>     <bytes>
1 tracked.csv copied  1357bc0161e229426dd1fba64a6adfd193f667632c54a5614ebde7370b700a5a     6 B        15 B
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
# A tibble: 1 × 2
  path        error                                                                                                         
  <chr>       <chr>                                                                                                         
1 tracked.csv Storage file missing for hash: Hashes(blake3=1357bc0161e229426dd1fba64a6adfd193f667632c54a5614ebde7370b700a5a)
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
Error: tracked.csv - Storage file missing for hash: Hashes(blake3=1357bc0161e229426dd1fba64a6adfd193f667632c54a5614ebde7370b700a5a)
Error: Some files failed to get
```


:::
:::


## Retrieved file does not match expected hash

The blob exists and decompresses successfully, but its content hashes to
something other than the hash recorded in the meta file. Simulates
content-level corruption of the blob.


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
DVS Initialized
```


:::

```{.r .cell-code}
writeLines("original", here::here(hm_project, "tampered.csv"))
dvs_add(paths = "tampered.csv")
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 5
  path         outcome hash                                                                size stored_size
  <chr>        <chr>   <chr>                                                            <bytes>     <bytes>
1 tampered.csv copied  4618385b07b77df8055daff68db05c4e3c37151fc3306a3f2bdbeb1958419234     9 B        18 B
```


:::

```{.r .cell-code}
# Replace the stored blob with zstd-compressed different content under the
# same filename (so the hash-keyed path resolves, but the decompressed bytes
# no longer match the recorded hash).
blob <- list.files(hm_storage, recursive = TRUE, full.names = TRUE)
blob <- blob[!grepl("audit", blob)]
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
# A tibble: 1 × 3
  path         outcome    size
  <chr>        <chr>   <bytes>
1 tampered.csv copied      9 B
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

