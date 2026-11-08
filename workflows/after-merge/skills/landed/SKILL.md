---
name: landed
description: After-merge wrap-up — confirm the PR merged and deployed, run smoke checks and the ticket's done-when checks on production (read-only), edit the ticket's one evidence note, write the deliverables entry in the past tense, and leave every repo on a clean, pulled default branch. Use when wait-for-merge fires, or when the human says "merged", "landed" or "it's live".
---

# Landed

Run this without asking once a merge is known. It ends work that `/wrap` took up to the PR.

## 1. Find what landed

1. The ticket, the PR(s) and the repo(s): from the argument, the wait-for-merge line, or `NEXT.md`.
2. `gh pr view <n> -R <owner/repo> --json state,mergedAt,mergeCommit`. Not merged: stop and say so.
3. Deployed? Find the production deploy newer than the merge, serving the merge commit (your host's CLI or dashboard: a deploy list, a release ID, a version route). Watch it in the background until it is ready or failed; never poll in the foreground.
4. Merged but not deployed: do sections 4 and 5 now and say plainly that the production checks are still owed.

## 2. Check it on production

1. `tools/smoke.sh`. Report every line; a FAIL goes first.
2. Run each done-when check from the ticket against production. ✅ or ❌, each with its evidence: a status code, a measured value, a log line, the live build ID. A check you didn't run stays unticked with the reason.
3. Read-only. A check that needs a write (a real payment, a real message to a person) is the human's: leave it ⬜ and name the exact steps for them.
4. Look around while there: the browser console and failed network calls on the pages you opened, and the server logs for the touched routes since the deploy. Anything broken becomes a fix or a ticket.

## 3. Ticket

1. Edit the ticket's one **Evidence** note (create it only if there is none): add a "Production" block with each check, its evidence and the PR link.
2. If the PR closes the ticket, check the tracker moved it. If not, leave the state alone unless the human said to close it.
3. Anything found in section 2 becomes a line in the ticket's "what's left" or a new ticket, never a new comment.

## 4. Deliverables

One entry in `deliverables.md`, in the format at the top of that file. Past tense. The result is what was measured in section 2, or `unknown`. Never an estimate.

## 5. Clean up

For each repo touched:
1. Close the ticket's desk if you use parallel-sessions (`tools/desk.sh done <TICKET>`), once no PR for it is still open.
2. Check out and pull the default branch, fast-forward only.
3. Delete the local branch already merged (`git branch -d`) and the merged remote branch if the host didn't.
4. Report, never delete, anything unusual: unpushed commits, uncommitted changes, untracked files that aren't build output.
5. Stop any dev server or watcher this session started.

## 6. Log and report

1. Update the running log: delete the ticket's line if nothing is left, or rewrite it to what is left (often "the human runs check N").
2. One short report: what is live and how it was verified, each check ✅/❌/⬜, what was cleaned up, anything found with its ticket, and the single next action.
