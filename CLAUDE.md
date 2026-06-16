# dvs2-docs

Documentation and demo repo for [dvs2](https://github.com/A2-ai/dvs2). Two roles:

- **Docs site** — the reference chapters (`r-*`, `cli-*`, the helper and internals
  vignettes) build into a Zola site on GitHub Pages
  (https://a2-ai.github.io/dvs2-docs/, public) via `just site-build`, and are
  also published to alx via `just publish`. One page per R function / CLI command.
- **Demo** — the original demonstration vignettes (`intro`, `intro-cli`,
  `lifecycle`, `collab`, `random_files`) stay in `vignette/` for reference. They
  are NOT on the docs site, NOT in the `site-build` MAP, and NOT published; their
  content is folded into the reference chapters.

## Layout

- `vignette/` — quarto `.qmd` sources; each renders to `.html` + `.html.md` (keep-md: true)
- `R/` — helper scripts used by vignettes
- `.alx/` — Alexandria config (project ID `22c331d9-0bd0-4e36-b5fd-df81a841a628`, remote https://alx.dev.a2-ai.cloud/api)
- `rproject.toml` — rv config; dvs R package installed from source

## Key workflows

```bash
just render        # render all vignettes
just render-one NAME  # e.g. just render-one error
just publish       # publish all to alx (includes .html.md as -I artifact)
just sync          # rv sync
```

## Dev: testing a dvs2 branch

Point rproject.toml at the local worktree — do not push and clone:

```toml
{ name = "dvs", path = "/path/to/dvs2-worktrees/<branch>/dvs-rpkg" }
```

Install the CLI from the same worktree:

```bash
cd /path/to/dvs2-worktrees/<branch> && just install-cli
```

Then clear the freeze cache and re-render:

```bash
rm -rf _freeze/vignette/<name>
just render-one <name>
```

## Updating .dvs (the local dvs2 clone)

`.dvs/` is the dvs2 source clone used for local R package builds. It is **not** tracked by git (`.dvs/.gitignore` contains `*`).

To switch it back to main and pull latest:

```bash
git -C .dvs checkout main
git -C .dvs pull --rebase
```

After changing the branch/path in `rproject.toml`, always run `rv sync` before rendering — otherwise the stale compiled package is used.

Install the CLI from the same `.dvs` clone after pulling:

```bash
just install-cli   # runs: cargo install --profile dev-cli --force --locked --path=.dvs/dvs-cli
```

The canonical `rproject.toml` entry for the main-branch local clone is:

```toml
{ name = "dvs", path = ".dvs/dvs-rpkg" }
```

## Adding a new vignette

1. Write `vignette/<name>.qmd` with `keep-md: true` and `freeze: auto`
2. Add `quarto render vignette/<name>.qmd` to the `render` recipe in `justfile`
3. Add an `alx publish` line to the `publish` recipe in `justfile`
4. Run `just render-one <name>` then `just publish`
