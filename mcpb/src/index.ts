import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";
import { runFuelGauge } from "./cli.js";
import { shapeHistory, shapeStatus } from "./shape.js";

const VERSION = "0.1.0";

const server = new McpServer(
  { name: "fuelgauge", version: VERSION },
  {
    instructions:
      "Fuel Gauge forecasts whether this Mac's Claude Code, Codex, and Grok Bot usage limits last until they " +
      "reset. Percentages are percent of the limit used; timestamps are UTC, and summaries use the Mac's local time. Answers are short on purpose, since " +
      "reading them uses the same limits. These tools only read. For disk space, use Disk Forecast; for CPU " +
      "and memory, use Spare.",
  },
);

const readOnly = {
  readOnlyHint: true,
  destructiveHint: false,
  idempotentHint: true,
  openWorldHint: false,
} as const;

function reply(result: { ok: boolean; text: string }) {
  return {
    content: [{ type: "text" as const, text: result.text }],
    ...(result.ok ? {} : { isError: true }),
  };
}

server.registerTool(
  "limits_status",
  {
    title: "Usage limit forecast",
    description:
      "How much Claude Code, Codex, and Grok Bot usage is left, when each limit resets, and whether it lasts " +
      "until then. Each limit has used_percent, resets_at, a verdict (makes_it, runs_out, out, learning, reset), " +
      "a one-line summary, and runs_out_at when it won't last. problem is true when a limit runs out before it " +
      "resets, or already has. Use for 'how much Claude Code do I have left?', 'will I hit my limit today?', " +
      "or 'when does my Codex limit reset?', and before a long task: if problem is true, tell the person which " +
      "limit runs out and when, and ask before starting. Covers AI usage limits only; for disk space, use " +
      "Disk Forecast, and for CPU and memory, use Spare.",
    inputSchema: {},
    annotations: { ...readOnly, title: "Usage limit forecast" },
  },
  async () => {
    const result = await runFuelGauge(["status"]);
    return reply(result.ok ? shapeStatus(result.stdout, result.code) : result);
  },
);

server.registerTool(
  "limits_history",
  {
    title: "Usage limit history",
    description:
      "The readings behind the forecast: for each limit (tool and limit name), points of [time, percent used] " +
      "over the last N days, keeping only the readings where the percent changed. readings is how many were " +
      "saved. Use for 'how fast am I using Claude Code?' or 'when did I burn through my Codex limit?'. " +
      "For what's left right now, use limits_status instead.",
    inputSchema: {
      days: z
        .number()
        .int()
        .min(1)
        .max(30)
        .default(1)
        .describe("How many days back, 1-30. Default 1."),
    },
    annotations: { ...readOnly, title: "Usage limit history" },
  },
  async ({ days }) => {
    const result = await runFuelGauge(["history", "--days", String(days)]);
    return reply(result.ok ? shapeHistory(result.stdout, days) : result);
  },
);

await server.connect(new StdioServerTransport());
