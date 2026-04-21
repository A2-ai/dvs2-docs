default:
    @just --list

# Render all vignettes
render:
    quarto render vignette/intro.qmd
    quarto render vignette/intro-internals.qmd
    quarto render vignette/random_files.qmd
    quarto render vignette/setup.qmd

# Render a single vignette (e.g. `just render-one intro`)
render-one NAME:
    quarto render vignette/{{NAME}}.qmd

# Clone the dvs2 source into .dvs (required for rv to build dvs-rpkg from source)
clone-dvs:
    gh repo clone A2-ai/dvs2 .dvs -- --single-branch --depth=1
    echo '*' > .dvs/.gitignore

# Pull the latest dvs2 source
update-dvs:
    cd .dvs && git pull --rebase

# Sync R packages via rv
sync:
    rv sync

# Initial project bootstrap: clone dvs source, install cargo-revendor, sync
init:
    just clone-dvs
    cargo install --locked --force --git https://github.com/A2-ai/miniextendr cargo-revendor
    just sync

# Remove rendered artefacts and generated data
clean:
    rm -rf vignette/*.html vignette/*_files tmp_random_files _freeze .quarto
