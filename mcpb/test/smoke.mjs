// Starts the built server over stdio, calls every tool against this Mac, and fails
// if a call that should work errors or a call that should fail doesn't.
// Then checks, against a fake CLI, the exact argv each tool sends and how each CLI outcome comes back.
// Run: npm test. SERVER=<path> runs an unpacked .mcpb instead of server/index.mjs.
import { mkdtempSync, readFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";

const ok = true;
const fails = false;
// [tool, arguments, should work, top-level key the answer must have]
const calls = [
  ["limits_status", {}, ok, "limits"],
  ["limits_history", {}, ok, "limits"],
  ["limits_history", { days: 7 }, ok, "limits"],
  ["limits_history", { days: 0 }, fails],
  ["limits_history", { days: 31 }, fails],
  ["limits_history", { days: 2.5 }, fails],
  ["limits_history", { days: "1; rm -rf ~" }, fails],
  ["install_statusline", {}, fails],
];

const NO_READINGS =
  "No readings yet. Open Fuel Gauge and use Claude Code, Codex, or Grok Bot for a few minutes. " +
  "Claude Code's limits only arrive through its status line: turn it on in Fuel Gauge's Settings > Tools.";
// [fake mode, tool, arguments, should work, argv the CLI must get, exact answer]
const fakeCalls = [
  [
    "ok", "limits_status", {}, ok, "status --json",
    {
      problem: false,
      limits: [{
        tool: "claude", window: "5-hour", verdict: "makes_it", summary: "Makes it to reset", used_percent: 10,
        resets_at: "2026-10-29T19:00Z", rate_per_hour: 7, last_reading_at: "2026-10-29T17:25Z",
      }],
    },
  ],
  [
    "short", "limits_status", {}, ok, "status --json",
    {
      problem: true,
      limits: [{
        tool: "codex", window: "weekly", verdict: "runs_out", summary: "Runs out around 3:40p", used_percent: 80,
        resets_at: "2026-10-30T00:00Z", runs_out_at: "2026-10-29T22:40Z", last_reading_at: "2026-10-29T17:25Z",
      }],
    },
  ],
  ["empty", "limits_status", {}, ok, "status --json", { problem: false, limits: [], note: NO_READINGS }],
  [
    "ok", "limits_history", {}, ok, "history --days 1 --json",
    {
      days: 1,
      limits: [{
        tool: "claude", limit: "five_hour", resets_at: "2026-10-29T14:00Z", readings: 4,
        points: [["2026-10-29T10:00Z", 5], ["2026-10-29T10:10Z", 7], ["2026-10-29T10:15Z", 7]],
      }],
    },
  ],
  ["empty", "limits_history", { days: 30 }, ok, "history --days 30 --json", { days: 30, limits: [], note: NO_READINGS }],
  ["garbage", "limits_status", {}, fails, "status --json", "Couldn't read Fuel Gauge's forecast."],
  ["garbage", "limits_history", {}, fails, "history --days 1 --json", "Couldn't read Fuel Gauge's history."],
  ["stderr", "limits_status", {}, fails, "status --json", "fake stderr error"],
  ["stderr", "limits_history", { days: 3 }, fails, "history --days 3 --json", "fake stderr error"],
];
const expectedTools = ["limits_history", "limits_status"];
const server = process.env.SERVER ?? new URL("../server/index.mjs", import.meta.url).pathname;
const fakeCli = new URL("./fake-cli.sh", import.meta.url).pathname;
const max = Number(process.env.SMOKE_CHARS ?? 600);
const failures = [];

async function connect(env) {
  const transport = new StdioClientTransport({ command: process.execPath, args: [server], env: { ...process.env, ...env } });
  const client = new Client({ name: "fuelgauge-smoke", version: "0.0.0" });
  await client.connect(transport);
  return client;
}

async function call(client, name, args) {
  let result;
  try {
    result = await client.callTool({ name, arguments: args });
  } catch (error) {
    result = { isError: true, content: [{ type: "text", text: `protocol error: ${error.message}` }] };
  }
  return { isError: Boolean(result.isError), text: result.content.map((c) => c.text).join("\n") };
}

function show(label, { isError, text }) {
  const shown = text.length > max ? `${text.slice(0, max)}\n… (${text.length} chars)` : text;
  console.log(`\n### ${label}${isError ? " [isError]" : ""}\n${shown}`);
}

const client = await connect({ FUELGAUGE_CLI: process.env.FUELGAUGE_CLI ?? "" });
const { tools } = await client.listTools();
console.log(`tools: ${tools.map((t) => t.name).join(", ")}`);
if (tools.map((t) => t.name).sort().join() !== expectedTools.join()) {
  throw new Error(`expected exactly these tools: ${expectedTools.join(", ")}`);
}
for (const tool of tools) {
  if (!tool.annotations?.readOnlyHint || tool.annotations?.destructiveHint !== false) {
    throw new Error(`${tool.name} is not annotated read-only`);
  }
}

for (const [name, args, shouldWork, key] of calls) {
  const label = `${name} ${JSON.stringify(args)}`;
  const result = await call(client, name, args);
  show(label, result);
  if (result.isError === shouldWork) failures.push(label);
  else if (shouldWork) {
    let parsed;
    try {
      parsed = JSON.parse(result.text);
    } catch {
      parsed = null;
    }
    if (!parsed?.[key]) failures.push(`${label} (no "${key}" in the output)`);
  }
}
await client.close();

const scratch = mkdtempSync(join(tmpdir(), "fuelgauge-smoke-"));
const argvLog = join(scratch, "argv");
for (const [mode, name, args, shouldWork, argv, expected] of fakeCalls) {
  const label = `fake CLI (${mode}) ${name} ${JSON.stringify(args)}`;
  rmSync(argvLog, { force: true });
  const fake = await connect({ FUELGAUGE_CLI: fakeCli, FAKE_MODE: mode, FAKE_ARGV_LOG: argvLog });
  const result = await call(fake, name, args);
  await fake.close();
  show(label, result);
  const sent = readFileSync(argvLog, "utf8");
  const wanted = shouldWork ? JSON.stringify(expected) : expected;
  if (sent !== argv) failures.push(`${label} (sent "${sent}", expected "${argv}")`);
  if (result.isError === shouldWork || result.text !== wanted) failures.push(label);
}
rmSync(scratch, { recursive: true, force: true });

if (failures.length) {
  console.error(`\nFAILED: ${failures.join("; ")}`);
  process.exit(1);
}
console.log(`\nAll ${calls.length + fakeCalls.length} calls behaved as expected.`);
