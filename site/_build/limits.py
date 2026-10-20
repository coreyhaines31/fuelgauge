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


def sources(*links):
    items = "".join(f'<li><a href="{url}">{name}</a></li>' for name, url in links)
    return f"""
        <h2>Sources</h2>
        <p>Checked on {VERIFIED}. Anthropic changes plans from time to time, so the help pages are the final word.</p>
        <ul>{items}</ul>"""


FORECAST = """
        <h2>Will you make it to the reset?</h2>
        <p>A percentage tells you how much you've used. It doesn't tell you whether, at the pace you're going, you'll run out before the window resets. <a href="/">Fuel Gauge</a> does that math: a free Mac menu bar app that reads your Claude Code limits after every reply and says "Makes it to reset" or "Runs out around 3:40p, 1h 20m early". It can put the same line under your Claude Code prompt.</p>"""

LIMITS = [
    {
        "path": "/limits/claude-pro",
        "short": "Claude Pro limits",
        "card": "5-hour session and weekly limits, shared with Claude Code",
        "hub_windows": "5-hour session, weekly",
        "hub_reset": "Every 5 hours; weekly at a set time for your account",
        "title": "Claude Pro usage limits (October 2026): session and weekly",
        "description": "How Claude Pro's limits work: a 5-hour session limit and a weekly limit, shared across Claude and Claude Code. When they reset and how to check.",
        "eyebrow": "Claude Pro",
        "h1": "Claude Pro usage limits",
        "lede": "Pro has two limits: a session limit that resets every five hours, and a weekly limit. Claude, Claude Desktop, and Claude Code all draw from both.",
        "answer": "Claude Pro ($20 a month, or $17 a month billed yearly) gives you at least 5x the per-session usage of the Free plan. Usage is capped by a 5-hour session limit and a weekly limit, shared across claude.ai, Claude Desktop, and Claude Code. Anthropic doesn't publish a message count; how far it goes depends on conversation length, model, features, and effort.",
        "sections": [
            {"id": "facts", "facts": [
                ("Price", "$20 a month, or $17 a month billed yearly ($200 up front)"),
                ("Usage", "At least 5x the Free plan's usage per 5-hour session"),
                ("Session limit", "Resets every five hours"),
                ("Weekly limit", "Yes, resets once a week"),
                ("Shared with", "claude.ai, Claude Desktop, Claude Code, and Claude Code in VS Code, Cursor, and JetBrains"),
                ("Claude Code", "Included"),
                ("Check it", f'<a href="{SETTINGS}">Settings › Usage</a> on claude.ai, or <code>/usage</code> in Claude Code'),
                ("At the limit", "Wait for the reset, turn on usage credits, or upgrade to Max"),
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
        <p>You'll see warnings as you get close. At the limit you can wait for the reset, <a href="https://support.claude.com/en/articles/12429409-extra-usage-for-paid-claude-plans">turn on usage credits</a> to keep working at extra cost, or upgrade to Max 5x, which applies right away.</p>
        <p>In Claude Code, if you hit the 5-hour limit mid-response, Claude Code can finish the current step ("Usage limit reached · wrapping up"). On Pro this wrap-up allowance applies at most once per weekly period, and it counts toward your weekly limit.</p>
        <p>One trap: if <code>ANTHROPIC_API_KEY</code> is set in your shell, Claude Code bills that API key instead of your Pro plan.</p>""" + FORECAST},
            {"id": "sources", "html": sources(
                ("How do usage and length limits work?", USAGE),
                ("Use Claude Code with your Pro or Max plan", CODE),
                ("Claude pricing", PRICING))},
        ],
        "faqs": [
            ("Does Claude Pro have a limit?", "Yes. Pro has a session limit that resets every five hours and a weekly limit. Both are shared across claude.ai, Claude Desktop, and Claude Code."),
            ("How many messages do you get on Claude Pro?", "Anthropic doesn't publish a number. It depends on how long your conversations are, which model and effort level you use, and which features are on. Pro gives at least 5x the per-session usage of Free."),
            ("Does Claude Code use the same limit as Claude?", "Yes. Activity in Claude and Claude Code counts against the same limits."),
            ("When does the Claude Pro limit reset?", "The session limit resets every five hours. The weekly limit resets once a week at a time set for your account; Settings › Usage on claude.ai shows the next reset."),
        ],
        "related": [
            ("Claude Max limits", "5x or 20x Pro's usage per session", "/limits/claude-max"),
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
            ("Claude Max limits", "5x or 20x Pro's usage", "/limits/claude-max"),
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
]
