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
    alx publish vignette/index.html           -S vignette/index.qmd                                   -I vignette/index.html.md           -t index           --overwrite --skip-warnings --no-prompt
    alx publish vignette/intro.html           -S vignette/intro.qmd           -S R/mkdatasetfiles.R   -I vignette/intro.html.md           -t intro           --overwrite --skip-warnings --no-prompt
    alx publish vignette/intro-cli.html       -S vignette/intro-cli.qmd       -S R/mkdatasetfiles.R   -I vignette/intro-cli.html.md       -t intro-cli       --overwrite --skip-warnings --no-prompt
    alx publish vignette/intro-internals.html -S vignette/intro-internals.qmd -S R/mkdatasetfiles.R   -I vignette/intro-internals.html.md -t intro-internals --overwrite --skip-warnings --no-prompt
    alx publish vignette/lifecycle.html       -S vignette/lifecycle.qmd       -S R/mkdatasetfiles.R   -I vignette/lifecycle.html.md       -t lifecycle       --overwrite --skip-warnings --no-prompt
    alx publish vignette/collab.html          -S vignette/collab.qmd          -S R/mkdatasetfiles.R   -I vignette/collab.html.md          -t collab          --overwrite --skip-warnings --no-prompt
    alx publish vignette/config.html          -S vignette/config.qmd          -S R/mkdatasetfiles.R   -I vignette/config.html.md          -t config          --overwrite --skip-warnings --no-prompt
    alx publish vignette/audit.html           -S vignette/audit.qmd           -S R/mkdatasetfiles.R   -I vignette/audit.html.md           -t audit           --overwrite --skip-warnings --no-prompt
    alx publish vignette/error.html           -S vignette/error.qmd                                   -I vignette/error.html.md           -t error           --overwrite --skip-warnings --no-prompt
    alx publish vignette/random_files.html    -S vignette/random_files.qmd    -S R/mkdatasetfiles.R   -I vignette/random_files.html.md    -t random_files    --overwrite --skip-warnings --no-prompt
    alx publish vignette/setup.html           -S vignette/setup.qmd                                   -I vignette/setup.html.md           -t setup           --overwrite --skip-warnings --no-prompt
    alx publish vignette/splash.html          -S vignette/splash.qmd          -S vignette/splash.scss                                     -t splash          --overwrite --skip-warnings --no-prompt

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
