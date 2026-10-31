# agent-dev-workflow

How one founder runs real ventures through AI coding agents: **13 repos, 824 commits and 101 recorded decisions between 2026-09-09 and 2026-10-31** ([PROOF.md](PROOF.md)). The agents do the building. The human approves plans and reads ✅/❌ reports. The rules a script can enforce are enforced by one. The rest are written so a reviewer can spot a skipped step from the report.

Each workflow below installs on its own. Take one, or all three.

## What's different from opening Claude Code

| | Plain Claude Code | With these workflows |
|---|---|---|
| **"Done"** | The agent says so | Three checks named up front, each run for real, ✅/❌ with evidence. The unrun one is the headline, not a footnote. |
| **A decision made in chat** | Gone when the chat ends | A dated record the same session; the owning doc rewritten; every older mention fixed or stamped *Superseded* |
| **Stale documents** | Look exactly as true as current ones | A retired name in a live doc fails a check with `file:line`, at the start of every session |
| **Numbers in a summary** | Copied, remembered or made up, and you can't tell which | Built from the documents that own them. A missing source fails the build; no number is typed by hand. |
| **Next session / next agent** | Starts from zero | Reads `NEXT.md`: what's true, what's next, what's blocked. A Stop hook won't let a session end without updating it. |
| **Where the human spends time** | Reviewing everything afterwards | Two cheap moments: say "go" to a plan card, read a ✅/❌ report |

## Pick a workflow

| Workflow | Use it if… | What you get |
|---|---|---|
| [**core-loop**](workflows/core-loop/) | you review an agent's work and keep finding out it was wrong after the fact | `/ticket` → `/start` → build → `/wrap`, 11 rules, a Stop hook that enforces the running log |
| [**decision-memory**](workflows/decision-memory/) | your project changes direction faster than its docs do | `/decide`, dated decision records, a retired-names list, a drift check on every session start |
| [**generated-views**](workflows/generated-views/) | you want status pages and summaries you can trust | a view builder where every fact needs a source, and a stale view fails a check |

They stack: core-loop produces the log and decisions, decision-memory keeps them true, generated-views turns them into views without retyping anything.

```
            core-loop                      decision-memory                 generated-views
 ticket → plan card → build → wrap  →  decisions/ + drift check  →  views built from NEXT.md, decisions/, …
                       │                       │                              │
                 Stop hook: NEXT.md     SessionStart: stale docs      SessionStart: stale views
```

## Install

```bash
git clone https://github.com/sorihan01/agent-dev-workflow
cd agent-dev-workflow
./install.sh core-loop ~/path/to/your-project          # repeat for any other workflow
```

The installer copies rules, templates, skills and hooks, adds one import line per workflow to `CLAUDE.md`, merges hooks into `.claude/settings.json`, and **never overwrites a file you already have**.

Or as Claude Code plugins (skills and hooks then update with this repo):

```
/plugin marketplace add sorihan01/agent-dev-workflow
/plugin install core-loop@agent-dev-workflow
```
then `./install.sh <workflow> <project> --files-only` for the project files (rules, `NEXT.md`, templates).

Needs `bash`, `git`, `python3`. No packages.

## See it on real work

[**Worked example**](examples/worked-example/): a scheduled job in a production app silently stopped. It follows the fix from the ⚠️ log line, through the founder's two-word decision and the old plan rewritten in place, to a wrap report that refuses to call it working until it ran in the cloud. Real artefacts, lightly redacted.

## Check it yourself

```bash
bash tests/run.sh
```

It installs every workflow into throwaway projects and proves each enforcement fires: the Stop hook blocks, the drift check catches a retired name, the view builder refuses a missing source. It runs against a throwaway `HOME`, so your own Claude Code settings are untouched.

## Also in the private setup, not packaged yet

- **Many repos, one rule set:** company rules → venture card → repo file, a merged never-do list with dated, founder-signed exceptions, and skills symlinked from the repo so it stays the source of truth.
- **A health check on every session start:** tools, keys (names only, never values), stale docs and stale views, silent when everything is fine.
- **Output shaped for the reviewer:** every artefact is a card (claim with ✅/❌/⚠️/ℹ️, so what, evidence, next), because review fatigue is the real constraint, not agent speed.
- **Unattended runs:** scheduled jobs with spend caps and a check gate that deploy only under a named decision.

## License

[MIT](LICENSE) © 2026 Sori Han
