# Decision memory

- **Chat is not a home.** When a human decides a name, scope, rule, priority, owner or tool, even in passing, run `/decide` in the same session. If nothing records it, it does not exist tomorrow.
- **The newest dated statement wins.** When two documents disagree, the one backed by the newer decision is true. Fix or stamp the older one in the same task and say so.
- **Stamp, don't delete.** History worth keeping gets line 1 `> **Superseded YYYY-MM-DD** by <path>`. Everything else is rewritten to the current version.
- **Retired names stay retired.** `deprecated-terms.txt` lists them; `python3 tools/drift-check.py` must print `clean` before a task that touched docs is done.
