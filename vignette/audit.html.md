---
title: "The audit log"
subtitle: "audit.log.jsonl format and querying"
format:
  html:
    keep-md: true
execute:
  freeze: auto
---

::: {.callout-note}
This page is implementation detail, beyond what normal use requires.
:::

Every add is appended to `audit.log.jsonl` in the storage directory. The log is
append-only and newline-delimited JSON, with one operation per line.

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


Run a sequence of dvs operations to populate the log:


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))
mkdatasetfiles(n_files = 3, size_mb = 2, prefix = "file_", dir = "data", show_progress = !nzchar(Sys.getenv("QUARTO_DOCUMENT_PATH")))
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
setwd(here::here(new_project))
invisible(dvs_add("data/file_1.csv", message = "initial add of file 1"))
invisible(dvs_add("data/file_2.csv", message = "initial add of file 2"))
invisible(dvs_add("data/file_3.csv", message = "initial add of file 3"))
```
:::


Restore a file with `get`. Note that `get` does not append to the audit log;
only `init` and `add` are recorded.


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))
unlink("data/file_1.csv")
dvs_get("data/file_1.csv")
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 1 × 3
  path            outcome    size
  <chr>           <chr>   <bytes>
1 data/file_1.csv copied   2.0 MB
```


:::
:::


Modify `file_2.csv` and re-add:


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))
cat("99,0,0,0,0,0\n", file = "data/file_2.csv", append = TRUE)
invisible(dvs_add("data/file_2.csv", message = "updated file 2, added row 99"))
```
:::


# Reading the log

The audit log is a newline-delimited JSON file (`audit.log.jsonl`) in the
storage directory. Each line is one operation:


::: {.cell}

```{.r .cell-code}
audit_path <- here::here(storage, "audit.log.jsonl")
```
:::


Raw file, one JSON object per line:


```{.r .cell-code}
lines <- readLines(audit_path)
cat("```json\n")
```

```json

```{.r .cell-code}
cat(lines, sep = "\n")
```

{"operation_id":"717644d4-ddf0-4f51-a0e7-30962f17ef91","timestamp":1781628655,"user":"elea","action":{"init":{"settings":{"compression":"zstd","metadata_folder_name":null,"backend":{"path":"/Users/elea/Documents/a2ai_github/dvs2-demo-repo/file4e15578b4566_storage","group":"staff"}},"project_path":"/Users/elea/Documents/a2ai_github/dvs2-demo-repo/file4e1578795870_project"}}}
{"operation_id":"ef3b2bf8-6ce4-4d0b-bcee-6ab39eba8ae7","timestamp":1781628655,"user":"elea","action":{"add":{"file":{"path":"data/file_1.csv","hashes":{"blake3":"7eccc458c3f4941f01cf32d26b0ac67bde4bb9377f0add92e8b989be7bf2e242"}},"compression":"zstd"}}}
{"operation_id":"9ee5b98b-9eda-40ab-acfa-bdac95ebbf11","timestamp":1781628655,"user":"elea","action":{"add":{"file":{"path":"data/file_2.csv","hashes":{"blake3":"855734680f86ce5ad3352dacd08c78c8041ab94bed7c862a36a0542c2bafb1cd"}},"compression":"zstd"}}}
{"operation_id":"9b30d94a-7ddb-4907-b689-33a24bc41f2a","timestamp":1781628655,"user":"elea","action":{"add":{"file":{"path":"data/file_3.csv","hashes":{"blake3":"f409a6bf55091606e5afc101ead8b864820467472f69890f05fdb9fd7392f77d"}},"compression":"zstd"}}}
{"operation_id":"93f8fb63-ca84-4aa2-ba59-24b3fc703970","timestamp":1781628655,"user":"elea","action":{"add":{"file":{"path":"data/file_2.csv","hashes":{"blake3":"166399740a4c8c9c363523dcbe5548f35c115e891bf3492a66f7930f6cbed09d"}},"compression":"zstd"}}}

```{.r .cell-code}
cat("\n```\n")
```

```

Same entries, pretty-printed:


```{.r .cell-code}
cat("```json\n")
```

```json

```{.r .cell-code}
for (l in lines) {
  cat(jsonlite::toJSON(jsonlite::fromJSON(l, simplifyVector = FALSE), pretty = TRUE, auto_unbox = TRUE))
  cat("\n")
}
```

{
  "operation_id": "717644d4-ddf0-4f51-a0e7-30962f17ef91",
  "timestamp": 1781628655,
  "user": "elea",
  "action": {
    "init": {
      "settings": {
        "compression": "zstd",
        "metadata_folder_name": {},
        "backend": {
          "path": "/Users/elea/Documents/a2ai_github/dvs2-demo-repo/file4e15578b4566_storage",
          "group": "staff"
        }
      },
      "project_path": "/Users/elea/Documents/a2ai_github/dvs2-demo-repo/file4e1578795870_project"
    }
  }
}
{
  "operation_id": "ef3b2bf8-6ce4-4d0b-bcee-6ab39eba8ae7",
  "timestamp": 1781628655,
  "user": "elea",
  "action": {
    "add": {
      "file": {
        "path": "data/file_1.csv",
        "hashes": {
          "blake3": "7eccc458c3f4941f01cf32d26b0ac67bde4bb9377f0add92e8b989be7bf2e242"
        }
      },
      "compression": "zstd"
    }
  }
}
{
  "operation_id": "9ee5b98b-9eda-40ab-acfa-bdac95ebbf11",
  "timestamp": 1781628655,
  "user": "elea",
  "action": {
    "add": {
      "file": {
        "path": "data/file_2.csv",
        "hashes": {
          "blake3": "855734680f86ce5ad3352dacd08c78c8041ab94bed7c862a36a0542c2bafb1cd"
        }
      },
      "compression": "zstd"
    }
  }
}
{
  "operation_id": "9b30d94a-7ddb-4907-b689-33a24bc41f2a",
  "timestamp": 1781628655,
  "user": "elea",
  "action": {
    "add": {
      "file": {
        "path": "data/file_3.csv",
        "hashes": {
          "blake3": "f409a6bf55091606e5afc101ead8b864820467472f69890f05fdb9fd7392f77d"
        }
      },
      "compression": "zstd"
    }
  }
}
{
  "operation_id": "93f8fb63-ca84-4aa2-ba59-24b3fc703970",
  "timestamp": 1781628655,
  "user": "elea",
  "action": {
    "add": {
      "file": {
        "path": "data/file_2.csv",
        "hashes": {
          "blake3": "166399740a4c8c9c363523dcbe5548f35c115e891bf3492a66f7930f6cbed09d"
        }
      },
      "compression": "zstd"
    }
  }
}

```{.r .cell-code}
cat("```\n")
```

```

# Parsing the log

Each entry has the shape:

```json
{
  "operation_id": "<uuid>",
  "timestamp":    <unix-seconds>,
  "user":         "<username>",
  "action":       { "<command>": { ... } }
}
```

The `action` field is a tagged union. The single key is the command name,
either `"init"` or `"add"` (`get` is not logged). Parse it with `purrr` and
`jsonlite`:


::: {.cell}

```{.r .cell-code}
parse_entry <- function(line) {
  entry <- jsonlite::fromJSON(line)
  cmd   <- names(entry$action)[1]
  path  <- switch(cmd,
    add  = entry$action$add$file$path,
    get  = entry$action$get$file$path,
    NA_character_
  )
  list(
    operation_id = entry$operation_id,
    timestamp    = as.POSIXct(entry$timestamp, origin = "1970-01-01"),
    user         = entry$user,
    command      = cmd,
    path         = path
  )
}

audit_tbl <- readLines(audit_path) |>
  purrr::map(parse_entry) |>
  dplyr::bind_rows()

audit_tbl
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 5 × 5
  operation_id                         timestamp           user  command path           
  <chr>                                <dttm>              <chr> <chr>   <chr>          
1 717644d4-ddf0-4f51-a0e7-30962f17ef91 2026-06-16 18:50:55 elea  init    <NA>           
2 ef3b2bf8-6ce4-4d0b-bcee-6ab39eba8ae7 2026-06-16 18:50:55 elea  add     data/file_1.csv
3 9ee5b98b-9eda-40ab-acfa-bdac95ebbf11 2026-06-16 18:50:55 elea  add     data/file_2.csv
4 9b30d94a-7ddb-4907-b689-33a24bc41f2a 2026-06-16 18:50:55 elea  add     data/file_3.csv
5 93f8fb63-ca84-4aa2-ba59-24b3fc703970 2026-06-16 18:50:55 elea  add     data/file_2.csv
```


:::
:::


# Querying the log

Operations by command type:


::: {.cell}

```{.r .cell-code}
dplyr::count(audit_tbl, command, sort = TRUE)
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 2 × 2
  command     n
  <chr>   <int>
1 add         4
2 init        1
```


:::
:::


Files touched per operation (excluding `init`):


::: {.cell}

```{.r .cell-code}
audit_tbl |>
  dplyr::filter(!is.na(path)) |>
  dplyr::select(timestamp, command, path) |>
  dplyr::arrange(timestamp)
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 4 × 3
  timestamp           command path           
  <dttm>              <chr>   <chr>          
1 2026-06-16 18:50:55 add     data/file_1.csv
2 2026-06-16 18:50:55 add     data/file_2.csv
3 2026-06-16 18:50:55 add     data/file_3.csv
4 2026-06-16 18:50:55 add     data/file_2.csv
```


:::
:::


How many times was each file touched?


::: {.cell}

```{.r .cell-code}
audit_tbl |>
  dplyr::filter(!is.na(path)) |>
  dplyr::count(path, command, sort = TRUE)
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 3 × 3
  path            command     n
  <chr>           <chr>   <int>
1 data/file_2.csv add         2
2 data/file_1.csv add         1
3 data/file_3.csv add         1
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

- [Storage and meta files](intro-internals.html): the blob and meta layout.
- [The dvs.toml project file](config.html): the project configuration.
- The command references: [dvs_add()](r-add.html) / [dvs add](cli-add.html).
