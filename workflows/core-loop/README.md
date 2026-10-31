# core-loop: plan, prove, log

**For:** anyone who reviews an AI agent's work and is tired of finding out it was wrong after the fact.

**The problem:** an agent says "done" with the same confidence whether it ran the tests or not. Without a plan you can't stop a wrong build early, and without a log the next session starts from zero.

## What it does

```
/ticket  →  /start  →  build  →  /wrap
   │          │          │          └─ run the 3 checks for real, ✅/❌ with evidence, update NEXT.md, commit
   │          │          └─ one small step per commit, sandbox only
   │          └─ re-check the ticket against today's code, dry-run the checks, one plan card, wait for "go"
   └─ the outcome, the evidence, and 3 checks that prove "done"
```

The human does two cheap things: approves a plan card and reads a ✅/❌ report. The **Stop hook** enforces the log: if the session changed files or made commits and `NEXT.md` wasn't touched, the agent can't finish its turn until it updates it.

## What's in it

| Path | Goes to | Does |
|---|---|---|
| `project/AGENTS.md` | `AGENTS.md` | The 11 rules (plan first, three checks, sandbox, no invented facts…). Read by Claude Code through `CLAUDE.md`, and by other agents directly. |
| `project/NEXT.md` | `NEXT.md` | The running log: Current Status · Immediate Next Steps · Potential Roadblocks. |
| `project/templates/` | `templates/` | Ticket, decision and pull-request formats. |
| `project/decisions/` | `decisions/` | One dated file per human decision. |
| `skills/ticket`, `start`, `wrap` | `.claude/skills/` | The loop as slash commands. |
| `hooks/session-start.sh` | `.claude/hooks/` | Records when the session started and where `HEAD` was. |
| `hooks/check-next.sh` | `.claude/hooks/` | Stop hook: blocks once if files changed and `NEXT.md` didn't. |

Needs `bash`, `git`, `python3`.

## Install

**Copy** (no plugin system):

```bash
git clone https://github.com/sorihan01/agent-dev-workflow && cd agent-dev-workflow
./install.sh core-loop ~/path/to/your-project
```

**Plugin** (skills and hooks update with the repo; you still copy the project files once):

```
/plugin marketplace add sorihan01/agent-dev-workflow
/plugin install core-loop@agent-dev-workflow
```
then `./install.sh core-loop ~/path/to/your-project --files-only`.

The installer never overwrites a file you already have; it tells you which it kept.

## Try it in 5 minutes

1. Edit `AGENTS.md` → *Where things live*: point "Tasks" at your tracker (Linear, GitHub Issues, a `TODO.md`).
2. Start a new Claude Code session in the project.
3. `/ticket add a --version flag to the CLI`. You get a ticket draft with three done-when checks and a human check block.
4. `/start` gives you a plan card. Say "go".
5. Before the agent says it's done, it runs `/wrap`. If it skips it, the Stop hook stops the turn.

## Limits

- The hook checks that `NEXT.md` was touched, not that the update is good. You still read it.
- "Three checks run for real" is a rule the agent follows, not something a script verifies. The ✅/❌ report with evidence is how you catch a skipped one.
- One repo at a time. Rules that must agree across many documents need [decision-memory](../decision-memory/).
