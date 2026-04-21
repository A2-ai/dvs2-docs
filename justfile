default:
    @just --list

# === Vignettes ===

# Render all vignettes
render:
    quarto render vignette/index.qmd
    quarto render vignette/intro.qmd
    quarto render vignette/intro-cli.qmd
    quarto render vignette/intro-internals.qmd
    quarto render vignette/lifecycle.qmd
    quarto render vignette/collab.qmd
    quarto render vignette/config.qmd
    quarto render vignette/audit.qmd
    quarto render vignette/random_files.qmd
    quarto render vignette/setup.qmd

# Render a single vignette (e.g. `just render-one intro`)
render-one NAME:
    quarto render vignette/{{NAME}}.qmd

# Live-preview a vignette in the browser
preview NAME:
    quarto preview vignette/{{NAME}}.qmd

# Open all rendered HTMLs
open:
    open vignette/index.html vignette/intro.html vignette/intro-cli.html vignette/intro-internals.html vignette/lifecycle.html vignette/collab.html vignette/config.html vignette/audit.html vignette/random_files.html vignette/setup.html

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
