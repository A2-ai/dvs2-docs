# dvs2-demo

Vignette repo for [dvs2](https://github.com/A2-ai/dvs2). Demonstrates the dvs R package and CLI side-by-side.

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
