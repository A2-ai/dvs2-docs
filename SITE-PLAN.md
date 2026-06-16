# dvs2 documentation site plan

Build-ready content plan for the dvs2 documentation site. The site is generated
from committed Quarto `keep-md` `.html.md` files, converted to Zola pages by
`tools/htmlmd_to_zola.py`, grouped into sections by the `MAP` in the `justfile`
`site-build` recipe. Section landings (`_index.md`) and `about.md` are
hand-authored; every other page is generated from a vignette.

This plan reorganizes the site from topic-grouped chapters into product
documentation with five top-level views: **Getting Started**, **R Package
commands**, **CLI commands**, **Helpers**, and **Internals**. The R and CLI
sections are in-depth references with one page per public function / command,
demonstrating every parameter and every flag. The two are kept separate because
their surfaces genuinely differ (see the capability matrix). The R-only helper
functions get their own section with one page per function. Internals sorts last.

Authoritative sources this plan is grounded in:

- CLI: `dvs --help` and per-subcommand help from the installed `0.3.0` binary.
- R: `.dvs2/dvs-rpkg/R/dvs-wrappers.R` (generated wrappers, exact signatures) and
  `.dvs2/dvs-rpkg/src/rust/lib.rs` (the `#[miniextendr]` source of truth).
- Behavior: `.dvs2/specs.md` and `.dvs2/dvs-rpkg/src/rust/lib.rs`.
- Output columns: `.dvs2/dvs/src/files/{add,get,status,types}.rs`.

## Important corrections (stale docs)

`.dvs2/specs.md` and `.dvs2/dvs-rpkg/CLAUDE.md` are out of date relative to the
generated wrappers. The plan follows the wrappers / `lib.rs`, not the stale docs.
Authors must use these signatures:

- `dvs_init(storage_path, root_dir = NULL, group = NULL, metadata_folder_name = NULL, compression = c("zstd", "none"))`.
  There is **no** `no_compression` parameter in R (specs.md and CLAUDE.md say
  `no_compression = FALSE`; the real R API takes `compression = "zstd" | "none"`).
  The CLI uses a `--no-compression` boolean flag instead.
- `dvs_add(paths = character(0), message = NULL, glob = NULL, dry_run = NULL, progress_callback = NULL)`.
  First arg is `paths`, not `files`. There is a `progress_callback` parameter
  (an internal `ProgressBarCallback` handle).
- `dvs_status(paths = character(0), recursive = NULL, status = c("current", "absent", "unsynced"))`.
  The R API does **not** take `current=`/`absent=`/`unsynced=` booleans (as
  specs.md/CLAUDE.md claim). It takes a `paths` positional, a `recursive` flag,
  and a `status` character vector (`match.arg(..., several.ok = TRUE)`).
- `dvs_get(paths = character(0), glob = NULL, dry_run = NULL, progress_callback = NULL)`.
  First arg is `paths`, not `files`.

The `dvs status` core can report a fourth state, `untracked`, but the R
`StatusChoice` enum and the CLI status filters expose only `current`, `absent`,
`unsynced`. Document the three; mention `untracked` only in Internals if at all.

---

## 1. Capability matrix

Every command/function with every CLI flag and every R parameter side by side.
"-" means the surface does not expose it. This table is the backbone justifying
separate CLI and R sections.

### Global / top-level

| Capability | CLI | R |
|---|---|---|
| JSON output | `--json` (top-level and per-subcommand) | - (R returns native data frames / lists) |
| Thread count (per call) | `--threads <N>` (top-level and per-subcommand; 0 = auto) | - (set process-wide via `set_dvs_threads(n)`, no per-call arg) |
| Thread count (process-wide) | `DVS_NUM_THREADS` env var | `set_dvs_threads(threads)` |
| Version | `dvs --version` / `-V` | `dvs_version()` |
| Log level | `RUST_LOG` env (CLI binary only) | `set_dvs_log_level(level)` (R ignores `RUST_LOG`) |
| Format a byte count | - | `format_byte_size(size_bytes)`, `new_dvs_bytes()` |

### init

| Capability | CLI `dvs init` | R `dvs_init` |
|---|---|---|
| Storage path | `<PATH>` (positional, required) | `storage_path` (required) |
| Project root | `--root-dir <ROOT_DIR>` | `root_dir = NULL` (default cwd) |
| Metadata folder name | `--metadata-folder-name <NAME>` | `metadata_folder_name = NULL` (default `.dvs`) |
| Unix group | `--group <GROUP>` | `group = NULL` |
| Compression | `--no-compression` (boolean; default zstd) | `compression = c("zstd", "none")` (match.arg) |
| Threads | `--threads <N>` | - |
| JSON | `--json` | - |

Difference to highlight: same five concepts, **different shape**. CLI compression
is a negating boolean flag; R is an enum argument with an explicit default.

### add

| Capability | CLI `dvs add` | R `dvs_add` |
|---|---|---|
| Paths | `[PATHS]...` (positional) | `paths = character(0)` |
| Glob | `--glob <GLOB>` | `glob = NULL` |
| Message | `-m, --message <MESSAGE>` | `message = NULL` |
| Dry run | `--dry-run` | `dry_run = NULL` (treated as FALSE) |
| Progress bar | (always; CLI prints its own) | `progress_callback = NULL` (opt-in handle) |
| Threads | `--threads <N>` | - |
| JSON | `--json` | - |

### status

| Capability | CLI `dvs status` | R `dvs_status` |
|---|---|---|
| Paths | `[PATHS]...` (positional) | `paths = character(0)` |
| Recursive | `-r, --recursive` | `recursive = NULL` |
| Filter to current | `--current` | element of `status` (`"current"`) |
| Filter to absent | `--absent` | element of `status` (`"absent"`) |
| Filter to unsynced | `--unsynced` | element of `status` (`"unsynced"`) |
| Metadata columns | `--with-metadata` (hidden by default) | **always returned** (data frame columns) |
| Threads | `--threads <N>` | - |
| JSON | `--json` | - |

Key difference to highlight: the CLI shows a compact table by default and only
adds hash/size/created_by/compression/message/add_time columns with
`--with-metadata`. The R `dvs_status` **always** returns the full metadata as
data frame columns; there is no with-metadata toggle because the caller can just
select columns. CLI filters are independent booleans (combinable); R filters are
a single `status` vector validated by `match.arg(several.ok = TRUE)`.

### get

| Capability | CLI `dvs get` | R `dvs_get` |
|---|---|---|
| Paths | `[PATHS]...` (positional) | `paths = character(0)` |
| Glob | `-g, --glob <GLOB>` | `glob = NULL` |
| Dry run | `--dry-run` | `dry_run = NULL` (treated as FALSE) |
| Progress bar | (always) | `progress_callback = NULL` (opt-in handle) |
| Threads | `--threads <N>` | - |
| JSON | `--json` | - |

Note: `get` exposes glob as `-g`/`--glob`, while `add` exposes only `--glob` (no
short form). Worth a one-line callout.

### R-only surface (no CLI equivalent)

| Function | Signature | Purpose |
|---|---|---|
| `dvs_version()` | `()` | core crate version string |
| `set_dvs_threads(threads)` | `threads = NULL` | process-wide thread pool size; NULL resets to auto |
| `set_dvs_log_level(level)` | `level = c("off","error","warn","info","debug","trace")` | route core log output to the R console |
| `format_byte_size(size_bytes)` | `size_bytes` (non-negative) | human-readable size string |
| `new_dvs_bytes(...)` | bytes constructor / pillar formatting | `dvs_bytes` vctr with `Ops`/`Summary`/`pillar_shaft`/`type_sum` S3 methods |

### CLI-only surface (no R equivalent)

| Flag | On | Why no R equivalent |
|---|---|---|
| `--json` | all commands | R returns native objects, so JSON serialization is unnecessary |
| `--threads <N>` | all commands | R sets it process-wide via `set_dvs_threads()` |
| `--with-metadata` | status | R always returns metadata columns |
| `--no-compression` | init | R uses the `compression` enum instead |

### Output columns (both surfaces, same core types)

- **add** success: `path, outcome (copied|present), hash, size, stored_size`; error rows carry `error`.
- **get** success: `path, outcome (copied|present), size`; error rows carry `error`.
- **status** success: `path, status (current|absent|unsynced), hash, size, created_by, compression, message, add_time`; error rows carry `error`.
  R drops the md5 column, strips the `metadata_`/`metadata_hashes_` prefixes,
  renames `blake3` to `hash`, and surfaces `add_time` as a POSIXct column. The
  CLI hides these columns unless `--with-metadata`.

---

## 2. Section and page map

Four sections. Weights set ordering. Every generated page lists its vignette
file, the `MAP` entry to add to `site-build`, whether it needs the R build to
render, and a page outline.

> Render dependency summary: **all R Package pages and the R Getting Started page
> need the R package built** (rproject.toml currently points at an absent
> `.dvs/dvs-rpkg`; source is at `.dvs2/dvs-rpkg`, so a build step is required
> before they render). **All CLI pages and the CLI Getting Started page render
> now** (the `dvs 0.3.0` binary is on PATH). Internals pages that use the R API
> need the build; an Internals page can also be authored CLI-only to avoid the
> dependency.

### Section A: Getting Started (`getting-started/`, section weight 1)

`_index.md` purpose: install instructions for both tracks, then point at the two
walkthroughs. This is the "I just re-cloned a project that uses dvs, how do I get
its data" entry point.

`_index.md` landing outline (mostly already authored, keep and extend):
- One paragraph: what dvs is (content-addressed blobs + meta files next to code, works with or without Git).
- `## Install` with CLI (`cargo install ... dvs-cli`) and R (`rv add dvs ...`) blocks.
- `## The core workflow`: the four verbs, then links to the two walkthroughs.
- Closing: links to R Package, CLI, Internals.

Pages:

| Title | Purpose | Vignette | MAP entry | Needs R build | 
|---|---|---|---|---|
| CLI walkthrough | Core loop end to end from the terminal | `getting-started-cli.qmd` (reuse, light edits) | `getting-started-cli getting-started/cli 1` | No |
| R walkthrough | Same loop from `library(dvs)` | `getting-started.qmd` (reuse, light edits) | `getting-started getting-started/r 2` | Yes |

Both walkthroughs use the same dataset and the same step sequence (see section 3).
Each step deep-links into the matching in-depth command page.

### Section B: R Package commands (`r-package/`, section weight 2)

`_index.md` purpose: orient the reader to the R surface, install line, and the
one-page-per-function model. State plainly that the R surface differs from the
CLI (returns native data frames, no `--json`, threads set process-wide).

`_index.md` landing outline:
- One paragraph: `library(dvs)` wraps the dvs core; functions return data frames / lists.
- `## Install` (rv block).
- `## Functions` short list linking each page below with its one-line purpose.
- Callout: how R differs from the CLI (link to CLI section), pointing at the capability matrix idea: R always returns metadata, threads are process-wide, no JSON.

Pages (one per exported verb function; the R-only helpers live in their own
Helpers section, not here):

| Title | Purpose | Vignette | MAP entry | Needs R build |
|---|---|---|---|---|
| `dvs_init()` | Initialize a repository; every parameter | `r-init.qmd` (new) | `r-init r-package/init 1` | Yes |
| `dvs_add()` | Add files; every parameter | `r-add.qmd` (new) | `r-add r-package/add 2` | Yes |
| `dvs_status()` | Report sync status; every parameter | `r-status.qmd` (new) | `r-status r-package/status 3` | Yes |
| `dvs_get()` | Retrieve files; every parameter | `r-get.qmd` (new) | `r-get r-package/get 4` | Yes |

Per-page outline pattern (apply to each verb page):

1. **Signature** block (verbatim from the wrapper) and a one-line description.
2. **Parameter table**: name, type, default, behavior. One row per parameter.
3. **Setup chunk** (shared): create a temp project, write the dataset, `dvs_init`
   into a sibling storage dir. Show it once per page.
4. **Per-parameter runnable example**: a small chunk that exercises exactly one
   parameter, with its output shown. Order parameters as in the signature.
5. **Return value**: the data frame / list shape with column descriptions (use
   the output-columns table above).
6. **Differences from the CLI**: a short callout linking the matching CLI page,
   naming the specific gaps (e.g. "R always returns metadata; the CLI hides it
   behind `--with-metadata`").
7. **See also**: cross-links to related pages and Internals.

Page-specific parameter coverage:

- **`dvs_init()`**: demonstrate `storage_path`; `root_dir` (init a project at a
  path other than cwd); `group` (do NOT attempt a live group set; render this one
  example locally in dev/source mode and commit the frozen result, exclude it
  from CI re-render, see build sequencing); `metadata_folder_name`
  (init with a custom folder, then `list.files` to show the renamed folder);
  `compression = "none"` vs `"zstd"` (init two projects, add the same file, show
  `stored_size` differs in the add result / on disk). Show the returned
  `list(status = "initialized")`. Callout: there is no `no_compression`; the CLI
  flag maps to `compression = "none"`.
- **`dvs_add()`**: `paths` (single file, multiple files); `message`; `glob`
  (`*.csv` vs `**/*.csv`, literal-separator rule); `dry_run = TRUE` (show the
  result with no on-disk change); document `progress_callback` in the parameter
  table only (note it is an internal handle), do NOT show a runnable example for
  it (decided: not crucial). Show the add result columns including `outcome`
  (copied vs present) and `stored_size`.
- **`dvs_status()`**: `paths` (scope to one file/dir); `recursive = TRUE` (dir
  with subdirs); `status` (single value, then `c("absent","unsynced")` via
  several.ok). Emphasize all metadata columns always return; show selecting
  columns with `[]` / dplyr. Cross-link the CLI `--with-metadata` difference.
- **`dvs_get()`**: `paths`; `glob`; `dry_run = TRUE`; document `progress_callback`
  in the parameter table only (no runnable example). Show restoring a deleted
  file (the absent -> current transition) and the get result columns.

(The R-only helpers `set_dvs_threads`, `set_dvs_log_level`, `dvs_version`,
`format_byte_size`, `new_dvs_bytes` are documented in the Helpers section below,
one page each.)

### Section C: CLI commands (`cli/`, section weight 3)

`_index.md` purpose: orient to the CLI surface, install line, the
one-page-per-command model, and the global flags (`--json`, `--threads`) that
apply to every command.

`_index.md` landing outline:
- One paragraph: the `dvs` binary, four subcommands, `--json` everywhere.
- `## Install` (cargo block).
- `## Global options`: `--json`, `--threads`, `--version` (a short table or list, since they repeat on every subcommand).
- `## Commands` list linking each page with one-line purpose.
- Callout: how the CLI differs from R (link to R section).

Pages (one per subcommand):

| Title | Purpose | Vignette | MAP entry | Needs R build |
|---|---|---|---|---|
| `dvs init` | Start a project; every flag | `cli-init.qmd` (new) | `cli-init cli/init 1` | No |
| `dvs add` | Add files; every flag | `cli-add.qmd` (new) | `cli-add cli/add 2` | No |
| `dvs status` | Status of tracked files; every flag | `cli-status.qmd` (new) | `cli-status cli/status 3` | No |
| `dvs get` | Retrieve files; every flag | `cli-get.qmd` (new) | `cli-get cli/get 4` | No |

These can be authored and rendered immediately (binary is installed). Salvage the
relevant fragments from `intro-cli.qmd` and split them across the four pages.

Per-page outline pattern (apply to each command page):

1. **Usage** block (verbatim from `dvs <cmd> --help`) and one-line description.
2. **Flag/option table**: flag, argument, default, behavior. One row per flag,
   including the repeated global `--json` and `--threads` (or reference the
   section landing's global-options list and only detail command-specific ones).
3. **Setup**: a bash chunk creating a temp project dir + storage dir (and the
   dataset). Use `Sys.setenv()` + `cd "$DVS_PROJECT"` as the existing CLI
   vignettes do, so chunks share state.
4. **Per-flag runnable example**: one bash chunk per flag, output shown.
5. **`--json` example**: pipe one invocation through `--json` and show the
   structure (optionally pretty-print).
6. **Differences from R**: callout linking the matching R page.
7. **See also**: cross-links.

Page-specific flag coverage:

- **`dvs init`**: positional `<PATH>`; `--root-dir`; `--metadata-folder-name`
  (then `ls -a` to show the renamed folder); `--group`; `--no-compression`
  (callout: maps to R `compression = "none"`); `--threads`; `--json`. Note init
  errors if `dvs.toml` already exists in the target dir.
- **`dvs add`**: positional `[PATHS]...` (shell-expanded glob vs `--glob`
  library-expanded); `--glob` (`*.csv` vs `**/*.csv`); `-m/--message`;
  `--dry-run`; `--threads`; `--json`. Show exit code 1 on partial failure.
- **`dvs status`**: positional `[PATHS]...`; `-r/--recursive`; `--current`,
  `--absent`, `--unsynced` (each alone, then combined); `--with-metadata`
  (the default-compact vs full table difference, the headline CLI-vs-R point);
  `--threads`; `--json`.
- **`dvs get`**: positional `[PATHS]...`; `-g/--glob`; `--dry-run`; `--threads`;
  `--json`. Show the absent -> current restore. Callout: `get` has a short
  `-g`, `add` does not.

### Section D: Helpers (`helpers/`, section weight 4)

R-only utility functions, one page per function. They configure the dvs core
process-wide (threads, logging) or format its outputs. They are not part of the
four-verb workflow, so they get their own section. Each page shows usage and the
set / reset / default semantics.

`_index.md` purpose: list the helper functions; note they are R-only and either
affect the dvs core process-wide or are formatting utilities.

Pages (one per function):

| Title | Purpose | Vignette | MAP entry | Needs R build |
|---|---|---|---|---|
| `set_dvs_threads()` | Set / reset the process-wide thread pool | `r-threads.qmd` (new) | `r-threads helpers/threads 1` | Yes |
| `set_dvs_log_level()` | Route core log output to the R console | `r-loglevel.qmd` (new) | `r-loglevel helpers/log-level 2` | Yes |
| `dvs_version()` | Report the core crate version | `r-version.qmd` (new) | `r-version helpers/version 3` | Yes |
| `format_byte_size()` | Human-readable byte sizes | `r-format-bytes.qmd` (new) | `r-format-bytes helpers/format-bytes 4` | Yes |
| `new_dvs_bytes()` | The `dvs_bytes` vctr + pillar printing | `r-bytes.qmd` (new) | `r-bytes helpers/bytes 5` | Yes |

Per-page coverage (each shows usage and set/reset/default semantics):
- **`set_dvs_threads()`**: set a fixed N (e.g. 2) and show it takes effect on the
  next add/get; reset with `set_dvs_threads(NULL)` to the auto default
  (`min(parallelism*4, 16)`). Note the CLI equivalent is the per-call `--threads`
  flag / `DVS_NUM_THREADS` env var; the R setting is process-wide.
- **`set_dvs_log_level()`**: levels `off|error|warn|info|debug|trace`; set `"info"`
  around an add to show log routing to the R console, then reset to `"off"` (the
  load-time default). Callout: R ignores `RUST_LOG` (CLI-only).
- **`dvs_version()`**: call it, show the returned version string (the core crate version).
- **`format_byte_size()`**: call on several magnitudes (bytes, KB, MB, GB); note non-negative input.
- **`new_dvs_bytes()`**: construct a `dvs_bytes` value; show how the column prints
  in a status/add tibble (the `pillar_shaft`/`type_sum` methods) and the `Ops`/
  `Summary` group generics (e.g. summing sizes).

All Helpers pages need the R build.

### Section E: Internals (`internals/`, section weight 5; sorts last; bump `about.md` to weight 6)

Explicitly "beyond expected use." Referenced from the other sections but off the
critical path. Replaces the current `reference/` section.

`_index.md` purpose: state this is implementation detail, not required for normal
use; index the internals pages.

Pages:

| Title | Purpose | Vignette | MAP entry | Needs R build |
|---|---|---|---|---|
| Storage and meta files | blob layout, hashing, meta JSON, compression | `intro-internals.qmd` (reuse, retitle/trim) | `intro-internals internals/storage 1` | Yes (uses R API) |
| The `dvs.toml` project file | every config field, project discovery | `config.qmd` (reuse, refocus on the toml) | `config internals/config 2` | Yes |
| The audit log | `audit.log.jsonl` format and querying | `audit.qmd` (reuse) | `audit internals/audit 3` | Yes |
| Error reference | every error R and CLI can raise | `error.qmd` (reuse) | `error internals/errors 4` | Mixed (has both R and CLI chunks) |

Internals content to cover (from `specs.md`, authoritative):
- **`dvs.toml`**: location and project discovery (walk up to find `dvs.toml`;
  init errors if one already exists locally, but a parent `dvs.toml` does not
  block a nested project); fields (storage path, compression, group, metadata
  folder name). Multiple projects per git repo.
- **Meta file format**: `.dvs/<path>.dvs` JSON sidecar mirroring the tree;
  fields `hashes.blake3`, `size`, `created_by`, `add_time` (ISO 8601),
  `compression` (`zstd`/`none`, recorded per file so changing project setting
  does not break old retrievals), optional `message`. Equality = hashes + size.
- **Storage layout**: content-addressed; blob path is `<2-char prefix>/<rest>` of
  the blake3 hash; identical content shares a blob; atomic temp-then-rename
  writes; stored files set read-only.
- **Compression**: zstd default; `none` available; per-file record means `get`
  always reads compression from metadata.
- **Audit log**: append-only `audit.log.jsonl` in the storage dir; per-entry
  `operation_id` (UUID per add invocation), `timestamp` (unix seconds), `user`,
  `file` (path + hashes), `action` (`add`); mutex-protected within a process,
  not across processes.
- **Hash cache**: SQLite at `{metadata_folder}/.cache/dvs.db`; mtime+size hit;
  optional and self-healing; gitignored.
- **Parallelism**: `DVS_NUM_THREADS`; default `min(parallelism*4, 16)`; override
  capped at 32; clamped to file count.
- **Gitignore**: added files appended to a `.gitignore` in their parent dir as
  `/<filename>`; skipped if no `.git`; failure is a warning, not fatal.

---

## 3. The Getting Started walkthrough(s)

Two pages, one per track (CLI and R), same dataset and same step sequence so a
reader can follow whichever matches their tooling. Not combined: mixing bash and
R chunks in one page muddies the "how do I drive this" story.

Dataset setup (identical in both): write R's built-in `Theoph` to a CSV.

```r
data(Theoph)
dir.create("data", showWarnings = FALSE)
write.csv(Theoph, "data/theoph.csv", row.names = FALSE)
```

Step sequence (the everyday "I re-cloned a project, get its data" loop):

1. **init** — create the project, point storage at a sibling dir.
   R: `dvs_init("../theoph-storage")`. CLI: `dvs init ../theoph-storage`.
   Deep-link: -> R `dvs_init()` page / CLI `dvs init` page.
2. **add** — track the CSV with a message.
   R: `dvs_add("data/theoph.csv", message = "initial Theoph data")`.
   CLI: `dvs add data/theoph.csv -m "initial Theoph data"`.
   Deep-link: -> add page.
3. **status** — show it is `current`.
   R: `dvs_status()`. CLI: `dvs status`.
   Deep-link: -> status page.
4. **remove the file** — delete the local CSV (plain `file.remove` / `rm`),
   the "someone re-cloned and the data is not here" moment.
5. **status** — show it is now `absent`.
   Deep-link: -> status page (call out the three states, link Internals storage).
6. **get** — restore it from storage.
   R: `dvs_get("data/theoph.csv")`. CLI: `dvs get data/theoph.csv`.
   Deep-link: -> get page.
7. **status** — show it is `current` again. Done.

Keep each page short: setup, seven labeled steps with one chunk + its output
each, and a closing "next steps" linking the R Package / CLI / Internals sections.

---

## 4. Presentation and clarity guidelines

Prose style: no em-dashes, no flourishes, no sales pitch, succinct and factual.

**Presenting "all parameters" readably.** Each command/function page leads with a
verbatim signature/usage block, then a single parameter table (name, type/arg,
default, behavior), then one short runnable example per parameter in signature
order. The table is the scannable reference; the examples prove each parameter
runs and show its output. Do not bury a parameter in a paragraph; every parameter
gets a table row and an example chunk.

**Surfacing CLI-vs-R differences.** Every command page ends with a short
"Differences from the CLI/R" callout that names the specific gap and links the
sibling page. The four headline differences to repeat where relevant:
`--json` (CLI only), `--threads` per call vs `set_dvs_threads()` process-wide,
`--with-metadata` vs R always returning metadata, `--no-compression` vs
`compression = "none"`. The capability matrix in section 1 is the master list;
pages cite it rather than re-deriving it.

**Callout usage.** Use Quarto callouts sparingly: `note` for cross-surface
differences and the "stale docs" corrections, `warning` for destructive or
permission-dependent behavior (e.g. `group`, deleting files in the walkthrough),
`tip` for the glob literal-separator rule. Internals pages open with a `note`
that the content is beyond normal use.

**Ordering.** Within a section: the four verbs in workflow order
(init, add, status, get), helpers after. Across sections: Getting Started (1),
R Package (2), CLI (3), Internals (5). Within a page: signature, params, setup,
per-param examples, return value, differences, see-also.

**Cross-link graph.**
- Getting Started steps -> the matching in-depth command page (R or CLI).
- Each R command page <-> its CLI counterpart (the differences callout).
- Command pages -> Internals (e.g. add/status link "Storage and meta files";
  init links "The dvs.toml project file"; any page touching the log -> "The audit log").
- Internals pages -> back to the command pages they explain.
- Section landings -> each other and to Getting Started.

Links use the converter's rewriting: a Markdown link to `<name>.html` is
rewritten to the Zola `@/<section>/<file>.md` path via the `MAP`-derived
name->path JSON, so author cross-links in the `.qmd` as `[text](othername.html)`
using the vignette name.

---

## 5. Reuse / migration table

| Existing vignette | Fate | Target page(s) |
|---|---|---|
| `index.qmd` | Retire (decided) | The authored root `_index.md` fully replaces it. Not in the `MAP`; drop its `render`/`publish` lines or leave the file unused. |
| `getting-started.qmd` | Reuse, light edits | Getting Started -> R walkthrough. Align steps with section 3 (add explicit remove + second status). |
| `getting-started-cli.qmd` | Reuse, light edits | Getting Started -> CLI walkthrough. Same alignment. |
| `intro.qmd` | Retire / harvest | "Working with many files" content folds into the R `dvs_add()` and `dvs_status()` pages (glob, folder, filter examples). |
| `intro-cli.qmd` | Retire / harvest | Split across the four CLI command pages (it already covers glob, dry-run, JSON, --with-metadata, filters, --threads). Primary source for the CLI section. |
| `intro-internals.qmd` | Reuse, retitle/trim | Internals -> "Storage and meta files". |
| `lifecycle.qmd` | Retire / harvest | dry-run + unsynced + recursive examples fold into R `dvs_add()`/`dvs_status()`/`dvs_get()` pages. |
| `collab.qmd` | Retire / harvest | shared-storage idea folds into Internals "Storage and meta files" or a short note on `dvs_init` pages; not its own page. |
| `config.qmd` | Reuse, refocus | Internals -> "The dvs.toml project file". Trim the R-init demo (now on the `dvs_init` page); keep the toml field tour. |
| `audit.qmd` | Reuse as-is | Internals -> "The audit log". |
| `error.qmd` | Reuse as-is | Internals -> "Error reference". |
| `random_files.qmd` | Retire from nav | The `mkdatasetfiles` helper is test-data plumbing, not product docs. Keep the file for rendering other vignettes; drop it from the `MAP`. |
| `setup.qmd` | Retire from nav | Bootstrap instructions are repo-dev concern, not product docs. Keep file, drop from `MAP`. |
| `splash.qmd` | Excluded (unchanged) | reveal.js deck, intentionally not in the site. |

New vignettes to author: `cli-init`, `cli-add`, `cli-status`, `cli-get`
(no R build needed); `r-init`, `r-add`, `r-status`, `r-get` (R Package);
`r-threads`, `r-loglevel`, `r-version`, `r-format-bytes`, `r-bytes` (Helpers).
All R vignettes need the R build.

---

## 6. Build sequencing

1. **Author and render the CLI section first** (binary is installed, no R build
   needed). Write `cli-init/add/status/get.qmd`, harvesting from `intro-cli.qmd`.
   `just render-one cli-init` etc. Add their `render`/`publish` lines to the
   justfile per the project's "Adding a new vignette" steps.
2. **Build the R package.** Point `rproject.toml`'s dvs entry at the live source
   (`{ name = "dvs", path = ".dvs2/dvs-rpkg" }`) or clone main into `.dvs` per
   the repo's documented flow, then `rv sync`. Without this, no R page renders.
3. **Author and render the R Package + Helpers sections.** Write
   `r-init/add/status/get.qmd` and the helper pages
   `r-threads/r-loglevel/r-version/r-format-bytes/r-bytes.qmd`. Render each,
   confirm output chunks execute. For the `dvs_init` `group` example: render it
   once locally in dev/source mode and commit the frozen `.html.md`; mark that
   chunk so CI does not re-execute it (e.g. `eval: false` with committed frozen
   output, or keep it in a vignette excluded from the CI render path). Do not
   attempt a live OS group set.
4. **Align the two Getting Started walkthroughs** to the section-3 step sequence
   (add the explicit remove + second status). Re-render both.
5. **Refocus the Internals vignettes** (`intro-internals`, `config`, `audit`,
   `error`) and re-render against `0.3.0` to refresh outputs.
6. **Restructure the `justfile` `MAP`** to the section/file layout in section 2;
   move `reference/*` to `internals/*`; drop `random_files` and `setup` from the
   `MAP`; add the new R and CLI page rows.
7. **Author the landings**: rewrite `r-package/_index.md` and `cli/_index.md` for
   the one-page-per-command model with global-options lists; add
   `helpers/_index.md` (R-only utilities, weight 4); add `internals/_index.md`
   (move from `reference/_index.md`, weight 5, sorts last); extend
   `getting-started/_index.md` install copy if needed. Bump `about.md` weight to 6.
8. **Rebuild and check**: `just site-build`, then `cd site && zola check` to
   catch broken internal links (the converter warns on internal-link level).

### Decisions (resolved by owner, 2026-06-16)

1. **Helper granularity:** helpers get their OWN section (Helpers, weight 4), one
   page per function, each showing usage and the set / reset / default semantics
   (resetting threads, restoring the default log level, etc.). Not grouped. (See
   Section D.)
2. **`progress_callback`:** document it in the parameter table on `dvs_add` /
   `dvs_get`, but do NOT show a runnable example; it is not crucial.
3. **`index.qmd`:** retire it; the authored root `_index.md` fully replaces it.
4. **`group` demonstration:** do NOT re-render in CI and do NOT attempt a live OS
   group set. Render the example once locally in dev/source mode and commit the
   frozen result. (See build sequencing step 3.)
5. **Internals ordering:** confirmed last (weight 5), after Getting Started, R
   Package, CLI, and Helpers; `about.md` at weight 6.
