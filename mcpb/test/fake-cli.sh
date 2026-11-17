#!/bin/sh
# Stands in for the fuelgauge CLI in the smoke test. It logs its arguments to FAKE_ARGV_LOG (calls joined
# by " then "), then FAKE_MODE picks the behavior. A command a mode doesn't list fails, like an older CLI.
if [ -n "$FAKE_ARGV_LOG" ]; then
  [ -s "$FAKE_ARGV_LOG" ] && printf ' then ' >> "$FAKE_ARGV_LOG"
  printf '%s' "$*" >> "$FAKE_ARGV_LOG"
fi
case "$FAKE_MODE:$1" in
  fable:status)
    echo '[{"tool":"claude","window":"weekly","limit":"seven_day_model_fable","model":"Fable","verdict":"makes_it","used_percent":36}]' ;;
  fable:resets)
    echo '{"claude":{"source":"manual","recorded_at":"2026-11-17T17:00:00Z","account_email":"someone@example.com",'
    echo '"fable":{"available":3,"usable":3,"expires_at":"2027-03-09T07:59:00Z","expires_soon":false,"explanation":"Refills Fable and gives back what Fable used this week","grant_id":"secret"},'
    echo '"weekly":{"available":1,"usable":1,"expires_soon":true,"explanation":"Resets your whole week"},'
    echo '"allowances":[{"model":"Fable","used_percent":36,"used_percent_of_weekly":18,"allowance_percent_of_weekly":50,"resets_at":"2026-11-20T21:00:00Z","checked_at":"2026-11-17T17:10:00Z"}],'
    echo '"advice":{"reset":"fable","title":"Fix: a Fable reset","text":"Using a Fable reset gives back 18% of your week."}}}' ;;
  ok:status)
    echo '[{"tool":"claude","window":"5-hour","verdict":"makes_it","summary":"Makes it to reset","used_percent":10.04,"resets_at":"2026-10-29T19:00:00Z","last_reading_at":"2026-10-29T17:25:53Z","rate_per_hour":7,"account_email":"someone@example.com"}]' ;;
  short:status)
    echo '[{"tool":"codex","window":"weekly","verdict":"runs_out","summary":"Runs out around 3:40p","used_percent":80,"resets_at":"2026-10-30T00:00:00Z","runs_out_at":"2026-10-29T22:40:00Z","last_reading_at":"2026-10-29T17:25:53Z"}]'
    exit 2 ;;
  stale:status)
    echo '[{"tool":"codex","window":"weekly","verdict":"stale","forecast_basis":"recent"}]' ;;
  schedule:status)
    echo '[{"tool":"claude","window":"weekly","verdict":"makes_it","forecast_basis":"schedule","session_runs_out_at":"2026-10-29T22:40:00Z"}]' ;;
  empty:status) echo '[]' ;;
  ok:history)
    echo '{"at":"2026-10-29T10:00:01Z","limit":"five_hour","resets_at":"2026-10-29T14:00:00Z","tool":"claude","used_percent":"5.0"}'
    echo '{"at":"2026-10-29T10:05:01Z","limit":"five_hour","resets_at":"2026-10-29T14:00:00Z","tool":"claude","used_percent":"5.0"}'
    echo '{"at":"2026-10-29T10:10:01Z","limit":"five_hour","resets_at":"2026-10-29T14:00:00Z","tool":"claude","used_percent":"7.0"}'
    echo '{"at":"2026-10-29T10:15:01Z","limit":"five_hour","resets_at":"2026-10-29T14:00:00Z","tool":"claude","used_percent":"7.0"}'
    echo '{"at":"2026-10-29T10:20:01Z","limit":"Secret Token","resets_at":"2026-10-29T14:00:00Z","tool":"claude","used_percent":"1.0"}' ;;
  empty:history) ;;
  many:history)
    # 59 readings climbing to 100% before a reset, then 41 in the next window: more than the server keeps.
    i=42; while [ $i -le 100 ]; do
      printf '{"at":"2026-10-29T08:%02d:00Z","limit":"five_hour","resets_at":"2026-10-29T09:00:00Z","tool":"claude","used_percent":"%s.0"}\n' $((i - 42)) $i
      i=$((i + 1)); done
    i=0; while [ $i -le 40 ]; do
      printf '{"at":"2026-10-29T09:%02d:00Z","limit":"five_hour","resets_at":"2026-10-29T14:00:00Z","tool":"claude","used_percent":"%s.0"}\n' $i $i
      i=$((i + 1)); done ;;
  garbage:*) echo 'not json' ;;
  stderr:*) echo "fuelgauge: fake stderr error" >&2; exit 1 ;;
  *) echo "unexpected: $FAKE_MODE $*" >&2; exit 1 ;;
esac
