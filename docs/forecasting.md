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

**Forecast details → Your usual hours** shows the same hourly estimates the engine uses, with separate weekday and weekend rows on a shared scale. Colored bars come from supported observations for that day group; gray bars borrow the same hour across all days. A dash means zero estimated usage, while a question mark means insufficient evidence. Selecting an hour shows its rate in percentage points per hour, the number of observed dates and hours behind it, and whether it is borrowed. A borrowed zero is labeled **Estimated quiet**, not **Observed quiet**. Times use the Mac's current time zone, including daylight-saving changes.

These bars are the usual hourly averages before recent-activity and session adjustments. Partial patterns can be inspected before the full schedule is eligible; the current forecast's method remains visible above. Learning requirements stay expanded while coverage is incomplete and can be expanded for a ready schedule.

**Recent workload** compares actual consumption with the usual pattern over known hours from the last three days. It needs at least 12 comparable hours and one percentage point of expected usage. The displayed ratio is uncapped: for example, activity can be 3× usual while the forecast adjustment is limited to 2×. When the current forecast is not using the schedule, the view identifies this as a historical comparison. Neither the hourly evidence counts nor workload ratios are confidence estimates.

The panel may also show a separate conditional estimate: **If you keep this session's pace**. This estimates what happens if the current observed rate continues, up to five hours ahead. It does not replace the normal forecast or automatically trigger an exhaustion notification.

## Session planning

**Forecast details → Plan your next session** compares all tracked limits for the selected provider, including short and weekly windows. Choose another 30 minutes, one hour, two hours, or four hours at the current session's pace. The planner shows projected usage and the first tracked limit expected to run out. It is available automatically and does not change the normal forecast, notifications, or prediction history.

The planner uses the same active-session pace as the conditional estimate above: at least two readings in the last hour, at least ten minutes of coverage, no gap longer than thirty minutes, and a latest reading no more than fifteen minutes old. Quiet usage does not establish a pace for future work; missing, contradictory, or old readings remain unknown. An observed exhausted limit stays exhausted until reset even without fresh activity.

Projections start from the latest reported percentage and assume the measured session pace continues. Usage is capped at 100%, and each projection stops at its quota reset. A plan that reaches a reset leaves the following window unknown rather than assuming its allowance or usage. Saved reset credits are never assumed to be redeemed. Reaching 100% at the session end is shown as exhaustion; reaching it exactly at the quota reset is not reported as running out early. These are conditional scenarios, not guarantees or calibrated probabilities.

## Forecast warnings

An early-exhaustion notification requires two distinct source readings that both support a run-out forecast at least 30 minutes before reset. Both readings must be no more than 15 minutes old when the warning fires and belong to the same quota window and window length. Repeated refreshes of a cached reading cannot confirm a warning.

Pending confirmation clears when a limit disappears, its forecast stops running short, readings become unreliable, or forecast notifications are disabled. A lower usage report or changed quota window starts a new confirmation; a backwards timestamp is discarded. A long pause expires the previous evidence. Small reset-time drift retains the existing 10-minute tolerance.

Confirmed warnings remain limited to once per quota window, including after restarting the app. Pending confirmation is kept only in memory, so a restart needs fresh corroboration. Percentage-threshold alerts remain based on observed usage and do not require this two-reading confirmation.

## Projection ranges

Schedule projections integrate the expected consumption in 15-minute steps, so the chart can flatten through learned quiet hours. These are point estimates. The recent-pace method's fastest/slowest range remains a comparison of averaging windows, not a calibrated confidence interval. Probability estimates and calibrated ranges are not implemented.

## Live prediction history

Open **Forecast details** in the menu bar panel to see the current method, the provider's latest reading time, and the schedule's four learning requirements. Learning and recording are on automatically for tracked providers. The reading time is separate from the app's refresh time.

While the app runs, it freezes the first eligible forecast for each limit in each clock hour. The record includes its issue time, source reading, app version, method, verdict, and predictions 1, 6, and 24 hours ahead. Both Fuel Gauge's adaptive prediction and the original recent-pace baseline use the same information available then. Stale, reset, and already-exhausted limits do not create records; learning forecasts can record an unavailable estimate. Targets at or beyond the known reset are marked ineligible. CLI-only use does not record predictions.

An outcome is scored only when the running app receives a reliable reading within 15 minutes after the target, with a source timestamp in that same interval. The frozen estimate is evaluated at the reading's actual timestamp, including exhaustion caps. Waking the Mac later or importing old readings cannot fill missed outcomes. Resets, sustained usage corrections, and unresolved contradictions are excluded. Once evaluated, an outcome is not rewritten by later readings.

**Forecast details → Predicted vs. actual** plots the saved predictions beside their observed outcomes. Choose a 1-, 6-, or 24-hour horizon and forecasts issued in the last 7 or 30 days. Select a time in the chart or use the previous/next buttons to inspect each forecast, including records without a comparison. The plotted time is the actual reading time for observed outcomes, or the original target for unobserved ones. Pending targets can extend into the future.

Blue diamonds show saved predictions and neutral circles show actual readings; a vertical connector shows their difference. Points are never joined across time, so missing observations and changed quota windows cannot imply a continuous usage curve. A missing actual is a gap, never zero usage. Each selection explains its outcome and shows the forecast's issue time, method, and app version. Expand **Saved forecast details** for the original target, quota reset, recent-pace baseline, and receipt time. Individual comparisons appear immediately, without waiting for the aggregate score's evidence threshold. This view does not reconstruct old predictions or alter recording, scoring, or the journal format.

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
