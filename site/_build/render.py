#!/usr/bin/env python3
"""Renders the limits, guides, and alternatives pages (with their hubs) and /privacy from the data files, rewrites
the homepage nav, footer, and JSON-LD between their markers, and writes sitemap.xml and llms.txt.

    python3 site/_build/render.py
"""
import datetime
import glob
import html
import json
import os
import re
import subprocess
import sys

sys.path.insert(0, os.path.dirname(__file__))
from compare import COMPARES  # noqa: E402
from guides import GUIDES  # noqa: E402
from limits import LIMITS, VERIFIED  # noqa: E402
from pages import CLI, COMPARISONS, PRIVACY  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")
SITE = "https://fuelgauge.app"
DOWNLOAD = "https://github.com/coreyhaines31/fuelgauge/releases/latest/download/FuelGauge.dmg"
REPO = "https://github.com/coreyhaines31/fuelgauge"
BREW = "brew install --cask coreyhaines31/tap/fuelgauge"
INSTALL_PROMPT = ("Install Fuel Gauge on my Mac: run `brew install --cask coreyhaines31/tap/fuelgauge`, open Fuel Gauge, "
                  "then run `fuelgauge install-statusline` and `fuelgauge status`.")
AGENT_RULE = ("Before starting a long or expensive task, run `fuelgauge status`. If it exits with code 2, a Claude Code, "
              "Codex, or Grok Bot limit is forecast to run out before it resets: tell me which one and when, and ask before "
              "starting, or switch to a cheaper model. `fuelgauge status --json` has the details.")

DOWNLOAD_ICON = ('<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 4v11m-5-5 5 5 5-5M5 20h14" fill="none" '
                 'stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/></svg>')
GITHUB_ICON = ('<svg viewBox="0 0 16 16" fill="currentColor" aria-hidden="true"><path d="M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 '
               '5.47 7.59.4.07.55-.17.55-.38 0-.19-.01-.82-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52'
               '-.01-.53.63-.01 1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64-.89-3.64-3.95 0-.87.31-1.59'
               '.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.2.82.64-.18 1.32-.27 2-.27.68 0 1.36.09 2 .27 1.53-1.04 2.2-.82 2.2-.82'
               '.44 1.1.16 1.92.08 2.12.51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 1.93-.01 2.2 0 '
               '.21.15.46.55.38A8.01 8.01 0 0 0 16 8c0-4.42-3.58-8-8-8z"/></svg>')
CTAS = (f'<a class="btn" href="{DOWNLOAD}">{DOWNLOAD_ICON}Download for Mac</a>\n'
        f'        <a class="btn-quiet" href="{REPO}">{GITHUB_ICON}View source code</a>')
FONTS = "https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap"

# Corey's other free Mac apps, cross-linked from every footer.
FAMILY = [
    ("Midnight Oil", "https://midnightoil.app", "Keep your Mac awake"),
    ("Disk Forecast", "https://diskforecast.com", "Know before your disk is full"),
    ("Spare", "https://spareformac.com", "See what's using your Mac"),
    ("WiFi or ISP", "https://wifiorisp.com", "Is slow internet your Wi-Fi or your ISP?"),
    ("Green Room", "https://greenroomformac.com", "Check your camera, mic, and speakers"),
    ("On Hand", "https://onhandformac.com", "A clipboard manager for your Mac"),
    ("Coat Check", "https://coatcheckformac.com", "Reach the menu bar icons the notch hides"),
]

COPY_SCRIPT = '''  <script>
    // Copy buttons. Falls back to selecting the text when the clipboard is unavailable.
    document.querySelectorAll("[data-copy]").forEach(button => {
      button.addEventListener("click", async () => {
        const source = document.getElementById(button.dataset.copy);
        try {
          await navigator.clipboard.writeText(source.textContent);
          button.textContent = "Copied";
          setTimeout(() => { button.textContent = "Copy"; }, 2000);
        } catch (_) {
          getSelection().selectAllChildren(source);
        }
      });
    });
  </script>
'''


def esc(t):
    return html.escape(t, quote=True)


def share_image(path):
    """The page's own share image from og_pages.py if it has one, else the homepage's."""
    name = "og/" + path.strip("/").replace("/", "-") + ".png"
    return f"{SITE}/images/{name}" if path != "/" and os.path.exists(os.path.join(ROOT, "images", name)) else f"{SITE}/images/og.png"


def head(title, description, path):
    return f'''<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{esc(title)}</title>
  <meta name="description" content="{esc(description)}">
  <link rel="canonical" href="{SITE}{path}">
  <meta property="og:title" content="{esc(title)}">
  <meta property="og:description" content="{esc(description)}">
  <meta property="og:type" content="website">
  <meta property="og:site_name" content="Fuel Gauge">
  <meta property="og:image" content="{share_image(path)}">
  <meta property="og:image:width" content="1200">
  <meta property="og:image:height" content="630">
  <meta property="og:url" content="{SITE}{path}">
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="{esc(title)}">
  <meta name="twitter:description" content="{esc(description)}">
  <meta name="theme-color" content="#fbe9d6" media="(prefers-color-scheme: light)">
  <meta name="theme-color" content="#1a120c" media="(prefers-color-scheme: dark)">
  <link rel="icon" href="/images/icon.svg" type="image/svg+xml">
  <link rel="apple-touch-icon" href="/images/icon.png">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link rel="stylesheet" href="{FONTS}">
  <link rel="stylesheet" href="/site.css">
  <script src="https://cdn.usefathom.com/script.js" data-site="ETCPQLNF" defer></script>
  <script src="https://ingest.getuserproof.com/sdk.js" data-site="eb2393e8-b6bf-405b-a82f-9adf86865677" defer></script>
</head>
<body>
'''


def nav():
    return f'''  <div class="sky" aria-hidden="true"><i></i><i></i><i></i><i></i></div>
  <div class="nav">
    <div class="wrap">
      <a class="brand" href="/"><img src="/images/icon.svg" alt="" width="28" height="28"> Fuel Gauge</a>
      <nav>
        <a href="/#how">How it works</a>
        <a href="/limits">Limits</a>
        <a href="/guides">Guides</a>
        <a href="/compare">Compare</a>
        <a href="/cli">For agents</a>
        <a class="btn" href="{DOWNLOAD}">Download</a>
      </nav>
    </div>
  </div>
'''


def footer_inner():
    limits = "".join(f'<a href="{p["path"]}">{esc(p["short"])}</a>' for p in LIMITS)
    guides = "".join(f'<a href="{p["path"]}">{esc(p["short"])}</a>' for p in GUIDES)
    compare = "".join(f'<a href="{p["path"]}">{esc(p["short"])}</a>' for p in COMPARES)
    compare += "".join(f'<a href="/{p["slug"]}">{esc(p["competitor"])} alternative</a>' for p in COMPARISONS)
    family = "".join(f'<a href="{url}" title="{esc(desc)}">{esc(name)}</a>' for name, url, desc in FAMILY)
    return (f'      <nav class="footer-alts" aria-label="Limits"><a class="label" href="/limits">Limits</a>{limits}</nav>\n'
            f'      <nav class="footer-alts" aria-label="Guides"><a class="label" href="/guides">Guides</a>{guides}</nav>\n'
            f'      <nav class="footer-alts" aria-label="Compare"><a class="label" href="/compare">Compare</a>{compare}</nav>\n'
            f'      <nav class="footer-alts" aria-label="More free Mac apps"><a class="label" href="https://github.com/coreyhaines31">More free Mac apps</a>{family}</nav>\n'
            f'      <div class="footer-links"><span>© 2026 Corey Haines. Source available under the <a href="{REPO}/blob/main/LICENSE">FSL-1.1-MIT License</a>.</span></div>\n'
            f'      <div class="footer-links"><a href="{REPO}">GitHub</a><a href="{REPO}/releases">Releases</a><a href="{REPO}/issues">Issues</a><a href="/privacy">Privacy</a><a href="/llms.txt">llms.txt</a></div>\n')


def footer():
    return f'''  <footer>
    <div class="wrap">
{footer_inner()}    </div>
  </footer>
'''


def homepage():
    with open(os.path.join(ROOT, "index.html")) as f:
        return f.read()


def replace_between(page, start, end, content):
    i, j = page.index(start) + len(start), page.index(end)
    return page[:i] + content + page[j:]


def faq_schema(faqs):
    data = {"@context": "https://schema.org", "@type": "FAQPage", "mainEntity": [
        {"@type": "Question", "name": q, "acceptedAnswer": {"@type": "Answer", "text": a}} for q, a in faqs]}
    return f'<script type="application/ld+json">{json.dumps(data)}</script>'


def render_homepage():
    """The homepage is hand-written. Keep its footer, and its JSON-LD built from its own FAQ, in sync."""
    page = homepage()
    faqs = [(html.unescape(q), html.unescape(re.sub(r"<[^>]+>", "", a)))
            for q, a in re.findall(r"<details><summary>(.*?)</summary><p>(.*?)</p></details>", page)]
    app = {"@context": "https://schema.org", "@type": "SoftwareApplication", "name": "Fuel Gauge",
           "operatingSystem": "macOS 14 or later", "applicationCategory": "DeveloperApplication",
           "offers": {"@type": "Offer", "price": "0", "priceCurrency": "USD"},
           "downloadUrl": DOWNLOAD, "url": f"{SITE}/", "image": f"{SITE}/images/icon.png",
           "author": {"@type": "Person", "name": "Corey Haines"}}
    schema = f'  <script type="application/ld+json">{json.dumps(app)}</script>\n  {faq_schema(faqs)}\n'
    page = replace_between(page, "<!-- footer -->\n", "      <!-- /footer -->", footer_inner())
    page = re.sub(r'  <div class="nav">.*?\n  </div>\n', nav().split('</div>\n', 1)[1], page, count=1, flags=re.S)
    page = replace_between(page, "<!-- schema -->\n", "  <!-- /schema -->", schema)
    with open(os.path.join(ROOT, "index.html"), "w") as f:
        f.write(page)


def breadcrumb_schema(crumbs):
    items = [{"@type": "ListItem", "position": 1, "name": "Fuel Gauge", "item": f"{SITE}/"}]
    items += [{"@type": "ListItem", "position": i + 2, "name": name, "item": f"{SITE}{path}"}
              for i, (name, path) in enumerate(crumbs)]
    data = {"@context": "https://schema.org", "@type": "BreadcrumbList", "itemListElement": items}
    return f'<script type="application/ld+json">{json.dumps(data)}</script>'


def crumbs_html(crumbs):
    """The visible trail above a page's title. The last crumb is the page itself, so it isn't a link."""
    links = [f'<a href="/">Fuel Gauge</a>'] + [f'<a href="{path}">{esc(name)}</a>' for name, path in crumbs[:-1]]
    return f'<nav class="crumbs" aria-label="Breadcrumb">{" <span>›</span> ".join(links)}</nav>'


def write(path, crumbs, body):
    """Writes /a/b as a/b.html, so Vercel's cleanUrls serves it without the extension."""
    body = body.replace("</body>", breadcrumb_schema(crumbs) + "\n</body>", 1)
    target = os.path.join(ROOT, path.strip("/") + ".html")
    os.makedirs(os.path.dirname(target), exist_ok=True)
    with open(target, "w") as f:
        f.write(body)


def table(rows, competitor):
    out = ['        <div class="table-card glass"><div class="table-scroll"><table class="compare">',
           f'          <thead><tr><td></td><th scope="col" class="us">Fuel Gauge</th><th scope="col">{esc(competitor)}</th></tr></thead><tbody>']
    for label, us, them in rows:
        cls = ' class="n"' if them == "—" else ""
        out.append(f'            <tr><th scope="row">{label}</th><td class="us">{us}</td><td{cls}>{them}</td></tr>')
    out.append('          </tbody></table></div></div>')
    out.append(f'        <p class="table-foot">“—” means we couldn\'t confirm it from {esc(competitor)}\'s own materials as of October 2026.</p>')
    return "\n".join(out)


def faq_block(faqs):
    items = "".join(f'          <details><summary>{esc(q)}</summary><p>{esc(a)}</p></details>\n' for q, a in faqs)
    return f'''    <section class="tight lit">
      <div class="wrap">
        <div class="head center head-sm"><h2>Questions</h2></div>
        <div class="faq glass">
{items}        </div>
      </div>
    </section>
'''


def cta(text):
    return f'''    <section class="cta lit">
      <div class="wrap">
        <div class="cta-card glass">
          <img src="/images/icon.svg" alt="" width="96" height="96" loading="lazy">
          <h2>{text}</h2>
          <p>Free. No account, no subscription.</p>
          <div class="actions">
            {CTAS}
          </div>
          <div class="copyline"><code id="brew-cta">{BREW}</code><button type="button" class="copy" data-copy="brew-cta">Copy</button></div>
          <div class="ask">
            <p>Or ask your coding agent:</p>
            <div class="prompt-box">
              <button type="button" class="copy" data-copy="install-prompt">Copy</button>
              <pre id="install-prompt">{esc(INSTALL_PROMPT)}</pre>
            </div>
          </div>
          <p class="fineprint">macOS 14 Sonoma or later · Apple Silicon and Intel</p>
        </div>
      </div>
    </section>
'''


def render_comparison(p):
    path = f"/{p['slug']}"
    crumbs = [("Alternatives", "/alternatives"), (p["card_title"] + " alternative", path)]
    parts = [head(p["title"], p["description"], path), nav(), "  <main>\n"]
    parts.append(f'''    <div class="sub-hero">
      <div class="wrap narrow">
        {crumbs_html(crumbs)}
        <div class="eyebrow">{esc(p["eyebrow"])}</div>
        <h1>{p["h1"]}</h1>
        <p class="lede">{p["lede"]}</p>
        <div class="actions">
          {CTAS}
        </div>
        <div class="tldr glass"><h2>The short version</h2><p>{p["tldr"]}</p></div>
      </div>
    </div>
''')
    for sec in p["sections"]:
        cls = "tight" + (" lit" if sec.get("lit") else "")
        body = sec["html"]
        if sec.get("table"):
            body = body.replace("{{TABLE}}", table(sec["table"], p["competitor"]))
        parts.append(f'    <section class="{cls}" id="{sec["id"]}">\n      <div class="wrap narrow"><div class="prose">\n{body}\n      </div></div>\n    </section>\n')
    parts.append(faq_block(p["faqs"]))
    parts.append(cta(p["cta"]))
    parts.append("  </main>\n")
    parts.append(footer())
    parts.append(COPY_SCRIPT)
    parts.append(faq_schema(p["faqs"]) + "\n</body>\n</html>\n")
    write(path, crumbs, "".join(parts))


def facts_table(rows):
    """A two-column facts table: the answers a limits page exists to give, in a form AI overviews quote."""
    out = ['        <div class="table-card glass"><div class="table-scroll"><table class="compare facts"><tbody>']
    for label, value in rows:
        out.append(f'            <tr><th scope="row">{label}</th><td>{value}</td></tr>')
    out.append('          </tbody></table></div></div>')
    return "\n".join(out)


def related_block(links):
    items = "".join(f'<a class="related-card glass" href="{href}"><strong>{esc(title)}</strong><span>{esc(sub)}</span></a>'
                    for title, sub, href in links)
    return f'''    <section class="tight">
      <div class="wrap narrow">
        <h2 class="related-head">Keep reading</h2>
        <div class="related">{items}</div>
      </div>
    </section>
'''


def render_page(p, crumbs):
    """A limits page or a guide: crumbs, title, short answer, sections, FAQ, related links, and the download CTA."""
    path = p["path"]
    parts = [head(p["title"], p["description"], path), nav(), "  <main>\n"]
    answer = f'<div class="tldr glass"><h2>The short answer</h2><p>{p["answer"]}</p></div>' if p.get("answer") else ""
    parts.append(f'''    <div class="sub-hero">
      <div class="wrap narrow">
        {crumbs_html(crumbs)}
        <div class="eyebrow">{esc(p["eyebrow"])}</div>
        <h1>{p["h1"]}</h1>
        <p class="lede">{p["lede"]}</p>
        {answer}
      </div>
    </div>
''')
    for sec in p["sections"]:
        cls = "tight" + (" lit" if sec.get("lit") else "")
        body = sec["html"]
        if sec.get("facts"):
            body = body.replace("{{FACTS}}", facts_table(sec["facts"]))
        parts.append(f'    <section class="{cls}" id="{sec["id"]}">\n      <div class="wrap narrow"><div class="prose">\n{body}\n      </div></div>\n    </section>\n')
    if p.get("faqs"):
        parts.append(faq_block(p["faqs"]))
    if p.get("related"):
        parts.append(related_block(p["related"]))
    parts.append(cta(p.get("cta", "Know if you&#39;ll make it to reset.")))
    parts.append("  </main>\n")
    parts.append(footer())
    parts.append(COPY_SCRIPT)
    parts.append((faq_schema(p["faqs"]) if p.get("faqs") else "") + "\n</body>\n</html>\n")
    write(path, crumbs, "".join(parts))


def render_hub(path, name, title, description, h1, lede, cards, extra=""):
    """A section's index page: a card per page in it."""
    items = "".join(f'<a class="related-card glass" href="{href}"><strong>{esc(t)}</strong><span>{esc(sub)}</span></a>'
                    for t, sub, href in cards)
    body = f'''{head(title, description, path)}{nav()}  <main>
    <div class="sub-hero">
      <div class="wrap narrow">
        {crumbs_html([(name, path)])}
        <h1>{h1}</h1>
        <p class="lede">{lede}</p>
      </div>
    </div>
    <section class="tight" style="padding-top:0">
      <div class="wrap narrow">
{extra}        <div class="related hub">{items}</div>
      </div>
    </section>
{cta("Know if you&#39;ll make it to reset.")}  </main>
{footer()}{COPY_SCRIPT}</body>
</html>
'''
    write(path, [(name, path)], body)


def render_hubs():
    rows = "".join(f'<tr><th scope="row"><a href="{p["path"]}">{esc(p["short"])}</a></th><td>{p["hub_windows"]}</td>'
                   f'<td>{p["hub_reset"]}</td></tr>' for p in LIMITS)
    limits_table = ('        <div class="table-card glass"><div class="table-scroll"><table class="compare">'
                    '<thead><tr><td></td><th scope="col">Limits</th><th scope="col">Resets</th></tr></thead>'
                    f'<tbody>{rows}</tbody></table></div></div>\n'
                    f'        <p class="table-foot">Checked against each provider\'s own help pages on {VERIFIED}.</p>\n')
    render_hub("/limits", "Limits",
               "AI coding usage limits: Claude, Codex, Cursor, Copilot, Grok",
               "How usage limits work on Claude Pro and Max, Claude Code, Codex, Cursor, Grok, and GitHub Copilot: the windows, when each resets, and how to check.",
               "Usage limits, <em>plan by plan.</em>",
               "What each plan limits, when it resets, and how to see what you have left. Checked against the official help pages.",
               [(p["short"], p["card"], p["path"]) for p in LIMITS], limits_table)
    render_hub("/guides", "Guides",
               "Guides: Claude usage, limit resets, and the status line",
               "Short guides for staying inside your Claude Code and Claude plan limits: checking usage, when limits reset, and the Claude Code status line.",
               "Guides for working <em>inside your limits.</em>",
               "How to check what you have left, when it comes back, and how to keep an eye on it while you work.",
               [(p["short"], p["card"], p["path"]) for p in GUIDES])
    render_hub("/compare", "Compare",
               "Compare AI coding plans: Claude Pro vs Max, and more",
               "Side-by-side comparisons of AI coding plans and their usage limits, plus how Fuel Gauge compares with other usage trackers.",
               "Compare plans <em>and tools.</em>",
               "Which plan gives you enough room, and which tool keeps an eye on it.",
               [(p["short"], p["card"], p["path"]) for p in COMPARES]
               + [("Usage tracker alternatives", "CodexBar, ccusage, ccstatusline", "/alternatives")])
    render_hub("/alternatives", "Alternatives",
               "Fuel Gauge compared: CodexBar, ccusage, ccstatusline",
               "How Fuel Gauge compares with CodexBar, ccusage, and ccstatusline for keeping an eye on Claude Code and Codex usage.",
               "How Fuel Gauge <em>compares.</em>",
               "Other good tools track AI coding usage. Here's what each does best, and where Fuel Gauge is different.",
               [(p["competitor"] + " alternative", p["card"], "/" + p["slug"]) for p in COMPARISONS])


def render_privacy():
    d = PRIVACY
    body = f'''{head(d["title"], d["description"], d["path"])}{nav()}  <main>
    <div class="sub-hero">
      <div class="wrap narrow"><h1>{esc(d["h1"])}</h1></div>
    </div>
    <section class="tight" style="padding-top:0">
      <div class="wrap narrow"><div class="prose">
{d["html"]}
      </div></div>
    </section>
  </main>
{footer()}</body>
</html>
'''
    write(d["path"], [("Privacy", d["path"])], body)


def last_modified(path):
    """The day a page's file last changed: today if it has changes not yet committed, else its last commit."""
    name = "index.html" if path == "/" else path.strip("/") + ".html"
    git = ["git", "-C", ROOT]
    if subprocess.run(git + ["diff", "--quiet", "HEAD", "--", name], capture_output=True).returncode != 0:
        return datetime.date.today().isoformat()
    day = subprocess.run(git + ["log", "-1", "--format=%cs", "--", name], capture_output=True, text=True).stdout.strip()
    return day or datetime.date.today().isoformat()


def render_sitemap():
    paths = (["/", "/limits"] + [p["path"] for p in LIMITS] + ["/guides"] + [p["path"] for p in GUIDES]
             + ["/compare"] + [p["path"] for p in COMPARES]
             + ["/alternatives"] + [f"/{p['slug']}" for p in COMPARISONS] + [CLI["path"], PRIVACY["path"]])
    urls = "".join(f"  <url><loc>{SITE}{p}</loc><lastmod>{last_modified(p)}</lastmod></url>\n" for p in paths)
    with open(os.path.join(ROOT, "sitemap.xml"), "w") as f:
        f.write(f'<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n{urls}</urlset>\n')


def render_llms():
    """/llms.txt: a plain summary of the app, for AI agents and AI search (llmstxt.org)."""
    compare = "\n".join(f"- [Fuel Gauge vs {p['competitor']}]({SITE}/{p['slug']}): {html.unescape(p['tldr'])}" for p in COMPARISONS)
    limits = "\n".join(f"- [{p['short']}]({SITE}{p['path']}): {html.unescape(re.sub(r'<[^>]+>', '', p['answer']))}" for p in LIMITS)
    guides = "\n".join(f"- [{p['short']}]({SITE}{p['path']}): {html.unescape(re.sub(r'<[^>]+>', '', p['answer']))}"
                       for p in GUIDES + COMPARES + [CLI])
    body = f"""# Fuel Gauge

> Fuel Gauge is a free, source-available macOS menu bar app (macOS 14 Sonoma or later) that forecasts whether your Claude Code, Codex, Grok Bot, and Cursor plan limits will last until they reset. It reads only what those tools already save on your Mac, and sends nothing anywhere.

- Install: `{BREW}`, or download {DOWNLOAD}
- Source: {REPO} (FSL-1.1-MIT)
- Limits tracked: Claude Code 5-hour and weekly, Codex, Grok Bot weekly, and Cursor (opt-in: asks cursor.com with the Cursor app's sign-in). Choose which in Settings › Tools.
- How it forecasts: readings come from Claude Code's status line (every time Claude Code replies), Codex's session logs (`~/.codex/sessions`), and Grok Bot's local usage cache. Pace is the climb over the last hour for 5-hour windows and the last day for weekly ones. It waits for 10 minutes of readings on a 5-hour limit and 3 hours on a weekly one, and shows a range, not an exact minute. It's an estimate from recent pace, not a promise.
- Command line: `fuelgauge status` prints the verdict for each limit and exits with code 2 when a limit is forecast to run out before it resets. `fuelgauge status --json` has the details. `fuelgauge history` shows the readings. `fuelgauge install-statusline` adds the forecast under Claude Code's prompt (keeping any existing status line and backing up settings.json), and `fuelgauge uninstall-statusline` removes it.
- Claude Desktop: the extension at https://github.com/coreyhaines31/fuelgauge/releases/latest/download/fuelgauge.mcpb gives Claude two read-only tools, `limits_status` and `limits_history`, that run the same `fuelgauge` command and return short answers. It needs the app installed and never changes Claude Code's settings.
- Install prompt for a coding agent: "{INSTALL_PROMPT}"
- Line for CLAUDE.md or AGENTS.md: "{AGENT_RULE}"
- Uninstall: run `fuelgauge uninstall-statusline` first, then `brew uninstall --cask fuelgauge`.
- Privacy: no browser cookies, no Full Disk Access, zero telemetry. Network requests include update checks, Codex reset checks through the installed CLI (on by default, with an opt-out), and optional Cursor usage. Details: {SITE}/privacy

## Plan limits, explained

{limits}

## Guides, comparisons, and the command

{guides}

## Compared with other apps

{compare}
"""
    with open(os.path.join(ROOT, "llms.txt"), "w") as f:
        f.write(body)


def check():
    """Fails the build when a page's title or description is a length search results cut off or ignore."""
    problems = []
    for name in sorted(glob.glob(os.path.join(ROOT, "**", "*.html"), recursive=True)):
        if "/_build/" in name:
            continue
        page = open(name).read()
        title = html.unescape(re.search(r"<title>(.*?)</title>", page).group(1))
        desc = html.unescape(re.search(r'name="description" content="(.*?)"', page).group(1))
        if len(title) > 60 or not 50 <= len(desc) <= 160:
            problems.append(f"{os.path.relpath(name, ROOT)}: title {len(title)}, description {len(desc)}")
    if problems:
        sys.exit("Titles must be 60 characters or fewer and descriptions 50 to 160:\n" + "\n".join(problems))


if __name__ == "__main__":
    for p in LIMITS:
        render_page(p, [("Limits", "/limits"), (p["short"], p["path"])])
    for p in GUIDES:
        render_page(p, [("Guides", "/guides"), (p["short"], p["path"])])
    for p in COMPARES:
        render_page(p, [("Compare", "/compare"), (p["short"], p["path"])])
    for p in COMPARISONS:
        render_comparison(p)
    cli = dict(CLI, sections=[dict(s, html=s["html"].replace("{AGENT_RULE}", esc(AGENT_RULE))
                                   .replace("{INSTALL_PROMPT}", esc(INSTALL_PROMPT))) for s in CLI["sections"]])
    render_page(cli, [("For agents", CLI["path"])])
    render_hubs()
    render_privacy()
    render_homepage()
    render_sitemap()
    render_llms()
    check()
    print(f"rendered {len(LIMITS)} limits, {len(GUIDES)} guides, {len(COMPARES)} plan comparisons, "
          f"{len(COMPARISONS)} alternatives, /cli, 4 hubs, privacy, "
          "homepage nav/footer/schema, sitemap, llms.txt")
