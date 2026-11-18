#!/usr/bin/env python3
"""Renders a share image per page into images/og/, from the page's <h1> and eyebrow.

    python3 site/_build/render.py && python3 site/_build/og_pages.py && python3 site/_build/render.py

render.py points a page's og:image at images/og/<slug>.png when that file exists, so run it again after
adding a page. The homepage uses images/og-video.png, the still from site/_og. Needs Google Chrome.
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

TEMPLATE = """<!doctype html><html><head><meta charset="utf-8">
<style>
@font-face {{ font-family: "Barlow"; font-weight: 500; src: url("file://{fonts}/barlow-500.woff2"); }}
@font-face {{ font-family: "Barlow"; font-weight: 600; src: url("file://{fonts}/barlow-600.woff2"); }}
@font-face {{ font-family: "Barlow Semi Condensed"; font-weight: 300; src: url("file://{fonts}/barlow-semi-condensed-300.woff2"); }}
@font-face {{ font-family: "Barlow Semi Condensed"; font-weight: 600; src: url("file://{fonts}/barlow-semi-condensed-600.woff2"); }}
@font-face {{ font-family: "Barlow Semi Condensed"; font-weight: 700; src: url("file://{fonts}/barlow-semi-condensed-700.woff2"); }}
* {{ box-sizing: border-box; }}
html, body {{ margin: 0; width: 1200px; height: 630px; overflow: hidden; }}
body {{ position: relative; color: #161616; font-family: "Barlow", "Helvetica Neue", sans-serif; -webkit-font-smoothing: antialiased;
  background: repeating-linear-gradient(0deg, rgba(255,255,255,.22) 0 1px, rgba(0,0,0,.035) 1px 2px, transparent 2px 3px),
    repeating-linear-gradient(0deg, rgba(0,0,0,.035) 0 1px, transparent 1px 7px),
    linear-gradient(100deg, rgba(255,255,255,0) 18%, rgba(255,255,255,.5) 40%, rgba(255,255,255,0) 64%),
    linear-gradient(180deg, #e7e8e9, #c3c5c7); }}
.screw {{ position: absolute; width: 14px; height: 14px; border-radius: 50%; background: radial-gradient(circle at 40% 35%, #fff, #b9bbbd 45%, #77797b 80%); }}
.card {{ position: absolute; inset: 0; padding: 64px 76px 0; display: flex; flex-direction: column; justify-content: space-between; }}
.brand {{ display: flex; align-items: center; gap: 18px; font: 700 34px/1 "Barlow Semi Condensed", sans-serif; }}
.brand img {{ width: 72px; height: 72px; }}
.kicker {{ display: inline-flex; gap: 14px; align-items: center; font: 600 20px/1 "Barlow Semi Condensed", sans-serif; letter-spacing: .26em;
  text-transform: uppercase; background: #1b1b1b; color: #d8d9da; padding: 10px 16px 10px 14px; border-radius: 3px; }}
.kicker i {{ width: 11px; height: 11px; border-radius: 50%; background: #e06a1b; box-shadow: 0 0 9px #e06a1b; }}
h1 {{ font: 600 {size}px/1.0 "Barlow Semi Condensed", sans-serif; margin: 22px 0 0; max-width: 1040px; text-wrap: balance; }}
h1 em {{ font-style: normal; font-weight: 300; }}
.foot {{ margin: 0 -76px; padding: 20px 76px 22px; background: #1b1b1b; color: #a9abad; font-size: 24px; font-weight: 500; letter-spacing: .02em; }}
</style></head><body>
<span class="screw" style="left:18px;top:18px"></span><span class="screw" style="right:18px;top:18px"></span>
<div class="card">
  <div class="brand"><img src="file://{icon}" alt="">Fuel Gauge</div>
  <div><div class="kicker"><i></i>{kicker}</div><h1>{headline}</h1></div>
  <div class="foot">fuelgauge.app/{slug}</div>
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
        size = 96 if length < 30 else 80 if length < 55 else 64
        source = TEMPLATE.format(icon=icon, fonts=os.path.join(ROOT, "fonts"), kicker=kicker(page, slug), headline=title, slug=slug, size=size)
        image = os.path.join(out_dir, slug.replace("/", "-") + ".png")
        with tempfile.NamedTemporaryFile("w", suffix=".html", delete=False) as tmp:
            tmp.write(source)
        try:
            subprocess.run([CHROME, "--headless", "--hide-scrollbars", f"--screenshot={image}",
                            "--window-size=1200,630", "--virtual-time-budget=4000", f"file://{tmp.name}"], capture_output=True, check=True)
        finally:
            os.unlink(tmp.name)
        if not os.path.exists(image):
            raise SystemExit(f"Chrome didn't write {image}")
        print(f"{slug}: images/og/{os.path.basename(image)}")


if __name__ == "__main__":
    main()
