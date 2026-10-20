#!/usr/bin/env python3
"""Renders a share image per page into images/og/, from the page's <h1> and eyebrow.

    python3 site/_build/render.py && python3 site/_build/og_pages.py && python3 site/_build/render.py

render.py points a page's og:image at images/og/<slug>.png when that file exists, so run it again after
adding a page. The homepage keeps images/og.png (from og.html). Needs Google Chrome.
"""
import glob
import html
import os
import re
import subprocess
import tempfile

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
SECTIONS = {"limits": "Limits", "guides": "Guide", "compare": "Compare", "alternatives": "Compare"}

TEMPLATE = """<!doctype html><html><head><meta charset="utf-8"><style>
* {{ box-sizing: border-box; }}
html, body {{ margin: 0; width: 1200px; height: 630px; overflow: hidden; }}
body {{ position: relative; background: #f5f6f8; color: #1d1d1f; letter-spacing: -0.012em;
  font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display", system-ui, sans-serif; -webkit-font-smoothing: antialiased; }}
.sky i {{ position: absolute; border-radius: 50%; opacity: 0.85; }}
.sky i:nth-child(1) {{ width: 760px; height: 760px; left: -220px; top: -260px; background: radial-gradient(circle, #ffc98a, transparent 68%); }}
.sky i:nth-child(2) {{ width: 640px; height: 640px; right: -160px; top: -240px; background: radial-gradient(circle, #ffe3a3, transparent 68%); }}
.sky i:nth-child(3) {{ width: 600px; height: 600px; left: 380px; top: 250px; background: radial-gradient(circle, #c9e6ff, transparent 68%); }}
.sky i:nth-child(4) {{ width: 520px; height: 520px; right: -60px; top: 230px; background: radial-gradient(circle, #ffd3c4, transparent 68%); }}
.card {{ position: absolute; inset: 44px 52px; border-radius: 44px; padding: 56px 64px; display: flex; flex-direction: column;
  justify-content: space-between; background: rgba(255,255,255,0.58);
  box-shadow: inset 0 1px 0 rgba(255,255,255,0.9), 0 1px 2px rgba(55,30,15,0.05), 0 14px 40px rgba(55,30,15,0.10); }}
.brand {{ display: flex; align-items: center; gap: 16px; font-size: 30px; font-weight: 600; letter-spacing: -0.02em; }}
.brand img {{ width: 64px; height: 64px; }}
.kicker {{ font-size: 22px; font-weight: 600; letter-spacing: 0.08em; text-transform: uppercase; color: #b84c06; }}
h1 {{ font-size: {size}px; line-height: 1.04; font-weight: 700; margin: 14px 0 0; letter-spacing: -0.04em; max-width: 1000px; }}
h1 em {{ font-style: normal; color: #e8670c; }}
.url {{ font-size: 24px; color: #6e6e73; }}
</style></head><body>
<div class="sky"><i></i><i></i><i></i><i></i></div>
<div class="card">
  <div class="brand"><img src="file://{icon}" alt="">Fuel Gauge</div>
  <div><div class="kicker">{kicker}</div><h1>{headline}</h1></div>
  <div class="url">fuelgauge.app/{slug}</div>
</div>
</body></html>"""


def text(fragment):
    return html.unescape(re.sub(r"<[^>]+>", "", fragment)).strip()


def headline(page):
    match = re.search(r"<h1[^>]*>(.*?)</h1>", page, re.S)
    if not match:
        return None
    parts = re.split(r"(<em>.*?</em>)", match.group(1).strip(), flags=re.S)
    plain = [html.escape(html.unescape(re.sub(r"<[^>]+>", "", p))) for p in parts]
    return "".join(f"<em>{t}</em>" if p.startswith("<em>") else t for p, t in zip(parts, plain))


def kicker(page, slug):
    match = re.search(r'<div class="eyebrow">(.*?)</div>', page, re.S)
    if match:
        return html.escape(text(match.group(1)))
    return SECTIONS.get(slug.split("/")[0], "Free for Mac")


def main():
    out_dir = os.path.join(ROOT, "images", "og")
    os.makedirs(out_dir, exist_ok=True)
    icon = os.path.join(ROOT, "images", "icon.svg")
    pages = [p for p in glob.glob(os.path.join(ROOT, "**", "*.html"), recursive=True)
             if "/_build/" not in p and os.path.relpath(p, ROOT) != "index.html"]
    for path in sorted(pages):
        slug = os.path.relpath(path, ROOT)[:-5]
        page = open(path).read()
        title = headline(page)
        if not title:
            continue
        length = len(text(title))
        size = 88 if length < 30 else 72 if length < 55 else 58
        source = TEMPLATE.format(icon=icon, kicker=kicker(page, slug), headline=title, slug=slug, size=size)
        image = os.path.join(out_dir, slug.replace("/", "-") + ".png")
        with tempfile.NamedTemporaryFile("w", suffix=".html", delete=False) as tmp:
            tmp.write(source)
        subprocess.run([CHROME, "--headless", "--hide-scrollbars", f"--screenshot={image}",
                        "--window-size=1200,630", f"file://{tmp.name}"], capture_output=True, check=True)
        os.unlink(tmp.name)
        print(f"{slug}: images/og/{os.path.basename(image)}")


if __name__ == "__main__":
    main()
