# parallel-sessions: many agents, one workspace, no collisions

**For:** anyone running two or more agent sessions on the same project at once.

**The problem:** two sessions in one checkout overwrite each other's files, fight over the same dev-server port, and both edit the one running log, so one session's update silently wipes the other's. You find out when a test passes for the wrong branch or a status line disappears.

## What it does

```
tools/desk.sh open ABC-42 login-fix api web
   │   a worktree per repo on one branch, env files copied with this desk's ports, a status file
   │
   ├─ build and test in the worktrees:  tools/desk.sh run ABC-42 web -- npm test   (DESK_PORT_* set)
   ├─ record checks as they run:        tools/desk.sh check ABC-42 1 pass
   ├─ log in your own file:             .next/ABC-42.md  →  tools/next.sh builds NEXT.md
   ├─ land shared files:                tools/land.sh <branch>   (fast-forward only; refuses on another session's edits)
   └─ close:                            tools/desk.sh done ABC-42   (refuses a dirty worktree)
```

- **Desks.** Slot N adds N to every base port in `desk.conf`, so desk 1's web server is 3001 and desk 2's is 3002, while the human's own dev server keeps 3000. `tools/desk.sh list` shows every desk: ticket, slot, branch, who claimed it, what it waits for, and its three checks.
- **The log, split.** `NEXT.md` becomes a build output (gitignored) of `.next/`, one file per ticket of at most 2 lines. Two sessions never edit the same file, so there is nothing to merge.
- **Landing.** Shared workspace files are edited in a worktree and landed with `tools/land.sh`. It rebases when the default branch moved and stops if another session has uncommitted edits to a file the branch changes.
- **The Stop hook.** If the workspace or any repo in `desk.conf` has commits or changes newer than the last commit under `.next/`, the session can't end until the ticket's log line is updated. It blocks once, never twice in a row.

## What's in it

| Path | Goes to | Does |
|---|---|---|
| `project/desk.conf` | `desk.conf` | Ticket format, branch pattern, the repos with their base ports and install commands. |
| `project/tools/desk.sh` | `tools/` | Open, run in, check, claim, list and close desks. |
| `project/tools/next.sh` | `tools/` | Build `NEXT.md` from `.next/`; `--lint`, `--check`, `--tickets`. |
| `project/tools/land.sh` | `tools/` | Land a workspace branch, fast-forward only. |
| `project/.next/` | `.next/` | Header, footer and the folder's README (with the sweep for tickets closed elsewhere). |
| `project/rules/parallel-sessions.md` | `rules/` | The 6 rules, imported by `CLAUDE.md`. |
| `hooks/check-log.sh` | `.claude/hooks/` | Stop hook: blocks once when work is newer than the log. |

Needs `bash`, `git` 2.31 or newer, `python3`. The tests run on macOS; the scripts avoid GNU-only flags but have not been run on Linux yet.

## Install

```bash
./install.sh parallel-sessions ~/path/to/your-workspace
```

Then edit `desk.conf`: one `REPOS` line per repo (`name|path|base port|install command`). A repo path of `.` is the workspace itself.

**With core-loop:** they work together. core-loop's Stop hook checks that `NEXT.md` changed; this one rebuilds `NEXT.md` from `.next/` first, so editing your ticket's file satisfies both. If core-loop already put a tracked `NEXT.md` in the project, untrack it once (`git rm --cached NEXT.md`) so it can be a build output.
