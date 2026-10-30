# dvs2-docs

Documentation and demonstration repository for [dvs2](https://github.com/A2-ai/dvs2), an independent data version control system by A2-AI. Vignettes are authored in Quarto and rendered to HTML and Markdown.

This repository serves two things:

- **The documentation site.** The reference chapters (one page per R function and CLI command, plus helpers and internals) build into a [Zola static site on GitHub Pages](https://a2-ai.github.io/dvs2-docs/), which is public. These same chapters are also published to A2-AI's Alexandria (alx) instance.
- **The demo.** The original demonstration vignettes (`intro`, `intro-cli`, `lifecycle`, `collab`, `random_files`) remain in `vignette/` for reference. They are not on the docs site; their content is covered by the reference chapters. They are not published.

## dvs2

dvs2 versions large or sensitive files alongside a Git repository without storing their content in Git. The core workflow is four commands: `dvs init` to set up storage, `dvs add` to track a file, `dvs status` to compare local and stored states, and `dvs get` to retrieve files from storage. dvs works with or without Git and uses content-addressed storage. It ships as both a Rust CLI binary and an R package.

## Layout

```
vignette/       Quarto .qmd sources; each renders to .html + .html.md (keep-md: true)
R/              Helper scripts used by vignettes
site/           Zola static site (config.toml, templates, sass, content/)
tools/          htmlmd_to_zola.py, converts vignette .html.md to Zola pages
.alx/           Alexandria config (project ID 22c331d9-0bd0-4e36-b5fd-df81a841a628)
rproject.toml   rv-managed R environment, dvs from dvs2 at a pinned commit (directory dvs-rpkg)
justfile        All build recipes
```

`rproject.toml` pins the dvs R package to one dvs2 commit, and `rv.lock` records it. `just install-cli` builds the dvs CLI from the same commit into `bin/`, which every recipe puts first on `PATH`. So the R chunks and the bash chunks in the vignettes run the same dvs.

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
just bootstrap           # rv sync, then install-cli
just update-dvs          # move the dvs pin to the tip of dvs2 main, rv sync, install-cli
just install-cli         # build the dvs CLI from the rv.lock commit into bin/
just clean               # remove rendered artefacts and generated data
just reset               # clean + drop bin/ and the rustdoc source in .dvs2-src/
```

Building dvs from source needs Rust and rv newer than 0.22.2 (git dependencies with a `directory`).

## Rendering and previewing locally

```bash
just bootstrap           # first-time setup: R packages and the dvs CLI
just render-one intro    # render one vignette
just site-serve          # build the Zola site and open it in the browser
```

## Testing a dvs2 branch

For a pushed branch, move the pin to its tip. This rewrites the commit in `rproject.toml`, runs `rv sync`, and reinstalls the CLI:

```bash
just update-dvs <branch>
```

For an unpushed worktree, point `rproject.toml` at it and install the CLI from it:

```toml
{ name = "dvs", path = "/path/to/dvs2-worktrees/<branch>", directory = "dvs-rpkg" }
```

```bash
rv sync
just install-cli /path/to/dvs2-worktrees/<branch>
```

Then clear the freeze cache and re-render. With `freeze: auto`, a vignette whose `.qmd` did not change is otherwise served from its old output.

```bash
rm -rf _freeze/vignette/<name>
just render-one <name>
```

Restore the commit pin in `rproject.toml` before committing.

## Adding a vignette

1. Write `vignette/<name>.qmd` with `keep-md: true` and `freeze: auto`.
2. Add `quarto render vignette/<name>.qmd` to the `render` recipe in `justfile`.
3. Add an entry to the `MAP` array in the `site-build` recipe (section and weight).
4. Add an `alx publish` line to the `publish` recipe.
5. Run `just render-one <name>` then `just site-build` to verify, then `just publish`.

## Links

- dvs2 source: https://github.com/A2-ai/dvs2
- Live docs site (public): https://a2-ai.github.io/dvs2-docs/
