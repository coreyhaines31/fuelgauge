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
        "tldr": "Pick CodexBar if you use many AI providers and want them all in one menu. Pick Fuel Gauge if you live in Claude Code, Codex, or Grok Bot and want the verdict first, a forecast under your Claude Code prompt, and an exit code your agents can check. Fuel Gauge forecasts from local readings and checks Codex reset credits through the installed CLI.",
        "card_title": "CodexBar",
        "cta": "Know if you&#39;ll make it.",
        "faqs": [
            ("Is CodexBar free?", "Yes. CodexBar is free and MIT licensed. Fuel Gauge is free too, with the source on GitHub under the FSL-1.1-MIT license."),
            ("Does Fuel Gauge track as many providers as CodexBar?", "No. CodexBar lists over 100 providers. Fuel Gauge tracks Claude Code, Codex, Grok Bot, and Cursor, and puts its effort into forecasting those."),
            ("Why doesn't Fuel Gauge use browser cookies?", "Its Claude Code, Codex, and Grok Bot forecasts use local readings. Codex reset checks use the installed CLI and its existing sign-in. Fuel Gauge does not read browser cookies or need Full Disk Access."),
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
        <p><strong>No browser cookies or Full Disk Access.</strong> CodexBar uses browser cookies and Full Disk Access for some providers. Fuel Gauge never does.</p>
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
    {
        "slug": "alternatives/claude-code-usage-monitor",
        "competitor": "Claude-Code-Usage-Monitor",
        "card": "A terminal token dashboard vs a forecast from Claude's own percentages",
        "title": "Claude-Code-Usage-Monitor alternative: Fuel Gauge for Mac",
        "description": "Claude-Code-Usage-Monitor predicts session token use in your terminal. Fuel Gauge forecasts your Claude Code limits from Claude's own percentages, in the menu bar.",
        "eyebrow": "Claude-Code-Usage-Monitor alternative",
        "h1": "Claude-Code-Usage-Monitor watches tokens. Fuel Gauge watches <em>your limit.</em>",
        "lede": "Claude-Code-Usage-Monitor is a popular terminal dashboard for Claude Code with burn rates and predictions. Fuel Gauge forecasts from the percentages Claude Code itself reports, and lives in the menu bar.",
        "tldr": "Use Claude-Code-Usage-Monitor if you want a live terminal dashboard of tokens and cost per 5-hour window, on macOS, Linux, or Windows. Use Fuel Gauge if you want a forecast from Claude&#39;s own limit percentages, always visible in the menu bar and under your prompt, with alerts, plus Codex, Grok Bot, and Cursor.",
        "card_title": "Claude-Code-Usage-Monitor",
        "cta": "Know if you&#39;ll make it.",
        "faqs": [
            ("Is Claude-Code-Usage-Monitor free?", "Yes. It's free and MIT licensed. Fuel Gauge is free too, with the source on GitHub under the FSL-1.1-MIT license."),
            ("How is Fuel Gauge's forecast different?", "Fuel Gauge works from the percent of your session and weekly limits that Claude Code reports after every reply. Token-based tools estimate limits from token counts, and Anthropic doesn't publish token limits for its plans."),
            ("Can I use both?", "Yes. One runs in your terminal, the other in the menu bar."),
        ],
        "sections": [
            {"id": "why", "html": """
        <h2>What Claude-Code-Usage-Monitor does well</h2>
        <p>It&#39;s a real-time terminal dashboard for Claude Code: tokens and cost in each 5-hour window, a burn-rate view, session forecasting that "predicts when sessions will expire", and warnings. It installs with <code>uv tool install claude-monitor</code>, runs on macOS, Linux, and Windows, and is free and MIT licensed with about 8,700 stars on GitHub.</p>
        <h3>Where Fuel Gauge is different</h3>
        <p><strong>It starts from Claude&#39;s own numbers.</strong> Fuel Gauge reads the session and weekly percentages Claude Code reports to its status line after every reply. Token-based tools have to estimate the limit: Claude-Code-Usage-Monitor uses built-in token limits per plan, with a P90-based default, because Anthropic doesn&#39;t publish token counts.</p>
        <p><strong>It covers the weekly limit.</strong> Each card forecasts its own window, 5-hour and weekly, with a range and the most you can use per hour and still make it.</p>
        <p><strong>It&#39;s always visible.</strong> A menu bar glyph that turns orange, one alert per window, a line under your Claude Code prompt, and Codex, Grok Bot, and Cursor too.</p>
            """},
            {"id": "compare", "lit": True, "html": """
        <h2>Fuel Gauge vs Claude-Code-Usage-Monitor</h2>
        {{TABLE}}
        <h3>What Claude-Code-Usage-Monitor does better</h3>
        <p>A detailed live terminal view with token and cost numbers, and it runs on Linux and Windows.</p>
        <h3>What Fuel Gauge does better</h3>
        <p>Forecasts from the percentages that actually decide when you&#39;re cut off, for both windows and four tools, without keeping a terminal open.</p>
            """, "table": [
                ("Price", "Free", "Free"),
                ("License", "FSL-1.1-MIT, source on GitHub", "MIT"),
                ("Where it runs", "Mac menu bar, Claude Code status line, CLI", "Terminal dashboard"),
                ("Measures", "Claude&#39;s own session and weekly percentages", "Tokens and cost per 5-hour window"),
                ("Forecast", "Each window, with a range", "Session forecasting"),
                ("Weekly limit forecast", "Yes", "—"),
                ("Codex, Grok Bot, Cursor", "Yes", "—"),
                ("Platforms", "macOS 14+", "macOS, Linux, Windows"),
            ]},
            {"id": "switch", "html": """
        <h2>Trying it takes a minute</h2>
        <ol class="steps">
          <li><b>Install Fuel Gauge.</b> <code>brew install --cask coreyhaines31/tap/fuelgauge</code>, or download the app from GitHub and drag it to Applications.</li>
          <li><b>Turn on the status line.</b> From the app, or with <code>fuelgauge install-statusline</code>. It keeps your existing status line and backs up <code>settings.json</code>.</li>
          <li><b>Keep working.</b> A 5-hour limit gets a forecast after about 10 minutes of readings, a weekly one after 3 hours. Until then it says “Learning your pace.”</li>
          <li><b>Keep Claude-Code-Usage-Monitor if you like its terminal dashboard.</b> The two don&#39;t conflict.</li>
        </ol>
            """},
        ],
    },
]

PRIVACY = {
    "path": "/privacy",
    "title": "Privacy policy · Fuel Gauge",
    "description": "Fuel Gauge has no telemetry. Learn about local usage readings, Codex reset checks, optional Cursor usage, and update requests.",
    "h1": "Privacy policy",
    "html": """
        <p><strong>Last updated October 27, 2026.</strong></p>
        <h2>The Fuel Gauge app</h2>
        <p>The app collects nothing about you. There&#39;s no account, no analytics, and no telemetry.</p>
        <p>To forecast your limits it reads what Claude Code, Codex, and Grok Bot already save on your Mac: the usage Claude Code passes to its status line, Codex&#39;s session logs in <code>~/.codex/sessions</code>, and Grok Bot&#39;s local usage cache. It keeps a history of those readings in <code>~/Library/Application Support/Fuel Gauge</code>. It doesn&#39;t read browser cookies or need Full Disk Access. Your saved reading history stays on your Mac.</p>
        <p>If you turn on the Claude Code status line, Fuel Gauge backs up your Claude Code <code>settings.json</code> before changing it. <code>fuelgauge uninstall-statusline</code> puts it back.</p>
        <p>Codex reset tracking is on by default while Codex is tracked. Every five minutes, Fuel Gauge asks the installed Codex CLI for available reset credits using its existing sign-in; this contacts OpenAI. Fuel Gauge does not read or store Codex credentials, and never redeems a reset. Turn tracking off in Settings &gt; Resets; explicit opt-outs are preserved across updates.</p>
        <p>Cursor tracking is off by default. If enabled, it requests usage from cursor.com using the Cursor app&#39;s existing sign-in. The update check fetches a small feed from GitHub. These services see requests like other web requests, including your IP address.</p>
        <h2>fuelgauge.app</h2>
        <p>This website uses <a href="https://usefathom.com">Fathom Analytics</a> for privacy-friendly visit counts and UserProof to see how visitors use the site (clicks, scrolling and page interactions, not anything you type). Neither sets cookies; UserProof keeps random ids in your browser&#39;s storage. No ad tracking, no personal data sold or shared. It&#39;s static pages hosted on Vercel, which keeps standard server logs, and it loads fonts from Google Fonts, which sees that request like any other web request.</p>
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
        {"id": "claude-desktop", "lit": True, "html": """
        <h2>Use it in Claude Desktop</h2>
        <p>Not using Claude Code? Download <a href="https://github.com/coreyhaines31/fuelgauge/releases/latest/download/fuelgauge.mcpb">fuelgauge.mcpb</a> and double-click it, or drag it onto Claude Desktop, and choose Install. Claude can then read your forecast and the readings behind it, and ask before a long task if a limit won&#39;t last. Answers come back short, so checking barely touches your limits. The extension only reads. <a href="/#claude">More about the extension</a>.</p>"""},
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
