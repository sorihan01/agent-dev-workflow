---
name: wrap
description: End-of-task wrap-up — run the step's three checks for real, update NEXT.md, record any decision, comment on the ticket, commit. Use at the end of every task, before saying it is done.
---

# Wrap

Run this before telling the human you are done.

1. **Verify.** Restate the three done-when checks and run each one for real (the command, the page, the output). Mark each ✅ or ❌ with one line of evidence. Never tick an unrun check. If any is ❌, say so first and stop: the step is not done.
2. **NEXT.md.** Rewrite its three sections to what is true now. Delete stale lines rather than adding new ones forever.
3. **Decisions.** Did the human decide anything this session (a name, scope, rule, priority, tool), even in passing? If it isn't in `decisions/` yet, write `decisions/YYYY-MM-DD-<slug>.md` from `templates/decision.md`. If a rule or name changed, search the project for the old wording and update or mark each hit as superseded.
4. **Ticket.** Leave one comment: what shipped, with the commit or pull request link. Only a verified result counts as done.
5. **Commit.** Small and descriptive, in each repo you changed. Never skip hooks or force-push.
6. **Report** in eight lines or fewer: shipped, each check ✅/❌ with evidence, decisions recorded, next step, anything the human must decide.
