# Forecasting

Forecasts run locally and automatically. The app, CLI, and Claude Code status line use the same engine and up to 56 days of saved quota readings. No token-to-quota conversion is assumed, and saved reset credits are not deducted from predicted consumption.

## Readings and freshness

Readings are reconciled in memory without rewriting the raw history. Within one limit window, a lower report is held aside until reports remain lower for ten minutes. A recovery to the previous level does not count the same consumption again. A sustained correction starts a new baseline; a changed reset time starts a new window.

An unresolved contradiction produces `stale`, as does a reading older than one hour for windows of five hours or less, or six hours for longer windows. A known exhausted limit remains exhausted until its reset. `stale` and `learning` are unknown outcomes, not evidence that a limit will last. They do not produce exhaustion predictions. The CLI keeps its existing exit convention: 2 for predicted or observed exhaustion, 0 otherwise; scripts should inspect `verdict` for unknown outcomes.

Equal uncapped readings establish an observed quiet interval, for up to 48 hours. An increase can establish consumption over an interval up to three hours long. Longer increases cannot identify which hours were busy, so they do not train the hourly schedule. Time spent at 100% cannot establish normal inactivity. These are cautious inferences from snapshots, not proof that no work happened elsewhere.

## Schedule and current activity

Limits of one day or longer can use a schedule after at least 14 days of history, seven observed dates, 12 supported hours of the day, and 168 observed hours within the latest 14 days. Until then, the engine uses the existing recent-pace method: approximately the last hour for a five-hour window and the last day for a weekly or monthly limit.

The schedule learns hourly averages separately for weekdays and weekends in the Mac's current time zone. A bucket needs two observed dates and two hours of coverage. Sparse buckets fall back to the same hour across all days, then to recent pace. If neither is available, the forecast stays in learning rather than treating unobserved hours as zero usage. A complete schedule can still forecast immediately after a reset. Older observations receive less weight, with a 14-day half-life. Local calendar hours handle daylight-saving transitions; travel and changes of time zone may require relearning a pattern.

Observed consumption over the latest three days adjusts the schedule by a factor between 0.5 and 2. This comparison uses only hours with a supported schedule baseline; unknown hourly rates are not compared against zero. That adjustment fades toward the established schedule over the following days. A fresh active session also influences the immediate forecast, fading over a few hours rather than being projected indefinitely through nights and weekends. Five-hour limits continue using their recent pace.

The panel may also show a separate conditional estimate: **If you keep this session's pace**. This estimates what happens if the current observed rate continues, up to five hours ahead. It does not replace the normal forecast or automatically trigger an exhaustion notification.

Schedule projections integrate the expected consumption in 15-minute steps, so the chart can flatten through learned quiet hours. These are point estimates. The recent-pace method's fastest/slowest range remains a comparison of averaging windows, not a calibrated confidence interval. Probability estimates and calibrated ranges are not implemented.

## Live prediction history

Open **Forecast details** in the menu bar panel to see the current method, the provider's latest reading time, and the schedule's four learning requirements. Learning and recording are on automatically for tracked providers. The reading time is separate from the app's refresh time.

While the app runs, it freezes the first eligible forecast for each limit in each clock hour. The record includes its issue time, source reading, app version, method, verdict, and predictions 1, 6, and 24 hours ahead. Both Fuel Gauge's adaptive prediction and the original recent-pace baseline use the same information available then. Stale, reset, and already-exhausted limits do not create records; learning forecasts can record an unavailable estimate. Targets at or beyond the known reset are marked ineligible. CLI-only use does not record predictions.

An outcome is scored only when the running app receives a reliable reading within 15 minutes after the target, with a source timestamp in that same interval. The frozen estimate is evaluated at the reading's actual timestamp, including exhaustion caps. Waking the Mac later or importing old readings cannot fill missed outcomes. Resets, sustained usage corrections, and unresolved contradictions are excluded. Once evaluated, an outcome is not rewritten by later readings.

The view compares the methods' mean absolute error in **percentage points**, on identical paired outcomes from the last 30 days. Each horizon needs at least 20 pairs across three local issue dates before showing a score. This is a minimum reporting threshold, not a claim of statistical confidence. Observation coverage shows pending, missed, conflicting, reset/correction, and beyond-reset targets separately, along with each method's availability and how many pairs used learned hours. When Fuel Gauge uses recent pace, equal scores are expected.

Hourly comparisons overlap. Changes in your behavior after a warning can also affect results, and the scores describe forecasts as issued across app versions. They are not probabilities or calibrated confidence intervals. No past history is imported as live prediction evidence.

Records stay in `~/Library/Application Support/Fuel Gauge/forecast-history-v1.json`, bounded to 60 days and 10,000 records. Updates are atomic and locked, unchanged data is not rewritten, and an unreadable or unsupported file is preserved with a visible recording warning. This file contains quota readings and predictions, not prompts, responses, tokens, or credentials.

## Historical replay

```sh
fuelgauge backtest --days 7
fuelgauge backtest --days 7 --json
```

The command only reads saved readings. It compares the original recent-pace engine with the adaptive engine at hourly checkpoints, using only readings timestamped at or before each checkpoint. It scores 1-, 6-, and 24-hour predictions when a reliable outcome is observed within 15 minutes after the target. Reset crossings, sustained corrections, missing outcomes, and unresolved contradictions are excluded.

Results include observation counts, each method's forecast coverage, the number of comparable pairs, and how many adaptive forecasts used a learned schedule. Mean absolute error is measured in percentage points on the same paired observations. The JSON includes total absolute errors and paired counts, whose quotient is mean absolute error. Missed exhaustion and early exhaustion counts refer to the target time, not to entire quota cycles.

Checkpoints overlap and are not independent trials. Backfilled source timestamps may precede when Fuel Gauge actually imported a reading, so this is retrospective evaluation rather than an exact audit of forecasts displayed live. Changed behavior after a warning can alter the outcome. Sparse data cannot establish that one model is better, and these results should not be treated as calibrated probabilities. No model parameters are fitted using future outcomes during replay.

Core tests include a multiweek weekday-only workload, an accelerated Monday session, overnight use, daylight-saving changes, contradictory caches, sustained corrections, missing data, reset crossings, and future-data exclusion. Run them with `swift test --package-path Packages/FuelGaugeCore`. Debug builds support `--demo --forecast-demo --snapshot /tmp/forecast.png` for native UI previews.
