// Turns the CLI's JSON into short answers for Claude. Only the listed fields pass through, so nothing
// the CLI might add later (or anything unexpected) reaches the conversation by accident.

export const NO_READINGS =
  "No readings yet. Open Fuel Gauge and use Claude Code, Codex, or Grok Bot for a few minutes. " +
  "Claude Code's limits only arrive through its status line: turn it on in Fuel Gauge's Settings > Tools.";

const STATUS_FIELDS = [
  "tool",
  "window",
  "verdict",
  "summary",
  "used_percent",
  "resets_at",
  "runs_out_at",
  "runs_out_earliest",
  "runs_out_latest",
  "projected_percent_at_reset",
  "rate_per_hour",
  "budget_per_hour",
  "last_reading_at",
] as const;
const MAX_POINTS = 48;
const TOKEN = /^[a-z0-9_-]{1,40}$/;

type Shaped = { ok: true; text: string } | { ok: false; text: string };

function round(value: number): number {
  return Math.round(value * 10) / 10;
}

// "2026-10-29T17:25:53Z" -> "2026-10-29T17:25Z": seconds don't matter to a forecast.
function minute(value: string): string {
  return value.replace(/^(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}):\d{2}(?:\.\d+)?Z$/, "$1Z");
}

function clean(value: unknown): string | number | undefined {
  if (typeof value === "number" && Number.isFinite(value)) return round(value);
  if (typeof value === "string") return minute(value.slice(0, 200));
  return undefined;
}

export function shapeStatus(stdout: string, code: 0 | 2): Shaped {
  let parsed: unknown;
  try {
    parsed = JSON.parse(stdout);
  } catch {
    return { ok: false, text: "Couldn't read Fuel Gauge's forecast." };
  }
  if (!Array.isArray(parsed)) return { ok: false, text: "Couldn't read Fuel Gauge's forecast." };

  const limits = parsed
    .filter((item): item is Record<string, unknown> => Boolean(item) && typeof item === "object")
    .map((item) => {
      const limit: Record<string, string | number> = {};
      for (const field of STATUS_FIELDS) {
        const value = clean(item[field]);
        if (value !== undefined) limit[field] = value;
      }
      return limit;
    });
  const answer: Record<string, unknown> = { problem: code === 2, limits };
  if (limits.length === 0) answer.note = NO_READINGS;
  return { ok: true, text: JSON.stringify(answer) };
}

type Point = [string, number];

// Keeps the readings where the percent changed (plus the latest), then thins evenly to MAX_POINTS.
function thin(points: Point[]): Point[] {
  const changed = points.filter((point, index) => index === 0 || point[1] !== points[index - 1][1]);
  const last = points[points.length - 1];
  if (changed[changed.length - 1] !== last) changed.push(last);
  if (changed.length <= MAX_POINTS) return changed;
  const step = (changed.length - 1) / (MAX_POINTS - 1);
  return Array.from({ length: MAX_POINTS }, (_, index) => changed[Math.round(index * step)]);
}

export function shapeHistory(stdout: string, days: number): Shaped {
  const series = new Map<string, { tool: string; limit: string; resets_at: string; points: Point[] }>();
  for (const line of stdout.split("\n")) {
    if (!line.trim()) continue;
    let reading: Record<string, unknown>;
    try {
      reading = JSON.parse(line);
    } catch {
      return { ok: false, text: "Couldn't read Fuel Gauge's history." };
    }
    const { tool, limit, at, resets_at: resetsAt } = reading;
    const used = Number(reading.used_percent);
    if (typeof tool !== "string" || !TOKEN.test(tool)) continue;
    if (typeof limit !== "string" || !TOKEN.test(limit)) continue;
    if (typeof at !== "string" || typeof resetsAt !== "string" || !Number.isFinite(used)) continue;

    const key = `${tool}/${limit}`;
    const entry = series.get(key) ?? { tool, limit, resets_at: "", points: [] };
    entry.resets_at = minute(resetsAt);
    entry.points.push([minute(at), round(used)]);
    series.set(key, entry);
  }

  const limits = [...series.values()].map(({ tool, limit, resets_at, points }) => ({
    tool,
    limit,
    resets_at,
    readings: points.length,
    // [time, percent used]
    points: thin(points),
  }));
  const answer: Record<string, unknown> = { days, limits };
  if (limits.length === 0) answer.note = NO_READINGS;
  return { ok: true, text: JSON.stringify(answer) };
}
