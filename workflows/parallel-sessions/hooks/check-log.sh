#!/usr/bin/env bash
# Stop hook: block once when the workspace or a repo in desk.conf has commits (or uncommitted
# changes) newer than the last commit under .next/. Quiet otherwise, so a mid-task pause with the
# log already current does not nag. NEXT.md is a build of .next/ (tools/next.sh), so an edit
# under .next/ is what counts as updating the log.
set -u
input="$(cat)"
active="$(printf '%s' "$input" | python3 -c 'import sys,json; print(str(json.load(sys.stdin).get("stop_hook_active",False)).lower())' 2>/dev/null)"
[ "${active:-false}" = "true" ] && exit 0

ws="${CLAUDE_PROJECT_DIR:-$PWD}"
ws="$(git -C "$ws" rev-parse --path-format=absolute --git-common-dir 2>/dev/null | xargs dirname 2>/dev/null)" || exit 0
[ -d "$ws/.next" ] || exit 0
# NEXT.md is a local build: rebuild it quietly, never nag about it.
bash "$ws/tools/next.sh" >/dev/null 2>&1 || true

# An uncommitted .next/ edit counts as updated.
git -C "$ws" diff --quiet -- .next 2>/dev/null || exit 0
[ -z "$(git -C "$ws" ls-files --others --exclude-standard -- .next 2>/dev/null)" ] || exit 0
next_ts="$(git -C "$ws" log -1 --format=%ct -- .next 2>/dev/null)"; next_ts="${next_ts:-0}"

REPOS=()
# shellcheck source=/dev/null
[ -f "$ws/desk.conf" ] && . "$ws/desk.conf"

newer=""
last_other="$(git -C "$ws" log -1 --format=%ct -- . ':!.next' 2>/dev/null)"
[ "${last_other:-0}" -gt "$next_ts" ] && newer="$newer workspace(commit)"
[ -n "$(git -C "$ws" status --porcelain 2>/dev/null | grep -vE '^.. (NEXT\.md|\.desk/)' | head -1)" ] && newer="$newer workspace(uncommitted)"
for line in "${REPOS[@]}"; do
  IFS='|' read -r name path _ _ <<<"$line"
  repo="$ws/$path"
  [ "$(cd "$repo" 2>/dev/null && pwd)" = "$ws" ] && continue   # the workspace itself, done above
  [ -e "$repo/.git" ] || continue
  head_ts="$(git -C "$repo" log -1 --format=%ct 2>/dev/null)"
  [ "${head_ts:-0}" -gt "$next_ts" ] && newer="$newer $name(commit)"
  [ -n "$(git -C "$repo" status --porcelain 2>/dev/null | head -1)" ] && newer="$newer $name(uncommitted)"
done
[ -n "$newer" ] || exit 0

echo "Work is newer than the last .next/ commit:$newer. Update .next/<TICKET>.md (what is true now, what is next; tools/next.sh --lint <TICKET>), commit it in a workspace worktree and land it with tools/land.sh <branch>." >&2
exit 2
