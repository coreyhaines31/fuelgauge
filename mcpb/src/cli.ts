import { execFile } from "node:child_process";
import { accessSync, constants } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

export const INSTALL_MESSAGE =
  "Fuel Gauge isn't installed on this Mac, so there's no forecast to read yet. " +
  "Install the free Fuel Gauge app from https://fuelgauge.app (or `brew install --cask coreyhaines31/tap/fuelgauge`), " +
  "open it once, then try again.";

const BUNDLE_ID = "app.fuelgauge.FuelGauge";
const APP_BINARY = "Contents/MacOS/fuelgauge";
// The CLI only reads local files, so it answers in well under a second.
const TIMEOUT_MS = 30_000;

// Only these subcommands can ever be spawned. statusline reads stdin for Claude Code, and
// install-statusline / uninstall-statusline edit ~/.claude/settings.json.
const ALLOWED_COMMANDS = new Set(["status", "history"]);

// The CLI exits 0 on success, 2 when `status` forecasts a limit running out before it resets (or already
// out), and 1 on any error, with the message on stderr. Exit 2 still prints the forecast.
export type RunResult = { ok: true; code: 0 | 2; stdout: string } | { ok: false; text: string };

function isExecutable(path: string): boolean {
  try {
    accessSync(path, constants.X_OK);
    return true;
  } catch {
    return false;
  }
}

function spotlightAppPaths(): Promise<string[]> {
  return new Promise((resolve) => {
    try {
      execFile(
        "/usr/bin/mdfind",
        [`kMDItemCFBundleIdentifier == '${BUNDLE_ID}'`],
        { timeout: 5_000 },
        (error, stdout) => {
          if (error) return resolve([]);
          const apps = stdout.split("\n").map((line) => line.trim()).filter(Boolean);
          resolve(apps.filter((app) => !app.includes("/.Trash/")));
        },
      );
    } catch {
      resolve([]);
    }
  });
}

export async function locateCli(): Promise<string | null> {
  const fromEnv = process.env.FUELGAUGE_CLI?.trim();
  if (fromEnv && isExecutable(fromEnv)) return fromEnv;

  const candidates = [
    join("/Applications/Fuel Gauge.app", APP_BINARY),
    join(homedir(), "Applications/Fuel Gauge.app", APP_BINARY),
    "/opt/homebrew/bin/fuelgauge",
    "/usr/local/bin/fuelgauge",
  ];
  for (const path of candidates) {
    if (isExecutable(path)) return path;
  }

  for (const app of await spotlightAppPaths()) {
    const path = join(app, APP_BINARY);
    if (isExecutable(path)) return path;
  }
  return null;
}

export async function runFuelGauge(args: string[]): Promise<RunResult> {
  if (!ALLOWED_COMMANDS.has(args[0])) {
    return { ok: false, text: `Not allowed: ${args[0]}` };
  }
  if (process.platform !== "darwin") {
    return { ok: false, text: "Fuel Gauge only runs on macOS." };
  }
  const cli = await locateCli();
  if (!cli) return { ok: false, text: INSTALL_MESSAGE };

  return new Promise((resolve) => {
    try {
      execFile(
        cli,
        [...args, "--json"],
        { timeout: TIMEOUT_MS, maxBuffer: 20 * 1024 * 1024 },
        (error, stdout, stderr) => {
          const code = error ? (typeof error.code === "number" ? error.code : null) : 0;
          if (code === 0 || code === 2) return resolve({ ok: true, code, stdout });

          const message = stderr.trim().split("\n")[0]?.replace(/^fuelgauge: /, "");
          if (message) return resolve({ ok: false, text: message });
          if (error?.killed) {
            return resolve({ ok: false, text: `Fuel Gauge didn't answer within ${TIMEOUT_MS / 1000} seconds.` });
          }
          resolve({ ok: false, text: `Fuel Gauge's command line tool failed: ${error?.message ?? "unknown error"}` });
        },
      );
    } catch (error) {
      resolve({ ok: false, text: `Couldn't start Fuel Gauge's command line tool at ${cli}: ${(error as Error).message}` });
    }
  });
}
