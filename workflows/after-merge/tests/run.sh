# Sourced by tests/run.sh (uses its ok / bad / expect / newproj / $repo).
M="$(newproj)"
expect 0 "installs into an empty project" "$repo/install.sh" after-merge "$M"
grep -qxF "@rules/after-merge.md" "$M/CLAUDE.md" && ok "CLAUDE.md imports the rules" || bad "rules import missing"
[ -f "$M/.claude/skills/landed/SKILL.md" ] && ok "/landed skill installed" || bad "/landed missing"

# A fake gh that answers with the state in $FAKE_PR_STATE: no network, no login.
FB="$(mktemp -d)"
printf '#!/usr/bin/env bash\necho "$FAKE_PR_STATE"\n' > "$FB/gh"; chmod +x "$FB/gh"
watch() { env PATH="$FB:$PATH" WAIT_SECONDS=0 FAKE_PR_STATE="$1" bash "$M/tools/wait-for-merge.sh" owner/repo 7 2; }
expect 0 "wait-for-merge: merged → exit 0" watch "MERGED 2026-01-15T10:00:00Z"
grep -q "MERGED: owner/repo #7 at 2026-01-15T10:00:00Z" /tmp/adw-test.out && ok "prints the merge time" || bad "merge line"
expect 2 "wait-for-merge: closed without merge → exit 2" watch "CLOSED -"
expect 1 "wait-for-merge: still open → timeout, exit 1" watch "OPEN -"

# A local server stands in for production.
W="$(mktemp -d)"; printf '<title>Shop</title>ok\n' > "$W/index.html"
port="$(python3 -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1",0)); print(s.getsockname()[1])')"
(cd "$W" && exec python3 -m http.server "$port" --bind 127.0.0.1 >/dev/null 2>&1) & srv=$!
for _ in $(seq 1 50); do curl -s -o /dev/null "http://127.0.0.1:$port/" && break; sleep 0.1; done
u="http://127.0.0.1:$port"
smoke() { printf '%b' "$1" > "$M/smoke.conf"; bash "$M/tools/smoke.sh"; }
expect 0 "smoke passes: right status and text" smoke "# comment\nHome | $u/ | 200 | <title>Shop\n"
expect 1 "smoke fails on a wrong status" smoke "Missing | $u/nope | 200\n"
expect 1 "smoke fails when the body lacks the text" smoke "Home | $u/ | 200 | Checkout\n"
expect 1 "smoke fails when nothing answers (could not run = FAIL)" smoke "Down | http://127.0.0.1:9/ | 200\n"
grep -q "answered 000" /tmp/adw-test.out && ok "names the unreachable check" || bad "unreachable line"
expect 1 "smoke fails with no checks" smoke "# only comments\n"
kill "$srv" 2>/dev/null; wait "$srv" 2>/dev/null
