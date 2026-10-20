# Content for the comparison page and the privacy page.
#
# Copy rules: plain and specific, short sentences, no hype. Say "free, source available" and "source on GitHub",
# never "open source". Fuel Gauge is licensed FSL-1.1-MIT.
# CodexBar facts come from codexbar.app as of October 2026. Be fair: it covers far more providers.

COMPARISONS = [
    {
        "slug": "codexbar-alternative",
        "competitor": "CodexBar",
        "title": "CodexBar alternative: Fuel Gauge, a free usage forecast for Mac",
        "description": "CodexBar shows usage for over 100 AI providers. Fuel Gauge is a free Mac alternative that forecasts whether your Claude Code, Codex, and Grok Bot limits last until reset.",
        "eyebrow": "CodexBar alternative",
        "h1": "CodexBar shows how much you&#39;ve used. Fuel Gauge says if you&#39;ll <em>make it to reset.</em>",
        "lede": "CodexBar is a good free menu bar app that tracks usage across a huge list of AI providers. Fuel Gauge does less, on purpose: three tools, and one answer for each.",
        "tldr": "Pick CodexBar if you use many AI providers and want them all in one menu. Pick Fuel Gauge if you live in Claude Code, Codex, or Grok Bot and want the verdict first, a forecast under your Claude Code prompt, and an exit code your agents can check. Fuel Gauge reads only local files.",
        "card_title": "CodexBar",
        "cta": "Know if you&#39;ll make it.",
        "faqs": [
            ("Is CodexBar free?", "Yes. CodexBar is free and MIT licensed. Fuel Gauge is free too, with the source on GitHub under the FSL-1.1-MIT license."),
            ("Does Fuel Gauge track as many providers as CodexBar?", "No. CodexBar lists over 100 providers. Fuel Gauge tracks Claude Code, Codex, and Grok Bot, and puts its effort into forecasting those."),
            ("Why doesn't Fuel Gauge use browser cookies?", "It reads only what Claude Code, Codex, and Grok Bot already save on your Mac. That means no browser cookies, no Full Disk Access, no keychain, and no sign-in."),
            ("Can I run both?", "Yes. They don't conflict. Some people keep CodexBar for its breadth and Fuel Gauge for the forecast."),
        ],
        "sections": [
            {"id": "why", "html": """
        <h2>What CodexBar does well</h2>
        <p>Breadth. CodexBar tracks usage across more than 100 AI providers from one menu bar icon, and it&#39;s free and MIT licensed. If you bounce between many services, nothing else covers as much.</p>
        <p>For each limit it shows how much you&#39;ve used, with a line that says when it runs out at your current rate.</p>
        <h3>Where Fuel Gauge is different</h3>
        <p><strong>It leads with the verdict.</strong> Each card opens with “Runs out around 11:50a, 1h 30m early” or “Makes it to reset, about 86% by then”, then shows how much you can use per hour and still make it.</p>
        <p><strong>It sits under your Claude Code prompt.</strong> The optional status line puts the forecast in Claude Code after every reply.</p>
        <p><strong>Agents can check it.</strong> <code>fuelgauge status</code> exits with code 2 when a limit will run out before it resets, so an agent can ask before a big job.</p>
        <p><strong>It reads only local files.</strong> CodexBar uses browser cookies and Full Disk Access for some providers. Fuel Gauge never does.</p>
            """},
            {"id": "compare", "lit": True, "html": """
        <h2>Fuel Gauge vs CodexBar</h2>
        {{TABLE}}
        <h3>What CodexBar does better</h3>
        <p>Coverage. If you need usage from dozens of AI services in one place, CodexBar is the one to use.</p>
        <h3>What Fuel Gauge does better</h3>
        <p>The forecast. It tells you if you&#39;ll make it, shows a range instead of one exact minute, warns you once when you&#39;re on pace to run out early, and puts the answer where you work: the menu bar, Claude Code&#39;s status line, and your agent&#39;s shell.</p>
            """, "table": [
                ("Price", "Free", "Free"),
                ("License", "FSL-1.1-MIT, source on GitHub", "MIT"),
                ("Providers", "Claude Code, Codex, Grok Bot, Cursor (opt-in)", "Over 100"),
                ("Leads with", "The verdict: makes it, or runs out early", "Percent used, plus a “runs out in” line"),
                ("Claude Code status line", "Yes", "—"),
                ("Exit code for agents", "Yes, <code>fuelgauge status</code> exits 2", "—"),
                ("Browser cookies", "Never", "For some providers"),
                ("Full Disk Access", "Never", "For some providers"),
                ("Telemetry", "None", "—"),
            ]},
            {"id": "switch", "html": """
        <h2>Trying it takes a minute</h2>
        <ol class="steps">
          <li><b>Install Fuel Gauge.</b> <code>brew install --cask coreyhaines31/tap/fuelgauge</code>, or download the app from GitHub and drag it to Applications.</li>
          <li><b>Turn on the status line.</b> From the app, or with <code>fuelgauge install-statusline</code>. It keeps your existing status line and backs up <code>settings.json</code>.</li>
          <li><b>Work for 10 minutes.</b> It needs about that many readings before it forecasts. Until then it says “Learning your pace.”</li>
          <li><b>Keep CodexBar if you use its other providers.</b> The two don&#39;t conflict.</li>
        </ol>
            """},
        ],
    },
]

PRIVACY = {
    "path": "/privacy",
    "title": "Privacy policy · Fuel Gauge",
    "description": "Fuel Gauge collects nothing about you. It reads only what Claude Code, Codex, and Grok Bot already save on your Mac.",
    "h1": "Privacy policy",
    "html": """
        <p><strong>Last updated October 2026.</strong></p>
        <h2>The Fuel Gauge app</h2>
        <p>The app collects nothing about you. There&#39;s no account, no analytics, and no telemetry.</p>
        <p>To forecast your limits it reads what Claude Code, Codex, and Grok Bot already save on your Mac: the usage Claude Code passes to its status line, Codex&#39;s session logs in <code>~/.codex/sessions</code>, and Grok Bot&#39;s local usage cache. It keeps a history of those readings in <code>~/Library/Application Support/Fuel Gauge</code>. It doesn&#39;t read browser cookies, the keychain, or anything that needs Full Disk Access, and it never signs in to anything. None of it leaves your Mac.</p>
        <p>If you turn on the Claude Code status line, Fuel Gauge backs up your Claude Code <code>settings.json</code> before changing it. <code>fuelgauge uninstall-statusline</code> puts it back.</p>
        <p>The app&#39;s only network request is the check for updates, which fetches a small update feed from GitHub. GitHub sees that request like any other web request, including your IP address.</p>
        <h2>fuelgauge.app</h2>
        <p>This website counts visits with <a href="https://usefathom.com">Fathom Analytics</a>, which uses no cookies and collects no personal data. It&#39;s static pages hosted on Vercel, which keeps standard server logs, and it loads fonts from Google Fonts, which sees that request like any other web request.</p>
        <h2>Downloads</h2>
        <p>The app is downloaded from GitHub Releases, or through Homebrew, which downloads it from GitHub. Their privacy policies cover those downloads.</p>
        <h2>Questions</h2>
        <p>Open an issue on <a href="https://github.com/coreyhaines31/fuelgauge/issues">GitHub</a>. The source is public, so you can check every claim on this page yourself.</p>
    """,
}
