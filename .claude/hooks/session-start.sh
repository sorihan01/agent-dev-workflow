#!/usr/bin/env bash
# SessionStart hook: remember when the session started and where HEAD was,
# so the Stop hook can tell whether this session changed anything.
set -u
input="$(cat)"
sid="$(printf '%s' "$input" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("session_id",""))' 2>/dev/null)"
[ -n "$sid" ] || exit 0
dir="${CLAUDE_PROJECT_DIR:-$PWD}/.claude/.session"
mkdir -p "$dir"
head="$(git -C "${CLAUDE_PROJECT_DIR:-$PWD}" rev-parse HEAD 2>/dev/null || echo none)"
printf '{"start": %s, "head": "%s"}\n' "$(date +%s)" "$head" > "$dir/$sid.json"
exit 0
