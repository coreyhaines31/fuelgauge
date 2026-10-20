# Plan comparisons, rendered by render.py with the same page template as limits and guides.
# Same sourcing rule as limits.py: only what the providers' own pages say, with sources on each page.

from limits import CODE, CODEX_HELP, CODEX_PRICING, CURSOR_PRICING, CURSOR_USAGE, MAX, PRICING, SETTINGS, USAGE, sources

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
    {
        "path": "/compare/claude-code-vs-codex",
        "short": "Claude Code vs Codex",
        "card": "Plans, windows, and limits side by side",
        "title": "Claude Code vs Codex limits (October 2026): plans compared",
        "description": "Claude Code vs OpenAI Codex usage limits: plan prices, 5-hour and weekly windows, what's shared, how to check usage, and what each does when you hit the limit.",
        "eyebrow": "Compare plans",
        "h1": "Claude Code vs Codex: <em>usage limits</em>",
        "lede": "Both put a coding agent on a subscription with a 5-hour window and a weekly limit. The details differ: who gets which window, what's shared, and what happens at the wall.",
        "answer": "Claude Code comes with Claude Pro ($20) and Max ($100 or $200) and shares a 5-hour session limit and a weekly limit with your Claude chats. Codex comes with every ChatGPT plan; Plus ($20) and Business use 5-hour windows and may have weekly limits, while Pro plans ($100 to $500) have no 5-hour limit. Neither publishes a fixed message count for its main paid tiers.",
        "sections": [
            {"id": "facts", "html": """
        <h2>Side by side</h2>
        <div class="table-card glass"><div class="table-scroll"><table class="compare">
          <thead><tr><td></td><th scope="col">Claude Code</th><th scope="col">Codex</th></tr></thead><tbody>
            <tr><th scope="row">Entry paid plan</th><td>Claude Pro, $20 a month</td><td>ChatGPT Plus, $20 a month (Go $8)</td></tr>
            <tr><th scope="row">Bigger plans</th><td>Max 5x $100, Max 20x $200</td><td>Pro $100, $200, or $500</td></tr>
            <tr><th scope="row">Free plan</th><td>Not included</td><td>Included (no Codex Cloud)</td></tr>
            <tr><th scope="row">5-hour window</th><td>All plans</td><td>Plus and Business; Pro plans have none</td></tr>
            <tr><th scope="row">Weekly limit</th><td>Yes, at a fixed time per account</td><td>"May also apply"</td></tr>
            <tr><th scope="row">Shared with</th><td>claude.ai and Claude Desktop</td><td>Cloud chats (and other ChatGPT work tools on some plans)</td></tr>
            <tr><th scope="row">Published counts</th><td>None</td><td>Ranges per model for Plus/Business, "not fixed limits"</td></tr>
            <tr><th scope="row">Check usage</th><td><code>/usage</code>, Settings › Usage</td><td><code>/status</code>, chatgpt.com/codex/settings/usage</td></tr>
            <tr><th scope="row">Mid-turn at the limit</th><td>Small wrap-up allowance</td><td>Can finish the turn, subject to fair use</td></tr>
            <tr><th scope="row">Past the limit</th><td>Usage credits, upgrade, Console API, or wait</td><td>Credits, banked reset, upgrade, API key, or wait</td></tr>
          </tbody></table></div></div>"""},
            {"id": "which", "lit": True, "html": """
        <h2>Which gives you more room?</h2>
        <p>Neither company publishes enough to compare token for token, and both change limits often. The honest answer is to measure your own work: run the same kind of task on each for a few days and watch how fast each window fills.</p>
        <p>Two structural differences matter more than the price tags. Claude's limits are shared with your Claude chats, so heavy chat use leaves less for Claude Code. And Codex's Pro plans drop the 5-hour window entirely, so long sessions only run into the weekly limit.</p>
        <h2>Track both in one place</h2>
        <p><a href="/">Fuel Gauge</a> reads both on your Mac with no sign-in: Claude Code's limits from its status line, and Codex's from its session logs. Each window gets a forecast, so you can see which one you'll run out of first, and switch tools before you hit it.</p>"""},
            {"id": "sources", "html": sources(
                ("Use Claude Code with your Pro or Max plan", CODE),
                ("Claude pricing", PRICING),
                ("Codex pricing", CODEX_PRICING),
                ("Using Codex with your ChatGPT plan", CODEX_HELP))},
        ],
        "faqs": [
            ("Does Codex have a 5-hour limit like Claude Code?", "On Plus and Business, yes. Pro plans currently have no five-hour limit, though weekly limits may apply."),
            ("Is Claude Code or Codex cheaper?", "Both start at $20 a month for the entry paid plan. Codex is also included in ChatGPT Free and Go; Claude Code isn't included in Claude Free."),
            ("Can I track Claude Code and Codex limits together?", "Yes. Fuel Gauge reads both on your Mac and forecasts each window."),
        ],
        "related": [
            ("Claude Code limits", "How Claude Code counts against your plan", "/limits/claude-code"),
            ("Codex limits", "5-hour and weekly windows", "/limits/codex"),
            ("Cursor vs Claude Code", "Weekly pool vs session and weekly", "/compare/cursor-vs-claude-code"),
        ],
    },
    {
        "path": "/compare/cursor-vs-claude-code",
        "short": "Cursor vs Claude Code",
        "card": "A weekly pool vs session and weekly limits",
        "title": "Cursor vs Claude Code (October 2026): limits and pricing",
        "description": "Cursor vs Claude Code compared on what limits your work: Cursor's weekly usage pool vs Claude's 5-hour and weekly limits, plan prices, and what happens at the limit.",
        "eyebrow": "Compare tools",
        "h1": "Cursor vs Claude Code: <em>how the limits work</em>",
        "lede": "One is an editor with an agent, the other an agent in your terminal. Their plans meter usage differently, which matters once you work all day.",
        "answer": "Cursor's current plans (Plus $8 to Ultra $200) give one usage pool for Cursor models that refreshes weekly, shared with Grok; Claude and GPT models cost extra at API prices on Premium and up. Claude Code comes with Claude Pro ($20) or Max ($100 or $200), with a session limit every five hours and a weekly limit shared with your Claude chats.",
        "sections": [
            {"id": "facts", "html": """
        <h2>Side by side</h2>
        <div class="table-card glass"><div class="table-scroll"><table class="compare">
          <thead><tr><td></td><th scope="col">Cursor</th><th scope="col">Claude Code</th></tr></thead><tbody>
            <tr><th scope="row">Plans</th><td>Free, Plus $8, Premium $30, Super $100, Ultra $200</td><td>Pro $20, Max 5x $100, Max 20x $200</td></tr>
            <tr><th scope="row">What's metered</th><td>One weekly pool for Cursor models</td><td>A 5-hour session limit and a weekly limit</td></tr>
            <tr><th scope="row">Shared with</th><td>Grok Bot and the Grok apps</td><td>claude.ai and Claude Desktop</td></tr>
            <tr><th scope="row">Claude models</th><td>Premium and up, at API list price from prepaid credit</td><td>Included in the plan</td></tr>
            <tr><th scope="row">Past the limit</th><td>Prepaid credit, upgrade, or wait; never downgraded</td><td>Usage credits, upgrade, Console API, or wait</td></tr>
            <tr><th scope="row">Check usage</th><td>grok.com/dashboard or editor settings</td><td><code>/usage</code>, Settings › Usage</td></tr>
          </tbody></table></div></div>
        <p class="table-foot">Cursor's legacy plans (Pro, Pro+, Ultra) use monthly pools instead; see <a href="/limits/cursor">Cursor limits</a>.</p>"""},
            {"id": "which", "lit": True, "html": """
        <h2>Which fits how you work?</h2>
        <p>A weekly pool forgives one heavy day: Cursor says its allowance "refreshes weekly, so one heavy day never wipes out your whole month." Claude's 5-hour session limit is stricter in the moment but comes back within hours; its weekly limit is the one that ends a heavy week.</p>
        <p>If you want Claude models specifically, Claude Code includes them in the plan, while Cursor bills them at API prices on top. If you mostly use Cursor's own models, Cursor's pool goes further.</p>
        <p>Many people use both. <a href="/">Fuel Gauge</a> forecasts Claude Code's limits from its status line, and can read Cursor and Grok Bot too, so you see which one you'll run out of first.</p>"""},
            {"id": "sources", "html": sources(
                ("Models and pricing (Cursor docs)", CURSOR_PRICING),
                ("Usage limits (Cursor help)", CURSOR_USAGE),
                ("Cursor pricing", "https://cursor.com/pricing"),
                ("Use Claude Code with your Pro or Max plan", CODE),
                ("Claude pricing", PRICING))},
        ],
        "faqs": [
            ("Is Cursor or Claude Code cheaper?", "Cursor's paid plans start at $8 a month; Claude Code starts with Claude Pro at $20. What you get differs: Cursor's pool covers Cursor models, while Claude plans include Claude models."),
            ("Can I use Claude models in Cursor?", "Yes, on Premium and up, billed at the model's API list price from prepaid credit."),
            ("Does Cursor have a 5-hour limit?", "No. Cursor's current plans have one pool that refreshes weekly."),
        ],
        "related": [
            ("Cursor limits", "One weekly pool on the new plans", "/limits/cursor"),
            ("Claude Code limits", "How Claude Code counts against your plan", "/limits/claude-code"),
            ("Claude Code vs Codex", "Limits side by side", "/compare/claude-code-vs-codex"),
        ],
    },
]
