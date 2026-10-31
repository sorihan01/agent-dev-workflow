# Rules for every agent in this project

## How we work

1. **Plan first.** Anything beyond a small fix: write the objective, the plan in plain English, and the files you will touch. Wait for the human's "go" before writing code.
2. **Three checks before code.** Write three concrete checks that will prove the step works (a command's output, a status code, a page that shows or doesn't show something). Afterwards run each one for real and report ✅/❌ with evidence, bad news first. A check you didn't run stays unticked.
3. **One small step at a time.** The smallest useful piece, its checks passing, one commit with a clear subject. Then the next.
4. **Sandbox always.** Work in branches, previews, test data and drafts. Anything live, published, paid or sent to a person waits for the human.
5. **Never invent facts.** Every number, price, date or quote comes from a source you can name. Otherwise write "unknown". A plausible guess reads as fact until it causes harm.
6. **Look before trusting.** Read the real data (file types, counts, actual API responses) before running anything on it. Existing code is evidence of how things behave, not a style guide.
7. **Prefer what exists.** Look for a free, maintained tool before building one. If only a paid one fits, name the price and let the human decide.
8. **Keep the log.** At the end of every task, update `NEXT.md` (Current Status / Immediate Next Steps / Potential Roadblocks). Delete stale lines; don't append forever. The Stop hook blocks the session until this is done.
9. **The newest dated statement wins.** When a rule, name or scope changes, write it where it lives, record a decision in `decisions/`, and update or mark every older mention in the same task. Never leave two documents that disagree.
10. **Stop and ask** for: a new dependency, a schema change, personal data, money, legal or compliance claims, anything outward-facing, or anything that would delete work. Guessing at scope is fine; guessing at numbers or at someone's intent is not.
11. **Report briefly.** Lead with the result and the evidence, then the next step. No narration of your own process.

## Git

Small commits with clear subjects. Never skip hooks, force-push, or commit secrets. Check tracked files for keys before the first push.

## Where things live (edit for your project)

- Tasks: `<your tracker: Linear, GitHub Issues, TODO.md>`
- Running log: `NEXT.md`
- Decisions: `decisions/YYYY-MM-DD-<slug>.md`
- Formats: `templates/`
