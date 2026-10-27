# Contributing

Bug reports, ideas, and pull requests are welcome. Open an issue first for anything bigger than a small fix, so we can agree on the approach before you spend time on it.

## Reporting a bug

[Open an issue](https://github.com/coreyhaines31/fuelgauge/issues/new/choose) and include:

- Your Fuel Gauge version (Settings › General) and macOS version.
- Which tools you use with it (Claude Code, Codex) and your plan (Pro, Max, Plus…).
- What you did, what you expected, and what happened. A screenshot of the menu or window helps.

For a forecast that looks wrong, include the output of `fuelgauge status --json` and what Claude Code or Codex showed for the same window.

## Setting up

Follow [Building from source](README.md#building-from-source) in the README. In short:

```sh
brew install xcodegen swiftlint
xcodegen generate
xcodebuild -project FuelGauge.xcodeproj -scheme FuelGauge \
  -derivedDataPath build/DerivedData CODE_SIGNING_ALLOWED=NO test
```

`FuelGauge.xcodeproj` is generated from `project.yml` and isn't checked in. Add new files on disk and run `xcodegen generate` again.

Most logic lives in `Packages/FuelGaugeCore`, which you can test on its own:

```sh
cd Packages/FuelGaugeCore && swift test
```

## Ground rules

These keep Fuel Gauge something people can trust next to their coding tools:

- **Read, never write.** Fuel Gauge reads Claude Code's status line input and Codex's session logs. The only file it changes outside its own folder is Claude Code's `settings.json`, when you turn the status line on, and it backs that up first.
- **No credentials by default.** No browser cookies, no Full Disk Access, no tokens. Anything that needs a keychain item stays opt-in.
- **No telemetry.** Network requests are limited to Sparkle updates and opt-in usage lookups: Cursor usage and Codex reset credits. Codex credentials stay with the installed CLI.
- **Honest forecasts.** Say "learning your pace" until there's enough data, and show a range, not a fake-precise minute.

## Before you open a pull request

- Run the tests and `swiftlint --strict`. Both run in CI on every pull request.
- Keep each pull request to one change, in small commits.
- Add or update tests in `Packages/FuelGaugeCore` for logic changes.
- For a change you can see, add a before-and-after screenshot of the menu or window.

## Contributor terms

Fuel Gauge is licensed under FSL-1.1-MIT, and some future features may be sold under a commercial license. To keep that possible, every contribution comes with these terms. By opening a pull request, you agree that:

1. You wrote the contribution, or otherwise have the right to submit it.
2. You grant Corey Haines a perpetual, worldwide, non-exclusive, royalty-free, irrevocable license to use, modify, and distribute your contribution, and to sublicense and relicense it under any terms, including commercial ones.
3. You keep the copyright in your contribution, and you can use it however you like.

If you can't agree to these terms, please open an issue describing the change instead.
