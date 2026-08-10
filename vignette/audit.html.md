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
# A tibble: 1 × 4
  compression metadata_folder_name backend_path                                                              backend_group
  <chr>       <lgl>                <chr>                                                                     <chr>        
1 zstd        NA                   /Users/elea/Documents/a2ai_github/dvs2-demo-repo/filee03632eba40d_storage staff        
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

{"operation_id":"7c137393-70b8-4807-b26d-373599b682f7","timestamp":1786375425,"user":"elea","action":{"init":{"settings":{"compression":"zstd","metadata_folder_name":null,"backend":{"path":"/Users/elea/Documents/a2ai_github/dvs2-demo-repo/filee03632eba40d_storage","group":"staff"}},"project_path":"/Users/elea/Documents/a2ai_github/dvs2-demo-repo/filee036c5f6b99_project"}}}
{"operation_id":"bb2ae161-8c2c-4755-8682-34c68fe4cab3","timestamp":1786375425,"user":"elea","action":{"add":{"file":{"path":"data/file_1.csv","hashes":{"blake3":"716693ea8b20e5a73abf0e5e35247cc232f1ae66c573ed1bc013cab8199f2cae"}},"compression":"zstd"}}}
{"operation_id":"008b7b6a-b15c-4f0d-b19b-327c6c84d460","timestamp":1786375425,"user":"elea","action":{"add":{"file":{"path":"data/file_2.csv","hashes":{"blake3":"59548c554d27252f5f5cf9a11ba5df4de216602831b000a9105c56094c958e88"}},"compression":"zstd"}}}
{"operation_id":"c0ac3187-bf33-4064-a581-5fe067cf85e2","timestamp":1786375425,"user":"elea","action":{"add":{"file":{"path":"data/file_3.csv","hashes":{"blake3":"2d9855e7f48b07cb280cfba4596893f9fc9b615ff96107d8b83446a12ee0451d"}},"compression":"zstd"}}}
{"operation_id":"ab323bc6-0a7c-4758-b667-f02b673075ec","timestamp":1786375425,"user":"elea","action":{"add":{"file":{"path":"data/file_2.csv","hashes":{"blake3":"db1eb2d8544f2c649b86a8058342273d221f9d9a0134227d03d36c924e9c85f9"}},"compression":"zstd"}}}

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
  "operation_id": "7c137393-70b8-4807-b26d-373599b682f7",
  "timestamp": 1786375425,
  "user": "elea",
  "action": {
    "init": {
      "settings": {
        "compression": "zstd",
        "metadata_folder_name": {},
        "backend": {
          "path": "/Users/elea/Documents/a2ai_github/dvs2-demo-repo/filee03632eba40d_storage",
          "group": "staff"
        }
      },
      "project_path": "/Users/elea/Documents/a2ai_github/dvs2-demo-repo/filee036c5f6b99_project"
    }
  }
}
{
  "operation_id": "bb2ae161-8c2c-4755-8682-34c68fe4cab3",
  "timestamp": 1786375425,
  "user": "elea",
  "action": {
    "add": {
      "file": {
        "path": "data/file_1.csv",
        "hashes": {
          "blake3": "716693ea8b20e5a73abf0e5e35247cc232f1ae66c573ed1bc013cab8199f2cae"
        }
      },
      "compression": "zstd"
    }
  }
}
{
  "operation_id": "008b7b6a-b15c-4f0d-b19b-327c6c84d460",
  "timestamp": 1786375425,
  "user": "elea",
  "action": {
    "add": {
      "file": {
        "path": "data/file_2.csv",
        "hashes": {
          "blake3": "59548c554d27252f5f5cf9a11ba5df4de216602831b000a9105c56094c958e88"
        }
      },
      "compression": "zstd"
    }
  }
}
{
  "operation_id": "c0ac3187-bf33-4064-a581-5fe067cf85e2",
  "timestamp": 1786375425,
  "user": "elea",
  "action": {
    "add": {
      "file": {
        "path": "data/file_3.csv",
        "hashes": {
          "blake3": "2d9855e7f48b07cb280cfba4596893f9fc9b615ff96107d8b83446a12ee0451d"
        }
      },
      "compression": "zstd"
    }
  }
}
{
  "operation_id": "ab323bc6-0a7c-4758-b667-f02b673075ec",
  "timestamp": 1786375425,
  "user": "elea",
  "action": {
    "add": {
      "file": {
        "path": "data/file_2.csv",
        "hashes": {
          "blake3": "db1eb2d8544f2c649b86a8058342273d221f9d9a0134227d03d36c924e9c85f9"
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
1 7c137393-70b8-4807-b26d-373599b682f7 2026-08-10 17:23:45 elea  init    <NA>           
2 bb2ae161-8c2c-4755-8682-34c68fe4cab3 2026-08-10 17:23:45 elea  add     data/file_1.csv
3 008b7b6a-b15c-4f0d-b19b-327c6c84d460 2026-08-10 17:23:45 elea  add     data/file_2.csv
4 c0ac3187-bf33-4064-a581-5fe067cf85e2 2026-08-10 17:23:45 elea  add     data/file_3.csv
5 ab323bc6-0a7c-4758-b667-f02b673075ec 2026-08-10 17:23:45 elea  add     data/file_2.csv
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
1 2026-08-10 17:23:45 add     data/file_1.csv
2 2026-08-10 17:23:45 add     data/file_2.csv
3 2026-08-10 17:23:45 add     data/file_3.csv
4 2026-08-10 17:23:45 add     data/file_2.csv
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
