# Parallel sessions

Several agent sessions work in this folder at once. These rules keep them from overwriting each other.

1. **One desk per ticket.** Start code work with `tools/desk.sh open <TICKET> <slug> <repo>...`. Work only in the desk's worktrees, never in the main checkout. Run servers and tests on the desk's ports (`tools/desk.sh run <TICKET> <repo> -- <command>`); never on the default ports, which belong to the human.
2. **The log is one file per ticket.** Edit `.next/<TICKET>.md`, never `NEXT.md` (it is built by `tools/next.sh` and gitignored). Run `tools/next.sh --lint <TICKET>` before committing.
3. **Shared files land through a worktree.** Edit `.next/` and other workspace files in `git worktree add ../<workspace>-<ticket> -b <branch>`, commit there, then `tools/land.sh <branch>`. It refuses when another session has uncommitted edits to a file you changed: wait and retry, don't work around it.
4. **Record the checks as they run.** `tools/desk.sh check <TICKET> <1|2|3> <pass|fail>`, so `tools/desk.sh list` shows every desk's state.
5. **Close the desk when the work lands.** `tools/desk.sh done <TICKET>` removes the worktrees (it refuses a dirty one) and the desk.
6. **Never touch another desk.** Not its worktree, its ports or its ticket file. If something there looks wrong, say so to the human.
