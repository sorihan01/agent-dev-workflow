---
name: ticket
description: Draft one ticket in the house format — why, scope, three done-when checks, user impact, evidence, and a human check block. Use for any new piece of work, bug or follow-up, before anyone plans or builds it.
argument-hint: "<what needs to happen>"
---

# Ticket

Turn a request into one ticket that someone else could pick up cold. Format: `templates/ticket.md`.

## Steps

1. **Search for duplicates** in the tracker named in `AGENTS.md`, one query per concrete thing the work touches (file, route, table, account), not only a topic word. If one already covers it, update that ticket instead.
2. **Write the outcome, not the ask.** "Customers can reset their password", not "ask Sam about the reset email".
3. **Open the evidence.** Every claim gets a `file:line`, a link, or a named person and date. No evidence means "unknown".
4. **List the edge cases first**, under User impact, then write the three done-when checks from that list. At least one check is an automated test.
5. **Show the draft** and wait for the human's yes before creating it in the tracker.

## Rules

- One screen long. Link other tickets instead of restating them.
- Numbers are measured or left blank. Never write a secret into a ticket.
- Explain jargon once in parentheses.
