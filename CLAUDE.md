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
- `bin/` — dvs CLI installed from `.dvs2` via `just install-cli` (gitignored;
  the justfile prepends it to PATH for every recipe, so rendered bash chunks
  use the same build as the R package)
- `.alx/` — Alexandria config (project ID `22c331d9-0bd0-4e36-b5fd-df81a841a628`, remote https://alx.dev.a2-ai.cloud/api)
- `rproject.toml` — rv config; dvs R package installed from source at `.dvs2/dvs-rpkg`

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

## Updating .dvs2 (the local dvs2 clone)

`.dvs2/` is the dvs2 source clone used for local builds of both the R package
and the CLI. It is **not** tracked by git (`.dvs2/.gitignore` contains `*`).

```bash
just update-dvs    # pull latest main + re-vendor dvs-rpkg (required!)
just install-cli   # cargo install --path .dvs2/dvs-cli --root .  ->  ./bin/dvs
just sync          # rebuild the R package from .dvs2/dvs-rpkg (R 4.5 on PATH)
```

The vendor step matters: dvs-rpkg depends on the in-repo core crate by
workspace path, which does not resolve when rv copies `dvs-rpkg/` to a temp
dir for the build. `just update-dvs` runs `.dvs2`'s own `vendor` recipe
(cargo-revendor) to seal the core crate into `dvs-rpkg/vendor/`. If sync
fails with `failed to load manifest for dependency 'dvs'`, the vendor step
was skipped.

The canonical `rproject.toml` entry is:

```toml
{ name = "dvs", path = ".dvs2/dvs-rpkg" }
```

To test a dvs2 branch instead, point `rproject.toml` at a worktree of that
branch, run its vendor step, `rv sync`, reinstall the CLI from the same
worktree, then clear the freeze cache (`rm -rf _freeze/vignette/<name>`) and
re-render.

## Adding a new vignette

1. Write `vignette/<name>.qmd` with `keep-md: true` and `freeze: auto`
2. Add it to `render` (site chapters, plus the `site-build` MAP) or
   `render-demos` (demos) in the `justfile`
3. Add an `alx publish` line to the `publish` recipe in `justfile`
4. Run `just render-one <name>` then `just publish`
