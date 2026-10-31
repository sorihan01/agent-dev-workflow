---
name: start
description: Pick up a ticket before any code — check it against today's code, walk it from the user's side, dry-run the checks, then show one plan card and wait for the human's go. Use when starting work on any ticket.
argument-hint: "<ticket id or link>"
---

# Start

The step between `/ticket` (written) and `/wrap` (done). A ticket can be days old: check it against today's code before building anything. Read-only until the human says go.

## 1. Read

1. The ticket, its comments and related tickets.
2. The mistakes made last time in this area: search `NEXT.md`, `decisions/` and closed tickets for the same file, page or table.
3. Work on a fresh branch from the latest main, never on main itself.

## 2. Still relevant?

- **Still broken?** Re-find the evidence at the current commit, or reproduce it. Already fixed → say so and stop.
- **Duplicate?** A newer ticket or an open pull request on the same code.
- **In use, half-built or badly built?** Check the callers, the data and the logs before deciding to fix or remove.
- **Worth it now?** Say if it should wait.

## 3. Dry run

Run each done-when check against today's code, read-only. Report what happened, not what the ticket assumes. Anything that can't be run is listed as "not run", with the reason.

## 4. From the user's side

Who it touches, their flow (page → action → result), the edge cases that apply, and what stays unaffected (with the callers traced).

## 5. Plan card, then stop

```
<ticket> · <title>
✅/❌ Still relevant: <one line, evidence>
Users and edge cases: <list>
Dry run: <each check: what it returned today, or "not run: reason">
Recommendation: <option> — <why>; one or two alternatives with a one-line trade-off
Stop-and-ask: <new dependency, schema change, personal data, money, outward-facing — or none>
Estimate: <range, with the assumption>
```

Wait for "go". Then build one small step per commit.
