#!/usr/bin/env bash
# After-deploy smoke check. Read-only: GET requests only. One PASS or FAIL line per check, then
# SMOKE: PASS or SMOKE: FAIL. A check that could not run (no answer, timeout) is a FAIL.
#   tools/smoke.sh [checks-file]     default: smoke.conf next to this folder
# checks-file, one check per line ("#" starts a comment):
#   label | url | expected status | text the body must contain (optional)
#   Home page | https://example.com/ | 200 | <title>
#   Health    | https://api.example.com/health | 200 | "ok"
# Needs curl.
set -u
here="$(cd "$(dirname "$0")/.." && pwd)"
file="${1:-$here/smoke.conf}"
[ -f "$file" ] || { echo "smoke: no checks file at $file" >&2; exit 1; }
trim() { local s="$1"; s="${s#"${s%%[![:space:]]*}"}"; echo "${s%"${s##*[![:space:]]}"}"; }
failed=0; ran=0
body="$(mktemp)"; trap 'rm -f "$body"' EXIT
while IFS='|' read -r label url want text || [ -n "$label" ]; do
  label="$(trim "$label")"; [ -n "$label" ] && [ "${label#\#}" = "$label" ] || continue
  url="$(trim "$url")"; want="$(trim "$want")"; text="$(trim "${text:-}")"
  ran=$((ran + 1))
  got="$(curl -s -o "$body" -w '%{http_code}' -m "${SMOKE_TIMEOUT:-10}" "$url" 2>/dev/null)"; got="${got:-000}"
  if [ "$got" != "$want" ]; then
    printf 'FAIL  %-28s %s answered %s, expected %s\n' "$label" "$url" "$got" "$want"; failed=1
  elif [ -n "$text" ] && ! grep -qF -- "$text" "$body"; then
    printf 'FAIL  %-28s %s: body lacks %s\n' "$label" "$url" "$text"; failed=1
  else
    printf 'PASS  %-28s %s %s\n' "$label" "$got" "${text:+(has $text)}"
  fi
done < "$file"
[ "$ran" -gt 0 ] || { echo "SMOKE: FAIL (no checks in $file)"; exit 1; }
[ "$failed" = 0 ] && { echo "SMOKE: PASS"; exit 0; }
echo "SMOKE: FAIL"; exit 1
