"""Merge a workflow's hooks/hooks.json into a project's .claude/settings.json.

Rewrites plugin paths (${CLAUDE_PLUGIN_ROOT}/hooks) to the copied location
($CLAUDE_PROJECT_DIR/.claude/hooks). Adds a hook only if the same command is
not already there, so re-running is safe.

    python3 scripts/merge_hooks.py <hooks.json> <settings.json>
"""
import json
import os
import sys

src, dest = sys.argv[1], sys.argv[2]
with open(src) as f:
    hooks = json.load(f)["hooks"]
settings = {}
if os.path.exists(dest):
    with open(dest) as f:
        settings = json.load(f)
current = settings.setdefault("hooks", {})

added = 0
for event, groups in hooks.items():
    existing = current.setdefault(event, [])
    known = {h.get("command") for g in existing for h in g.get("hooks", [])}
    for group in groups:
        group = json.loads(
            json.dumps(group).replace("${CLAUDE_PLUGIN_ROOT}/hooks", "$CLAUDE_PROJECT_DIR/.claude/hooks")
        )
        if all(h.get("command") in known for h in group.get("hooks", [])):
            continue
        existing.append(group)
        added += 1

os.makedirs(os.path.dirname(dest) or ".", exist_ok=True)
with open(dest, "w") as f:
    json.dump(settings, f, indent=2)
    f.write("\n")
print(f"  hooks: {added} added to {dest}")
