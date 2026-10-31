# Sourced by tests/run.sh (uses its ok / bad / expect / newproj / $repo).
V="$(newproj)"
"$repo/install.sh" core-loop "$V" >/dev/null
expect 0 "installs on top of core-loop" "$repo/install.sh" generated-views "$V"
view() { (cd "$V" && CLAUDE_PROJECT_DIR="$V" python3 tools/build-view.py "$@"); }
printf '# NEXT\n\n## Current Status\n- login works\n\n## Immediate Next Steps\n1. Ship the export button\n\n## Potential Roadblocks\n- none\n' > "$V/NEXT.md"
touch "$V/decisions/2026-01-15-a.md" "$V/decisions/2026-02-01-b.md"
expect 1 "--check before the first build → stale" view --check
expect 0 "builds the view" view
grep -q "| Decisions recorded | 2 |" "$V/views/status.md" && ok "count comes from the file system (2 decisions)" || bad "decision count"
grep -q "Ship the export button" "$V/views/status.md" && ok "text copied verbatim from NEXT.md" || bad "section text"
expect 0 "--check right after a build → fresh" view --check
touch "$V/decisions/2026-03-01-c.md"
expect 1 "a source changed → --check fails" view --check
grep -q "status.md is stale" /tmp/adw-test.out && ok "says which view is stale" || bad "stale message"
view >/dev/null; grep -q "| Decisions recorded | 3 |" "$V/views/status.md" && ok "rebuild picks up the new count (3)" || bad "rebuild count"
sed -i '' 's/"AGENTS.md"/"MISSING.md"/' "$V/views/status.json"
expect 1 "a source path that doesn't exist → build fails" view
grep -q "source not found: MISSING.md" /tmp/adw-test.out && ok "names the missing source" || bad "missing-source message"
sed -i '' 's/"MISSING.md"/"AGENTS.md"/; s/Potential Roadblocks/Budget/' "$V/views/status.json"
expect 1 "a fact the source doesn't contain → build fails, no blank row" view
