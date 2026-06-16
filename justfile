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
    # Getting Started holds install (in its _index.md) + the two light Theoph
    # walkthroughs. The R Package / CLI / Reference sections hold the in-depth
    # chapters. The `setup` bootstrap doc and `index`/`splash` are excluded.
    MAP=(
      "getting-started-cli getting-started/cli          1"
      "getting-started     getting-started/r            2"
      "intro               r-package/intro              1"
      "lifecycle           r-package/lifecycle          2"
      "collab              r-package/collab             3"
      "random_files        r-package/random-files       4"
      "intro-cli           cli/intro                    1"
      "intro-internals     reference/internals          1"
      "config              reference/config             2"
      "audit               reference/audit              3"
      "error               reference/error              4"
    )

    # name->path JSON map so the converter can rewrite <name>.html cross-links
    # to the new section paths (index is special-cased to the site root).
    MAPFILE=$(mktemp -t dvs-zola-map)
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

# Build (via site-build), then live-preview the site in a browser
site-serve: site-build
    cd site && zola serve --open

# === Vignettes ===

# Render all vignettes
render:
    quarto render vignette/index.qmd
    quarto render vignette/getting-started.qmd
    quarto render vignette/getting-started-cli.qmd
    quarto render vignette/intro.qmd
    quarto render vignette/intro-cli.qmd
    quarto render vignette/intro-internals.qmd
    quarto render vignette/lifecycle.qmd
    quarto render vignette/collab.qmd
    quarto render vignette/config.qmd
    quarto render vignette/audit.qmd
    quarto render vignette/error.qmd
    quarto render vignette/random_files.qmd
    quarto render vignette/setup.qmd
    quarto render vignette/splash.qmd

# Render a single vignette (e.g. `just render-one intro`)
render-one NAME:
    quarto render vignette/{{NAME}}.qmd

# Live-preview a vignette in the browser
preview NAME:
    quarto preview vignette/{{NAME}}.qmd

# Open all rendered HTMLs
open:
    open vignette/index.html vignette/intro.html vignette/intro-cli.html vignette/intro-internals.html vignette/lifecycle.html vignette/collab.html vignette/config.html vignette/audit.html vignette/error.html vignette/random_files.html vignette/setup.html vignette/splash.html

# Publish all rendered vignettes to alx.dev.a2-ai.cloud (dvs2-demo project)
publish:
    alx publish vignette/index.html                -S vignette/index.qmd                                   -I vignette/index.html.md                -t index                --overwrite --skip-warnings --no-prompt
    alx publish vignette/getting-started.html      -S vignette/getting-started.qmd                         -I vignette/getting-started.html.md      -t getting-started      --overwrite --skip-warnings --no-prompt
    alx publish vignette/getting-started-cli.html  -S vignette/getting-started-cli.qmd                     -I vignette/getting-started-cli.html.md  -t getting-started-cli  --overwrite --skip-warnings --no-prompt
    alx publish vignette/intro.html                -S vignette/intro.qmd           -S R/mkdatasetfiles.R   -I vignette/intro.html.md                -t intro                --overwrite --skip-warnings --no-prompt
    alx publish vignette/intro-cli.html            -S vignette/intro-cli.qmd       -S R/mkdatasetfiles.R   -I vignette/intro-cli.html.md            -t intro-cli            --overwrite --skip-warnings --no-prompt
    alx publish vignette/intro-internals.html      -S vignette/intro-internals.qmd -S R/mkdatasetfiles.R   -I vignette/intro-internals.html.md      -t intro-internals      --overwrite --skip-warnings --no-prompt
    alx publish vignette/lifecycle.html            -S vignette/lifecycle.qmd       -S R/mkdatasetfiles.R   -I vignette/lifecycle.html.md            -t lifecycle            --overwrite --skip-warnings --no-prompt
    alx publish vignette/collab.html               -S vignette/collab.qmd          -S R/mkdatasetfiles.R   -I vignette/collab.html.md               -t collab               --overwrite --skip-warnings --no-prompt
    alx publish vignette/config.html               -S vignette/config.qmd          -S R/mkdatasetfiles.R   -I vignette/config.html.md               -t config               --overwrite --skip-warnings --no-prompt
    alx publish vignette/audit.html                -S vignette/audit.qmd           -S R/mkdatasetfiles.R   -I vignette/audit.html.md                -t audit                --overwrite --skip-warnings --no-prompt
    alx publish vignette/error.html                -S vignette/error.qmd                                   -I vignette/error.html.md                -t error                --overwrite --skip-warnings --no-prompt
    alx publish vignette/random_files.html         -S vignette/random_files.qmd    -S R/mkdatasetfiles.R   -I vignette/random_files.html.md         -t random_files         --overwrite --skip-warnings --no-prompt
    alx publish vignette/setup.html                -S vignette/setup.qmd                                   -I vignette/setup.html.md                -t setup                --overwrite --skip-warnings --no-prompt
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
