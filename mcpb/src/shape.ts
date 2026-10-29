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
type Reading = { at: string; used: number; window: string };

// Keeps the readings where the percent changed, plus the latest. Past MAX_POINTS it thins evenly, but
// always keeps each window's peak, so a limit that ran out still shows 100% before its reset.
function thin(readings: Reading[]): { points: Point[]; sampled: boolean } {
  const changed = readings.filter((reading, index) => index === 0 || reading.used !== readings[index - 1].used);
  const last = readings[readings.length - 1];
  if (changed[changed.length - 1] !== last) changed.push(last);
  const toPoints = (list: Reading[]) => list.map((reading): Point => [reading.at, reading.used]);
  if (changed.length <= MAX_POINTS) return { points: toPoints(changed), sampled: false };

  const keep = new Set<number>([0, changed.length - 1]);
  const peaks = new Map<string, number>();
  changed.forEach((reading, index) => {
    const peak = peaks.get(reading.window);
    if (peak === undefined || reading.used >= changed[peak].used) peaks.set(reading.window, index);
  });
  for (const index of peaks.values()) keep.add(index);
  const spare = MAX_POINTS - keep.size;
  if (spare > 0) {
    const step = (changed.length - 1) / (spare + 1);
    for (let n = 1; n <= spare; n++) keep.add(Math.round(n * step));
  }
  const kept = [...keep].sort((a, b) => a - b).map((index) => changed[index]);
  return { points: toPoints(kept), sampled: true };
}

export function shapeHistory(stdout: string, days: number): Shaped {
  const series = new Map<string, { tool: string; limit: string; resets_at: string; readings: Reading[] }>();
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
    const entry = series.get(key) ?? { tool, limit, resets_at: "", readings: [] };
    entry.resets_at = minute(resetsAt);
    entry.readings.push({ at: minute(at), used: round(used), window: entry.resets_at });
    series.set(key, entry);
  }

  const limits = [...series.values()].map(({ tool, limit, resets_at, readings }) => {
    const { points, sampled } = thin(readings);
    // points are [time, percent used]
    return { tool, limit, resets_at, readings: readings.length, points, ...(sampled ? { sampled: true } : {}) };
  });
  const answer: Record<string, unknown> = { days, limits };
  if (limits.length === 0) answer.note = NO_READINGS;
  return { ok: true, text: JSON.stringify(answer) };
}
