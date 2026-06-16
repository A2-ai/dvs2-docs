---
title: "dvs audit log"
subtitle: "every dvs operation is appended to audit.log.jsonl in the storage directory"
format:
  html:
    keep-md: true
execute:
  freeze: auto
---

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


Simulate a restore (get):


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

{"operation_id":"180d4e11-51eb-4734-8309-e9177075b741","timestamp":1777035581,"user":"elea","action":{"init":{"settings":{"compression":"zstd","metadata_folder_name":null,"backend":{"path":"/Users/elea/Documents/a2ai_github/dvs2-demo/fileda58494cb9ac_storage","group":"staff"}},"project_path":"/Users/elea/Documents/a2ai_github/dvs2-demo/fileda584c31f0cc_project"}}}
{"operation_id":"8b1c0538-421f-41f5-8b8c-4032dd5c24d5","timestamp":1777035581,"user":"elea","action":{"add":{"file":{"path":"data/file_1.csv","hashes":{"blake3":"7eccc458c3f4941f01cf32d26b0ac67bde4bb9377f0add92e8b989be7bf2e242"}},"compression":"zstd"}}}
{"operation_id":"9d354cd7-c823-443e-9e17-f41c94bd9d7f","timestamp":1777035582,"user":"elea","action":{"add":{"file":{"path":"data/file_2.csv","hashes":{"blake3":"855734680f86ce5ad3352dacd08c78c8041ab94bed7c862a36a0542c2bafb1cd"}},"compression":"zstd"}}}
{"operation_id":"b2e10221-ca4b-44a4-ba43-7ba35f78c619","timestamp":1777035582,"user":"elea","action":{"add":{"file":{"path":"data/file_3.csv","hashes":{"blake3":"f409a6bf55091606e5afc101ead8b864820467472f69890f05fdb9fd7392f77d"}},"compression":"zstd"}}}
{"operation_id":"b35e681d-4531-4681-be2f-6734f57610a3","timestamp":1777035582,"user":"elea","action":{"add":{"file":{"path":"data/file_2.csv","hashes":{"blake3":"166399740a4c8c9c363523dcbe5548f35c115e891bf3492a66f7930f6cbed09d"}},"compression":"zstd"}}}

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
  "operation_id": "180d4e11-51eb-4734-8309-e9177075b741",
  "timestamp": 1777035581,
  "user": "elea",
  "action": {
    "init": {
      "settings": {
        "compression": "zstd",
        "metadata_folder_name": {},
        "backend": {
          "path": "/Users/elea/Documents/a2ai_github/dvs2-demo/fileda58494cb9ac_storage",
          "group": "staff"
        }
      },
      "project_path": "/Users/elea/Documents/a2ai_github/dvs2-demo/fileda584c31f0cc_project"
    }
  }
}
{
  "operation_id": "8b1c0538-421f-41f5-8b8c-4032dd5c24d5",
  "timestamp": 1777035581,
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
  "operation_id": "9d354cd7-c823-443e-9e17-f41c94bd9d7f",
  "timestamp": 1777035582,
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
  "operation_id": "b2e10221-ca4b-44a4-ba43-7ba35f78c619",
  "timestamp": 1777035582,
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
  "operation_id": "b35e681d-4531-4681-be2f-6734f57610a3",
  "timestamp": 1777035582,
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

The `action` field is a tagged union. The single key is the command name
(`"init"`, `"add"`, or `"get"`). Parse it with `purrr` and `jsonlite`:


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
1 180d4e11-51eb-4734-8309-e9177075b741 2026-04-24 14:59:41 elea  init    <NA>           
2 8b1c0538-421f-41f5-8b8c-4032dd5c24d5 2026-04-24 14:59:41 elea  add     data/file_1.csv
3 9d354cd7-c823-443e-9e17-f41c94bd9d7f 2026-04-24 14:59:42 elea  add     data/file_2.csv
4 b2e10221-ca4b-44a4-ba43-7ba35f78c619 2026-04-24 14:59:42 elea  add     data/file_3.csv
5 b35e681d-4531-4681-be2f-6734f57610a3 2026-04-24 14:59:42 elea  add     data/file_2.csv
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
1 2026-04-24 14:59:41 add     data/file_1.csv
2 2026-04-24 14:59:42 add     data/file_2.csv
3 2026-04-24 14:59:42 add     data/file_3.csv
4 2026-04-24 14:59:42 add     data/file_2.csv
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


---

**Next up**: [Random files](random_files.html): the `mkdatasetfiles()` helper used to generate test data throughout these vignettes. Or return to the [full index](index.html).
