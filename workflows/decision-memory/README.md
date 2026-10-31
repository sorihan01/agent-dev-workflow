# decision-memory: decisions that stick, docs that can't quietly disagree

**For:** anyone whose project changes direction faster than its documents do: renames, scope cuts, new rules decided in a chat.

**The problem:** you decide something in a conversation with an agent. The chat ends. Next week a fresh agent reads the old spec, the old name, the old rule, and builds against it with full confidence. With plain Claude Code the decision was never written anywhere the next session reads.

## What it does

```
human decides in chat  →  /decide
                             ├─ decisions/2026-03-02-rename-atlas.md   (dated record, ≤10 lines)
                             ├─ the owning doc rewritten to the new version
                             ├─ every older mention: fixed, or stamped "> **Superseded <date>** by <record>"
                             ├─ old name appended to deprecated-terms.txt
                             └─ tools/drift-check.py must print "clean"

every new session  →  SessionStart hook runs the drift check, so the agent sees any stale doc before it reads it as truth
```

The point is a **check a machine can run**, not a hope that the agent remembers. A retired name in a live doc is a failing check with a file and line number.

## What's in it

| Path | Goes to | Does |
|---|---|---|
| `skills/decide` | `.claude/skills/decide` | `/decide`: record, update the owner, hunt the echoes, retire names, prove it with the drift check. |
| `project/rules/decision-memory.md` | `rules/decision-memory.md` | The four rules, imported from `CLAUDE.md`. |
| `project/deprecated-terms.txt` | `deprecated-terms.txt` | `old \| new \| where the rule lives`, one per line. |
| `project/tools/drift-check.py` | `tools/drift-check.py` | Scans every `.md`/`.mdc`; exit 1 with `file:line` for each live mention of a retired name. |
| `hooks/hooks.json` | `.claude/settings.json` | SessionStart: run the drift check quietly; shows hits, never blocks the session. |

Needs `python3`. No packages.

**What the drift check deliberately ignores:** files stamped `> **Superseded…`, anything in `decisions/`, lines that read as a rename note (`renamed`, `formerly`, `→`, or that also name the new term), and longer words (`Atlas` doesn't match `Atlassian`).

## Install

Works alone, and works best on top of [core-loop](../core-loop/) (whose `/wrap` asks "did the human decide anything?").

```bash
./install.sh decision-memory ~/path/to/your-project
```

or as a plugin:

```
/plugin marketplace add sorihan01/agent-dev-workflow
/plugin install decision-memory@agent-dev-workflow
```
then `./install.sh decision-memory ~/path/to/your-project --files-only`.

## Try it in 5 minutes

1. In a project with a doc that says "Project Atlas", tell the agent: *"we're renaming Project Atlas to Northstar"*.
2. `/decide`. You get a decision file and a list of every doc it fixed or stamped.
3. Run `python3 tools/drift-check.py`. It should print `clean`.
4. Add "Project Atlas ships in May" to any doc and run it again: exit 1, with the file and line.

## Limits

- It catches retired **names and phrases**. A changed number or rule needs its own line in `deprecated-terms.txt` or a careful `/decide` step 3; the agent can still miss an echo the list doesn't name.
- It reads Markdown only. Code comments and UI copy are out of scope.
- The human still decides. `/decide` records, it doesn't choose.
