#!/usr/bin/env bash
# Stop hook: if this session changed files or made commits, and NEXT.md was not
# updated since the session started, block once and ask for the update.
set -u
input="$(cat)"
read -r sid active <<<"$(printf '%s' "$input" | python3 -c 'import sys,json; d=json.load(sys.stdin); print(d.get("session_id","") or "none", str(d.get("stop_hook_active",False)).lower())' 2>/dev/null)"
[ "${active:-false}" = "true" ] && exit 0

root="${CLAUDE_PROJECT_DIR:-$PWD}"
state="$root/.claude/.session/${sid:-none}.json"
[ -f "$state" ] || exit 0
read -r start head_start <<<"$(python3 -c 'import sys,json; d=json.load(open(sys.argv[1])); print(d["start"], d["head"])' "$state" 2>/dev/null)"
[ -n "${start:-}" ] || exit 0

cd "$root" || exit 0
git rev-parse --show-toplevel >/dev/null 2>&1 || exit 0
changed=0
[ -n "$(git status --porcelain -- . ':!.claude/.session' 2>/dev/null)" ] && changed=1
[ "$(git rev-parse HEAD 2>/dev/null || echo none)" != "$head_start" ] && changed=1
[ "$changed" = 1 ] || exit 0

next="$root/NEXT.md"
[ -f "$next" ] || exit 0
mtime="$(stat -f %m "$next" 2>/dev/null || stat -c %Y "$next")"
if [ "$mtime" -lt "$start" ]; then
  echo "Files changed this session but NEXT.md was not updated. Rewrite Current Status / Immediate Next Steps / Potential Roadblocks (or run /wrap), then finish." >&2
  exit 2
fi
exit 0
