# Content for the comparison page and the privacy page.
#
# Copy rules: plain and specific, short sentences, no hype. Say "free, source available" and "source on GitHub",
# never "open source". Fuel Gauge is licensed FSL-1.1-MIT.
# Competitor facts come from their own sites and READMEs as of October 2026. Be fair: say what each does better.

COMPARISONS = [
    {
        "slug": "alternatives/codexbar",
        "competitor": "CodexBar",
        "card": "Over 100 providers vs a forecast for four",
        "title": "CodexBar alternative: Fuel Gauge, a free usage forecast",
        "description": "CodexBar tracks over 100 AI providers. Fuel Gauge is a free Mac app that forecasts whether your Claude Code, Codex, Grok Bot, and Cursor limits last.",
        "eyebrow": "CodexBar alternative",
        "h1": "CodexBar shows how much you&#39;ve used. Fuel Gauge says if you&#39;ll <em>make it to reset.</em>",
        "lede": "CodexBar is a good free menu bar app that tracks usage across a huge list of AI providers. Fuel Gauge does less, on purpose: four tools, and one answer for each.",
        "tldr": "Pick CodexBar if you use many AI providers and want them all in one menu. Pick Fuel Gauge if you live in Claude Code, Codex, or Grok Bot and want the verdict first, a forecast under your Claude Code prompt, and an exit code your agents can check. Fuel Gauge reads only local files.",
        "card_title": "CodexBar",
        "cta": "Know if you&#39;ll make it.",
        "faqs": [
            ("Is CodexBar free?", "Yes. CodexBar is free and MIT licensed. Fuel Gauge is free too, with the source on GitHub under the FSL-1.1-MIT license."),
            ("Does Fuel Gauge track as many providers as CodexBar?", "No. CodexBar lists over 100 providers. Fuel Gauge tracks Claude Code, Codex, Grok Bot, and Cursor, and puts its effort into forecasting those."),
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
          <li><b>Keep working.</b> A 5-hour limit gets a forecast after about 10 minutes of readings, a weekly one after 3 hours. Until then it says “Learning your pace.”</li>
          <li><b>Keep CodexBar if you use its other providers.</b> The two don&#39;t conflict.</li>
        </ol>
            """},
        ],
    },
    {
        "slug": "alternatives/ccusage",
        "competitor": "ccusage",
        "card": "Token and cost reports vs a limit forecast",
        "title": "ccusage alternative: forecast your Claude Code limits",
        "description": "ccusage reports token use and cost from local logs. Fuel Gauge forecasts whether your Claude Code and Codex limits last until reset. Free Mac app.",
        "eyebrow": "ccusage alternative",
        "h1": "ccusage counts your tokens. Fuel Gauge says if you&#39;ll <em>make it to reset.</em>",
        "lede": "ccusage is a great command-line report of what your coding agents spent. Fuel Gauge answers a different question: at your pace, will your plan&#39;s limit last until it resets?",
        "tldr": "Use ccusage to see token use and estimated dollar cost by day, month, session, or 5-hour block, across 18 coding agents. Use Fuel Gauge to see, without running anything, whether your Claude Code, Codex, Grok Bot, or Cursor limit will last until it resets, with an alert when it won&#39;t. They answer different questions, so they work well together.",
        "card_title": "ccusage",
        "cta": "Know if you&#39;ll make it.",
        "faqs": [
            ("Is ccusage free?", "Yes. ccusage is free and MIT licensed. Fuel Gauge is free too, with the source on GitHub under the FSL-1.1-MIT license."),
            ("Does Fuel Gauge show dollar costs like ccusage?", "No. Fuel Gauge works in percent of your plan's limit, which is what decides whether you get cut off on Pro or Max. ccusage estimates cost from tokens at API prices."),
            ("Can I use ccusage and Fuel Gauge together?", "Yes. ccusage is a command you run for reports; Fuel Gauge runs in the menu bar. Neither changes the other."),
        ],
        "sections": [
            {"id": "why", "html": """
        <h2>What ccusage does well</h2>
        <p>ccusage reads the usage data coding agents leave on your machine and turns it into reports: <code>daily</code>, <code>weekly</code>, <code>monthly</code>, and <code>session</code>, with tokens and an estimated cost in dollars, plus a <code>blocks</code> report for Claude Code&#39;s 5-hour windows. It covers 18 tools, including Claude Code, Codex, Gemini CLI, and GitHub Copilot CLI, and runs with <code>npx ccusage@latest</code>. It&#39;s free, MIT licensed, and has about 19,000 stars on GitHub.</p>
        <h3>Where Fuel Gauge is different</h3>
        <p><strong>It measures the limit, not the tokens.</strong> On Pro and Max, what cuts you off is the percent of your session or weekly limit, and Anthropic doesn&#39;t publish how many tokens that is. Fuel Gauge reads those percentages straight from Claude Code after every reply.</p>
        <p><strong>It forecasts.</strong> Each limit gets a verdict: "Makes it to reset" or "Runs out around 3:40p, 1h 20m early", with the most you can use per hour and still make it.</p>
        <p><strong>It&#39;s always on.</strong> A menu bar app with a glyph that turns orange, one alert per window, and a line under your Claude Code prompt. Nothing to run.</p>
            """},
            {"id": "compare", "lit": True, "html": """
        <h2>Fuel Gauge vs ccusage</h2>
        {{TABLE}}
        <h3>What ccusage does better</h3>
        <p>History and cost. If you want to know what last month cost at API prices, or compare usage across many agents, ccusage is the tool.</p>
        <h3>What Fuel Gauge does better</h3>
        <p>The next few hours. It tells you whether your current limit will last, while you work, without opening a terminal.</p>
            """, "table": [
                ("Price", "Free", "Free"),
                ("License", "FSL-1.1-MIT, source on GitHub", "MIT"),
                ("What it measures", "Percent of your plan&#39;s limits", "Tokens and estimated cost in dollars"),
                ("Forecast to reset", "Yes, with a range", "—"),
                ("Where it runs", "Mac menu bar, Claude Code status line, CLI", "Command line"),
                ("Tools", "Claude Code, Codex, Grok Bot, Cursor (opt-in)", "18, including Claude Code, Codex, Gemini CLI"),
                ("Alerts", "Once per window, plus 50/80/95%", "—"),
                ("Platforms", "macOS 14+", "Anywhere Node, Bun, or Nix runs"),
            ]},
            {"id": "switch", "html": """
        <h2>Trying it takes a minute</h2>
        <ol class="steps">
          <li><b>Install Fuel Gauge.</b> <code>brew install --cask coreyhaines31/tap/fuelgauge</code>, or download the app from GitHub and drag it to Applications.</li>
          <li><b>Turn on the status line.</b> From the app, or with <code>fuelgauge install-statusline</code>. It keeps your existing status line and backs up <code>settings.json</code>.</li>
          <li><b>Keep working.</b> A 5-hour limit gets a forecast after about 10 minutes of readings, a weekly one after 3 hours. Until then it says “Learning your pace.”</li>
          <li><b>Keep ccusage for reports. The two don&#39;t conflict.</b></li>
        </ol>
            """},
        ],
    },
    {
        "slug": "alternatives/ccstatusline",
        "competitor": "ccstatusline",
        "card": "A widget-packed status line vs a forecast, and using both",
        "title": "ccstatusline alternative: a usage forecast for Claude Code",
        "description": "ccstatusline is a customizable Claude Code statusline. Fuel Gauge adds a forecast of whether your limits last until reset, and runs alongside it.",
        "eyebrow": "ccstatusline alternative",
        "h1": "ccstatusline shows where you are. Fuel Gauge shows <em>where you&#39;re headed.</em>",
        "lede": "ccstatusline is the most customizable status line for Claude Code. Fuel Gauge adds the one thing it doesn&#39;t do: a forecast. And it can run underneath it.",
        "tldr": "Keep ccstatusline if you love its widgets: git, tokens, context, cost, and session and weekly usage with reset timers. Add Fuel Gauge for the forecast: whether each limit lasts until it resets at your pace, in the menu bar and as one more line under your status line. Fuel Gauge keeps your existing status line when you turn its line on.",
        "card_title": "ccstatusline",
        "cta": "Know if you&#39;ll make it.",
        "faqs": [
            ("Is ccstatusline free?", "Yes. ccstatusline is free and MIT licensed. Fuel Gauge is free too, with the source on GitHub under the FSL-1.1-MIT license."),
            ("Can I use ccstatusline and Fuel Gauge together?", "Yes. When you turn on Fuel Gauge's status line, it saves your current status line command and runs it first, then prints the forecast underneath. Turning it off puts ccstatusline back on its own."),
            ("Does ccstatusline show usage limits?", "Yes. It has session and weekly usage widgets and reset timers. It doesn't forecast whether you'll run out before the reset; that's what Fuel Gauge adds."),
        ],
        "sections": [
            {"id": "why", "html": """
        <h2>What ccstatusline does well</h2>
        <p>Everything you might want under the prompt. ccstatusline has widgets for the model, git branch and status, tokens, context use, cost, cache hit rate, and, for limits, session and weekly usage with reset timers and extra usage. You set it up in an interactive screen with <code>npx -y ccstatusline@latest</code>. It&#39;s free, MIT licensed, and has about 13,000 stars on GitHub.</p>
        <h3>Where Fuel Gauge is different</h3>
        <p><strong>It forecasts.</strong> ccstatusline shows how much you&#39;ve used and when it resets. Fuel Gauge works out whether you&#39;ll get there: <code>⛽ 5h 55% out ~11:50a · wk 41% ok</code>.</p>
        <p><strong>It&#39;s there when Claude Code isn&#39;t.</strong> The menu bar shows the same forecast, warns you once per window, and covers Codex, Grok Bot, and Cursor too.</p>
        <p><strong>It reads, it doesn&#39;t call.</strong> Fuel Gauge takes the limits Claude Code already passes to the status line, with no extra requests.</p>
            """},
            {"id": "compare", "lit": True, "html": """
        <h2>Fuel Gauge vs ccstatusline</h2>
        {{TABLE}}
        <h3>Use both</h3>
        <p>Claude Code runs one status line command. When you turn on Fuel Gauge&#39;s line, it saves your ccstatusline command and runs it first, with the same input, then prints the forecast under it. <code>fuelgauge uninstall-statusline</code> puts ccstatusline back on its own.</p>
            """, "table": [
                ("Price", "Free", "Free"),
                ("License", "FSL-1.1-MIT, source on GitHub", "MIT"),
                ("Session and weekly usage", "Yes", "Yes"),
                ("Reset times", "Yes", "Yes"),
                ("Forecast to reset", "Yes, with a range", "—"),
                ("Git, tokens, context, cost widgets", "No", "Yes, dozens"),
                ("Menu bar app and alerts", "Yes", "—"),
                ("Codex, Grok Bot, Cursor", "Yes", "—"),
            ]},
            {"id": "switch", "html": """
        <h2>Trying it takes a minute</h2>
        <ol class="steps">
          <li><b>Install Fuel Gauge.</b> <code>brew install --cask coreyhaines31/tap/fuelgauge</code>, or download the app from GitHub and drag it to Applications.</li>
          <li><b>Turn on the status line.</b> From the app, or with <code>fuelgauge install-statusline</code>. It keeps your existing status line and backs up <code>settings.json</code>.</li>
          <li><b>Keep working.</b> A 5-hour limit gets a forecast after about 10 minutes of readings, a weekly one after 3 hours. Until then it says “Learning your pace.”</li>
          <li><b>Keep ccstatusline. It keeps running, with the forecast under it.</b></li>
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

CLI = {
    "path": "/cli",
    "short": "Fuel Gauge for agents",
    "title": "fuelgauge command: let AI agents check usage limits first",
    "description": "The fuelgauge command tells you or an AI agent whether Claude Code, Codex, Grok Bot, and Cursor limits will last until reset, and exits 2 when one won't.",
    "eyebrow": "For agents",
    "h1": "Let your agent check <em>before the big job.</em>",
    "lede": "Fuel Gauge includes a <code>fuelgauge</code> command. It prints the forecast for every limit and exits with code 2 when one will run out before it resets, so a coding agent can ask you before it burns through what's left.",
    "answer": "Run <code>fuelgauge status</code>. It exits 0 when every limit will last until it resets, and 2 when one won't (or already ran out). Add one line to CLAUDE.md or AGENTS.md and your agent checks before long tasks. Homebrew puts the command on your PATH; otherwise use Settings › General › Install.",
    "sections": [
        {"id": "commands", "html": """
        <h2>Commands</h2>
        <pre><code>fuelgauge status              # every limit, in plain words; exits 2 if one will run out before it resets
fuelgauge status --json       # the same, for scripts and agents
fuelgauge history --days 2    # the readings behind the forecasts
fuelgauge install-statusline  # make Fuel Gauge Claude Code's status line (keeps yours, backs up settings.json)
fuelgauge uninstall-statusline</code></pre>
        <h3>What status prints</h3>
        <pre><code>Claude Code · 5-hour: Runs out around 11:50a, 1h 30m early
  55% used · resets 1:20p (in 3h 6m)
  Using 28% an hour. You can use up to 15% an hour and still make it.
Claude Code · Weekly: Makes it to reset, about 86% by then
  41% used · resets Thu 9a (in 2d 22h)</code></pre>"""},
        {"id": "json", "lit": True, "html": """
        <h2>The JSON</h2>
        <p><code>fuelgauge status --json</code> prints one object per limit, with stable snake_case keys:</p>
        <pre><code>[
  {
    "tool": "claude",
    "window": "5-hour",
    "used_percent": 55,
    "resets_at": "2026-10-20T20:20:00Z",
    "verdict": "runs_out",
    "runs_out_at": "2026-10-20T18:50:00Z",
    "rate_per_hour": 28,
    "budget_per_hour": 15,
    "summary": "Runs out around 11:50a, 1h 30m early"
  }
]</code></pre>
        <p><code>verdict</code> is one of <code>makes_it</code>, <code>runs_out</code>, <code>out</code>, <code>learning</code>, or <code>reset</code>. Exit code 2 means at least one limit is <code>runs_out</code> or <code>out</code>.</p>"""},
        {"id": "agents", "html": """
        <h2>Add it to CLAUDE.md or AGENTS.md</h2>
        <div class="prompt-box"><button type="button" class="copy" data-copy="agent-rule-cli">Copy</button><pre id="agent-rule-cli">{AGENT_RULE}</pre></div>
        <p>Then every agent session checks before the expensive stuff, and tells you which limit runs out and when instead of hitting the wall halfway through.</p>
        <h3>Install it with your agent</h3>
        <div class="prompt-box"><button type="button" class="copy" data-copy="install-prompt-cli">Copy</button><pre id="install-prompt-cli">{INSTALL_PROMPT}</pre></div>"""},
    ],
    "faqs": [
        ("What does exit code 2 mean?", "At least one tracked limit is forecast to run out before it resets, or has already run out."),
        ("Does the command need the app running?", "The app collects Codex and Grok Bot readings in the background; Claude Code readings arrive through the status line. Keep the app running for current Codex numbers."),
        ("Is the JSON stable?", "Yes. Keys are snake_case and new fields are only ever added."),
    ],
    "related": [
        ("Claude Code status line", "Your limits under the prompt", "/guides/claude-code-statusline"),
        ("Stop hitting Claude limits", "What uses your limit fastest", "/guides/stop-hitting-claude-limits"),
        ("Claude Code limits", "How Claude Code counts against your plan", "/limits/claude-code"),
    ],
}
