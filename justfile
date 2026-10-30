# The dvs CLI is installed into ./bin from the dvs2 commit that rv.lock records
# for the R package (see install-cli). Prepending it here means every recipe
# (and the bash chunks in rendered vignettes) uses the same dvs as the R chunks.
export PATH := justfile_directory() / "bin:" + env_var('PATH')

default:
    @just --list

# === Website (zola) ===
# A dedicated static site built from the rendered vignettes, separate from the
# alx publish. Content is generated from vignette/*.html.md by
# tools/htmlmd_to_zola.py; theming lives in site/ (lifted from miniextendr/site).

# Regenerate site/content from the rendered vignettes and build to site/public.
# Content comes from the committed vignette/<name>.html.md (Quarto keep-md, i.e.
# the executed markdown); tools/htmlmd_to_zola.py converts each to a Zola page.
# The vignettes are grouped into sections (Getting Started, R Package, CLI,
# Internals) via the name->"section/file" map below. Section landing pages
# (_index.md) and about.md are authored and committed, never generated here.
# `splash` is a reveal.js deck and is intentionally excluded.
site-build:
    #!/usr/bin/env bash
    set -euo pipefail

    # "<vignette> <section/file> <in-section weight>"
    # Four sections: Getting Started (install + two walkthroughs), R Package
    # (one page per function, plus the R-only helper utilities), CLI (one page
    # per command), Internals (last). The harvested vignettes (intro, intro-cli,
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
      "r-threads           r-package/threads            5"
      "r-loglevel          r-package/log-level          6"
      "r-format-bytes      r-package/format-bytes       7"
      "r-bytes             r-package/bytes              8"
      "r-version           r-package/version            9"
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

# Build the dvs rustdoc into site/static/rustdoc, mirroring the CI step in
# .github/workflows/pages.yml (deps included for the complete picture). The
# source is the dvs2 commit in rv.lock, fetched into .dvs2-src (gitignored, a
# cache the recipe resets). Placed in static/ so zola build/serve/check all
# pick it up at /rustdoc/ automatically. The dir is gitignored. CI builds its
# own copy.
#
# Nightly + -Z unstable-options theme the docs to match the Zola site:
# --extend-css overrides rustdoc's per-theme color/font variables, and
# --html-before-content injects a "back to docs" banner (site/rustdoc/).
site-rustdoc:
    #!/usr/bin/env bash
    set -euo pipefail
    dvs_src=.dvs2-src
    [ -d "$dvs_src/.git" ] || git init -q "$dvs_src"
    git -C "$dvs_src" fetch -q --depth 1 https://github.com/A2-ai/dvs2 "$(just dvs-sha)"
    git -C "$dvs_src" checkout -q --force --detach FETCH_HEAD
    # Keep the build next to the source. A target-dir in the user's cargo
    # config would otherwise get the docs, and the clean below.
    export CARGO_TARGET_DIR="$PWD/$dvs_src/target"
    export RUSTDOCFLAGS="-Z unstable-options --default-setting use-system-theme=true \
      --extend-css $PWD/site/rustdoc/zola.css \
      --html-before-content $PWD/site/rustdoc/banner.html"
    # cargo fingerprints RUSTDOCFLAGS but not the css/banner file contents, so
    # editing them alone won't trigger a rebuild. Clean the doc output first.
    cargo +nightly clean --doc --manifest-path "$dvs_src/Cargo.toml"
    cargo +nightly doc -p dvs --manifest-path "$dvs_src/Cargo.toml"
    rm -rf site/static/rustdoc && mkdir -p site/static/rustdoc
    cp -r "$dvs_src/target/doc/." site/static/rustdoc/

# Build the Starlight (Astro) R-package reference into site/static/r, mirroring
# the CI step in .github/workflows/pages.yml. Placed in static/ so zola
# serve/build/check pick it up at /r/ automatically. Base is /r/ for local
# serving (CI uses /dvs2-docs/r/). The dir is gitignored; CI builds its own
# copy into public/r. Plain Astro project: uses bun (matches the committed
# bun.lock; sharp's prebuilt binaries resolve under bun but not always npm).
site-r:
    #!/usr/bin/env bash
    set -euo pipefail
    cd starlight
    bun install
    ASTRO_SITE=http://127.0.0.1:1111 ASTRO_BASE=/r/ bun run build
    cd ..
    rm -rf site/static/r && mkdir -p site/static/r
    cp -r starlight/dist/. site/static/r/

# Build rustdoc + Starlight + site, then verify all links (resolve at
# /rustdoc/ and /r/).
site-check: site-rustdoc site-r site-build
    cd site && zola check

# Build the Starlight R docs (/r/) and the site, then live-preview in a browser.
# Rustdoc (/rustdoc/) is heavier (nightly + a dvs2 checkout). Run `just site-rustdoc`
# separately if you need it in the preview.
site-serve: site-r site-build
    cd site && zola serve --open

# === Vignettes ===

# Render the demo vignettes (published to alx, not on the Zola site):
# intro (lightweight quickstart), then the in-depth R / CLI intros and collab
render-demos:
    quarto render vignette/intro.qmd
    quarto render vignette/intro-r.qmd
    quarto render vignette/intro-cli.qmd
    quarto render vignette/collab.qmd

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

# Open the rendered demo HTMLs
open:
    open vignette/intro.html vignette/intro-r.html vignette/intro-cli.html vignette/collab.html

# Publish all rendered vignettes to alx.dev.a2-ai.cloud (dvs2-demo project).
# Titles carry a 0-padded reading-order prefix so alx sorts them; a shared
# number marks a fork (equivalent alternatives: R or CLI, take your pick).
publish:
    alx publish vignette/splash.html               -S vignette/splash.qmd          -S vignette/splash.scss                                          -t 00-splash               --overwrite --skip-warnings --no-prompt
    alx publish showcase/dvs-showcase.html         -S showcase/build.py                                                                             -t 01-showcase             --overwrite --skip-warnings --no-prompt
    alx publish vignette/intro.html                -S vignette/intro.qmd                                   -I vignette/intro.html.md                -t 02-intro                --overwrite --skip-warnings --no-prompt
    alx publish vignette/intro-r.html              -S vignette/intro-r.qmd         -S R/mkdatasetfiles.R   -I vignette/intro-r.html.md              -t 03-intro-r              --overwrite --skip-warnings --no-prompt
    alx publish vignette/intro-cli.html            -S vignette/intro-cli.qmd       -S R/mkdatasetfiles.R   -I vignette/intro-cli.html.md            -t 03-intro-cli            --overwrite --skip-warnings --no-prompt
    alx publish vignette/collab.html               -S vignette/collab.qmd          -S R/mkdatasetfiles.R   -I vignette/collab.html.md               -t 04-collab               --overwrite --skip-warnings --no-prompt
    alx publish vignette/getting-started.html      -S vignette/getting-started.qmd                         -I vignette/getting-started.html.md      -t 05-getting-started      --overwrite --skip-warnings --no-prompt
    alx publish vignette/getting-started-cli.html  -S vignette/getting-started-cli.qmd                     -I vignette/getting-started-cli.html.md  -t 05-getting-started-cli  --overwrite --skip-warnings --no-prompt
    alx publish vignette/r-init.html               -S vignette/r-init.qmd                                  -I vignette/r-init.html.md               -t 06-r-init               --overwrite --skip-warnings --no-prompt
    alx publish vignette/cli-init.html             -S vignette/cli-init.qmd                                -I vignette/cli-init.html.md             -t 06-cli-init             --overwrite --skip-warnings --no-prompt
    alx publish vignette/r-add.html                -S vignette/r-add.qmd                                   -I vignette/r-add.html.md                -t 07-r-add                --overwrite --skip-warnings --no-prompt
    alx publish vignette/cli-add.html              -S vignette/cli-add.qmd                                 -I vignette/cli-add.html.md              -t 07-cli-add              --overwrite --skip-warnings --no-prompt
    alx publish vignette/r-status.html             -S vignette/r-status.qmd                                -I vignette/r-status.html.md             -t 08-r-status             --overwrite --skip-warnings --no-prompt
    alx publish vignette/cli-status.html           -S vignette/cli-status.qmd                              -I vignette/cli-status.html.md           -t 08-cli-status           --overwrite --skip-warnings --no-prompt
    alx publish vignette/r-get.html                -S vignette/r-get.qmd                                   -I vignette/r-get.html.md                -t 09-r-get                --overwrite --skip-warnings --no-prompt
    alx publish vignette/cli-get.html              -S vignette/cli-get.qmd                                 -I vignette/cli-get.html.md              -t 09-cli-get              --overwrite --skip-warnings --no-prompt
    alx publish vignette/r-threads.html            -S vignette/r-threads.qmd                               -I vignette/r-threads.html.md            -t 10-r-threads            --overwrite --skip-warnings --no-prompt
    alx publish vignette/r-loglevel.html           -S vignette/r-loglevel.qmd                              -I vignette/r-loglevel.html.md           -t 11-r-loglevel           --overwrite --skip-warnings --no-prompt
    alx publish vignette/r-format-bytes.html       -S vignette/r-format-bytes.qmd                          -I vignette/r-format-bytes.html.md       -t 12-r-format-bytes       --overwrite --skip-warnings --no-prompt
    alx publish vignette/r-bytes.html              -S vignette/r-bytes.qmd                                 -I vignette/r-bytes.html.md              -t 13-r-bytes              --overwrite --skip-warnings --no-prompt
    alx publish vignette/r-version.html            -S vignette/r-version.qmd                               -I vignette/r-version.html.md            -t 14-r-version            --overwrite --skip-warnings --no-prompt
    alx publish vignette/intro-internals.html      -S vignette/intro-internals.qmd -S R/mkdatasetfiles.R   -I vignette/intro-internals.html.md      -t 15-intro-internals      --overwrite --skip-warnings --no-prompt
    alx publish vignette/config.html               -S vignette/config.qmd                                  -I vignette/config.html.md               -t 16-config               --overwrite --skip-warnings --no-prompt
    alx publish vignette/audit.html                -S vignette/audit.qmd           -S R/mkdatasetfiles.R   -I vignette/audit.html.md                -t 17-audit                --overwrite --skip-warnings --no-prompt
    alx publish vignette/error.html                -S vignette/error.qmd                                   -I vignette/error.html.md                -t 18-error                --overwrite --skip-warnings --no-prompt

# Rebuild the showcase page from the committed captures + screenshots
showcase:
    python3 showcase/build.py

# === rv / R package management ===

# rv init
rv-init:
    rv init

# rv add the dvs package from dvs2 at a commit (rproject.toml pins it the same way)
add-dvs commit:
    rv add dvs --git https://github.com/A2-ai/dvs2 --directory dvs-rpkg --commit {{commit}}

# rv add vignette + helper dependencies
add-deps:
    rv add usethis quarto here stringr stringi dplyr

# rv sync
sync:
    rv sync

# === dvs version ===
# rproject.toml pins the dvs R package to a dvs2 commit (a git dependency with
# `directory = "dvs-rpkg"`, so rv runs dvs-rpkg's bootstrap.R in its checkout
# to stage the core crate). rv.lock records the commit. The CLI and the
# rustdoc build read it from there, so all three show the same dvs.

# Print the dvs2 commit that rv.lock records for the dvs R package
[private]
dvs-sha:
    #!/usr/bin/env bash
    set -euo pipefail
    sha=$(grep -A2 '^name = "dvs"$' rv.lock | grep -o 'sha = "[0-9a-f]*"' | cut -d'"' -f2)
    [ -n "$sha" ] || { echo "rv.lock has no git commit for dvs. Is rproject.toml pointing at a path?" >&2; exit 1; }
    echo "$sha"

# Move the dvs pin to the tip of a dvs2 branch: rewrite the commit in
# rproject.toml, rebuild the R package (R 4.5 on PATH), then the CLI.
update-dvs branch="main":
    #!/usr/bin/env bash
    set -euo pipefail
    sha=$(git ls-remote https://github.com/A2-ai/dvs2 "refs/heads/{{branch}}" | cut -f1)
    [ -n "$sha" ] || { echo "dvs2 has no branch {{branch}}" >&2; exit 1; }
    perl -pi -e "s{(name = \"dvs\", git = \"https://github.com/A2-ai/dvs2\", commit = \")[0-9a-f]+}{\${1}$sha}" rproject.toml
    grep -q "commit = \"$sha\"" rproject.toml || { echo "rproject.toml has no dvs commit pin to move" >&2; exit 1; }
    rv sync
    just install-cli

# Install the dvs CLI into ./bin (kept on PATH above) from the dvs2 commit in
# rv.lock. With a path (a local dvs2 checkout), install from that instead.
install-cli path="":
    #!/usr/bin/env bash
    set -euo pipefail
    if [ -n "{{path}}" ]; then
        cargo install --locked --force --path "{{path}}/dvs-cli" --root .
    else
        cargo install --locked --git https://github.com/A2-ai/dvs2 --rev "$(just dvs-sha)" --root . dvs-cli
    fi

# === Bootstrap ===

# Bootstrap a brand-new sibling project (equivalent to dev/LOG.R)
new-project NAME:
    mkdir {{NAME}}
    cd {{NAME}} && Rscript -e 'usethis::create_project(".")'
    cd {{NAME}} && rv init
    cd {{NAME}} && rv add dvs --git https://github.com/A2-ai/dvs2 --directory dvs-rpkg --commit "$(just dvs-sha)"
    cd {{NAME}} && rv add usethis quarto here stringr stringi dplyr
    cd {{NAME}} && rv sync

# Bootstrap the current project from scratch (R packages, then the CLI)
bootstrap:
    just sync
    just install-cli

# === Housekeeping ===

# Remove rendered artefacts and generated data
clean:
    rm -rf vignette/*.html vignette/*_files tmp_random_files _freeze .quarto

# Full reset: clean + drop the installed CLI and the rustdoc source
reset: clean
    rm -rf bin .crates.toml .crates2.json .dvs2-src

# Show tree respecting .treeignore
tree *ARGS:
    tree --gitfile .treeignore {{ARGS}}
