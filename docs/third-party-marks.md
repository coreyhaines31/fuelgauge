# Third-party marks

Fuel Gauge shows each tool's mark next to its name so the sections are easy to tell apart.

Logos are trademarks of their owners and are used only to identify the tools Fuel Gauge reads. Fuel Gauge is not affiliated with or endorsed by any of them.

This is nominative use: each mark identifies the tool whose limits a section shows, and nothing more. We use it even where a vendor's guidelines ask for permission first, and accept that risk. The rules: the vendor's exact mark geometry from its own brand page or official assets (no redrawing, no distortion), one colour as a template image, the tool's name always shown as text, and nothing that implies endorsement.

Each file in `FuelGauge/Assets.xcassets/ToolMarks/` and the matching inline SVG on fuelgauge.app is the vendor's own asset, unedited: same paths, same proportions, no added elements. The app draws them as one-colour template images in the panel's ink (near-black in light mode, near-white in dark), the vendors' own one-colour treatment, at about 12 pt beside the tool's name and never larger than it. The name stays visible; the mark's accessibility label is the tool name.

Downloaded 2026-11-17.

| Tool | Mark | Official source | File used |
|---|---|---|---|
| Claude Code | Claude Spark | Anthropic press kit, linked as "Download press kit" under Media assets on https://www.anthropic.com/news (https://www.anthropic.com/press-kit) | `Anthropic logos/Claude logos/3 Claude Spark/SVG/Claude Spark - Clay.svg` |
| Codex | OpenAI Blossom | https://openai.com/brand/, "Download logos" (https://cdn.openai.com/brand/OpenAI-Logos-2025.zip) | `OpenAI-logos(new)/SVGs/OpenAI-black-monoblossom.svg` |
| Grok Bot | Grok logomark | https://x.ai/legal/brand-guidelines, "Download Logos" | `Grok_Logomark_Dark.svg` |
| Cursor | Cube (2D) | https://cursor.com/brand, "Download brand assets" | `General Logos/Cube/SVG/CUBE_2D_LIGHT.svg` |

## Terms each vendor sets

Who asks for permission:

| Vendor | Asks for permission? |
|---|---|
| OpenAI | Yes. Its guidelines say not to use the logo without permission, and to send requests to partnercomms@openai.com. |
| Anthropic | Publishes no usage terms. The press kit is meant for media. |
| SpaceXSI (Grok) | No. Use is allowed if you follow its usage terms, with the logo used exactly as provided. |
| Cursor | No. It states no terms beyond the name "Cursor". |

**Anthropic.** The press kit has the Claude Spark, plus one-colour versions of the Claude and Claude Code logos. It comes without written usage rules. We use the Spark unaltered and only to identify Claude Code. Questions: press@anthropic.com.

**OpenAI** (brand page, "Usage terms" and "Dos and Don'ts: Blossom"):
- Use the logo only when it directly relates to OpenAI services, exactly as provided, and acknowledge that it belongs to OpenAI.
- Don't add colours to the Blossom, use it as primary branding, add elements, or put it over a busy image. Keep its prescribed spacing; the downloaded file's canvas holds that clear space, and we keep it.
- Don't show the marks more prominently than your own name, imply endorsement, or put them on merchandise.
- Permission is non-exclusive and non-transferable, and OpenAI can review it, require changes, or end it.
- Contact: partnercomms@openai.com (permissions), legal@openai.com.

**SpaceXSI (Grok)** (brand guidelines, "Usage Terms" and "Logos"):
- Use the marks only to refer accurately to SpaceXSI or its services. Don't imply endorsement, use them in an app or product name, put anything near them that makes a new mark, or make them part of your own marks.
- Use the logos only exactly as provided at the download link, without alteration.
- SpaceXSI can end the permission at any time. Contact: legal@x.ai.
- The live zip (https://data.x.ai/logos/SpaceXAI_Grok_Assets.zip) blocks scripted downloads. The file here is `Grok_Logomark_Dark.svg` from the earlier official zip (https://data.x.ai/logos/xAI_Grok_Assets.zip, archived copy from 2025-09-10). Before a release, re-download the current zip in a browser and replace the file if the mark has changed.

**Cursor** (brand page): it offers the cube on its own, in 2D (the default) and 2.5D, light and dark, and asks that the product be called "Cursor". We use the 2D cube for light backgrounds.

## If a vendor asks

Delete that vendor's imageset and its `case` in `ToolMark.asset(for:)`. The header then shows just the name, as before. Remove the matching inline SVG from `site/index.html` too.
