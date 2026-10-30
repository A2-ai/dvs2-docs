# dvs2-docs

Documentation and demo repo for [dvs2](https://github.com/A2-ai/dvs2). Two roles:

- **Docs site** — the reference chapters (`r-*`, `cli-*`, the helper and internals
  vignettes) build into a Zola site on GitHub Pages
  (https://a2-ai.github.io/dvs2-docs/, public) via `just site-build`, and are
  also published to alx via `just publish`. One page per R function / CLI command.
- **Demos** — narrative demo vignettes, published to alx but NOT on the Zola
  site (not in the `site-build` MAP): `intro` (lightweight quickstart
  introduction), then the in-depth `intro-r`, `intro-cli`, and `collab`.
  The older demos (lifecycle, random_files) were folded into these in 2026-08.

## Layout

- `vignette/` — quarto `.qmd` sources; each renders to `.html` + `.html.md` (keep-md: true)
- `R/` — helper scripts used by vignettes (`mkdatasetfiles.R` test-data generator)
- `bin/` — dvs CLI installed by `just install-cli` from the dvs2 commit in
  `rv.lock` (gitignored). The justfile prepends it to PATH for every recipe, so
  rendered bash chunks use the same dvs as the R package
- `.alx/` — Alexandria config (project ID `22c331d9-0bd0-4e36-b5fd-df81a841a628`, remote https://alx.dev.a2-ai.cloud/api)
- `rproject.toml` — rv config. The dvs R package is a git dependency on dvs2 at a pinned commit, subdirectory `dvs-rpkg`

## Key workflows

```bash
just render         # render the site chapters + splash deck
just render-demos   # render the demo vignettes (intro, intro-r, intro-cli, collab)
just render-one NAME
just publish        # publish demos + chapters to alx (includes .html.md as -I artifact)
just sync           # rv sync
```

**Rendering and rv sync need R 4.5 on PATH** (the machine default 4.6 has no
PRISM binaries and old packages fail to compile under it):

```bash
export PATH="/Library/Frameworks/R.framework/Versions/4.5-arm64/Resources/bin:$PATH"
```

## Which dvs (the pinned dvs2 commit)

`rproject.toml` pins dvs to one dvs2 commit, the way ncakit's consumers pin
ncakit:

```toml
{ name = "dvs", git = "https://github.com/A2-ai/dvs2", commit = "<sha>", directory = "dvs-rpkg" }
```

`rv.lock` records the commit. `just install-cli` builds the CLI into `./bin`
from that commit, and `just site-rustdoc` and the Pages workflow document it.
So the R chunks, the bash chunks and `/rustdoc/` all show the same dvs.

```bash
just update-dvs        # move the pin to the tip of dvs2 main, rv sync, install-cli
just update-dvs NAME   # the same for another dvs2 branch
just install-cli       # rebuild ./bin/dvs from the rv.lock commit (no-op if current)
```

`update-dvs` and `sync` need R 4.5 on PATH. After moving the pin, clear the
freeze cache (`rm -rf _freeze`) and re-render, or `freeze: auto` serves the
old output for every vignette whose `.qmd` did not change.

dvs-rpkg depends on the dvs core crate by the path `../../../dvs`, which is
outside `dvs-rpkg/`. With `directory`, rv checks out the whole repository and
runs dvs-rpkg's `bootstrap.R` there, which stages the core crate for the
build. A dependency on `dvs-rpkg/` alone (the old `path = ".dvs2/dvs-rpkg"`)
fails at configure with "Path dependencies outside the package directory are
missing". This needs rv newer than 0.22.2.

The CLI needs `dvs init local <path>` since dvs2 added the server backend.
`dvs init <path>` stops with "dvs init needs a backend before the storage
path".

To test an unpushed dvs2 worktree, replace the entry with
`{ name = "dvs", path = "/path/to/worktree", directory = "dvs-rpkg" }`,
`rv sync`, and `just install-cli /path/to/worktree`. Restore the commit pin
before committing.

## Adding a new vignette

1. Write `vignette/<name>.qmd` with `keep-md: true` and `freeze: auto`
2. Add it to `render` (site chapters, plus the `site-build` MAP) or
   `render-demos` (demos) in the `justfile`
3. Add an `alx publish` line to the `publish` recipe in `justfile`
4. Run `just render-one <name>` then `just publish`
