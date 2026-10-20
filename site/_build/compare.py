# Plan comparisons, rendered by render.py with the same page template as limits and guides.
# Same sourcing rule as limits.py: only what the providers' own pages say, with sources on each page.

from limits import CODE, MAX, PRICING, SETTINGS, USAGE, sources

COMPARES = [
    {
        "path": "/compare/claude-pro-vs-max",
        "short": "Claude Pro vs Max",
        "card": "$20 or $100–$200 a month: what the extra usage buys",
        "title": "Claude Pro vs Max (October 2026): limits and when to upgrade",
        "description": "Claude Pro vs Max 5x and 20x: price, per-session usage, weekly limits, Claude Code, and how to tell from your own usage whether upgrading is worth it.",
        "eyebrow": "Compare plans",
        "h1": "Claude Pro vs Max",
        "lede": "Same features, same two kinds of limits. Max buys you more of each session: five or twenty times Pro's.",
        "answer": "Pro is $20 a month. Max 5x is $100 and gives five times Pro's usage per five-hour session; Max 20x is $200 and gives twenty times. All three have a session limit that resets every five hours and a weekly limit, shared with Claude Code. Upgrade when you hit your limits often enough that waiting costs you more than the difference.",
        "sections": [
            {"id": "facts", "facts": [
                ("Price", "Pro $20 a month ($17 billed yearly) · Max 5x $100 · Max 20x $200"),
                ("Usage per 5-hour session", "Pro: at least 5x Free · Max 5x: 5x Pro · Max 20x: 20x Pro"),
                ("Session limit", "All three reset every five hours"),
                ("Weekly limit", "All three; Max also has a separate weekly limit for Fable"),
                ("Claude Code", "Included in all three, sharing the same limits"),
                ("Wrap-up allowance in Claude Code", "Pro: once per weekly period · Max: each time you reach a 5-hour limit"),
                ("Billing", "Pro monthly or yearly · Max monthly only"),
            ], "html": """
        <h2>Pro vs Max at a glance</h2>
        {{FACTS}}"""},
            {"id": "decide", "lit": True, "html": f"""
        <h2>How to tell if you need Max</h2>
        <p>Anthropic doesn't publish message counts, so you can't pick a plan from a spec sheet. Your own usage is the better guide:</p>
        <ul>
          <li><strong>You hit the 5-hour limit most working days.</strong> Max 5x gives five times the room per session. That's the clearest signal.</li>
          <li><strong>You run Claude Code for hours, with subagents or loops.</strong> Long agentic sessions are what use plans up fastest.</li>
          <li><strong>You rarely see a limit warning.</strong> Stay on Pro, and try the habits in <a href="/guides/stop-hitting-claude-limits">how to stop hitting Claude limits</a> first.</li>
        </ul>
        <p>Upgrading applies right away, and moving up from Pro is prorated. Usage credits are the in-between option: keep Pro and pay for extra usage only when you go over.</p>
        <p>To check, open <a href="{SETTINGS}">Settings › Usage</a> or run <code>/usage</code> in Claude Code.</p>"""},
            {"id": "pace", "html": """
        <h2>Let your pace decide</h2>
        <p>The question isn't how much you used today. It's whether your usual pace makes it to the reset. <a href="/">Fuel Gauge</a> tracks that for every window and tells you, in the menu bar and under your Claude Code prompt, whether you'll make it. A week of "runs out early" on Pro is a good reason to try Max 5x. A week of "makes it, about 60% by then" means Pro is enough.</p>"""},
            {"id": "sources", "html": sources(
                ("What is the Max plan?", MAX),
                ("Use Claude Code with your Pro or Max plan", CODE),
                ("How do usage and length limits work?", USAGE),
                ("Claude pricing", PRICING))},
        ],
        "faqs": [
            ("Is Claude Max worth it over Pro?", "If you hit Pro's 5-hour or weekly limit most days, usually yes: Max 5x gives five times Pro's usage per session for $100 a month. If you rarely hit a limit, Pro is enough."),
            ("What's the difference between Claude Max 5x and 20x?", "Max 5x gives five times Pro's per-session usage for $100 a month; Max 20x gives twenty times for $200."),
            ("Do Pro and Max have the same weekly reset?", "Both have a weekly limit that resets at a fixed time assigned to your account. Settings › Usage shows yours."),
        ],
        "related": [
            ("Claude Pro limits", "Session and weekly, shared with Claude Code", "/limits/claude-pro"),
            ("Claude Max limits", "5x or 20x Pro's usage", "/limits/claude-max"),
            ("Stop hitting Claude limits", "What uses your limit fastest", "/guides/stop-hitting-claude-limits"),
        ],
    },
]
