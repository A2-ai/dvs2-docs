#!/usr/bin/env python3
"""Convert Quarto keep-md output (vignette/<name>.html.md) into Zola content.

Quarto's .html.md is the executed-markdown intermediate of the HTML render. It
carries Pandoc cell markup (``::: {.cell}`` fenced divs, ```` ```{.r .cell-code} ````
fences) and a YAML front matter block. Zola wants CommonMark with a TOML ``+++``
front matter, so we:

  * lift the YAML title/subtitle, emit a TOML front matter with an explicit weight
  * drop the Pandoc ``:::`` div fences (the inner code/output fences are kept)
  * normalise ```` ```{.r .cell-code} ```` (and friends) to a plain ```` ```r ```` info string
  * rewrite ``<name>.html`` cross-links to Zola internal links, honouring the
    name->path map so links survive the vignettes being grouped into sections

Usage: htmlmd_to_zola.py <name> <weight> <src.html.md> <dest.md> [map.json]

map.json maps an original vignette name (the ``<name>`` part of ``<name>.html``)
to its Zola content path without extension, e.g. {"getting-started-cli":
"cli/getting-started"}. ``index`` is special-cased to the site root. Names absent
from the map fall back to ``@/<name>.md``.
"""
import json
import re
import sys


def split_front_matter(text):
    """Return (yaml_dict_subset, body). Only title/subtitle are extracted."""
    meta = {}
    if text.startswith("---\n"):
        end = text.find("\n---", 4)
        if end != -1:
            block = text[4:end]
            body = text[end + 4:].lstrip("\n")
            for line in block.splitlines():
                m = re.match(r'^(title|subtitle):\s*"?(.*?)"?\s*$', line)
                if m:
                    meta[m.group(1)] = m.group(2)
            return meta, body
    return meta, text


# ```{.r .cell-code}  ->  ```r   (also handles {.bash ...}, {.python ...}, {.r})
FENCE_RE = re.compile(r'^(\s*)```\s*\{\.([A-Za-z0-9_+-]+)[^}]*\}\s*$')
# bare ``` { .foo } with no leading language token -> plain ```
FENCE_BARE_RE = re.compile(r'^(\s*)```\s*\{[^}]*\}\s*$')
# Pandoc div fences: ::: or ::: {.cell ...}
DIV_RE = re.compile(r'^\s*:::+\s*(\{[^}]*\})?\s*$')
# cross links: foo.html / foo_bar.html -> internal link
LINK_RE = re.compile(r'\]\(([A-Za-z0-9_-]+)\.html(#[^)]*)?\)')


def make_link_rewriter(linkmap):
    def rewrite(m):
        name, frag = m.group(1), m.group(2) or ""
        if name == "index":
            return f"](/{frag})"
        target = linkmap.get(name, name)
        return f"](@/{target}.md{frag})"
    return rewrite


def convert_body(body, linkmap):
    out = []
    for line in body.splitlines():
        if DIV_RE.match(line):
            continue
        m = FENCE_RE.match(line)
        if m:
            out.append(f"{m.group(1)}```{m.group(2)}")
            continue
        b = FENCE_BARE_RE.match(line)
        if b:
            out.append(f"{b.group(1)}```")
            continue
        out.append(line)
    text = "\n".join(out)
    text = LINK_RE.sub(make_link_rewriter(linkmap), text)
    # collapse 3+ blank lines left behind by stripped divs
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text.strip() + "\n"


def toml_escape(s):
    return s.replace("\\", "\\\\").replace('"', '\\"')


def main():
    name, weight, src, dest = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
    linkmap = {}
    if len(sys.argv) > 5:
        with open(sys.argv[5], encoding="utf-8") as fh:
            linkmap = json.load(fh)
    with open(src, encoding="utf-8") as fh:
        meta, body = split_front_matter(fh.read())
    title = meta.get("title", name)
    desc = meta.get("subtitle", "")
    fm = [
        "+++",
        f'title = "{toml_escape(title)}"',
        f"weight = {weight}",
    ]
    if desc:
        fm.append(f'description = "{toml_escape(desc)}"')
    fm.append("+++\n")
    with open(dest, "w", encoding="utf-8") as fh:
        fh.write("\n".join(fm) + "\n" + convert_body(body, linkmap))


if __name__ == "__main__":
    main()
