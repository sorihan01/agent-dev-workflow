# Proof

Every number below was measured on **2026-10-31** in the private workspace these workflows come from, with the command next to it. Venture names are left out on purpose. Nothing here is estimated; if a number isn't listed, it wasn't measured.

| What | Number | How it was measured |
|---|---|---|
| Time span | 2026-09-09 → 2026-10-31 | `git log --reverse --format=%ad --date=short \| head -1` and `git log -1` in the umbrella repo |
| Commits across all repos in that span | 824 | `git -C <repo> rev-list --count --since=2026-09-09 HEAD`, summed over the 13 repos |
| Repos run under one rule set | 13 | `find . -maxdepth 3 -name .git -not -path '*/node_modules/*'` |
| Dated decision records | 101 | `ls ops/decisions \| grep -cE '^20[0-9]{2}-'` |
| Retired names the drift check enforces | 15 | `grep -cvE '^\s*(#\|$)' ops/deprecated-terms.txt` |
| Running logs (`NEXT.md`) kept current by the Stop hook | 8 | `find . -name NEXT.md -not -path '*/node_modules/*' -not -path '*/archive/*'` |
| In-house tools (`ops/tools/`) | 31 | `ls ops/tools \| wc -l` |
| Skills written in-house | 10 | `/decide /next /wrap /capture /standup /research /jobsearch /youtube-script /content-intake` + `session-guard`; the other skills in the folder are installed third-party packs |
| People | 1 founder + AI agents | — |

## This repo's own checks

```bash
bash tests/run.sh
```

It validates the marketplace and every plugin, installs each plugin into a throwaway `HOME`, installs each workflow into a throwaway project, and proves the enforcement fires: the Stop hook blocks a session that changed files without updating `NEXT.md`, the drift check fails on a retired name and passes on a stamped file, the view builder fails on a stale view, a missing source and a fact its source doesn't contain. Last run: **35 passed, 0 failed** (2026-10-31).
