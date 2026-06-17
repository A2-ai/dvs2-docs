default:
    @just --list

# === Website (zola) ===
# A dedicated static site built from the rendered vignettes, separate from the
# alx publish. Content is generated from vignette/*.html.md by
# tools/build-site.sh; theming lives in site/ (lifted from miniextendr/site).

# Regenerate site/content from the rendered vignettes and build to site/public.
# Content comes from the committed vignette/<name>.html.md (Quarto keep-md, i.e.
# the executed markdown); tools/htmlmd_to_zola.py converts each to a Zola page.
# The vignettes are grouped into sections (Getting Started, R Package, CLI,
# Reference) via the name->"section/file" map below. Section landing pages
# (_index.md) and about.md are authored and committed, never generated here.
# `splash` is a reveal.js deck and is intentionally excluded.
site-build:
    #!/usr/bin/env bash
    set -euo pipefail

    # "<vignette> <section/file> <in-section weight>"
    # Five sections: Getting Started (install + two walkthroughs), R Package
    # (one page per function), CLI (one page per command), Helpers (R-only
    # utilities), Internals (last). The harvested vignettes (intro, intro-cli,
    # lifecycle, collab, random_files) and the splash deck are excluded.
    MAP=(
      "getting-started     getting-started/r            1"
      "getting-started-cli getting-started/cli          2"
      "r-init              r-package/init               1"
      "r-add               r-package/add                2"
      "r-status            r-package/status             3"
      "r-get               r-package/get                4"
      "cli-init            cli/init                     1"
      "cli-add             cli/add                      2"
      "cli-status          cli/status                   3"
      "cli-get             cli/get                      4"
      "r-threads           helpers/threads              1"
      "r-loglevel          helpers/log-level            2"
      "r-format-bytes      helpers/format-bytes         3"
      "r-bytes             helpers/bytes                4"
      "r-version           helpers/version              5"
      "intro-internals     internals/storage            1"
      "config              internals/config             2"
      "audit               internals/audit              3"
      "error               internals/errors             4"
    )

    # name->path JSON map so the converter can rewrite <name>.html cross-links
    # to the new section paths (index is special-cased to the site root).
    MAPFILE=$(mktemp /tmp/dvs-zola-map-XXXXXX)
    trap 'rm -f "$MAPFILE"' EXIT
    {
      echo "{"
      first=1
      for row in "${MAP[@]}"; do
        set -- $row
        [ $first -eq 1 ] && first=0 || echo ","
        printf '  "%s": "%s"' "$1" "$2"
      done
      echo
      echo "}"
    } > "$MAPFILE"

    echo "==> Cleaning previously generated content (keeping authored _index.md / about.md)"
    find site/content -name '*.md' ! -name '_index.md' ! -name 'about.md' -delete

    echo "==> Generating site/content from vignette/*.html.md"
    for row in "${MAP[@]}"; do
      set -- $row
      name="$1"; path="$2"; weight="$3"
      src="vignette/$name.html.md"
      dest="site/content/$path.md"
      if [ ! -f "$src" ]; then
        echo "    !! missing $src (render it first); skipping" >&2
        continue
      fi
      mkdir -p "$(dirname "$dest")"
      python3 tools/htmlmd_to_zola.py "$name" "$weight" "$src" "$dest" "$MAPFILE"
      echo "    $name -> $path (weight $weight)"
    done

    echo "==> zola build"
    cd site && zola build

# Build the dvs rustdoc into site/static/rustdoc using the local .dvs2 clone,
# mirroring the CI step in .github/workflows/pages.yml (deps included for the
# complete picture). Placed in static/ so zola build/serve/check all pick it up
# at /rustdoc/ automatically. The dir is gitignored; CI builds its own copy.
site-rustdoc dvs_src=".dvs2":
    cargo doc -p dvs --manifest-path {{dvs_src}}/Cargo.toml
    rm -rf site/static/rustdoc && mkdir -p site/static/rustdoc
    cp -r {{dvs_src}}/target/doc/. site/static/rustdoc/

# Build rustdoc + site, then verify all links (rustdoc resolves at /rustdoc/).
site-check: site-rustdoc site-build
    cd site && zola check

# Build (via site-build), then live-preview the site in a browser
site-serve: site-build
    cd site && zola serve --open

# === Vignettes ===

# Render all vignettes that feed the site (one per MAP entry), plus the deck
render:
    quarto render vignette/getting-started.qmd
    quarto render vignette/getting-started-cli.qmd
    quarto render vignette/r-init.qmd
    quarto render vignette/r-add.qmd
    quarto render vignette/r-status.qmd
    quarto render vignette/r-get.qmd
    quarto render vignette/cli-init.qmd
    quarto render vignette/cli-add.qmd
    quarto render vignette/cli-status.qmd
    quarto render vignette/cli-get.qmd
    quarto render vignette/r-threads.qmd
    quarto render vignette/r-loglevel.qmd
    quarto render vignette/r-version.qmd
    quarto render vignette/r-format-bytes.qmd
    quarto render vignette/r-bytes.qmd
    quarto render vignette/intro-internals.qmd
    quarto render vignette/config.qmd
    quarto render vignette/audit.qmd
    quarto render vignette/error.qmd
    quarto render vignette/splash.qmd

# Render a single vignette (e.g. `just render-one intro`)
render-one NAME:
    quarto render vignette/{{NAME}}.qmd

# Live-preview a vignette in the browser
preview NAME:
    quarto preview vignette/{{NAME}}.qmd

# Open all rendered HTMLs
open:
    open vignette/intro.html vignette/intro-cli.html vignette/intro-internals.html vignette/lifecycle.html vignette/collab.html vignette/config.html vignette/audit.html vignette/error.html vignette/random_files.html vignette/splash.html

# Publish all rendered vignettes to alx.dev.a2-ai.cloud (dvs2-demo project)
publish:
    alx publish vignette/getting-started.html      -S vignette/getting-started.qmd                         -I vignette/getting-started.html.md      -t getting-started      --overwrite --skip-warnings --no-prompt
    alx publish vignette/getting-started-cli.html  -S vignette/getting-started-cli.qmd                     -I vignette/getting-started-cli.html.md  -t getting-started-cli  --overwrite --skip-warnings --no-prompt
    alx publish vignette/r-init.html               -S vignette/r-init.qmd                                  -I vignette/r-init.html.md               -t r-init               --overwrite --skip-warnings --no-prompt
    alx publish vignette/r-add.html                -S vignette/r-add.qmd                                   -I vignette/r-add.html.md                -t r-add                --overwrite --skip-warnings --no-prompt
    alx publish vignette/r-status.html             -S vignette/r-status.qmd                                -I vignette/r-status.html.md             -t r-status             --overwrite --skip-warnings --no-prompt
    alx publish vignette/r-get.html                -S vignette/r-get.qmd                                   -I vignette/r-get.html.md                -t r-get                --overwrite --skip-warnings --no-prompt
    alx publish vignette/cli-init.html             -S vignette/cli-init.qmd                                -I vignette/cli-init.html.md             -t cli-init             --overwrite --skip-warnings --no-prompt
    alx publish vignette/cli-add.html              -S vignette/cli-add.qmd                                 -I vignette/cli-add.html.md              -t cli-add              --overwrite --skip-warnings --no-prompt
    alx publish vignette/cli-status.html           -S vignette/cli-status.qmd                              -I vignette/cli-status.html.md           -t cli-status           --overwrite --skip-warnings --no-prompt
    alx publish vignette/cli-get.html              -S vignette/cli-get.qmd                                 -I vignette/cli-get.html.md              -t cli-get              --overwrite --skip-warnings --no-prompt
    alx publish vignette/r-threads.html            -S vignette/r-threads.qmd                               -I vignette/r-threads.html.md            -t r-threads            --overwrite --skip-warnings --no-prompt
    alx publish vignette/r-loglevel.html           -S vignette/r-loglevel.qmd                              -I vignette/r-loglevel.html.md           -t r-loglevel           --overwrite --skip-warnings --no-prompt
    alx publish vignette/r-version.html            -S vignette/r-version.qmd                               -I vignette/r-version.html.md            -t r-version            --overwrite --skip-warnings --no-prompt
    alx publish vignette/r-format-bytes.html       -S vignette/r-format-bytes.qmd                          -I vignette/r-format-bytes.html.md       -t r-format-bytes       --overwrite --skip-warnings --no-prompt
    alx publish vignette/r-bytes.html              -S vignette/r-bytes.qmd                                 -I vignette/r-bytes.html.md              -t r-bytes              --overwrite --skip-warnings --no-prompt
    alx publish vignette/intro-internals.html      -S vignette/intro-internals.qmd -S R/mkdatasetfiles.R   -I vignette/intro-internals.html.md      -t intro-internals      --overwrite --skip-warnings --no-prompt
    alx publish vignette/config.html               -S vignette/config.qmd                                  -I vignette/config.html.md               -t config               --overwrite --skip-warnings --no-prompt
    alx publish vignette/audit.html                -S vignette/audit.qmd           -S R/mkdatasetfiles.R   -I vignette/audit.html.md                -t audit                --overwrite --skip-warnings --no-prompt
    alx publish vignette/error.html                -S vignette/error.qmd                                   -I vignette/error.html.md                -t error                --overwrite --skip-warnings --no-prompt
    alx publish vignette/splash.html               -S vignette/splash.qmd          -S vignette/splash.scss                                          -t splash               --overwrite --skip-warnings --no-prompt

# === rv / R package management ===

# rv init
rv-init:
    rv init

# rv add the dvs package from a local clone at .dvs/dvs-rpkg
add-dvs:
    rv add dvs --git https://github.com/a2-ai/dvs2 --directory dvs-rpkg --branch main

# rv add vignette + helper dependencies
add-deps:
    rv add usethis quarto here stringr stringi dplyr

# rv sync
sync:
    rv sync

# === dvs source repo ===

# Clone dvs2 into .dvs (required to build dvs-rpkg from source via rv)
clone-dvs:
    gh repo clone A2-ai/dvs2 .dvs -- --single-branch --depth=1
    echo '*' > .dvs/.gitignore

# Pull the latest dvs2 source
update-dvs:
    git -C .dvs pull --rebase

# Install the cargo-revendor build helper
install-cargo-revendor:
    cargo install --locked --force --git https://github.com/A2-ai/miniextendr cargo-revendor

# === Bootstrap ===

# Bootstrap a brand-new sibling project (equivalent to dev/LOG.R)
new-project NAME:
    mkdir {{NAME}}
    cd {{NAME}} && Rscript -e 'usethis::create_project(".")'
    cd {{NAME}} && rv init
    cd {{NAME}} && rv add dvs --git https://github.com/a2-ai/dvs2 --directory dvs-rpkg --branch main
    cd {{NAME}} && rv add usethis quarto here stringr stringi dplyr
    cd {{NAME}} && gh repo clone A2-ai/dvs2 .dvs -- --single-branch --depth=1
    cd {{NAME}} && echo '*' > .dvs/.gitignore
    cd {{NAME}} && rv sync

# Bootstrap the current project from scratch (clone dvs, install tooling, sync)
bootstrap:
    just clone-dvs
    just install-cargo-revendor
    just sync

# === Housekeeping ===

# Remove rendered artefacts and generated data
clean:
    rm -rf vignette/*.html vignette/*_files tmp_random_files _freeze .quarto

# Full reset: clean + drop .dvs clone
reset: clean
    rm -rf .dvs

# Show tree respecting .treeignore
tree *ARGS:
    tree --gitfile .treeignore {{ARGS}}
