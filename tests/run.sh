#!/usr/bin/env bash
# Proves each workflow does what its README says, in throwaway projects.
#   bash tests/run.sh
set -u
repo="$(cd "$(dirname "$0")/.." && pwd)"
pass=0; fail=0
ok()  { echo "  ✅ $1"; pass=$((pass+1)); }
bad() { echo "  ❌ $1"; fail=$((fail+1)); }
expect() { # expect <want-exit> <label> <cmd...>
  local want="$1" label="$2"; shift 2
  "$@" >/tmp/adw-test.out 2>&1; local got=$?
  [ "$got" = "$want" ] && ok "$label (exit $got)" || { bad "$label: want exit $want, got $got"; sed 's/^/      /' /tmp/adw-test.out | head -8; }
}
newproj() { local d; d="$(mktemp -d)"; git -C "$d" init -q; git -C "$d" -c user.name=t -c user.email=t@t commit -q --allow-empty -m init; echo "$d"; }

echo "manifests"
expect 0 "marketplace validates" claude plugin validate "$repo"
for w in "$repo"/workflows/*/; do expect 0 "plugin $(basename "$w") validates" claude plugin validate "$w"; done
H="$(mktemp -d)"  # throwaway HOME so your own Claude Code settings are untouched
expect 0 "marketplace adds from this checkout" env HOME="$H" claude plugin marketplace add "$repo"
for w in "$repo"/workflows/*/; do
  n="$(basename "$w")"
  expect 0 "plugin $n installs" env HOME="$H" claude plugin install "$n@agent-dev-workflow"
done

echo "core-loop"
P="$(newproj)"
expect 0 "installs into an empty project" "$repo/install.sh" core-loop "$P"
[ "$(grep -c '^@AGENTS.md$' "$P/CLAUDE.md")" = 1 ] && ok "CLAUDE.md imports AGENTS.md once" || bad "CLAUDE.md import"
"$repo/install.sh" core-loop "$P" >/dev/null
[ "$(grep -c 'check-next.sh' "$P/.claude/settings.json")" = 1 ] && ok "re-install adds no duplicate hook" || bad "duplicate hook after re-install"
git -C "$P" add -A && git -C "$P" -c user.name=t -c user.email=t@t commit -qm install
export CLAUDE_PROJECT_DIR="$P"
echo '{"session_id":"t1"}' | bash "$P/.claude/hooks/session-start.sh"
touch -t 202001010000 "$P/NEXT.md"
expect 0 "Stop hook lets an unchanged session finish" bash -c "echo '{\"session_id\":\"t1\"}' | bash '$P/.claude/hooks/check-next.sh'"
echo "x" > "$P/feature.txt"; touch -t 202001010000 "$P/NEXT.md"
expect 2 "Stop hook blocks: files changed, NEXT.md not updated" bash -c "echo '{\"session_id\":\"t1\"}' | bash '$P/.claude/hooks/check-next.sh'"
touch "$P/NEXT.md"
expect 0 "Stop hook lets it finish once NEXT.md is updated" bash -c "echo '{\"session_id\":\"t1\"}' | bash '$P/.claude/hooks/check-next.sh'"

for t in "$repo"/workflows/*/tests/run.sh; do [ -f "$t" ] && { echo "$(basename "$(dirname "$(dirname "$t")")")"; . "$t"; }; done

echo; echo "$pass passed, $fail failed"; [ "$fail" = 0 ]
