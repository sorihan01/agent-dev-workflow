# Sourced by tests/run.sh (uses its ok / bad / expect / newproj / $repo).
D="$(newproj)"
expect 0 "installs into an empty project" "$repo/install.sh" decision-memory "$D"
grep -qxF "@rules/decision-memory.md" "$D/CLAUDE.md" && ok "CLAUDE.md imports the rules" || bad "rules import missing"
drift() { (cd "$D" && CLAUDE_PROJECT_DIR="$D" python3 tools/drift-check.py "$@"); }
expect 0 "no rules yet → clean" drift
echo "Project Atlas | Northstar | decisions/2026-01-15-rename.md" >> "$D/deprecated-terms.txt"
mkdir -p "$D/docs" "$D/decisions"
printf '# Plan\n\nShip Project Atlas by spring.\n' > "$D/docs/plan.md"
printf 'We renamed Project Atlas to Northstar.\n' > "$D/decisions/2026-01-15-rename.md"
expect 1 "live mention of a retired name → exit 1" drift
grep -q "docs/plan.md:3" /tmp/adw-test.out && ok "names the file and line (docs/plan.md:3)" || bad "file:line missing"
grep -q "^  decisions/" /tmp/adw-test.out && bad "flagged decisions/ (the record itself)" || ok "ignores decisions/"
printf '> **Superseded 2026-01-15** by decisions/2026-01-15-rename.md\n# Plan\n\nShip Project Atlas by spring.\n' > "$D/docs/plan.md"
expect 0 "same file with a Superseded stamp → clean" drift
printf 'Project Atlas → Northstar\nProject Atlas is now Northstar.\nProject Atlassian sync\n' > "$D/docs/plan.md"
expect 0 "rename notes and longer words are not stale" drift
printf 'Ship Project Atlas.\n' > "$D/docs/plan.md"
out="$(cd "$D" && CLAUDE_PROJECT_DIR="$D" bash -c "$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["hooks"]["SessionStart"][0]["hooks"][0]["command"])' "$D/.claude/settings.json")"; echo "exit=$?")"
echo "$out" | grep -q "docs/plan.md:1" && echo "$out" | grep -q "exit=0" && ok "SessionStart hook shows the hit and never blocks" || { bad "SessionStart hook output"; echo "$out" | sed 's/^/      /'; }
