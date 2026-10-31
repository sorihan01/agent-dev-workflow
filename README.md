# agent-dev-workflow

A copy-ready setup for building software with AI coding agents (Claude Code) so that every piece of work is planned before it starts, proven before it counts as done, and logged so anyone can pick it up later: you next month, another agent, or a new teammate.

## The loop

```
ticket  →  start  →  build  →  wrap
  │          │         │         │
  │          │         │         └─ run the 3 checks for real, update NEXT.md, commit
  │          │         └─ one small step per commit, sandbox only
  │          └─ re-check the ticket against today's code, plan, wait for a human "go"
  └─ write the outcome, the evidence and 3 checks that prove "done"
```

Four habits hold it together:

1. **Plan before code.** Anything bigger than a small fix gets a written objective, plan and file list, and waits for a human yes.
2. **Three checks before "done".** Each step names three concrete checks up front. At the end each one is run for real and reported ✅ or ❌ with evidence. An unrun check stays unticked.
3. **No invented facts.** Numbers, prices and dates are measured or left blank as "unknown".
4. **A running log.** `NEXT.md` always says what is true now, what is next and what is blocked. A hook stops the agent from finishing a session that changed files without updating it.

## Why

Agents are fast and confident, including when they are wrong. This setup moves the human's effort to two cheap moments, approving a plan and reading a ✅/❌ report, instead of reviewing everything after the fact. It also means work can stop at any point and be handed over without a meeting: the ticket, the log and the decision records carry the context.

## What's in it

| Path | What it does |
|---|---|
| `AGENTS.md` | The rules every agent follows. `CLAUDE.md` imports it so Claude Code loads it on start. |
| `NEXT.md` | The running log: Current Status, Immediate Next Steps, Potential Roadblocks. |
| `decisions/` | One short dated file per decision, so "why did we do this?" has an answer. |
| `templates/` | Ticket, decision and pull request formats. |
| `.claude/skills/` | `/ticket`, `/start`, `/wrap`: the loop as slash commands. |
| `.claude/hooks/` | Session-start snapshot and the Stop hook that enforces the log. |
| `.claude/settings.json` | Wires the hooks into Claude Code. |

## Use it

1. Copy everything except `README.md` into the root of your project (or click "Use this template" on GitHub).
2. Edit `AGENTS.md`: add your project's stop-and-ask list and where tickets live.
3. Start a new Claude Code session in the project (rules and skills load at session start).
4. Run `/ticket <what you want>`, then `/start`, build, then `/wrap`.

The hooks need `bash`, `git` and `python3`. Session state is written to `.claude/.session/` (ignored by git).

## Works with any tracker

The skills say "your tracker". Point them at Linear, GitHub Issues, Jira or a `TODO.md` in `AGENTS.md` → *Where things live*.
