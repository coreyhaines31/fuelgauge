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
    {
        "path": "/compare/claude-code-pricing",
        "short": "Claude Code pricing",
        "card": "Pro, Max, Team, Enterprise, or pay per token",
        "title": "Claude Code pricing (October 2026): every plan and the API",
        "description": "What Claude Code costs: Pro $20, Max $100 or $200, Team and Enterprise seats, or API billing per token. What each plan's limits mean, and how to pick.",
        "eyebrow": "Pricing",
        "h1": "Claude Code pricing",
        "lede": "There's no separate Claude Code subscription. It comes with every paid Claude plan, or you pay per token through the Claude Console.",
        "answer": "Claude Code is included with Claude Pro ($20 a month, or $17 billed yearly), Max 5x ($100), Max 20x ($200), Team, and Enterprise. It isn't included in Claude Free. On a plan, Claude Code shares the plan's 5-hour session limit and weekly limit with your Claude chats. You can also skip the plan and pay per token at standard API rates through the Claude Console.",
        "sections": [
            {"id": "facts", "facts": [
                ("Free", "$0 · Claude Code not included"),
                ("Pro", "$20 a month, or $17 a month billed yearly ($200 up front)"),
                ("Max 5x", "$100 a month · 5x Pro's usage per session"),
                ("Max 20x", "$200 a month · 20x Pro's usage per session"),
                ("Team", "Standard seat $20 billed yearly ($25 monthly) · Premium seat $100 yearly ($125 monthly) · 2 to 150 people"),
                ("Enterprise", "$20 a seat a month billed yearly, 20-seat minimum, plus usage that scales with model and task"),
                ("API (Claude Console)", "No subscription; pay per token at standard API rates"),
            ], "html": """
        <h2>Every way to pay for Claude Code</h2>
        {{FACTS}}
        <p class="table-foot">Prices in US dollars, from Anthropic's pricing page on October 20, 2026.</p>"""},
            {"id": "limits", "lit": True, "html": """
        <h2>What the price buys: limits, not messages</h2>
        <p>Anthropic doesn't sell Claude Code by the message or the token on a subscription. Each plan buys a share of usage, capped two ways: a session limit that resets every five hours, and a weekly limit. Claude, Claude Desktop, and Claude Code all draw from the same limits, so heavy chat use leaves less for coding.</p>
        <p>That makes the plans hard to compare on paper. Pro gives at least five times the Free plan's usage per session, Max 5x five times Pro's, and Max 20x twenty times Pro's, but none of them comes with a message count. The details are on the <a href="/limits/claude-pro">Pro</a>, <a href="/limits/claude-max">Max</a>, and <a href="/limits/claude-code">Claude Code</a> limits pages.</p>"""},
            {"id": "pick", "html": """
        <h2>Which plan to pick</h2>
        <ul>
          <li><strong>Start on Pro</strong> unless you already know you work in long agent sessions. It's the cheapest way to find out how fast you use a session.</li>
          <li><strong>Move to Max 5x</strong> when you hit the 5-hour limit most working days. Upgrading applies right away and is prorated. <a href="/compare/claude-pro-vs-max">Pro vs Max</a> goes through the signs.</li>
          <li><strong>Max 20x</strong> is for running Claude Code most of the day, with subagents or loops.</li>
          <li><strong>Pay per token</strong> if you use Claude Code a few times a month, or need it billed to a company API account.</li>
        </ul>"""},
            {"id": "api", "lit": True, "html": f"""
        <h2>Subscription or API billing?</h2>
        <p>Claude Code can bill API credits at standard API rates instead of your plan. That's useful as overflow, but easy to do by accident: if an <code>ANTHROPIC_API_KEY</code> is set in your environment, Claude Code uses it. To stay on your plan, run <code>claude logout</code>, then <code>claude login</code> and sign in with your Pro or Max account.</p>
        <p>Two things that don't count toward Claude Code: the monthly API credits that come with Max can't be used in Claude Code or the Claude apps. Usage credits can, though: turn them on in <a href="{SETTINGS}">Settings › Usage</a> to keep working past a limit at API rates.</p>"""},
            {"id": "pace", "html": """
        <h2>Are you on the right plan?</h2>
        <p>The price you need depends on your pace, not on a spec sheet. <a href="/">Fuel Gauge</a> is a free Mac menu bar app that reads your Claude Code limits after every reply and tells you whether you'll make it to the reset. A week of "runs out early" is a reason to move up; a week of "makes it, about 50% by then" means you could pay less.</p>"""},
            {"id": "sources", "html": sources(
                ("Claude pricing", PRICING),
                ("Use Claude Code with your Pro or Max plan", CODE),
                ("What is the Max plan?", MAX),
                ("How do usage and length limits work?", USAGE))},
        ],
        "faqs": [
            ("How much does Claude Code cost?", "Claude Code comes with Claude Pro ($20 a month, or $17 billed yearly), Max ($100 or $200 a month), Team, and Enterprise. Or you can pay per token at API rates through the Claude Console."),
            ("Is Claude Code free?", "No. Claude Free doesn't include Claude Code. Pro at $20 a month is the cheapest plan that does."),
            ("Can I use Claude Code with an API key instead of a plan?", "Yes. Claude Code can bill API credits at standard API rates through the Claude Console. If ANTHROPIC_API_KEY is set, Claude Code uses it instead of your subscription."),
            ("Do the Max plan's API credits work in Claude Code?", "No. The monthly API credits included with Max can't be used in Claude Code or the Claude apps."),
        ],
        "related": [
            ("Claude Pro vs Max", "What the extra usage buys", "/compare/claude-pro-vs-max"),
            ("Claude Code limits", "How Claude Code counts against your plan", "/limits/claude-code"),
            ("Codex pricing", "ChatGPT plans, credits, and the API", "/compare/codex-pricing"),
        ],
    },
    {
        "path": "/compare/codex-pricing",
        "short": "Codex pricing",
        "card": "Every ChatGPT plan, credits, or an API key",
        "title": "Codex pricing (October 2026): ChatGPT plans, credits, API",
        "description": "What OpenAI Codex costs: included in every ChatGPT plan from Free to Pro, plus credits for extra usage or API billing. What each plan's limits look like.",
        "eyebrow": "Pricing",
        "h1": "Codex pricing",
        "lede": "Codex doesn't have its own price. It comes with every ChatGPT plan, and you can add credits or use an API key when the plan runs out.",
        "answer": "Codex is included with every ChatGPT plan: Free, Go ($8 a month), Plus ($20), Pro ($100, $200, or $500), Business ($20 a user a month billed yearly, $25 monthly), and Enterprise and Edu. Plus and Business use 5-hour windows and weekly limits may apply; Pro has no 5-hour limit. Past the limit, Plus and Pro can buy credits, or you can sign in with an API key and pay API rates.",
        "sections": [
            {"id": "facts", "facts": [
                ("Free", "$0 · for quick coding tasks"),
                ("Go", "$8 a month · for lightweight coding tasks"),
                ("Plus", "$20 a month · 5-hour windows, weekly limits may apply"),
                ("Pro", "$100, $200, or $500 a month · no 5-hour limit"),
                ("Business", "$20 a user a month billed yearly, $25 monthly, 2 or more users"),
                ("Enterprise and Edu", "Contact sales; flexible pricing scales with credits"),
                ("API key", "Usage-based, at standard API rates"),
            ], "html": """
        <h2>Every way to pay for Codex</h2>
        {{FACTS}}
        <p class="table-foot">Prices in US dollars, from OpenAI's Codex pricing page on October 20, 2026.</p>"""},
            {"id": "plus", "lit": True, "html": """
        <h2>How much Plus gets you</h2>
        <p>OpenAI publishes rough ranges for Plus and Standard Business: local messages per 5-hour window, by model. They're ranges, not fixed limits, because a message's cost depends on how much code and context it involves. Cloud tasks can use more than local messages, and both share the same allowance.</p>
        <div class="table-card glass"><div class="table-scroll"><table class="compare">
          <thead><tr><th scope="col">Model</th><th scope="col">Local messages per 5 hours</th></tr></thead><tbody>
            <tr><th scope="row">GPT-6 Astra</th><td>5–45</td></tr>
            <tr><th scope="row">GPT-6.1 Sol</th><td>15–160</td></tr>
            <tr><th scope="row">GPT-6 Sol</th><td>15–150</td></tr>
            <tr><th scope="row">GPT-6 Luna</th><td>350–3,000</td></tr>
          </tbody></table></div></div>
        <p>Picking a lighter model for routine work stretches a window the furthest. The <a href="/limits/codex">Codex limits page</a> covers the windows and how to check them.</p>"""},
            {"id": "credits", "html": """
        <h2>Credits, when the plan runs out</h2>
        <p>Plus and Pro can buy credits to keep going after a limit, and Business, Edu, and Enterprise workspaces on flexible pricing buy workspace credits. Credits are charged per million tokens, at a rate set per model: GPT-6.1 Sol is 50 credits per million input tokens and 250 per million output, and GPT-6 Luna is 2.5 and 12.5. OpenAI says a typical GPT-5.6 Sol task uses 2 to 15 credits. Fast mode costs twice the standard rate and Ultrafast six times.</p>
        <p>The other option is an API key: sign Codex in with it and you pay standard API rates, with no plan limits.</p>"""},
            {"id": "pace", "lit": True, "html": """
        <h2>Know before you need credits</h2>
        <p><a href="/">Fuel Gauge</a> is a free Mac menu bar app that reads Codex's limits from its session logs on your Mac, with no sign-in, and forecasts whether each window lasts until it resets. If it says "runs out around 3p" on most days, a bigger plan is cheaper than buying credits; if it says "makes it" every day, you might not need the plan you're on.</p>"""},
            {"id": "sources", "html": sources(
                ("Codex pricing", CODEX_PRICING),
                ("Using Codex with your ChatGPT plan", CODEX_HELP))},
        ],
        "faqs": [
            ("How much does Codex cost?", "Codex is included with every ChatGPT plan: Free, Go ($8), Plus ($20), Pro ($100, $200, or $500), Business ($20 a user billed yearly), and Enterprise. You can also pay API rates with an API key."),
            ("Is Codex free?", "Yes, Codex is included in ChatGPT Free, for quick coding tasks. Paid plans give more usage."),
            ("Does Codex Pro have a 5-hour limit?", "No. Pro plans currently have no five-hour limit, though weekly limits may apply."),
            ("What happens when I run out of Codex usage?", "Wait for the window to reset, buy credits on Plus or Pro, upgrade, or switch to an API key."),
        ],
        "related": [
            ("Codex limits", "5-hour and weekly windows", "/limits/codex"),
            ("Claude Code vs Codex", "Limits side by side", "/compare/claude-code-vs-codex"),
            ("Claude Code pricing", "Every plan that includes it, and the API", "/compare/claude-code-pricing"),
        ],
    },
]
