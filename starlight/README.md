# dvs R package docs — Starlight site

A [Starlight](https://starlight.astro.build/) documentation site for the **dvs**
R package, generated from the package's `man/` Rd files and README with
[starlightr](https://github.com/A2-ai/starlightr).

This is an alternative to the Quarto→Zola site in the repo root. It is not yet
wired into the GitHub Pages deploy (`.github/workflows/pages.yml` still serves
the Zola site); switching the live deploy is a separate decision.

## Develop / build

```bash
cd starlight
bun install
bun run dev      # local preview at http://localhost:4321
bun run build    # static build into dist/
```

The build reads `ASTRO_SITE` / `ASTRO_BASE` env vars for the deployed URL, e.g.

```bash
ASTRO_SITE="https://a2-ai.github.io" ASTRO_BASE="/dvs2-docs/" bun run build
```

## Regenerating from the R package

The content under `src/content/docs/` is generated — edit the R package docs
(`dvs-rpkg/man/*.Rd`, `README.md`) or the sidebar/home config in
`_starlightr.toml`, then re-run:

```r
# with starlightr installed and the dvs package installed
starlightr::build_site(
  pkg = "path/to/dvs-rpkg",
  config_file = "_starlightr.toml",
  output_dir = "path/to/dvs2-docs/starlight"
)
```

`_starlightr.toml` in this directory is the config used to generate the site
(site metadata, hero/cards, and the reference/articles sidebar grouping).
