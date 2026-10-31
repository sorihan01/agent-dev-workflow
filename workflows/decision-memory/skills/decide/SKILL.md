---
name: decide
description: Turn a decision made in chat into the project's memory — a dated decision record, the owning document updated, every older mention fixed or stamped, retired names added to the drift check. Use the moment a human decides a name, scope, rule, priority, owner or tool, even in passing.
argument-hint: "<the decision, in the human's words>"
---

# Decide

A decision that lives only in a chat is gone when the chat ends, and the next agent will follow the old document. This skill makes the newest decision the only live version.

Input: the human's decision in their own words (the argument, or their last message). If it is unclear what was decided, ask one question; never guess at intent.

## Steps

1. **Record.** Write `decisions/YYYY-MM-DD-<slug>.md` from `templates/decision.md` (if present), ten lines or fewer:
   - **Context:** one sentence, what forced the choice.
   - **Decision:** the human's words, tidied, not reinterpreted.
   - **Consequences:** what changes, what is now ruled out, which documents you updated or stamped.
   - Slug: lowercase, hyphens, 3–6 words. Same slug today already exists → append a dated line to it instead.
2. **Update where it lives.** Change the one document that owns the subject (`AGENTS.md` for rules, the spec for product scope, the README for setup). One place, not three. Write it in the present tense, as if it had always been true; the history lives in `decisions/`.
3. **Hunt the echoes.** For every old name, number or phrasing the decision replaces, search all docs: `grep -rniw "<old wording>" --include=*.md --include=*.mdc .`. Each hit gets one of:
   - **fixed**: rewritten to the new version, or
   - **stamped**: if the file is history worth keeping, line 1 becomes `> **Superseded YYYY-MM-DD** by <decision path>`.
4. **Retire names.** If a name changed, append `old | new | <decision path>` to `deprecated-terms.txt`.
5. **Prove it.** Run `python3 tools/drift-check.py`. It must print `clean`. If it lists hits, go back to step 3.
6. **Tell the log.** One line under Current Status in `NEXT.md`: `- Decision: <slug> (decisions/<file>)`. One comment on the affected ticket, linking the file.
7. **Report** in five lines or fewer: the decision file, documents updated, documents stamped, drift check result, anything still stale that needs the human.

## Rules

- Record what the human decided, not what you would have decided. No added scope.
- Numbers in a decision come from the human or a cited source; otherwise "unknown".
- Never delete an old document to "resolve" a conflict. Fix it or stamp it.
