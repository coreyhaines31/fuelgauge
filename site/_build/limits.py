# The limits library: one page per plan, rendered by render.py.
#
# Every fact here comes from the provider's own help pages, linked in each page's Sources. Plans change often:
# re-check each value against those pages before shipping a change, and update VERIFIED when you do.
# Anthropic doesn't publish message or token counts for any plan, so never state one.

VERIFIED = "October 20, 2026"

USAGE = "https://support.claude.com/en/articles/11647753-how-do-usage-and-length-limits-work"
MAX = "https://support.claude.com/en/articles/11049741-what-is-the-max-plan"
CODE = "https://support.claude.com/en/articles/11145838-use-claude-code-with-your-pro-or-max-plan"
FREE = "https://support.claude.com/en/articles/8602283-about-free-claude-usage"
PRICING = "https://claude.com/pricing"
COSTS = "https://code.claude.com/docs/en/costs"
SETTINGS = "https://claude.ai/settings/usage"
CODEX_PRICING = "https://learn.chatgpt.com/docs/pricing"
CODEX_HELP = "https://help.openai.com/en/articles/11369540-using-codex-with-your-chatgpt-plan"
CODEX_USAGE = "https://chatgpt.com/codex/settings/usage"
CURSOR_PRICING = "https://cursor.com/docs/models-and-pricing"
CURSOR_USAGE = "https://cursor.com/help/models-and-usage/usage-limits"
CURSOR_LEGACY = "https://cursor.com/docs/account/pricing/legacy-cursor-plans"
GROK_FAQ = "https://grok.com/faq"
GROK_BOT_PLANS = "https://cursor.com/help/grok-bot/plans"
COPILOT_BLOG = "https://github.blog/news-insights/company-news/github-copilot-is-moving-to-usage-based-billing/"
COPILOT_BILLING = "https://docs.github.com/en/copilot/concepts/billing/billing-for-individuals"
COPILOT_ORGS = "https://docs.github.com/en/copilot/concepts/billing/usage-based-billing-for-organizations-and-enterprises"
COPILOT_PLANS = "https://github.com/features/copilot/plans"
COPILOT_LEGACY = "https://docs.github.com/en/copilot/concepts/billing/copilot-requests"
ULTRA = "https://support.claude.com/en/articles/17728952-what-is-the-ultra-plan"
PRO = "https://support.claude.com/en/articles/8325606-what-is-the-pro-plan"
TEAM = "https://support.claude.com/en/articles/9266767-what-is-the-team-plan"
FABLE_PLAN = "https://support.claude.com/en/articles/15424964-claude-fable-models-on-your-plan"
LIMIT_RESET = "https://support.claude.com/en/articles/17007452-what-is-a-limit-reset"
FABLE_OFFERS = "https://support.claude.com/en/articles/17506494-claude-fable-5-2-launch-offers"
GET_STARTED = "https://support.claude.com/en/articles/8114491-get-started-with-claude"
STATUSLINE = "https://code.claude.com/docs/en/statusline"
CHECKED = "November 17, 2026"


def sources(*links, checked=VERIFIED):
    items = "".join(f'<li><a href="{url}">{name}</a></li>' for name, url in links)
    return f"""
        <h2>Sources</h2>
        <p>Checked on {checked}. Plans change from time to time, so the providers' own pages are the final word.</p>
        <ul>{items}</ul>"""


FORECAST = """
        <h2>Will you make it to the reset?</h2>
        <p>A percentage tells you how much you've used. It doesn't tell you whether, at the pace you're going, you'll run out before the window resets. <a href="/">Fuel Gauge</a> does that math: a free Mac menu bar app that reads your Claude Code limits after every reply and says "Makes it to reset" or "Runs out around 3:40p, 1h 20m early". It can put the same line under your Claude Code prompt.</p>"""

LIMITS = [
    {
        "path": "/limits/claude",
        "short": "Claude usage limits",
        "card": "Every plan: the 5-hour session, the weekly limit, and Fable",
        "hub_windows": "5-hour session (none on verified Ultra), weekly, weekly Fable cap on Max and Ultra",
        "hub_reset": "5 hours after your first message; weekly at a set time for your account",
        "title": "Claude usage limits (November 2026): every plan explained",
        "description": "How Claude usage limits work on Free, Pro, Max, Ultra, and Team: the 5-hour session limit, the weekly limit, the Fable cap, and how to check yours.",
        "eyebrow": "Claude",
        "h1": "Claude usage limits",
        "lede": "Paid Claude plans meter your usage in two windows: a session that resets five hours after your first message, and a week that resets at a fixed time set for your account. Chat, Claude Desktop, and Claude Code all draw from the same limits.",
        "answer": "Paid Claude plans have a 5-hour session limit and a weekly limit, shared across claude.ai, Claude Desktop, and Claude Code. Pro costs $20 a month. Max ($100) gives 5x Pro's usage every five hours and every week. Ultra ($200, formerly Max 20x) gives 10x Pro's weekly usage and has no 5-hour limit once your account is verified. Max and Ultra can spend up to half the weekly limit on Fable. Anthropic doesn't publish message counts for any plan. Settings › Usage shows where you stand.",
        "sections": [
            {"id": "facts", "facts": [
                ("Free", "$0 · A session limit that resets every five hours; how much fits changes with demand · No Claude Code"),
                ("Pro", "$20 a month, or $17 a month billed yearly · 5-hour and weekly limits · Fable runs on usage credits"),
                ("Max", "$100 a month · 5x Pro's usage every five hours and every week · Fable up to 50% of the weekly limit"),
                ("Ultra", "$200 a month · 10x Pro's usage every week · No 5-hour limit on verified accounts · Fable up to 50% of the weekly limit"),
                ("Team", "Standard seat: 1.25x Pro's per-session usage · Premium seat: 6.25x · Each member has their own weekly limit"),
                ("Enterprise", "Seat-based plans have seat limits; usage-based plans are billed by what you use"),
                ("Shared by", "claude.ai, Claude Desktop, and Claude Code, including Claude Code in VS Code, Cursor, and JetBrains"),
                ("Check it", f'<a href="{SETTINGS}">Settings › Usage</a> on claude.ai, or <code>/usage</code> in Claude Code'),
            ], "html": """
        <h2>Claude usage limits by plan</h2>
        {{FACTS}}
        <p class="table-foot">Anthropic states every allowance relative to another plan, never as a message or token count.</p>"""},
            {"id": "how", "lit": True, "html": """
        <h2>How the 5-hour limit works</h2>
        <p>The session window starts when you send your first message and resets in full five hours later. If you hit the limit before then, you're paused until the reset. Settings › Usage shows the time left under <strong>Current session</strong>.</p>
        <p>Verified Ultra accounts have no 5-hour limit, just the weekly one. A new Ultra account has a temporary limit until Anthropic verifies it, which happens on its own. If you don't see a Current session bar, your account is verified.</p>
        <h2>How the weekly limit works</h2>
        <p>The weekly limit covers every model and caps your total for the week, however you spread it across sessions. It resets at a fixed day and time assigned to your account. It stays the same regardless of when your subscription began or when you started using Claude. The <a href="/limits/claude-weekly-limit">Claude weekly limit</a> page covers it in detail.</p>
        <h2>The Fable allowance</h2>
        <p>On Max, Ultra, and Team premium seats, Fable models come with the plan, and you can spend up to 50% of your weekly limit on them. That's a cap inside the weekly limit, not extra room on top of it. On Pro and Team standard seats, Fable isn't part of the plan's limits and runs on usage credits.</p>
        <h3>What uses it up faster</h3>
        <ul>
          <li>Long conversations, since each message carries the history before it</li>
          <li>Bigger models, Fable especially, and higher effort levels</li>
          <li>Tools and connectors, which use a lot of tokens</li>
          <li>Long chats that hit automatic context management, which summarizes earlier messages and costs extra usage</li>
        </ul>"""},
            {"id": "limit", "html": """
        <h2>What happens when you hit a Claude limit</h2>
        <p>Claude warns you as you get close. At the limit you have three options:</p>
        <ul>
          <li><strong>Wait</strong> for the session or the week to reset.</li>
          <li><strong>Turn on <a href="https://support.claude.com/en/articles/12429409-manage-usage-credits-for-paid-claude-plans">usage credits</a></strong> and keep working at extra cost.</li>
          <li><strong>Upgrade</strong>: Pro to Max, or Max to Ultra. The new limits apply right away.</li>
        </ul>
        <p>Sometimes Anthropic gives an account a <strong>limit reset</strong>, which refills the 5-hour or weekly limit on the spot. Use it from Settings › Usage or from the message you see at the limit. The button isn't in Claude Code in the terminal, but the usage it restores counts there too.</p>
        <h3>In Claude Code</h3>
        <p>If you hit the 5-hour limit partway through a response, Claude Code can finish the step in progress ("Usage limit reached · wrapping up"). On Pro that happens at most once per week; on Max it can happen at every 5-hour limit. It counts toward your weekly limit.</p>
        <p>Two traps. If <code>ANTHROPIC_API_KEY</code> is set in your shell, Claude Code bills that key instead of your plan. And the monthly API credits that come with Max and Ultra don't cover Claude Code or the Claude apps.</p>"""},
            {"id": "check", "lit": True, "html": """
        <h2>How to see your Claude usage</h2>
        <ul>
          <li><strong><a href="https://claude.ai/settings/usage">Settings › Usage</a></strong> on claude.ai, Claude Desktop, or mobile: the current session, the weekly limit, the Fable allowance where your plan has one, and your next reset.</li>
          <li><strong><code>/usage</code></strong> in Claude Code: plan usage bars, plus a breakdown of what used them.</li>
          <li><strong>The Claude Code status line</strong> gets your 5-hour and weekly percentages after every reply on Pro, Max, and Ultra. <a href="/guides/claude-code-statusline">Here's how to show them</a>.</li>
        </ul>
        <p>More detail: <a href="/guides/check-claude-usage">every way to check your Claude usage</a>.</p>
        <h2>Will you make it to the reset?</h2>
        <p>A percentage says how much you've used. It doesn't say whether you'll run out before the window resets. <a href="/">Fuel Gauge</a> is a free Mac menu bar app that does that math: "Makes it to reset" or "Runs out around 3:40p, 1h 20m early". You find out in time to switch to a cheaper model or save the big job for after the reset.</p>
        <p>What it can and can't see:</p>
        <ul>
          <li><strong>5-hour and weekly limits</strong> come from Claude Code, which reports them after every reply. They're your plan's numbers, so they include what you used in chat. They only refresh when Claude Code replies.</li>
          <li><strong>The Fable allowance</strong> comes from your installed Claude Code once an hour. No prompt is sent, so it costs no usage.</li>
          <li><strong>Plans</strong>: Pro, Max, and Ultra, the plans Claude Code reports limits for. If you only chat on claude.ai and never use Claude Code, Fuel Gauge has nothing to read.</li>
        </ul>"""},
            {"id": "sources", "html": sources(
                ("How do usage and length limits work?", USAGE),
                ("Claude pricing", PRICING),
                ("What is the Pro plan?", PRO),
                ("What is the Max plan?", MAX),
                ("What is the Ultra plan?", ULTRA),
                ("What is the Team plan?", TEAM),
                ("Claude Fable models on your plan", FABLE_PLAN),
                ("What is a limit reset?", LIMIT_RESET),
                ("Use Claude Code with your Pro, Max, or Ultra plan", CODE),
                ("Get started with Claude (Free plan limits)", GET_STARTED),
                ("Status line (Claude Code docs)", STATUSLINE),
                checked=CHECKED)},
        ],
        "faqs": [
            ("What are Claude's usage limits?", "Paid plans have a session limit that resets five hours after your first message and a weekly limit that resets at a fixed time for your account. Max and Ultra also cap Fable at up to half the weekly limit. Free has a 5-hour session limit that changes with demand."),
            ("Does Claude have a daily limit?", "No. The windows are a five-hour session and a week. Anthropic says it may add other caps to manage capacity."),
            ("How many messages can I send on Claude?", "Anthropic doesn't publish a number for any plan. It depends on conversation length, files, the model, the effort level, and the features you use."),
            ("Do Claude and Claude Code share the same limit?", "Yes. claude.ai, Claude Desktop, and Claude Code all count toward the same limits."),
            ("What happened to Claude Max 20x?", "It's now the Ultra plan. Max 20x subscribers moved to Ultra automatically with no price change. Ultra gives 10x Pro's weekly usage and has no 5-hour limit on verified accounts."),
            ("Is there an unlimited Claude plan?", "No. Every plan has limits. On a paid plan, usage credits let you keep working past them, and usage-based Enterprise plans are billed by consumption."),
        ],
        "related": [
            ("The Claude weekly limit", "When it resets and how Fable fits in", "/limits/claude-weekly-limit"),
            ("When do Claude limits reset?", "Session and weekly resets, explained", "/guides/when-does-claude-limit-reset"),
            ("Stop hitting Claude limits", "What actually stretches your plan", "/guides/stop-hitting-claude-limits"),
        ],
    },
    {
        "path": "/limits/claude-weekly-limit",
        "short": "Claude weekly limit",
        "card": "The fixed weekly reset, the Fable cap, and limit resets",
        "hub_windows": "Weekly, across all models; Fable capped at half on Max and Ultra",
        "hub_reset": "Once a week, at a fixed day and time for your account",
        "title": "Claude weekly limit (November 2026): how it works and resets",
        "description": "How Claude's weekly limit works on Pro, Max, Ultra, and Team: the fixed weekly reset time, the Fable cap, limit resets, and what to do when you hit it.",
        "eyebrow": "Claude",
        "h1": "The Claude weekly limit",
        "lede": "The weekly limit caps your total for the week, however you spread it across sessions. It resets at the same day and time every week, set for your account.",
        "answer": "Every paid Claude plan has a weekly limit. It applies across all models and is shared by claude.ai, Claude Desktop, and Claude Code. It resets at a fixed time each week assigned to your account, not when you subscribed or first used Claude, and you get the full allowance back each cycle. On Max and Ultra, Fable can use up to half of it. Settings › Usage shows your next reset.",
        "sections": [
            {"id": "facts", "facts": [
                ("Plans", "Pro, Max, Ultra, and Team seats"),
                ("Covers", "All models, across claude.ai, Claude Desktop, and Claude Code"),
                ("Resets", "Once a week, at a fixed day and time assigned to your account"),
                ("Doesn't depend on", "When your subscription began or when you started using Claude"),
                ("Size", "Max: 5x Pro's · Ultra: 10x Pro's · Anthropic doesn't publish it as a message count"),
                ("Fable", "Max, Ultra, Team premium seats: up to 50% of the weekly limit · Pro, Team standard seats: usage credits instead"),
                ("Check it", f'<a href="{SETTINGS}">Settings › Usage</a> shows your next reset'),
                ("At the limit", "Wait, turn on usage credits, upgrade, or use a limit reset if you have one"),
            ], "html": """
        <h2>The Claude weekly limit at a glance</h2>
        {{FACTS}}"""},
            {"id": "how", "lit": True, "html": """
        <h2>Weekly limit vs the 5-hour limit</h2>
        <p><strong>The 5-hour limit</strong> starts with your first message and resets five hours later. It's the one that stops a long afternoon session.</p>
        <p><strong>The weekly limit</strong> adds up every session. A few heavy days can use it up even if no single session hit its cap, and then you wait for the weekly reset, not the next five-hour window.</p>
        <p>On a verified Ultra account there's no 5-hour limit at all, so the weekly limit is the only one you'll hit.</p>
        <h3>Switching models won't get you around it</h3>
        <p>The weekly limit covers every model. Moving to a smaller model stretches what's left, but once the limit is reached, every model is paused until the reset.</p>
        <h2>How the Fable cap fits in</h2>
        <p>On Max, Ultra, and Team premium seats, you can spend up to 50% of your weekly limit on Fable models. That's a cap inside the weekly limit, not 50% extra. Say you've used 40% of your week on Fable and 30% on other models: you can spend another 10% on Fable, and 30% of the week is left in total.</p>
        <p>When you hit the Fable cap, switch to another model to keep working within your plan, or keep using Fable on usage credits. On Pro and Team standard seats, Fable runs on usage credits from the start and doesn't count toward the weekly limit.</p>"""},
            {"id": "resets", "html": """
        <h2>Limit resets</h2>
        <p>Anthropic occasionally gives accounts a limit reset. A weekly reset refills your weekly limit right away. A Fable reset gives back only what you spent on Fable, and refills the 5-hour window if you have one. Either way, your regular reset day and time stay the same.</p>
        <p>To use one, open Settings › Usage on the web, desktop, or mobile app and choose "Reset for free". The same button appears on the message you see at the limit. It isn't in Claude Code in the terminal, but the usage it restores applies there too. A reset can't be undone, and it's gone if you downgrade or cancel first.</p>
        <p>For the Fable 5.2 launch, Max, Ultra, and Team premium subscribers with paid billing in place before 10:00 am PT on November 9, 2026 got one to three Fable resets, depending on how long they've subscribed. Those expire March 8, 2027 at 11:59 pm PT.</p>
        <h2>What to do when you hit it</h2>
        <ul>
          <li><strong>Wait</strong> for the weekly reset. Settings › Usage shows when.</li>
          <li><strong>Turn on usage credits</strong> to keep going at extra cost. On Max and Ultra they also work past the Fable cap.</li>
          <li><strong>Upgrade</strong> from Pro to Max, or Max to Ultra. The new limit applies right away.</li>
        </ul>
        <p>In Claude Code, the wrap-up allowance that lets a step finish at the 5-hour limit counts toward your weekly limit. The monthly API credits on Max and Ultra can't be used in Claude Code or the Claude apps.</p>"""},
            {"id": "forecast", "lit": True, "html": """
        <h2>Will your week last?</h2>
        <p>With three days to go, 60% used can be fine or a problem. It depends on how you'll use the rest of the week. <a href="/">Fuel Gauge</a>, a free Mac menu bar app, reads your weekly limit from Claude Code after every reply and forecasts whether you'll make it to the reset: "Makes it to reset, about 70% by then", or when you'll run out.</p>
        <p>After about two weeks of readings it learns your usual hours and your weekday and weekend patterns, so a quiet weekend ahead counts. It tracks the Fable cap as its own limit. When your week won't last, it says whether one of your saved limit resets would fix it, and which one. It can't use a reset for you.</p>
        <p>It works with Pro, Max, and Ultra, through Claude Code. Your chat usage is in the numbers, since the limit is shared, but the reading only updates when Claude Code replies.</p>"""},
            {"id": "sources", "html": sources(
                ("How do usage and length limits work?", USAGE),
                ("What is the Max plan?", MAX),
                ("What is the Ultra plan?", ULTRA),
                ("What is the Team plan?", TEAM),
                ("Claude Fable models on your plan", FABLE_PLAN),
                ("What is a limit reset?", LIMIT_RESET),
                ("Claude Fable 5.2 launch offers", FABLE_OFFERS),
                ("Use Claude Code with your Pro, Max, or Ultra plan", CODE),
                checked=CHECKED)},
        ],
        "faqs": [
            ("When does the Claude weekly limit reset?", "Once a week, at a fixed day and time assigned to your account. Settings › Usage on claude.ai shows your next reset."),
            ("Why does my weekly limit reset on a different day than someone else's?", "Each account gets its own weekly reset time. It isn't a calendar day everyone shares."),
            ("Does my subscription date set my weekly reset?", "No. Your reset day and time stay the same regardless of when your subscription began or when you started using Claude."),
            ("Does the Fable limit add to my weekly limit?", "No. On Max and Ultra you can spend up to half your weekly limit on Fable, but all models draw from the same weekly limit."),
            ("Can I reset my Claude weekly limit early?", "Only with a limit reset, if Anthropic has given your account one. Otherwise usage credits let you keep working until the reset."),
            ("Does Claude Code have its own weekly limit?", "No. Claude Code shares your plan's weekly limit with claude.ai and Claude Desktop."),
        ],
        "related": [
            ("Claude usage limits", "Every plan's limits in one place", "/limits/claude"),
            ("When do Claude limits reset?", "Session and weekly resets, explained", "/guides/when-does-claude-limit-reset"),
            ("Check your Claude usage", "Every place to see what's left", "/guides/check-claude-usage"),
        ],
    },
    {
        "path": "/limits/claude-pro",
        "short": "Claude Pro limits",
        "card": "5-hour session and weekly limits, shared with Claude Code",
        "hub_windows": "5-hour session, weekly",
        "hub_reset": "Every 5 hours; weekly at a set time for your account",
        "title": "Claude Pro usage limits (November 2026): session and weekly",
        "description": "How Claude Pro's limits work: a 5-hour session limit and a weekly limit, shared across Claude and Claude Code. When they reset and how to check.",
        "eyebrow": "Claude Pro",
        "h1": "Claude Pro usage limits",
        "lede": "Pro has two limits: a session limit that resets every five hours, and a weekly limit. Claude, Claude Desktop, and Claude Code all draw from both.",
        "answer": "Claude Pro ($20 a month, or $17 a month billed yearly) gives you more usage per session than the Free plan. Usage is capped by a 5-hour session limit and a weekly limit, shared across claude.ai, Claude Desktop, and Claude Code. Anthropic doesn't publish a message count; how far it goes depends on conversation length, model, features, and effort. Fable models aren't part of Pro's limits; they run on usage credits.",
        "sections": [
            {"id": "facts", "facts": [
                ("Price", "$20 a month, or $17 a month billed yearly ($200 up front)"),
                ("Usage", "More per session than the Free plan; Anthropic doesn't publish a multiple"),
                ("Fable", "Not in the plan's limits; runs on usage credits"),
                ("Session limit", "Resets every five hours"),
                ("Weekly limit", "Yes, resets once a week"),
                ("Shared with", "claude.ai, Claude Desktop, Claude Code, and Claude Code in VS Code, Cursor, and JetBrains"),
                ("Claude Code", "Included"),
                ("Check it", f'<a href="{SETTINGS}">Settings › Usage</a> on claude.ai, or <code>/usage</code> in Claude Code'),
                ("At the limit", "Wait for the reset, turn on usage credits, or upgrade to Max or Ultra"),
            ], "html": """
        <h2>Claude Pro limits at a glance</h2>
        {{FACTS}}"""},
            {"id": "how", "lit": True, "html": """
        <h2>How the two limits work together</h2>
        <p><strong>The session limit</strong> resets every five hours. It's the one you hit in the middle of a long working session.</p>
        <p><strong>The weekly limit</strong> caps your total for the week, however you spread it across sessions. It resets once a week, so a few heavy days can use it up even if no single session hit its cap.</p>
        <p>Both count everything: chats on claude.ai and the desktop app, and every Claude Code request, including Claude Code inside VS Code, Cursor, and JetBrains. Using Claude Code heavily in the afternoon leaves less for chat in the evening.</p>
        <h3>What uses it up faster</h3>
        <ul>
          <li>Long conversations, since each message carries the history before it</li>
          <li>Bigger models and higher effort levels</li>
          <li>Extended thinking, tools, connectors, and web search when you don't need them</li>
          <li>In Claude Code: long sessions you never <code>/clear</code>, subagents, and scheduled loops</li>
        </ul>"""},
            {"id": "limit", "html": """
        <h2>What happens when you hit it</h2>
        <p>You'll see warnings as you get close. At the limit you can wait for the reset, <a href="https://support.claude.com/en/articles/12429409-manage-usage-credits-for-paid-claude-plans">turn on usage credits</a> to keep working at extra cost, or upgrade to Max (5x Pro's usage) or Ultra (10x Pro's weekly usage), which applies right away.</p>
        <p>In Claude Code, if you hit the 5-hour limit mid-response, Claude Code can finish the current step ("Usage limit reached · wrapping up"). On Pro this wrap-up allowance applies at most once per weekly period, and it counts toward your weekly limit.</p>
        <p>One trap: if <code>ANTHROPIC_API_KEY</code> is set in your shell, Claude Code bills that API key instead of your Pro plan.</p>""" + FORECAST},
            {"id": "sources", "html": sources(
                ("What is the Pro plan?", PRO),
                ("How do usage and length limits work?", USAGE),
                ("Claude Fable models on your plan", FABLE_PLAN),
                ("Use Claude Code with your Pro, Max, or Ultra plan", CODE),
                ("Claude pricing", PRICING),
                checked=CHECKED)},
        ],
        "faqs": [
            ("Does Claude Pro have a limit?", "Yes. Pro has a session limit that resets every five hours and a weekly limit. Both are shared across claude.ai, Claude Desktop, and Claude Code."),
            ("How many messages do you get on Claude Pro?", "Anthropic doesn't publish a number. It depends on how long your conversations are, which model and effort level you use, and which features are on. Pro gives more usage per session than Free."),
            ("Does Claude Code use the same limit as Claude?", "Yes. Activity in Claude and Claude Code counts against the same limits."),
            ("When does the Claude Pro limit reset?", "The session limit resets every five hours. The weekly limit resets once a week at a time set for your account; Settings › Usage on claude.ai shows the next reset."),
        ],
        "related": [
            ("Claude Max limits", "5x Pro's usage, plus a Fable allowance", "/limits/claude-max"),
            ("Claude Code limits", "How Claude Code counts against your plan", "/limits/claude-code"),
            ("When do Claude limits reset?", "Session and weekly resets, explained", "/guides/when-does-claude-limit-reset"),
        ],
    },
    {
        "path": "/limits/claude-max",
        "short": "Claude Max limits",
        "card": "5x or 20x Pro's usage per session, plus weekly limits",
        "hub_windows": "5-hour session, weekly, separate weekly Fable limit",
        "hub_reset": "Every 5 hours; weekly at a set time for your account",
        "title": "Claude Max limits (October 2026): 5x vs 20x, weekly reset",
        "description": "How Claude Max 5x and 20x usage limits work: per-session allowance vs Pro, the weekly limit and separate Fable limit, when they reset, and how to check them.",
        "eyebrow": "Claude Max",
        "h1": "Claude Max usage limits",
        "lede": "Max comes in two sizes: 5x or 20x Pro's usage per five-hour session. Both also have a weekly limit across all models, plus a separate weekly limit for Fable.",
        "answer": "Claude Max 5x ($100 a month) gives five times Pro's per-session usage, and Max 20x ($200 a month) gives twenty times. Sessions reset every five hours. A weekly limit applies across all models and resets at a fixed time assigned to your account, and Max has a separate weekly limit for Fable.",
        "sections": [
            {"id": "facts", "facts": [
                ("Price", "Max 5x: $100 a month · Max 20x: $200 a month (monthly only)"),
                ("Usage", "5x or 20x the Pro plan's per-session allowance"),
                ("Session limit", "Resets every five hours"),
                ("Weekly limit", "Across all models, resets at a fixed time assigned to your account"),
                ("Fable", "Has its own separate weekly limit on Max"),
                ("Shared with", "claude.ai, Claude Desktop, Claude Code"),
                ("Check it", f'<a href="{SETTINGS}">Settings › Usage</a> shows your next reset; <code>/usage</code> in Claude Code shows plan usage bars'),
                ("At the limit", "Wait, turn on usage credits, or move from 5x to 20x"),
            ], "html": """
        <h2>Claude Max limits at a glance</h2>
        {{FACTS}}"""},
            {"id": "how", "lit": True, "html": """
        <h2>5x or 20x: what the multiplier means</h2>
        <p>The multiplier is per session. Max 5x gives you five times what Pro allows in a five-hour session; Max 20x gives twenty times. It doesn't say how many messages that is, because Anthropic doesn't publish a count for any plan.</p>
        <p>The weekly limit is the one heavy Claude Code users run into on Max. It applies across all models and resets at a fixed time assigned to your account, not on a calendar day everyone shares. Settings › Usage on claude.ai shows when yours resets.</p>
        <p>Fable has its own weekly limit on Max, separate from the all-models one. When you hit a model-specific limit, switching to a model outside that family with <code>/model</code> keeps you working. That doesn't help with the session or weekly limits, which cover every model.</p>"""},
            {"id": "limit", "html": """
        <h2>What happens when you hit it</h2>
        <p>Wait for the reset, turn on usage credits, or move from 5x to 20x, which applies right away. The monthly API credits that come with Max can't be used in Claude Code or the Claude apps.</p>
        <p>In Claude Code, the wrap-up allowance lets the current step finish when you hit the 5-hour limit mid-response. On Max it can apply each time you reach a 5-hour limit, as long as you're inside your weekly limit. Claude Code 2.1.234 and later can also wait for the reset and continue the interrupted task on its own.</p>""" + FORECAST},
            {"id": "sources", "html": sources(
                ("What is the Max plan?", MAX),
                ("Use Claude Code with your Pro or Max plan", CODE),
                ("Manage costs effectively (Claude Code docs)", COSTS))},
        ],
        "faqs": [
            ("What's the difference between Max 5x and Max 20x?", "Max 5x gives five times Pro's usage per five-hour session for $100 a month. Max 20x gives twenty times for $200 a month. Both have weekly limits."),
            ("Does Claude Max have a weekly limit?", "Yes. A weekly limit applies across all models and resets at a fixed time assigned to your account. Max also has a separate weekly limit for Fable."),
            ("When does the Claude Max weekly limit reset?", "At a fixed time assigned to your account, once a week. Settings › Usage on claude.ai shows your next reset."),
            ("Can I use Max's API credits in Claude Code?", "No. The monthly API credits included with Max can't be used in Claude Code or the Claude apps, including for extra usage."),
        ],
        "related": [
            ("Claude Pro limits", "The plan Max multiplies", "/limits/claude-pro"),
            ("Claude Code limits", "How Claude Code counts against your plan", "/limits/claude-code"),
            ("When do Claude limits reset?", "Session and weekly resets, explained", "/guides/when-does-claude-limit-reset"),
        ],
    },
    {
        "path": "/limits/claude-code",
        "short": "Claude Code limits",
        "card": "How Claude Code counts against your Pro or Max plan",
        "hub_windows": "Your plan's 5-hour session and weekly limits",
        "hub_reset": "Same as your plan",
        "title": "Claude Code usage limits on Pro and Max (October 2026)",
        "description": "How Claude Code usage limits work on Pro and Max: shared session and weekly limits, the wrap-up allowance, /usage, and what to do at the limit.",
        "eyebrow": "Claude Code",
        "h1": "Claude Code usage limits",
        "lede": "Claude Code doesn't have limits of its own on Pro and Max. It draws from your plan's session and weekly limits, the same pool as your chats.",
        "answer": "On Pro and Max, Claude Code shares your plan's 5-hour session limit and weekly limit with claude.ai and Claude Desktop, including Claude Code inside VS Code, Cursor, and JetBrains. Run /usage to see your plan usage bars. At the limit you can wait, turn on usage credits, upgrade, or switch to API billing through the Claude Console.",
        "sections": [
            {"id": "facts", "facts": [
                ("Plans", "Pro, Max 5x, Max 20x (not Free)"),
                ("Limits", "Your plan's 5-hour session limit and weekly limit; Max also has a weekly Fable limit"),
                ("Shared with", "claude.ai, Claude Desktop, and Claude Code in VS Code, Cursor, and JetBrains"),
                ("Check it", "<code>/usage</code> shows plan usage bars and what's using them"),
                ("Mid-response at the limit", "A small wrap-up allowance lets the current step finish"),
                ("At the limit", "Wait, usage credits (<code>/usage-credits</code>), upgrade, or Console API billing"),
                ("Watch out", "<code>ANTHROPIC_API_KEY</code> in your shell switches Claude Code to API billing"),
            ], "html": """
        <h2>Claude Code limits at a glance</h2>
        {{FACTS}}"""},
            {"id": "usage", "lit": True, "html": """
        <h2>Seeing what's left from inside Claude Code</h2>
        <p><strong><code>/usage</code></strong> shows your plan usage bars, plus a breakdown of what's eating them: skills, subagents, plugins, MCP servers, and scheduled loops, for the last 24 hours (<code>d</code>) or 7 days (<code>w</code>). The breakdown only covers sessions on this Mac, not claude.ai.</p>
        <p><strong>The status line</strong> gets your session and weekly percent and reset times after every reply, so a script can show them under the prompt all the time. <a href="/guides/claude-code-statusline">Our status line guide</a> shows how.</p>
        <h3>Why a long session burns through it</h3>
        <p>Claude Code sends the whole conversation with every request, and again with every batch of tool results. A one-line question in a session that's been open all day still pays for the whole history. <code>/clear</code> between unrelated tasks is the biggest saver. Subagents, agent teams, scheduled loops, and <code>/compact</code> on a huge context all add up too.</p>"""},
            {"id": "limit", "html": """
        <h2>What happens when you hit it</h2>
        <p>"You've hit your session limit" and "You've hit your weekly limit" cover every model, so <code>/model</code> won't get you around them. The message tells you when the window resets. A model-specific message, like "You've hit your Opus limit", is different: switching to a model outside that family keeps you going.</p>
        <p>Your options: wait (Claude Code 2.1.234 and later can wait for the reset and continue the interrupted task on its own), turn on usage credits with <code>/usage-credits</code>, upgrade (Pro to Max 5x, or Max 5x to 20x), or use API credits through a Claude Console account, billed at API rates.</p>""" + FORECAST},
            {"id": "sources", "html": sources(
                ("Use Claude Code with your Pro or Max plan", CODE),
                ("Manage costs effectively (Claude Code docs)", COSTS),
                ("How do usage and length limits work?", USAGE))},
        ],
        "faqs": [
            ("Does Claude Code have its own usage limit?", "Not on Pro and Max. It shares your plan's session and weekly limits with claude.ai and Claude Desktop."),
            ("How do I check my Claude Code usage?", "Run /usage in Claude Code for your plan usage bars and a breakdown of what used them, or see Settings › Usage on claude.ai."),
            ("Is Claude Code included in the Free plan?", "No. Claude Code comes with Pro and Max."),
            ("Why did Claude Code bill my API key?", "If ANTHROPIC_API_KEY is set in your environment, Claude Code uses it instead of your subscription. Unset it and log in with your Pro or Max account."),
        ],
        "related": [
            ("Check your Claude usage", "Every place to see what's left", "/guides/check-claude-usage"),
            ("Claude Code status line", "Your limits under the prompt", "/guides/claude-code-statusline"),
            ("Claude Code pricing", "Every plan that includes it, and the API", "/compare/claude-code-pricing"),
        ],
    },
    {
        "path": "/limits/claude-free",
        "short": "Claude Free limits",
        "card": "A 5-hour session limit that moves with demand",
        "hub_windows": "5-hour session",
        "hub_reset": "Every 5 hours",
        "title": "Claude Free plan usage limits (October 2026)",
        "description": "How the Claude Free plan's usage limit works: a session limit that resets every five hours, why the message count changes with demand, and what Pro adds.",
        "eyebrow": "Claude Free",
        "h1": "Claude Free plan limits",
        "lede": "Free has a session limit that resets every five hours. How much fits in a session changes with demand.",
        "answer": "The Claude Free plan has a session-based usage limit that resets every five hours. The number of messages you can send varies with demand, and Anthropic may add other limits to keep access fair. Claude Code isn't included; Pro gives at least 5x Free's usage per session.",
        "sections": [
            {"id": "facts", "facts": [
                ("Price", "$0"),
                ("Session limit", "Resets every five hours"),
                ("How much", "Varies with demand; Anthropic doesn't publish a number"),
                ("Other limits", "Anthropic may add other kinds of limits to keep access fair"),
                ("Claude Code", "Not included"),
                ("Next step up", "Pro: at least 5x Free's usage per 5-hour session, plus Claude Code"),
            ], "html": """
        <h2>Claude Free limits at a glance</h2>
        {{FACTS}}"""},
            {"id": "how", "lit": True, "html": """
        <h2>Why the limit moves</h2>
        <p>On Free, how many messages fit in a five-hour session depends on demand: when lots of people are using Claude, the free allowance shrinks. Long conversations and file uploads use it up faster, since each message carries the conversation before it.</p>
        <p>Claude tells you when you've reached the limit. Starting a new chat for a new topic, and keeping prompts and files short, stretches it.</p>
        <h2>When Free stops being enough</h2>
        <p>If you hit the limit most days, or want Claude Code, Pro is the next step: at least 5x Free's usage per session, a weekly limit on top, and Claude Code included. See <a href="/limits/claude-pro">Claude Pro limits</a>.</p>
        <p>Fuel Gauge forecasts the paid plans' limits through Claude Code, so it's for Pro and Max.</p>"""},
            {"id": "sources", "html": sources(
                ("About free Claude usage", FREE),
                ("Claude pricing", PRICING))},
        ],
        "faqs": [
            ("How many messages does Claude Free give you?", "Anthropic doesn't publish a number. It varies with demand and with how long your conversations are."),
            ("When does the Claude Free limit reset?", "The session limit resets every five hours."),
            ("Does Claude Free include Claude Code?", "No. Claude Code comes with Pro and Max."),
        ],
        "related": [
            ("Claude Pro limits", "At least 5x Free's usage per session", "/limits/claude-pro"),
            ("When do Claude limits reset?", "Session and weekly resets, explained", "/guides/when-does-claude-limit-reset"),
            ("Check your Claude usage", "Every place to see what's left", "/guides/check-claude-usage"),
        ],
    },
    {
        "path": "/limits/codex",
        "short": "Codex limits",
        "card": "5-hour and weekly windows on ChatGPT plans, shared with cloud",
        "hub_windows": "5-hour and weekly (Pro: weekly only)",
        "hub_reset": "Shown on your Codex usage dashboard",
        "title": "Codex usage limits (October 2026): Plus, Pro, Business",
        "description": "How Codex usage limits work on ChatGPT plans: 5-hour and weekly windows, what Plus and Business get per 5 hours, Pro's weekly-only limit, and how to check.",
        "eyebrow": "OpenAI Codex",
        "h1": "Codex usage limits",
        "lede": "Codex is included in every ChatGPT plan. Paid plans get a 5-hour window and a weekly limit; Pro plans drop the 5-hour limit.",
        "answer": "Codex comes with every ChatGPT plan, including Free and Go. On Plus and Business, usage is measured in 5-hour windows, and weekly limits may also apply; Pro plans have no 5-hour limit. Local messages and cloud chats share one allowance. Check yours at chatgpt.com/codex/settings/usage, or run /status in the Codex CLI.",
        "sections": [
            {"id": "facts", "facts": [
                ("Plans", "Free, Go ($8), Plus ($20), Pro ($100, $200, or $500), Business ($20/user billed yearly, $25 monthly), Enterprise/Edu"),
                ("5-hour window", "Plus and Business; Pro plans have no five-hour limit"),
                ("Weekly limit", "\"Weekly limits may also apply\""),
                ("Shared", "Local messages and cloud chats use the same allowance"),
                ("Codex Cloud", "Plus, Pro, Business, Enterprise, Healthcare, Education; not Free or Go"),
                ("Check it", f'<a href="{CODEX_USAGE}">chatgpt.com/codex/settings/usage</a>, or <code>/status</code> in the Codex CLI'),
                ("At the limit", "Add credits, apply a banked reset, upgrade, wait, or switch to an API key"),
            ], "html": """
        <h2>Codex limits at a glance</h2>
        {{FACTS}}"""},
            {"id": "numbers", "lit": True, "html": """
        <h2>How much fits in 5 hours</h2>
        <p>OpenAI publishes ranges, not fixed limits, for local messages per 5 hours on Plus and Standard Business. The range is wide because a short question and a long agentic task cost very different amounts:</p>
        <div class="table-card glass"><div class="table-scroll"><table class="compare facts"><tbody>
            <tr><th scope="row">GPT-6 Astra</th><td>5–45 local messages per 5 hours</td></tr>
            <tr><th scope="row">GPT-6.1 Sol</th><td>15–160</td></tr>
            <tr><th scope="row">GPT-6 Sol</th><td>15–150</td></tr>
            <tr><th scope="row">GPT-6 Luna</th><td>350–3,000</td></tr>
        </tbody></table></div></div>
        <p>OpenAI's words: "These estimates are not fixed message limits." Free and Go numbers aren't published. Enterprise and Edu workspaces with flexible pricing have no fixed rate limits.</p>"""},
            {"id": "limit", "html": """
        <h2>What happens when you hit it</h2>
        <p>If you reach a limit in the middle of a turn, Codex can finish that turn. After that you can add credits (eligible Plus and Pro users can buy them without changing plans), apply a banked reset if you have one, which refreshes your 5-hour and weekly windows and moves your weekly reset date, upgrade, or wait. You can also keep working locally with an OpenAI API key, billed at API rates. OpenAI Support doesn't reset limits.</p>
        <h2>Will you make it to the reset?</h2>
        <p>Codex writes its limits to its session logs on your Mac after every turn: each window's percent used, its length, and its reset time. <a href="/">Fuel Gauge</a> reads them, with no sign-in, and tells you whether you'll make it to the reset at your current pace. It reads the last 8 days of logs on first launch, so weekly forecasts start right away.</p>"""},
            {"id": "sources", "html": sources(
                ("Codex pricing", CODEX_PRICING),
                ("Using Codex with your ChatGPT plan", CODEX_HELP))},
        ],
        "faqs": [
            ("Does Codex have a weekly limit?", "OpenAI says weekly limits may apply alongside the 5-hour window. Pro plans have no 5-hour limit. Your usage dashboard shows your current limits and reset times."),
            ("How do I check my Codex usage?", "Open chatgpt.com/codex/settings/usage, or run /status in an active Codex CLI session."),
            ("Do Codex cloud tasks have a separate limit?", "No. Local messages and cloud chats share your plan's usage allowance."),
            ("Is Codex included in ChatGPT Free?", "Yes, Codex is included across ChatGPT plans, including Free and Go. Codex Cloud isn't included with Free or Go."),
        ],
        "related": [
            ("Claude Code vs Codex", "Limits side by side", "/compare/claude-code-vs-codex"),
            ("Claude Code limits", "How Claude Code counts against your plan", "/limits/claude-code"),
            ("Codex pricing", "ChatGPT plans, credits, and the API", "/compare/codex-pricing"),
        ],
    },
    {
        "path": "/limits/cursor",
        "short": "Cursor limits",
        "card": "One weekly pool on the new plans, monthly on legacy ones",
        "hub_windows": "Weekly pool (legacy plans: monthly)",
        "hub_reset": "Weekly; legacy plans with your billing cycle",
        "title": "Cursor usage limits (October 2026): weekly pool, legacy plans",
        "description": "How Cursor usage limits work now: one weekly pool shared with Grok on the new plans, monthly pools on legacy Pro and Ultra, what happens over the limit, and how to check.",
        "eyebrow": "Cursor",
        "h1": "Cursor usage limits",
        "lede": "Cursor's plans changed. New plans have one usage pool that refreshes weekly, shared with Grok Bot and the Grok apps. Legacy plans keep monthly pools.",
        "answer": "On Cursor's current plans (Free, Plus $8, Premium $30, Super $100, Ultra $200), each paid plan has one pool of usage for Cursor models that refreshes weekly, shared across the editor, CLI, Cloud Agents, Grok Bot, and the Grok apps. Legacy plans (Hobby, Pro, Pro+, Ultra, Teams) have two monthly pools that reset with your billing cycle. Check usage at grok.com/dashboard or in your editor settings.",
        "sections": [
            {"id": "facts", "facts": [
                ("Current plans", "Free · Plus $8 · Premium $30 (4x Plus) · Super $100 (15x Plus) · Ultra $200 (50x Plus) a month"),
                ("Pool", "One pool for Cursor models, shared with Grok Bot and the Grok apps"),
                ("Reset", "Weekly; unused usage doesn't roll over"),
                ("Third-party models", "Claude, GPT, Gemini on Premium and up, at API list price from prepaid credit"),
                ("Over the limit", "Wait for the reset, use prepaid credit, or upgrade; requests are never downgraded"),
                ("Check it", "Usage at grok.com/dashboard (used, next reset, credit), or your editor settings"),
                ("Legacy plans", "Two monthly pools, reset with your billing cycle"),
            ], "html": """
        <h2>Cursor limits at a glance</h2>
        {{FACTS}}"""},
            {"id": "legacy", "lit": True, "html": """
        <h2>If you're on a legacy plan</h2>
        <p>Hobby, Pro ($20), Pro+ ($60), Ultra ($200), and the old Teams plans ($40 and $120 per user) are now legacy. They have two monthly pools, Cursor models and other models, that reset with your billing cycle. On Pro, Pro+, and Ultra, on-demand usage is off until you turn it on under Spending at cursor.com/dashboard/spending, where you can set a monthly spend limit; on Teams it's on by default. On Hobby, AI features pause until the pool resets.</p>
        <h2>What "Auto" means for your limit</h2>
        <p>On individual plans, Auto runs in Cost mode: it bills as a Cursor-model request and draws from your weekly pool, whichever model serves it.</p>
        <h2>Will you make it to the reset?</h2>
        <p><a href="/">Fuel Gauge</a> forecasts whether your usage lasts until the reset. On Grok Bot it reads the weekly usage Grok Bot saves on your Mac; for Cursor it can ask cursor.com with the Cursor app's own sign-in, which is off until you turn it on.</p>"""},
            {"id": "sources", "html": sources(
                ("Models and pricing (Cursor docs)", CURSOR_PRICING),
                ("Usage limits (Cursor help)", CURSOR_USAGE),
                ("Legacy Cursor plans", CURSOR_LEGACY))},
        ],
        "faqs": [
            ("Does Cursor have a weekly limit?", "On the current plans, yes: one pool of usage for Cursor models that refreshes weekly. Legacy plans reset monthly with your billing cycle."),
            ("What happens when I run out of Cursor usage?", "Wait for the weekly reset, use prepaid credit, or upgrade. Cursor says requests are never downgraded in quality or speed."),
            ("Where do I see my Cursor usage?", "Usage at grok.com/dashboard shows how much of your weekly pool you've used, the next reset, and your prepaid credit. Your editor settings show the same."),
            ("Does Cursor usage roll over?", "No. Unused included usage doesn't roll over on either kind of plan. Prepaid credit lasts 365 days."),
        ],
        "related": [
            ("Grok limits", "The same weekly pool, from the Grok side", "/limits/grok"),
            ("Cursor vs Claude Code", "Limits and pricing side by side", "/compare/cursor-vs-claude-code"),
            ("Codex limits", "5-hour and weekly windows", "/limits/codex"),
        ],
    },
    {
        "path": "/limits/grok",
        "short": "Grok limits",
        "card": "One shared weekly pool, including Grok Bot",
        "hub_windows": "One weekly pool",
        "hub_reset": "Weekly, on the schedule in Settings › Usage",
        "title": "Grok usage limits (October 2026): the weekly pool, Grok Bot",
        "description": "How Grok usage limits work: one shared weekly usage pool instead of daily limits, how it resets, what pauses when it runs out, and where Grok Bot fits.",
        "eyebrow": "Grok",
        "h1": "Grok usage limits",
        "lede": "Grok replaced separate daily limits with one shared weekly pool, shown as a percentage and reset on a schedule in your settings.",
        "answer": "Starting in June 2026, Grok moved to one shared weekly usage pool instead of separate daily limits per product. It resets every week on the schedule shown in Settings › Usage, where you see it as a percentage used, broken down by API, Build, Chat, Imagine, and Voice. When it runs out, paid features pause until the reset unless you add Extra Usage Credits.",
        "sections": [
            {"id": "facts", "facts": [
                ("Pool", "One weekly pool shared across Grok products"),
                ("Reset", "Every week, on the schedule in Settings › Usage"),
                ("Shown as", "Percent used, broken down by API, Build, Chat, Imagine, and Voice"),
                ("When it runs out", "Paid features pause until the weekly reset"),
                ("Extra usage", "Extra Usage Credits from $5, valid one year, with optional Auto Top Up"),
                ("Free tier", "Chat and Voice limits reset on their own schedule"),
                ("Published numbers", "None"),
            ], "html": """
        <h2>Grok limits at a glance</h2>
        {{FACTS}}"""},
            {"id": "bot", "lit": True, "html": """
        <h2>Grok Bot</h2>
        <p>Grok Bot is the desktop and iOS agent from Cursor. On the X Subscription, it's included on Premium, Super, and Ultra and draws from the same weekly pool as Cursor and the Grok apps, not a separate Grok Bot meter. On legacy Cursor plans it has its own weekly usage. Grok Bot on macOS and iOS share one usage bucket, and its Usage &amp; Billing settings show weekly included usage and on-demand usage.</p>
        <h2>Will you make it to the reset?</h2>
        <p>Grok Bot saves your weekly usage on your Mac while it's open. <a href="/">Fuel Gauge</a> reads it, with no sign-in or network call, and tells you whether you'll make it to the weekly reset at your current pace.</p>"""},
            {"id": "sources", "html": sources(
                ("Grok FAQ", GROK_FAQ),
                ("Grok Bot plans (Cursor help)", GROK_BOT_PLANS),
                ("Models and pricing (Cursor docs)", CURSOR_PRICING))},
        ],
        "faqs": [
            ("Does Grok have daily limits?", "Not anymore for paid features. Grok moved to one shared weekly usage pool. Free-tier Chat and Voice limits reset on their own schedule."),
            ("When does the Grok usage limit reset?", "Every week, on the schedule shown in the Usage tab in Settings."),
            ("Does Grok Bot have its own limit?", "On the X Subscription, no: it draws from the same weekly pool as Cursor and the Grok apps. Legacy Cursor plans give it its own weekly usage."),
        ],
        "related": [
            ("Cursor limits", "The same weekly pool, from the Cursor side", "/limits/cursor"),
            ("Codex limits", "5-hour and weekly windows", "/limits/codex"),
            ("Check your Claude usage", "Every place to see what's left", "/guides/check-claude-usage"),
        ],
    },
    {
        "path": "/limits/github-copilot",
        "short": "GitHub Copilot limits",
        "card": "Monthly AI credits since June 2026; premium requests on legacy plans",
        "hub_windows": "Monthly AI credits",
        "hub_reset": "1st of the month, 00:00 UTC",
        "title": "GitHub Copilot limits (October 2026): AI credits, resets",
        "description": "How GitHub Copilot limits work since June 2026: monthly AI credits per plan, the reset on the 1st at 00:00 UTC, what happens when they run out, and legacy premium requests.",
        "eyebrow": "GitHub Copilot",
        "h1": "GitHub Copilot limits",
        "lede": "Copilot replaced premium requests with AI credits on June 1, 2026. Each plan gets a monthly allowance that resets on the 1st, at midnight UTC.",
        "answer": "GitHub Copilot now meters usage in AI credits ($0.01 each), priced per model by tokens. Pro includes 1,500 a month, Pro+ 7,000, Max 20,000, Business 1,900 per user, and Enterprise 3,900 per user, pooled. Allowances reset at 00:00 UTC on the 1st of each month, whatever your billing date, and unused credits don't carry over. Code completions don't use credits.",
        "sections": [
            {"id": "facts", "facts": [
                ("Free", "$0 · 2,000 completions and 50 chat requests a month"),
                ("Pro", "$10 · 1,500 AI credits a month"),
                ("Pro+", "$39 · 7,000 AI credits a month"),
                ("Max", "$100 · 20,000 AI credits a month"),
                ("Business / Enterprise", "$19 / $39 per user · 1,900 / 3,900 credits per user, pooled"),
                ("Reset", "00:00:00 UTC on the 1st of each month; unused credits don't carry over"),
                ("Not counted", "Code completions and next edit suggestions"),
                ("Check it", "Your Copilot usage dashboard on GitHub"),
            ], "html": """
        <h2>Copilot limits at a glance</h2>
        {{FACTS}}
        <p class="table-foot">Each paid allowance is part base, part flex credits; GitHub says flex credits may change over time. 1 AI credit = $0.01.</p>"""},
            {"id": "limit", "lit": True, "html": """
        <h2>What happens when you run out</h2>
        <p>On an individual plan you can upgrade, set a budget for additional usage, or wait for the reset on the 1st. For organizations and enterprises, additional usage is on by default; if it isn't allowed, usage is blocked until the next billing cycle. Subscriptions bought through GitHub Mobile can't buy more credits.</p>
        <h2>Legacy annual plans and premium requests</h2>
        <p>Annual Pro and Pro+ plans bought before the change keep premium requests until they expire, then move to Copilot Free: 300 a month on Pro and 1,500 on Pro+, reset on the 1st at 00:00 UTC, with extra requests at $0.04 each.</p>
        <h2>Does Fuel Gauge track Copilot?</h2>
        <p>Not yet. <a href="/">Fuel Gauge</a> forecasts Claude Code, Codex, Grok Bot, and Cursor limits. Copilot's monthly allowance is a good fit for a forecast, so it's on the list.</p>"""},
            {"id": "sources", "html": sources(
                ("GitHub Copilot is moving to usage-based billing", COPILOT_BLOG),
                ("Billing for individuals (GitHub docs)", COPILOT_BILLING),
                ("Usage-based billing for organizations and enterprises", COPILOT_ORGS),
                ("Copilot plans", COPILOT_PLANS),
                ("Copilot requests (legacy plans)", COPILOT_LEGACY))},
        ],
        "faqs": [
            ("Does GitHub Copilot still use premium requests?", "Only on legacy annual Pro and Pro+ plans. Since June 1, 2026, Copilot meters usage in AI credits."),
            ("When do Copilot credits reset?", "At 00:00:00 UTC on the 1st of each month, regardless of your billing date. Unused credits don't carry over."),
            ("Do code completions use AI credits?", "No. Code completions and next edit suggestions don't use credits."),
        ],
        "related": [
            ("Codex limits", "5-hour and weekly windows", "/limits/codex"),
            ("Cursor limits", "One weekly pool on the new plans", "/limits/cursor"),
            ("Claude Code limits", "How Claude Code counts against your plan", "/limits/claude-code"),
        ],
    },
]
