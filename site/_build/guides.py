# Guides, rendered by render.py. Same sourcing rule as limits.py: only what the official docs say.

from limits import CODE, COSTS, MAX, SETTINGS, USAGE, sources

STATUSLINE = "https://code.claude.com/docs/en/statusline"

GUIDES = [
    {
        "path": "/guides/check-claude-usage",
        "short": "Check your Claude usage",
        "card": "Settings › Usage, /usage, the status line, and a forecast",
        "title": "How to check your Claude usage (Pro, Max, Claude Code)",
        "description": "Every way to see how much of your Claude plan you've used: Settings › Usage on claude.ai, /usage in Claude Code, the status line, and a menu bar forecast.",
        "eyebrow": "Guide",
        "h1": "How to check your Claude usage",
        "lede": "Four places show how much of your limit is left, from a page you open once in a while to a line that's always under your prompt.",
        "answer": "On claude.ai, open <a href=\"" + SETTINGS + "\">Settings › Usage</a> to see your usage and when your limits reset. In Claude Code, run <code>/usage</code> for your plan usage bars. To see it all the time, put it in Claude Code's status line, or let a menu bar app like Fuel Gauge show it and forecast whether you'll make it to the reset.",
        "sections": [
            {"id": "settings", "html": f"""
        <h2>1. Settings › Usage on claude.ai</h2>
        <p>Open <a href="{SETTINGS}">claude.ai/settings/usage</a>. It shows how much of your session and weekly limits you've used and when each resets. It's also where Pro and Max subscribers turn usage credits on or off and see what they've spent.</p>
        <p>Because Claude, Claude Desktop, and Claude Code share the same limits, this page covers all of them.</p>"""},
            {"id": "usage", "lit": True, "html": """
        <h2>2. <code>/usage</code> in Claude Code</h2>
        <p>Type <code>/usage</code> in Claude Code. On Pro and Max you get your plan usage bars and a breakdown of what used them: skills, subagents, plugins, MCP servers, and scheduled loops. Press <code>d</code> or <code>w</code> to switch between the last day and the last week.</p>
        <p>Two things to know: the breakdown only counts sessions on this Mac, not claude.ai or other computers, and the dollar figure in the Session block is for API users, not subscribers. If <code>/usage</code> says it's rate limited until a certain time, that's the usage check that's limited, not your work.</p>
        <p>In the VS Code extension, the same numbers are in the Account &amp; usage dialog.</p>"""},
            {"id": "statusline", "html": """
        <h2>3. Claude Code's status line</h2>
        <p>After every reply, Claude Code hands its status line command your session and weekly usage as percentages, with their reset times. A status line script can print them under the prompt, so you never have to ask. The <a href="/guides/claude-code-statusline">status line guide</a> has a ready-made script.</p>"""},
            {"id": "forecast", "lit": True, "html": """
        <h2>4. A forecast in the menu bar</h2>
        <p>The first three tell you where you are. None of them says whether you'll make it: 55% used with three hours left is fine at one pace and a problem at another.</p>
        <p><a href="/">Fuel Gauge</a> is a free Mac menu bar app that does that math. It reads your limits from Claude Code after each reply, measures your pace, and says "Makes it to reset" or "Runs out around 3:40p". It also covers Codex, Grok Bot, and (if you turn it on) Cursor, and adds the forecast to the status line.</p>"""},
            {"id": "sources", "html": sources(
                ("Manage costs effectively (Claude Code docs)", COSTS),
                ("Customize your status line (Claude Code docs)", STATUSLINE),
                ("What is the Max plan?", MAX))},
        ],
        "faqs": [
            ("Where do I see my Claude usage?", "Settings › Usage on claude.ai shows your usage and when your limits reset. In Claude Code, run /usage."),
            ("Does /usage include my claude.ai chats?", "The plan usage bars cover everything, since the limits are shared. The breakdown of what used them only counts Claude Code sessions on this Mac."),
            ("Can I see my Claude usage all the time?", "Yes. Claude Code passes your usage to its status line after every reply, so a status line script can show it under the prompt. Fuel Gauge also shows it in the menu bar, with a forecast."),
        ],
        "related": [
            ("When do Claude limits reset?", "Session and weekly resets, explained", "/guides/when-does-claude-limit-reset"),
            ("Claude Code status line", "Your limits under the prompt", "/guides/claude-code-statusline"),
            ("Claude Code limits", "How Claude Code counts against your plan", "/limits/claude-code"),
        ],
    },
    {
        "path": "/guides/when-does-claude-limit-reset",
        "short": "When Claude limits reset",
        "card": "The 5-hour session and the weekly limit, and how to find your times",
        "title": "When does the Claude usage limit reset? Session and weekly",
        "description": "When Claude's usage limits reset: the session limit every five hours, the weekly limit at a fixed time for your account, and how to find your exact reset times.",
        "eyebrow": "Guide",
        "h1": "When does the Claude limit reset?",
        "lede": "There are two clocks: the session limit resets every five hours, and the weekly limit resets once a week at a time set for your account.",
        "answer": "Claude's session limit resets every five hours. On paid plans, the weekly limit resets once a week at a fixed time assigned to your account, not a day everyone shares. Settings › Usage on claude.ai shows your next reset, and Claude Code's limit message tells you when the window comes back.",
        "sections": [
            {"id": "session", "html": """
        <h2>The 5-hour session limit</h2>
        <p>Every plan, Free included, has a session limit that resets every five hours. It's the limit you hit in the middle of a long working stretch, and it's the one that comes back fastest.</p>
        <h2>The weekly limit</h2>
        <p>Pro and Max also have a weekly limit. It resets at a fixed time assigned to your account, once a week, and you get the full allowance back each time. Because the time is per account, your friend's reset may not be on the same day as yours.</p>
        <p>Max has one more: a separate weekly limit for Fable.</p>"""},
            {"id": "find", "lit": True, "html": f"""
        <h2>How to find your reset times</h2>
        <ul>
          <li><strong>claude.ai:</strong> <a href="{SETTINGS}">Settings › Usage</a> shows your next reset.</li>
          <li><strong>Claude Code:</strong> when you hit a limit, the message says when the window resets. <code>/usage</code> shows your usage bars.</li>
          <li><strong>The status line:</strong> Claude Code gives status line scripts each window's reset time, so it can sit under your prompt.</li>
          <li><strong>Fuel Gauge:</strong> shows each reset time, and whether you'll get there before you run out.</li>
        </ul>"""},
            {"id": "wait", "html": """
        <h2>If you hit the limit before the reset</h2>
        <p>Claude Code 2.1.234 and later can wait for the reset and pick the interrupted task back up on its own. You can also turn on usage credits to keep working at extra cost, or upgrade: Pro to Max 5x, or Max 5x to 20x. A new plan's limits apply right away.</p>
        <p>Better still is seeing it coming. A percentage tells you where you are; <a href="/">Fuel Gauge</a> tells you whether you'll make it to the reset at your current pace, and warns you once if you won't.</p>"""},
            {"id": "sources", "html": sources(
                ("How do usage and length limits work?", USAGE),
                ("What is the Max plan?", MAX),
                ("Manage costs effectively (Claude Code docs)", COSTS))},
        ],
        "faqs": [
            ("How long is the Claude usage limit?", "The session limit lasts until it resets, every five hours. The weekly limit resets once a week."),
            ("When does the Claude weekly limit reset?", "At a fixed time assigned to your account, once a week. Settings › Usage on claude.ai shows your next reset."),
            ("Does the weekly reset happen on the same day for everyone?", "No. The time is assigned per account."),
            ("Can Claude Code keep going after the reset?", "Yes. Claude Code 2.1.234 and later can wait for the reset and continue the interrupted task on its own."),
        ],
        "related": [
            ("Check your Claude usage", "Every place to see what's left", "/guides/check-claude-usage"),
            ("Claude Pro limits", "Session and weekly, shared with Claude Code", "/limits/claude-pro"),
            ("Claude Max limits", "5x or 20x Pro's usage", "/limits/claude-max"),
        ],
    },
    {
        "path": "/guides/claude-code-statusline",
        "short": "Claude Code status line",
        "card": "Show your limits and reset times under the prompt",
        "title": "Claude Code statusline: show your usage limits",
        "description": "Set up a Claude Code statusline that shows your 5-hour and weekly usage and reset times: the JSON it gets, a ready-made script, and a forecast.",
        "eyebrow": "Guide",
        "h1": "Claude Code statusline: your limits under the prompt",
        "lede": "Claude Code runs a script of your choice after every reply and shows whatever it prints. That script gets your usage limits for free.",
        "answer": "Set <code>statusLine</code> in <code>~/.claude/settings.json</code> to a command. After each reply, Claude Code sends that command JSON on stdin, including <code>rate_limits.five_hour</code> and <code>rate_limits.seven_day</code> with <code>used_percentage</code> and <code>resets_at</code> on Pro and Max. Print them, and your limits sit under the prompt.",
        "sections": [
            {"id": "how", "html": """
        <h2>How the status line works</h2>
        <p>The status line is a row under Claude Code's prompt. You point it at a command in <code>settings.json</code>; Claude Code runs it when a session starts, after each reply, and at a few other moments, passes it JSON about the session on stdin, and shows what it prints. Colors (ANSI codes) and multiple lines work.</p>
        <p>The JSON includes the model, the working folder, context window use, cost, and on Pro and Max plans, <code>rate_limits</code>:</p>
        <pre><code>"rate_limits": {
  "five_hour": { "used_percentage": 23.5, "resets_at": 1738425600 },
  "seven_day": { "used_percentage": 41.2, "resets_at": 1738857600 }
}</code></pre>
        <p><code>resets_at</code> is a Unix timestamp. <code>rate_limits</code> appears after the first reply in a session, each window can be missing, and a window drops out once its reset time passes, so scripts should handle absence.</p>"""},
            {"id": "script", "lit": True, "html": """
        <h2>A status line that shows your limits</h2>
        <p>Save this as <code>~/.claude/statusline.sh</code> and run <code>chmod +x</code> on it. It needs <code>jq</code>.</p>
        <pre><code>#!/bin/bash
input=$(cat)
five=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
week=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
line="$(echo "$input" | jq -r '.model.display_name')"
[ -n "$five" ] &amp;&amp; line="$line · 5h ${five%.*}%"
[ -n "$reset" ] &amp;&amp; line="$line (resets $(date -r "$reset" +%-I:%M%p))"
[ -n "$week" ] &amp;&amp; line="$line · week ${week%.*}%"
echo "$line"</code></pre>
        <p>Then add it to <code>~/.claude/settings.json</code>:</p>
        <pre><code>{
  "statusLine": { "type": "command", "command": "~/.claude/statusline.sh" }
}</code></pre>
        <p>It shows up after Claude's next reply: <code>Opus · 5h 23% (resets 3:00PM) · week 41%</code>. On Linux, use <code>date -d "@$reset"</code> instead of <code>date -r</code>.</p>"""},
            {"id": "forecast", "html": """
        <h2>A status line that forecasts</h2>
        <p>A percentage tells you where you are, not where you're headed. <a href="/">Fuel Gauge</a> adds a line that does the math at your recent pace:</p>
        <pre><code>⛽ 5h 55% out ~11:50a · wk 41% ok</code></pre>
        <p>Turn it on from the app, or run <code>fuelgauge install-statusline</code>. If you already have a status line, it keeps running and prints above the forecast, and your <code>settings.json</code> is backed up first. <code>fuelgauge uninstall-statusline</code> puts things back.</p>
        <h3>Other status line tools</h3>
        <p><a href="/alternatives/ccstatusline">ccstatusline</a> is a popular, highly customizable status line with dozens of widgets, including session and weekly usage. It works alongside Fuel Gauge: keep it as your status line and Fuel Gauge adds its line underneath.</p>"""},
            {"id": "sources", "html": sources(
                ("Customize your status line (Claude Code docs)", STATUSLINE),
                ("Use Claude Code with your Pro or Max plan", CODE))},
        ],
        "faqs": [
            ("Where is the Claude Code statusline configured?", "In settings.json, usually ~/.claude/settings.json, under statusLine with a type of command and the command to run."),
            ("Can the status line show my usage limits?", "Yes, on Pro and Max. Claude Code passes rate_limits.five_hour and rate_limits.seven_day, each with used_percentage and resets_at, to the status line command."),
            ("Why doesn't my status line show rate limits?", "They appear only for Pro and Max subscribers, and only after the first reply in a session. A window drops out once its reset time passes."),
            ("Can I use two status line tools?", "Claude Code runs one command. Fuel Gauge's installer wraps your existing one, so both print: yours first, the forecast under it."),
        ],
        "related": [
            ("ccstatusline alternative", "Widgets vs a forecast, and using both", "/alternatives/ccstatusline"),
            ("Check your Claude usage", "Every place to see what's left", "/guides/check-claude-usage"),
            ("Claude Code limits", "How Claude Code counts against your plan", "/limits/claude-code"),
        ],
    },
    {
        "path": "/guides/stop-hitting-claude-limits",
        "short": "Stop hitting Claude limits",
        "card": "What burns through your limit in Claude Code, and what saves it",
        "title": "How to stop hitting Claude usage limits in Claude Code",
        "description": "Why Claude Code burns through your Pro or Max limit and what actually helps: /clear, the right model and effort, fewer MCP tools, subagents, and a forecast.",
        "eyebrow": "Guide",
        "h1": "How to stop hitting your Claude limits",
        "lede": "Most limit trouble in Claude Code comes from a few habits. Here's what uses your limit fastest, what saves the most, and how to see a wall coming.",
        "answer": "Claude Code sends your whole conversation with every request, so long sessions are the biggest drain. Run <code>/clear</code> between unrelated tasks, match the model and effort level to the job, turn off MCP servers you aren't using, and send noisy work to subagents. Then watch your pace, so you know before a big task whether your limit will last.",
        "sections": [
            {"id": "why", "html": """
        <h2>Why usage climbs in a long session</h2>
        <p>Claude Code sends the full conversation with every request, and again with each batch of tool results. Caching makes re-reading history cheaper, but it still counts, so a one-line question in a session that's been open all day draws usage for the whole conversation.</p>
        <p>Other things that add up while you're not looking:</p>
        <ul>
          <li><strong>Cache misses:</strong> your first message after a long break reprocesses the full context.</li>
          <li><strong>Scheduled loops:</strong> a <code>/loop</code> task fires on its interval even while you're idle, sending your full context each time.</li>
          <li><strong>Subagents and agent teams:</strong> each one sends its own requests. Agent teams can use about 7x the tokens of a normal session when teammates run in plan mode.</li>
          <li><strong>Compacting a huge context:</strong> <code>/compact</code> reads everything it summarizes, so it's a big request itself.</li>
        </ul>
        <p>On Pro and Max, <code>/usage</code> flags any of these that accounts for 10% or more of your recent usage.</p>"""},
            {"id": "fixes", "lit": True, "html": """
        <h2>What saves the most</h2>
        <ol class="steps">
          <li><b>Clear between tasks.</b> <code>/clear</code> starts fresh when you switch to unrelated work. Use <code>/rename</code> first so you can <code>/resume</code> it later.</li>
          <li><b>Match the model to the job.</b> Sonnet handles most coding tasks and costs less than Opus. Save Opus for hard architecture and multi-step reasoning, and switch with <code>/model</code>.</li>
          <li><b>Lower the effort for routine work.</b> Extended thinking is billed as output. <code>/effort</code> turns it down for simple tasks.</li>
          <li><b>Trim MCP servers.</b> Run <code>/mcp</code> and turn off servers you aren't using. A CLI like <code>gh</code> is often cheaper than an MCP server for the same job.</li>
          <li><b>Move instructions into skills.</b> CLAUDE.md loads into every session. Workflow-specific instructions in skills only load when used. Keep CLAUDE.md under about 200 lines.</li>
          <li><b>Send noisy work to subagents.</b> Test runs, log digging, and doc fetching stay in the subagent's context, and only a summary comes back. Give simple subagents a smaller model.</li>
          <li><b>Be specific, and plan first.</b> "Add input validation to the login function in auth.ts" costs far less than "improve this codebase". Plan mode (Shift+Tab) catches a wrong direction before it's expensive.</li>
        </ol>"""},
            {"id": "forecast", "html": """
        <h2>See the wall before you hit it</h2>
        <p>Habits stretch your limit. Knowing your pace tells you when to use them. <a href="/">Fuel Gauge</a> is a free Mac menu bar app that reads your limits from Claude Code after every reply and says, at your recent pace, whether you'll make it to the reset: "Makes it to reset" or "Runs out around 3:40p, 1h 20m early", with the most you can use per hour and still make it. When it says you won't, that's the moment to switch to Sonnet, clear, or save the big job for after the reset.</p>
        <p>Agents can check too: <code>fuelgauge status</code> exits with code 2 when a limit will run out before it resets. See <a href="/cli">Fuel Gauge for agents</a>.</p>"""},
            {"id": "sources", "html": sources(
                ("Manage costs effectively (Claude Code docs)", COSTS),
                ("How do usage and length limits work?", USAGE))},
        ],
        "faqs": [
            ("Why do I hit my Claude limit so fast in Claude Code?", "Claude Code sends the whole conversation with every request, so long sessions, subagents, scheduled loops, and cache misses after breaks all add up. /usage shows what used it."),
            ("Does switching models help when I hit the limit?", "Not for the session or weekly limit, which cover every model. It does help after a model-specific message like \"You've hit your Opus limit\"."),
            ("What's the single biggest saver?", "Running /clear between unrelated tasks, so each request doesn't carry a long history it doesn't need."),
        ],
        "related": [
            ("Check your Claude usage", "Every place to see what's left", "/guides/check-claude-usage"),
            ("Claude Code limits", "How Claude Code counts against your plan", "/limits/claude-code"),
            ("Claude Pro vs Max", "When upgrading is worth it", "/compare/claude-pro-vs-max"),
        ],
    },
]

