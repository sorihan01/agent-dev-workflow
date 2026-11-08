# Sourced by tests/run.sh (uses its ok / bad / expect / newproj / $repo).
G=(-c user.name=t -c user.email=t@t)
S="$(newproj)"; git -C "$S" branch -M main
expect 0 "installs into an empty project" "$repo/install.sh" parallel-sessions "$S"
grep -qxF "@rules/parallel-sessions.md" "$S/CLAUDE.md" && ok "CLAUDE.md imports the rules" || bad "rules import missing"
grep -qxF "NEXT.md" "$S/.gitignore" && grep -qxF ".desk/" "$S/.gitignore" && ok ".gitignore gets NEXT.md and .desk/" || bad ".gitignore lines missing"
printf 'API=http://localhost:3000/v1\nOTHER=localhost:30001\n' > "$S/.env.local"; echo ".env.local" >> "$S/.gitignore"
git -C "$S" add -A && git -C "$S" "${G[@]}" commit -qm install
desk() { (cd "$S" && bash tools/desk.sh "$@"); }
wt1="$(dirname "$S")/$(basename "$S")-abc-1"

expect 1 "desk refuses a ticket that doesn't match TICKET_RE" desk open abc-1 demo app
expect 0 "desk opens ABC-1" desk open ABC-1 demo app
[ -d "$wt1" ] && [ "$(git -C "$wt1" branch --show-current)" = "desk/abc-1-demo" ] && ok "worktree on desk/abc-1-demo" || bad "worktree or branch"
grep -q "localhost:3001/v1" "$wt1/.env.local" && grep -q "localhost:30001" "$wt1/.env.local" && ok "env file moved to the desk's port, longer numbers left alone" || bad "env port rewrite: $(tr '\n' ' ' < "$wt1/.env.local")"
expect 1 "a second desk for the same ticket is refused" desk open ABC-1 demo app
expect 0 "desk opens ABC-2" desk open ABC-2 other app
grep -q '"slot": 2' "$S/.desk/ABC-2.json" && ok "second desk takes the next free slot" || bad "slot"
[ "$(desk run ABC-1 app -- printenv DESK_PORT_APP)" = "3001" ] && ok "run sets DESK_PORT_APP for the desk" || bad "DESK_PORT_APP"
desk check ABC-1 1 pass >/dev/null
listing="$(desk list)"; grep -q "ABC-1 .*checks: pass todo todo" <<<"$listing" && ok "check is recorded and listed" || bad "check/list"
touch "$wt1/scratch.txt"
expect 1 "done refuses a dirty worktree" desk done ABC-1
rm "$wt1/scratch.txt"
expect 0 "done closes a clean desk" desk done ABC-1
[ ! -d "$wt1" ] && [ ! -f "$S/.desk/ABC-1.json" ] && ok "worktree and desk file removed" || bad "leftovers after done"
desk done ABC-2 >/dev/null

next() { (cd "$S" && bash tools/next.sh "$@"); }
printf '200 2. **Second:** later\n100 1. **First:** now\nnote for agents, never printed\n' > "$S/.next/ABC-1.md"
expect 0 "next.sh builds NEXT.md" next
grep -n "First\|Second" "$S/NEXT.md" | head -1 | grep -q "First" && ! grep -q "note for agents" "$S/NEXT.md" && ok "items sorted by key, notes left out" || bad "NEXT.md order"
expect 0 "--check passes on a fresh build" next --check
printf '300 3. **Third:** soon\n' >> "$S/.next/ABC-1.md"
expect 1 "--check fails once .next/ changed" next --check
expect 1 "--lint fails on 3 item lines" next --lint ABC-1
[ "$(next --tickets)" = "ABC-1" ] && ok "--tickets lists ticket files only" || bad "--tickets: $(next --tickets)"
printf '100 1. **First:** now\n' > "$S/.next/ABC-1.md"
git -C "$S" add .next && git -C "$S" "${G[@]}" commit -qm "log ABC-1"

hook() { echo "$1" | CLAUDE_PROJECT_DIR="$S" bash "$S/.claude/hooks/check-log.sh"; }
expect 0 "Stop hook quiet when the log is the newest commit" hook '{}'
sleep 1; echo x > "$S/feature.txt"; git -C "$S" add feature.txt && git -C "$S" "${G[@]}" commit -qm feature
expect 2 "Stop hook blocks: work committed after the last .next/ commit" hook '{}'
expect 0 "Stop hook never blocks twice in a row" hook '{"stop_hook_active":true}'
printf '100 1. **First:** feature shipped\n' > "$S/.next/ABC-1.md"
expect 0 "Stop hook quiet once .next/ is edited" hook '{}'
git -C "$S" checkout -q -- .next

land() { (cd "$S" && bash tools/land.sh "$@"); }
wl="$(dirname "$S")/$(basename "$S")-log"
git -C "$S" worktree add -q -b log/abc-1 "$wl"
printf '100 1. **First:** landed\n' > "$wl/.next/ABC-1.md"; git -C "$wl" "${G[@]}" commit -qam "log: ABC-1 landed"
printf '100 1. **First:** another session, uncommitted\n' > "$S/.next/ABC-1.md"
expect 1 "land refuses when another session has uncommitted edits to the same file" land log/abc-1
git -C "$S" checkout -q -- .next
expect 0 "land fast-forwards the branch" land log/abc-1
[ "$(git -C "$S" log -1 --format=%s)" = "log: ABC-1 landed" ] && [ ! -d "$wl" ] && ok "commit on main, worktree removed" || bad "after land"
grep -q "landed" "$S/NEXT.md" && ok "land rebuilds NEXT.md" || bad "NEXT.md not rebuilt"
