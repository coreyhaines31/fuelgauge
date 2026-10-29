#!/bin/sh
# Stands in for the fuelgauge CLI in the smoke test. It logs its arguments to FAKE_ARGV_LOG,
# then FAKE_MODE picks the behavior.
[ -n "$FAKE_ARGV_LOG" ] && printf '%s' "$*" > "$FAKE_ARGV_LOG"
case "$FAKE_MODE:$1" in
  ok:status)
    echo '[{"tool":"claude","window":"5-hour","verdict":"makes_it","summary":"Makes it to reset","used_percent":10.04,"resets_at":"2026-10-29T19:00:00Z","last_reading_at":"2026-10-29T17:25:53Z","rate_per_hour":7,"account_email":"someone@example.com"}]' ;;
  short:status)
    echo '[{"tool":"codex","window":"weekly","verdict":"runs_out","summary":"Runs out around 3:40p","used_percent":80,"resets_at":"2026-10-30T00:00:00Z","runs_out_at":"2026-10-29T22:40:00Z","last_reading_at":"2026-10-29T17:25:53Z"}]'
    exit 2 ;;
  empty:status) echo '[]' ;;
  ok:history)
    echo '{"at":"2026-10-29T10:00:01Z","limit":"five_hour","resets_at":"2026-10-29T14:00:00Z","tool":"claude","used_percent":"5.0"}'
    echo '{"at":"2026-10-29T10:05:01Z","limit":"five_hour","resets_at":"2026-10-29T14:00:00Z","tool":"claude","used_percent":"5.0"}'
    echo '{"at":"2026-10-29T10:10:01Z","limit":"five_hour","resets_at":"2026-10-29T14:00:00Z","tool":"claude","used_percent":"7.0"}'
    echo '{"at":"2026-10-29T10:15:01Z","limit":"five_hour","resets_at":"2026-10-29T14:00:00Z","tool":"claude","used_percent":"7.0"}'
    echo '{"at":"2026-10-29T10:20:01Z","limit":"Secret Token","resets_at":"2026-10-29T14:00:00Z","tool":"claude","used_percent":"1.0"}' ;;
  empty:history) ;;
  garbage:*) echo 'not json' ;;
  stderr:*) echo "fuelgauge: fake stderr error" >&2; exit 1 ;;
  *) echo "unexpected: $FAKE_MODE $*" >&2; exit 1 ;;
esac
