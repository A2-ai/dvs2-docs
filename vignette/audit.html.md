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

Every `init` and `add` is appended to `audit.log.jsonl` in the storage
directory. The log is append-only and newline-delimited JSON, with one operation
per line.

# Setup


::: {.cell}

```{.r .cell-code}
options(width = 1000)
library(dvs)
library(fs)
library(here)
```
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
# A tibble: 1 × 4
  compression metadata_folder_name backend_path                                                              backend_group
  <chr>       <lgl>                <chr>                                                                     <chr>        
1 zstd        NA                   /Users/elea/Documents/a2ai_github/dvs2-demo-repo/filee53a6024dcef_storage staff        
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


Restore a file with `get`. `get` does not append to the audit log; only `init`
and `add` are recorded.


::: {.cell}

```{.r .cell-code}
setwd(here::here(new_project))
unlink("data/file_1.csv")
dvs_get("data/file_1.csv")
```

::: {.cell-output .cell-output-stdout}

```
# Restored 1
# A tibble: 1 × 13
  path            local_path      before action   satisfied    size target_hash                                                      local_hash stored_copy code  message hint  duration_ms
* <chr>           <chr>           <chr>  <chr>    <lgl>     <bytes> <chr>                                                            <chr>      <chr>       <chr> <chr>   <chr>       <dbl>
1 data/file_1.csv data/file_1.csv absent restored TRUE       2.0 MB 716693ea8b20e5a73abf0e5e35247cc232f1ae66c573ed1bc013cab8199f2cae <NA>       <NA>        <NA>  <NA>    <NA>           29
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

{"operation_id":"7490a66b-1b57-4f58-91fb-1ca5b9e1670e","timestamp":1793385741,"user":"elea","action":{"init":{"settings":{"compression":"zstd","metadata_folder_name":null,"backend":{"path":"/Users/elea/Documents/a2ai_github/dvs2-demo-repo/filee53a6024dcef_storage","group":"staff"}},"project_path":"/Users/elea/Documents/a2ai_github/dvs2-demo-repo/filee53a14250039_project"}}}
{"operation_id":"d499dbf9-701e-4502-986b-8220b4ded90a","timestamp":1793385741,"user":"elea","action":{"add":{"file":{"path":"data/file_1.csv","hashes":{"blake3":"716693ea8b20e5a73abf0e5e35247cc232f1ae66c573ed1bc013cab8199f2cae"}},"compression":"zstd","message":"initial add of file 1"}}}
{"operation_id":"af230192-ed7d-4420-9ef5-d6f2d205513e","timestamp":1793385741,"user":"elea","action":{"add":{"file":{"path":"data/file_2.csv","hashes":{"blake3":"59548c554d27252f5f5cf9a11ba5df4de216602831b000a9105c56094c958e88"}},"compression":"zstd","message":"initial add of file 2"}}}
{"operation_id":"3a5d985b-70d2-4ce1-b5e3-2157bc6ca415","timestamp":1793385741,"user":"elea","action":{"add":{"file":{"path":"data/file_3.csv","hashes":{"blake3":"2d9855e7f48b07cb280cfba4596893f9fc9b615ff96107d8b83446a12ee0451d"}},"compression":"zstd","message":"initial add of file 3"}}}
{"operation_id":"d68e8e7d-dee3-49c8-83d3-738b6f4b4f06","timestamp":1793385741,"user":"elea","action":{"add":{"file":{"path":"data/file_2.csv","hashes":{"blake3":"db1eb2d8544f2c649b86a8058342273d221f9d9a0134227d03d36c924e9c85f9"}},"compression":"zstd","message":"updated file 2, added row 99"}}}

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
  "operation_id": "7490a66b-1b57-4f58-91fb-1ca5b9e1670e",
  "timestamp": 1793385741,
  "user": "elea",
  "action": {
    "init": {
      "settings": {
        "compression": "zstd",
        "metadata_folder_name": {},
        "backend": {
          "path": "/Users/elea/Documents/a2ai_github/dvs2-demo-repo/filee53a6024dcef_storage",
          "group": "staff"
        }
      },
      "project_path": "/Users/elea/Documents/a2ai_github/dvs2-demo-repo/filee53a14250039_project"
    }
  }
}
{
  "operation_id": "d499dbf9-701e-4502-986b-8220b4ded90a",
  "timestamp": 1793385741,
  "user": "elea",
  "action": {
    "add": {
      "file": {
        "path": "data/file_1.csv",
        "hashes": {
          "blake3": "716693ea8b20e5a73abf0e5e35247cc232f1ae66c573ed1bc013cab8199f2cae"
        }
      },
      "compression": "zstd",
      "message": "initial add of file 1"
    }
  }
}
{
  "operation_id": "af230192-ed7d-4420-9ef5-d6f2d205513e",
  "timestamp": 1793385741,
  "user": "elea",
  "action": {
    "add": {
      "file": {
        "path": "data/file_2.csv",
        "hashes": {
          "blake3": "59548c554d27252f5f5cf9a11ba5df4de216602831b000a9105c56094c958e88"
        }
      },
      "compression": "zstd",
      "message": "initial add of file 2"
    }
  }
}
{
  "operation_id": "3a5d985b-70d2-4ce1-b5e3-2157bc6ca415",
  "timestamp": 1793385741,
  "user": "elea",
  "action": {
    "add": {
      "file": {
        "path": "data/file_3.csv",
        "hashes": {
          "blake3": "2d9855e7f48b07cb280cfba4596893f9fc9b615ff96107d8b83446a12ee0451d"
        }
      },
      "compression": "zstd",
      "message": "initial add of file 3"
    }
  }
}
{
  "operation_id": "d68e8e7d-dee3-49c8-83d3-738b6f4b4f06",
  "timestamp": 1793385741,
  "user": "elea",
  "action": {
    "add": {
      "file": {
        "path": "data/file_2.csv",
        "hashes": {
          "blake3": "db1eb2d8544f2c649b86a8058342273d221f9d9a0134227d03d36c924e9c85f9"
        }
      },
      "compression": "zstd",
      "message": "updated file 2, added row 99"
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
  # init records settings and project_path, not a file, so it has no path.
  path  <- switch(cmd,
    add  = entry$action$add$file$path,
    init = NA_character_,
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
1 7490a66b-1b57-4f58-91fb-1ca5b9e1670e 2026-10-30 19:42:21 elea  init    <NA>           
2 d499dbf9-701e-4502-986b-8220b4ded90a 2026-10-30 19:42:21 elea  add     data/file_1.csv
3 af230192-ed7d-4420-9ef5-d6f2d205513e 2026-10-30 19:42:21 elea  add     data/file_2.csv
4 3a5d985b-70d2-4ce1-b5e3-2157bc6ca415 2026-10-30 19:42:21 elea  add     data/file_3.csv
5 d68e8e7d-dee3-49c8-83d3-738b6f4b4f06 2026-10-30 19:42:21 elea  add     data/file_2.csv
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
1 2026-10-30 19:42:21 add     data/file_1.csv
2 2026-10-30 19:42:21 add     data/file_2.csv
3 2026-10-30 19:42:21 add     data/file_3.csv
4 2026-10-30 19:42:21 add     data/file_2.csv
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
