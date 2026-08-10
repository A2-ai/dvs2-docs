#!/usr/bin/env python3
"""Build the standalone dvs showcase page (showcase/dvs-showcase.html).

Inputs: the terminal capture texts produced for the screenshot set (committed
alongside this script in captures/) and the rendered PNGs in screenshots/.
Everything is inlined, so the output is a single self-contained HTML file
suitable for `alx publish`.
"""

import base64
import html
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
CAP = ROOT / "showcase" / "captures"
SHOTS = ROOT / "screenshots"
OUT = ROOT / "showcase" / "dvs-showcase.html"


def frame(name: str, prompt: str = "$") -> str:
    """Render a capture text as a styled terminal window."""
    text = (CAP / name).read_text().rstrip("\n")
    lines_html = []
    for line in text.split("\n"):
        esc = html.escape(line)
        if line.startswith(prompt + " "):
            cmd = html.escape(line[len(prompt) + 1 :])
            lines_html.append(
                f'<span class="ln"><span class="pr">{prompt}</span> '
                f'<span class="cmd">{cmd}</span></span>'
            )
        else:
            lines_html.append(f'<span class="ln out">{esc}</span>')
    body = "".join(lines_html)
    return (
        '<figure class="term">'
        '<div class="bar"><i class="d r"></i><i class="d y"></i><i class="d g"></i></div>'
        f"<pre>{body}</pre></figure>"
    )


def png(name: str) -> str:
    data = base64.b64encode((SHOTS / name).read_bytes()).decode()
    return f"data:image/png;base64,{data}"


shots = [
    ("dvs-cli-01-init.png", "init: point the project at shared storage"),
    ("dvs-cli-02-add.png", "add: hash, compress, store, and record a message"),
    ("dvs-cli-03-status-states.png", "status: current, unsynced, and absent at a glance"),
    ("dvs-cli-04-get.png", "get: restore files from storage, verified by hash"),
    ("dvs-git-metadata-vs-blob.png", "what git tracks vs what storage holds"),
    ("dvs-r-session.png", "the same four verbs from an R session"),
]

gallery = "\n".join(
    f'<figure class="shot">'
    f'<img src="{png(f)}" alt="{html.escape(cap)}" loading="lazy">'
    f"<figcaption>{html.escape(cap)}<span class=\"dl\">right-click the image to save it as {html.escape(f)}</span></figcaption></figure>"
    for f, cap in shots
)

page = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>dvs: version your data next to your code</title>
<style>
  :root {{
    --bg: #f7f7f8; --fg: #1c1e21; --muted: #5c6470; --accent: #0b7285;
    --term-bg: #16181d; --term-fg: #d6d8de; --term-out: #9aa0ab;
    --card: #ffffff; --line: #e3e5e9;
  }}
  * {{ box-sizing: border-box; margin: 0; padding: 0; }}
  body {{
    background: var(--bg); color: var(--fg);
    font: 16px/1.65 -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    padding: 0 1.25rem 4rem;
  }}
  main {{ max-width: 880px; margin: 0 auto; }}
  header.hero {{ padding: 3.5rem 0 2rem; border-bottom: 1px solid var(--line); margin-bottom: 2.5rem; }}
  .hero h1 {{ font-size: 2.1rem; line-height: 1.2; letter-spacing: -0.02em; }}
  .hero h1 code {{ font-family: ui-monospace, "SF Mono", Menlo, monospace; color: var(--accent); }}
  .hero p.tag {{ margin-top: .75rem; font-size: 1.15rem; color: var(--muted); max-width: 46rem; }}
  .hero nav {{ margin-top: 1.25rem; display: flex; gap: 1.25rem; flex-wrap: wrap; }}
  .hero nav a {{ color: var(--accent); text-decoration: none; font-weight: 600; }}
  .hero nav a:hover {{ text-decoration: underline; }}
  h2 {{ font-size: 1.45rem; letter-spacing: -0.01em; margin: 3rem 0 .75rem; }}
  h3 {{ font-size: 1.1rem; margin: 2rem 0 .5rem; }}
  p {{ margin: .65rem 0; max-width: 46rem; }}
  p code, li code {{ font-family: ui-monospace, "SF Mono", Menlo, monospace; font-size: .92em;
    background: #eceef1; padding: .1em .35em; border-radius: 4px; }}
  ul {{ margin: .65rem 0 .65rem 1.4rem; max-width: 44rem; }}
  li {{ margin: .3rem 0; }}
  .verbs {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: .9rem; margin: 1.25rem 0; }}
  .verb {{ background: var(--card); border: 1px solid var(--line); border-radius: 10px; padding: .9rem 1rem; }}
  .verb b {{ font-family: ui-monospace, "SF Mono", Menlo, monospace; color: var(--accent); }}
  .verb span {{ display: block; color: var(--muted); font-size: .92rem; margin-top: .2rem; }}
  figure.term {{ margin: 1.25rem 0 1.75rem; border-radius: 10px; overflow: hidden;
    box-shadow: 0 12px 32px rgba(10, 14, 20, .18); border: 1px solid #0c0e12; }}
  .term .bar {{ background: #23262d; padding: .55rem .8rem; display: flex; gap: .45rem; }}
  .term .d {{ width: 12px; height: 12px; border-radius: 50%; display: inline-block; }}
  .term .r {{ background: #ff5f57; }} .term .y {{ background: #febc2e; }} .term .g {{ background: #28c840; }}
  .term pre {{ background: var(--term-bg); color: var(--term-fg); padding: 1.1rem 1.2rem;
    overflow-x: auto; font: 13.5px/1.55 ui-monospace, "SF Mono", Menlo, monospace; }}
  .term .ln {{ display: block; white-space: pre; }}
  .term .pr {{ color: #28c840; font-weight: 700; }}
  .term .cmd {{ color: #eceef1; font-weight: 600; }}
  .term .out {{ color: var(--term-out); }}
  .split {{ display: grid; grid-template-columns: 1fr 1fr; gap: 1.5rem; align-items: start; margin: 1.5rem 0; }}
  @media (max-width: 720px) {{ .split {{ grid-template-columns: 1fr; }} }}
  .box {{ background: var(--card); border: 1px solid var(--line); border-radius: 10px; padding: 1rem 1.1rem; }}
  .box h4 {{ font-size: .95rem; text-transform: uppercase; letter-spacing: .06em; color: var(--muted); margin-bottom: .4rem; }}
  .box p {{ font-size: .95rem; }}
  .gallery {{ display: grid; grid-template-columns: 1fr 1fr; gap: 1.4rem; margin-top: 1.25rem; }}
  @media (max-width: 720px) {{ .gallery {{ grid-template-columns: 1fr; }} }}
  figure.shot img {{ width: 100%; height: auto; border-radius: 8px;
    box-shadow: 0 8px 24px rgba(10, 14, 20, .14); }}
  figure.shot figcaption {{ font-size: .92rem; color: var(--muted); margin-top: .5rem; }}
  figure.shot .dl {{ display: block; font-size: .8rem; color: var(--accent); }}
  footer {{ margin-top: 4rem; padding-top: 1.5rem; border-top: 1px solid var(--line);
    color: var(--muted); font-size: .92rem; }}
  footer a {{ color: var(--accent); }}
</style>
</head>
<body>
<main>

<header class="hero">
  <h1><code>dvs</code>: version your data files next to your code</h1>
  <p class="tag">Analysis projects pair code with data, and git is only good at
  half of that pairing. dvs keeps the data in the project tree, moves the bytes
  to shared storage, and gives git a few hundred bytes of metadata per file to
  track instead.</p>
  <nav>
    <a href="https://a2-ai.github.io/dvs2-docs/">Documentation</a>
    <a href="https://github.com/A2-ai/dvs2">Source (A2-ai/dvs2)</a>
  </nav>
</header>

<section>
  <h2>Four verbs, two surfaces</h2>
  <p>Everything below is a real capture of dvs 0.4.0 running against a project
  with PK datasets. The same four verbs are available as a CLI and as an R
  package, and both operate on the same project interchangeably.</p>
  <div class="verbs">
    <div class="verb"><b>init</b><span>point the project at a shared storage directory</span></div>
    <div class="verb"><b>add</b><span>hash, compress, and store files; write metadata</span></div>
    <div class="verb"><b>status</b><span>compare every tracked file against its metadata</span></div>
    <div class="verb"><b>get</b><span>materialize missing files from storage, hash-verified</span></div>
  </div>
</section>

<section>
  <h2>The loop</h2>
  <h3>1. Initialize once per project</h3>
  <p><code>dvs init</code> writes <code>dvs.toml</code>, the entire project
  configuration. It belongs in git; every clone reads the storage location
  from it.</p>
  {frame("01-init.txt")}

  <h3>2. Add data with a message</h3>
  <p>Each file is hashed (blake3), compressed (zstd), and stored once per
  unique content. Note the sizes: a 2.9&nbsp;KB file stores as 842&nbsp;B.
  The message travels with the data, like a commit message for a dataset.</p>
  {frame("02-add.txt")}

  <h3>3. Status knows three states</h3>
  <p><code>current</code> matches the metadata, <code>unsynced</code> is on
  disk but modified, and <code>absent</code> is tracked but not on disk, the
  state every fresh clone starts in.</p>
  {frame("03-status.txt")}

  <h3>4. Get restores the rest</h3>
  <p>Retrieval is verified against the recorded hash before the file is moved
  into place; a re-add brings a modified file back to <code>current</code>.</p>
  {frame("04-get.txt")}
</section>

<section>
  <h2>What git tracks, what storage holds</h2>
  <div class="split">
    <div class="box">
      <h4>In git</h4>
      <p><code>dvs.toml</code>, one small JSON meta file per data file under
      <code>.dvs/</code>, and the <code>.gitignore</code> entries dvs wrote.
      A complete, versioned description of the data at kilobyte scale.</p>
    </div>
    <div class="box">
      <h4>In storage</h4>
      <p>Content-addressed blobs, named by their hash, compressed, read-only,
      deduplicated across every project and user that shares the storage. Plus
      an append-only audit log of who added what, when.</p>
    </div>
  </div>
  <p>The proof, from the session above: the meta file records the hash, git
  stages only metadata (no CSV in sight), and the blob sits in storage under
  its hash at a third of the original size:</p>
  {frame("05-metadata.txt")}
</section>

<section>
  <h2>The same story from R</h2>
  <p>The R package returns tibbles, so status and results plug straight into
  dplyr pipelines. This is a live console transcript:</p>
  {frame("06-r.txt", prompt=">")}
</section>

<section>
  <h2>Slide-ready captures</h2>
  <p>High-resolution PNG renders of the frames above, ready to drop into a
  deck. Right-click any image to save it (the same files live in the repo
  under <code>screenshots/</code>).</p>
  <div class="gallery">
  {gallery}
  </div>
</section>

<footer>
  <p>dvs is built by <a href="https://a2-ai.com">A2-AI</a>. Full documentation,
  including one page per R function and CLI command, lives at
  <a href="https://a2-ai.github.io/dvs2-docs/">a2-ai.github.io/dvs2-docs</a>.
  The narrative demos (quickstart, R in depth, CLI in depth, collaboration)
  are published alongside this page.</p>
</footer>

</main>
</body>
</html>
"""

OUT.write_text(page)
print(f"wrote {OUT} ({OUT.stat().st_size / 1e6:.1f} MB)")
