# dvs2-demo

Documentation and demonstration repository for [dvs2](https://github.com/A2-ai/dvs2), an independent data version control system by A2-AI. Vignettes are authored in Quarto, rendered to HTML and Markdown, and published two ways: to a [Zola static site on GitHub Pages](https://a2-ai.github.io/dvs2-demo/) and to A2-AI's internal Alexandria (alx) instance. The live site is internal to the A2-AI organization and only accessible to authenticated members.

## dvs2

dvs2 versions large or sensitive files alongside a Git repository without storing their content in Git. The core workflow is four commands: `dvs init` to set up storage, `dvs add` to track a file, `dvs status` to compare local and stored states, and `dvs get` to retrieve files from storage. dvs works with or without Git and uses content-addressed storage. It ships as both a Rust CLI binary and an R package.

## Layout

```
vignette/       Quarto .qmd sources; each renders to .html + .html.md (keep-md: true)
R/              Helper scripts used by vignettes
site/           Zola static site (config.toml, templates, sass, content/)
tools/          htmlmd_to_zola.py, converts vignette .html.md to Zola pages
.alx/           Alexandria config (project ID 22c331d9-0bd0-4e36-b5fd-df81a841a628)
rproject.toml   rv-managed R environment; dvs installed from .dvs/dvs-rpkg
justfile        All build recipes
```

`.dvs/` holds a local clone of the dvs2 source used to build the R package. It is not tracked by git.

## Docs pipeline

1. Quarto renders each `vignette/<name>.qmd` to `vignette/<name>.html` and `vignette/<name>.html.md` (`keep-md: true`).
2. `just site-build` runs `tools/htmlmd_to_zola.py` on each `.html.md` to produce a Zola content page, then calls `zola build` to produce `site/public/`.
3. GitHub Actions (`pages.yml`) triggers on pushes to `main` that touch `site/`, `vignette/`, or related files, runs `just site-build`, and deploys `site/public/` to GitHub Pages.
4. `just publish` calls `alx publish` for each vignette, uploading the `.html` as the main artifact and `.html.md` as a secondary artifact (`-I`).

## Key recipes

```bash
just render              # render all vignettes with Quarto
just render-one NAME     # render a single vignette, e.g. just render-one error
just preview NAME        # live-preview a vignette in the browser
just site-build          # generate site/content from .html.md files, then zola build
just site-serve          # site-build + zola serve --open (local preview)
just publish             # publish all vignettes to alx
just sync                # rv sync (install/update R packages)
just bootstrap           # clone .dvs, install cargo-revendor, run rv sync
just clone-dvs           # clone dvs2 source into .dvs/
just update-dvs          # pull latest dvs2 source (git -C .dvs pull --rebase)
just install-cli         # cargo install the dvs CLI from .dvs/dvs-cli
just clean               # remove rendered artefacts and generated data
just reset               # clean + drop .dvs clone
```

## Rendering and previewing locally

```bash
just bootstrap           # first-time setup: clones .dvs, syncs R packages
just render-one intro    # render one vignette
just site-serve          # build the Zola site and open it in the browser
```

## Testing a dvs2 branch

Point `rproject.toml` at the branch worktree instead of `.dvs`:

```toml
{ name = "dvs", path = "/path/to/dvs2-worktrees/<branch>/dvs-rpkg" }
```

Install the CLI from the same worktree:

```bash
cd /path/to/dvs2-worktrees/<branch> && just install-cli
```

Clear the freeze cache for the vignette and re-render:

```bash
rm -rf _freeze/vignette/<name>
just render-one <name>
```

Always run `rv sync` after changing the path in `rproject.toml` before rendering.

## Adding a vignette

1. Write `vignette/<name>.qmd` with `keep-md: true` and `freeze: auto`.
2. Add `quarto render vignette/<name>.qmd` to the `render` recipe in `justfile`.
3. Add an entry to the `MAP` array in the `site-build` recipe (section and weight).
4. Add an `alx publish` line to the `publish` recipe.
5. Run `just render-one <name>` then `just site-build` to verify, then `just publish`.

## Links

- dvs2 source: https://github.com/A2-ai/dvs2
- Live docs site (A2-AI internal): https://a2-ai.github.io/dvs2-demo/
