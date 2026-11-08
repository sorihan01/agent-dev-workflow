# after-merge: done means live and written down

**For:** anyone whose agent opens a PR and then forgets about it.

**The problem:** "merged" isn't "working". The deploy can fail, production can differ from staging, and nobody writes down what shipped. A week later nobody can say what changed, or whether it was ever checked live.

## What it does

```
open PR → tools/wait-for-merge.sh (background) → human merges → /landed
                                                                   ├─ merged? deployed? serving the merge commit?
                                                                   ├─ tools/smoke.sh + the ticket's checks on production, read-only, ✅/❌/⬜
                                                                   ├─ one evidence note on the ticket, edited in place
                                                                   ├─ one past-tense entry in deliverables.md, measured result or "unknown"
                                                                   └─ clean repos, update the log, one-screen report
```

The agent notices the merge itself: the watch fires and `/landed` runs, with no "it's merged" message needed. A check that would write to production (a real payment, a real email) is never run by the agent. It stays ⬜ with the steps for the human.

## What's in it

| Path | Goes to | Does |
|---|---|---|
| `project/tools/wait-for-merge.sh` | `tools/` | Polls a PR once a minute; exit 0 merged, 2 closed, 1 timeout. |
| `project/tools/smoke.sh` | `tools/` | Read-only GET checks from `smoke.conf`; any FAIL or unreachable check fails the run. |
| `project/smoke.conf` | `smoke.conf` | Your checks: label, URL, expected status, text the body must contain. |
| `project/deliverables.md` | `deliverables.md` | The log of what landed, one entry per piece of work. |
| `project/rules/after-merge.md` | `rules/` | The 6 rules, imported by `CLAUDE.md`. |
| `skills/landed` | `.claude/skills/` | `/landed`, the after-merge wrap-up. |

Needs `bash`, `curl`, and the GitHub CLI (`gh`, logged in) for the merge watch.

## Install

```bash
./install.sh after-merge ~/path/to/your-project
```

Then replace the example line in `smoke.conf` with your own pages and health routes.

**With core-loop:** `/wrap` ends a step at the PR; `/landed` ends it after the merge. **With parallel-sessions:** `/landed` closes the ticket's desk.
